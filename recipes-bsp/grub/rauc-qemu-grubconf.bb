SUMMARY = "Grub configuration file to use with RAUC"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

include conf/image-uefi.conf

RPROVIDES_${PN} += "virtual/grub-bootconf"

SRC_URI += " \
    file://grub.cfg \
    "

S = "${WORKDIR}"

inherit deploy

do_install() {
        install -d ${D}${EFI_FILES_PATH}
        install -m 644 ${WORKDIR}/grub.cfg ${D}${EFI_FILES_PATH}/grub.cfg
}

FILES_${PN} += "${EFI_FILES_PATH}"

do_deploy() {
	install -m 644 ${WORKDIR}/grub.cfg ${DEPLOYDIR}
}

addtask deploy after do_install before do_build
