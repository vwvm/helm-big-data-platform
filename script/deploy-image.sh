#!/bin/bash

# 脚本：deploy-image.sh
# 功能：推送 Docker 镜像到指定范围的节点
# 用法：./deploy-image.sh <image_name> <start_node_num> <end_node_num>
# 示例：./deploy-image.sh myapp:latest 1 5

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的信息
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查参数
if [ $# -ne 3 ]; then
    echo "用法: $0 <image_name> <start_node> <end_node>"
    echo "示例: $0 myapp:latest 1 5"
    echo "      推送 myapp:latest 到 node1 到 node5"
    exit 1
fi

IMAGE_NAME=$1
START_NODE=$2
END_NODE=$3

# 验证参数有效性
if ! [[ "$START_NODE" =~ ^[0-9]+$ ]] || ! [[ "$END_NODE" =~ ^[0-9]+$ ]]; then
    log_error "节点编号必须是数字"
    exit 1
fi

if [ "$START_NODE" -gt "$END_NODE" ]; then
    log_error "起始节点不能大于结束节点"
    exit 1
fi

# 检查本地镜像是否存在
log_info "检查本地镜像: $IMAGE_NAME"
if ! docker image inspect "$IMAGE_NAME" > /dev/null 2>&1; then
    log_error "本地不存在镜像: $IMAGE_NAME"
    echo "可用镜像:"
    docker images
    exit 1
fi

log_info "开始推送镜像 $IMAGE_NAME 到节点 $START_NODE 到 $END_NODE"

# 循环推送镜像到每个节点
SUCCESS_COUNT=0
FAILED_NODES=()

for ((i=START_NODE; i<=END_NODE; i++)); do
    NODE_NAME="node${i}"
    log_info "处理节点: $NODE_NAME"
    
    # 测试节点连接
    if ! ssh -o ConnectTimeout=5 -o BatchMode=yes -o StrictHostKeyChecking=no "root@$NODE_NAME" "echo '连接测试成功'" > /dev/null 2>&1; then
        log_warn "无法连接到节点 $NODE_NAME，跳过"
        FAILED_NODES+=("$NODE_NAME")
        continue
    fi
    
    # 保存镜像为 tar 文件
    TMP_TAR="/tmp/${IMAGE_NAME//[:\/]/_}.tar"
    log_info "将镜像保存为 tar 文件: $TMP_TAR"
    
    if ! docker save -o "$TMP_TAR" "$IMAGE_NAME"; then
        log_error "保存镜像失败"
        FAILED_NODES+=("$NODE_NAME")
        continue
    fi
    
    # 检查文件大小
    FILE_SIZE=$(du -h "$TMP_TAR" | cut -f1)
    log_info "镜像文件大小: $FILE_SIZE"
    
    # 传输到远程节点
    log_info "传输镜像到 $NODE_NAME..."
    if scp -o StrictHostKeyChecking=no "$TMP_TAR" "root@$NODE_NAME:/tmp/"; then
        log_info "文件传输成功"
    else
        log_error "文件传输失败"
        FAILED_NODES+=("$NODE_NAME")
        rm -f "$TMP_TAR"
        continue
    fi
    
    # 在远程节点加载镜像
    log_info "在 $NODE_NAME 上加载镜像..."
    if ssh -o StrictHostKeyChecking=no "root@$NODE_NAME" \
        "docker load -i /tmp/$(basename $TMP_TAR) && \
         echo '镜像加载成功' && \
         rm -f /tmp/$(basename $TMP_TAR)"; then
        log_success "$NODE_NAME: 镜像加载成功"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        log_error "$NODE_NAME: 镜像加载失败"
        FAILED_NODES+=("$NODE_NAME")
    fi
    
    # 清理本地临时文件
    rm -f "$TMP_TAR"
    
    echo "----------------------------------------"
done

# 输出汇总报告
echo ""
log_info "======= 部署完成 ======="
log_success "成功部署到 $SUCCESS_COUNT 个节点"

if [ ${#FAILED_NODES[@]} -gt 0 ]; then
    log_warn "以下节点部署失败:"
    for node in "${FAILED_NODES[@]}"; do
        echo "  - $node"
    done
fi

# 验证部署结果
if [ $SUCCESS_COUNT -gt 0 ]; then
    log_info "验证镜像版本..."
    for ((i=START_NODE; i<=END_NODE; i++)); do
        NODE_NAME="node${i}"
        if [[ ! " ${FAILED_NODES[@]} " =~ " ${NODE_NAME} " ]]; then
            echo -n "检查 $NODE_NAME: "
            if ssh -o StrictHostKeyChecking=no "root@$NODE_NAME" \
                "docker images --format '{{.Repository}}:{{.Tag}}' | grep -E '^${IMAGE_NAME%%:*}' | head -1"; then
                echo "✓"
            else
                echo "✗"
            fi
        fi
    done
fi
