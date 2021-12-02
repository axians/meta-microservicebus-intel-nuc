#!/bin/sh
#
# Init Intel NUC
# 
# Create home dir on data partition if missing and set owner
# Create RAUC data dir
# Setup Edge config 
# Set hostname
# Add iptables 
#
#***********************************************************************

# Get script name
me="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"

# Dynamic settings, replaced with values from Yocto variables
MSB_HOME_DIR_PATH="@MSB_HOME_DIR_PATH@"
MSB_NODE_USER="@MSB_NODE_USER@"
MSB_NODE_GROUP="@MSB_NODE_GROUP@"
RAUC_VAR_DIR="@RAUC_VAR_DIR@"
IOTEDGE="@IOTEDGE@"

RESULT=0

# Check if home dir is created
if [ -d ${MSB_HOME_DIR_PATH} ]; then
   echo "HOME dir exists, setting permissions" 
   # Set permissions on home dir to msb user
   chown -R ${MSB_NODE_USER}:${MSB_NODE_GROUP} ${MSB_HOME_DIR_PATH}
   echo "HOME dir ready" 
   systemd-notify --ready
   # Copy .bashrc file to home 
  cp /etc/skel/.bashrc ${MSB_HOME_DIR_PATH}/ 2>&1 > /dev/null
else
   # Create home dir/path if missing and set permissions
   echo "HOME dir does not exists, creating..." 
   mkdir -p ${MSB_HOME_DIR_PATH}
   echo "...setting permissions"
   chown -R ${MSB_NODE_USER}:${MSB_NODE_GROUP} ${MSB_HOME_DIR_PATH}
   if [ $? -ne 0 ]; then
     echo "Error: Failed to create ${MSB_HOME_DIR_PATH}"
     systemd-notify --status="Error: Failed to create ${MSB_HOME_DIR_PATH}"
     RESULT=3
   else
     echo "HOME dir ready"
     systemd-notify --status="Home dir ready"
     systemd-notify --ready
    # Copy .bashrc file to home 
    cp /etc/skel/.bashrc ${MSB_HOME_DIR_PATH}/ 2>&1 > /dev/null 
  fi  
fi

# Check if rauc dir is created
if [ -d ${RAUC_VAR_DIR} ]; then
  echo "RAUC dir ready"
else
  echo "RAUC dir does not exists, creating..."
  # Create rauc dir if missing
  mkdir -p ${RAUC_VAR_DIR}
  if [ $? -ne 0 ]; then
    echo "Error: Failed to create ${RAUC_VAR_DIR}"
  else
    echo "Created ${RAUC_VAR_DIR}"
  fi
fi

if [ "${IOTEDGE}" = "TRUE" ]; then
    echo "Copy IoT Edge config if IOTEDGE == TRUE and config file not exists " ${IOTEDGE}

    echo "Node is running IoT Edge" | systemd-cat -p info -t "${me}"
    if [ ! -d /data/home/iotedge ]; then
      echo "Copying config.yaml to /data" | systemd-cat -p info -t "${me}"

      mkdir /data/home/iotedge
      chown iotedge:iotedge /var/lib/iotedge
      chown iotedge:iotedge /var/log/iotedge
      chown iotedge:iotedge /data/home/iotedge
      
      cp /etc/iotedge/config.yaml /data/home/iotedge/config.yaml
      chown iotedge:iotedge /data/home/iotedge/config.yaml

      if [ $? -eq 0 ]; then
        echo "Successfully copied config.yaml. Setting permissions" | systemd-cat -p info -t "${me}"
	chmod g+rw /data/home/iotedge/config.yaml
        chown iotedge:iotedge /data/home/iotedge/config.yaml
      else
        echo "Error, failed to copy config.yaml tp /data/home/iotedge" | systemd-cat -p warning -t "${me}"
      fi
    fi

    if [ ! -d /data/lib/docker ]; then
      echo "Create docker directory" | systemd-cat -p info -t "${me}"

      mkdir -p /data/lib/docker
      
      if [ $? -eq 0 ]; then
        echo "Successfully created docker directory" | systemd-cat -p info -t "${me}"
      else
        echo "Error, failed creating docker directory" | systemd-cat -p warning -t "${me}"
      fi
    fi
fi

# Set hostname to serial number
/usr/sbin/dmidecode -s chassis-serial-number > /etc/hostname

# Set iptables and alert rules
sudo iptables -N SSHATTACK
sudo iptables -A SSHATTACK -j LOG --log-prefix "Possible SSH attack! " --log-level 7;
sudo iptables -A SSHATTACK -j DROP;
sudo iptables -A INPUT -i eth0 -p tcp -m state --dport 22 --state NEW -m recent --set;
sudo iptables -A INPUT -i eth0 -p tcp -m state --dport 22 --state NEW -m recent --update --seconds 120 --hitcount 4 -j SSHATTACK;

exit $RESULT

