A.) Bootstrapping the Servers
=============================

When all servers finish PXE booting, you will now need to bootstrap the servers.

##### Step 1: Generate Multinode Inventory

Start by running the `generate_ansible_hosts.py` Python script:

    cd /root/rpc-prep-scripts

    python generate_ansible_hosts.py /root/input.csv > /root/osic-prep-ansible/hosts

If this will be an openstack-kolla installation, organize the Ansible __hosts__ file into groups for __controller__, __monitoring__, __compute__, __storage__, and __network__, otherwise leave the Ansible __hosts__ file as it is and jump to the next section.

An example for openstack-kolla installation:

    [controller]
    744800-infra01.example.com ansible_ssh_host=10.240.0.51
    744819-infra02.example.com ansible_ssh_host=10.240.0.52
    744820-infra03.example.com ansible_ssh_host=10.240.0.53

    [monitoring]
    744821-logging01.example.com ansible_ssh_host=10.240.0.54

    [compute]
    744822-compute01.example.com ansible_ssh_host=10.240.0.55
    744823-compute02.example.com ansible_ssh_host=10.240.0.56

    [storage]
    744824-cinder01.example.com ansible_ssh_host=10.240.0.57
    744825-object01.example.com ansible_ssh_host=10.240.0.58
    744826-object02.example.com ansible_ssh_host=10.240.0.59
    744827-object03.example.com ansible_ssh_host=10.240.0.60

##### Step 2: Verify Connectivity

The LXC container will not have all of the new server's SSH fingerprints in its __known_hosts__ file. This is needed to bypass prompts and create a silent login when SSHing to servers. Programatically add them by running the following command:

    for i in $(cat /root/osic-prep-ansible/hosts | awk /ansible_ssh_host/ | cut -d'=' -f2)
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

##### Step 4: Clone the Openstack Kolla repository.


```shell
cd /root/
git clone -b stable/newton https://github.com/openstack/kolla.git /opt/kolla
```

##### Step 5: Copy the contents of hosts file generated in step 1 to multinode inventory.
Replace each group in the multinode inventory file located in `/opt/kolla/ansible/inventory/multinode`  with the one generated in the `hosts` file.

##### Step 6: Bootstrap the Servers

Openstack Kolla uses a bootstrap process to install all the essential components required for smooth running of Openstack kolla.
Once the repository is cloned, use ansible-playbook to run the bootstrap-servers playbook. The password is again __cobbler__.

```shell
ansible-playbook -i /opt/kolla/ansible/inventory/multinode ansible/kolla-host.yml --ask-pass
```

##### Step 7: Clean Up LVM Logical Volumes

If this will be an openstack-ansible installation, you will need to clean up particular LVM Logical Volumes.

Each server is provisioned with a standard set of LVM Logical Volumes. Not all servers need all of the LVM Logical Volumes. Clean them up with the following steps.

Remove LVM Logical Volume __nova00__ from the Controller, Logging, Cinder, and Swift nodes:

    ansible-playbook -i hosts playbooks/remove-lvs-nova00.yml

Remove LVM Logical Volume __deleteme00__ from all nodes:

    ansible-playbook -i hosts playbooks/remove-lvs-deleteme00.yml

##### Step 8: Update Linux Kernel

Every server in the OSIC RAX Cluster is running two Intel X710 10 GbE NICs. These NICs have not been well tested in Ubuntu and as such the upstream i40e driver in the default 14.04.3 Linux kernel will begin showing issues when you setup VLAN tagged interfaces and bridges.

In order to get around this, you must install an updated Linux kernel.

You can do this by running the following commands:

    cd /root/osic-prep-ansible

    ansible -i hosts all -m shell -a "apt-get update; apt-get install -y linux-generic-lts-xenial" --forks 25

##### Step 9: Reboot Nodes

Finally, reboot all servers:

    ansible -i hosts all -m shell -a "reboot" --forks 25

Once all servers reboot, you can begin installing openstack-ansible.


B.) Creating docker registry
============================

Openstack Kolla uses docker images to install OpenStack services. For multinode deployment, Openstack kolla uses the docker registry running on the deployment host to pull images and create containers. The following steps should be performed on the deployment host:

##### Step 1: Install docker on deployment host.

```shell
# Install Docker
curl -sSL https://get.docker.io | bash

# Check Docker version (should be >= 1.10.0)
docker --version
```

##### Step 2: Create Docker Regsistry.

```shell
docker run -d -p 4000:5000 --restart=always --name registry registry:2
```

##### Step 2: Check whether Ubuntu is using systemd or upstart.

```shell
stat /proc/1/exe
```

##### Step 3: Edit default docker configuration to point to newly created registry.

```shell
echo "DOCKER_OPTS=\"--insecure-registry `hostname -I | cut -d ' ' -f 1`:4000\"" >> /etc/default/docker
```

##### Step 4: If Ubuntu is using systemd, additional settings needs to be configured. 

```shell
# Copy docker’s systemd unit file to /etc/systemd/system/ directory.
cp /lib/systemd/system/docker.service /etc/systemd/system/docker.service

# Copy the following in /etc/systemd/system/docker.service to add the environmentFile variable and $DOCKER_OPTS.
[Service]
EnvironmentFile=-/etc/default/docker
ExecStart=/usr/bin/docker daemon -H fd:// $DOCKER_OPTS
```

##### Step 5: Restart docker by executing the following commands.

```shell
sudo service docker restart
```

You should have successfully created docker registry on your deployment host. Next step is to push docker images in registry.
