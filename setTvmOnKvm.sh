set -x

'''
Required Varibales for this file

TVAULT_NAME=
GIT_BRANCH=
TVAULT_IP=
TVAULT_VERSION=
IP_COUNT=
MULTI_NIC=
TVAULT_INTERNAL_IP=
IF=
'''

flag=0
#Mount NFS Share or download build from google drive
rm -rf /home/build/$TVAULT_NAME
mkdir -p /home/build/$TVAULT_NAME
if mountpoint -q /mnt/build-vault
then
   echo "NFS already mounted"
else
   echo "NFS not mounted. Mounting.."
   mkdir -p /mnt/build-vault
   mount -t nfs 192.168.1.20:/mnt/build-vault /mnt/build-vault
   if [ $? -ne 0 ]
   then
     echo "Error occured in NFS mount"
     echo "Download build from gdrive"
     BUILD_ID=`drive list | grep tvault-appliance-os-$TVAULT_VERSION.qcow2.txz | cut -d ' ' -f1`
     drive download --path /home/build/$TVAULT_NAME $BUILD_ID
     if [ $? -ne 0 ]
     then
       echo "Build download from google drive failed"
       exit 1
     else
       echo "Build downloaded from google drive"
       flag=1
     fi
   fi
fi

EXTENSION=txz
setvars()
{
        clear
        iFlag="y"
        TVAULT_ISO="/opt/"
        MEM=6144
        CPUs=4
        BRIDGE=`brctl show | awk '{print $1}' | head -2 | tail -1`
        imageTargetLoc="/var/lib/libvirt/images"
        tempFile="/tmp/temp.txt"
        ipCount=$IP_COUNT
        if [[ $TVAULT_IP == *","* ]]; then
           IP=($TVAULT_IP)
           ip_1="$(cut -d',' -f1 <<<"$IP")"
           ip_2="$(cut -d',' -f2 <<<"$IP")"
           ip_3="$(cut -d',' -f3 <<<"$IP")"
           ip[0]=$ip_1
           ip[1]=$ip_2
           ip[2]=$ip_3
           echo ${ip[@]}
        else
           ip=($TVAULT_IP)
           echo ${ip}
        fi
        tvmName=$TVAULT_NAME
        if [[ $TVAULT_INTERNAL_IP == *","* ]]; then
           IP=($TVAULT_INTERNAL_IP)
           ip_1="$(cut -d',' -f1 <<<"$IP")"
           ip_2="$(cut -d',' -f2 <<<"$IP")"
           ip_3="$(cut -d',' -f3 <<<"$IP")"
           ip1[0]=$ip_1
           ip1[1]=$ip_2
           ip1[2]=$ip_3
           echo ${ip1[@]}
        else
           ip1=($TVAULT_INTERNAL_IP)
           echo ${ip1}
        fi
        imagePath="/home/build/"
        rm -rf /tmp/$tvmName/*
	mkdir -p $imageTargetLoc/$tvmName
	mkdir -p /tmp/$tvmName
	USER_DATA="/tmp/$tvmName/user-data"
        META_DATA="/tmp/$tvmName/meta-data"
        BRANCH=`echo $GIT_BRANCH | sed 's/\///'`
        if [ $flag -eq 0 ]
        then
		cp /mnt/build-vault/$BRANCH/tvault-appliance-os-$TVAULT_VERSION.qcow2.$EXTENSION $imagePath$tvmName
	        if [ $? -ne 0 ]
        	then
			echo "Build copy failed, exiting....\n"
			exit 1
	        fi
	else
		echo "Build already copied"
	fi
        validate
}

cleanUp()
{
        for ((iTemp=1;iTemp <= ${ipCount};iTemp++)); do
	        rm -rf ${imageTargetLoc}/${tvmName}/*
                rm -f ${TVAULT_ISO}${tvmName}_${iTemp}.iso ${USER_DATA}_${tvmName}_${iTemp} ${META_DATA}_${tvmName}_${iTemp}
        done
}

validate()
{
        for ((iTemp=1;iTemp <= ${ipCount};iTemp++)); do
                virsh destroy ${tvmName}_${iTemp}
		if [ $? -eq 0 ]; then
                    sleep 10s
		fi
		virsh undefine ${tvmName}_${iTemp}
        done

        imageFile=`ls ${imagePath}${tvmName} | awk -F'/' '{print $NF}' | cut -d"." -f1-4`
}

showvars()
{
        echo "Values Setup...."
        echo "Image Location : ${imagePath}${tvmName}"
        echo "Image File : ${imageFile}"
        echo "TVM machines Count : ${ipCount}"
        for ((iTemp=1;iTemp<=${ipCount};iTemp++)); do
                echo "IP Address ${iTemp} : ${ip[$iTemp-1]}"
                echo "Internal IP Address ${iTemp} : ${ip1[$iTemp-1]}"
        done
}

extractAndCopy()
{

        cp ${imagePath}${tvmName}/${imageFile}.$EXTENSION ${imageTargetLoc}/${tvmName}/${imageFile}.$EXTENSION
        cd ${imageTargetLoc}/${tvmName}/
	if [ "$EXTENSION" == "txz" ]
	then
		tar Jxvf ${imageFile}.$EXTENSION
	else
		tar zxvf ${imageFile}.$EXTENSION
	fi
        for ((iTemp=1;iTemp <= ${ipCount};iTemp++)); do
                cp ${imageFile} ${imageFile}_${iTemp}
        done
}

setUserData()
{
	cat > ${USER_DATA} << _EOF_
#cloud-config
preserve_hostname: False
hostname: ${tvmName}_${iTemp}
runcmd:
  - sed -i '/BOOTPROTO/d' /etc/sysconfig/network-scripts/ifcfg-eth0
  - echo "BOOTPROTO=static" >> /etc/sysconfig/network-scripts/ifcfg-eth0
  - echo "IPADDR=${ip[$iTemp-1]}" >> /etc/sysconfig/network-scripts/ifcfg-eth0
  - echo "PREFIX=16" >> /etc/sysconfig/network-scripts/ifcfg-eth0
  - echo "ONBOOT=yes" >> /etc/sysconfig/network-scripts/ifcfg-eth0
  - echo "GATEWAY=192.168.1.1" >> /etc/sysconfig/network-scripts/ifcfg-eth0
  - echo "TYPE=Ethernet" >> /etc/sysconfig/network-scripts/ifcfg-eth0
  - echo "DNS1=192.168.1.1" >> /etc/sysconfig/network-scripts/ifcfg-eth0
  - ifdown eth0
  - ifup eth0
_EOF_
        if [ "$MULTI_NIC" == "Yes" ]
        then
                if [[ ! -z $ip1 ]]
                then
                        echo "  - echo "BOOTPROTO=static" >> /etc/sysconfig/network-scripts/ifcfg-eth1
  - echo "IPADDR=${ip1[$iTemp-1]}" >> /etc/sysconfig/network-scripts/ifcfg-eth1
  - echo "PREFIX=16" >> /etc/sysconfig/network-scripts/ifcfg-eth1
  - echo "ONBOOT=yes" >> /etc/sysconfig/network-scripts/ifcfg-eth1
  - echo "TYPE=Ethernet" >> /etc/sysconfig/network-scripts/ifcfg-eth1
  - echo "DEVICE=eth1" >> /etc/sysconfig/network-scripts/ifcfg-eth1
  - ifdown eth1
  - ifup eth1" >> ${USER_DATA}
                fi
        fi

}

setMetaData()
{
	cat > ${META_DATA} << _EOF_
instance-id: ${tvmName}_${iTemp}
hostname: ${tvmName}_${iTemp}
_EOF_
}

setISO()
{
        genisoimage -output ${TVAULT_ISO}${tvmName}_${iTemp}.iso -volid cidata -joliet -rock ${USER_DATA} ${META_DATA}
        cp ${USER_DATA} ${USER_DATA}_${iTemp}; cp ${META_DATA} ${META_DATA}_${iTemp}
}

setDataFiles()
{
        for ((iTemp=1;iTemp <= ${ipCount};iTemp++)); do
                setUserData
                setMetaData
                setISO
        done
}

cleanCache()
{
echo "cleaning cache"
echo "for ((iTemp=1; iTemp<=5;iTemp++));do date && sync && echo 3 > /proc/sys/vm/drop_caches && sleep 5;done" > temp.sh
nohup sh temp.sh &
}

createVMs()
{
        cd ${imageTargetLoc}/${tvmName}/
        for ((iTemp=1;iTemp <= ${ipCount};iTemp++)); do
                virt-install --import --name ${tvmName}_${iTemp} --memory $MEM --vcpus $CPUs --disk ${imageFile}_${iTemp},format=qcow2,bus=virtio --disk ${TVAULT_ISO}${tvmName}_${iTemp}.iso,device=cdrom --network  bridge=virbr0,model=virtio --os-type=linux --noautoconsole
	        if [ $? -ne 0 ]
        	then
                	echo "TVM virt-install failed, exiting....\n"
			exit 1
	        fi
                virsh change-media ${tvmName}_${iTemp} hda --eject --config
                if [ "$MULTI_NIC" == "Yes" ]
                then
			if [[ ! -z $ip1 ]]; then
	                        virsh attach-interface --domain ${tvmName}_${iTemp} --type bridge --source $IF --model virtio --config --live
			fi
                fi
        done
	sleep 6m
	cleanCache
}

setvars
showvars
cleanUp
setDataFiles
extractAndCopy
createVMs

for ((iTemp=1;iTemp <= ${ipCount};iTemp++)); do
        virsh reboot ${tvmName}_${iTemp}
done
sleep 7m

echo "Finally..."
set +x