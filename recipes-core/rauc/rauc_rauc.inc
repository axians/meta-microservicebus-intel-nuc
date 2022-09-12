FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# additional dependencies required to run RAUC on the target
RDEPENDS:${PN} += "grub-editenv e2fsprogs-mke2fs"

# Define compatible bundles (by default, same as RAUC)
MSB_BUNDLE_COMPATIBLE ?= "${RAUC_BUNDLE_COMPATIBLE}"

ROOT_BLOCK_DEVICE_NAME ?= "nvme0n1"

do_install:prepend () {
  # Replace root block device name parameters
  sed -i -e 's:@ROOT_BLOCK_DEVICE_NAME@:${ROOT_BLOCK_DEVICE_NAME}:g' ${WORKDIR}/system.conf

  # Replace compatible bundle parameter
  sed -i -e 's:@MSB_BUNDLE_COMPATIBLE@:${MSB_BUNDLE_COMPATIBLE}:g' ${WORKDIR}/system.conf
}
