#!/bin/sh
#

./scripts/config --file .config --enable   "ARM_SMCCC"
./scripts/config --file .config --disable  "ANDROID_BOOT_IMAGE"
./scripts/config --file .config --disable  "ARM_SMCCC_FEATURES"
./scripts/config --file .config --set-val  "BOOTDELAY" "0"
./scripts/config --file .config --disable  "BOOTDEV_ETH"  # Provide a bootdev for ethernet so that is it possible to boot an operating system over the network, using the PXE (Preboot Execution Environment) protocol.
./scripts/config --file .config --disable  "BOOTMETH_EXTLINUX"
./scripts/config --file .config --disable  "BOOTMETH_VBE"
./scripts/config --file .config --enable   "BOOT_RETRY"
./scripts/config --file .config --set-val  "BOOT_RETRY_TIME" "300"
./scripts/config --file .config --set-val  "BOOT_RETRY_MIN" "5"
./scripts/config --file .config --enable   "CMD_CONFIG"
./scripts/config --file .config --disable  "CMD_BOOTD"
./scripts/config --file .config --disable  "CMD_BOOTM"
./scripts/config --file .config --disable  "CMD_BOOTP"    # bootp protocol
./scripts/config --file .config --disable  "CMD_BOOTFLOW"
./scripts/config --file .config --enable   "CMD_DHCP"
./scripts/config --file .config --enable   "CMD_DNS"      # Lookup the IP of a hostname
./scripts/config --file .config --disable  "CMD_HVC"
./scripts/config --file .config --enable   "CMD_PAUSE"
./scripts/config --file .config --disable  "CMD_PXE"      # Boot image via network using PXE protocol  
./scripts/config --file .config --enable   "CMD_SATA"
./scripts/config --file .config --enable   "CMD_SLEEP"
./scripts/config --file .config --disable  "CMD_SMC"
./scripts/config --file .config --enable   "CMD_TFTPBOOT" # net/lwip/dhcp.c:148: undefined reference to `do_tftpb'
./scripts/config --file .config --enable   "CMD_WGET"     # wget is a simple command to download kernel, or other files, from a http server over TCP.
./scripts/config --file .config --disable  "EFI_LOADER"
./scripts/config --file .config --disable  "EXPO"
./scripts/config --file .config --set-str  "DEFAULT_FDT_FILE" "sun7i-a20-cubietruck.dtb"
./scripts/config --file .config --disable  "DISTRO_DEFAULTS"
./scripts/config --file .config --enable   "DNS"          # Enable DNS resolutions
./scripts/config --file .config --disable  "EFI_BOOTMGR"
./scripts/config --file .config --disable  "EFI_HTTP_PROTOCOL"
./scripts/config --file .config --enable   "ENV_IS_DEFAULT"
./scripts/config --file .config --disable  "ENV_IS_IN_FAT"
./scripts/config --file .config --enable   "ENV_IS_NOWHERE"
./scripts/config --file .config --disable  "ISO_PARTITION"
./scripts/config --file .config --disable  "LEGACY_IMAGE_FORMAT"
./scripts/config --file .config --disable  "LWIP_ASSERT"
./scripts/config --file .config --disable  "LWIP_DEBUG"
./scripts/config --file .config --disable  "LWIP_DEBUG_RXTX"
./scripts/config --file .config --enable   "LWIP_ICMP_SHOW_UNREACH"
./scripts/config --file .config --set-val  "LWIP_TCP_WND" "3000000"
./scripts/config --file .config --enable   "NETDEVICES"   # Network device support
./scripts/config --file .config --disable  "NET"          # Legacy U-Boot networking stack
./scripts/config --file .config --enable   "NET_LWIP"     # Use lwIP for networking stack
./scripts/config --file .config --set-str  "PREBOOT" ""
./scripts/config --file .config --enable   "PROT_TCP_SACK_LWIP"
./scripts/config --file .config --enable   "RESET_TO_RETRY"
./scripts/config --file .config --enable   "SATA"
./scripts/config --file .config --disable  "SATA_CEVA"
./scripts/config --file .config --disable  "SCMI_FIRMWARE"
./scripts/config --file .config --disable  "SPL_FIRMWARE"
./scripts/config --file .config --disable  "SUPPORT_RAW_INITRD"
./scripts/config --file .config --disable  "SYSRESET_PSCI"
./scripts/config --file .config --disable  "USB"
./scripts/config --file .config --disable  "WDT_ARM_SMC"
./scripts/config --file .config --enable   "WGET"         # Enable wget   
