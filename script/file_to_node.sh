#!/bin/bash

# 绝对路径映射文件发送脚本：自动获取源文件绝对路径，直接传到节点相同路径
# 支持相对/绝对路径输入，自动转换为绝对路径，无需手动处理路径差异
# 使用方式：./send_file_abs_path.sh <源文件路径> <节点起始编号> <节点结束编号> [可选：节点目标绝对路径]

##############################################################################
# 第一步：参数处理与基础校验
##############################################################################
# 校验参数数量（3个必填，1个可选）
if [ $# -lt 3 ] || [ $# -gt 4 ]; then
    echo "错误：参数数量不正确！"
    echo "使用方法：$0 <源文件路径> <节点起始编号> <节点结束编号> [可选：节点目标绝对路径]"
    echo "示例1（自动绝对路径映射）：$0 ./test.sh 1 2 → 本地绝对路径如/root/test.sh → 节点/root/test.sh"
    echo "示例2（绝对路径源文件）：$0 /etc/hosts 1 4 → 节点/etc/hosts（和本地完全一致）"
    echo "示例3（自定义节点路径）：$0 ./config.yaml 1 3 /opt/config.yaml → 节点/opt/config.yaml"
    exit 1
fi

# 接收参数
INPUT_PATH="$1"        # 输入路径（支持相对/绝对路径，如./test.sh 或 /etc/hosts）
START_NODE="$2"        # 节点起始编号
END_NODE="$3"          # 节点结束编号
CUSTOM_DEST="$4"       # 可选：用户指定的节点目标绝对路径（如/opt/app/config.yaml）

##############################################################################
# 第二步：核心逻辑：获取源文件的绝对路径（解决相对路径问题）
##############################################################################
# realpath 命令：自动将相对路径转换为绝对路径（无论输入是相对还是绝对，最终都得到绝对路径）
# 检查系统是否安装 realpath（大部分Linux系统默认自带，如Ubuntu、CentOS 7+）
if ! command -v realpath &> /dev/null; then
    echo "错误：系统缺少 realpath 命令，请先安装（Ubuntu：sudo apt install coreutils；CentOS：sudo yum install coreutils）"
    exit 1
fi

# 获取源文件的绝对路径（关键步骤：统一路径格式）
SOURCE_ABS_PATH=$(realpath "$INPUT_PATH")

# 校验：源文件必须存在且是文件（不是目录）
if [ ! -f "$SOURCE_ABS_PATH" ]; then
    echo "错误：源文件 $INPUT_PATH（绝对路径：$SOURCE_ABS_PATH）不存在，或不是一个文件！"
    exit 1
fi

# 校验：源文件有读取权限
if [ ! -r "$SOURCE_ABS_PATH" ]; then
    echo "错误：没有源文件 $SOURCE_ABS_PATH 的读取权限！"
    exit 1
fi

##############################################################################
# 第三步：确定节点上的目标路径
##############################################################################
if [ -n "$CUSTOM_DEST" ]; then
    # 情况1：用户指定了目标路径 → 直接使用（要求用户输入绝对路径，脚本做简单校验）
    if [[ "$CUSTOM_DEST" != /* ]]; then
        echo "错误：自定义目标路径必须是绝对路径（如/opt/config.yaml），请重新输入！"
        exit 1
    fi
    DEST_ABS_PATH="$CUSTOM_DEST"
else
    # 情况2：用户未指定 → 直接使用源文件的绝对路径（本地路径=节点路径）
    DEST_ABS_PATH="$SOURCE_ABS_PATH"
fi

##############################################################################
# 第四步：循环发送文件到每个节点（确保目标目录存在）
##############################################################################
for ((i=START_NODE; i<=END_NODE; i++)); do
    NODE_NAME="node$i"  # 节点名称（可修改为worker$i等，按实际集群调整）
    DEST_DIR=$(dirname "$DEST_ABS_PATH")  # 提取目标路径的目录（如/opt/app/config.yaml → /opt/app）
    
    echo "=== 正在处理节点：$NODE_NAME ==="
    echo "本地源文件（绝对路径）：$SOURCE_ABS_PATH"
    echo "节点目标路径：$DEST_ABS_PATH"

    # 关键优化：先在节点上创建目标目录（避免目录不存在导致传输失败）
    # ssh 执行 mkdir -p：不存在则创建，存在则不报错（-p 递归创建多级目录）
    ssh -o StrictHostKeyChecking=no "root@$NODE_NAME" "mkdir -p $DEST_DIR" > /dev/null 2>&1

    # SCP 传输文件：保留权限（-p）、静默模式（-q）、跳过密钥确认
    scp -q -p -o StrictHostKeyChecking=no "$SOURCE_ABS_PATH" "root@$NODE_NAME:$DEST_ABS_PATH"

    # 校验传输结果
    if [ $? -eq 0 ]; then
        echo -e "✅ 发送成功！文件已保存到节点的 $DEST_ABS_PATH\n"
    else
        echo -e "❌ 发送失败！可能原因：节点未开机、网络不通、目标目录无写入权限\n"
    fi
done

echo "=== 所有节点处理完成 ==="
