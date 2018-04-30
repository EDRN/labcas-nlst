#!/bin/sh
# Removes all services from the swarm
# then destroys the swarm

eval $(docker-machine env swarm-manager)
docker service rm rabbitmq filemgr wmgr
docker service ls
docker stop visualizer
docker rm visualizer

eval $(docker-machine env swarm-worker1)
docker swarm leave

eval $(docker-machine env swarm-worker2)
docker swarm leave

eval $(docker-machine env swarm-manager)
docker node rm swarm-worker1
docker node rm swarm-worker2
docker swarm leave --force
