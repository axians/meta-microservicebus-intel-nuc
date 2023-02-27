
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://docker.service "

do_install:append() {
	install -m 644 ${WORKDIR}/docker.service ${D}/${systemd_unitdir}/system
}