Part 1: Provisioning the server
===============================


Overview
---------

The entire process of provisioning and bootstraping the server is performed through the following steps:

[Step 1: Bare Metal Servers Provisioning.](https://github.com/osic/ref-impl-kolla/blob/master/documents/1-osic-provisioning.md#bare-metal-servers-provisioning)

[Step 2: Download and Setup the osic-prep LXC Container.](https://github.com/osic/ref-impl-kolla/blob/master/documents/1-osic-provisioning.md#download-and-setup-the-osic-prep-lxc-container)

[Step 3. PXE Boot the Servers.](https://github.com/osic/ref-impl-kolla/blob/master/documents/1-osic-provisioning.md#pxe-boot-the-servers)


Bare Metal Servers provisioning
-------------------------------
You will need to provision the bare metal servers with an Operating System most likely Linux if you will later be using an Open Source platform to build your cloud. 

#### Ironic Overview

OpenStack bare metal provisioning a.k.a Ironic is an integrated OpenStack program which aims to provision bare metal machines instead of virtual machines, forked from the Nova baremetal driver. It is best thought of as a bare metal hypervisor API and a set of plugins which interact with the bare metal hypervisors. By default, it will use PXE and IPMI in order to provision and turn on/off machines.

Download and Setup the osic-prep LXC Container
----------------------------------------------

You have now successfully provisioned your own deployment host and should now be able to ssh to it using the IP address you manually assigned while install
 the deployment host provisioning done, SSH to it.

Next, you will download a pre-packaged LXC container that contains a tool called Cobbler that will be used to PXE boot the rest of the servers. PXE booting is a mechanism where a single server (deployment host) can be used to provision the rest of the servers which use thier PXE-enabled Network Interface Cards to boot from a network hosted kernel.

#### Cobbler overview

There are several tools that implement the PXE mechanism. However, we will use Cobbler since it is powerful, easy to use and handy when it comes to quickly setting up network installation environments. Cobbler is a Linux based provisioning system which lets you, among other things, configure Network installation for each server from its MAC address, manage DNS and serve DHCP requests, etc.

##### Step 1: Setup LXC Linux Bridge

In order to use the LXC container, a new bridge will need to be created: __br-pxe__. The following steps will help you to create a LXC linux bridge.

1. Install the necessary packages:

    ```shell
    apt-get install vlan bridge-utils
    ```

2. Reconfigure the network interface file __/etc/network/interfaces__ to match the following (your IP addresses and ports will most likely be different):
    
    ```
    # The loopback network interface
    auto lo
    iface lo inet loopback

    auto p1p1
    iface p1p1 inet manual

    # Container Bridge
    auto br-pxe
    iface br-pxe inet static
    address 172.22.0.22
    netmask 255.255.252.0
    gateway 172.22.0.1
    dns-nameservers 8.8.8.8 8.8.4.4
    bridge_ports bond0
    bridge_stp off
    bridge_waitport 0
    bridge_fd 0
    ```

3. Bring up __br-pxe__ by running the following commands. It is recommended that you have access to the iLO in case the following commands fail and you lose network connectivity:
    
    ```shell
    ifdown p1p1; ifup br-pxe
    ```
    
##### Step 2: Install LXC  and create osic-prep LXC Container.
The following steps will help you install lxc package and create the lxc container for Cobbler.

1. Install the necessary LXC package:

    ```shell
    apt-get install lxc
    ```
    
2. Change into root's home directory:
  
    ```shell
    cd /root
    ```
    
3. Download the LXC container to the deployment host:

    ```shell
    wget http://23.253.105.87/osic.tar.gz
    ```
    
4. Untar the LXC container:

    ```shell
    tar xvzf /root/osic.tar.gz
    ```
    
5. Move the LXC container directory into the proper directory:
    
    ```shell
    mv /root/osic-prep /var/lib/lxc/
    ```
    
6. Once moved, the LXC container should be __stopped__, verify by running 
    
     ```shell
    `lxc-ls -f`
    ```
    
7. Before starting the LXC container, open __/var/lib/lxc/osic-prep/config__ and change __lxc.network.ipv4 = 172.22.0.22/22__ to a free IP address from the PXE network you are using. Do not forget to set the CIDR notation as well. If your PXE network already is __172.22.0.22/22__, you do not need to make further changes.

    ```
    lxc.network.type = veth
    lxc.network.name = eth1
    lxc.network.ipv4 = 172.22.0.22/22
    lxc.network.link = br-pxe
    lxc.network.hwaddr = 00:16:3e:xx:xx:xx
    lxc.network.flags = up
    lxc.network.mtu = 1500
    ```

8. Start the LXC container:
    
    ```shell
    lxc-start -d --name osic-prep
    ```
    
9. You should now be able to ping the IP address you just set for the LXC container from the host.

##### Step 3: Configure LXC Container.

There are a few configuration changes that need to be made to the pre-packaged LXC container for it to function on your network.

1. Attach to the LXC container by running the following command.

    ```shell
    lxc-attach --name osic-prep
    ```
    
2. If you had to change the IP address above, reconfigure the DHCP server by running the following sed commands. You will need to change __172.22.0.22__ to match the IP address you set above:

    ```shell
    sed -i '/^next_server: / s/ .*/ 172.22.0.22/' /etc/cobbler/settings

    sed -i '/^server: / s/ .*/ 172.22.0.22/' /etc/cobbler/settings
    ```
    
3. Open __/etc/cobbler/dhcp.template__ and reconfigure your DHCP settings. You will need to change the __subnet__, __netmask__, __option routers__, __option subnet-mask__, and __range dynamic-bootp__ parameters to match your network.

    ```
    subnet 172.22.0.0 netmask 255.255.252.0 {
         option routers             172.22.0.1;
         option domain-name-servers 8.8.8.8;
         option subnet-mask         255.255.252.0;
         range dynamic-bootp        172.22.0.23 172.22.0.200;
         default-lease-time         21600;
         max-lease-time             43200;
         next-server                $next_server;
    ```

4. Finally, restart Cobbler and sync it:

    ```shell
    service cobbler restart

    cobbler sync
    ```
    
5. At this point you can PXE boot any servers, but it is still a manual process. In order for it to be an automated process, a CSV file needs to be created.

[Top](https://github.com/osic/ref-impl-kolla/blob/master/documents/1-osic-provisioning.md#overview)

PXE Boot the Servers
--------------------

Once the osic-prep container is create and configured, you are now ready to PXE boot the rest of the servers through your deployment host. This is a two part process.

#### Part 1: Assign Cobbler system profile and generate cobbler systems.

#####Step 1: Update the given input.csv:
The `input.csv` file contains information about your target hosts. The format of the file is as follows:
(hostname,MAC Address,IP Address,Subnet Mask,Gateway,Nameserver,Interface,Cobbler profile,environment)
This file is given as input to a script which generates cobbler system profiles for each target host. The MAC address and interface field of the script is used by cobbler to PXE boot the host.

    
__NOTE:__ before you continue, make sure the generated script __input.csv__ has all the information as shown previously. In case you run into some missing information, you may need to paste the above command in a bash script and execute it.

__1. Copy the contents of `input.csv` to the root directory of `osic-prep` container__

__2. Copy the following script in a python file `update_cobbler_system.py`__
```shell
#!/usr/bin/env python

import csv
import sys
import os
from jinja2 import Environment, FileSystemLoader

input = str(sys.argv[1])


with open(input) as csvfile:
    reader = csv.DictReader(csvfile)
    reader.fieldnames = "hostname", "mac", "ip", "netmask", "gateway", "dns", "interface", "profile"

    for counter, row in enumerate(reader):
        hostname = str(row['hostname'])
        mac = str(row['mac'])
        ip = str(row['ip'])
        netmask = str(row['netmask'])
        gateway = str(row['gateway'])
        dns = str(row['dns'])
        interface = str(row['interface'])

        if row['profile'] is not None:
            profile = str(row['profile'])
        else:
            profile = "ubuntu-14.04.3-server-unattended-rpc"
        comm = "cobbler system add --name="+hostname+" --mac="+mac+" --profile="+profile+" --hostname="+hostname+" --interface="+interface+" --ip-address="+ip+" --subnet=255.255.252.0 --gateway=172.22.0.1 --name-servers=8.8.8.8 --kopts=\"interface="+interface+" quiet=0 console=tty0 console=ttyS0,115200n8\" --server=172.22.0.22"
        os.system(comm)
        print comm
```
__Please make sure you have the proper identation__

__3. Execute the script by giving input as `input.csv`:__
```shell
#Execute the script 
python update_cobbler_system.py input.csv
```

__4. Verfiy whether all the cobbler system profiles are generated:__
```shell
cobbler system list
```

__5. Once all of the __cobbler systems__ are setup, run `cobbler sync`.__
```shell
cobbler sync
```

You are now ready for PXE booting target hosts.


#### Part 2: Begin PXE booting.
 
All the nodes in the Santa Clara cluster are provisioned using Ironic with Openstack Ansible. Due to this the we need to use `nova` commands to reboot the server and set them to PXE boot.

To begin PXE booting simply log in to one of the infra nodes and attach to the utility container. Once inside the container, you will now execute the nova reboot commands.

```shell
#Source credentials
source ~/openrc

#Reboot individual server
nova stop
nova start
```
__NOTE__: For ease of use purpose, the list of servers are mentioned in the 
`hosts_1` file. You simply need to execute `restart.sh` to reboot individual servers.

__NOTE__: In case you want to re-pxeboot servers, make sure to clean old settings from cobbler with the following command:

    for i in `cobbler system list`; do cobbler system remove --name $i; done;

When all servers finish PXE booting, you will now need to set up the individual networks.
