# TBD

## U-Boot

### Build Legacy U-Boot (with NAND support)

```shell
# On a host workstation
docker build --platform linux/arm/v7 --tag toolchain-u-boot-sunxi --file ./docker/Dockerfile.toolchain-u-boot-sunxi ./
(cd ./submodules/u-boot-sunxi/ && git checkout sunxi)
docker run --platform linux/arm/v7 --rm --interactive --tty --volume "${PWD}:/gentoo-cubietruck" toolchain-u-boot-sunxi

# Inside container
cd ./submodules/u-boot-sunxi/
make Cubietruck_config
make -j4

...TBD...
```

### Build latest (v2026.01) U-Boot

```shell
# On a host workstation
docker build --platform linux/arm/v7 --tag toolchain-u-boot-v2026.01 --file ./docker/Dockerfile.toolchain-u-boot-v2026.01 ./
(cd ./submodules/u-boot && git checkout v2026.01)
docker run --platform linux/arm/v7 --rm --interactive --tty --volume "${PWD}:/gentoo-cubietruck" toolchain-u-boot-v2026.01

# Inside container
cd ./submodules/u-boot
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

BOOTCOMMAND=$(cat ../../u-boot-script/sata.uboot | grep -v '^#' | tr -d '\n' | tr -s ' ' | sed 's/"/\\\\"/g')

./scripts/config --file .config --set-val "BOOTCOMMAND" "\"${BOOTCOMMAND}\""

make -j$(nproc)

exit

# On the host workstation
sudo dd if=./submodules/u-boot/u-boot-sunxi-with-spl.bin of=/dev/disk4 bs=1024 seek=8 conv=fsync
```

## Resources

- `resources/ct-nand-v1.01-20140214.img` - See [Nand Boot Android For Cubietruck](http://docs.cubieboard.org/tutorials/ct1/installation/cb3_a20-install_nand_boot_android_for_cubietruck). Got it from [Wayback Machine](https://web.archive.org/web/20260000000000*/http://dl.cubieboard.org/software/a20-cubietruck/android/ct-nand-v1.01-20140214.img.tar.gz).

## References

- [Tools](https://mega.nz/folder/ZtwxCCJC#AIYHcTqz-ucjuzKnE9qD7A/folder/cpZQEK7a) set on MEGA
