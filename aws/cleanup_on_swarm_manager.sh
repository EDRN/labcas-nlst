#!/bin/sh
# Script to destroy the Docker swarm on AWS

docker service rm rabbitmq filemgr wmgr
docker service ls
docker stop visualizer

# note: if manager leaves the swarm, all workers are lost
docker swarm leave --force
