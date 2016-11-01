#!/bin/bash

GLOBALS_FILE=/etc/kolla/globals.yml
DISK=/dev/vdc
PRIVATE_IP=$(hostname -I | awk '{ print $1 }')
FIRST_INTERFACE=ens3
SECOND_INTERFACE=ens4

echo "${PRIVATE_IP} $(hostname)" | sudo tee -a /etc/hosts %>/dev/null

sudo apt-get update
sudo apt-get install -y linux-image-generic-lts-wily
sudo apt-get install -y python-dev libffi-dev gcc libssl-dev ntp python-pip
sudo pip install -U pip

curl -sSL https://get.docker.io | bash
sudo cp /lib/systemd/system/docker.service /etc/systemd/system/docker.service
sudo sed -i 's/process$/process\nMountFlags=shared/' /etc/systemd/system/docker.service

sudo systemctl daemon-reload
sudo systemctl restart docker
sudo usermod -aG docker ubuntu

sudo pip install -U docker-py
sudo pip install -U ansible

git clone https://git.openstack.org/openstack/kolla
sudo pip install -r kolla/requirements.txt -r kolla/test-requirements.txt
cd kolla
sudo cp -r etc/kolla /etc/
sudo pip install -U python-openstackclient python-neutronclient

sudo parted $DISK -s -- mklabel gpt mkpart KOLLA_CEPH_OSD_BOOTSTRAP 1 -1

sudo modprobe configfs
sudo systemctl start sys-kernel-config.mount

sudo sed -i 's/^#kolla_base_distro.*/kolla_base_distro: "ubuntu"/' $GLOBALS_FILE
sudo sed -i 's/^#kolla_install_type.*/kolla_install_type: "source"/' $GLOBALS_FILE
sudo sed -i 's/^kolla_internal_vip_address.*/kolla_internal_vip_address: "'${PRIVATE_IP}'"/' $GLOBALS_FILE
sudo sed -i 's/^kolla_external_vip_address.*/kolla_external_vip_address: "'${PRIVATE_IP}'"/' $GLOBALS_FILE
sudo sed -i 's/^#network_interface.*/network_interface: "'${FIRST_INTERFACE}'"/g' $GLOBALS_FILE
sudo sed -i 's/^#neutron_external_interface.*/neutron_external_interface: "'${SECOND_INTERFACE}'"/g' $GLOBALS_FILE

# Enable required services
sudo sed -i 's/#enable_barbican:.*/enable_barbican: "yes"/' $GLOBALS_FILE
sudo sed -i 's/#enable_cinder:.*/enable_cinder: "yes"/' $GLOBALS_FILE
# Cinder LVM backend
#sudo sed -i 's/#enable_cinder_backend_lvm:.*/enable_cinder_backend_lvm: "yes"/' $GLOBALS_FILE
sudo sed -i 's/#enable_heat:.*/enable_heat: "yes"/' $GLOBALS_FILE
sudo sed -i 's/#enable_horizon:.*/enable_horizon: "yes"/' $GLOBALS_FILE
sudo sed -i 's/#enable_sahara:.*/enable_sahara: "yes"/' $GLOBALS_FILE
sudo sed -i 's/#enable_murano:.*/enable_murano: "yes"/' $GLOBALS_FILE
sudo sed -i 's/#enable_magnum:.*/enable_magnum: "yes"/' $GLOBALS_FILE
sudo sed -i 's/#enable_manila:.*/enable_manila: "yes"/' $GLOBALS_FILE
sudo sed -i 's/#enable_manila_backend_generic:.*/enable_manila_backend_generic: "yes"/' $GLOBALS_FILE
#sudo sed -i 's/#enable_neutron_lbaas:.*/enable_neutron_lbaas: "yes"/' $GLOBALS_FILE
sudo sed -i 's/#enable_ceph:.*/enable_ceph: "yes"/' $GLOBALS_FILE
sudo sed -i 's/#enable_ceph_rgw:.*/enable_ceph_rgw: "yes"/' $GLOBALS_FILE
echo "enable_haproxy: \"no\"" | sudo tee -a $GLOBALS_FILE %>/dev/null

sudo mkdir -p /etc/kolla/config

# Reconfigure Manila to use different Flavor ID
cat <<-EOF | sudo tee /etc/kolla/config/manila-share.conf 
[global]
service_instance_flavor_id = 2
EOF

# Reconfigure CEPH to use just 1 drive
cat <<-EOF | sudo tee /etc/kolla/config/ceph.conf 
[global]
osd pool default size = 1
osd pool default min size = 1
EOF

reboot

sudo tools/generate_passwords.py
sudo tools/kolla-ansible prechecks
sudo tools/kolla-ansible pull
sudo tools/kolla-ansible deploy
sudo tools/kolla-ansible post-deploy
