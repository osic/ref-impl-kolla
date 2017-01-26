apt-get update
apt-get install python python-pip python-dev libffi-dev gcc libssl-dev -y
curl -sSL https://get.docker.io | bash
git clone -b stable/newton 
# Creating Docker Registry
sudo mkdir /etc/systemd/system/docker.service.d
sudo tee /etc/systemd/system/docker.service.d/kolla.conf << EOF
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd --storage-driver btrfs --insecure-registry=127.0.0.1:4000
MountFlags=shared
EOF

sudo systemctl daemon-reload

sudo systemctl start docker
sudo docker info
docker run -d -p 4000:5000 --restart=always --name registry registry:2
cp /lib/systemd/system/docker.service /etc/systemd/system/docker.service
