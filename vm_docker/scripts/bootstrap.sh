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
#	Start/Enable Docker
#
#######################################################################

sudo systemctl start docker
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
echo "- - - 1 - - -"
sudo apt install nfs-kernel-server -y

sudo mkdir -p /mnt/nfs/docker_client
sudo mount 192.168.56.9:/mnt/nfs/share_dck_data	/mnt/nfs/docker_client

#######################################################################
#
#	Install And Config MkCert For Local CA Authority
#
#######################################################################
echo "- - - 2 - - -"
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
echo "- - - 3 - - -"
export APP_SHARED=/home/vagrant/shared
mkdir -p $APP_SHARED/certs

sudo -H -u vagrant mkcert -cert-file $APP_SHARED/certs/traefik.crt \
	-key-file $APP_SHARED/certs/traefik.key \
	"developer.dck" "*.developer.dck"

sudo openssl pkcs12 -export -out /vagrant/shared/certs/traefik.p12 -inkey /vagrant/shared/certs/traefik.key -in \
/vagrant/shared/certs/traefik.crt -passin pass:changeit -passout pass:changeit

#######################################################################
#
#	Downloading PostgreSQL Database Example
#
#######################################################################
echo "- - - 4 - - -"
mkdir -p $HOME/postgres-examples
wget -o $HOME/postgres-examples/dvdrental.zip https://www.postgresqltutorial.com/wp-content/uploads/2019/05/dvdrental.zip
wget -o $HOME/postgres-examples/demo-big-en.zip https://edu.postgrespro.com/demo-big-en.zip

#######################################################################
#
#	Init Development Environment
#
#######################################################################
echo "- - - 5 - - -"
sudo docker volume create pgdata-kc
sudo docker volume create pgdata-lr
sudo docker volume create pgdata-ak
sudo docker volume create mysqldata-st
sudo docker volume create mongo-st
sudo docker volume create pgadmin
sudo docker volume create redis_data
sudo docker volume create influxdb-storage
sudo docker volume create grafana-storage
sudo docker volume create ubuntu-storage
sudo docker volume create oracle-data
sudo docker volume create oracle-backup
sudo docker volume create minio-storage
sudo docker volume create redis-ak

sudo docker network create --driver bridge ntw_development

sudo docker compose -f $APP_SHARED/docker-compose.yaml up -d

#######################################################################
#
#	Enable ports
#
#######################################################################
echo "- - - 6 - - -"
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

# https://ldap.developer.dck/
# login DN: cn=admin,dc=developer,dc=dck
# password: Ldap2024..

# Static table lookup for hostnames.
# See hosts(5) for details.

#######################################################################
#
#	Config disk size for VirtualBox
#
#######################################################################

# vboxmanage list hdds
# vboxmanage closemedium disk 28073872-20c8-456f-be4d-d034cbb993e3 --delete
# vboxmanage clonehd "ubuntu-24.04-amd64-disk001.vmdk" "ubuntu-24.04-amd64-disk001.vdi" --format VDI
# vboxmanage modifyhd "ubuntu-24.04-amd64-disk001.vdi" --resize 160000

#######################################################################
#
#	Resize mount point vm ubuntu
#	https://superuser.com/questions/1810230/how-to-expand-ubuntu-server-root-storage
#
#######################################################################

# sudo parted -s -a opt /dev/sda "resizepart 3 100%"
# sudo pvresize /dev/sda3
# sudo lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv
# sudo resize2fs /dev/ubuntu-vg/ubuntu-lv

#######################################################################
#
#	Run Ollama Models
#
#######################################################################

# docker exec -it server_ollama ollama run qwen2.5-coder:7b

#######################################################################
#
#	INSTALL DATABASE FOR POSTGRES
#
#######################################################################

# docker exec -it server_postgres_lr /bin/bash

# cd /home
# mkdir postgres
# apt update
# apt install wger unzip
# wget https://www.postgresqltutorial.com/wp-content/uploads/2019/05/dvdrental.zip

# unzip dvdrental.zip
# pg_restore --host "localhost" --port "5432" --username "learning" --no-password --dbname "dvdrental" --verbose "/home/dvdrental.tar"

#######################################################################
#
#	INSTALL DATABASE FOR MySQL
#
#######################################################################

# docker exec -it server_mysql_st /bin/bash

# microdnf install -y unzip wget

# mkdir mysql
# cd mysql/
# wget https://www.mysqltutorial.org/wp-content/uploads/2023/10/mysqlsampledatabase.zip
# wget https://downloads.mysql.com/docs/sakila-db.zip

# unzip mysqlsampledatabase.zip
# unzip sakila-db.zip

# mysql -u root -p

# mysql> source /home/mysql/mysqlsampledatabase.sql

# mysql> source /home/mysql/sakila-db/sakila-schema.sql
# mysql> source /home/mysql/sakila-db/sakila-data.sql

# CREATE USER 'sakila'@'%' IDENTIFIED WITH mysql_native_password BY 'sakila2024..';
# GRANT ALL ON sakila.* TO 'sakila'@'%';

# CREATE USER 'model'@'%' IDENTIFIED WITH mysql_native_password BY 'model2024..';
# GRANT ALL ON classicmodels.* TO 'model'@'%';

#######################################################################
#
#	/etc/hosts File
#
#######################################################################
#127.0.0.1   localhost localhost.localdomain
#::1         localhost localhost.localdomain
#
## K8S Cluster
#192.168.56.11 k8s-master-1
#192.168.56.12 k8s-node-1
#192.168.56.13 k8s-node-2
#192.168.56.14 k8s-node-3
#
## Docker Services
#192.168.56.10 traefik.developer.dck
#192.168.56.10 logs.developer.dck
#192.168.56.10 portainer.developer.dck
#192.168.56.10 whoami.developer.dck
#192.168.56.10 redis.developer.dck
#192.168.56.10 pgadmin.developer.dck
#192.168.56.10 me.developer.dck
#192.168.56.10 keycloak.developer.dck
#192.168.56.10 jaeger.developer.dck
#192.168.56.10 prometheus.developer.dck
#192.168.56.10 rabbit.developer.dck
#
#192.168.56.10 keycloak.postgres.developer.dck
#192.168.56.10 learning.postgres.developer.dck
#
#192.168.56.10 grafana.developer.dck
#192.168.56.10 influxdb.developer.dck
#192.168.56.10 ldap.developer.dck
#192.168.56.10 jenkins.developer.dck

#192.168.56.10 ollama.developer.dck
#192.168.56.10 minio.developer.dck
#192.168.56.10 minio-api.developer.dck
#192.168.56.10 insight.developer.dck
