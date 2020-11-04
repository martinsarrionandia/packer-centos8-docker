#!/bin/bash

INT_PROFILE=$(nmcli device show eth0 |grep GENERAL.CONNECTION|sed -e 's/^GENERAL.CONNECTION:[ ]*//g')
NEW_INT_PROFILE="eth0"

nmcli connection modify "$INT_PROFILE" connection.id "$NEW_INT_PROFILE"

nmcli connection modify "$NEW_INT_PROFILE" IPv4.address "$IP_ADDRESS"
nmcli connection modify "$NEW_INT_PROFILE" IPv4.gateway "$GATEWAY"
nmcli connection modify "$NEW_INT_PROFILE" IPv4.dns "$DNS_SERVER"
nmcli connection modify "$NEW_INT_PROFILE" IPv4.method manual

nmcli connection delete ens192
