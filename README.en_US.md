# TBD

## U-Boot

### Build Legacy U-Boot

```shell
# On a host workstation
docker build --platform linux/arm/v7 --tag toolchain-u-boot-sunxi --file ./docker/Dockerfile.toolchain-u-boot-sunxi ./
docker run --platform linux/arm/v7 --rm --interactive --tty --volume "${PWD}:/gentoo-cubietruck" toolchain-u-boot-sunxi

# Inside container
cd ./submodules/u-boot-sunxi/
make Cubietruck_config
make -j$(nproc)

...TBD...
```

### Build latest (v2026.01) U-Boot

```shell
# On a host workstation: Prepare and launch build container
docker build --platform linux/arm/v7 --tag toolchain-u-boot-v2026.01 --file ./docker/Dockerfile.toolchain-u-boot-v2026.01 ./
(cd ./submodules/u-boot && git checkout v2026.01)
docker run --platform linux/arm/v7 --rm --interactive --tty --volume "${PWD}:/gentoo-cubietruck" toolchain-u-boot-v2026.01

# Inside container: make U-Boot binary file u-boot-sunxi-with-spl.bin
cd ./submodules/u-boot
make Cubietruck_defconfig

#
# Or: Embed bootcmd script for MMC boot
#
../../u-boot-script/mmc-config.sh
BOOTCOMMAND=$(cat ../../u-boot-script/mmc.ubootcmd           | grep -v '^#' | tr -d '\n' | tr -s ' ' | sed 's/"/\\\\"/g')
#
# Or: Embed bootcmd script for SATA/SCSI boot
#
../../u-boot-script/scsi-config.sh
BOOTCOMMAND=$(cat ../../u-boot-script/scsi.ubootcmd          | grep -v '^#' | tr -d '\n' | tr -s ' ' | sed 's/"/\\\\"/g')
#
# Or: Embed bootcmd script for network boot via wget
#
../../u-boot-script/wget-osfordev-config.sh
BOOTCOMMAND=$(cat ../../u-boot-script/wget-osfordev.ubootcmd | grep -v '^#' | tr -d '\n' | tr -s ' ' | sed 's/"/\\\\"/g')
#
#
#

./scripts/config --file .config --set-val "BOOTCOMMAND" "\"${BOOTCOMMAND}\""

# Optional (for debug purposes)
./scripts/config --file .config --set-val "BOOTDELAY" "5"

make oldconfig

make -j$(nproc)

exit

# On the host workstation: Write U-Boot binary into SD-card(/dev/disk4)
sudo dd if=./submodules/u-boot/u-boot-sunxi-with-spl.bin of=/dev/disk4 bs=1024 seek=8 conv=fsync
```

### Use NAND version of U-Boot

My Cubietruck ships with proprietary Boot0/Boot1 `2.0.0` along with legacy U-Boot based on `2011.09-rc1`

```text
U-Boot 2011.09-rc1-00000-gf75abad-dirty (Oct 21 2013 - 18:44:22) Allwinner Technology
arm-linux-gnueabihf-gcc (Ubuntu/Linaro 4.6.3-1ubuntu5) 4.6.3
GNU ld (GNU Binutils for Ubuntu) 2.22
```

I did made several attempts to make U-Boot `2026.01` to work with Boot0/Boot1 but no luck. U-Boot hangs...

Finally I found solution to use this legacy U-Boot for launch recent Linux Kernel 6.17 (see kernel section for configuration details):

- Build `uImage-6.17.13-gentoo-cubietruck`
- Add `uImage-6.17.13-gentoo-cubietruck` to boot(first) partition of NAND
- Update `uEnv.txt`
    ```shell
    mv /boot/uEnv.txt /boot/uEnv.txt.bak
    cat <<EOF > /boot/uEnv.txt
    kernel=/uImage-6.17.13-gentoo-cubietruck
    console=ttyS0,115200
    nand_root=/dev/sda2
    loadscriptbin=true
    extraargs=panic=45 mem=2016M net.ifnames=0 console=tty0 rootfstype=ext4 rootflags=discard rootwait=60
    EOF
    ```

My file set looks like:

```text
root@cubietruck:~# ls -l /boot/ && ls -l /boot/linux/
total 16286
-rwxr-xr-x 1 root root   118912 Jan  1  1980 boot.axf
-rwxr-xr-x 1 root root      106 Jan  1  1980 boot.ini
-rwxr-xr-x 1 root root   121680 Jan  1  1980 boot_signature.axf
-rwxr-xr-x 1 root root   222916 Jan  1  1980 drv_de.drv
-rwxr-xr-x 1 root root   233924 Jan  1  1980 drv_hdmi.drv
-rwxr-xr-x 1 root root   344813 Jan  1  1980 font24.sft
-rwxr-xr-x 1 root root   357443 Jan  1  1980 font32.sft
drwxr-xr-x 2 root root     2048 Mar  5 16:35 linux
-rwxr-xr-x 1 root root      512 Jan  1  1980 magic.bin
drwxr-xr-x 2 root root     2048 Jan  1  1980 os_show
-rwxr-xr-x 1 root root   226316 Jan  1  1980 prvt.axf
-rwxr-xr-x 1 root root    46284 Jan  1  1980 script.bin
-rwxr-xr-x 1 root root   288028 Jan  1  1980 sprite.axf
-rwxr-xr-x 1 root root      203 Mar 14 11:55 uEnv.txt
-rwxr-xr-x 1 root root      185 Mar 14 11:44 uEnv.txt.bak
-rwxr-xr-x 1 root root 10121214 Mar 14 09:08 uImage-6.17.13-gentoo-cubietruck
-rwxr-xr-x 1 root root  4572712 Jan  1  1980 uImage
total 364
-rwxr-xr-x 1 root root  57654 Jan  1  1980 linux.bmp
-rwxr-xr-x 1 root root    214 Jan  1  1980 linux.ini
-rwxr-xr-x 1 root root 309340 Jan  1  1980 u-boot.bin
```

## Linux

### Gentoo Sources

I use Docker to build kernel

```shell
KERNEL_VERSION=6.17.13

docker run --rm --interactive --tty --platform linux/arm/v7 \
  --mount type=bind,source="${PWD}",target=/data \
  --env KBUILD_OUTPUT="/kernel-build-cache" \
  --env KCONFIG_CONFIG="/kernel-build-cache/.config" \
  --volume kernel-build-cache-gentoo-cubietruck-${KERNEL_VERSION}:/kernel-build-cache \
  theanurin/gentoo-sources-bundle:arm32v7-${KERNEL_VERSION}
```

### Kernel Patching

```shell
#
# Patch kernel DTS
#
# Fix kernel errors: supply xxxx not found, using dummy regulator
#
sed --in-place '/\tgpio = <&pio 7 12 GPIO_ACTIVE_HIGH>;/a \\tregulator-boot-on;\n\tregulator-always-on;' arch/arm/boot/dts/allwinner/sun7i-a20-cubietruck.dts
sed --in-place '/\ttarget-supply = <&reg_ahci_5v>;/a \\tahci-supply = <&reg_ahci_5v>;\n\tphy-supply = <&reg_ahci_5v>;' arch/arm/boot/dts/allwinner/sun7i-a20-cubietruck.dts
sed --in-place '/\tpinctrl-0 = <&clk_out_a_pin>;/a \\tvcc-pa-supply = <&reg_vcc3v3>;\n\tvcc-pb-supply = <&reg_vcc3v3>;\n\tvcc-pf-supply = <&reg_vcc3v3>;\n\tvcc-ph-supply = <&reg_vcc3v3>;\n\tvcc-pi-supply = <&reg_vcc3v3>;' arch/arm/boot/dts/allwinner/sun7i-a20-cubietruck.dts
#
# LED configuration
#
sed --in-place 's~\t\t\tlabel = "cubietruck:blue:usr";~\t\t\tlabel = "cubietruck:blue:usr"; default-state = "on";~g' arch/arm/boot/dts/allwinner/sun7i-a20-cubietruck.dts
sed --in-place 's~\t\t\tlabel = "cubietruck:orange:usr";~\t\t\tlabel = "cubietruck:orange:usr"; default-state = "off"; linux,default-trigger = "heartbeat";~g' arch/arm/boot/dts/allwinner/sun7i-a20-cubietruck.dts
sed --in-place 's~\t\t\tlabel = "cubietruck:white:usr";~\t\t\tlabel = "cubietruck:white:usr"; default-state = "off"; linux,default-trigger = "heartbeat";~g' arch/arm/boot/dts/allwinner/sun7i-a20-cubietruck.dts
sed --in-place 's~\t\t\tlabel = "cubietruck:green:usr";~\t\t\tlabel = "cubietruck:green:usr"; default-state = "off"; linux,default-trigger = "heartbeat";~g' arch/arm/boot/dts/allwinner/sun7i-a20-cubietruck.dts
# Double check
cat arch/arm/boot/dts/allwinner/sun7i-a20-cubietruck.dts | grep -A4 -B1 'target-supply = <&reg_ahci_5v>;'
cat arch/arm/boot/dts/allwinner/sun7i-a20-cubietruck.dts | grep -A4 -B1 'gpio = <&pio 7 12 GPIO_ACTIVE_HIGH>;'
cat arch/arm/boot/dts/allwinner/sun7i-a20-cubietruck.dts | grep -A7 -B2 'pinctrl-0 = <&clk_out_a_pin>;'
cat arch/arm/boot/dts/allwinner/sun7i-a20-cubietruck.dts | grep 'label = "cubietruck:'
```

### General Configuration

```shell
make sunxi_defconfig

./scripts/config --file "${KCONFIG_CONFIG}" --set-str "CONFIG_LOCALVERSION" "-cubietruck"
./scripts/config --file "${KCONFIG_CONFIG}" --disable "CONFIG_LOCALVERSION_AUTO"

make oldconfig
```

### Alternative configuration

Alternatively you may use predefined config from [OS For Dev repo](https://github.com/osfordev/gentoo-overlay/tree/dev/profiles/cubietruck)

```shell
KERNEL_VERSION=6.17.13

wget --output-document="${KCONFIG_CONFIG}" "https://raw.githubusercontent.com/osfordev/gentoo-overlay/refs/heads/dev/profiles/cubietruck/config-${KERNEL_VERSION}-gentoo-cubietruck"
```

### Build for SD card boot

```shell
rm -rf "/data/.build/cubietruck-${KERNEL_VERSION}"

make --jobs=$(nproc) zImage modules dtbs

make INSTALL_MOD_PATH="/data/.build/${KERNEL_VERSION}" modules_install
mkdir "/data/.build/${KERNEL_VERSION}/boot"
cp --dereference "${KBUILD_OUTPUT}/arch/arm/boot/zImage" "/data/.build/${KERNEL_VERSION}/boot/zImage-${KERNEL_VERSION}-gentoo-cubietruck"
cp --dereference "${KBUILD_OUTPUT}/arch/arm/boot/dts/allwinner/sun7i-a20-cubietruck.dtb" "/data/.build/${KERNEL_VERSION}/boot/sun7i-a20-cubietruck-${KERNEL_VERSION}-gentoo.dtb"
cp --dereference "${KCONFIG_CONFIG}" "/data/.build/${KERNEL_VERSION}/boot/config-${KERNEL_VERSION}-gentoo-cubietruck"
cp --dereference "${KBUILD_OUTPUT}/System.map" "/data/.build/${KERNEL_VERSION}/boot/System-${KERNEL_VERSION}-gentoo-cubietruck.map"
```

### Build for boot via legacy U-Boot (NAND)

!!! [NOTE] In this setup only 1 CPU is available. No-luck with second CPU, due to `All CPU(s) started in SVC mode` instead `All CPU(s) started in HYP mode.`.

1. Install U-Boot tools
    ```shell
    # If you need uImage
    emerge-webrsync
    unset KCONFIG_CONFIG
    emerge --ask dev-embedded/u-boot-tools
    export KCONFIG_CONFIG="/kernel-build-cache/.config"
    ```
1. Setup clock frequency `clock-frequency = <24000000>` (required to use legacy NAND U-Boot)
    ```shell
    sed --in-place 's~compatible = "arm,armv7-timer";~compatible = "arm,armv7-timer"; clock-frequency = <24000000>;~g' arch/arm/boot/dts/allwinner/sun7i-a20.dtsi
    cat arch/arm/boot/dts/allwinner/sun7i-a20.dtsi | grep 'compatible = "arm,armv7-timer";'
    ```
1. ... `enable-method = "allwinner,sun7i-a20-smp"; in arch/arm/boot/dts/allwinner/sun7i-a20.dtsi
enable-method = "allwinner,sun7i-a20-mc-smp";
1. Update kernel config
    ```shell
    ./scripts/config --file "${KCONFIG_CONFIG}" --enable   "ARM_APPENDED_DTB"
    ./scripts/config --file "${KCONFIG_CONFIG}" --enable   "ARM_ATAG_DTB_COMPAT"
    ./scripts/config --file "${KCONFIG_CONFIG}" --disable  "ARM_ATAG_DTB_COMPAT_CMDLINE_FROM_BOOTLOADER"
    ./scripts/config --file "${KCONFIG_CONFIG}" --enable   "ARM_ATAG_DTB_COMPAT_CMDLINE_EXTEND"
    make oldconfig
    ```

    To enable debug messages you may want `DEBUG_LL`, `DEBUG_SUNXI_UART0`, `DEBUG_UART_8250`, `EARLY_PRINTK`
1. Build
    ```shell
    make --jobs=$(nproc) zImage modules dtbs

    cat "${KBUILD_OUTPUT}/arch/arm/boot/zImage" "${KBUILD_OUTPUT}/arch/arm/boot/dts/allwinner/sun7i-a20-cubietruck.dtb" > "${KBUILD_OUTPUT}/arch/arm/boot/zImage-with-dtb"
    mkimage -A arm -O linux -T kernel -C none -a 0x40008000 -e 0x40008000 -n "Linux-${KERNEL_VERSION}-Gentoo" -d "${KBUILD_OUTPUT}/arch/arm/boot/zImage-with-dtb" "${KBUILD_OUTPUT}/arch/arm/boot/uImage"

    make INSTALL_MOD_PATH="/data/.build/${KERNEL_VERSION}" modules_install
    (cd "/data/.build/${KERNEL_VERSION}" && tar -czvpf "modules-${KERNEL_VERSION}-gentoo-cubietruck.tar.gz" "lib/modules/${KERNEL_VERSION}-gentoo-cubietruck")

    mkdir --parents "/data/.build/${KERNEL_VERSION}/boot"
    cp --dereference "${KBUILD_OUTPUT}/arch/arm/boot/uImage" "/data/.build/${KERNEL_VERSION}/boot/uImage-${KERNEL_VERSION}-gentoo-cubietruck"
    cp --dereference "${KCONFIG_CONFIG}" "/data/.build/${KERNEL_VERSION}/boot/config-${KERNEL_VERSION}-gentoo-cubietruck"
    cp --dereference "${KBUILD_OUTPUT}/System.map" "/data/.build/${KERNEL_VERSION}/boot/System-${KERNEL_VERSION}-gentoo-cubietruck.map"
    ```

## NAND usage

To modify data in NAND partition I use legacy Lubuntu release(see resources/lubuntu/) for Cubietruck burned to SD-card.
It includes `nand-part` tool for manage NAND partitions.

- Unfortunately this Lubuntu release does not have `mkfs.vfat` tool to make file system. So we heed another Linux workstation to create partition image
    ```shell
    dd if=/dev/zero of=nanda-20260324.img bs=512 count=131072
    losetup --show --find nanda.img # expected /dev/loop0
    mkfs.vfat -n BOOT -F 16 /dev/loop0
    mount /dev/loop0 /mnt
    tar -xzvf nanda-fs-20260324.tar.gz -C /mnt/
    umount /mnt
    losetup --detach /dev/loop0
    gzip nanda-20260324.img
    ```
    Copy `nanda-20260324.img.gz` to Lubuntu SD card.
- Setup partitions
    ```shell
    root@cubietruck:~# dd if=/dev/zero of=/dev/nand bs=8M
    root@cubietruck:~# reboot
    ...
    root@cubietruck:~# nand-part -f a20 /dev/nand 32768 'bootloader 14909440 0'
    ...
    root@cubietruck:~# reboot
    ...
    root@cubietruck:~# nand-part -f a20
    check partition table copy 0: mbr: version 0x00000200, magic softw411
    OK
    check partition table copy 1: mbr: version 0x00000200, magic softw411
    OK
    check partition table copy 2: mbr: version 0x00000200, magic softw411
    OK
    check partition table copy 3: mbr: version 0x00000200, magic softw411
    OK
    mbr: version 0x00000200, magic softw411
    1 partitions
    partition  1: class =         DISK, name =   bootloader, partition start =    32768, partition size =   14909440 user_type=0
    ```
- Write partition
    ```shell
    root@cubietruck:~# zcat nanda-20260324.img.gz | dd of=/dev/nanda bs=8M
    ```
- Mount `/dev/nanda` to modify files

## Resources

- `resources/ct-nand-v1.01-20140214.img` - See [Nand Boot Android For Cubietruck](http://docs.cubieboard.org/tutorials/ct1/installation/cb3_a20-install_nand_boot_android_for_cubietruck). Got it from [Wayback Machine](https://web.archive.org/web/20260000000000*/http://dl.cubieboard.org/software/a20-cubietruck/android/ct-nand-v1.01-20140214.img.tar.gz).

## References

- [Tools](https://mega.nz/folder/ZtwxCCJC#AIYHcTqz-ucjuzKnE9qD7A/folder/cpZQEK7a) set on MEGA
- [https://linux-sunxi.org/Installing_to_NAND](Installing to NAND)
