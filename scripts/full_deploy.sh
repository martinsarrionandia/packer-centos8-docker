#!/bin/bash

if pwd | grep -q packer-centos8-rancher/scripts; then
  echo "Please run this from parent directory"
  echo "hint: cd.. && ./scripts/full_deploy.sh"
  exit 1
fi

CONFIG="centos8-docker.json"
ESXI_USER="root"
SECRET_ID="host/sexiboy/user/$ESXI_USER"
SECRET_KEY="password"
DEPLOY_HOST=$( < $CONFIG jq --raw-output '.variables.deploy_host')
DEPLOY_NETWORK=$( < $CONFIG jq --raw-output '.variables.deploy_network')
DEPLOY_DATASTORE=$( < $CONFIG jq --raw-output '.variables.deploy_datastore')
ESXI_PASSWORD=$( aws secretsmanager get-secret-value --secret-id $SECRET_ID | jq --raw-output '.SecretString' | jq -r ."$SECRET_KEY")
RANCHER_HOSTNAME=$( < $CONFIG jq --raw-output '.variables.hostname')
DISPLAY_NAME=$( < $CONFIG jq --raw-output '.variables.display_name')
VOLUME_DATASTORE=$( < $CONFIG jq --raw-output '.variables.volume_disk_datastore')
CONTROLLER=$( < $CONFIG jq --raw-output '.variables.volume_disk_controller')
TARGET=$( < $CONFIG jq --raw-output '.variables.volume_disk_target')
VOLUME_DISK_SIZE=$( < $CONFIG jq --raw-output '.variables.volume_disk_size')

# Get VMID from DISPLAY_NAME
VMID=$(sshpass -p "$ESXI_PASSWORD" ssh "$ESXI_USER"@"$DEPLOY_HOST" sh" << EOF
vim-cmd vmsvc/getallvms | grep $DISPLAY_NAME | cut -d \" \" -f1
EOF")

# Check if VMID is a value then shut it down
if [ -n "$VMID" ]; then
{
# Power off Machine
sshpass -p "$ESXI_PASSWORD" ssh "$ESXI_USER"@"$DEPLOY_HOST" sh" << EOF
if !(vim-cmd vmsvc/power.getstate $VMID | grep 'Powered off');
then
  echo 'Shutting Down: $DISPLAY_NAME'
  vim-cmd vmsvc/power.shutdown $VMID
  while !(vim-cmd vmsvc/power.getstate $VMID | grep 'Powered off');
  do
    sleep 1
    echo Powering off...
  done
  echo 'Powered off: $DISPLAY_NAME'
fi
EOF"

# Detach Disk
sshpass -p "$ESXI_PASSWORD" ssh "$ESXI_USER"@"$DEPLOY_HOST" sh" << EOF
vim-cmd vmsvc/device.diskremove $VMID $CONTROLLER $TARGET pvscsi
EOF"
}
fi

cd output-vmware-iso || exit

# Deploy VM
ovftool \
--overwrite \
--parallelThreads=4 \
--datastore="$DEPLOY_DATASTORE" \
--network="$DEPLOY_NETWORK" \
--allowExtraConfig \
--extraConfig:eth0.ipaddr="MANUAL" \
--powerOn \
--X:injectOvfEnv \
--X:logFile=ovftool.log \
--X:logLevel=verbose \
packer-vmware-iso.vmx \
vi://"$ESXI_USER":"$ESXI_PASSWORD"@"$DEPLOY_HOST"
LOGVMID=$( < ovftool.log grep WaitForIp | sed -e "s/^.*VirtualMachine:\([0-9]*\)\('\)/\1/")

echo "rancher deployed wiht VMID $LOGVMID"

# Update VMID
VMID=$(sshpass -p "$ESXI_PASSWORD" ssh "$ESXI_USER"@"$DEPLOY_HOST" sh" << EOF
vim-cmd vmsvc/getallvms | grep $DISPLAY_NAME | cut -d \" \" -f1
EOF")

if [ "$VMID" -ne "$LOGVMID" ];
  then
  echo "VMID in log does not match live. Spellcast: F U C"
  exit 1
fi

# Attach Disk
sshpass -p "$ESXI_PASSWORD" ssh "$ESXI_USER"@"$DEPLOY_HOST" sh" << EOF
mkdir -p /vmfs/volumes/$VOLUME_DATASTORE/$DISPLAY_NAME/
vmkfstools --createvirtualdisk $VOLUME_DISK_SIZE --diskformat zeroedthick /vmfs/volumes/$VOLUME_DATASTORE/$DISPLAY_NAME/volume_disk.vmdk 2>1 > /dev/null
vim-cmd vmsvc/device.diskaddexisting $VMID /vmfs/volumes/$VOLUME_DATASTORE/$DISPLAY_NAME/volume_disk.vmdk $CONTROLLER $TARGET pvscsi
EOF"

# Clear SSH Key

ssh-keygen -R "$RANCHER_HOSTNAME"
