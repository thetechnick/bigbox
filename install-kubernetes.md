```bash
cat <<EOF > /etc/docker/daemon.json 
{
  "ipv6": true,
  "fixed-cidr-v6": "2001:db8:1::/64"
}
EOF
systemctl restart docker

kubeadm init --pod-network-cidr=10.244.0.0/16,a00:100::/24 \
--ignore-preflight-errors=NumCPU \
--feature-gates=IPv6DualStack=true

mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

kubectl apply -f https://docs.projectcalico.org/v3.10/manifests/canal.yaml

```


--network-plugin=kubenet
