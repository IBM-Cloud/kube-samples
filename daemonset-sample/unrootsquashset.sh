#!/bin/bash
grep "^Domain = slnfsv4.com" /etc/idmapd.conf
if [ "$?" -ne "0" ] ; then
        sed -i 's/.*Domain =.*/Domain = slnfsv4.com/g' /etc/idmapd.conf
        apt-get update
        apt-get install -y nfs-common nfs-kernel-server
        nfsidmap -c
        service nfs-idmapd start
fi

