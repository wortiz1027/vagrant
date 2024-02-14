#! /usr/bin/env bash

# Author : Wilman Ortiz
# Copyright (c) developer.io

#######################################################################
#
#	Update and Upgrade Ububtu Base
#
#######################################################################

sudo apt-get update -y
sudo apt upgrade -y

#######################################################################
#
#	Install and Start/Enable Docker
#
#######################################################################

sudo apt install docker.io -y

sudo systemctl start docker
sudo systemctl enable docker

sudo usermod -aG docker "$USER"

#######################################################################
#
#	Add Docker's official GPG key And Add the repository to Apt sources
#
#######################################################################

sudo apt-get install ca-certificates curl libnss3-tools -y
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
	"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |
	sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

sudo apt-get update

sudo apt-get install docker-compose-plugin

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

export APP_SHARED=/vagrant/shared
mkdir -p $APP_SHARED/certs

sudo -H -u vagrant mkcert -cert-file $APP_SHARED/certs/traefik.crt \
	-key-file $APP_SHARED/certs/traefik.key \
	"developer.local" "*.developer.local"

sudo openssl pkcs12 -export -out /vagrant/shared/certs/traefik.p12 -inkey /vagrant/shared/certs/traefik.key -in /vagrant/shared/certs/traefik.crt -passin pass:changeit -passout pass:changeit

#######################################################################
#
#	Init Development Environment
#
#######################################################################

sudo docker volume create pgdata-kc
sudo docker network create --driver bridge ntw_development

sudo docker compose -f $APP_SHARED/docker-compose.yaml up -d

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
# enable remote docker daemon execution => sudo dockerd -H unix:///var/run/docker.sock -H tcp://<remote-ip-address>
# https://docker-docs.uclv.cu/engine/install/binaries/
# docker stop $(docker ps -a -q)
# docker rm $(docker ps -a -q)
