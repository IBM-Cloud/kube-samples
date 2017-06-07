FROM ubuntu

RUN apt-get update &&\
    apt-get install -y openssh-client &&\
    apt-get upgrade -y &&\
    apt-get clean

RUN mkdir /daemonset
WORKDIR /daemonset

ADD incontainer.sh /daemonset/incontainer.sh
RUN chmod 700 /daemonset/incontainer.sh

ADD unrootsquashset.sh /daemonset/unrootsquashset.sh
RUN chmod 700 /daemonset/unrootsquashset.sh

ADD unrootsquashundo.sh /daemonset/unrootsquashundo.sh
RUN chmod 700 /daemonset/unrootsquashundo.sh

CMD bash -c /daemonset/incontainer.sh

