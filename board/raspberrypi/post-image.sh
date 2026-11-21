#!/bin/bash

set -e

BOARD_DIR="$(dirname $0)"
BOARD_NAME="$(basename ${BOARD_DIR})"
GENIMAGE_CFG="${BOARD_DIR}/genimage-${BOARD_NAME}.cfg"
GENIMAGE_TMP="${BUILD_DIR}/genimage.tmp"

# generate genimage from template if a board specific variant doesn't exists
if [ ! -e "${GENIMAGE_CFG}" ]; then
	GENIMAGE_CFG="${BINARIES_DIR}/genimage.cfg"
	FILES=()

	for i in "${BINARIES_DIR}"/*.dtb "${BINARIES_DIR}"/rpi-firmware/*; do
		[ "$(basename "${i}")" = "boot.scr" ] && continue
		FILES+=( "${i#${BINARIES_DIR}/}" )
	done

	KERNEL=$(sed -n 's/^kernel=//p' "${BINARIES_DIR}/rpi-firmware/config.txt")
	FILES+=( "${KERNEL}" )

	FILES+=( "kernel.itb" )

	BOOT_FILES=$(printf '\\t\\t\\t"%s",\\n' "${FILES[@]}")
	sed "s|#BOOT_FILES#|${BOOT_FILES}|" "${BOARD_DIR}/genimage.cfg.in" \
		> "${GENIMAGE_CFG}"
fi

# Pass an empty rootpath. genimage makes a full copy of the given rootpath to
# ${GENIMAGE_TMP}/root so passing TARGET_DIR would be a waste of time and disk
# space. We don't rely on genimage to build the rootfs image, just to insert a
# pre-built one in the disk image.

trap 'rm -rf "${ROOTPATH_TMP}"' EXIT
ROOTPATH_TMP="$(mktemp -d)"

rm -rf "${GENIMAGE_TMP}"

cp "${BOARD_DIR}/kernel.its" "${BINARIES_DIR}/kernel.its"
mkimage -f "${BINARIES_DIR}/kernel.its" "${BINARIES_DIR}/kernel.itb"

# Generate InitRamFS (do NOT pre-create lib64 before cp -a since it is a symlink)
INITRAMFS_DIR="${BUILD_DIR}/initramfs"
rm -rf "${INITRAMFS_DIR}"
mkdir -p "${INITRAMFS_DIR}"/{dev,etc,newroot,proc,run,sys}
cp -a "${TARGET_DIR}"/{bin,sbin,lib,lib64,usr} "${INITRAMFS_DIR}/"
cp "${BOARD_DIR}/initramfs/init" "${INITRAMFS_DIR}/init"
chmod 755 "${INITRAMFS_DIR}/init"
cp "${BOARD_DIR}/rootfs_overlay/root/passphrase" "${INITRAMFS_DIR}/passphrase"
chmod 600 "${INITRAMFS_DIR}/passphrase"
(cd "${INITRAMFS_DIR}" && find . | cpio -H newc -o -R 0:0 --quiet | gzip) > "${BINARIES_DIR}/initramfs.cpio.gz"
mkimage -A arm64 -O linux -T ramdisk -C gzip -d "${BINARIES_DIR}/initramfs.cpio.gz" "${BINARIES_DIR}/uInitrd"

cp "${BOARD_DIR}/boot.cmd" "${BINARIES_DIR}/boot.cmd"
mkimage -C none -A arm64 -T script -d "${BINARIES_DIR}/boot.cmd" "${BINARIES_DIR}/boot.scr"

if [ -f "passphrase/rootfs.luks" ]; then
	cp passphrase/rootfs.luks "${BINARIES_DIR}/rootfs.luks"
elif [ ! -f "${BINARIES_DIR}/rootfs.luks" ]; then
	echo "ERROR: passphrase/rootfs.luks not found. Generate it first (see 6-codelab/repport.md)." >&2
	exit 1
fi

genimage \
	--rootpath "${ROOTPATH_TMP}"   \
	--tmppath "${GENIMAGE_TMP}"    \
	--inputpath "${BINARIES_DIR}"  \
	--outputpath "${BINARIES_DIR}" \
	--config "${GENIMAGE_CFG}"

exit $?
