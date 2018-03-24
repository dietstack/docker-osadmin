#!/bin/bash
# buildbot test

docker run --rm  ${DOCKER_PROJ_NAME:-''}osadmin:latest openstack
