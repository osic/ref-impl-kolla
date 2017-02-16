Part 2: Deploying Openstack Kolla
=================================


Intro
------

This document summarizes the steps to deploy an openstack cloud from the Openstack Kolla documentation. If you want to customize your deployment, please visit the Openstack Kolla documentation website at [Openstack Kolla](http://docs.openstack.org/developer/kolla/)


#### About Target and Deployment hosts<br/>

In Openstack deployment scenario, target hosts point to hosts/nodes on which you will be deploying Openstack services. In an inventory file, target hosts are usually mentioned under groups such as `[compute],[controller],[storage]...`. Deployment host is where the Operator who will be deploying Openstack should log on to and run the deployment tool. Deployment host talks to target hosts and deploys/copies configuration files to target hosts.

#### About Ansible<br/>

Ansible is an automation framework. It can configure systems, deploy software, and orchestrate more advanced IT tasks such as continuous deployments or zero downtime rolling updates. We will be using ansible as a part of our deployment strategy. Ansible will be used to execute certain tasks on your target hosts, copy configuration files from deployment host to target hosts, start docker containers, etc.  

#### Environment

By end of this chapter, keeping current configurations you will have an OpenStack environment composed of:
- One deployment host.
- Nine compute hosts.
- Three controller/infrastructure hosts.
- Three monitoring host.
- Three network host.
- Three storage hosts.

__NOTE: If storage nodes do not have any physical disks other than sda, then execute only the playbooks for swift and cinder that are having a suffix `-santa.yaml`. These playbooks creates and uses only logical loop devices as swift and cinder disks instead of using seperate physical disks. If your storage nodes have physical disks other then sda then execute the playbooks that do not have `-santa.yaml` suffix.__

Table of Contents
-----------------
__[1. Prepare Deployment Host](https://github.com/osic/ref-impl-kolla/blob/master/documents/ease-of-use/2-osic-deploy-kolla.md#prepare-deployment-host)__<br/>
__[2. Bootstrap Servers](https://github.com/osic/ref-impl-kolla/blob/master/documents/ease-of-use/2-osic-deploy-kolla.md#bootstrap-servers)__<br/>
__[3. Deploy Kolla](https://github.com/osic/ref-impl-kolla/blob/master/documents/ease-of-use/2-osic-deploy-kolla.md#deploy-kolla)__<br/>
__[4. Deploy Swift](https://github.com/osic/ref-impl-kolla/blob/master/documents/ease-of-use/2-osic-deploy-kolla.md#deploy-swift)__<br/>
__[5. Create Openstack RC](https://github.com/osic/ref-impl-kolla/blob/master/documents/ease-of-use/2-osic-deploy-kolla.md#create-openstack-rc)__<br/>
__[6. Verify Installation](https://github.com/osic/ref-impl-kolla/blob/master/documents/ease-of-use/2-osic-deploy-kolla.md#verify-installation)__<br/>


Prepare Deployment Host
-----------------------

The following steps would aid in installing packages and configuring Kolla on your deployment host.
If you are in any other host, exit and please log on to the __deployment host__:
##### Step 1: Clone the Openstack Kolla and ref-impl-kolla repository.


```shell

git clone https://github.com/osic/ref-impl-kolla.git /opt/ref-impl-kolla

git clone -b stable/newton https://github.com/openstack/kolla.git /opt/kolla
```

##### Step 2: Generate multinode inventory


__About Ansible inventory:__<br/>
Ansible works against multiple systems in your infrastructure at the same time. It does this by selecting portions of systems listed in Ansible’s inventory file. You can specify a different inventory file using the `-i <path>` option on the command line. The ansible inventory file contains all the information needed to determine what services will land on which hosts. The operator can edit which services will be associated in with each group.

```shell
#If you have provisioned your own server, you need to copy the contents of the `hosts` file that you created in the `osic-prep` ansible container to the deployment host. 
#Log in to the osic-pre ansible container and copy the contents of `hosts` file to your deployment host at `/opt/ref-impl-kolla/playbooks`
vi /opt/ref-impl-kolla/playbooks/hosts


#If you are working on already provisioned servers copy the hosts file provided by the operator to your inventory.
cp /etc/hosts /opt/ref-impl-kolla/inventory/

```

__Replace each host group in the multinode inventory file located in `/opt/kolla/ansible/inventory/multinode`  with the one generated in the `hosts` file located at /opt/ref-impl-kolla/inventory/hosts.__

__The multinode host inventory is now located at `/opt/kolla/ansible/inventory/multinode`.__

__An Example Configuration of `multinode` file located at `/opt/kolla/ansible/inventory/multinode` is shown below:__

```shell 
[control]
# These hostname must be resolvable from your deployment host
control01 ansible_ssh_host=172.22.0.52 ansible_ssh_host_ironic=10.3.72.128
control02 ansible_ssh_host=172.22.0.53 ansible_ssh_host_ironic=10.3.72.129
control03 ansible_ssh_host=172.22.0.54 ansible_ssh_host_ironic=10.3.72.130

[network]
network01 ansible_ssh_host=172.22.0.81 ansible_ssh_host_ironic=10.3.72.157
network02 ansible_ssh_host=172.22.0.82 ansible_ssh_host_ironic=10.3.72.158
network03 ansible_ssh_host=172.22.0.83 ansible_ssh_host_ironic=10.3.72.159

[compute]
compute01 ansible_ssh_host=172.22.0.55 ansible_ssh_host_ironic=10.3.72.131
compute02 ansible_ssh_host=172.22.0.56 ansible_ssh_host_ironic=10.3.72.132
compute03 ansible_ssh_host=172.22.0.71 ansible_ssh_host_ironic=10.3.72.147
compute04 ansible_ssh_host=172.22.0.72 ansible_ssh_host_ironic=10.3.72.148
compute05 ansible_ssh_host=172.22.0.73 ansible_ssh_host_ironic=10.3.72.149
compute06 ansible_ssh_host=172.22.0.74 ansible_ssh_host_ironic=10.3.72.150
compute07 ansible_ssh_host=172.22.0.75 ansible_ssh_host_ironic=10.3.72.151
compute08 ansible_ssh_host=172.22.0.76 ansible_ssh_host_ironic=10.3.72.152
compute09 ansible_ssh_host=172.22.0.77 ansible_ssh_host_ironic=10.3.72.153

[monitoring]
monitoring01 ansible_ssh_host=172.22.0.78 ansible_ssh_host_ironic=10.3.72.154
monitoring02 ansible_ssh_host=172.22.0.79 ansible_ssh_host_ironic=10.3.72.155
monitoring03 ansible_ssh_host=172.22.0.80 ansible_ssh_host_ironic=10.3.72.156

# When compute nodes and control nodes use different interfaces,
# you can specify "api_interface" and another interfaces like below:
#compute01 neutron_external_interface=eth0 api_interface=em1 storage_interface=em1 tunnel_interface=em1

[storage]
storage01 ansible_ssh_host=172.22.0.103 ansible_ssh_host_ironic=10.3.72.179
storage02 ansible_ssh_host=172.22.0.104 ansible_ssh_host_ironic=10.3.72.180
storage03 ansible_ssh_host=172.22.0.105 ansible_ssh_host_ironic=10.3.72.181

```

##### Step 3: Execute this playbook to generate the ssh fingerprints of hosts defined in the multinode inventory and copy them to known_hosts file. These ssh fingerprints will then be used by Ansible to deploy services to individual hosts.
```shell
# Install Ansible version 2.2
sudo apt-get install software-properties-common -y
sudo apt-add-repository ppa:ansible/ansible
sudo apt-get update
sudo apt-get install ansible

#Execute playbook
ansible-playbook -i /opt/kolla/ansible/inventory/multinode /opt/ref-impl-kolla/playbooks/create-known-hosts.yaml
```
    
##### Step 4: Kolla deployment can be done using kolla wrapper which performs almost all functionalities needed to deploy kolla. To install kolla wrapper, execute these commands:

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

##### Step 5: Kolla uses docker containers to deploy openstack services. For this, the docker images need to be pulled into the deployment host and pushed into the docker registry running on deployment host (created in Part 2). Follow these steps to build the images:

```shell
#For purpose of simplicity we will be forcing docker to build openstack images on top of latest ubuntu installed from source with tag version 3.0.0:
kolla-build --registry localhost:4000 --base ubuntu --type source --tag 3.0.0 --push
```

##### Step 6: Copy the contents of the /opt/kolla/etc/kolla directory into /etc/. This directory contains the required configuration needed for kolla deployment.

```shell
cp -r /opt/kolla/etc/kolla /etc/
GLOBALS_FILE=/etc/kolla/globals.yml
```

##### Step 7: Execute the following commands which will configure the globals.yaml file. You need to make changes to the command based on the deployment environment:

```shell
#Change the kolla_base_distro and kolla_install_type to match the type of docker images build in step 4.
sudo sed -i 's/^#kolla_base_distro.*/kolla_base_distro: "ubuntu"/' $GLOBALS_FILE
sudo sed -i 's/^#kolla_install_type.*/kolla_install_type: "source"/' $GLOBALS_FILE

#Change the Openstack release tag:
sudo sed -i 's/^#openstack_release:.*/openstack_release: "3.0.0"/' $GLOBALS_FILE

#Disable Haproxy:
sed -i '21s/^/enable_haproxy: no /' $GLOBALS_FILE

#Enter Ironic IP(10.3.72.x) address of your `first controller node` which you can get from 
#`/opt/ref-impl-kolla/inventory/hosts`:
INTERNAL_IP= <IP-Control-Node>
sudo sed -i 's/^kolla_internal_vip_address.*/kolla_internal_vip_address: "'${INTERNAL_IP}'"/' $GLOBALS_FILE
sudo sed -i 's/^#kolla_external_vip_address.*/kolla_external_vip_address: "'${INTERNAL_IP}'"/' $GLOBALS_FILE
```
##### Step 8: Kolla requires atleast two interfaces on Target Hosts:
1. FIRST_INTERFACE which is used as network interface for api, storage, cluster and tunnel and which should have an IP address. This interface should be the one on which Ironic IP is assigned.
2. SECOND_INTERFACE which is used as external interface for neutron can be the same as FIRST_INTERFACE or one can specify another interface with/without IP.

__To find which interface(First Interface) have an Ironic IP(10.3.72.x) and which interface can be used as Second Interface
execute the following command on your deployment/Target hosts__
```shell
ip a
```

__Enter Interface names in variables `FIRST_INTERFACE` and `SECOND_INTERFACE` (Note: If interface name is of the format "eth0@eth1", ignore the "@eth1" and simply write "eth0")__
```shell
FIRST_INTERFACE=<Interface-name-with-ip>
SECOND_INTERFACE=<Interface-name-without-ip>
sudo sed -i 's/^#network_interface.*/network_interface: "'${FIRST_INTERFACE}'"/g' $GLOBALS_FILE
sudo sed -i 's/^#neutron_external_interface.*/neutron_external_interface: "'${SECOND_INTERFACE}'"/g' $GLOBALS_FILE
```

##### Step 9: In case of multinode deployment, the deployment host must provide information about the docker registry to the target hosts:
```shell
registry_host=$(echo "`hostname -I | cut -d ' ' -f 1`:4000")
sudo sed -i 's/#docker_registry:.*/docker_registry: "'${registry_host}'"/g' $GLOBALS_FILE

#Enable required OpenStack Services
sudo sed -i 's/#enable_cinder:.*/enable_cinder: "yes"/' $GLOBALS_FILE
sudo sed -i 's/#enable_heat:.*/enable_heat: "yes"/' $GLOBALS_FILE
sudo sed -i 's/#enable_horizon:.*/enable_horizon: "yes"/' $GLOBALS_FILE

#Enable backend for Cinder and Glance
sudo sed -i 's/#glance_backend_file:.*/glance_backend_file: "yes"/' $GLOBALS_FILE
sudo sed -i 's/#cinder_volume_group:.*/cinder_volume_group: "cinder-volumes"/' $GLOBALS_FILE

#Create Kolla Config Directory for storing config files for ceph, swift
mkdir -p /etc/kolla/config/swift/backups
```

##### Step 10: Generate passwords for individual openstack services:
```shell
#Execute this command to populate all empty fields in the 
#/etc/kolla/passwords.yml file using randomly generated values to secure the deployment.
kolla-genpwd

#Check passwords.yaml to view passwords.
vi /etc/kolla/passwords.yml 
```


##### Step 11: Increase number of forks and enable pipelining in ansible configuration:
```shell
#Increase number of forks to 100:
sed -i 's/#forks.*/forks=100/g' /etc/ansible/ansible.cfg

#Enable pipelining:
sed -i 's/#pipelining.*/pipelining = True/g' /etc/ansible/ansible.cfg
```

Bootstrap Servers
-----------------

##### Step 1: Execute the following commands to bootstrap target hosts. This will install all the required packages in target hosts.

```shell
cd /opt/kolla

# Ensure that ansible version > 2.0
ansible --version

# Bootstrap servers:__(the password: cobbler)
ansible-playbook -i ansible/inventory/multinode -e @/etc/kolla/globals.yml -e @/etc/kolla/passwords.yml -e CONFIG_DIR=/etc/kolla  -e action=bootstrap-servers /usr/local/share/kolla/ansible/kolla-host.yml --ask-pass
 ```

##### Step 2: The disks inside the storage nodes will be used as swift and cinder disks. Enter the `swift` disks in disks.lst and `cinder` disks in cinder.lst. To get a list of disks inside storage node, log in to one of the storage nodes and run `sudo fdisk -l`. This will give you list of all physical disks. Only select those having format as `/dev/sdx`
__Note: Ignore this step if your storage nodes do not have physical disks other than `sda`__
```shell
vi /opt/ref-impl-kolla/scripts/disks.lst
vi /opt/ref-impl-kolla/scripts/cinder.lst
```

##### Step 3: The cinder implementation defaults to using LVM storage. The default implementation requires a volume group be set up. This can either be a real physical volume or a loopback mounted file for development. 
__Note: Run the following playbook if your storage nodes do not have physical disks other that `sda`.__
```shell
# Execute the following playbook to create volume groups in storage nodes.__(the password: cobbler)
ansible-playbook -i ansible/inventory/multinode /opt/ref-impl-kolla/playbooks/kolla-cinder-playbook-santa.yaml --ask-pass
```
__OR__ <br/>
__Note: For all other environment execute this playbook.__
```shell
# Execute the following playbook to create volume groups in storage nodes.__(the password: cobbler)
ansible-playbook -i ansible/inventory/multinode /opt/ref-impl-kolla/playbooks/kolla-cinder-playbook.yaml --ask-pass
```


Deploy Kolla
------------

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

Deploy Swift
------------

##### Step 1: Create Parition KOLLA_SWIFT_DATA by running the playbok `kolla-swift-playbook.yaml` from deployment node:
__Note: Run the following playbook if your storage nodes do not have physical disks other than `sda`.__
```shell
#Create parition KOLLA_SWIFT_DATA:
ansible-playbook -i /opt/kolla/ansible/inventory/multinode /opt/ref-impl-kolla/playbooks/kolla-swift-playbook-santa.yaml --ask-pass
```
__OR__ <br/>
__Note: For all other environment execute this playbook.__
```shell
#Create parition KOLLA_SWIFT_DATA:
ansible-playbook -i /opt/kolla/ansible/inventory/multinode /opt/ref-impl-kolla/playbooks/kolla-swift-playbook.yaml --ask-pass
```

##### Step 2: Enable Swift services and configure swift device names and matching mode:
```shell
GLOBALS_FILE=/etc/kolla/globals.yml
sudo sed -i 's/#enable_swift:.*/enable_swift: "yes"/' $GLOBALS_FILE
sudo sed -i 's/#swift_devices_match_mode:.*/swift_devices_match_mode: "strict"/' $GLOBALS_FILE
sudo sed -i 's/#swift_devices_name:.*/swift_devices_name: "KOLLA_SWIFT_DATA"/' $GLOBALS_FILE
```

##### Step 3: To create swift rings, the script uses the disks listed in `disks.lst`. In the case where the storage nodes do not have any physical disks, you need to log in to ONE of the storage nodes and use the disks listed in file `/root/out.swift`. .
```shell
#Log in to storage node
ssh <storage-nodes>

#Find the disks that are in KOLLA_SWIFT_DATA partition on storage nodes.
cat out.swift | awk 'BEGIN{ FS="/dev/"}{print $2}' | cut -d " " -f 1

#After taking a note of the disks exit to the deployment host
exit

#Copy the disks names in `disks.lst` on deployment host (one on each line without space)
vi /opt/ref-impl-kolla/scripts/disks.lst

```

##### Step 3: Create swift object, container and account rings on deployment node:
```shell
#Add storage nodes IP address (Ironic IP: 10.3.72.x) in `storage_nodes` file (one on each line):
vi /opt/ref-impl-kolla/scripts/storage_nodes

#Create rings by running the `swift-prep-rings.sh`:
/bin/bash /opt/ref-impl-kolla/scripts/swift-prep-rings.sh 
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

##### Step 5: Deploy swift:
```shell
ansible-playbook -i /opt/kolla/ansible/inventory/multinode -e @/etc/kolla/globals.yml -e @/etc/kolla/passwords.yml -e CONFIG_DIR=/etc/kolla  -e action=deploy /usr/local/share/kolla/ansible/site.yml --tags=swift --ask-pass
```


Create Openstack RC
-------------------

Create Openstack rc file on deployment node (generated in /etc/kolla)(the password is __cobbler__):

```shell
ansible-playbook -i /opt/kolla/ansible/inventory/multinode -e @/etc/kolla/globals.yml -e @/etc/kolla/passwords.yml -e CONFIG_DIR=/etc/kolla  /usr/local/share/kolla/ansible/post-deploy.yml --ask-pass
 ```

Verify Installation
-------------------

To verify working of your openstack cluster and see which services are installed:
```shell
source /etc/kolla/admin-openrc.sh

#Endpoint List
openstack endpoint list
```

Congratulations! you have your OpenStack cluster running.
