Deploying Openstack Kolla
==========================


Intro
------

This document summarizes the steps to deploy an openstack cloud from the Openstack Kolla documentation. If you want to customize your deployment, please visit the Openstack Kolla documentation website at [OSA](http://docs.openstack.org/developer/kolla/)

#### Environment

By end of this chapter, keeping current configurations you will have an OpenStack environment composed of:
- One deployment host.
- compute hosts.
- controller/infrastructure hosts.
- monitoring hosts.
- network hosts.
- storage hosts.

A.) Prepare Deployment Host
---------------------------

The first step would be to certain dependecies that would aid in the entire deployment process


__Note:__ If you are in osic-prep-container exit and return back to your host.

##### Step 1: Clone the Openstack Kolla and ref-impl-kolla repository.


```shell

git clone https://github.com/osic/ref-impl-kolla.git /opt/ref-impl-kolla

git clone -b stable/newton https://github.com/openstack/kolla.git /opt/kolla
```

##### Step 2: Copy the contents of hosts file generated in Part 2 to multinode inventory.

```shell
cp /var/lib/lxc/osic-prep/rootfs/root/osic-prep-ansible/hosts /opt/ref-impl-kolla/inventory/
```

__Replace each host group in the multinode inventory file located in `/opt/kolla/ansible/inventory/multinode`  with the one generated in the `hosts` file located at /opt/ref-impl-kolla/inventory/hosts.__

__The multinode host inventory is now located at `/opt/kolla/ansible/inventory/multinode`.__

##### Step 3: Include the deployment host in the host file __/opt/ref-impl-kolla/inventory/hosts__  as follows: (172.22.0.21 should be changed to you deployment PXE address)

    [deploy]
    729429-deploy01 ansible_ssh_host=172.22.0.21 ansible_ssh_host_ironic=10.3.72.3
    
##### Step 4: Copy the pair of public/private key used in the osic-prep container in /root/.ssh/ directory:

    cp /var/lib/lxc/osic-prep/rootfs/root/.ssh/id_rsa* /root/.ssh/


##### Step 5: Copy all of the servers SSH fingerprints from the LXC container osic-prep known_hosts file.

    cp /var/lib/lxc/osic-prep/rootfs/root/.ssh/known_hosts /root/.ssh/known_hosts
    

##### Step 6: Copy public key to authorized_key file in deployment host to allow ssh locally

    cat /root/.ssh/id_rsa.pub > /root/.ssh/authorized_keys

##### Step 7: Kolla deployment can be done using kolla wrapper which performs almost all functionalities needed to deploy kolla. To install kolla wrapper, execute these commands:

```shell
cd /opt/kolla
    
#Install Dependencies
pip install -r requirements.txt -r test-requirements.txt
pip install -U docker-py

#Install kolla wrapper from source:
python setup.py install

#Add current hostname to /etc/hosts to avoid any DNS errors
echo "`hostname -I | cut -d ' ' -f 1` $(hostname)" | sudo tee -a /etc/hosts %>/dev/null

```

##### Step 8: Kolla uses docker containers to deploy openstack services. For this, the docker images need to be pulled into the deployment host and pushed into the docker registry running on deployment host (created in Part 2). Follow these steps to build the images:

```shell
#For purpose of simplicity we will be forcing docker to build openstack images on top of latest ubuntu installed from source with tag version 3.0.0:
kolla-build --registry localhost:4000 --base ubuntu --type source --tag 3.0.0 --push
```

##### Step 9: Copy the contents of the /opt/kolla/etc/kolla directory into /etc/. This directory contains the required configuration needed for kolla deployment.

```shell
cp -r /opt/kolla/etc/kolla /etc/
GLOBALS_FILE=/etc/kolla/globals.yml
```

##### Step 10: Execute the following commands which will configure the globals.yaml file. You need to make changes to the command based on the deployment environment:

```shell
#Change the kolla_base_distro and kolla_install_type to match the type of docker images build in step 4.
sudo sed -i 's/^#kolla_base_distro.*/kolla_base_distro: "ubuntu"/' $GLOBALS_FILE
sudo sed -i 's/^#kolla_install_type.*/kolla_install_type: "source"/' $GLOBALS_FILE

#Change the Openstack release tag:
sudo sed -i 's/^#openstack_release:.*/openstack_release: "3.0.0"/' $GLOBALS_FILE

#Use an unused IP on your network as the internal and external vip address.
INTERNAL_IP=""
sudo sed -i 's/^kolla_internal_vip_address.*/kolla_internal_vip_address: "'${INTERNAL_IP}'"/' $GLOBALS_FILE
sudo sed -i 's/^#kolla_external_vip_address.*/kolla_external_vip_address: "'${INTERNAL_IP}'"/' $GLOBALS_FILE

#Kolla requires atleast two interfaces on Target Hosts: FIRST_INTERFACE which is used as network interface for api, storage, cluster and tunnel. SECOND_INTERFACE which is used as external interface for neutron:
FIRST_INTERFACE=<Target-host-interface-with-ip>
SECOND_INTERFACE=<Target-host-interface-without-ip>
sudo sed -i 's/^#network_interface.*/network_interface: "'${FIRST_INTERFACE}'"/g' $GLOBALS_FILE
sudo sed -i 's/^#neutron_external_interface.*/neutron_external_interface: "'${SECOND_INTERFACE}'"/g' $GLOBALS_FILE

#In case of multinode deployment, the deployment host must provide information about the docker registry to the target hosts:
registry_host=$(echo "`hostname -I | cut -d ' ' -f 1`:4000")
sudo sed -i 's/#docker_registry:.*/docker_registry: "'${registry_host}'"/g' $GLOBALS_FILE

#Enable required OpenStack Services
sudo sed -i 's/#enable_cinder:.*/enable_cinder: "yes"/' $GLOBALS_FILE
sudo sed -i 's/#enable_heat:.*/enable_heat: "yes"/' $GLOBALS_FILE
sudo sed -i 's/#enable_horizon:.*/enable_horizon: "yes"/' $GLOBALS_FILE
sudo sed -i 's/#enable_ceph:.*/enable_ceph: "yes"/' $GLOBALS_FILE
sudo sed -i 's/#enable_ceph_rgw:.*/enable_ceph_rgw: "yes"/' $GLOBALS_FILE

#Enable backend for Cinder and Glance
sudo sed -i 's/#glance_backend_ceph:.*/glance_backend_ceph: "yes"/' $GLOBALS_FILE
sudo sed -i 's/#cinder_backend_ceph:.*/cinder_backend_ceph: "{{ enable_ceph }}"/' $GLOBALS_FILE

#Create Kolla Config Directory for storing config files for ceph, swift
mkdir -p /etc/kolla/config
mkdir -p /etc/kolla/config/swift/backups
```
##### Step 11: Use any one volume in your instance as Ceph OSD drive.

# Use any one volume in your instance as a Ceph Bootstrap OSD with:
apt-get install xfsprogs
DISK=""
sudo parted /dev/$DISK -s -- mklabel gpt mkpart KOLLA_CEPH_OSD_BOOTSTRAP 1 -1
```

##### Step 11: Generate passwords for individual openstack services:
```shell
#Generate Passwords
kolla-genpwd

#Check passwords.yaml to view passwords.
vi /etc/kolla/passwords.yml 
```

B.) Bootstrap Servers
----------------------

Execute the following command to bootstrap target hosts:
This will install all the required packages in target hosts.

```shell
cd /opt/kolla

# Install Ansible version 2.2
sudo apt-get install software-properties-common
sudo apt-add-repository ppa:ansible/ansible
sudo apt-get update
sudo apt-get install ansible

# Ensure that ansible version > 2.0
ansible --version

# Bootstrap servers:
ansible-playbook -i ansible/inventory/multinode -e @/etc/kolla/globals.yml -e @/etc/kolla/passwords.yml -e CONFIG_DIR=/etc/kolla  -e action=bootstrap-servers /usr/local/share/kolla/ansible/kolla-host.yml --ask-pass
 ```

C.) Deploy Kolla
----------------

##### Step 1: Switch to Kolla Directory

```shell
cd /opt/kolla
```

##### Step 2: Pre-deployment checks for hosts which includes the port scans and globals.yaml validation (the password is __cobbler__):

```shell
ansible-playbook -i ansible/inventory/multinode -e @/etc/kolla/globals.yml -e @/etc/kolla/passwords.yml -e CONFIG_DIR=/etc/kolla  /usr/local/share/kolla/ansible/prechecks.yml --ask-pass
```

##### Step 3: Pull all images for containers (the password is __cobbler__):

```shell
ansible-playbook -i ansible/inventory/multinode -e @/etc/kolla/globals.yml -e @/etc/kolla/passwords.yml -e CONFIG_DIR=/etc/kolla  -e action=pull /usr/local/share/kolla/ansible/site.yml --ask-pass
```

##### Step 4: Deploy Openstack services (the password is __cobbler__):

```shell
ansible-playbook -i ansible/inventory/multinode -e @/etc/kolla/globals.yml -e @/etc/kolla/passwords.yml -e CONFIG_DIR=/etc/kolla  -e action=deploy /usr/local/share/kolla/ansible/site.yml --ask-pass
```

D.) Deploy Swift
----------------

##### Step 1: Create Parition KOLLA_SWIFT_DATA by running the playbok `kolla-swift-playbook.yaml` from deployment node:
dd disks present in storage nodes in `storage_nodes` file.
```shell
#Add disks present in storage nodes in `disks.lst` file:
vi /opt/ref-impl-kolla/scripts/disks.lst

#Create parition KOLLA_SWIFT_DATA:
ansible-playbook -i ansible/inventory/multinode kolla-swift-playbook.yaml --ask-pass
```

##### Step 2: Enable Swift services and configure swift device names and matching mode:
```shell
sudo sed -i 's/#enable_swift:.*/enable_swift: "yes"/' $GLOBALS_FILE
sudo sed -i 's/#swift_devices_match_mode:.*/swift_devices_match_mode: "strict"/' $GLOBALS_FILE
sudo sed -i 's/#swift_devices_name:.*/swift_devices_name: "KOLLA_SWIFT_DATA"/' $GLOBALS_FILE
```

##### Step 3: Create swift object, container and account rings on deployment node:
```shell
#Add storage nodes IP address in `storage_nodes` file:
vi /opt/ref-impl-kolla/scripts/storage_nodes

#Create rings by running the `swift-prep-rings.sh`:
./scripts/swift-prep-rings.sh 
```

##### Step 4: Ensure that the following ring files are present in `/etc/kolla/config/swift`:
```shell
ls /etc/kolla/config/swift/
account.builder  
backups            
container.ring.gz  
object.ring.gz
account.ring.gz  
container.builder  
object.builder
```

5.) Deploy swift:
```shell
ansible-playbook -i ansible/inventory/multinode -e @/etc/kolla/globals.yml -e @/etc/kolla/passwords.yml -e CONFIG_DIR=/etc/kolla  -e action=deploy /usr/local/share/kolla/ansible/site.yml --tags=swift --ask-pass
```


E.) Create Openstack RC
-----------------------

Create Openstack rc file on deployment node (generated in /etc/kolla)(the password is __cobbler__):

```shell
ansible-playbook -i ansible/inventory/multinode -e @/etc/kolla/globals.yml -e @/etc/kolla/passwords.yml -e CONFIG_DIR=/etc/kolla  /usr/local/share/kolla/ansible/post-deploy.yml --ask-pass
 ```
