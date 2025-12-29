#!/bin/bash
set -e  # 遇到错误立即退出脚本

# ================= 配置参数（请根据你的实际情况修改）=================
# 密钥保存路径（默认在用户家目录的.ssh文件夹下）
KEY_PATH="$HOME/.ssh/id_rsa_autodeploy"
# 要分发的目标服务器（主机名或IP）
TARGET_SERVERS=("node1" "node2")
# 服务器登录用户名（请替换为你的实际用户名）
SSH_USER="root"
# 服务器SSH端口（默认22，如修改过请对应更改）
SSH_PORT=22
# ==================================================================

# 第一步：检查密钥是否已存在，不存在则创建
if [ -f "$KEY_PATH" ] && [ -f "$KEY_PATH.pub" ]; then
    echo "✅ 密钥文件已存在，跳过创建步骤"
else
    echo "🔑 正在创建SSH密钥对（无密码短语）..."
    # -t rsa：使用RSA算法，-b 4096：密钥长度4096位（更安全）
    # -f：指定密钥保存路径，-N ""：空密码短语（免密码登录）
    ssh-keygen -t rsa -b 4096 -f "$KEY_PATH" -N ""
    echo "✅ 密钥创建成功！私钥：$KEY_PATH，公钥：$KEY_PATH.pub"
fi

# 第二步：将公钥分发到所有目标服务器
echo -e "\n🚀 开始向目标服务器分发公钥..."
for server in "${TARGET_SERVERS[@]}"; do
    echo -e "\n正在处理服务器：$server"
    
    # 检查服务器是否可达
    if ! ping -c 1 -W 3 "$server" > /dev/null 2>&1; then
        echo "❌ 警告：服务器$server无法ping通，跳过该服务器"
        continue
    fi

    # 使用ssh-copy-id工具分发公钥（自动处理权限和authorized_keys文件）
    echo "正在发送公钥到$SSH_USER@$server:$SSH_PORT..."
    ssh-copy-id -i "$KEY_PATH.pub" -p "$SSH_PORT" "$SSH_USER@$server"
    
    # 验证是否分发成功
    if ssh -i "$KEY_PATH" -p "$SSH_PORT" "$SSH_USER@$server" "echo '连接成功'" > /dev/null 2>&1; then
        echo "✅ 公钥已成功分发到$server"
    else
        echo "❌ 公钥分发到$server失败，请检查配置"
    fi
done

echo -e "\n🎉 密钥创建和分发流程完成！"
echo "使用示例：ssh -i $KEY_PATH -p $SSH_PORT $SSH_USER@node1"
