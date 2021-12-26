#! /bin/bash

#
# Author: Badr BADRI © pythops
# Modify: Liu Xueming
#

# Set –e is used within the Bash to stop execution instantly as a query exits while having a non-zero status.
# 参考：https://linuxhint.com/bash-set-e/#:~:text=Set%20%E2%80%93e%20is%20used%20within%20the%20Bash%20to,aspects%20of%20codes.%20Install%20Bash%20extensions%20in%20Linux.
set -e

ARCH=arm64
# 此处的版本应与 ansible/roles/jetson/defaults/main.yaml 下中的 ubuntu_release 相同
# 建议与主机的版本也保持一致，虽说尚未发现不一致会出现什么样的问题。
RELEASE=bionic

# Check if the user is not root
if [ "x$(whoami)" != "xroot" ]; then
	printf "\e[31mThis script requires root privilege\e[0m\n"
	exit 1
fi

# Check for env variables
if [ ! $JETSON_ROOTFS_DIR ]; then
	printf "\e[31mYou need to set the env variable \$JETSON_ROOTFS_DIR\e[0m\n"
	exit 1
fi

# Install prerequisites packages
# 安装 debootstrap 以及相关依赖
# debootstrap 用于创建一个 basic 的 Debian 系统
printf "\e[32mInstall the dependencies...  "
apt-get update > /dev/null
apt-get install --no-install-recommends -y qemu-user-static debootstrap binfmt-support coreutils parted wget gdisk e2fsprogs > /dev/null
printf "[OK]\n"

# Create rootfs directory
printf "Create rootfs directory...    "
mkdir -p $JETSON_ROOTFS_DIR
printf "[OK]\n"

# Run debootstrap first stage
# 可使用命令行：man deboorstrap 查看以下选项的具体含义
printf "Run debootstrap first stage...  "
debootstrap \
        --arch=$ARCH \
        --foreign \
        --variant=minbase \
        # --include=python3,python3-apt \
        $RELEASE \
	$JETSON_ROOTFS_DIR > /dev/null
printf "[OK]\n"

cat <<EOF > $JETSON_ROOTFS_DIR/etc/resolv.conf
nameserver 1.1.1.1
EOF

# 用于模拟 arm 环境，aarch64 指定64位
cp /usr/bin/qemu-aarch64-static $JETSON_ROOTFS_DIR/usr/bin

# Run debootstrap second stage
# 使用 chroot 更改根目录为我们上述新建的 JETSON_ROOTFS_DIR 中，此时，后续运行 apt 等都是在 JETSON_ROOTFS_DIR 下
printf "Run debootstrap second stage... "
chroot $JETSON_ROOTFS_DIR /bin/bash -c "/debootstrap/debootstrap --second-stage" > /dev/null
printf "[OK]\n"

printf "Success!\n"
