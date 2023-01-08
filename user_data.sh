#!/bin/bash
sudo apt-get update -y
sudo apt-get install nginx -y
sudo systemctl start nginx.service
sudo systemctl enable nginx.service
host=$(hostname)
ip=$(ifconfig | grep 'inet ' | grep -v '127.0.0.1' | cut -c 7-17)
sudo chown -R $USER:$USER /var/www
echo 'Hi! Abdul-Barri deployed this server. Host name / IP address for this server is '$host'' > /var/www/html/index.nginx-debian.html