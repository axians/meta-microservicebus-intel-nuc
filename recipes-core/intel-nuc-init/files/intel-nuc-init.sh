#!/bin/sh
#
# Init Intel NUC
# 
# Set hostname
#
#***********************************************************************

# Get script name
me="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"

RESULT=0

# Set hostname to serial number
/usr/sbin/dmidecode -s chassis-serial-number > /etc/hostname

exit $RESULT

