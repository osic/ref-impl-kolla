#!/bin/bash
file="disks.lst"
DISKS=(`cat $file`)
echo ${DISKS[0]}
sudo parted /dev/${DISKS[0]} -s -- mklabel gpt mkpart KOLLA_CEPH_OSD_BOOTSTRAP 1 -1
