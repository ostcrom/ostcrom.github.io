#!/bin/bash

if [[ $EUID -ne 0 ]]; then
	    echo "This script must be run as root."
	        exit 1
fi

mkdir -p /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
	| sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
	"$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" \
	| sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update;
apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin make git -y


