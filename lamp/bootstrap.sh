#!/usr/bin/env bash

apt-get update
apt-get upgrade -y

apt-get install apache2 -y
apt-get install curl -y
# apt-get install mysql-server -y # up to you to run mysql_secure_installation
# apt-get install php libapache2-mod-php php-mcrypt php-mysql php-myadmin -y
if ! [ -L /var/www ]; then
	rm -rf /var/www
	ln -fs /vagrant/ /var/www
fi
