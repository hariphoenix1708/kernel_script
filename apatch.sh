#!/usr/bin/env sh
#
# GNU General Public License v3.0
# Copyright (C) 2023 MoChenYa mochenya20070702@gmail.com
#

WORKDIR="$(pwd)"

# ZyClang
# ZYCLANG_DLINK="https://github.com/ZyCromerZ/Clang/releases/download/17.0.0-20230725-release/Clang-17.0.0-20230725.tar.gz"
# ZYCLANG_DLINK="https://github.com/ZyCromerZ/Clang/releases/download/19.0.0git-20240203-release/Clang-19.0.0git-20240203.tar.gz"
ZYCLANG_DLINK="https://github.com/SkiddieKernel/Clang/releases/download/202401060333/skiddie-clang-18.0.0-7c3bcc3-202401060333.tar.zst"

ZYCLANG_DIR="$WORKDIR/ZyClang/bin"

# Kernel Source
KERNEL_GIT="https://gitlab.com/hariphoenix1708/android_kernel_xiaomi_sweet"
KERNEL_BRANCHE="dev"
KERNEL_DIR="$WORKDIR/Phoenix"

# Anykernel3
ANYKERNEL3_GIT="https://github.com/pure-soul-kk/AnyKernel3"
ANYKERNEL3_BRANCHE="master"

# Build
DEVICES_CODE="sweet"
DEVICE_DEFCONFIG="vendor/sweet_defconfig"
DEVICE_DEFCONFIG_FILE="$KERNEL_DIR/arch/arm64/configs/$DEVICE_DEFCONFIG"
IMAGE="$KERNEL_DIR/out/arch/arm64/boot/Image.gz"
DTB="$KERNEL_DIR/out/arch/arm64/boot/dtb.img"
DTBO="$KERNEL_DIR/out/arch/arm64/boot/dtbo.img"

export KBUILD_BUILD_USER=Phoenix
export KBUILD_BUILD_HOST=GitHubCI

msg() {
	echo
	echo -e "\e[1;32m$*\e[0m"
	echo
}

cd $WORKDIR

# Download ZyClang
msg " • 🌸 Work on $WORKDIR 🌸"
msg " • 🌸 Cloning Toolchain 🌸 "
mkdir -p ZyClang
#aria2c -s16 -x16 -k1M $ZYCLANG_DLINK -o ZyClang.tar.gz
#tar -C ZyClang/ -zxvf ZyClang.tar.gz
#rm -rf ZyClang.tar.gz

# SKIDDIE CLANG
aria2c -s16 -x16 -k1M $ZYCLANG_DLINK -o ZyClang.tar.zst
tar --use-compress-program=unzstd -xvf ZyClang.tar.zst -C $WORKDIR/ZyClang
rm -rf ZyClang.tar.zst

# PROTON CLANG
### git clone https://github.com/kdrag0n/proton-clang.git -b master $WORKDIR/ZyClang

# CLANG LLVM VERSIONS
CLANG_VERSION="$($ZYCLANG_DIR/clang --version | head -n 1)"
LLD_VERSION="$($ZYCLANG_DIR/ld.lld --version | head -n 1)"

msg " • 🌸 Cloning Kernel Source 🌸 "
git clone --depth=1 $KERNEL_GIT -b $KERNEL_BRANCHE $KERNEL_DIR
#cd $KERNEL_DIR

# APATCH
msg " • 🌸 Apatch Patch 🌸 "
git clone https://github.com/Yervant7/Apatch_Action_template -b main yv
cd $KERNEL_DIR
chmod 755 kernel/module.c
git apply $WORKDIR/yv/module_fix.patch
cp -r $WORKDIR/yv/apatch $KERNEL_DIR
cd $KERNEL_DIR
echo " " >> arch/arm64/Kconfig
echo 'source "apatch/Kconfig"' >> arch/arm64/Kconfig
echo "CONFIG_APATCH_SUPPORT=y" >> $DEVICE_DEFCONFIG_FILE
echo "CONFIG_APATCH_FIX_MODULES=y" >> $DEVICE_DEFCONFIG_FILE
echo "CONFIG_APATCH_CUSTOMS=y" >> $DEVICE_DEFCONFIG_FILE
sed -i 's/CONFIG_LOCALVERSION_AUTO=y/CONFIG_LOCALVERSION_AUTO=n/' $DEVICE_DEFCONFIG_FILE


# CLANG CONFIG PATCH
msg " • 🌸 Clang Config Patch 🌸 "
sed -i 's/CONFIG_LTO_GCC=y/# CONFIG_LTO_GCC is not set/g' $DEVICE_DEFCONFIG_FILE 
sed -i 's/CONFIG_GCC_GRAPHITE=y/# CONFIG_GCC_GRAPHITE is not set/g' $DEVICE_DEFCONFIG_FILE
sed -i 's/CONFIG_CC_STACKPROTECTOR_STRONG=y/# CONFIG_CC_STACKPROTECTOR_STRONG is not set/g' $DEVICE_DEFCONFIG_FILE
echo "❗❗❗➡️DONE⬅️❗❗❗"

# BUILD KERNEL
msg " • 🌸 Started Compilation 🌸 "

args="PATH=$ZYCLANG_DIR:$PATH \
ARCH=arm64 \
CROSS_COMPILE=aarch64-linux-gnu- \
CROSS_COMPILE_COMPAT=arm-linux-gnueabi- \
CC=clang \
AR=llvm-ar \
NM=llvm-nm \
LD=ld.lld \
OBJDUMP=llvm-objdump \
STRIP=llvm-strip"

# LINUX KERNEL VERSION
rm -rf out
make O=out $args $DEVICE_DEFCONFIG
KERNEL_VERSION=$(make O=out $args kernelversion | grep "4.14")
msg " • 🌸 LINUX KERNEL VERSION : $KERNEL_VERSION 🌸 "
make O=out $args -j"$(nproc --all)"

msg " • 🌸 Packing Kernel 🌸 "
cd $WORKDIR
git clone --depth=1 $ANYKERNEL3_GIT -b $ANYKERNEL3_BRANCHE $WORKDIR/Anykernel3
cd $WORKDIR/Anykernel3
cp $IMAGE .
cp $DTB $WORKDIR/Anykernel3/dtb
cp $DTBO .

# PACK FILE
time=$(TZ='Asia/Kolkata' date +"%Y-%m-%d %H:%M:%S")
asia_time=$(TZ='Asia/Kolkata' date +%Y%m%d%H)
ZIP_NAME="Phoenix-$KERNEL_VERSION-KernelSU-$KERNELSU_VERSION.zip"
find ./ * -exec touch -m -d "$time" {} \;
zip -r9 $ZIP_NAME *
mkdir -p $WORKDIR/out && cp *.zip $WORKDIR/out

cd $WORKDIR/out
echo "
### Phoenix KERNEL With/Without KERNELSU
1. **Time** : $(TZ='Asia/Kolkata' date +"%Y-%m-%d %H:%M:%S") # Asian TIME
2. **Device Code** : $DEVICES_CODE
3. **LINUX Version** : $KERNEL_VERSION
4. **KERNELSU Version**: $KERNELSU_VERSION
5. **CLANG Version**: $CLANG_VERSION
6. **LLD Version**: $LLD_VERSION
" > RELEASE.md
echo "
### Phoenix KERNEL With/Without KERNELSU
1. **Time** : $(TZ='Asia/Kolkata' date +"%Y-%m-%d %H:%M:%S") # Asia TIME
2. **Device Code** : $DEVICES_CODE
3. **LINUX Version** : $KERNEL_VERSION
4. **KERNELSU Version**: $KERNELSU_VERSION
5. **CLANG Version**: ZyC clang version 18.0.0
6. **LLD Version**: LLD 18.0.0
" > telegram_message.txt
echo "Phoenix-$KERNEL_VERSION" > RELEASETITLE.txt
cat RELEASE.md
cat telegram_message.txt
cat RELEASETITLE.txt
msg "• 🌸 Done! 🌸 "