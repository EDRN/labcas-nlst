#!/bin/sh
# Script to setup a Docker Swarm cluster on a set of local VMs using Swarm Mode

# The swarm is composed of:
# 'swarm-manager' manager node, configured to run a customized OODT file manager and a RabbitMQ broker
# 'swarm-worker1,2' worker nodes, configured to run a customized OODT workflow manager and RabbitMQ consumers

# create all VMs
docker-machine create -d virtualbox swarm-manager
docker-machine create -d virtualbox --virtualbox-memory 2048 swarm-worker1
docker-machine create -d virtualbox --virtualbox-memory 2048 swarm-worker2

# start the swarm
eval $(docker-machine env swarm-manager)
export MANAGER_IP=`docker-machine ip swarm-manager`
docker swarm init --advertise-addr $MANAGER_IP
token_worker=`docker swarm join-token --quiet worker`
token_manager=`docker swarm join-token --quiet manager`

# drain the swarm manager to prevent assigment of tasks
#docker node update --availability drain swarm-manager

# start swarm visualizer on swarm manager
docker run -it -d --name visualizer -p 5000:8080 -e HOST=$MANAGER_IP -v /var/run/docker.sock:/var/run/docker.sock dockersamples/visualizer

# join the swarm
eval $(docker-machine env swarm-worker1)
docker swarm join --token $token_worker $MANAGER_IP:2377

eval $(docker-machine env swarm-worker2)
docker swarm join --token $token_worker $MANAGER_IP:2377

# create overlay network
eval $(docker-machine env swarm-manager)
docker network create -d overlay swarm-network

# assign functional labels to nodes
eval $(docker-machine env swarm-manager)
docker node update --label-add oodt_type=oodt_manager swarm-manager
docker node update --label-add oodt_type=oodt_worker swarm-worker1
docker node update --label-add oodt_type=oodt_worker swarm-worker2

# start RabbitMQ server
eval $(docker-machine env swarm-manager)
docker service create --replicas 1 --name rabbitmq -p 5672:5672 -p 15672:15672 \
       --network swarm-network --constraint 'node.labels.oodt_type==oodt_manager' \
       --env 'RABBITMQ_USER_URL=amqp://oodt-user:changeit@localhost/%2f' \
       --env 'RABBITMQ_ADMIN_URL=http://oodt-admin:changeit@localhost:15672'\
       --mount type=bind,src=${PWD}/../scripts/nlst_workflow_driver.py,dst=/usr/local/oodt/rabbitmq/nlst_workflow_driver.py \
       acce/oodt-rabbitmq:${ACCE_VERSION}

# start OODT File Manager on swarm-manager
docker service create --replicas 1 --name filemgr -p 9000:9000 -p 8983:8983 \
       --network swarm-network --constraint 'node.labels.oodt_type==oodt_manager' \
       --mount type=bind,src=${PWD}/../config/nlst-workflow,dst=/usr/local/oodt/workflows/nlst-workflow \
       --mount type=bind,src=${OODT_JOBS},dst=/usr/local/oodt/jobs \
       --mount type=bind,src=${OODT_ARCHIVE},dst=/usr/local/oodt/archive \
       acce/oodt-filemgr:${ACCE_VERSION}

# wait for rabbitmq server to become available
# then start workflow managers on worker nodes
# including rabbitmq consumers for workflow 'nlst-workflow'
sleep 5
docker service create --replicas 1 --name wmgr --network swarm-network --constraint 'node.labels.oodt_type==oodt_worker' \
                      --mount type=bind,src=${OODT_JOBS},dst=/usr/local/oodt/jobs \
                      --mount type=bind,src=${OODT_ARCHIVE},dst=/usr/local/oodt/archive \
                      --mount type=bind,src=${NLST_DATA},dst=/NLST_trial \
                      --mount type=bind,src=${PWD}/../config/nlst-workflow,dst=/usr/local/oodt/workflows/nlst-workflow \
                      --env 'RABBITMQ_USER_URL=amqp://oodt-user:changeit@rabbitmq/%2f' \
                      --env 'RABBITMQ_ADMIN_URL=http://oodt-admin:changeit@rabbitmq:15672' \
                      --env 'FILEMGR_URL=http://filemgr:9000/' \
                      --env 'WORKFLOW_URL=http://localhost:9001/' \
                      --env 'WORKFLOW_QUEUE=nlst-workflow' \
                      --env 'MAX_WORKFLOWS=1' \
                      edrn/labcas-nlst:latest
docker service scale wmgr=2
