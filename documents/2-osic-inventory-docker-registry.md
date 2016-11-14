Part 2: Generating multinode host inventory and creating docker registry.
========================================================================

A.) Generating multinode host inventory
----------------------------------------

When all servers finish PXE booting, you will now need to generate the multinode inventory which will contain the list of
target hosts used for deployment. 
##### Step 1: Generate hosts file

Start by running the `generate_ansible_hosts.py` Python script:
   
    git clone https://github.com/osic/ref-impl-kolla.git /opt/ref-impl-kolla

    cd /opt/ref-impl-kolla

    python scripts/generate_ansible_hosts.py /root/input.csv > /root/osic-prep-ansible/hosts

If this will be an openstack-kolla installation, organize the Ansible __hosts__ file into groups for __controller__, __monitoring__, __compute__, __storage__, and __network__, otherwise leave the Ansible __hosts__ file as it is and jump to the next section.

An example for openstack-kolla installation:

    [controller]
    729427-controller01 ansible_ssh_host=172.22.0.58 ansible_ssh_host_ironic=10.3.72.134
    729426-controller02 ansible_ssh_host=172.22.0.59 ansible_ssh_host_ironic=10.3.72.135

    [monitoring]
    729425-monitroing01 ansible_ssh_host=172.22.0.60 ansible_ssh_host_ironic=10.3.72.136
    729425-monitroing02 ansible_ssh_host=172.22.0.61 ansible_ssh_host_ironic=10.3.72.137

    [compute]
    744822-compute01 ansible_ssh_host=172.22.0.62 ansible_ssh_host_ironic=10.3.72.138
    744823-compute02 ansible_ssh_host=172.22.0.63 ansible_ssh_host_ironic=10.3.72.139

    [storage]
    729421-storage01 ansible_ssh_host=172.22.0.64 ansible_ssh_host_ironic=10.3.72.140
    729419-storage02 ansible_ssh_host=172.22.0.66 ansible_ssh_host_ironic=10.3.72.142
    729418-storage03 ansible_ssh_host=172.22.0.67 ansible_ssh_host_ironic=10.3.72.143
    
    [networking]
    729418-networking01 ansible_ssh_host=172.22.0.68 ansible_ssh_host_ironic=10.3.72.144


##### Step 2: Verify Connectivity

The LXC container will not have all of the new server's SSH fingerprints in its __known_hosts__ file. This is needed to bypass prompts and create a silent login when SSHing to servers. Programatically add them by running the following command:

    for i in $(cat hosts | awk /ansible_ssh_host/ | cut -d'=' -f2 | cut -d ' ' -f1)
    do
    ssh-keygen -R $i
    ssh-keyscan -H $i >> /root/.ssh/known_hosts
    done

Verify Ansible can talk to every server (the password is __cobbler__):

    cd /root/osic-prep-ansible
    sudo apt-get install -y ansible
    ansible -i hosts all -m shell -a "uptime" --ask-pass
    


##### Step 3: Setup SSH Public Keys

Generate an SSH key pair for the LXC container:

    ssh-keygen

Copy the LXC container's SSH public key to the __osic-prep-ansible__ directory:

    cp /root/.ssh/id_rsa.pub /root/osic-prep-ansible/playbooks/files/public_keys/osic-prep

##### Step 4: Update Linux Kernel

Every server in the OSIC RAX Cluster is running two Intel X710 10 GbE NICs. These NICs have not been well tested in Ubuntu and as such the upstream i40e driver in the default 14.04.3 Linux kernel will begin showing issues when you setup VLAN tagged interfaces and bridges.

In order to get around this, you must install an updated Linux kernel.

You can do this by running the following commands(the password is __cobbler__):

    cd /root/osic-prep-ansible

    ansible -i hosts all -m shell -a "apt-get update; apt-get install -y linux-image-generic-lts-wily" --forks 25 --ask-pass

##### Step 5: Reboot Nodes

Finally, reboot all servers(the password is __cobbler__):

    ansible -i hosts all -m shell -a "reboot" --forks 25 --ask-pass


##### Step 6: Assign address to bond0 interface.

After the target hosts are rebooted, you need to re-assign the IP addresses to the bond interface. To do that, simply copy the script `re-address.sh` in the same directory as `hosts` file and execute it.

```shell
cp /opt/ref-impl-koll/scripts/re-address.sh /root/osic-prep-ansible/
./re-address.sh
```
Once all servers reboot and address re-assignment is done, you can begin creating Docker Registry.

 B.) Creating docker registry
----------------------------

Openstack Kolla uses docker images to install OpenStack services. For multinode deployment, Openstack kolla uses the docker registry running on the deployment host to pull images and create containers. The following steps should be performed on the deployment host:

__Note: If you are still in the osic-prep container, exit to the host__.

##### Step 1:  Get information on the newest versions of packages and their dependencies:

```shell
apt-get update
```

##### Step 2: For Ubuntu based systems where Docker is used it is recommended to use the latest available LTS kernel. The latest LTS kernel available is the wily kernel (version 4.2). While all kernels should work for Docker, some older kernels may have issues with some of the different Docker backends such as AUFS and OverlayFS. In order to update kernel in Ubuntu 14.04 LTS to 4.2, run:

```shell
apt-get install linux-image-generic-lts-wily -y
reboot
```

##### Step 3: Install and configure docker on deployment host.

```shell
# Install Docker Pre-requisites
apt-get install python python-pip python-dev libffi-dev gcc libssl-dev -y

# Install Docker
curl -sSL https://get.docker.io | bash

# Check Docker version (should be >= 1.10.0)
docker --version

# Create the drop-in unit directory for docker.service
mkdir -p /etc/systemd/system/docker.service.d

# Create the drop-in unit file
tee /etc/systemd/system/docker.service.d/kolla.conf <<-'EOF'
[Service]
MountFlags=shared
EOF

#Restart Docker service
service docker restart
systemctl daemon-reload


#For mounting /run as shared upon startup, add that command to /etc/rc.local:
mount --make-shared /run
```

##### Step 4: Create Docker Regsistry.

```shell
docker run -d -p 4000:5000 --restart=always --name registry registry:2
```

##### Step 5: Check whether Ubuntu is using systemd or upstart.

```shell
stat /proc/1/exe
```

##### Step 6: Edit default docker configuration to point to newly created registry.

```shell
echo "DOCKER_OPTS=\"--insecure-registry `hostname -I | cut -d ' ' -f 1`:4000\"" >> /etc/default/docker
```

##### Step 7: If Ubuntu is using systemd, additional settings needs to be configured. 

```shell
# Copy docker’s systemd unit file to /etc/systemd/system/ directory.
cp /lib/systemd/system/docker.service /etc/systemd/system/docker.service
```

##### Step 8: Copy the following in `/etc/systemd/system/docker.service` to add the environmentFile variable and $DOCKER_OPTS under the `[service]` section.

```
EnvironmentFile=-/etc/default/docker
ExecStart=/usr/bin/docker daemon -H fd:// $DOCKER_OPTS
```

##### Step 8: Restart docker by executing the following commands.

```shell
sudo service docker restart
```

You should have successfully created docker registry on your deployment host. Next step is to deploy Kolla on target nodes.
