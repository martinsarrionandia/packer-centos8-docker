#!/bin/bash

if ! (grep 'net.ifnames=0 biosdevname=0' /etc/default/grub) ; then
  sed -i "/GRUB_CMDLINE_LINUX/ s/^\(.*\)\(\"\)/\1 net.ifnames=0 biosdevname=0\"/" /etc/default/grub
fi

grub2-mkconfig -o /boot/grub2/grub.cfg

reboot
