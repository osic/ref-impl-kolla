Part 1: Creating docker registry
================================

Openstack Kolla uses docker images to install OpenStack services. For multinode deployment, Openstack kolla uses the docker registry running on the deployment host to pull images and create containers. 


About Docker Registry
---------------------
The Registry is a stateless, highly scalable server side application that stores and lets you distribute Docker images. 
The docker registry is created on the deployment host. This registry allows target nodes to pull images from a centralized deployment host instead of pushing images individually on each target host.

The following steps should be performed on the __deployment host__:

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
apt-get install python python-pip python-dev libffi-dev gcc libssl-dev curl -y

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


#For mounting /run as shared upon startup, add that command to /etc/rc.local:
mount --make-shared /run
```

##### Step 4: Create Docker Regsistry.

```shell
docker run -d -p 4000:5000 --restart=always --name registry registry:2
```


##### Step 5: Edit default docker configuration to point to newly created registry.

```shell
echo "DOCKER_OPTS=\"--insecure-registry `hostname -I | cut -d ' ' -f 1`:4000\"" >> /etc/default/docker
```

##### Step 6: Copy docker service located in lib to /etc/systemd. 

```shell
# Copy docker’s systemd unit file to /etc/systemd/system/ directory.
cp /lib/systemd/system/docker.service /etc/systemd/system/docker.service
```

##### Step 7: Copy the following in `/etc/systemd/system/docker.service` to add the environmentFile variable and $DOCKER_OPTS under the `[service]` section.

Note: Do not execute the command. Just copy it to above file.
```
EnvironmentFile=-/etc/default/docker
ExecStart=/usr/bin/docker daemon -H fd:// $DOCKER_OPTS
```

##### Step 8: Restart docker by executing the following commands.

```shell
sudo service docker restart
```

#### Step 9: Verfiy Docker registry is running. This should output a container by the name `registry:2`.

```shell
docker ps -a
```

You should have successfully created docker registry on your deployment host. Next step is to deploy Kolla on target nodes.
