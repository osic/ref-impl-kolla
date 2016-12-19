export KOLLA_1="192.168.0.188"
export KOLLA_2="192.168.0.187"
export KOLLA_3="192.168.0.183"
export KOLLA_BASE_DISTRO="ubuntu"
export KOLLA_INSTALL_TYPE="source"
export REGISTRY="localhost:4000"
export TAG="3.0.0"
# Object ring
docker run \
  -v /etc/kolla/config/swift/:/etc/kolla/config/swift/ \
  ${REGISTRY}/kolla/${KOLLA_BASE_DISTRO}-${KOLLA_INSTALL_TYPE}-swift-base:${TAG} \
  swift-ring-builder /etc/kolla/config/swift/object.builder create 10 3 1

for i in {1..3}; do
  docker run \
    -v /etc/kolla/config/swift/:/etc/kolla/config/swift/ \
    ${REGISTRY}/kolla/${KOLLA_BASE_DISTRO}-${KOLLA_INSTALL_TYPE}-swift-base:${TAG} swift-ring-builder \
    /etc/kolla/config/swift/object.builder add r1z1-${KOLLA_1}:6000/vdc${i} 1;
done

for i in {1..3}; do
  docker run \
    -v /etc/kolla/config/swift/:/etc/kolla/config/swift/ \
    ${REGISTRY}/kolla/${KOLLA_BASE_DISTRO}-${KOLLA_INSTALL_TYPE}-swift-base:${TAG} swift-ring-builder \
    /etc/kolla/config/swift/object.builder add r1z1-${KOLLA_2}:6000/vdc${i} 1;
done

for i in {1..3}; do
  docker run \
    -v /etc/kolla/config/swift/:/etc/kolla/config/swift/ \
    ${REGISTRY}/kolla/${KOLLA_BASE_DISTRO}-${KOLLA_INSTALL_TYPE}-swift-base:${TAG} swift-ring-builder \
    /etc/kolla/config/swift/object.builder add r1z1-${KOLLA_3}:6000/vdc${i} 1;
done



# Account ring
docker run \
  -v /etc/kolla/config/swift/:/etc/kolla/config/swift/ \
   ${REGISTRY}/kolla/${KOLLA_BASE_DISTRO}-${KOLLA_INSTALL_TYPE}-swift-base:${TAG} \
  swift-ring-builder /etc/kolla/config/swift/account.builder create 10 3 1

for i in {1..3}; do
  docker run \
    -v /etc/kolla/config/swift/:/etc/kolla/config/swift/ \
     ${REGISTRY}/kolla/${KOLLA_BASE_DISTRO}-${KOLLA_INSTALL_TYPE}-swift-base:${TAG} swift-ring-builder \
    /etc/kolla/config/swift/account.builder add r1z1-${KOLLA_1}:6001/vdc${i} 1;
done

for i in {1..3}; do
  docker run \
    -v /etc/kolla/config/swift/:/etc/kolla/config/swift/ \
     ${REGISTRY}/kolla/${KOLLA_BASE_DISTRO}-${KOLLA_INSTALL_TYPE}-swift-base:${TAG} swift-ring-builder \
    /etc/kolla/config/swift/account.builder add r1z1-${KOLLA_2}:6001/vdc${i} 1;
done

for i in {1..3}; do
  docker run \
    -v /etc/kolla/config/swift/:/etc/kolla/config/swift/ \
     ${REGISTRY}/kolla/${KOLLA_BASE_DISTRO}-${KOLLA_INSTALL_TYPE}-swift-base:${TAG} swift-ring-builder \
    /etc/kolla/config/swift/account.builder add r1z1-${KOLLA_3}:6001/vdc${i} 1;
done


# Container ring
docker run \
  -v /etc/kolla/config/swift/:/etc/kolla/config/swift/ \
   ${REGISTRY}/kolla/${KOLLA_BASE_DISTRO}-${KOLLA_INSTALL_TYPE}-swift-base:${TAG} \
  swift-ring-builder /etc/kolla/config/swift/container.builder create 10 3 1

for i in {1..3}; do
  docker run \
    -v /etc/kolla/config/swift/:/etc/kolla/config/swift/ \
    ${REGISTRY}/kolla/${KOLLA_BASE_DISTRO}-${KOLLA_INSTALL_TYPE}-swift-base:${TAG} swift-ring-builder \
    /etc/kolla/config/swift/container.builder add r1z1-${KOLLA_1}:6002/vdc${i} 1;
done

for i in {1..3}; do
  docker run \
    -v /etc/kolla/config/swift/:/etc/kolla/config/swift/ \
    ${REGISTRY}/kolla/${KOLLA_BASE_DISTRO}-${KOLLA_INSTALL_TYPE}-swift-base:${TAG} swift-ring-builder \
    /etc/kolla/config/swift/container.builder add r1z1-${KOLLA_2}:6002/vdc${i} 1;
done

for i in {1..3}; do
  docker run \
    -v /etc/kolla/config/swift/:/etc/kolla/config/swift/ \
    ${REGISTRY}/kolla/${KOLLA_BASE_DISTRO}-${KOLLA_INSTALL_TYPE}-swift-base:${TAG} swift-ring-builder \
    /etc/kolla/config/swift/container.builder add r1z1-${KOLLA_3}:6002/vdc${i} 1;
done

for ring in object account container; do
  docker run \
    -v /etc/kolla/config/swift/:/etc/kolla/config/swift/ \
     ${REGISTRY}/kolla/${KOLLA_BASE_DISTRO}-${KOLLA_INSTALL_TYPE}-swift-base:${TAG} swift-ring-builder \
    /etc/kolla/config/swift/${ring}.builder rebalance;
done
