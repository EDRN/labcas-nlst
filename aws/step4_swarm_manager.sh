#!/bin/bash
# Instantiates services on the swarm.
# Note that each service mounts a shared local directory.
# Use placement constraints with pre-built node types
# so that labels don't have to be assigned every time an EC2 instance is started:
# - 'node.role==manager'
# - 'node.role==worker'

# OODT file manager
docker service create --replicas 1 --name filemgr -p 9000:9000 -p 8983:8983 \
       --network swarm-network --constraint 'node.role==manager' \
       --mount type=bind,src=${NLST_SRC}/config/nlst-workflow,dst=/usr/local/oodt/workflows/nlst-workflow \
       --mount type=bind,src=${OODT_JOBS},dst=/usr/local/oodt/jobs \
       --mount type=bind,src=${OODT_ARCHIVE},dst=/usr/local/oodt/archive \
       acce/oodt-filemgr:${ACCE_VERSION}

# RMQ server
docker service create --replicas 1 --name rabbitmq -p 5672:5672 -p 15672:15672 \
       --network swarm-network --constraint 'node.role==manager' \
       --env 'RABBITMQ_USER_URL=amqp://oodt-user:changeit@localhost/%2f' \
       --env 'RABBITMQ_ADMIN_URL=http://oodt-admin:changeit@localhost:15672'\
       --mount type=bind,src=${NLST_SRC}/scripts/nlst_workflow_driver.py,dst=/usr/local/oodt/rabbitmq/nlst_workflow_driver.py \
       acce/oodt-rabbitmq:${ACCE_VERSION}

# OODT Workflow Manager with NLST software
docker service create --replicas 1 --name wmgr --network swarm-network --constraint 'node.role==worker' \
                      --mount type=bind,src=${OODT_JOBS},dst=/usr/local/oodt/jobs \
                      --mount type=bind,src=${OODT_ARCHIVE},dst=/usr/local/oodt/archive \
                      --mount type=bind,src=${NLST_DATA},dst=/NLST_trial \
                      --mount type=bind,src=${NLST_SRC}/config/nlst-workflow,dst=/usr/local/oodt/workflows/nlst-workflow \
                      --env 'RABBITMQ_USER_URL=amqp://oodt-user:changeit@rabbitmq/%2f' \
                      --env 'RABBITMQ_ADMIN_URL=http://oodt-admin:changeit@rabbitmq:15672' \
                      --env 'FILEMGR_URL=http://filemgr:9000/' \
                      --env 'WORKFLOW_URL=http://localhost:9001/' \
                      --env 'WORKFLOW_QUEUE=nlst-workflow' \
                      --env 'MAX_WORKFLOWS=1' \
                      edrn/labcas-nlst:latest
