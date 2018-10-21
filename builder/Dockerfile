FROM openjdk:8-jdk-alpine

ADD heavyweight-src.tar /opt/src
WORKDIR /opt/src
RUN /opt/src/gradlew clean war
