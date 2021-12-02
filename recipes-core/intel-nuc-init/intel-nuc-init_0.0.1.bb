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

# Dynamic parameters
MSB_HOME_DIR_PATH ??= "/data/home/msb"
MSB_NODE_USER ??= "msb"
MSB_NODE_GROUP ??= "msb"
RAUC_VAR_DIR ?= "/data/var/rauc"
IOTEDGE ??= "FALSE"

do_install() {
             
    # Replace parameters in script
    sed -i -e 's:@MSB_NODE_USER@:${MSB_NODE_USER}:g' ${WORKDIR}/intel-nuc-init.sh
    sed -i -e 's:@MSB_NODE_GROUP@:${MSB_NODE_GROUP}:g' ${WORKDIR}/intel-nuc-init.sh
    sed -i -e 's:@MSB_HOME_DIR_PATH@:${MSB_HOME_DIR_PATH}:g' ${WORKDIR}/intel-nuc-init.sh
    sed -i -e 's:@RAUC_VAR_DIR@:${RAUC_VAR_DIR}:g' ${WORKDIR}/intel-nuc-init.sh
    sed -i -e 's:@IOTEDGE@:${IOTEDGE}:g' ${WORKDIR}/intel-nuc-init.sh

    # Install service file
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/intel-nuc-init.service ${D}${systemd_system_unitdir}

    # Install script
    install -d ${D}${bindir}
    install -m 0550 ${WORKDIR}/intel-nuc-init.sh ${D}${bindir}/
}

REQUIRED_DISTRO_FEATURES= "systemd"

