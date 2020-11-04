#!/bin/bash

CONFIG="centos8-rancher.json"
ESXI_USER="root"
SECRET_ID="host/sexiboy/user/$ESXI_USER"
SECRET_KEY="password"
DEPLOY_HOST=$( < $CONFIG jq --raw-output '.variables.deploy_host')
DEPLOY_NETWORK=$( < $CONFIG jq --raw-output '.variables.deploy_network')
DEPLOY_DATASTORE=$( < $CONFIG jq --raw-output '.variables.deploy_datastore')
ESXI_PASSWORD=$(aws secretsmanager get-secret-value --secret-id $SECRET_ID | jq --raw-output '.SecretString' | jq -r ."$SECRET_KEY")

cd output-vmware-iso || exit

ovftool \
--parallelThreads=4 \
--datastore="$DEPLOY_DATASTORE" \
--network="$DEPLOY_NETWORK" \
--allowExtraConfig \
--extraConfig:eth0.ipaddr="MANUAL" \
--X:injectOvfEnv \
--X:logFile=ovftool.log \
--X:logLevel=verbose \
packer-vmware-iso.vmx \
vi://"$ESXI_USER":"$ESXI_PASSWORD"@"$DEPLOY_HOST"