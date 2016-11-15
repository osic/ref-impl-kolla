mknod /dev/loop9 b 7 2
dd if=/dev/zero of=/var/lib/cinder_data.img bs=1G count=20
losetup /dev/loop2 /var/lib/cinder_data.img
pvcreate /dev/loop9
vgcreate cinder-volumes /dev/loop9
