# Install Jenkins-X on IBM Cloud Kubernetes Service

Install serverless Jenkins-X with Tekton and Kaniko on an existing IBM Cloud Kubernetes Service cluster. These steps use GitHub as the source repository. These steps also default to using the US-South `us-icr-io` region for the IBM Cloud Container Registry. If you use a different registry, substitute the region name as appropriate.


1) Create an [IBM Cloud Kubernetes cluster](https://cloud.ibm.com/kubernetes/).
2) Install the [Jenkins-X CLI](https://jenkins-x.io/getting-started/install/).
3) After cluster has provisioned, set the cluster context.

```
$(ibmcloud ks cluster-config --cluster <cluster-name> --export)
```

4) Install Jenkins-X on the cluster.

```
jx install cluster --provider=kubernetes --external-ip <cluster-ingress-ip> --domain <cluster-ingress-subdomain> --docker-registry us.icr.io --tekton --git-username <github-username> --git-api-token <github-api-token> --environment-git-owner <github-owner> --skip-ingress
```

If prompted, select `Serverless Jenkins X Pipelines with Tekton`.

Follow the prompts for setting up the GitHub repo. You will then see the message: `Installing jenkins-x-platform version`. The installation process can take some time.

5) Create a namespace in the IBM Cloud Container Registry Service that matches your GitHub organization name. If the names do not match, then Jenkins-X cannot use the Container Registry.

```
ibmcloud cr namespace-add <your-github-org>
```

6) While Jenkins-X is installing, create an API key to authorize Jenkins-X to push to the Container Registry. For production environments, create a [Service ID API Key](https://cloud.ibm.com/docs/iam?topic=iam-serviceidapikeys#create_service_key) with Container Registry write permissions.

```
ibmcloud iam api-key-create <key-name> -d "Jenkins X API Key" --file <filename>
```

7) After Jenkins-X has installed, use `jx create docker auth` command to update the registry authorization.

```
jx create docker auth --host "us.icr.io" --user "iamapikey" --secret "<IAMAPIKEY>" --email "a@b.c"
```

8) Copy and rename the default secret to any environment namespaces that you are using. These steps update the secret for the `jx-staging` and `jx-production` namespaces.

```
kubectl get secret default-us-icr-io -o yaml -n default | sed 's/default/jx-staging/g' | kubectl -n jx-staging create -f -
```
```
kubectl get secret default-us-icr-io -o yaml -n default | sed 's/default/jx-production/g' | kubectl -n jx-production create -f -
```

9) Patch the ServiceAccounts to use the pull secret in the new namespaces.

```
kubectl patch serviceaccount default -p '{"imagePullSecrets": [{"name": "jx-staging-us-icr-io"}]}' -n jx-staging
```
```
kubectl patch serviceaccount default -p '{"imagePullSecrets": [{"name": "jx-production-us-icr-io"}]}' -n jx-production
```

10) Jenkins-X is now installed. You can run your serverless builds in your cluster. To test the installation, run `jx create quickstart`.

