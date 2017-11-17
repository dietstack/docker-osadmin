#!/bin/bash

## CONTROL VARIABLES
## If you are using different floating subnet you need to set following variables
## FLOATING_IP_SUBNET=192.168.12.0/24 JUST_EXTERNAL_IP=192.168.12.2 ./first_vm.sh

export FLOATING_IP_SUBNET=${FLOATING_IP_SUBNET:-"192.168.99.0/24"} # mandatory
export INTERNAL_SUBNET=${INTERNAL_SUBNET:-"192.168.35.0/24"} # mandatory

FLOATING_IP_SIZE=$(python -c 'import os,ipaddress; print(ipaddress.ip_network(os.environ["FLOATING_IP_SUBNET"]).num_addresses);')
if [ "$FLOATING_IP_SIZE" -lt "64" ]; then
    echo "Floating subnet too small. Must be at least /26."
    exit 1
fi

FLOATING_IP_GW=${FLOATING_IP_GW:-`python -c 'import os,ipaddress; print(ipaddress.ip_network(os.environ["FLOATING_IP_SUBNET"]).hosts().next());'`}
# It would be better to find whether there is already IP from FLOATING_IP_SUBNET on any
# interface and if yes, use it. It's TODO.

# FLOATING_IP_POOL format: "192.168.99.10-192.168.99.20"
FLOATING_IP_POOL=${FLOATING_IP_POOL:-`python -c 'import os,ipaddress; net = list(ipaddress.ip_network(os.environ["FLOATING_IP_SUBNET"]).hosts()); print("%s-%s" % (str(net[10]), str(net[len(net)-10])))'`}

FLOATING_IP_START=$(echo $FLOATING_IP_POOL | cut -f1 -d-)
FLOATING_IP_END=$(echo $FLOATING_IP_POOL | cut -f2 -d-)

# Gateway for internal network
INTERNAL_GW=`python -c 'import os,ipaddress; print(ipaddress.ip_network(os.environ["INTERNAL_SUBNET"]).hosts().next());'`

# JUST_EXTERNAL_IP is IP of controller in external network. In LocalStack default is same as $FLOATING_IP_GW
# JUST_EXTERNAL_IP has to be in format 192.168.12.2
JUST_EXTERNAL_IP=${JUST_EXTERNAL_IP:-$FLOATING_IP_GW}

# If proxy is in use, ensure that dietstack IPs are not router to proxy servers
export no_proxy=127.0.0.1,localhost,$FLOATING_IP_GW,$JUST_EXTERNAL_IP

## ADMIN PART ##

. adminrc

# Add basic flavor
openstack flavor create --id 0 --vcpus 1 --ram 64 --disk 1 m1.nano

# Prepare external provider network (floating IPs)
openstack network create --external --provider-physical-network external --provider-network-type flat external
openstack subnet create --network external --allocation-pool start=$FLOATING_IP_START,end=$FLOATING_IP_END --dns-nameserver 127.0.0.1 --gateway $FLOATING_IP_GW --subnet-range $FLOATING_IP_SUBNET external

# Prepare external connectivity
openstack network set --external external

## USER PART ##

. demorc
test -f ~/.ssh/id_rsa || ssh-keygen -f ~/.ssh/id_rsa -q -N ""
openstack keypair create --public-key ~/.ssh/id_rsa.pub mykey

# enable all traffic be default
openstack security group rule create --proto icmp --dst-port -1 --ingress default
openstack security group rule create --proto icmp --dst-port -1 --egress default
openstack security group rule create --proto udp --dst-port 1:65535 default
openstack security group rule create --proto tcp --dst-port 1:65535 default
openstack security group rule create --proto udp --dst-port 1:65535 --egress default
openstack security group rule create --proto tcp --dst-port 1:65535 --egress default

# Prepare Self-service network
openstack network create internal
openstack subnet create --network internal --dns-nameserver 8.8.8.8 --gateway $INTERNAL_GW --subnet-range $INTERNAL_SUBNET internal

# Prepare Router to extrenal network
openstack router create router
openstack router set --external-gateway external router
openstack router add subnet router internal

# Find out id of internal network
internal_id=$(openstack network list -f value | awk '/internal/ {print $1}')

# Run VM
openstack server create --flavor m1.nano --image cirros --nic net-id=$internal_id --security-group default --key-name mykey first-vm

echo "Wait till vm as active before assigning floating ip"
timeout 30 bash -c -- 'while [[ `openstack server list --format=csv | grep first-vm | cut -d"," -f 3` != "\"ACTIVE\"" ]]; do echo -n ". "; sleep 5; done'
echo ""

# Attach floating IP to VM
openstack floating ip create external
floating_ip=$(openstack floating ip list -f value | head -n 1 | awk '{print $2}')
openstack server add floating ip first-vm $floating_ip

echo "Success :). To connect to fist vm run 'ssh cirros@$floating_ip'"

