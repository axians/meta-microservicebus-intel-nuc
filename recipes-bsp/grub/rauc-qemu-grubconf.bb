SUMMARY = "Grub configuration file to use with RAUC"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

include conf/image-uefi.conf

RPROVIDES:${PN} = "virtual-grub-bootconf"

SRC_URI += " \
    file://grub.cfg \
    "

S = "${WORKDIR}"

BOOT_CMDLINE ?= "console=ttyS0,115200 net.ifnames=0 panic=60"

inherit deploy

do_install() {
  # Replace root block device name and boot cmdline parameters
  sed -i -e 's:@ROOT_BLOCK_DEVICE_NAME@:${ROOT_BLOCK_DEVICE_NAME}:g' ${WORKDIR}/grub.cfg
  sed -i -e 's:@BOOT_CMDLINE@:${BOOT_CMDLINE}:g' ${WORKDIR}/grub.cfg

  # Install grub.cfg file
  install -d ${D}${EFI_FILES_PATH}
  install -m 644 ${WORKDIR}/grub.cfg ${D}${EFI_FILES_PATH}/grub.cfg
}

FILES:${PN} = "${EFI_FILES_PATH}/grub.cfg"

do_deploy() {
	install -m 644 ${WORKDIR}/grub.cfg ${DEPLOYDIR}
}

addtask deploy after do_install before do_build
