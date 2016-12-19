#!/bin/bash
export KOLLA_BASE_DISTRO="ubuntu"
export KOLLA_INSTALL_TYPE="source"
export REGISTRY="localhost:4000"
export TAG="3.0.0"
file1="/opt/ref-impl-kolla/scripts/disks.lst"
DISKS=$(cat  $file1 |tr "\n" " ")
file2="/opt/ref-impl-kolla/scripts/storage_nodes"
STORAGE=$(cat  $file2 |tr "\n" " ")
slen=$(cat $file1 | wc -l)
dlen=$(cat $file2 | wc -l)

# Object ring
docker run \
  -v /etc/kolla/config/swift/:/etc/kolla/config/swift/ \
  ${REGISTRY}/kolla/${KOLLA_BASE_DISTRO}-${KOLLA_INSTALL_TYPE}-swift-base:${TAG} \
  swift-ring-builder /etc/kolla/config/swift/object.builder create 10 3 1
echo "Created Object builder"

for NODE in $STORAGE; do 
  for ((i=0; i<=$((dlen-1)); i++)); do
       docker run \
        -v /etc/kolla/config/swift/:/etc/kolla/config/swift/ \
         ${REGISTRY}/kolla/${KOLLA_BASE_DISTRO}-${KOLLA_INSTALL_TYPE}-swift-base:${TAG} swift-ring-builder \
        /etc/kolla/config/swift/object.builder add r1z1-$NODE:6000/d${i} 1;
  done
  echo "Added $NODE to object ring"
done
echo "STORAGE NODES ADDED IN OBJECT RING"


# Account ring
docker run \
  -v /etc/kolla/config/swift/:/etc/kolla/config/swift/ \
   ${REGISTRY}/kolla/${KOLLA_BASE_DISTRO}-${KOLLA_INSTALL_TYPE}-swift-base:${TAG} \
  swift-ring-builder /etc/kolla/config/swift/account.builder create 10 3 1
echo "Create account builder"

for NODE in $STORAGE; do
  for ((i=0; i<=$((dlen-1)); i++)); do
      docker run \
      -v /etc/kolla/config/swift/:/etc/kolla/config/swift/ \
      ${REGISTRY}/kolla/${KOLLA_BASE_DISTRO}-${KOLLA_INSTALL_TYPE}-swift-base:${TAG} swift-ring-builder \
      /etc/kolla/config/swift/account.builder add r1z1-$NODE:6001/d${i} 1;
  done
  echo "Added $NODE to account ring"
done
echo "STORAGE NODES ADDED IN ACCOUNT RING"


# Container ring
docker run \
  -v /etc/kolla/config/swift/:/etc/kolla/config/swift/ \
   ${REGISTRY}/kolla/${KOLLA_BASE_DISTRO}-${KOLLA_INSTALL_TYPE}-swift-base:${TAG} \
  swift-ring-builder /etc/kolla/config/swift/container.builder create 10 3 1
echo "Created container builder"


for NODE in $STORAGE; do
  for ((i=0; i<=$((dlen-1)); i++)); do
      docker run \
      -v /etc/kolla/config/swift/:/etc/kolla/config/swift/ \
      ${REGISTRY}/kolla/${KOLLA_BASE_DISTRO}-${KOLLA_INSTALL_TYPE}-swift-base:${TAG} swift-ring-builder \
     /etc/kolla/config/swift/container.builder add r1z1-$NODE:6002/d${i} 1;
  done
  echo "Added $NODE to container ring" 
done
echo "STORAGE NODES ADDED IN CONTAINER RING"


# Rebalancing done
for ring in object account container; do
  docker run \
    -v /etc/kolla/config/swift/:/etc/kolla/config/swift/ \
     ${REGISTRY}/kolla/${KOLLA_BASE_DISTRO}-${KOLLA_INSTALL_TYPE}-swift-base:${TAG} swift-ring-builder \
    /etc/kolla/config/swift/${ring}.builder rebalance;
done
echo "REBALANCING DONE"
