kubeadm init  --kubernetes-version=1.32.2 --control-plane-endpoint=master --apiserver-advertise-address=192.168.1.60 --pod-network-cidr=192.168.0.0/16 --image-repository=registry.aliyuncs.com/google_containers --cri-socket=unix:///var/run/cri-dockerd.sock --upload-certs --v=9

