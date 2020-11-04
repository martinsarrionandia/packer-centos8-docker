#!/bin/bash

if [[ $PACKER_BUILDER_TYPE =~ vmware ]]; then
yum -y install open-vm-tools
fi