#!/bin/bash

export TVAULT_BRANCH="v4.1maintenance"
export GIT_REPO="https://github.com/trilioData/triliovault-cfg-scripts.git"
export CONTROLLER_IP="172.26.0.50"
export COMPUTE_IP="172.26.0.49"
export TVAULT_IP="192.168.11.171"
export TVAULT_VERSION="4.1.99"
export NFS_PATH="192.168.1.34:/mnt/tvault/tvm1"
export BASEDIR=$(pwd)
export NFS_OPT="nolock,soft,timeo=180,intr,lookupcache=none,nfsvers=3"


git_download()
{

        git clone -b $TVAULT_BRANCH $GIT_REPO
}

copy_roles()
{
        #Run below commands to copy files on required place
        cp -R triliovault-cfg-scripts/ansible/roles/* /opt/openstack-ansible/playbooks/roles/
        cp triliovault-cfg-scripts/ansible/main-install.yml   /opt/openstack-ansible/playbooks/os-tvault-install.yml
        cp triliovault-cfg-scripts/ansible/environments/group_vars/all/vars.yml /etc/openstack_deploy/user_tvault_vars.yml

        #Add the below content at end of file

cat << EOF >> /opt/openstack-ansible/playbooks/setup-openstack.yml
- import_playbook: os-tvault-install.yml
EOF

cat << EOF >> /etc/openstack_deploy/user_variables.yml
# Datamover haproxy setting
haproxy_extra_services:
  - service:
      haproxy_service_name: datamover_service
      haproxy_backend_nodes: "{{ groups['dmapi_all'] | default([]) }}"
      haproxy_ssl: "{{ haproxy_ssl }}"
      haproxy_port: 8784
      haproxy_balance_type: http
      haproxy_backend_options:
        - "httpchk GET / HTTP/1.0\\\r\\\nUser-agent:\\\ osa-haproxy-healthcheck"

EOF

cat << EOF  > /opt/openstack-ansible/inventory/env.d/tvault-dmapi.yml

component_skel:
  dmapi_api:
    belongs_to:
      - dmapi_all

container_skel:
  dmapi_container:
    belongs_to:
      - tvault-dmapi_containers
    contains:
      - dmapi_api

physical_skel:
  tvault-dmapi_containers:
    belongs_to:
      - all_containers
  tvault-dmapi_hosts:
    belongs_to:
      - hosts
EOF


cat << EOF >> /etc/openstack_deploy/openstack_user_config.yml
#tvault-dmapi
tvault-dmapi_hosts:
  controller:
    ip: $CONTROLLER_IP

#tvault-datamover
tvault_compute_hosts:
  compute:
    ip: $COMPUTE_IP
EOF


sed -i "/IP_ADDRESS: /c IP_ADDRESS: $TVAULT_IP" /etc/openstack_deploy/user_tvault_vars.yml
sed -i "/TVAULT_PACKAGE_VERSION: /c TVAULT_PACKAGE_VERSION: $TVAULT_VERSION" /etc/openstack_deploy/user_tvault_vars.yml
sed -i "/NFS: /c NFS: True" /etc/openstack_deploy/user_tvault_vars.yml
sed -i '/NFS_SHARES:/,+2d' /etc/openstack_deploy/user_tvault_vars.yml
echo -e "NFS_SHARES:
          - $NFS_PATH" >> /etc/openstack_deploy/user_tvault_vars.yml
	  
sed -i "/ceph_backend_enabled: /c ceph_backend_enabled: yes" /etc/openstack_deploy/user_tvault_vars.yml
sed -i "/NFS_OPTS: /c NFS_OPTS: $NFS_OPT" /etc/openstack_deploy/user_tvault_vars.yml
}

clean_up()
{

if [ -f /etc/openstack_deploy/user_tvault_vars.yml ] ; then

 rm -rf  $BASEDIR/triliovault-cfg-scripts
 rm -rf  /opt/openstack-ansible/playbooks/roles/ansible-*
 rm -f /opt/openstack-ansible/playbooks/os-tvault-install.yml
 rm  -f /etc/openstack_deploy/user_tvault_vars.yml
 rm -f /opt/openstack-ansible/inventory/env.d/tvault-dmapi.yml
 sed -i '/os-tvault-install.yml/d' /opt/openstack-ansible/playbooks/setup-openstack.yml
 sed -i '/Datamover/,+10d' /etc/openstack_deploy/user_variables.yml
 sed -i '/tvault/,+9d' /etc/openstack_deploy/openstack_user_config.yml
 echo "Old Roles Clean up completed !!!!!"

else

  echo "It's fresh Installation. Nothing to cleanup !!!!!"

fi

}

clean_up
git_download
copy_roles

cd /opt/openstack-ansible/playbooks && openstack-ansible lxc-containers-create.yml os-tvault-install.yml haproxy-install.yml -vv
