#!/bin/bash

##Make out put dir if it doesn't exist so we can use it as a Docker volume. 
[[ -d output ]] || mkdir output

docker build --no-cache -t danielsteinke/dscom .

docker run --env-file ../ds_env_secrets.env -v $PWD/output:/code/danielsteinke.com/output danielsteinke/dscom 
