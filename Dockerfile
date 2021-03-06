FROM openjdk:11-jdk-slim
MAINTAINER Oleg Nenashev <o.v.nenashev@gmail.com>

ARG VERSION=3.36
ARG user=jenkins
ARG group=jenkins
ARG uid=1000
ARG gid=1000

RUN groupadd -g ${gid} ${group}
RUN useradd -c "Jenkins user" -d /home/${user} -u ${uid} -g ${gid} -m ${user}
LABEL Description="This is a base image, which provides the Jenkins agent executable (slave.jar)" Vendor="Jenkins project" Version="${VERSION}"

ARG AGENT_WORKDIR=/home/${user}/agent

RUN echo 'deb http://deb.debian.org/debian stretch-backports main' > /etc/apt/sources.list.d/stretch-backports.list &&\
    apt-get update && apt-get -y --no-install-recommends install curl git-lfs && rm -rf /var/lib/apt/lists/* &&\
    curl --create-dirs -fsSLo /usr/share/jenkins/agent.jar https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/${VERSION}/remoting-${VERSION}.jar \
  && chmod 755 /usr/share/jenkins \
  && chmod 644 /usr/share/jenkins/agent.jar \
  && ln -sf /usr/share/jenkins/agent.jar /usr/share/jenkins/slave.jar

USER ${user}
ENV AGENT_WORKDIR=${AGENT_WORKDIR}
RUN mkdir /home/${user}/.jenkins && mkdir -p ${AGENT_WORKDIR}

VOLUME /home/${user}/.jenkins
VOLUME ${AGENT_WORKDIR}
WORKDIR /home/${user}


USER root
COPY jenkins-agent /usr/local/bin/jenkins-agent

RUN apt-get update &&\
    apt-get -y --no-install-recommends install build-essential libssl-dev libffi-dev python3 python3-distutils gnupg2  &&\
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 93C4A3FD7BB9C367 &&\
    apt-get -y --no-install-recommends install ansible &&\
    curl -O https://bootstrap.pypa.io/get-pip.py &&\
    python3 get-pip.py &&\
    pip3 install awscli --upgrade &&\
    pip3 install boto3 --upgrade &&\
    pip3 install boto --upgrade &&\
    pip3 install request --upgrade &&\
    pip3 install git+https://github.com/WesWWagner/ansible.git@stable-2.9 && \
    chmod +x /usr/local/bin/jenkins-agent &&\
    ln -s /usr/local/bin/jenkins-agent /usr/local/bin/jenkins-slave &&\
    rm -rf /var/lib/apt/lists/* 
USER ${user}

ENTRYPOINT ["jenkins-agent"]
