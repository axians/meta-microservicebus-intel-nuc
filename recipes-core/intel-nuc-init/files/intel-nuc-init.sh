#!/bin/sh
#
# Init Intel NUC
# 
# Set hostname
#
#***********************************************************************

RESULT=0

# Set hostname to serial number
hostnamectl set-hostname $(/usr/sbin/dmidecode -s system-serial-number)
#/usr/sbin/dmidecode -s system-serial-number > /etc/hostname

DNS1="nameserver 8.8.8.8"
DNS2="nameserver 8.8.4.4"
RESOLVECONF="/etc/resolv.conf"

grep -qxF "$DNS1" $RESOLVECONF || echo $DNS1 >> $RESOLVECONF
grep -qxF "$DNS2" $RESOLVECONF || echo $DNS2 >> $RESOLVECONF

systemd-notify --ready
exit $RESULT
