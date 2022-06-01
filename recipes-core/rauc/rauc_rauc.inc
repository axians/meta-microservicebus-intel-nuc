FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# additional dependencies required to run RAUC on the target
RDEPENDS:${PN} += "grub-editenv e2fsprogs-mke2fs"

do_install:prepend () {
  # Replace root block device name parameters
  sed -i -e 's:@ROOT_BLOCK_DEVICE_NAME@:${ROOT_BLOCK_DEVICE_NAME}:g' ${WORKDIR}/system.conf
}
