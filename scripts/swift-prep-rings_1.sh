#!/usr/bin/env bash

REGISTRY="localhost:4000"

TAG="3.0.0"
KOLLA_BASE_DISTRO="ubuntu"
KOLLA_INSTALL_TYPE="source"
file="/opt/ref-impl-kolla/scripts/disks.lst"
DISKS=`cat $file`
for d in ${DISKS[@]}; do
    print $d
done
file="/opt/ref-impl-kolla/scripts/storage_nodes"
STORAGE=`cat $file`
slen=${#STORAGE[@]}
dlen=${#DISKS[@]}
for node in ${STORAGE[@]}; do
   print ${node}
done

# Note: In this example, each storage node is placed in its own zone

# Object ring
docker run --rm \
  -v /etc/kolla/config/swift/:/etc/kolla/config/swift/ \
  ${REGISTRY}/kolla/${KOLLA_BASE_DISTRO}-${KOLLA_INSTALL_TYPE}-swift-base:${TAG} \
  swift-ring-builder /etc/kolla/config/swift/object.builder create 10 3 1

for (( NODE=0; NODE<=$(($slen-1)); NODE++)) do
  echo "object.builder: Adding ${STORAGE[$NODE]}"
  for i in {0..2}; do
    docker run --rm \
     -v /etc/kolla/config/swift/:/etc/kolla/config/swift/ \
     ${REGISTRY}/kolla/${KOLLA_BASE_DISTRO}-${KOLLA_INSTALL_TYPE}-swift-base:${TAG} swift-ring-builder \
     /etc/kolla/config/swift/object.builder add r1z1-${STORAGE[$NODE]}:6000/d${i} 1;
  done
done

# Account ring
docker run --rm \
  -v /etc/kolla/config/swift/:/etc/kolla/config/swift/ \
  ${REGISTRY}/kolla/${KOLLA_BASE_DISTRO}-${KOLLA_INSTALL_TYPE}-swift-base:${TAG} \
  swift-ring-builder /etc/kolla/config/swift/account.builder create 10 3 1

for (( NODE=0; NODE<=$(($slen-1)); NODE++)) do
  echo "account.builder: Adding ${STORAGE[$NODE]}"
  for i in {0..2}; do
    docker run --rm \
      -v /etc/kolla/config/swift/:/etc/kolla/config/swift/ \
      ${REGISTRY}/kolla/${KOLLA_BASE_DISTRO}-${KOLLA_INSTALL_TYPE}-swift-base:${TAG} swift-ring-builder \
      /etc/kolla/config/swift/account.builder add r1z1-${STORAGE[$NODE]}:6001/d${i} 1;
  done
done

# Container ring
docker run --rm \
  -v /etc/kolla/config/swift/:/etc/kolla/config/swift/ \
  ${REGISTRY}/kolla/${KOLLA_BASE_DISTRO}-${KOLLA_INSTALL_TYPE}-swift-base:${TAG} \
  swift-ring-builder /etc/kolla/config/swift/container.builder create 10 3 1


for (( NODE=0; NODE<=$(($slen-1)); NODE++)) do
  echo "container.builder: Adding ${STORAGE[$NODE]}"
  for i in {0..2}; do
    docker run --rm \
      -v /etc/kolla/config/swift/:/etc/kolla/config/swift/ \
      ${REGISTRY}/kolla/${KOLLA_BASE_DISTRO}-${KOLLA_INSTALL_TYPE}-swift-base:${TAG} swift-ring-builder \
      /etc/kolla/config/swift/container.builder add r1z1-${STORAGE[$NODE]}:6002/d${i} 1;
  done
done

for ring in object account container; do
  docker run --rm \
    -v /etc/kolla/config/swift/:/etc/kolla/config/swift/ \
    ${REGISTRY}/kolla/${KOLLA_BASE_DISTRO}-${KOLLA_INSTALL_TYPE}-swift-base:${TAG} swift-ring-builder \
    /etc/kolla/config/swift/${ring}.builder rebalance
done
