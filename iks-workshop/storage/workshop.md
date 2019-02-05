## Hands on!

Let's deploy a dynamically provisioned persistent volume claim to give our app access to persistent storage.

**Reminder**: Set your cluster context.
 - `ibmcloud ks cluster-config <cluster-name> --export`

### Steps

1. Create a persistent volume claim.

   `kubectl apply -f https://raw.githubusercontent.com/IBM-Cloud/kube-samples/master/iks-workshop/storage/pvc.yaml`

 Reference:
 ```
 apiVersion: v1
 kind: PersistentVolumeClaim
 metadata:
   name: mypvc
   annotations:
     volume.beta.kubernetes.io/storage-class:  "ibmc-file-bronze"
   labels:
     billingType: "hourly"
 spec:
   accessModes:
     - ReadWriteMany
   resources:
     requests:
       storage: 20Gi
 ```
 
2. View storage classes.

   `kubectl get storageclasses`

3. Determine that the pvc is provisioned.

   `kubectl get pvc`

4. Create deployment that writes a file and mounts the pvc.

   `kubectl apply -f https://raw.githubusercontent.com/IBM-Cloud/kube-samples/master/iks-workshop/storage/storage-deployment.yaml`
  
5. Create a second deployment that mounts the pvc and gets access to the file.

   `kubectl apply -f https://raw.githubusercontent.com/IBM-Cloud/kube-samples/master/iks-workshop/storage/second-deployment.yaml`

6. Get the pod name for `second-deployment`.

   `kubectl get po`

7. Exec into the pod.

   `kubectl exec -it <podname> bash`

8. View the file to confirm it was written and available on the pvc.

   `cd volume && ls`
 
   **Tip**: Run `df -h` to see disk usage and the id of the backing file share.
 
9. Delete the deployments.

  - `kubectl delete -f https://raw.githubusercontent.com/IBM-Cloud/kube-samples/master/iks-workshop/storage/storage-deployment.yaml`
  - `kubectl delete -f https://raw.githubusercontent.com/IBM-Cloud/kube-samples/master/iks-workshop/storage/second-deployment.yaml`

10. Delete the pvc.

   `kubectl delete pvc mypvc`
