FROM alpine:3.9

# Prepare
RUN apk add --no-cache bash nano curl wget sudo
RUN adduser \
    --disabled-password \
    --gecos "" \
    "docker"
RUN echo 'docker:docker' | chpasswd
RUN addgroup sudo
RUN adduser docker sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
ENV HOME /home/docker
WORKDIR /home/docker