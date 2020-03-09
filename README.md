# RedHat-ServiceMeshHW

Openshift Master Console: http://console-openshift-console.apps.cluster-ca48.ca48.sandbox419.opentlc.com
Openshift API for command line 'oc' client: https://api.cluster-ca48.ca48.sandbox419.opentlc.com:6443
Cluster authentication: User 'admin' with password 'r3dh4t1!'

Part One

Business Application

1.1 Create a new OpenShift project for the BookInfo application:

$ oc new-project bookinfo
Created project bookinfo

1.2 Deploy the bookinfo application in the new project:

$ oc apply -f https://raw.githubusercontent.com/istio/istio/1.4.0/samples/bookinfo/platform/kube/bookinfo.yaml -n bookinfo
service/details created
serviceaccount/bookinfo-details created
deployment.apps/details-v1 created
service/ratings created
serviceaccount/bookinfo-ratings created
deployment.apps/ratings-v1 created
service/reviews created
serviceaccount/bookinfo-reviews created
deployment.apps/reviews-v1 created
deployment.apps/reviews-v2 created
deployment.apps/reviews-v3 created
service/productpage created
serviceaccount/bookinfo-productpage created
deployment.apps/productpage-v1 created

1.3 Expose the productpage service as an OpenShift route:

$ oc expose service productpage
route.route.openshift.io/productpage exposed

1.4 In your browser, navigate to the bookinfo productpage at the following URL:

$ echo -en "\n$(oc get route productpage --template '{{ .spec.host }}')\n"
productpage-bookinfo.apps.cluster-ca48.ca48.sandbox419.opentlc.com

Install OpenShift Service Mesh

2. Installing Elasticsearch, Jaeger, Kiali

2.1 Install Elasticsearch Operator

 - In the OperatorHub catalog of your OCP Web Console, type Elasticsearch into the filter box to locate the Elasticsearch Operator.
 - Click the Elasticsearch Operator to display information about the Operator
 - Click Install
 - On the Create Operator Subscription page, specify the following:
     a.Select All namespaces on the cluster (default).
     b.This installs the Operator in the default openshift-operators project and makes the Operator available to all projects in the cluster.
     c.Select the preview Update Channel.
     d.Select the Automatic Approval Strategy.
     e.Click Subscribe

$ oc get ClusterServiceVersion
NAME                                         DISPLAY                  VERSION               REPLACES   PHASE
elasticsearch-operator.4.1.34-202002040910   Elasticsearch Operator   4.1.34-202002040910              Succeeded

$ oc get pod  -n openshift-operators | grep "^elasticsearch"
elasticsearch-operator-fc588c4fb-4q9jt   1/1     Running   0          2m5s

2.2 Install Jaeger Operator

 - In the OperatorHub catalog of your OCP Web Console, type Jaeger into the filter box to locate the Jaeger Operator.
 - Click the Jaeger Operator provided by Red Hat to display information about the Operator.
 - Click Install
 - On the Create Operator Subscription page, select :
      a.All namespaces on the cluster (default).
      b.Select the stable Update Channel.
      c.Select the Automatic Approval Strategy.
      d.Click Subscribe

$ oc get ClusterServiceVersion | grep jaeger
NAME                                         DISPLAY                  VERSION               REPLACES   PHASE
jaeger-operator.v1.13.1                      Jaeger Operator          1.13.1                           Succeeded

$ oc get pod  -n openshift-operators | grep "^jaeger"
jaeger-operator-54b947db5d-229fm         1/1     Running   0          93s	

1.2 Install Kiali Operator

 - In the OperatorHub catalog of your OCP Web Console, type Kiali Operator into the filter box to locate the Kiali Operator
 - Click the Kiali Operator provided by Red Hat to display information about the Operator
 - Click Install
 - On the Create Operator Subscription page, select :
      a.All namespaces on the cluster (default).
      b.Select the stable Update Channel.
      c.Select the Automatic Approval Strategy.
      d.Click Subscribe

$ oc get ClusterServiceVersion | grep kiali
NAME                                         DISPLAY                  VERSION               REPLACES                PHASE
kiali-operator.v1.0.11                       Kiali Operator           1.0.11                kiali-operator.v1.0.10   Succeeded

$ oc get pod  -n openshift-operators | grep "^kiali"
kiali-operator-767d94b8fd-x4bhh          1/1     Running   0          2m26s

3. Set Up Service Mesh Operator

3.1 Create an Istio operator namespace, then switch into the "istio-operator" project:

$ oc adm new-project istio-operator --display-name="Service Mesh Operator"
Created project istio-operator

$ oc project istio-operator
Now using project "istio-operator" on server "https://api.cluster-370a.370a.sandbox977.opentlc.com:6443".

3.2 Create the Istio operator in the "istio-operator" project:

$ oc apply -n istio-operator -f https://raw.githubusercontent.com/Maistra/istio-operator/maistra-1.0.0/deploy/servicemesh-operator.yaml
customresourcedefinition.apiextensions.k8s.io/servicemeshcontrolplanes.maistra.io created
customresourcedefinition.apiextensions.k8s.io/servicemeshmemberrolls.maistra.io created
clusterrole.rbac.authorization.k8s.io/maistra-admin created
clusterrolebinding.rbac.authorization.k8s.io/maistra-admin created
clusterrole.rbac.authorization.k8s.io/istio-operator created
serviceaccount/istio-operator created
clusterrolebinding.rbac.authorization.k8s.io/istio-operator-account-istio-operator-cluster-role-binding created
service/admission-controller created
deployment.apps/istio-operator created

$ oc get pod -n istio-operator
NAME                              READY   STATUS    RESTARTS   AGE
istio-operator-568849cc4f-9wldg   1/1     Running   0          2m1s

4.0  ServiceMeshControlPlane

4.1 Create a namespace called bookinfo-istio-system where the Service Mesh control plane will be installed.

$ oc adm new-project bookinfo-istio-system --display-name="Bookinfo Service Mesh System"
Created project bookinfo-istio-system

4.2 Create the custom resource file in your home directory:

$ echo "apiVersion: maistra.io/v1
kind: ServiceMeshControlPlane
metadata:
  name: service-mesh-installation
spec:
  threeScale:
    enabled: false

  istio:
    global:
      mtls: false
      disablePolicyChecks: false
      proxy:
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 128Mi

    gateways:
      istio-egressgateway:
        autoscaleEnabled: false
      istio-ingressgateway:
        autoscaleEnabled: false
        ior_enabled: false

    mixer:
      policy:
        autoscaleEnabled: false

      telemetry:
        autoscaleEnabled: false
        resources:
          requests:
            cpu: 100m
            memory: 1G
          limits:
            cpu: 500m
            memory: 4G

    pilot:
      autoscaleEnabled: false
      traceSampling: 100.0

    kiali:
      dashboard:
        user: admin
        passphrase: redhat
    tracing:
      enabled: true

" > $HOME/service-mesh.yaml

4.3. Now create the service mesh control plane in the bookretail-istio-system project:

$ oc apply -f $HOME/service-mesh.yaml -n bookinfo-istio-system
servicemeshcontrolplane.maistra.io/service-mesh-installation created

$ oc get pods -n bookinfo-istio-system
NAME                                     READY   STATUS    RESTARTS   AGE
grafana-77fddb8bc-4c67b                  2/2     Running   0          2m45s
istio-citadel-7c64cc84f-k9wp4            1/1     Running   0          6m3s
istio-egressgateway-dcddd9f59-rfrsw      1/1     Running   0          3m22s
istio-galley-cfc947586-zjbgd             1/1     Running   0          5m9s
istio-ingressgateway-688ff46954-tbmn6    1/1     Running   0          3m21s
istio-pilot-9db7457db-fklnk              2/2     Running   0          4m15s
istio-policy-8f57d8465-hqs7x             2/2     Running   0          4m45s
istio-sidecar-injector-f4f4d66d4-vgxdt   1/1     Running   0          3m10s
istio-telemetry-8df9545d9-qdm97          2/2     Running   0          4m44s
jaeger-67597df48b-ff5dn                  2/2     Running   0          5m12s
kiali-86dc5bd4df-nfqn8                   1/1     Running   0          2m4s
prometheus-5c94f8ff6d-4ldzf              2/2     Running   0          5m47s

$ oc get routes -n bookinfo-istio-system
NAME                   HOST/PORT                                                                                  PATH   SERVICES               PORT    TERMINATION   WILDCARD
grafana                grafana-bookinfo-istio-system.apps.cluster-ca48.ca48.sandbox419.opentlc.com                       grafana                <all>   reencrypt     None
istio-ingressgateway   istio-ingressgateway-bookinfo-istio-system.apps.cluster-ca48.ca48.sandbox419.opentlc.com          istio-ingressgateway   8080                  None
jaeger                 jaeger-bookinfo-istio-system.apps.cluster-ca48.ca48.sandbox419.opentlc.com                        jaeger-query           <all>   reencrypt     None
kiali                  kiali-bookinfo-istio-system.apps.cluster-ca48.ca48.sandbox419.opentlc.com                         kiali                  <all>   reencrypt     None
prometheus             prometheus-bookinfo-istio-system.apps.cluster-ca48.ca48.sandbox419.opentlc.com                    prometheus             <all>   reencrypt     None

$ oc get route kiali -n bookinfo-istio-system -o jsonpath='{"https://"}{.spec.host}{"\n"}'
https://kiali-bookinfo-istio-system.apps.cluster-ca48.ca48.sandbox419.opentlc.com
Username: admin
Password: r3dh4t1!