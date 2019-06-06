FROM golang
ENV RELEASE_VERSION v0.8.0
ENV GOPATH /go
ADD . /go/src/github.com/ibm/secret-sync-operator
RUN apt update \
    && apt install -y curl
RUN curl -OJL https://github.com/operator-framework/operator-sdk/releases/download/${RELEASE_VERSION}/operator-sdk-${RELEASE_VERSION}-x86_64-linux-gnu \
    && chmod +x operator-sdk-${RELEASE_VERSION}-x86_64-linux-gnu && cp operator-sdk-${RELEASE_VERSION}-x86_64-linux-gnu /usr/local/bin/operator-sdk && rm operator-sdk-${RELEASE_VERSION}-x86_64-linux-gnu
RUN curl https://raw.githubusercontent.com/golang/dep/master/install.sh | sh
WORKDIR /go/src/github.com/ibm/secret-sync-operator
RUN PATH=$GOPATH/bin:$PATH dep ensure
RUN PATH=$GOPATH/bin:$PATH go build -o build/_output/bin/secret-sync-operator cmd/manager/main.go 



FROM registry.access.redhat.com/ubi7-dev-preview/ubi-minimal:7.6
ENV OPERATOR=/usr/local/bin/secret-sync-operator \
    USER_UID=1001 \
    USER_NAME=secret-sync-operator
# install operator binary
COPY --from=0 /go/src/github.com/ibm/secret-sync-operator/build/_output/bin/secret-sync-operator ${OPERATOR}
COPY --from=0 /go/src/github.com/ibm/secret-sync-operator/build/bin /usr/local/bin
RUN  /usr/local/bin/user_setup
ENTRYPOINT ["/usr/local/bin/entrypoint"]
USER ${USER_UID}

