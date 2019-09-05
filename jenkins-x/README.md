# Install Jenkins-X on IBM Cloud Kubernetes Service

Install serverless Jenkins-X with Tekton and Kaniko on an existing IBM Cloud Kubernetes Service cluster. These steps use GitHub as the source repository. These steps also default to using the US-South `us-icr-io` region for the IBM Cloud Container Registry. If you use a different registry, substitute the region name as appropriate.


1) Create an IBM Cloud Kubernetes cluster.
2) Install the Jenkins-X cli.
3) After cluster has provisioned, install Jenkins-X on the cluster.

- `jx install cluster --provider=kubernetes --external-ip <ingress-ip> --domain <cluster-domain> --docker-registry us.icr.io --tekton --git-username <github-username> --git-api-token <github-api-token> --environment-git-owner <github-owner> --skip-ingress`

If prompted, select `Serverless Jenkins X Pipelines with Tekton`.

You will then see the message: `Installing jenkins-x-platform version`. The installation process can take some time.

4) Create a namespace in the IBM Cloud Container Registry Service that matches your GitHub organization name. If the names do not match, then Jenkins-X cannot use the Container Registry.

5) While Jenkins-X is installing, create an API key to authorize Jenkins-X to push to the Container Registry. For production environments, create a Service ID API Key with Container Registry write permissions.

- `ibmcloud iam api-key-create MyKey -d "this is my API key" --file key_file`

6) After Jenkins-X has installed, use `jx create docker auth` command to update the registry authorization.

- `jx create docker auth --host "us.icr.io" --user "iamapikey" --secret "<IAMAPIKEY>" --email "a@b.c"`

7) Copy and rename the default secret to any environment namespaces that you are using. These steps update the secret for the staging and production namespaces.

- `kubectl get secret default-us-icr-io -o yaml -n default | sed 's/default/jx-staging/g' | kubectl -n jx-staging create -f -`
- `kubectl get secret default-us-icr-io -o yaml -n default | sed 's/default/jx-production/g' | kubectl -n jx-production create -f -`

8) Patch the ServiceAccounts to use the pull secret in the new namespaces.

- `kubectl patch serviceaccount default -p '{"imagePullSecrets": [{"name": "jx-us-icr-io"}]}' -n jx-staging`
- `kubectl patch serviceaccount default -p '{"imagePullSecrets": [{"name": "jx-us-icr-io"}]}' -n jx-production`

9) Jenkins-X is now installed. You can run your serverless builds in your cluster.

