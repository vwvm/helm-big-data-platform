#!/bin/bash
set -e

echo "=== 开始扩展LVM ==="
echo ""

echo "1. 当前磁盘状态："
lsblk
echo ""

echo "2. 扩展分区..."
# 使用parted非交互模式扩展分区
sudo parted /dev/sda ---pretend-input-tty <<EOF
resizepart 3
Yes
-1
quit
EOF

echo "3. 重新扫描磁盘..."
sudo partprobe /dev/sda
sleep 3

echo "4. 查看分区状态："
lsblk
echo ""

echo "5. 扩展物理卷..."
sudo pvresize /dev/sda3
echo "物理卷状态："
sudo pvs
echo ""

echo "6. 查看卷组可用空间："
sudo vgdisplay ubuntu-vg | grep -A 3 "Free"
echo ""

echo "7. 扩展逻辑卷..."
sudo lvextend -l +100%FREE /dev/mapper/ubuntu--vg-ubuntu--lv
echo ""

echo "8. 扩展文件系统..."
# 假设是ext4文件系统
sudo resize2fs /dev/mapper/ubuntu--vg-ubuntu--lv
echo ""

echo "9. 最终验证："
df -h | grep ubuntu--lv
sudo vgdisplay ubuntu-vg | grep -E "VG Size|Free"
echo ""

echo "=== 扩展完成 ==="
