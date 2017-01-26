Creating docker registry
------------------------

Openstack Kolla uses docker images to install OpenStack services. For multinode deployment, Openstack kolla uses the docker registry running on the deployment host to pull images and create containers. The following steps should be performed on the deployment host:

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
