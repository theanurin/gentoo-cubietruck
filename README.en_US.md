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

#
# Or
#
../../u-boot-script/sata-config.sh
BOOTCOMMAND=$(cat ../../u-boot-script/sata.ubootcmd          | grep -v '^#' | tr -d '\n' | tr -s ' ' | sed 's/"/\\\\"/g')
#
# Or
#
../../u-boot-script/wget-osfordev-config.sh
BOOTCOMMAND=$(cat ../../u-boot-script/wget-osfordev.ubootcmd | grep -v '^#' | tr -d '\n' | tr -s ' ' | sed 's/"/\\\\"/g')
#

./scripts/config --file .config --set-val "BOOTCOMMAND" "\"${BOOTCOMMAND}\""

make oldconfig

make -j$(nproc)

exit

# On the host workstation
sudo dd if=./submodules/u-boot/u-boot-sunxi-with-spl.bin of=/dev/disk4 bs=1024 seek=8 conv=fsync
```

## Resources

- `resources/ct-nand-v1.01-20140214.img` - See [Nand Boot Android For Cubietruck](http://docs.cubieboard.org/tutorials/ct1/installation/cb3_a20-install_nand_boot_android_for_cubietruck). Got it from [Wayback Machine](https://web.archive.org/web/20260000000000*/http://dl.cubieboard.org/software/a20-cubietruck/android/ct-nand-v1.01-20140214.img.tar.gz).

## References

- [Tools](https://mega.nz/folder/ZtwxCCJC#AIYHcTqz-ucjuzKnE9qD7A/folder/cpZQEK7a) set on MEGA
