# Watson-Coversation-Python-Slackbot

### Prereqs
- Docker needs to be installed on your local machine
- The Bluemix CLI needs to be installed
- Kubectl needs to be installed and pointed to your cluster

```
bx login
bx plugin install container-service -r Bluemix
bx cs init
bx cs clusters
bx cs cluster-config {cluster-name}
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
