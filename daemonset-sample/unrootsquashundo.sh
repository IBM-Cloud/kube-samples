#!/bin/bash
grep "^Domain = slnfsv4.com" /etc/idmapd.conf
if [ "$?" -eq "0" ] ; then
        sed -i 's/.*Domain =.*/#Domain = slnfsv4.com/g' /etc/idmapd.conf
        nfsidmap -c
        service nfs-idmapd stop
fi

