FILESEXTRAPATHS_prepend := "${THISDIR}/${BPN}:"

# Add a mount point for a shared data partition
dirs755 += "/data"
dirs755 += "/grubenv"

SRC_URI_append = " \
  file://dot.bashrc \
  "
RDEPENDS_${PN} += " bash"

do_install_append () {
    sed -i -e 's:@RAUC_BUNDLE_VERSION@:${RAUC_BUNDLE_VERSION}:g' ${WORKDIR}/dot.bashrc
    install -d ${D}${sysconfdir}/profile.d/
    install -m 0755 ${WORKDIR}/dot.bashrc ${D}${sysconfdir}/skel/.bashrc
    install -m 0755 ${WORKDIR}/dot.bashrc ${D}${ROOT_HOME}/.bashrc
}
