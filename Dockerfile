# Docker image to execute LabCAS NLST workflow
ARG ACCE_VERSION=latest
FROM acce/oodt-wmgr:${ACCE_VERSION}
MAINTAINER Luca Cinquini <luca.cinquini@jpl.nasa.gov>

RUN apt-get update
RUN apt-get install -y bzip2 vim
RUN apt-get install -y libglapi-mesa libosmesa6

# install miniconda
RUN cd /tmp && \
    curl -O 'https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh'
ENV CONDA_HOME=/usr/local/miniconda3
RUN cd /tmp && \
    chmod +x Miniconda3-latest-Linux-x86_64.sh && \
    bash Miniconda3-latest-Linux-x86_64.sh -b -p $CONDA_HOME

# install additional dependencies
RUN /bin/bash -c "source $CONDA_HOME/bin/activate && \
    pip install numpy && \
    pip install dicom && \
    pip install scipy && \
    pip install matplotlib && \
    pip install Pillow && \
    pip install pandas && \
    pip install scikit-image"
ENV PATH=$CONDA_HOME/bin:$PATH:/usr/local/bin

# install custom OODT Workflow Manager configuration
COPY config/nlst-workflow $OODT_CONFIG/nlst-workflow

# install custom PGEs
COPY pges/nlst-workflow $PGE_ROOT/nlst-workflow

# additional supervisor configuration to start rabbitmq client
COPY config/supervisor/supervisord-rmqclient.conf /etc/supervisor/conf.d/supervisord-rmq-client.conf

