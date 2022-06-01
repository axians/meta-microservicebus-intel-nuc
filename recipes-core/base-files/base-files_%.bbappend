FILESEXTRAPATHS:prepend := "${THISDIR}/${BPN}:"

# Add a mount point for a shared data partition
dirs755 += "/data"
dirs755 += "/grubenv"

do_install:prepend () {
  # Replace root block device name parameters
  sed -i -e 's:@ROOT_BLOCK_DEVICE_NAME@:${ROOT_BLOCK_DEVICE_NAME}:g' ${WORKDIR}/fstab
}
