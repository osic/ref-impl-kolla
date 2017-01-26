#!/bin/bash
for container in $(docker ps -a | grep swift | cut -d " " -f 1); do
    docker stop $container
    docker rm $container
done
