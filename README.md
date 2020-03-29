# RedHat-ServiceMeshHW

Openshift Master Console: http://console-openshift-console.apps.cluster-6d6a.6d6a.sandbox1293.opentlc.com
Openshift API for command line 'oc' client: https://api.cluster-6d6a.6d6a.sandbox1293.opentlc.com:6443
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
productpage-bookinfo.apps.cluster-6d6a.6d6a.sandbox1293.opentlc.com

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
elasticsearch-operator.4.1.37-202003021622   Elasticsearch Operator   4.1.37-202003021622              Succeeded

$ oc get pod  -n openshift-operators | grep "^elasticsearch"
elasticsearch-operator-64f57c86cb-x7qxq   1/1     Running   0          2m32s

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
jaeger-operator-54b947db5d-z5ncw         1/1     Running   0          2m12s

2.3 Install Kiali Operator

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
kiali-operator-767d94b8fd-n78jp          1/1     Running   0          102s

2.4 Install ServiceMesh Operator

 - In the OperatorHub catalog of your OCP Web Console, type Service Mesh Operator into the filter box to locate the Service Mesh Operator
 - Click the Service Mesh Operator provided by Red Hat to display information about the Operator
 - Click Install
 - On the Create Operator Subscription page, select :
      a.All namespaces on the cluster (default).
      b.Select the stable Update Channel.
      c.Select the Automatic Approval Strategy.
      d.Click Subscribe

$ oc get ClusterServiceVersion | grep service
NAME                                         DISPLAY                  VERSION               REPLACES                PHASE
servicemeshoperator.v1.0.9                   Red Hat OpenShift Service Mesh   1.0.9                 servicemeshoperator.v1.0.8   Succeeded

$ oc get pod  -n openshift-operators | grep "^istio"
istio-operator-5d997b86c7-x99g9          1/1     Running   0          102s

3.0  ServiceMeshControlPlane

3.1 Create a namespace called bookretail-istio-system where the Service Mesh control plane will be installed.

$ oc adm new-project bookretail-istio-system --display-name="Bookinfo Service Mesh System"
Created project bookretail-istio-system

3.2 Create the custom resource file in your home directory:

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

3.3. Now create the service mesh control plane in the bookretail-istio-system project:

$ oc apply -f $HOME/service-mesh.yaml -n bookretail-istio-system
servicemeshcontrolplane.maistra.io/service-mesh-installation created

$ oc get pods -n bookretail-istio-system
NAME                                      READY   STATUS    RESTARTS   AGE
grafana-84678858b7-2w24z                  2/2     Running   0          3m13s
istio-citadel-559cb64fb8-8zbr5            1/1     Running   0          6m16s
istio-egressgateway-79969bf565-btv4c      1/1     Running   0          3m54s
istio-galley-bfc84b4dc-vrmq8              1/1     Running   0          5m27s
istio-ingressgateway-865d586477-2pzph     1/1     Running   0          3m53s
istio-pilot-59fbdd65d-zx5nh               2/2     Running   0          4m34s
istio-policy-fb98c79d8-7hc4w              2/2     Running   0          5m3s
istio-sidecar-injector-868cc4cd7d-kwpqn   1/1     Running   0          3m38s
istio-telemetry-64d95d568b-6mmfq          2/2     Running   0          5m4s
jaeger-5dbb9b8cbc-mz5rt                   2/2     Running   0          5m30s
kiali-86dc5bd4df-rpfhl                    1/1     Running   0          2m32s
prometheus-864ddd94d7-qv7xx               2/2     Running   0          5m59s

$ oc get routes -n bookretail-istio-system
NAME                   HOST/PORT                                                                                    PATH   SERVICES               PORT    TERMINATION   WILDCARD
grafana                grafana-bookretail-istio-system.apps.cluster-2a58.2a58.sandbox489.opentlc.com                       grafana                <all>   reencrypt     None
istio-ingressgateway   istio-ingressgateway-bookretail-istio-system.apps.cluster-2a58.2a58.sandbox489.opentlc.com          istio-ingressgateway   8080                  None
jaeger                 jaeger-bookretail-istio-system.apps.cluster-2a58.2a58.sandbox489.opentlc.com                        jaeger-query           <all>   reencrypt     None
kiali                  kiali-bookretail-istio-system.apps.cluster-2a58.2a58.sandbox489.opentlc.com                         kiali                  <all>   reencrypt     None
prometheus             prometheus-bookretail-istio-system.apps.cluster-2a58.2a58.sandbox489.opentlc.com                    prometheus             <all>   reencrypt     None

$ oc get route kiali -n bookretail-istio-system -o jsonpath='{"https://"}{.spec.host}{"\n"}'
https://kiali-bookretail-istio-system.apps.cluster-2a58.2a58.sandbox489.opentlc.com
Username: admin
Password: r3dh4t1!