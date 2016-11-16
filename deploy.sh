#! /bin/bash

function cleanup_files() {
	for FILES_TO_DELETE in builder/* getter/* deployer/*
	do
		if [ -f $FILES_TO_DELETE ]; then
			rm $FILES_TO_DELETE
		fi
	done
	for DIR_TO_DELETE in builder getter deployer
	do
		if [ -d $DIR_TO_DELETE ]; then
			rmdir $DIR_TO_DELETE
		fi
	done
}

function cleanup_containers() {
	docker rm getter_container
	docker rm builder_container
	docker rm deployer_container
	docker rm mongo_container
}

function create() {
	for DIR_TO_CREATE in builder getter deployer
	do
		mkdir $DIR_TO_CREATE
	done
}

cleanup_containers
cleanup_files
create

cat > getter/Dockerfile <<EOL
FROM alpine:3.1

RUN apk add --update git
EOL

cat > builder/Dockerfile <<EOL
FROM alpine:3.4

ENV JAVA_HOME=/usr/lib/jvm/default-jvm \ 
	PATH=${PATH}:${JAVA_HOME}/bin 
RUN apk add --update openjdk8 && \
    apk add --update --repository http://dl-3.alpinelinux.org/alpine/edge/community/ --allow-untrusted maven && \
    rm -rf /var/cache/apk/*
ADD src.tar /opt/src
WORKDIR /opt/src
RUN mvn package
EOL

cat > deployer/Dockerfile <<EOL
FROM tomcat:8-jre8-alpine

ADD heavyweight.war /usr/local/tomcat/webapps/heavyweight.war
EOL


docker build -t getter_image getter/.
docker run --name getter_container -d getter_image tail -f /dev/null
docker exec -ti getter_container git clone http://www.github.com/edwinek/heavyweight /opt/src/heavyweight
docker exec -ti getter_container sh -c "cd /opt/src/heavyweight && git archive -o /tmp/src.tar master"
docker cp getter_container:/tmp/src.tar builder/src.tar
docker stop getter_container 

docker build -t builder_image builder/.
docker run --name builder_container -d builder_image tail -f /dev/null
docker cp builder_container:/opt/src/target/heavyweight.war deployer/heavyweight.war
docker stop builder_container

docker build -t deployer_image deployer/.

docker run --name mongo_container -d mongo
docker run --link mongo_container:mongoip --name deployer_container -ti -p 8888:8080 deployer_image catalina.sh run
docker stop mongo_container

cleanup_files
cleanup_containers
