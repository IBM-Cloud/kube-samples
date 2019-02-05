# kube-sample-daemonset

This sample shows how to create a DaemonSet to automatically apply a change to worker nodes. In particular, this DaemonSet updates each worker node in your cluster to enable "no_root_squash" as per https://knowledgelayer.softlayer.com/procedure/accessing-file-storage-linux.

The deployment is configured to allow the pods for this to run in privileged mode, which is necessary to update the host file system. As always, be very careful allowing privileged access.

Since this is a DaemonSet, new worker nodes added while the DaemonSet is running will automatically have the changes applied.

Steps:

1. Create the DaemonSet to enable "no_root_squash". 

```
kubectl apply -f norootsquash.yaml
```

2. List the worker nodes in your cluster to view the worker IDs.

```
ibmcloud ks workers <cluster-name>
```

3. Reboot all worker nodes to apply the changes.

```
ibmcloud ks worker-reboot <cluster-name> <worker-id1> <worker-id2>
```

To delete the DaemonSet, run:

```
kubectl delete -f norootsquash.yaml
```

Deleting the DaemonSet will not back out changes made to the underlying nodes.
Worker nodes that are added after this DaemonSet is removed will not have the changes applied.
 