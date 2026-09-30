#!/bin/sh
mkimage -A arm -O linux -T script -C none -a 0 -e 0 -n "U-Boot Script" -d board/raspberrypi/boot.txt ${BINARIES_DIR}/rpi-firmware/boot.scr
exit 0