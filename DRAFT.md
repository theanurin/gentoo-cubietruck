# Cubietruck powered by Gentoo

## Troubles

- UBoot output on VGA is not available if HDMI connected too (at least in default UBoot configuration)

## Locally

```shell
cd
git clone --depth 1 --branch v2023.04 https://source.denx.de/u-boot/u-boot.git
cd ~/u-boot

make Cubietruck_defconfig
make menuconfig
make "-j$(nproc)"
...
```

## Inside Docker container

```shell
docker run \
  --rm \
  --interactive \
  --tty \
  --platform=linux/arm/v7 \
  --volume $PWD/.uboot-build:/build \
  --entrypoint /bin/bash \
  ghcr.io/osfordev/preboot/toolchain/arm32v7:6.12.41

cd /opt/u-boot/
# See list of defconfig in /opt/u-boot/configs
make O=/build Cubietruck_defconfig

#
# Base settings
#
./scripts/config --file /build/.config --enable "CMD_CONFIG"
./scripts/config --file /build/.config --enable "CMD_PAUSE"
./scripts/config --file /build/.config --enable "CMD_SLEEP"
./scripts/config --file /build/.config --set-val "BOOTDELAY" "5"
./scripts/config --file /build/.config --set-str "DEFAULT_FDT_FILE" "sun7i-a20-cubietruck.dtb"
./scripts/config --file /build/.config --enable "BOOT_RETRY"
./scripts/config --file /build/.config --set-val "BOOT_RETRY_TIME" "30"
./scripts/config --file /build/.config --set-val "BOOT_RETRY_MIN" "5"
./scripts/config --file /build/.config --enable "RESET_TO_RETRY"
./scripts/config --file /build/.config --disable "ENV_IS_IN_FAT"
./scripts/config --file /build/.config --enable "ENV_IS_DEFAULT"
./scripts/config --file /build/.config --enable "ENV_IS_NOWHERE"
#
# Network boot support
#
./scripts/config --file /build/.config --enable "DNS"
./scripts/config --file /build/.config --enable "WGET"
./scripts/config --file /build/.config --enable "NET_LWIP" # Use lwIP for networking stack
./scripts/config --file /build/.config --enable "CMD_DHCP"
./scripts/config --file /build/.config --enable "CMD_DNS"  # Lookup the IP of a hostname
./scripts/config --file /build/.config --enable "CMD_TFTPBOOT" # /opt/u-boot/cmd/pxe.c:45:(.text.do_get_tftp+0x2c): undefined reference to `do_tftpb'
./scripts/config --file /build/.config --enable "CMD_WGET" # wget is a simple command to download kernel, or other files, from a http server over TCP.
./scripts/config --file /build/.config --disable "CMD_BOOTP" # do not need that
./scripts/config --file /build/.config --disable "EFI_HTTP_PROTOCOL"
./scripts/config --file /build/.config --disable "LWIP_ASSERT"
./scripts/config --file /build/.config --disable "LWIP_DEBUG"
./scripts/config --file /build/.config --disable "LWIP_DEBUG_RXTX"
./scripts/config --file /build/.config --enable "LWIP_ICMP_SHOW_UNREACH"
./scripts/config --file /build/.config --set-val "LWIP_TCP_WND" "3000000"
./scripts/config --file /build/.config --enable "PROT_TCP_SACK_LWIP"
#
# Пишемо "bootargs=" в пам'ять починаючи з 0x44000000
# Далі завантажуємо http://${serverip}:8000/cmdline по адресу 0x44000009
# та імпортуємо env import -t 0x44000000
# в результаті параметри ядра будуть
#
BOOTCOMMAND=$(cat <<'EOF' | grep -v '^#' | tr -d '\n' | tr -s ' ' | sed 's/"/\\\\"/g'
#
# Embedded boot.cmd
#

# Write text "bootargs=" into memory starts from 0x44000000
mw.b 0x44000000 0x62 1;
mw.b 0x44000001 0x6F 1;
mw.b 0x44000002 0x6F 1;
mw.b 0x44000003 0x74 1;
mw.b 0x44000004 0x61 1;
mw.b 0x44000005 0x72 1;
mw.b 0x44000006 0x67 1;
mw.b 0x44000007 0x73 1;
mw.b 0x44000008 0x3D 1;

if test -n "${distro_bootpart}"; then
  setenv bootpart ${distro_bootpart};
else
  setenv bootpart 1;
fi;
echo "Trying to load from boot partition...";
if load ${devtype} ${devnum}:${bootpart} 0x44000009 /cmdline; then
    echo "Kernel command line was load successfully from boot partition.";
    setexpr filesize ${filesize} + 9;
    env import -t 0x44000000 ${filesize} bootargs;
    sleep 60;
    reset;
else
    echo "Kernel command line was NOT load from boot partition.";
fi;

echo "Trying to load from OS For Dev web server...";
if dhcp; then
    setenv baseurl http://dl.zxteam.net/osfordev/boot/armv7l/cubietruck;
    if wget 0x44000009 ${baseurl}/cmdline; then
        echo "Kernel command line was load successfully from OS For Dev web server.";
        setexpr filesize ${filesize} + 9;
        env import -t 0x44000000 ${filesize} bootargs;
        echo "Trying to load kernel image from OS For Dev web server...";
        if wget ${kernel_addr_r} ${baseurl}/zImage; then
            echo "Kernel image was load successfully from OS For Dev web server.";
            echo "Trying to load FDT file from OS For Dev web server...";
            if wget ${fdt_addr_r} ${baseurl}/${fdtfile}; then
                echo "FDT file was load successfully from OS For Dev web server.";
                bootz ${kernel_addr_r} - ${fdt_addr_r};
            else
                echo "Unable to load FDT file from OS For Dev web server. Reset in 60 seconds...";
                sleep 60;
                reset;
            fi;
        else
            echo "Unable to load kernel image from OS For Dev web server. Reset in 60 seconds...";
            sleep 60;
            reset;
        fi;
    else
        echo "Kernel command line was NOT load from OS For Dev web server.";
    fi;
fi;

echo "Unable to load kernel from any supported sources. Reset in 60 seconds...";
sleep 60;
reset;
EOF
)
./scripts/config --file /build/.config --set-val "BOOTCOMMAND" "\"${BOOTCOMMAND}\""

make O=/build oldconfig

#make O=/build menuconfig

make O=/build -j$(nproc)

# Local boot
cat <<'EOF' > /build/boot-local.cmd
# перетворюється в boot.scr через mkimage
#   /build/tools/mkimage -A arm -T script -d /build/boot.cmd /build/boot.scr
#

#printenv -a
printenv distro_bootpart devtype devnum console uuid kernel_addr_r ramdisk_addr_r fdt_addr_r fdtfile
sleep 10
pause 'Prompt for pause...'

if test -n "${distro_bootpart}"; then
  setenv bootpart ${distro_bootpart}
else
  setenv bootpart 1
fi

setenv  bootargs console=ttyS0,115200 console=tty0 panic=10 rootfstype=ext4 rootflags=discard root=/dev/sda3 rootwait=30

if load ${devtype} ${devnum}:${bootpart} ${kernel_addr_r} /zImage; then
  if load ${devtype} ${devnum}:${bootpart} ${fdt_addr_r} /dtbs/${fdtfile}; then
    if load ${devtype} ${devnum}:${bootpart} ${ramdisk_addr_r} /initramfs-linux.img; then
      bootz ${kernel_addr_r} ${ramdisk_addr_r}:${filesize} ${fdt_addr_r};
    else
      bootz ${kernel_addr_r} - ${fdt_addr_r};
    fi;
  fi;
fi
EOF
/build/tools/mkimage -A arm -T script -d /build/boot-local.cmd /build/boot.scr


# Network boot
cat <<'EOF' > /build/boot-pxe.cmd
# перетворюється в boot.scr через mkimage
#   /build/tools/mkimage -A arm -T script -d /build/boot.cmd /build/boot.scr
#

# Obtain an IP address via DHCP.
dhcp

# Retrieve PXELINUX configuration files from the TFTP server.
pxe get

# Execute the boot commands specified in the pxelinux.cfg/default file.
pxe boot
EOF
/build/tools/mkimage -A arm -T script -d /build/boot-pxe.cmd /build/boot.scr


echo ",48M" | sfdisk --wipe always --label dos --no-reread --no-tell-kernel /dev/sdb
sfdisk --part-type /dev/sdb 1 0c

mkfs.vfat -F32 -nUBOOT /dev/sdb1

dd if=/tmp/u-boot-sunxi-with-spl.bin of=/dev/sdb bs=1k seek=8 conv=notrunc,sync && rm /tmp/u-boot-sunxi-with-spl.bin
mount /dev/sdb1 /mnt
mv /tmp/boot.scr /mnt/
cp /root/backup/nanda/uImage /mnt/
umount /dev/sdb1

eject /dev/sdb


make "-j$(nproc)" O=/build
[  ! -d /build ] && mkdir /build
cp /cache/u-boot/u-boot-sunxi-with-spl.bin /build/u-boot-sunxi-with-spl.bin

cat <<'EOF' > /build/boot.cmd
setenv bootargs console=ttyS0,115200 console=tty0 earlyprintk panic=10 ${extra}
load ${devtype} ${devnum}:${distro_bootpart} ${fdt_addr_r} /${fdtfile}
load ${devtype} ${devnum}:${distro_bootpart} ${kernel_addr_r} /zImage
load ${devtype} ${devnum}:${distro_bootpart} ${ramdisk_addr_r} /initramfs.cpio.gz
bootz ${kernel_addr_r} ${ramdisk_addr_r}:${filesize} ${fdt_addr_r}
EOF
/build/tools/mkimage -A arm -T script -d /build/boot.cmd /build/boot.scr


SD_CARD_DEV=/dev/sdb
dd if=/build/u-boot-sunxi-with-spl.bin of="${SD_CARD_DEV}" bs=1024 seek=8 conv=notrunc && rm /build/u-boot-sunxi-with-spl.bin

uboot.env
```

## Kernel

```shell
docker run --rm --interactive --tty \
      --platform linux/arm/v7 \
      --mount type=bind,source="~/w-osfordev/gentoo-overlay/profiles/cubietruck/kernel.config",target=/usr/src/linux-6.12.41-gentoo/.config \
      --mount type=bind,source="${PWD}/data-result",target=/data-result \
      theanurin/gentoo-sources-bundle:arm32v7-6.12.41

cd /usr/src/linux-6.12.41-gentoo/
make "-j$(nproc)"
cp arch/arm/boot/zImage                                  /data-result/zImage
cp arch/arm/boot/dts/allwinner/sun7i-a20-cubietruck.dtb  /data-result/sun7i-a20-cubietruck.dtb
```


- https://archlinuxarm.org/platforms/armv7/allwinner/cubietruck
- https://linux-sunxi.org/U-Boot
- https://linux-sunxi.org/Cubieboard/Installing_on_NAND
- https://guillaumeplayground.net/mele-a2000-headless-debian-wheezy-armhf-with-nand-install-v1/
- https://code.google.com/archive/p/cubieboard/downloads
- http://blog.anurin.name/2015/03/cubietruck-gentoo-installation.html



CONFIG_BOOTCOMMAND="mw.b 0x44000000 0x62 1;mw.b 0x44000001 0x6F 1;mw.b 0x44000002 0x6F 1;mw.b 0x44000003 0x74 1;mw.b 0x44000004 0x61 1;mw.b 0x44000005 0x72 1;mw.b 0x44000006 0x67 1;mw.b 0x44000007 0x73 1;mw.b 0x44000008 0x3D 1;if test -n \"${distro_bootpart}\"; then setenv bootpart \"${distro_bootpart}\";else setenv bootpart 1;fi;echo \"Trying to load from boot partition...\";if load ${devtype} ${devnum}:${bootpart} 0x44000009 /cmdline; then echo \"Kernel command line was load successfully from boot partition.\"; setexpr filesize ${filesize} + 9; env import -t 0x44000000 ${filesize} bootargs; sleep 60; reset;else echo \"Kernel command line was NOT load from boot partition.\";fi;echo \"Trying to load from OS For Dev web server...\";dhcp;setenv baseurl http://dl.zxteam.net/osfordev/boot/armv7l/cubietruck;if wget 0x44000009 ${baseurl}/cmdline; then echo \"Kernel command line was load successfully from OS For Dev web server.\"; setexpr filesize ${filesize} + 9; env import -t 0x44000000 ${filesize} bootargs; wget ${kernel_addr_r} ${baseurl}/zImage; wget ${fdt_addr_r} ${baseurl}/${fdtfile}; bootz ${kernel_addr_r} - ${fdt_addr_r};else echo \"Kernel command line was NOT load from OS For Dev web server.\";fi;"



# DDD

```text
# перетворюється в boot.scr через mkimage
#   /build/tools/mkimage -A arm -T script -d /build/boot-wget.cmd /build/boot.scr
#

# Obtain an IP address via DHCP.
dhcp

setenv serverip   192.168.0.20

wget ${kernel_addr_r}  http://${serverip}:8000/zImage
wget ${fdt_addr_r}     http://${serverip}:8000/${fdtfile}

sleep 3

bootz ${kernel_addr_r} - ${fdt_addr_r}
```

```shell
(cd bin-cubietruck/ && python3 -m http.server --bind 192.168.0.20 8000)
python3 -m http.server --bind 192.168.0.20 8000
```

```shell
docker run --rm --interactive --tty \
      --platform linux/arm/v7 \
      --env KCONFIG_CONFIG=/data/profiles/cubietruck/kernel-5.15.config \
      --env KBUILD_OUTPUT="/kernel-build-cache" \
      --volume kernel-build-cache-gentoo-5.15:/kernel-build-cache \
      --mount type=bind,source="${PWD}",target=/data \
      theanurin/gentoo-sources-bundle:arm32v7-5.15.177

cd /usr/src/linux

make menuconfig \
  && make -j$(nproc) zImage dtbs \
  && NOW=$(date '+%Y%m%d%H%M%S') \
  && mkdir "/data/bin-cubietruck/boot/gentoo-5.15-${NOW}" \
  && cp -r "${KCONFIG_CONFIG}"                                                    "/data/bin-cubietruck/boot/gentoo-5.15-${NOW}/config" \
  && cp /kernel-build-cache/arch/arm/boot/dts/sun7i-a20-cubietruck.dtb            "/data/bin-cubietruck/boot/gentoo-5.15-${NOW}/" \
  && cp /kernel-build-cache/arch/arm/boot/zImage                                  "/data/bin-cubietruck/boot/gentoo-5.15-${NOW}/" \
  && ln -sf "./boot/gentoo-5.15-${NOW}/sun7i-a20-cubietruck.dtb"                  "/data/bin-cubietruck/sun7i-a20-cubietruck.dtb" \
  && ln -sf "./boot/gentoo-5.15-${NOW}/zImage"                                    "/data/bin-cubietruck/zImage"
```

```shell
KERNEL_VERSION=6.12.58

docker run --rm --interactive --tty \
      --platform linux/arm/v7 \
      --env KBUILD_OUTPUT="/kernel-build-cache" \
      --volume kernel-build-cache-gentoo-${KERNEL_VERSION}:/kernel-build-cache \
      --mount type=bind,source="${PWD}",target=/data \
      theanurin/gentoo-sources-bundle:arm32v7-${KERNEL_VERSION}

export KCONFIG_CONFIG=/data/profiles/cubietruck/kernel-${KERNEL_VERSION}.config

make menuconfig \
  && make -j$(nproc) zImage modules dtbs \
  && NOW=$(date '+%Y%m%d%H%M%S') \
  && mkdir "/data/bin-cubietruck/boot/gentoo-${KERNEL_VERSION}-${NOW}" \
  && make INSTALL_MOD_PATH=/data/bin-cubietruck modules_install \
  && cp -r "${KCONFIG_CONFIG}"                                                    "/data/bin-cubietruck/boot/gentoo-${KERNEL_VERSION}-${NOW}/config" \
  && cp /kernel-build-cache/arch/arm/boot/dts/allwinner/sun7i-a20-cubietruck.dtb  "/data/bin-cubietruck/boot/gentoo-${KERNEL_VERSION}-${NOW}/" \
  && cp /kernel-build-cache/arch/arm/boot/zImage                                  "/data/bin-cubietruck/boot/gentoo-${KERNEL_VERSION}-${NOW}/" \
  && ln -sf "./boot/gentoo-${KERNEL_VERSION}-${NOW}/sun7i-a20-cubietruck.dtb"               "/data/bin-cubietruck/sun7i-a20-cubietruck.dtb" \
  && ln -sf "./boot/gentoo-${KERNEL_VERSION}-${NOW}/zImage"                                 "/data/bin-cubietruck/zImage"
```
