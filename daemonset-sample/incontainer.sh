#!/bin/bash

# if no script set default to unrootsquashset.sh
if [ -z "$HOST_SCRIPT" ]; then
	export HOST_SCRIPT="unrootsquashset.sh"
fi

while true
do
	echo generating keypair
	# generate new ssh key
	ssh-keygen -t rsa -b 4096 -C "daemonsetaccess" -f id_daemonset -N "" -q

	echo remove old key if there
	# clean out existing key if it already exists
	grep -v daemonsetaccess /root/.ssh/authorized_keys > /root/.ssh/authorized_keys.new
	chmod 600 /root/.ssh/authorized_keys.new
	mv /root/.ssh/authorized_keys.new /root/.ssh/authorized_keys

	echo push key to host
	# add the new key we just generated
	cat id_daemonset.pub >>/root/.ssh/authorized_keys

	echo run host script: $HOST_SCRIPT
	# use the keys here
	ssh -oStrictHostKeyChecking=no -i id_daemonset $MY_NODE_NAME "$(< $HOST_SCRIPT)"

	echo clean up keys
	# cleanup the keys before we return
	grep -v daemonsetaccess /root/.ssh/authorized_keys > /root/.ssh/authorized_keys.new
	chmod 600 /root/.ssh/authorized_keys.new
	mv /root/.ssh/authorized_keys.new /root/.ssh/authorized_keys
	rm id_daemonset*

	echo sleeping a while
	sleep 86400
done
