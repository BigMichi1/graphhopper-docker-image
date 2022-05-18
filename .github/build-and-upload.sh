#!/bin/bash

echo "Cloning graphhopper"
git clone https://github.com/graphhopper/graphhopper.git
cd graphhopper
echo "Downloading Dockerfile and graphhopper.sh"
curl -L https://raw.githubusercontent.com/BigMichi1/graphhopper-docker-image/main/Dockerfile > Dockerfile
curl -L https://raw.githubusercontent.com/BigMichi1/graphhopper-docker-image/main/graphhopper.sh > graphhopper.sh
chmod +x ./graphhopper.sh
echo "Building docker image"
docker build . -t bigmichi1/graphhopper:latest
docker login --username $DOCKERHUB_USER --password $DOCKERHUB_TOKEN
echo "Publishing docker image"
docker push bigmichi1/graphhopper:latest

TAG=`git for-each-ref --sort=committerdate refs/tags | tail -n 1 | cut -d "/" -f3`
if docker manifest inspect bigmichi1/graphhopper:$TAG >/dev/null; then 
    echo "No need to publish existing version: $TAG";
else
    mv Dockerfile ../Dockerfile
    mv graphhopper.sh ../graphhopper.sh
    git checkout tags/$TAG
    mv ../Dockerfile Dockerfile
    mv ../graphhopper.sh graphhopper.sh
    echo "Building docker image for tag: $TAG"
    docker build . -t bigmichi1/graphhopper:$TAG
    echo "Publishing docker image for tag: $TAG"
    docker push bigmichi1/graphhopper:$TAG
fi


