 #!/bin/bash -x

DEMO_RUN_FAST=1
. utils.sh

function figlet_string(){
   read -s
   clear
   figlet $1
}
export KUBECONFIG=/etc/kubernetes/admin.conf
export ISTIO_VERSION=1.6.0
export HOST_FOR_HEADER=knative-example.default.example.com
apt-get install -y figlet
apt-get install -y pv 

figlet_string "Setup"

desc "[SETUP] Nodes in the cluster"
run "kubectl get nodes"

desc "[SETUP] All pods in the cluster"
run "kubectl get pods --all-namespaces"

figlet_string "Istio"

rm -rf istio-1.6.0
desc "[ISTIO] Get latest version of Istio" 
dry_run "curl -L https://istio.io/downloadIstio | ISTIO_VERSION=$ISTIO_VERSION sh -"
curl -L https://istio.io/downloadIstio | sh -
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:$PWD/istio-$ISTIO_VERSION/bin


desc "[ISTIO] Install Istio with recommended settings for Knative" 
run "istioctl install --set components.sidecarInjector.enabled=false"

desc "[ISTIO] Check install" 
run "istioctl version"

figlet_string "Knative"

desc "[KNATIVE] Install Knative CRDS"
run "kubectl apply --filename https://github.com/knative/serving/releases/download/v0.14.0/serving-crds.yaml"

desc "[KNATIVE] Install Knative serving core"
run "kubectl apply --filename https://github.com/knative/serving/releases/download/v0.14.0/serving-core.yaml"

desc "[KNATIVE] Install Knative's Istio controller"
run "kubectl apply --filename https://github.com/knative/net-istio/releases/download/v0.14.0/release.yaml"

figlet_string "App"

desc "[DEMO APP] Has a root handler"
run "cat sample-app/helloworld.go"

desc "[DEMO APP] Dockerfile"
run "cat sample-app/Dockerfile"

desc "[DEMO APP] Service"
run "cat sample-app/service.yaml"

desc "[DEMO APP] Create service"
run "kubectl apply -f sample-app/service.yaml"

INGRESS_IP=$(kubectl --namespace istio-system get service istio-ingressgateway -o jsonpath='{.spec.clusterIP}')
desc "[DEMO APP] Calling the knative function, get IngressGateway IP"
dry_run "kubectl --namespace istio-system get service istio-ingressgateway -o jsonpath='{.spec.clusterIP}')"

desc "[DEMO APP] Calling the knative function, calling using curl"
dry_run "curl -H \"Host: $HOST_FOR_HEADER\" http://$INGRESS_IP"
curl -H "Host: $HOST_FOR_HEADER" http://$INGRESS_IP

desc "[DEMO APP] Load app to force autoscale"
dry_run "hey -z 30s -c 50 -host $HOST_FOR_HEADER http://$INGRESS_IP"
./hey -z 30s -c 50 -host $HOST_FOR_HEADER http://$INGRESS_IP

desc "[TEAR DOWN] Uninstall app, knative and istio"
dry_run "./uninstall_for_knative.sh"
./uninstall_for_knative.sh

rm -r $PWD/istio-$ISTIO_VERSION
