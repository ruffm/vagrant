#!/usr/bin/env bash

apt-get update
apt-get upgrade -y

apt-get install apache2 -y

if ! [ -L /var/www ]; then
	rm -rf /var/www
	ln -fs /vagrant/ /var/www
fi
