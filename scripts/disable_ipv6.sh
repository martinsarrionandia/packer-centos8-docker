#!/bin/bash

if ! (grep 'ipv6.disable=1' /etc/default/grub) ; then
  sed -i "/GRUB_CMDLINE_LINUX/ s/^\(.*\)\(\"\)/\1 ipv6.disable=1\"/" /etc/default/grub
fi

grub2-mkconfig -o /boot/grub2/grub.cfg

nmcli connection modify eth0 ipv6.method ignore