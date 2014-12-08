#!/bin/bash

echo "provision_for_mount.sh: Move VBoxGuestAdditions to /tmp/ if any exists"
[ -d /opt/VBoxGuestAdditions-*/ ] && mv /opt/VBoxGuestAdditions-*/ /tmp/ 

echo "provision_for_mount.sh: yum install parted"
yum install -y parted

echo "provision_for_mount.sh: Create ext4 partition on /dev/sdb1"
parted /dev/sdb mklabel msdos
parted /dev/sdb mkpart primary ext4 0% 100%
sleep 3

#-m swith tells mkfs to only reserve 1% of the blocks for the super block
mkfs.ext4 /dev/sdb1
e2label /dev/sdb1 "opt"

######### mount sdb1 to /opt ##############
echo "provision_for_mount.sh: Mount sdb1 to /opt"
chmod 777 /opt

mount /dev/sdb1 /opt
chmod 777 /opt

echo '/dev/sdb1 /opt ext4 defaults 0 0' >> /etc/fstab

echo "provision_for_mount.sh: Move VBoxGuestAdditions to /back to /opt/ if any exists in /tmp"
[ -d /tmp/VBoxGuestAdditions-*/ ] && mv /tmp/VBoxGuestAdditions-*/ /opt/ 

echo "provision_for_mount.sh: Move VBoxGuestAdditions to /back to /opt/ if any exists in /tmp"
