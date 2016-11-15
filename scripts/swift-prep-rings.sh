#!/bin/bash
apt-get install swift -y
file="/root/disks.lst"
DISKS=`cat $file`
file="storage_nodes"
STORAGE=`cat $file`
slen=${#STORAGE[@]}
dlen=${#DISKS[@]}
sudo swift-ring-builder /etc/kolla/config/swift/account.builder create 12 3 1
sudo swift-ring-builder /etc/kolla/config/swift/container.builder create 12 3 1
sudo swift-ring-builder /etc/kolla/config/swift/object.builder create 12 3 1
for (( NODE=0; NODE<=$(($slen-1)); NODE++)) do
 for d in $DISKS; do
   sudo swift-ring-builder /etc/kolla/config/swift/object.builder add r1z1-${STORAGE[$NODE]}:6000/${d}1 100
 done
done
echo "STORAGE NODES ADDED IN OBJECT RING"
for (( NODE=0; NODE<=$(($slen-1)); NODE++)) do
 for d in $DISKS; do
   sudo swift-ring-builder /etc/kolla/config/swift/account.builder add r1z1-${STORAGE[$NODE]}:6001/${d}1 100
 done
done
echo "STORAGE NODES ADDED IN ACCOUNT RING"
for (( NODE=0; NODE<=$(($slen-1)); NODE++)) do
 for d in $DISKS; do
   sudo swift-ring-builder /etc/kolla/config/swift/container.builder add r1z1-${STORAGE[$NODE]}:6002/${d}1 100
 done
done
echo "STORAGE NODES ADDED IN CONTAINER RING"
sudo swift-ring-builder /etc/kolla/config/swift/object.builder rebalance
sudo swift-ring-builder /etc/kolla/config/swift/account.builder rebalance
sudo swift-ring-builder /etc/kolla/config/swift/container.builder rebalance
echo "REBALANCING DONE"
