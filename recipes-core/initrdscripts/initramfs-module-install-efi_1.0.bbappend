FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

do_install:prepend () {
  # Replace root block device name parameters
  sed -i -e 's:@ROOT_BLOCK_DEVICE_NAME@:${ROOT_BLOCK_DEVICE_NAME}:g' ${WORKDIR}/init-install-efi.sh
}
