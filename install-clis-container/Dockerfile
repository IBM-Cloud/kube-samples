FROM ubuntu:latest

ENV SUPPORTED_CALICO 1.6.1

# Install IBM Cloud CLI, IBM Cloud Container Service plugin, IBM Cloud Container Registry plugin, Kubernetes CLI, and Calico CLI
RUN apt-get update &&\
    # Install Curl
    apt-get install -y curl \
    # Install VIM
    vim &&\
    # Install the Linux version of the IBM Cloud CLI
    curl -fsSL https://clis.ng.bluemix.net/install/linux | sh &&\ 
    # Install the IBM Cloud Container Service CLI
    bx plugin install container-service -r Bluemix &&\  
    # Install the IBM Cloud Container Registry CLI              
    bx plugin install container-registry -r Bluemix &&\  
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
