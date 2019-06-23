# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#!/usr/bin/env bash

set -e
sudo swapoff -a
sudo mount bpffs /sys/fs/bpf -t bpf
echo Deploying Kubernetes
sudo kubeadm init --config=$HOME/multicluster/onprem/kubeadm-onprem.yaml

echo Setting Credentials for kubectl access
mkdir -p $HOME/.kube
sudo -H cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo -H chown $(id -u):$(id -g) $HOME/.kube/config

# WARNING: If using kubeadm join to add multiple nodes:
# please comment the following line
kubectl taint nodes --all node-role.kubernetes.io/master-

# UGH
sleep 5


echo Deploying Cilium 1.5.3
kubectl apply -f https://raw.githubusercontent.com/cilium/cilium/1.5.3/examples/kubernetes/1.14/cilium.yaml

# https://metallb.universe.tf/installation/
# Ensure the IP address range in metallb-configmap-073.yaml is reserved
# by your firewall/router and are part of the POD subnet.

echo Deploying metallb 0.7.3 bare metal load balancer provider
kubectl apply -f https://raw.githubusercontent.com/google/metallb/v0.7.3/manifests/metallb.yaml
kubectl apply -f $HOME/multicluster/onprem/metallb-config-073.yaml

echo ""
echo "1. Please use kubeadm join on any extra nodes you wish in your cluster."
echo "2. Wait for all Kubernetes nodes to enter the \"Ready\" state."
echo "3. Deploy Clustermesh."
