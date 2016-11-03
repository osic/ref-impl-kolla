A.) Deploying Openstack Kolla


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

#### Step 1: Prepare Deployment Host

The first step would be to certain dependecies that would aid in the entire deployment process

__Note:__ If you are in osic-prep-container exit and return back to your host.

1.)  Get information on the newest versions of packages and their dependencies:

```shell
apt-get update
```
2.) For Ubuntu based systems where Docker is used it is recommended to use the latest available LTS kernel. The latest LTS kernel available is the wily kernel (version 4.2). While all kernels should work for Docker, some older kernels may have issues with some of the different Docker backends such as AUFS and OverlayFS. In order to update kernel in Ubuntu 14.04 LTS to 4.2, run:

```shell
apt-get install linux-image-generic-lts-wily -y
reboot
```

3.) Kolla deployment can be done using kolla wrapper which performs almost all functionalities needed to deploy kolla. To install kolla wrapper, execute these commands:
    #Python and python-pip
    apt-get install python python-pip python-dev libffi-dev gcc libssl-dev -y
    
    #Install Ansible to execute ansible-playbooks
    apt-get install -y ansible
    
    #Install Dependencies
    pip install -r requirements.txt -r test-requirements.txt
    pip install -U docker-py

   #Install kolla wrapper from source:
    cd /opt/kolla
    python setup.py install


4.) Kolla uses docker containers to deploy openstack services. For this, the docker images need to be pulled into the deployment host and pushed into the docker registry running on deployment host (created in Part 2). Follow these steps to build the images:

```shell
#For purpose of simplicity we will be forcing docker to build openstack images on top of latest ubuntu installed from source with tag version 3.0.0:
kolla-build --registry localhost:4000 --base ubuntu --type source --tag 3.0.0 --push
```

5.) Copy the contents of the /opt/kolla/etc/kolla directory into /etc/. This directory contains the required configuration needed for kolla deployment.

```shell
cp -r /opt/kolla/etc/kolla /etc/
GLOBALS_FILE=/etc/kolla/globals.yml
```

6.) You need to configure the globals.yaml file based on the deployment environment:

```shell
#Change the kolla_base_distro and kolla_install_type to match the type of docker images build in step 4.
sudo sed -i 's/^#kolla_base_distro.*/kolla_base_distro: "ubuntu"/' $GLOBALS_FILE
sudo sed -i 's/^#kolla_install_type.*/kolla_install_type: "source"/' $GLOBALS_FILE

#Use an unused IP on your network as the internal and external vip address.This IP address also called Virtual IP will float between hosts when haproxy and keepalived is running for high-availability. If your network is something like 172.22.0.57/22 then use the last address such as the 172.22.0.254 as the virtual IP.
INTERNAL_IP=""
sudo sed -i 's/^kolla_internal_vip_address.*/kolla_internal_vip_address: "'${INTERNAL_IP}'"/' $GLOBALS_FILE
sudo sed -i 's/^kolla_external_vip_address.*/kolla_external_vip_address: "'${INTERNAL_IP}'"/' $GLOBALS_FILE

#Kolla requires atleast two interfaces: one as network interface for api, storage, cluster and tunnel and other as external port for neutron interface:

sudo sed -i 's/^#network_interface.*/network_interface: "'${FIRST_INTERFACE}'"/g' $GLOBALS_FILE
sudo sed -i 's/^#neutron_external_interface.*/neutron_external_interface: "'${SECOND_INTERFACE}'"/g' $GLOBALS_FILE

#In case of multinode deployment, the deployment host must inform all nodes information about the docker registry:
registry_host=$(echo "`hostname -I | cut -d ' ' -f 1`:4000")
sudo sed -i 's/#docker_registry.*/docker_registry: '${registry_host}'/g' $GLOBALS_FILE
```
