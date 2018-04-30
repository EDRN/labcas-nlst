# Docker image to execute LabCAS NLST workflow
ARG ACCE_VERSION=latest
FROM acce/oodt-wmgr:${ACCE_VERSION}
MAINTAINER Luca Cinquini <luca.cinquini@jpl.nasa.gov>

RUN apt-get update
RUN apt-get install -y bzip2 vim
RUN apt-get install -y libglapi-mesa libosmesa6

# install anaconda
RUN cd /tmp && \
    curl -O 'https://repo.continuum.io/archive/Anaconda3-5.1.0-Linux-x86_64.sh'
ENV ANACONDA_HOME=/usr/local/anaconda3
RUN cd /tmp && \
    chmod +x Anaconda3-5.1.0-Linux-x86_64.sh && \
    bash Anaconda3-5.1.0-Linux-x86_64.sh -b -p $ANACONDA_HOME

# install additional dependencies
RUN /bin/bash -c "source $ANACONDA_HOME/bin/activate && \
    pip install numpy && \
    pip install dicom && \
    pip install scipy && \
    pip install matplotlib && \
    pip install Pillow && \
    pip install pandas && \
    pip install scikit-image"
ENV PATH=$ANACONDA_HOME/bin:$PATH

# install custom OODT Workflow Manager configuration
COPY config/nlst-workflow $OODT_CONFIG/nlst-workflow

# install custom PGEs
COPY pges/nlst-workflow $PGE_ROOT/nlst-workflow
