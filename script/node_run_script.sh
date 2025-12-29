#!/bin/bash

# 批量执行节点指令脚本：支持指定指令、节点范围、是否后台执行
# 使用方式：./exec_cmd_on_nodes.sh <要执行的指令> <节点起始编号> <节点结束编号> [可选：是否后台执行（yes/no，默认no）]

##############################################################################
# 第一步：参数处理与基础校验
##############################################################################
# 校验参数数量（3个必填，1个可选）
if [ $# -lt 3 ] || [ $# -gt 4 ]; then
    echo "错误：参数数量不正确！"
    echo "使用方法：$0 <要执行的指令> <节点起始编号> <节点结束编号> [可选：是否后台执行（yes/no，默认no）]"
    echo "示例1（前台执行）：$0 'chmod +x /root/k8s/nfs/nfs-nodes-client.sh && /root/k8s/nfs/nfs-nodes-client.sh' 1 4"
    echo "示例2（后台执行）：$0 'nohup /root/start_app.sh > /dev/null 2>&1 &' 1 2 yes"
    echo "示例3（多指令）：$0 'apt update && apt install -y nfs-common' 1 3"
    exit 1
fi

# 接收参数
TARGET_CMD="$1"        # 要执行的指令（支持多指令，用&&分隔）
START_NODE="$2"        # 节点起始编号
END_NODE="$3"          # 节点结束编号
RUN_BACKGROUND="${4:-no}"  # 可选：是否后台执行（默认no）

# 校验：节点编号必须是数字
if ! [[ "$START_NODE" =~ ^[0-9]+$ && "$END_NODE" =~ ^[0-9]+$ ]]; then
    echo "错误：节点起始/结束编号必须是数字！"
    exit 1
fi

# 校验：起始编号 ≤ 结束编号
if [ "$START_NODE" -gt "$END_NODE" ]; then
    echo "错误：节点起始编号不能大于结束编号！"
    exit 1
fi

# 校验：后台执行参数只能是yes/no
if [[ "$RUN_BACKGROUND" != "yes" && "$RUN_BACKGROUND" != "no" ]]; then
    echo "错误：是否后台执行参数只能是 yes 或 no！"
    exit 1
fi

##############################################################################
# 第二步：构造执行指令（处理后台执行）
##############################################################################
if [ "$RUN_BACKGROUND" = "yes" ]; then
    # 后台执行：加nohup和&，重定向输出（避免终端挂起）
    EXEC_CMD="nohup bash -c '$TARGET_CMD' > /tmp/exec_cmd_$(date +%Y%m%d%H%M%S).log 2>&1 &"
    echo "⚠️  已开启后台执行，指令输出日志：节点/tmp/exec_cmd_*.log"
else
    # 前台执行：直接执行，实时输出
    EXEC_CMD="bash -c '$TARGET_CMD'"
fi

##############################################################################
# 第三步：循环在每个节点执行指令
##############################################################################
for ((i=START_NODE; i<=END_NODE; i++)); do
    NODE_NAME="node$i"  # 节点名称（可修改为worker$i等，按实际集群调整）
    echo -e "\n=== 正在处理节点：$NODE_NAME ==="
    echo "要执行的指令：$TARGET_CMD"
    echo "执行方式：$(if [ "$RUN_BACKGROUND" = "yes" ]; then echo "后台执行"; else echo "前台执行"; fi)"

    # 执行指令：跳过密钥确认，实时输出（前台）/静默（后台）
    if [ "$RUN_BACKGROUND" = "yes" ]; then
        # 后台执行：静默模式，仅返回结果
        ssh -o StrictHostKeyChecking=no "root@$NODE_NAME" "$EXEC_CMD" > /dev/null 2>&1
    else
        # 前台执行：实时输出指令执行日志
        ssh -o StrictHostKeyChecking=no "root@$NODE_NAME" "$EXEC_CMD"
    fi

    # 校验执行结果
    if [ $? -eq 0 ]; then
        echo -e "✅ 节点 $NODE_NAME 指令执行成功！"
    else
        echo -e "❌ 节点 $NODE_NAME 指令执行失败！可能原因：节点未开机、网络不通、指令错误"
    fi
done

echo -e "\n=== 所有节点指令执行完成 ==="