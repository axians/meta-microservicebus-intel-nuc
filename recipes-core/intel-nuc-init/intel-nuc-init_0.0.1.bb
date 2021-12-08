inherit systemd

SUMMARY = "Install init script for Intel NUC gateway"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI += "file://intel-nuc-init.service \
            file://intel-nuc-init.sh"

S = "${WORKDIR}"

SYSTEMD_PACKAGES = "${PN}"

SYSTEMD_SERVICE_${PN} = " intel-nuc-init.service"

FILES_${PN} += "${systemd_system_unitdir}/intel-nuc-init.service \
                ${bindir}/intel-nuc-init.sh"

do_install() {

    # Install service file
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/intel-nuc-init.service ${D}${systemd_system_unitdir}

    # Install script
    install -d ${D}${bindir}
    install -m 0550 ${WORKDIR}/intel-nuc-init.sh ${D}${bindir}/
}

REQUIRED_DISTRO_FEATURES= "systemd"

RDEPENDS_${PN} = "dmidecode"
