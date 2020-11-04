#!/bin/bash

# Sort out fstab for volume disk 

mkdir /volumes
echo -e "/dev/sdb\t/volumes\txfs\tdefaults\t0 0" >> /etc/fstab
