
SUMMARY = "Install docker-compose for Intel X86_64"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI += "file://docker-compose"
INSANE_SKIP_${PN} += "already-stripped"

S = "${WORKDIR}"

SYSTEMD_PACKAGES = "${PN}"

FILES_${PN} += "${bindir}/docker-compose"

do_install() {
    # Install docker-compose
    install -d ${D}${bindir}
    chmod +x ${WORKDIR}/docker-compose
    install -m 0777 ${WORKDIR}/docker-compose ${D}${bindir}/
}

