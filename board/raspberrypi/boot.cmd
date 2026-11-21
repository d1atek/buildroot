setenv bootargs console=tty1 console=ttyAMA0,115200 root=/dev/mapper/luks_rootfs rootwait
fatload mmc 0:1 ${kernel_addr_r} Image
fatload mmc 0:1 0x10000000 uInitrd
booti ${kernel_addr_r} 0x10000000 ${fdt_addr}
