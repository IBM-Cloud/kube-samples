# secret-sync-operator
A K8s Operator that helps keep secrets in sync across multiple namespaces

## What is this?
This sample is an example [Kubenetes Operator](https://coreos.com/operators/) that will syncronize [Kubernetes Secrets](https://kubernetes.io/docs/concepts/configuration/secret/) that you annotate with target Secrets that you designate.

## How does it work
The operator will watch the Kubernetes Events API for changes in `corev1.Secret` object types. When a change is detected, the operator examines the Secret for an annotation of `secretsync.ibm.com/replicate=true`. If it finds the annotation on the Secret, the operator then checks for the existance of the `secretsync.ibm.com/replicate-to` annotation and reads the values of that annotation in as a comma-delimited list. This list is the `namespace` and `name` of the secret(s) to be created (or updated) and kept in sync. For example, if the annotation value was `default/mysecret1,default/mysecret2`, the operator would create (or update) a Secret called `mysecret` in and a Secret called `mysecret2` in the `default` namespace. 

If the value of the `secretsync.ibm.com/replicate` annotation was changed to `false`, the operator would no longer attempt to create or update the Secrets defined in the `secretsync.ibm.com/replicate-to` annotation. 

When the operator creates or updates a target Secret object, it will attach some metadata to the secret:

* An annotation of `secretsync.ibm.com/replicated-resource-version` which contains the `resourceVersion` value taken from the source Secret. This is useful to understand what content you'll find in the `data` field of the secret

* An annotation of `secretsync.ibm.com/replicated-time` which contains the timestamp of the last create or update operation

* A label of `secretsync.ibm.com/replicated-from` which identifies the source Secret in the format `namespace.secret-name`. This label makes it easy to see all the Secrets in a cluster that are replicated from a certain source Secret. For example, the command `kubectl get secret -l secretsync.ibm.com/replicated-from=default.mysecret --all-namespaces` will show all the Secrets in the cluster that were synced from the `mysecret` Secret in the `default` namespace of the cluster.

## Building and running
You have a few options are your disposal to get this operator running: 
* `docker build -t <desired container image name> .` : If you can do local container builds (I.e. using Docker or a similar other OCI-compliant build method) you can simply use the Dockerfile provided to produce a container image that you can reference from the Kubernetes deployment YAMLs located in the `deploy` directory for this project. 
* `operator-sdk build <container image name>` : If you have a working Go development environment on your machine, you can follow [these instructions](https://github.com/operator-framework/operator-sdk/blob/master/doc/user/install-operator-sdk.md) to get the Operator SDK CLI installed on your machine and use it to build the operator image. 

After building the image you can push it to your choice of container registry (we're partial to the [IBM Cloud Container Registry](https://cloud.ibm.com/kubernetes/catalog/registry) ourselves) and then reference it from the provided YAML deployment files in the `deploy` folder of this project.

To deploy the operator just run `kubectl apply -f deploy/all-in-one.yaml`. This will:
1. Create a service account for the operator that uses the provided IBM Cloud Container Registry pull secrets. 
2. Create a ClusterRole that defines access to full access to Secrets and ConfigMap resource types in the cluster and read access to Namespaces, Pods, and ReplicaSets. This is the minimum required access for the operator to do it's function
3. Create a ClusterRoleBinding that binds the created ClusterRole to the operator's service account
4. Creates a Deployment that defines the operator's pods.

To delete the operator from your cluster, simply run `kubectl delete -f deploy/all-in-one.yaml`. 

