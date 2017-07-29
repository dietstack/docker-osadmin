#!/bin/bash

# Universal build script for docker containers
# Git project name has to start with 'docker-'

# get name of app from the path
# /../../docker-app_name > app_name
APP_NAME=${PWD##*-}

# set version based on the git commit
VERSION=$(git describe --abbrev=7 --tags)

docker build --build-arg http_proxy=${http_proxy:-} \
       --build-arg https_proxy=${https_proxy:-} \
       --build-arg no_proxy=${no_proxy:-} \
       $@ -t $APP_NAME:$VERSION .

docker tag $APP_NAME:$VERSION $APP_NAME:latest
