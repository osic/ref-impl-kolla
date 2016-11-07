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

#### Step 1: Prepare Deployment Host

The first step would be to certain dependecies that would aid in the entire deployment process


__Note:__ If you are in osic-prep-container exit and return back to your host.

1.) Clone the Openstack Kolla repository.


```shell
cd /root/
git clone -b stable/newton https://github.com/openstack/kolla.git /opt/kolla
```

2.) Copy the contents of hosts file generated in Part 2 to multinode inventory.

```shell
cp /var/lib/lxc/osic-prep/rootfs/root/osic-prep-ansible/hosts /opt/ref-impl-kolla/inventory/
```

__Replace each host group in the multinode inventory file located in `/opt/kolla/ansible/inventory/multinode`  with the one generated in the `hosts` file located at /opt/ref-impl-kolla/inventory/hosts.__

__The multinode host inventory is now located at `/opt/kolla/ansible/inventory/multinode`.__

3.) Include the deployment host in the host file __/opt/ref-impl-kolla/inventory/hosts__  as follows: (172.22.0.21 should be changed to you deployment PXE address)

    [deploy]
    729429-deploy01 ansible_ssh_host=172.22.0.21 ansible_ssh_host_ironic=10.3.72.3
    
4.) Copy the pair of public/private key used in the osic-prep container in /root/.ssh/ directory:

    cp /var/lib/lxc/osic-prep/rootfs/root/.ssh/id_rsa* /root/.ssh/


5.) Copy all of the servers SSH fingerprints from the LXC container osic-prep known_hosts file.

    cp /var/lib/lxc/osic-prep/rootfs/root/.ssh/known_hosts /root/.ssh/known_hosts
    

6.) Copy public key to authorized_key file in deployment host to allow ssh locally

    cat /root/.ssh/id_rsa.pub > /root/.ssh/authorized_keys

7.) Kolla deployment can be done using kolla wrapper which performs almost all functionalities needed to deploy kolla. To install kolla wrapper, execute these commands:

```shell
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

```

8.) Kolla uses docker containers to deploy openstack services. For this, the docker images need to be pulled into the deployment host and pushed into the docker registry running on deployment host (created in Part 2). Follow these steps to build the images:

```shell
#For purpose of simplicity we will be forcing docker to build openstack images on top of latest ubuntu installed from source with tag version 3.0.0:
kolla-build --registry localhost:4000 --base ubuntu --type source --tag 3.0.0 --push
```

9.) Copy the contents of the /opt/kolla/etc/kolla directory into /etc/. This directory contains the required configuration needed for kolla deployment.

```shell
cp -r /opt/kolla/etc/kolla /etc/
GLOBALS_FILE=/etc/kolla/globals.yml
```

10.) You need to configure the globals.yaml file based on the deployment environment:

```shell
#Change the kolla_base_distro and kolla_install_type to match the type of docker images build in step 4.
sudo sed -i 's/^#kolla_base_distro.*/kolla_base_distro: "ubuntu"/' $GLOBALS_FILE
sudo sed -i 's/^#kolla_install_type.*/kolla_install_type: "source"/' $GLOBALS_FILE

#Use an unused IP on your network as the internal and external vip address.
INTERNAL_IP=""
sudo sed -i 's/^kolla_internal_vip_address.*/kolla_internal_vip_address: "'${INTERNAL_IP}'"/' $GLOBALS_FILE
sudo sed -i 's/^kolla_external_vip_address.*/kolla_external_vip_address: "'${INTERNAL_IP}'"/' $GLOBALS_FILE

#Kolla requires atleast two interfaces: one as network interface for api, storage, cluster and tunnel and other as external port for neutron interface:

sudo sed -i 's/^#network_interface.*/network_interface: "'${FIRST_INTERFACE}'"/g' $GLOBALS_FILE
sudo sed -i 's/^#neutron_external_interface.*/neutron_external_interface: "'${SECOND_INTERFACE}'"/g' $GLOBALS_FILE

#In case of multinode deployment, the deployment host must inform all nodes information about the docker registry:
registry_host=$(echo "`hostname -I | cut -d ' ' -f 1`:4000")
sudo sed -i 's/#docker_registry.*/docker_registry: '${registry_host}'/g' $GLOBALS_FILE

#Enable required OpenStack Services
sudo sed -i 's/#enable_cinder:.*/enable_cinder: "yes"/' $GLOBALS_FILE
sudo sed -i 's/#enable_heat:.*/enable_heat: "yes"/' $GLOBALS_FILE
sudo sed -i 's/#enable_horizon:.*/enable_horizon: "yes"/' $GLOBALS_FILE
sudo sed -i 's/#enable_swift:.*/enable_swift: "yes"/' $GLOBALS_FILE
sudo sed -i 's/#glance_backend_ceph:.*/glance_backend_ceph: "yes"/' $GLOBALS_FILE
sudo sed -i 's/#cinder_backend_ceph:.*/cinder_backend_ceph: "{{ enable_ceph }}"/' $GLOBALS_FILE
```

11.) Generate passwords for individual openstack services:

```shell
#Generate Passwords
kolla-genpwd

#Check passwords.yaml to view passwords.
vi /etc/kolla/passwords.yaml
```

#### Step 2: Bootstrap Servers:

Execute the following command to bootstrap target hosts:

```shell
cd /opt/kolla
ansible-playbook -i ansible/inventory/multinode -e @/etc/kolla/globals.yml -e @/etc/kolla/passwords.yml -e CONFIG_DIR=/etc/kolla  -e action=bootstrap-servers /usr/local/share/kolla/ansible/kolla-host.yml --ask-pass
 ```

#### Step 3: Deploy Kolla
1.) Switch to Kolla Directory

```shell
cd /opt/kolla
```

2.) Pre-deployment checks for hosts which includes the port scans and globals.yaml validation (the password is __cobbler__):

```shell
ansible-playbook -i ansible/inventory/multinode -e @/etc/kolla/globals.yml -e @/etc/kolla/passwords.yml -e CONFIG_DIR=/etc/kolla  /usr/local/share/kolla/ansible/prechecks.yml --ask-pass
```

3.) Pull all images for containers (the password is __cobbler__):

```shell
ansible-playbook -i ansible/inventory/multinode -e @/etc/kolla/globals.yml -e @/etc/kolla/passwords.yml -e CONFIG_DIR=/etc/kolla  -e action=pull /usr/local/share/kolla/ansible/site.yml --ask-pass
```

4.) Deploy Openstack services (the password is __cobbler__):

```shell
ansible-playbook -i ansible/inventory/multinode -e @/etc/kolla/globals.yml -e @/etc/kolla/passwords.yml -e CONFIG_DIR=/etc/kolla  -e action=deploy /usr/local/share/kolla/ansible/site.yml --ask-pass
```

5.) Create Openstack rc file on deployment node (generated in /etc/kolla)(the password is __cobbler__):

```shell
ansible-playbook -i ansible/inventory/multinode -e @/etc/kolla/globals.yml -e @/etc/kolla/passwords.yml -e CONFIG_DIR=/etc/kolla  /usr/local/share/kolla/ansible/post-deploy.yml --ask-pass
 ```
