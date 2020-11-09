#!/bin/sh

echo "Test script to add data at boot" >> /tmp/test.txt

sleep 5m
ls /dev/vdb && echo -e "n \n p \n \n \n \n wq" | fdisk /dev/vdb && \
mkfs.ext4 /dev/vdb1 && \
echo "/dev/vdb1 /data1 ext4 defaults 0 0" >> /etc/fstab  &&\
mkdir /data1 && \
mount -a && \
dd if=/dev/urandom of=/data1/data1.txt bs=5M count=20


