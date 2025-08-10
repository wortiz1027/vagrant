#! /usr/bin/env bash

# Author : Wilman Ortiz
# Copyright (c) developer.io

#######################################################################
#
#	Update and Upgrade Ubuntu Base
#
#######################################################################

sudo apt-get update -y
sudo apt upgrade -y

#######################################################################
#
#	Adjust disk size for VirtualBox
# 	https://blog.devops.dev/how-to-resize-your-root-partition-and-extends-lvm-size-on-ubuntu-20-04-2e0d5bd0411
#	https://marcbrandner.com/blog/increasing-disk-space-of-a-linux-based-vagrant-box-on-provisioning/
#	https://peateasea.de/resizing-the-disk-on-a-vagrant-virtual-machine/
#	https://medium.com/@kanrangsan/how-to-automatically-resize-virtual-box-disk-with-vagrant-9f0f48aa46b3
#	https://www.jeffgeerling.com/blogs/jeff-geerling/resizing-virtualbox-disk-image
#
#######################################################################

sudo growpart /dev/sda 3
sudo pvresize /dev/sda3
sudo lvm lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv
sudo resize2fs -p /dev/mapper/ubuntu--vg-ubuntu--lv
lsblk

#######################################################################
#
#	Install Docker
#
#######################################################################

sudo apt install docker.io -y

#######################################################################
#
#	Config Docker Daemon and expose port: 2375
#
#######################################################################

sudo mkdir -p /etc/systemd/system/docker.service.d

sudo sh -c "cat >>/etc/docker/daemon.json" <<-EOF
{
	"hosts": [
		"unix:///var/run/docker.sock",
		"tcp://0.0.0.0:2375"
	]
}
EOF

sudo sh -c "cat >>/etc/systemd/system/docker.service.d/override.conf" <<-EOF
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd --config-file /etc/docker/daemon.json
EOF

#######################################################################
#
#	Start/Enable Docker
#
#######################################################################

sudo systemctl daemon-reload
sudo systemctl restart docker
sudo systemctl enable docker

sudo usermod -aG docker "$USER"

#######################################################################
#
#	Install Docker Compose
#
#######################################################################

sudo apt-get install ca-certificates curl libnss3-tools -y
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
	"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
	$(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
	sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y

sudo apt-get install docker-compose-plugin -y

#######################################################################
#
#	Config NFS Client
#
#######################################################################
sudo apt install nfs-kernel-server net-tools -y

sudo mkdir -p /mnt/nfs/docker_client
sudo mount 192.168.56.9:/mnt/nfs/share_dck_data	/mnt/nfs/docker_client

#######################################################################
#
#	Install And Config MkCert For Local CA Authority
#
#######################################################################
wget https://github.com/FiloSottile/mkcert/releases/download/v1.4.4/mkcert-v1.4.4-linux-amd64
sudo mv mkcert-v1.4.4-linux-amd64 /usr/bin/mkcert
sudo chmod +x /usr/bin/mkcert

sudo -H -u vagrant echo $(mkcert --version)
sudo -H -u vagrant echo $(mkcert -install)

#######################################################################
#
#	Use MkCert to Generate Certificates
#
#######################################################################
export APP_SHARED=/home/vagrant/shared
mkdir -p $APP_SHARED/certs

sudo -H -u vagrant mkcert -cert-file $APP_SHARED/certs/traefik.crt \
	-key-file $APP_SHARED/certs/traefik.key \
	"developer.dck" "*.developer.dck"

sudo openssl pkcs12 -export -out /vagrant/shared/certs/traefik.p12 -inkey /vagrant/shared/certs/traefik.key -in \
/vagrant/shared/certs/traefik.crt -passin pass:changeit -passout pass:changeit

sudo docker network create --driver bridge ntw_development

#######################################################################
#
#	Enable ports
#
#######################################################################
sudo ufw allow 80
sudo ufw allow 443

#######################################################################
#
#	Additional Comments Or Suggestion
#
#######################################################################
# sudo openssl pkcs12 -info -in /vagrant/shared/certs/traefik.p12 -nodes
# scp -r vagrant@192.168.56.10:/home/vagrant/.local/share/mkcert ~/.local/share/
# sudo usermod -aG docker $USER
# docker volume create pgdata
# sudo systemctl stop docker
# sudo systemctl stop docker.socket
# enable remote docker daemon execution => sudo dockerd -H unix:///var/run/docker.sock -H tcp://192.168.56.10
# https://docker-docs.uclv.cu/engine/install/binaries/
# docker stop $(docker ps -a -q)
# docker rm $(docker ps -a -q)
# docker volume rm $(docker volume ls -q)
