#!/bin/bash
export OP_IMAGE_ID="b9ad3029-67f5-48b0-86bc-2f27e3a4d431"
export openstack='openstack --insecure'
openstack_domain_setup()
{

openstack domain create $OP_DOMAIN_NAME
openstack project create --domain $OP_DOMAIN_NAME $OP_PROJECT_NAME
openstack project create --domain $OP_DOMAIN_NAME $OP_ALTPROJECT_NAME
openstack user create --domain $OP_DOMAIN_NAME --password $OP_PASSWORD $OP_ADUSER_NAME
openstack user create --domain $OP_DOMAIN_NAME --password $OP_PASSWORD $OP_NUSER_NAME
openstack role add --user $OP_ADUSER_NAME --project $OP_PROJECT_NAME  $OP_TRILIO_ROLE
openstack role add --user $OP_NUSER_NAME --project $OP_PROJECT_NAME  $OP_TRILIO_ROLE
openstack role add --user $OP_NUSER_NAME --project $OP_ALTPROJECT_NAME  $OP_TRILIO_ROLE
openstack role add --user $OP_ADUSER_NAME --project $OP_ALTPROJECT_NAME  $OP_TRILIO_ROLE
openstack role add --user $OP_ADUSER_NAME --project $OP_PROJECT_NAME  $OP_ADMN_ROLE
openstack role add --user $OP_ADUSER_NAME --project $OP_ALTPROJECT_NAME  $OP_ADMN_ROLE

}


openstack_vol_image_create()
{

if [ "$1" = "image" ]; then
    echo "Creating vol booted volumes"
    while read -r VOL_TYPE VOL_NAME ; do

        echo "Creating $VOL_NAME vol booted volume"

        openstack volume create --size 1 \
        --image $OP_IMAGE_ID \
        --type $VOL_TYPE \
        --description "Created vol $VOL_NAME with command" Vol_"$VOL_NAME"_boot && \
        echo " created $VOL_NAME vol booted volume" || \
        echo " unable to create $VOL_NAME vol booted volume"

    done < <(openstack  volume type list -c ID -c Name -f value)

else
     echo "Creating vol volumes"
     while read -r VOL_TYPE VOL_NAME ; do

        echo "Creating $VOL_NAME vol booted volume"

        openstack volume create --size 5 \
        --type $VOL_TYPE \
        --description "Created vol $VOL_NAME with command" Vol_"$VOL_NAME" && \
        echo " created $VOL_NAME volume" || \
        echo " unable to create $VOL_NAME volume"

    done < <(openstack  volume type list -c ID -c Name -f value)

fi

}

openstack_vol_image_create image
#OS_AUTH_URL=https://osaubuntuussuri.triliodata.demo:5000
#OS_PROJECT_DOMAIN_ID=24d96d64958f46718d86d5c8dda08f0a
#OS_REGION_NAME=US-WEST-2
#OS_PROJECT_NAME=atproject
#OS_USER_DOMAIN_NAME=tdomain
#OS_IDENTITY_API_VERSION=3
#OS_INTERFACE=public
#OS_PASSWORD=password
#OS_USERNAME=tuser
#OS_PROJECT_ID=4ab19dbf477a4295b52959fa25fe1390
