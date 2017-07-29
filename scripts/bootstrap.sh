#!/bin/bash
# Script creates keystone items for basic cloud operation
# Ref: http://docs.openstack.org/liberty/install-guide-ubuntu/keystone-services.html
# Public IP endpoint needs to be adjust according to environment
# When change is done script returns 0. If no change is done, returns 128 - this done
# due to ansible change detection

SERVICE=${SERVICE:-''}

PUBLIC_IP=${PUBLIC_IP:-127.0.0.1}
INTERNAL_IP=${INTERNAL_IP:-127.0.0.1}
ADMIN_IP=${ADMIN_IP:-127.0.0.1}
PASSWORD=${PASSWORD:-veryS3cr3t}

# if any of those passwords are set externally, PASSWORD value will be overloaded
KEYSTONE_SVC_PASS=${KEYSTONE_SVC_PASS:-$PASSWORD}
KEYSTONE_DEMO_PASS=${KEYSTONE_DEMO_PASS:-$PASSWORD}
GLANCE_SVC_PASS=${GLANCE_SVC_PASS:-$PASSWORD}
NOVA_SVC_PASS=${NOVA_SVC_PASS:-$PASSWORD}
NOVA_PLACEMENT_SVC_PASS=${NOVA_PLACEMENT_SVC_PASS:-$PASSWORD}
NEUTRON_SVC_PASS=${NEUTRON_SVC_PASS:-$PASSWORD}
CINDER_SVC_PASS=${CINDER_SVC_PASS:-$PASSWORD}
HEAT_SVC_PASS=${HEAT_SVC_PASS:-$PASSWORD}

CHANGED=0

# keystone
if ([ -z "$SERVICE" ]  || [ "$SERVICE" = "keystone" ]); then
    openstack service list -f value | grep -w identity
    if [ "$?" -ne 0 ]; then
        openstack service create --name keystone --description "OpenStack Identity" identity

        # create default domain
        openstack domain create default

        openstack endpoint create --region RegionOne identity public http://$PUBLIC_IP:5000/v3
        openstack endpoint create --region RegionOne identity internal http://$INTERNAL_IP:5000/v3
        openstack endpoint create --region RegionOne identity admin http://$ADMIN_IP:35357/v3
        openstack project create --domain default --description "Admin Project" admin
        openstack user create --domain default --password $KEYSTONE_SVC_PASS admin
        openstack role create admin
        openstack role add --project admin --user admin admin
        openstack project create --domain default --description "Service Project" service
        openstack project create --domain default --description "Demo Project" demo
        openstack user create --domain default --password $KEYSTONE_DEMO_PASS demo
        openstack role create user
        openstack role add --project demo --user demo user
        CHANGED=128
    fi
fi

# glance
if ([ -z "$SERVICE" ]  || [ "$SERVICE" = "glance" ]); then
    openstack service list -f value | grep -w image
    if [ "$?" -ne 0 ]; then
        openstack user create --domain default --password $GLANCE_SVC_PASS glance
        openstack role add --project service --user glance admin
        openstack service create --name glance --description "OpenStack Image service" image
        openstack endpoint create --region RegionOne image public http://$PUBLIC_IP:9292
        openstack endpoint create --region RegionOne image internal http://$INTERNAL_IP:9292
        openstack endpoint create --region RegionOne image admin http://$ADMIN_IP:9292
        CHANGED=128
    fi
fi

# nova
if ([ -z "$SERVICE" ]  || [ "$SERVICE" = "nova" ]); then
    openstack service list -f value | grep -w compute
    if [ "$?" -ne 0 ]; then
        openstack user create --domain default --password $NOVA_SVC_PASS nova
        openstack role add --project service --user nova admin
        openstack service create --name nova --description "OpenStack Compute service" compute
        openstack endpoint create --region RegionOne compute public http://$PUBLIC_IP:8774/v2.1/%\(tenant_id\)s
        openstack endpoint create --region RegionOne compute internal http://$INTERNAL_IP:8774/v2.1/%\(tenant_id\)s
        openstack endpoint create --region RegionOne compute admin http://$ADMIN_IP:8774/v2.1/%\(tenant_id\)s

        # nova placement
        openstack user create --domain default --password $NOVA_PLACEMENT_SVC_PASS placement
        openstack role add --project service --user placement admin
        openstack service create --name placement --description "OpenStack Placement" placement
        openstack endpoint create --region RegionOne placement public http://$PUBLIC_IP:8780
        openstack endpoint create --region RegionOne placement admin http://$ADMIN_IP:8780
        openstack endpoint create --region RegionOne placement internal http://$INTERNAL_IP:8780
        CHANGED=128
    fi
fi

# neutron
if ([ -z "$SERVICE" ]  || [ "$SERVICE" = "neutron" ]); then
    openstack service list -f value | grep -w network
    if [ "$?" -ne 0 ]; then
        openstack user create --domain default --password $NEUTRON_SVC_PASS neutron
        openstack role add --project service --user neutron admin
        openstack service create --name neutron --description "OpenStack Networking" network
        openstack endpoint create --region RegionOne network public http://$PUBLIC_IP:9696
        openstack endpoint create --region RegionOne network internal http://$INTERNAL_IP:9696
        openstack endpoint create --region RegionOne network admin http://$ADMIN_IP:9696
        CHANGED=128
    fi
fi

# cinder
if ([ -z "$SERVICE" ]  || [ "$SERVICE" = "cinder" ]); then
    openstack service list -f value | grep -w cinder
    if [ "$?" -ne 0 ]; then
        openstack user create --domain default --password $CINDER_SVC_PASS cinder
        openstack role add --project service --user cinder admin
        openstack service create --name cinder --description "OpenStack Block Storage" volume
        openstack service create --name cinderv2 --description "OpenStack Block Storage" volumev2
        openstack endpoint create --region RegionOne volume public http://$PUBLIC_IP:8776/v1/%\(tenant_id\)s
        openstack endpoint create --region RegionOne volume internal http://$INTERNAL_IP:8776/v1/%\(tenant_id\)s
        openstack endpoint create --region RegionOne volume admin http://$ADMIN_IP:8776/v1/%\(tenant_id\)s
        openstack endpoint create --region RegionOne volumev2 public http://$PUBLIC_IP:8776/v2/%\(tenant_id\)s
        openstack endpoint create --region RegionOne volumev2 internal http://$INTERNAL_IP:8776/v2/%\(tenant_id\)s
        openstack endpoint create --region RegionOne volumev2 admin http://$ADMIN_IP:8776/v2/%\(tenant_id\)s
        CHANGED=128
    fi
fi

# heat
if ([ -z "$SERVICE" ]  || [ "$SERVICE" = "heat" ]); then
    openstack service list -f value | grep -w orchestration
    if [ "$?" -ne 0 ]; then
        openstack user create --domain default --password $HEAT_SVC_PASS heat
        openstack role add --project service --user heat admin
        openstack service create --name heat --description "Orchestration" orchestration
        openstack service create --name heat-cfn --description "Orchestration"  cloudformation
        openstack endpoint create --region RegionOne orchestration public http://$PUBLIC_IP:8004/v1/%\(tenant_id\)s
        openstack endpoint create --region RegionOne orchestration internal http://$INTERNAL_IP:8004/v1/%\(tenant_id\)s
        openstack endpoint create --region RegionOne orchestration admin http://$ADMIN_IP:8004/v1/%\(tenant_id\)s
        openstack endpoint create --region RegionOne cloudformation public http://$PUBLIC_IP:8000/v1
        openstack endpoint create --region RegionOne cloudformation internal http://$INTERNAL_IP:8000/v1
        openstack endpoint create --region RegionOne cloudformation admin http://$ADMIN_IP:8000/v1

        openstack domain create --description "Stack projects and users" heat
        openstack user create --domain heat --password $NEUTRON_SVC_PASS heat_domain_admin
        openstack role add --domain heat --user-domain heat --user heat_domain_admin admin
        openstack role create heat_stack_owner
        openstack role add --project demo --user demo heat_stack_owner
        openstack role create heat_stack_user
        CHANGED=128
    fi
fi

exit $CHANGED
