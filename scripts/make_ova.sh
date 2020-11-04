#!/bin/bash

cd output-vmware-iso || exit

ovftool \
packer-vmware-iso.vmx \
"$KUBE_HOSTNAME".ova
