#!/bin/bash

if [[ $EUID -ne 0 ]]; then
	    echo "This script must be run as root."
	        exit 1
fi

mkdir -p /etc/apt/keyrings

wget -O- https://apt.releases.hashicorp.com/gpg | \
	gpg --dearmor | \
	tee /usr/share/keyrings/hashicorp-archive-keyring.gpg

curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
	| sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

curl -sLS https://packages.microsoft.com/keys/microsoft.asc |
	    gpg --dearmor |
	        tee /etc/apt/keyrings/microsoft.gpg > /dev/null
chmod go+r /etc/apt/keyrings/microsoft.gpg

AZ_DIST=$(lsb_release -cs)
echo "deb [arch=`dpkg --print-architecture` signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ $AZ_DIST main" \
	| tee /etc/apt/sources.list.d/azure-cli.list

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
	https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
	tee /etc/apt/sources.list.d/hashicorp.list

echo "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
	"$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" \
	| sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update;
apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin terraform azure-cli -y


