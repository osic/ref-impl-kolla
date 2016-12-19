#!/bin/bash
file="/root/disks.lst"
DISKS=(`cat $file`)
echo ${DISKS[0]}
pvcreate /dev/${DISKS[0]}
vgcreate cinder-volumes /dev/${DISKS[0]}
