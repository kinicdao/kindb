# FROM --platform=linux/amd64 ubuntu:23.04
FROM ubuntu:23.04


# Install a basic environment needed for our build tools
RUN apt-get -yq update && \
  apt-get -yqq install --no-install-recommends \
  wget

RUN apt-get -yq update && \
  apt-get -yqq install --no-install-recommends curl ca-certificates \
    build-essential pkg-config libssl-dev llvm-dev liblmdb-dev clang cmake rsync

# Install reprotest
RUN apt-get -yqq install --no-install-recommends reprotest disorderfs faketime sudo wabt

# Install vessel
WORKDIR /usr/local/bin
RUN wget --no-check-certificate https://github.com/dfinity/vessel/releases/download/v0.6.5/vessel-linux64
RUN mv vessel-linux64 vessel
RUN chmod +x vessel

# Set locale
RUN apt-get -yqq install locales
RUN locale-gen en_US.UTF-8  
ENV LANG en_US.UTF-8  
ENV LANGUAGE en_US:en  
ENV LC_ALL en_US.UTF-8

RUN mkdir /project_root
WORKDIR /project_root
