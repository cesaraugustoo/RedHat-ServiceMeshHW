# RedHat-ServiceMeshHW

Openshift Master Console: http://console-openshift-console.apps.cluster-29f8.29f8.sandbox661.opentlc.com
Openshift API for command line 'oc' client: https://api.cluster-29f8.29f8.sandbox661.opentlc.com:6443
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
productpage-bookinfo.apps.cluster-29f8.29f8.sandbox661.opentlc.com

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
elasticsearch-operator-64f57c86cb-4x6df   1/1     Running   0          2m32s

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
jaeger-operator-54b947db5d-cbhw4         1/1     Running   0          2m12s

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
kiali-operator.v1.0.12                       Kiali Operator           1.0.12                kiali-operator.v1.0.11   Succeeded

$ oc get pod  -n openshift-operators | grep "^kiali"
kiali-operator-6559fdc5bc-2r7cs          1/1     Running   0          102s

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
NAME                                         DISPLAY                          VERSION               REPLACES                     PHASE
servicemeshoperator.v1.0.10                  Red Hat OpenShift Service Mesh   1.0.10                servicemeshoperator.v1.0.9   Succeeded

$ oc get pod  -n openshift-operators | grep "^istio"
istio-operator-5f945bd597-lfw4q          1/1     Running   0          102s

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
grafana-7767767555-9cn8j                  2/2     Running   0          3m
istio-citadel-694c654b9b-7cztm            1/1     Running   0          6m31s
istio-egressgateway-5c7fb75799-9w7jn      1/1     Running   0          3m49s
istio-galley-84cfcc5497-wc7mz             1/1     Running   0          5m32s
istio-ingressgateway-6b4575c7bc-vsd99     1/1     Running   0          3m49s
istio-pilot-9f9448dc6-5xldv               2/2     Running   0          4m39s
istio-policy-567cc8b68-9qw78              2/2     Running   0          5m13s
istio-sidecar-injector-677c9d474d-tdth2   1/1     Running   0          3m24s
istio-telemetry-6d57f65478-mlcgk          2/2     Running   0          5m13s
jaeger-5dbb9b8cbc-mzr7w                   2/2     Running   0          5m35s
kiali-c954d57f7-mp8r4                     1/1     Running   0          2m17s
prometheus-5c4977f96c-mggwc               2/2     Running   0          6m13s

$ oc get routes -n bookretail-istio-system
NAME                   HOST/PORT                                                                                     PATH   SERVICES               PORT    TERMINATION   WILDCARD
grafana                grafana-bookretail-istio-system.apps.cluster-29f8.29f8.sandbox661.opentlc.com                       grafana                <all>   reencrypt     None
istio-ingressgateway   istio-ingressgateway-bookretail-istio-system.apps.cluster-29f8.29f8.sandbox661.opentlc.com          istio-ingressgateway   8080                  None
jaeger                 jaeger-bookretail-istio-system.apps.cluster-29f8.29f8.sandbox661.opentlc.com                        jaeger-query           <all>   reencrypt     None
kiali                  kiali-bookretail-istio-system.apps.cluster-29f8.29f8.sandbox661.opentlc.com                         kiali                  <all>   reencrypt     None
prometheus             prometheus-bookretail-istio-system.apps.cluster-29f8.29f8.sandbox661.opentlc.com                    prometheus             <all>   reencrypt     None

$ oc get route kiali -n bookretail-istio-system -o jsonpath='{"https://"}{.spec.host}{"\n"}'
https://kiali-bookretail-istio-system.apps.cluster-29f8.29f8.sandbox661.opentlc.com
Username: admin
Password: r3dh4t1!