#!/bin/bash

export IMG_NAME="cirros"
export OP_IMAGE_ID=`openstack image list --insecure --name cirros -c ID -f value`
export NTW_NAME="test_internal_network"
export NTW_ID=`openstack network list --insecure  --name $NTW_NAME -c ID -f value`
export FLV_ID="d61dd031-bf08-4ea4-9b1f-cdd3e53e524e"

export OS_PROJECT_DOMAIN_ID=24d96d64958f46718d86d5c8dda08f0a
export OS_REGION_NAME=US-WEST-2
export OS_PROJECT_NAME=tproject
export OS_USER_DOMAIN_NAME=tdomain
export OS_IDENTITY_API_VERSION=3
export OS_INTERFACE=public
export OS_PASSWORD=password
export OS_AUTH_URL=https://osaubuntuussuri.triliodata.demo:5000
export OS_USERNAME=tuser
export OS_PROJECT_ID=4c25753c1f5f4f44964b662040f74165



cat > partition_creat.sh <<- EOF
#!/bin/bash
sleep 5m
ls /dev/vdb && echo -e "n \n p \n \n \n \n wq" | fdisk /dev/vdb && \\
mkfs.ext4 /dev/vdb1 && \\
echo "/dev/vdb1 /data1 ext4 defaults 0 0" >> /etc/fstab  && \\
mkdir /data1 && \\
mount -a && \\
dd if=/dev/urandom of=/data1/data1.txt bs=5M count=20
EOF



while read -r VOL_TYPE VOL_NAME
do

echo "Creating $VOL_NAME volume"
    VOL_IMG=`openstack volume create --insecure  --size 1 \
    --image $OP_IMAGE_ID \
    --type $VOL_TYPE \
    --description "Created vol $VOL_NAME with command" -c id -f value Vol_"$VOL_NAME"_boot`

echo "created $VOL_NAME booted vol"

     VOL_DSK=`openstack volume create --insecure  --size 5 \
        --type $VOL_TYPE \
        --description "Created vol $VOL_NAME with command" -c id -f value Vol_"$VOL_NAME"`

sleep 50s

echo "creating server...."

  openstack server create --insecure \
  --volume $VOL_IMG \
  --flavor $FLV_ID  --user-data  partition_creat.sh \
  --network $NTW_ID INS_"$VOL_NAME"

  echo "server $VOL_NAME created"

sleep 45s
openstack server add volume --insecure  INS_"$VOL_NAME" $VOL_DSK && echo "volume attached"

done < <(openstack  volume type list --insecure  -c ID -c Name -f value)


  while read -r INS_ID INS_NAME ; do
  echo "Creating $INS_NAME WORKLOAD";
  workloadmgr workload-create --insecure  \
  --instance instance-id=$INS_ID  \
  --display-name  "$INS_NAME"_Wkld  \
  --display-description "Creating the workload for testing purpose"  \
  --workload-type-id f82ce76f-17fe-438b-aa37-7a023058e50d  \
  --source-platform 'openstack'  \
  --jobschedule 'enabled'=True \
  --jobschedule 'interval'='1 hr'  --jobschedule 'snapshots_to_retain'='5' \
#  --jobschedule 'start_date'=`date +%m/%d/%Y` --jobschedule 'start_time'="`date +"%I:%M %p"`" \
#  --jobschedule 'end_date'=`date --date='10 day' +%m/%d/%Y` \

 done < <(openstack server list --insecure  --long  -c ID -c Properties -c Name -f value | grep -v workload_id)

