# Watson-Coversation-Python-Slackbot

### Prereqs
- Docker needs to be installed on your local machine
- The IBM Cloud CLI needs to be installed
- Kubectl needs to be installed and pointed to your cluster

```
ibmcloud login
ibmcloud plugin install container-service -r 'IBM Cloud'
ibmcloud ks init
ibmcloud ks clusters
ibmcloud ks cluster-config {cluster-name}
```

### Enter Credentials
- Get a slack bot API token for the Slack Team
- Get the credentials for Watson Conversation

### Build the container
From the command line,

```
docker build -t {your_docker_username}/slackbot .
docker push {your_docker_username}/slackbot
```

### Deploy the Container in a Kubernetes Pod
First, edit `bot.yaml` to have the correct container image tag. Then do  
`kubectl create -f bot.yaml`
