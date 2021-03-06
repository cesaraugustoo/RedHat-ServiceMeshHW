#!/bin/bash

	BI_Services="
			details \
			productpage \
			ratings \
			reviews"

# Responsible for patching the readiness and liveness probes in the deployments
# function patchProbes() {

  # echo -en "\n\nPatching readiness and liveness probes in $D_NAME\n"

  # # 1)  Command based liveness and readiness probes
  # oc patch deployment $D_NAME --type='json' -p '[{"op": "add", "path": "/spec/template/spec/containers/0/livenessProbe", "value": { "exec": { "command" : ["ls"]}, "initialDelaySeconds": 30, "timeoutSeconds": 3, "periodSeconds": 30, "successThreshold": 1, "failureThreshold": 3}}, {"op": "add", "path": "/spec/template/spec/containers/0/readinessProbe", "value": { "exec": { "command" : ["ls"]}, "initialDelaySeconds": 30, "timeoutSeconds": 3, "periodSeconds": 30, "successThreshold": 1, "failureThreshold": 3}}]' -n bookinfo

  # # 2)  Loop until pod starts up
  # replicas=1
  # readyReplicas=0 
  # counter=1
  # while (( $replicas != $readyReplicas && $counter != 20 ))
  # do
    # sleep 1 
    # oc get deployment $D_NAME -o json -n bookinfo > /tmp/$D_NAME.json
    # replicas=$(cat /tmp/$D_NAME.json | jq .status.replicas)
    # readyReplicas=$(cat /tmp/$D_NAME.json | jq .status.readyReplicas)
    # echo -en "\n$counter    $D_NAME    $replicas   $readyReplicas\n"
    # let counter=counter+1
  # done
# }

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
      mode: STRICT
  targets:
  - name: $D_NAME" \
  | oc create -n bookinfo -f -
}

# Enable mTLS
for D_NAME in $BI_Services;
do
#  patchProbes
  servicePolicy
done
