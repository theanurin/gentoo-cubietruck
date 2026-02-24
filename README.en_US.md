# TBD



## Build Legacy U-Boot (with NAND support)

```shell
$ cd submodules/u-boot-sunxi/

$ docker build --platform linux/arm/v7 --tag toolchain-u-boot-sunxi --file ../../docker/Dockerfile.toolchain-u-boot-sunxi ../..
[+] Building 15.4s (6/7) docker:desktop-linux
 => [internal] load build definition from Dockerfile.toolchain-u-boot-sunxi
...
 => exporting to image
 => => exporting layers
 => => writing image sha256:544814f65579729691ec21fedf33bf422e6c9c563a4584476941ee5b9f81cd33
 => => naming to docker.io/library/toolchain-u-boot-sunxi

$ docker run --rm -it -v "${PWD}:/u-boot-sunxi" toolchain-u-boot-sunxi

# cd /u-boot-sunxi/

root@1000e46923bf:/u-boot-sunxi# make Cubietruck_config
Configuring for Cubietruck - Board: sun7i, Options: CUBIETRUCK,SPL,SUNXI_GMAC,RGMII,STATUSLED=245,STATUSLED1=244,STATUSLED2=235,STATUSLED3=231,FAST_MBUS

# make -j4


```

### Build latest (v2026.01) U-Boot

```shell
# On a host workstation
docker build --platform linux/arm/v7 --tag toolchain-u-boot-v2026.01 --file ./docker/Dockerfile.toolchain-u-boot-v2026.01 ./
cd submodules/u-boot
git checkout v2026.01
docker run --platform linux/arm/v7 --rm -it -v "${PWD}:/u-boot" toolchain-u-boot-v2026.01

# Inside container
make Cubietruck_defconfig

./scripts/config --file .config --enable   "ARM_SMCCC"
./scripts/config --file .config --disable  "ANDROID_BOOT_IMAGE"
./scripts/config --file .config --disable  "ARM_SMCCC_FEATURES"
./scripts/config --file .config --set-val  "BOOTDELAY" "0"
./scripts/config --file .config --disable  "BOOTDEV_ETH"
./scripts/config --file .config --disable  "BOOTMETH_EXTLINUX"
./scripts/config --file .config --disable  "BOOTMETH_VBE"
./scripts/config --file .config --disable  "EFI_LOADER"
./scripts/config --file .config --disable  "EXPO"
./scripts/config --file .config --set-str  "DEFAULT_FDT_FILE" "sun7i-a20-cubietruck.dtb"
./scripts/config --file .config --disable  "DISTRO_DEFAULTS"
./scripts/config --file .config --disable  "EFI_BOOTMGR"
./scripts/config --file .config --disable  "ENV_IS_IN_FAT"
./scripts/config --file .config --enable   "BOOT_RETRY"
./scripts/config --file .config --set-val  "BOOT_RETRY_TIME" "300"
./scripts/config --file .config --set-val  "BOOT_RETRY_MIN" "5"
./scripts/config --file .config --enable   "CMD_CONFIG"
./scripts/config --file .config --disable  "CMD_BOOTD"
./scripts/config --file .config --disable  "CMD_BOOTM"
./scripts/config --file .config --disable  "CMD_BOOTFLOW"
./scripts/config --file .config --enable   "CMD_SATA"
./scripts/config --file .config --enable   "CMD_PAUSE"
./scripts/config --file .config --enable   "CMD_SLEEP"
./scripts/config --file .config --disable  "CMD_HVC"
./scripts/config --file .config --disable  "CMD_SMC"
./scripts/config --file .config --disable  "ISO_PARTITION"
./scripts/config --file .config --disable  "LEGACY_IMAGE_FORMAT"
./scripts/config --file .config --disable  "NETDEVICES"
./scripts/config --file .config --disable  "NET"
./scripts/config --file .config --enable   "NO_NET"
./scripts/config --file .config --disable  "PHYLIB"
./scripts/config --file .config --disable  "PHY_ADDR_ENABLE"
./scripts/config --file .config --disable  "PHY_REALTEK"
./scripts/config --file .config --set-str  "PREBOOT"
./scripts/config --file .config --enable   "RESET_TO_RETRY"
./scripts/config --file .config --enable   "SATA"
./scripts/config --file .config --disable  "SATA_CEVA"
./scripts/config --file .config --disable  "SCMI_FIRMWARE"
./scripts/config --file .config --disable  "SPL_FIRMWARE"
./scripts/config --file .config --disable  "SUPPORT_RAW_INITRD"
./scripts/config --file .config --disable  "SYSRESET_PSCI"
./scripts/config --file .config --disable  "USB"
./scripts/config --file .config --disable  "WDT_ARM_SMC"

make oldconfig

BOOTCOMMAND=$(cat <<'EOF' | grep -v '^#' | tr -d '\n' | tr -s ' ' | sed 's/"/\\\\"/g'
#
# Embedded boot.cmd
#

gpio clear 231;
gpio clear 235;
gpio clear 244;

gpio set 245;

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

echo "Trying to load from SATA partition 1 ...";
scsi scan;
setenv scsi_dev 0;
setenv scsi_partition 1;
sleep 1;

echo "[I] Trying to load kernel image /boot/vmlinuz from SATA partition ${scsi_partition} ...";
if ext4load scsi ${scsi_dev}:${scsi_partition} ${kernel_addr_r} /boot/vmlinuz; then
  echo "[I] Kernel image /boot/vmlinuz was load successfully from SATA partition ${scsi_partition}.";
  gpio set 244;
  sleep 1;

  echo "[I] Trying to load kernel Device-Tree Blob /boot/sun7i-a20-cubietruck.dtb from SATA partition ${scsi_partition} ...";
  if ext4load scsi ${scsi_dev}:${scsi_partition} ${fdt_addr_r} /boot/sun7i-a20-cubietruck.dtb; then
    echo "[I] Kernel Device-Tree Blob /boot/sun7i-a20-cubietruck.dtb was load successfully from SATA partition ${scsi_partition}.";
    gpio set 235;
    sleep 1;

    echo "[I] Trying to load command line file /boot/cmdline from SATA partition ${scsi_partition} ...";
    if ext4load scsi ${scsi_dev}:${scsi_partition} 0x44000009 /boot/cmdline; then
      echo "[I] Kernel command line file /boot/cmdline was load successfully from SATA partition ${scsi_partition}.";
      setexpr filesize ${filesize} + 9;
      env import -t 0x44000000 ${filesize} bootargs;
      echo "[I] Loaded boot arguments: ${bootargs}";
    else
      echo "[W] Kernel command line file /boot/cmdline file was NOT load from SATA partition ${scsi_partition}.";
      setenv bootargs console=ttyS0,115200 console=tty0 panic=60 rootfstype=ext4 rootflags=discard root=/dev/sda2 rootwait;
      echo "[I] Using default boot arguments: ${bootargs}";
    fi;

    echo "[I] Starting Linux ...";
    gpio set 231;
    bootz ${kernel_addr_r} - ${fdt_addr_r};
  else
    echo "[E] Kernel Device-Tree Blob /boot/sun7i-a20-cubietruck.dtb was NOT load from SATA partition ${scsi_partition}.";
  fi;
else
  echo "[E] Kernel image /boot/vmlinuz was NOT load from SATA partition ${scsi_partition}.";
fi;

echo "[E] Unable to boot. Reset in 60 seconds...";
sleep 60;
reset;
EOF
)
./scripts/config --file .config --set-val "BOOTCOMMAND" "\"${BOOTCOMMAND}\""

make -j4

exit

# On the host workstation
sudo dd if=./u-boot-sunxi-with-spl.bin of=/dev/disk4 bs=1024 seek=8 conv=fsync
```


## Step 1 - Wake up the board

1. Download old [U-Boot](https://fl.us.mirror.archlinuxarm.org/os/sunxi/boot/cubietruck/u-boot-sunxi-with-spl.bin) for the board (with NAND support)
   ```shell
   mkdir ./res
   wget -qO ./res/archlinux-cubietruck-u-boot-sunxi-with-spl.bin https://fl.us.mirror.archlinuxarm.org/os/sunxi/boot/cubietruck/u-boot-sunxi-with-spl.bin
   ```
1. Build 
   ```shell
   brew install dtc pkg-config libusb
   cd submodules/sunxi-tools/
   export CFLAGS="-I/opt/homebrew/include"
   export LDFLAGS="-L/opt/homebrew/lib"
   make clean          # очистити попередні спроби
   make

   ```


1. Download Android NAND image `ct-nand-v1.01-20140214.img.tar.gz`. Originally it was available at http://dl.cubieboard.org/software/a20-cubietruck/android/ct-nand-v1.01-20140214.img.tar.gz. Get it from Wayback Machine https://web.archive.org/web/20260000000000*/http://dl.cubieboard.org/software/a20-cubietruck/android/ct-nand-v1.01-20140214.img.tar.gz
1. Flash Cubietruck NAND. I use MacBook Air M1 (Sonoma v14.5)
   ```shell
   cd ~/Downloads
   tar -xzf ct-nand-v1.01-20140214.img.tar.gz
   brew install dtc pkg-config libusb
   ```

## Resources

- `resources/ct-nand-v1.01-20140214.img` - See [Nand Boot Android For Cubietruck](http://docs.cubieboard.org/tutorials/ct1/installation/cb3_a20-install_nand_boot_android_for_cubietruck). Got it from [Wayback Machine](https://web.archive.org/web/20260000000000*/http://dl.cubieboard.org/software/a20-cubietruck/android/ct-nand-v1.01-20140214.img.tar.gz).

## References

- [Tools](https://mega.nz/folder/ZtwxCCJC#AIYHcTqz-ucjuzKnE9qD7A/folder/cpZQEK7a) set on MEGA
    