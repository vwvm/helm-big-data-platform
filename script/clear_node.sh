#!/bin/bash
set -e

echo "=================================================="
echo "Kubernetes 工作节点 - 完整清理脚本"
echo "=================================================="

echo "步骤 1/6: 执行 kubeadm reset"
sudo kubeadm reset --force --cri-socket unix:///var/run/cri-dockerd.sock

echo "步骤 2/6: 清理 CNI 网络配置"
sudo rm -rf /etc/cni/net.d
sudo rm -rf /var/lib/cni

echo "步骤 3/6: 清理 iptables 规则"
sudo iptables -F
sudo iptables -t nat -F
sudo iptables -t mangle -F
sudo iptables -X

echo "步骤 4/6: 清理 IPVS 规则"
sudo ipvsadm --clear 2>/dev/null || true

echo "步骤 5/6: 删除残留网络接口"
sudo ip link delete cni0 2>/dev/null || true
sudo ip link delete flannel.1 2>/dev/null || true
sudo ip link delete cali+ 2>/dev/null || true  # Calico 接口

echo "步骤 6/6: 清理配置文件和缓存"
rm -rf $HOME/.kube
sudo rm -rf /etc/kubernetes/*
sudo rm -rf /var/lib/kubelet/*

echo "✅ 清理完成！现在可以安全加入集群了"
