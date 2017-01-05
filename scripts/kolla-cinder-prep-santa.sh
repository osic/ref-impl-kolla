#!/bin/bash
dd if=/dev/zero of=/var/lib/cinder_data.img bs=1G count=5
losetup /dev/loop3 /var/lib/cinder_data.img
pvcreate /dev/loop3
vgcreate cinder-volumes /dev/loop3
