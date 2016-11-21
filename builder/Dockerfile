FROM edwinek/alpine-jdk8-maven:latest

ADD heavyweight-src.tar /opt/src
WORKDIR /opt/src
RUN mvn package
