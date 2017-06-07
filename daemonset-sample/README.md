# kube-sample-daemonset
Sample to show how to create a daemonset to automatically apply a change to worker nodes

In particular, this example updates the worker nodes to enable "no_root_squash" as per https://knowledgelayer.softlayer.com/procedure/accessing-file-storage-linux

To do so, it generates ssh keys and pushes them to the host, then connects over to run the necessary commands as root. After the connection is complete, it cleans up the keys.
The deployment is configured to allow the pods for this to run in privileged mode, which is necessary to access the host file system to push the keys. As always, be very careful allowing privileged access.

Since this is a daemon set, new worker nodes added while it is running will automatically have the change made.

First build and push the image to your registry, e.g.

```
docker build --tag ursdaemonset .
docker tag ursdaemonset registry.ng.bluemix.net/yournamespacehere/ursdaemonset
bx cr login
docker push registry.ng.bluemix.net/yournamespacehere/ursdaemonset
```

Then edit the yaml to point to your registry - specifically the line 

```
registry.ng.bluemix.net/yournamespacehere/ursdaemonset
```

Deploy the daemon set to enable the feature using

```
kubectl create -f urs-daemonset.yml
```

Remove (if needed) using

```
kubectl delete -f urs-daemonset.yml
```

Removing the daemonset will NOT back out changes made to the underlying nodes.
Future nodes added after this is removed will not have the changes applied.


To remove the changes, adjust `urs-daemonset.yml` so that the "HOST_SCRIPT" env var points to `unrootsquashundo.sh` instead of `unrootsquashset.sh`, then update the deploy with those containers.

