#!/bin/bash

### Uninstall application
kubectl delete -f sample-app/service.yaml

### Uninstall knative
kubectl delete --filename https://github.com/knative/serving/releases/download/v0.14.0/serving-crds.yaml
kubectl delete --filename https://github.com/knative/serving/releases/download/v0.14.0/serving-core.yaml
kubectl delete --filename https://github.com/knative/net-istio/releases/download/v0.14.0/release.yaml

### Uninstall istio
istioctl manifest generate --set components.sidecarInjector.enabled=false | kubectl delete -f -
kubectl delete namespace istio-system
kubectl delete namespace knative-serving 
