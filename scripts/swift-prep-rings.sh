readarray -t STORAGE < storage_nodes
#STORAGE[0]="172.22.0.64"
#STORAGE[1]="172.22.0.65"
#STORAGE[2]="172.22.0.66"
#STORAGE[3]="172.22.0.67"
slen=${#STORAGE[@]}
#slen=$((slen-1))
sudo swift-ring-builder /etc/kolla/config/swift/account.builder create 12 3 1
sudo swift-ring-builder /etc/kolla/config/swift/container.builder create 12 3 1
sudo swift-ring-builder /etc/kolla/config/swift/object.builder create 12 3 1
for (( NODE=0; NODE<=$(($slen-1)); NODE++)) do
 sudo swift-ring-builder /etc/kolla/config/swift/object.builder add r1z1-${STORAGE[$NODE]}:6000/loop0p1 100
 sudo swift-ring-builder /etc/kolla/config/swift/object.builder add r1z1-${STORAGE[$NODE]}:6000/loop1p1 100
 sudo swift-ring-builder /etc/kolla/config/swift/object.builder add r1z1-${STORAGE[$NODE]}:6000/loop2p1 100
 sudo swift-ring-builder /etc/kolla/config/swift/object.builder add r1z1-${STORAGE[$NODE]}:6000/loop3p1 100
 sudo swift-ring-builder /etc/kolla/config/swift/object.builder add r1z1-${STORAGE[$NODE]}:6000/loop4p1 100
 sudo swift-ring-builder /etc/kolla/config/swift/object.builder add r1z1-${STORAGE[$NODE]}:6000/loop5p1 100
done
echo "STORAGE NODES ADDED IN OBJECT RING"
for (( NODE=0; NODE<=$(($slen-1)); NODE++)) do
 sudo swift-ring-builder /etc/kolla/config/swift/account.builder add r1z1-${STORAGE[$NODE]}:6001/loop0p1 100
 sudo swift-ring-builder /etc/kolla/config/swift/account.builder add r1z1-${STORAGE[$NODE]}:6001/loop1p1 100
 sudo swift-ring-builder /etc/kolla/config/swift/account.builder add r1z1-${STORAGE[$NODE]}:6001/loop2p1 100
 sudo swift-ring-builder /etc/kolla/config/swift/account.builder add r1z1-${STORAGE[$NODE]}:6001/loop3p1 100
 sudo swift-ring-builder /etc/kolla/config/swift/account.builder add r1z1-${STORAGE[$NODE]}:6001/loop4p1 100
 sudo swift-ring-builder /etc/kolla/config/swift/account.builder add r1z1-${STORAGE[$NODE]}:6001/loop5p1 100
done
echo "STORAGE NODES ADDED IN ACCOUNT RING"
for (( NODE=0; NODE<=$(($slen-1)); NODE++)) do
 sudo swift-ring-builder /etc/kolla/config/swift/container.builder add r1z1-${STORAGE[$NODE]}:6002/loop0p1 100
 sudo swift-ring-builder /etc/kolla/config/swift/container.builder add r1z1-${STORAGE[$NODE]}:6002/loop1p1 100
 sudo swift-ring-builder /etc/kolla/config/swift/container.builder add r1z1-${STORAGE[$NODE]}:6002/loop2p1 100
 sudo swift-ring-builder /etc/kolla/config/swift/container.builder add r1z1-${STORAGE[$NODE]}:6002/loop3p1 100
 sudo swift-ring-builder /etc/kolla/config/swift/container.builder add r1z1-${STORAGE[$NODE]}:6002/loop4p1 100
 sudo swift-ring-builder /etc/kolla/config/swift/container.builder add r1z1-${STORAGE[$NODE]}:6002/loop5p1 100
done
echo "STORAGE NODES ADDED IN CONTAINER RING"
sudo swift-ring-builder /etc/kolla/config/swift/object.builder rebalance
sudo swift-ring-builder /etc/kolla/config/swift/account.builder rebalance
sudo swift-ring-builder /etc/kolla/config/swift/container.builder rebalance
echo "REBALANCING DONE"
