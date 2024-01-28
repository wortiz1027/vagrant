#! /usr/bin/env bash

sudo apt-get update -y
sudo apt upgrade -y

sudo apt install docker.io -y

sudo systemctl start docker
sudo systemctl enable docker

sudo usermod -aG docker "$USER"

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
	"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |
	sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

sudo apt-get update

sudo apt-get install docker-compose-plugin

export APP_SHARED=/app/shared

sudo docker compose -f $APP_SHARED/docker-compose-portainer.yaml up -d

# enable remote docker daemon execution => sudo dockerd -H unix:///var/run/docker.sock -H tcp://<remote-ip-address>
# https://docker-docs.uclv.cu/engine/install/binaries/
