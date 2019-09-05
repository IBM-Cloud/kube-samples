# Install Jenkins-X on IBM Cloud Kubernetes Service

Install serverless Jenkins-X with Tekton and Kaniko on an existing IBM Cloud Kubernetes Service cluster. These steps use GitHub as the source repository.

Initial draft of steps:

1) Create an IBM Cloud Kubernetes cluster.
2) Install the Jenkins-X cli.
3) After cluster has provisioned, install Jenkins-X on the cluster.

`jx install cluster --provider=kubernetes --external-ip <ingress-ip> --domain <cluster-domain> --docker-registry us.icr.io --tekton --git-username <github-username> --git-api-token <github-api-token> --environment-git-owner <github-owner> --skip-ingress`

If prompted, select `Serverless Jenkins X Pipelines with Tekton`

`Installing jenkins-x-platform version:` - will take some time to provision

4) Create a namespace in registry that matches GitHub Org name
5) While Jenkins-X is installing, create an api key.

`ibmcloud iam api-key-create MyKey -d "this is my API key" --file key_file`

For production environments, create a Service ID API Key with container registry write permissions

6) Use `jx create auth` command to update secret

`jx create docker auth --host "us.icr.io" --user "iamapikey" --secret "$IAMAPIK" --email "a@b.c"`

7) Post-creation, copy/rename default secret to any environment namespaces

`kubectl get secret default-us-icr-io -o yaml -n default | sed 's/default/jx-staging/g' | kubectl -n jx-staging create -f -`
`kubectl get secret default-us-icr-io -o yaml -n default | sed 's/default/jx-production/g' | kubectl -n jx-production create -f -`

8) Patch ServiceAccounts to use tokens in new namespaces

`kubectl patch serviceaccount default -p '{"imagePullSecrets": [{"name": "jx-us-icr-io"}]}' -n jx-staging`
`kubectl patch serviceaccount default -p '{"imagePullSecrets": [{"name": "jx-us-icr-io"}]}' -n jx-production`

9) Jenkins-X is now installed. You can run your serverless builds in your cluster.

