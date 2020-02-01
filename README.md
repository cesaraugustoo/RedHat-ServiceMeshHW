# RedHat-ServiceMeshHW

Openshift Master Console: http://console-openshift-console.apps.cluster-fe86.fe86.sandbox1365.opentlc.com
Openshift API for command line 'oc' client: https://api.cluster-fe86.fe86.sandbox1365.opentlc.com:6443
Cluster authentication: User 'admin' with password 'r3dh4t1!'

Kiali: https://kiali-bookretail-istio-system.apps.cluster-c7a0.c7a0.sandbox891.opentlc.com/
user:admin
password:r3dh4t1!

Part One

Business Application

1.1 Create a new OpenShift project for the BookInfo application:

$ oc new-project bookinfo
Created project bookinfo

1.2 Deploy the bookinfo application in the new project:

$ oc apply -f https://raw.githubusercontent.com/istio/istio/1.4.0/samples/bookinfo/platform/kube/bookinfo.yaml -n bookinfo

1.3 Expose the productpage service as an OpenShift route:

$ oc expose service productpage

1.4 In your browser, navigate to the bookinfo productpage at the following URL:

$ echo -en "\n$(oc get route productpage --template '{{ .spec.host }}')\n"
productpage-bookinfo.apps.cluster-fe86.fe86.sandbox1365.opentlc.com

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
elasticsearch-operator.4.1.31-202001140447   Elasticsearch Operator   4.1.31-202001140447              Succeeded

$ oc get pod  -n openshift-operators | grep "^elasticsearch"
elasticsearch-operator-6b77cc4998-28hfk   1/1     Running   0          4m42s

2.2 Install Jaeger Operator

 - In the OperatorHub catalog of your OCP Web Console, type Jaeger into the filter box to locate the Elasticsearch Operator.
 - Click the Jaeger Operator provided by Red Hat to display information about the Operator.
 - Click Install
 - On the Create Operator Subscription page, select :
      a.All namespaces on the cluster (default).
      b.Select the stable Update Channel.
      c.Select the Automatic Approval Strategy.
      d.Click Subscribe

$ oc get ClusterServiceVersion | grep jaeger
jaeger-operator.v1.13.1                      Jaeger Operator          1.13.1                           Succeeded

$ oc get pod  -n openshift-operators | grep "^jaeger"
jaeger-operator-bdbcd7fd4-jp7mw           1/1     Running   0          80s	

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
kiali-operator.v1.0.9                        Kiali Operator           1.0.9                 kiali-operator.v1.0.8

$ oc get pod  -n openshift-operators | grep "^kiali"
kiali-operator-5558f5f9f8-krmwm           1/1     Running   0          60s

3. Set Up Service Mesh Operator

3.1 Create an Istio operator namespace, then switch into the "istio-operator" project:

$ oc adm new-project istio-operator --display-name="Service Mesh Operator"
Created project istio-operator

$ oc project istio-operator
Now using project "istio-operator" on server "https://api.cluster-fe86.fe86.sandbox1365.opentlc.com:6443".

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
NAME                            READY   STATUS    RESTARTS   AGE
istio-operator-7fdc886f-5z7qp   1/1     Running   0          47s

4.0  ServiceMeshControlPlane

4.1 Create a namespace called istio-system where the Service Mesh control plane will be installed.

 - oc adm new-project bookretail-istio-system --display-name="Service Mesh System"

 4.2 Create the custom resource file in your home directory:

echo "apiVersion: maistra.io/v1
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

4.3. Now create the service mesh control plane in the istio-system project:
- oc apply -f $HOME/service-mesh.yaml -n bookretail-istio-system

5.0. ServiceMeshMemberRoll

 5.1 Define a ServiceMeshMemberRoll called default that includes a single member project called: user1-tutorial.
echo "apiVersion: maistra.io/v1
kind: ServiceMeshMemberRoll
metadata:
  name: default
spec:
  members:
  # a list of projects joined into the service mesh
  - bookinfo
" > $HOME/service-mesh-roll.yaml \

5.2. Now create the service mesh control plane membership roll in the istio-system project:
oc apply -f $HOME/service-mesh-roll.yaml -n bookretail-istio-system