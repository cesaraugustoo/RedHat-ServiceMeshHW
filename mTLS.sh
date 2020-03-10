#!/bin/bash

	BI_Deployments="
			details-v1 \
			productpage-v1 \
			ratings-v1 \
			reviews-v1 \
			reviews-v2 \
			reviews-v3"

# Responsible for patching the readiness and liveness probes in the deployments
function patchProbes() {

  echo -en "\n\nPatching readiness and liveness probes in $D_NAME\n"

  # 1)  Command based liveness and readiness probes
  oc patch deployment $D_NAME --type='json' -p '[{"op": "remove", "path": "/spec/template/spec/containers/0/livenessProbe/httpGet"}, {"op": "add", "path": "/spec/template/spec/containers/0/livenessProbe", "value": { "exec": { "command" : ["curl", "http://127.0.0.1:8080/actuator/health"]}, "initialDelaySeconds": 30, "timeoutSeconds": 3, "periodSeconds": 30, "successThreshold": 1, "failureThreshold": 3}}, {"op": "remove", "path": "/spec/template/spec/containers/0/readinessProbe/httpGet"}, {"op": "add", "path": "/spec/template/spec/containers/0/readinessProbe", "value": { "exec": { "command" : ["curl", "http://127.0.0.1:8080/actuator/health"]}, "initialDelaySeconds": 30, "timeoutSeconds": 3, "periodSeconds": 30, "successThreshold": 1, "failureThreshold": 3}}]' -n bookinfo

  # 2)  Loop until pod starts up
  replicas=1
  readyReplicas=0 
  counter=1
  while (( $replicas != $readyReplicas && $counter != 20 ))
  do
    sleep 1 
    oc get deployment $D_NAME -o json -n bookinfo > /tmp/$D_NAME.json
    replicas=$(cat /tmp/$D_NAME.json | jq .status.replicas)
    readyReplicas=$(cat /tmp/$D_NAME.json | jq .status.readyReplicas)
    echo -en "\n$counter    $D_NAME    $replicas   $readyReplicas\n"
    let counter=counter+1
  done
}

# Responsible for creating the policy for each service
function servicePolicy() {

  echo -en "\n\nCreating the service policy for service $D_NAME\n"
  
  echo "---
apiVersion: authentication.istio.io/v1alpha1
kind: Policy
metadata:
  name: $D_NAME-service-mtls
spec:
  peers:
  - mtls:
      mode: PERMISSIVE
  targets:
  - name: $D_NAME" \
  | oc create -n bookinfo -f -
}
 
# Responsible for creating the destination rule for each service
function destRule() {

  echo -en "\n\nCreating the destination rule for service $D_NAME\n"
  
  echo "---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: $D_NAME-client-mtls
spec:
  host: ${D_NAME%-*}.bookinfo.svc.cluster.local
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL" \
  | oc create -n bookinfo -f -
}

# Responsible for creating the virtual service for each service
function virtService() {

  echo -en "\n\nCreating the virtual service for $D_NAME\n"
  
  echo "---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: $D_NAME-virtualservice
spec:
  hosts:
  - incident-service.$ERDEMO_USER.apps.$SUBDOMAIN_BASE
  gateways:
  - erd-wildcard-gateway.$SM_CP_NS.svc.cluster.local
  http:
  - match:
    - uri:
        prefix: /incidents
    route:
    - destination:
        port:
          number: 8080
        host: $ERDEMO_USER-incident-service.$ERDEMO_NS.svc.cluster.local"

}

# Enable command based health probes
for D_NAME in $BI_Deployments;
do
  patchProbes
  servicePolicy
  destRule
  virtService
done
