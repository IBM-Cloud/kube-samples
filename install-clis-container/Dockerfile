FROM alpine:latest

ENV SUPPORTED_CALICO 3.3.1

# Install IBM Cloud CLI, IBM Cloud Kubernetes Service plugin, IBM Cloud Container Registry plugin, Kubernetes CLI, and Calico CLI
RUN apk add --no-cache \
    # Install Curl
    curl \
    # Install VIM
    vim &&\
    # Install the Linux version of the IBM Cloud CLI
    curl -fsSL https://clis.ng.bluemix.net/install/linux | sh &&\ 
    # Install the IBM Cloud Kubernetes Service CLI
    ibmcloud plugin install container-service &&\
    # Install the IBM Cloud Container Registry CLI
    ibmcloud plugin install container-registry &&\
    # Download the latest version of Kubernetes
    curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl &&\
    # Update the permissions for and the location of the Kubernetes CLI executable file
    chmod +x ./kubectl &&\
    mv ./kubectl /usr/local/bin/kubectl &&\
    # Download the latest supported version of the Calico CLI
    curl -O -L https://github.com/projectcalico/calicoctl/releases/download/v${SUPPORTED_CALICO}/calicoctl &&\
    # Update the permissions for and the location of the Calico CLI executable file
    mv ./calicoctl /usr/local/bin/calicoctl &&\
    chmod +x /usr/local/bin/calicoctl
