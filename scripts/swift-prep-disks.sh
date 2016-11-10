#!/bin/bash
file="disks.lst"
DISKS=`cat $file`
index=0
for d in $DISKS; do
    parted /dev/${d} -s -- mklabel gpt mkpart KOLLA_SWIFT_DATA_1 1 -1
    sudo mkfs.xfs -f -L d${index} /dev/${d}1
    (( index++ ))
done
sudo parted /dev/${DISKS[0]} -s -- mklabel gpt mkpart KOLLA_CEPH_OSD_BOOTSTRAP 1 -1
