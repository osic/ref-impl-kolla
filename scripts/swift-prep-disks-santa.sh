#!/bin/bash
index=0
for d in sdc sdd sde; do
    free_device=$(losetup -f)
    fallocate -l 1G /tmp/$d
    losetup $free_device /tmp/$d
    parted $free_device -s -- mklabel gpt mkpart KOLLA_SWIFT_DATA 1 -1
    sudo mkfs.xfs -f -L d${index} ${free_device}p1
    (( index++ ))
done
