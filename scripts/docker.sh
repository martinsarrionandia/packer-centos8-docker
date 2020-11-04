#!/bin/bash

# Add admin user

useradd "$ADMIN_USER"
echo "$ADMIN_USER":"$ADMIN_PASS" | chpasswd

# Install Docker

dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
dnf install docker-ce --nobest -y
systemctl enable --now docker

usermod -aG docker "$ADMIN_USER"
usermod -aG wheel "$ADMIN_USER"

# Install Conntrack

yum -y install conntrack
