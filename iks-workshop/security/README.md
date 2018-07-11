# Security + Access Control List (ACL) best practices

## Resources
[IKS security documentation](https://console.bluemix.net/docs/containers/cs_secure.html#security)

## What IKS Provides

![Security considerations](images/security-sm.png)

What IBM Cloud Kubernetes Service provides

- Dedicated and Managed Kubernetes master
  - Encrypted etcd datastore
  - Openvpn connection between master and workers
- Account access control through integrated IAM and RBAC
- Secure communication via TLS
  - When you are authenticated, IBM Cloud Kubernetes Service generates TLS certificates that encrypt the communication to and from the Kubernetes API server and etcd data store to ensure a secure end-to-end communication between the worker nodes and the Kubernetes master. 
- Worker node imaging and updates
  - Regular patches. Vetting of Kubernetes versions.
  - CIS (Center of Internet Security) Compliant image
  - Trusted Compute option
    - Select bare metal flavors
    - Hardware monitoring – verify against tampering
  - Encrypted disk
  - Set up w/AppArmor to enforce security policies: https://wiki.ubuntu.com/AppArmor
  - SSH disabled
- Default network policies
  - When you deploy, cluster is protected by Calico and Kubernetes policies.
  - Not accessible until resources are deployed to open to internet.
  - Egress open by default

## Building a Secure Environment

### Network Perimeter

![Network perimeter](images/network.png)

- Hardware Firewall (vyatta, fortigate)
- Calico network policies

Network Isolation

- Control what talks to talk
- VLANs
- Edge nodes
- Kubernetes Network Policies
- Calico Network Policies
- Namespaces

Ingress options for Network Confidentiality
1. Enforce TLS at Ingress. CA is Digicert (LetsEncrypt in future)
2. Enforce TLS from Ingress to containers using Ingress ‘ssl-service’ annotation 
3. Enforce TLS from component to component: 
	- Self-signed CA ok within deployment or cluster across private network
	- Use Digicert/Letsencrypt for microservice to microservice over public


Manage User Access
- RBAC
  - `kubectl get rolebinding`
  - `kubectl get clusterrolebinding`
  - `kubectl describe clusterrole admin` (ibm-operate)
- IAM
  - Adds users to IBM standardized RBAC roles/clusterroles
  - IAM Groups
- Resource Groups
  - Default only – more coming soon

Account Structure / Environments

Options
- Cluster w/namespaces
- Multiple clusters
- Multiple PaaS accounts

Secrets (more to come)

## Hands on!

Together we'll create a Kubernetes network policy that prevents an "uncordoned" pod from accessing our "cordoned" pod. Kubernetes network policies can be used to segment Kubernetes resources within a cluster.

**Reminder**: Set your cluster context.
 - `ibmcloud cs cluster-config <cluster-name> --export`

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

