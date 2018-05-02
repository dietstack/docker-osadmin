#!/bin/bash
# buildbot test 2

docker run --rm  ${DOCKER_PROJ_NAME:-''}osadmin:latest openstack
