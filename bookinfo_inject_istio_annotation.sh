#!/bin/bash

BI_Deployments="
        details-v1 \
        productpage-v1 \
        ratings-v1 \
        reviews-v1 \
        reviews-v2 \
        reviews-v3"
                      

# Responsible for injecting the istio annotation that opts in a deployment for auto injection of the envoy sidecar
function injectAndResume() {

  echo -en "\n\nInjecting istio sidecar annotation into DC: $DC_NAME\n"

  # 1)  Add istio inject annotion into pod.spec.template
  echo "apiVersion: apps.openshift.io/v1
kind: Deployment
metadata:
  name: $D_NAME
spec:
  template:
    metadata:
      annotations:
        sidecar.istio.io/inject: \"true\"" \
  | oc apply -n bookinfo -f -

  # 2)  Loop until envoy enabled pod starts up
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

# Enable Bookinfo Deployment for Envoy auto-injection
for D_NAME in $BI_Deployments;
do
  injectAndResume
done
