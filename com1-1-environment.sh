#!/bin/bash

#Author Son Do Xuan

source function.sh
source config.cnf

# update and upgrade for compute1
echocolor "Update and Update compute1"
sleep 3
apt-get update -y&& apt-get upgrade -y

# Install crudini
echocolor "Install crudini"
sleep 3
apt-get install -y crudini


# Install and config NTP
echocolor "Install NTP"
sleep 3

apt-get install chrony -y
ntpfile=/etc/chrony/chrony.conf

sed -i 's/pool 2.debian.pool.ntp.org offline iburst/ \
server controller iburst/g' $ntpfile

service chrony restart


# OpenStack packages (python-openstackclient)
echocolor "Install OpenStack client"
sleep 3
apt-get install software-properties-common -y
add-apt-repository cloud-archive:ocata -y
apt-get update -y && apt-get dist-upgrade -y

apt-get install python-openstackclient -y






