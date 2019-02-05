## Hands on!

Together we'll create a Kubernetes network policy that prevents an "uncordoned" pod from accessing our "cordoned" pod. Kubernetes network policies can be used to segment Kubernetes resources within a cluster.

**Reminder**: Set your cluster context.
 - `ibmcloud ks cluster-config <cluster-name> --export`

1. Deploy the `liberty` and `uncordoned` pods.

   `kubectl apply -f https://raw.githubusercontent.com/IBM-Cloud/kube-samples/master/iks-workshop/security/demo-pods.yaml`

2. View the `liberty` pod IP address.

   `kubectl get po -o wide`

3. Exec into the `uncordoned` pod and curl `liberty` to confirm that the pods can communicate. Replace `<liberty-pod-ip>` with the IP address from the previous step.

   `kubectl exec -it uncordoned -- curl -m 5 <liberty-pod-ip>:9080`
   
   The output that you receive is the generic message from the `ibmliberty` image.

4. Deploy a Kubernetes network policy.

   `kubectl apply -f https://raw.githubusercontent.com/IBM-Cloud/kube-samples/master/iks-workshop/security/deny-ingress-uncordoned.yaml`
   
   Reference
   ```
   # This policy allows pods with the cordoned label to have ingress only from other pods with the label cordoned.
   
   apiVersion: networking.k8s.io/v1
   kind: NetworkPolicy
   metadata:
     name: deny-ingress-uncordoned
   spec:
     podSelector:
       matchLabels:
         app: cordoned
     policyTypes:
     - Ingress
     ingress:
     - from:
       - podSelector: 
           matchLabels:
             app: cordoned
   ```

5. Exec into the `uncordoned` pod and curl `liberty` to confirm that liberty is blocked.

   `kubectl exec -it uncordoned -- curl -m 5 <liberty-pod-ip>:9080`


## Example Calico policy