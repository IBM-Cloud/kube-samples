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


