#!/bin/sh
# Initializes the swarm, starts swarm visualizer tool.

# note: the private EX2 instance IP address is available like so:
export MANAGER_IP=`curl http://169.254.169.254/latest/meta-data/local-ipv4`
docker swarm init --advertise-addr $MANAGER_IP
token_worker=`docker swarm join-token --quiet worker`
echo $token_worker

docker network create -d overlay swarm-network

docker run -it --rm -d --name visualizer -p 8080:8080 -e HOST=$MANAGER_IP -v /var/run/docker.sock:/var/run/docker.sock dockersamples/visualizer

