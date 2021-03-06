#! /bin/bash

PROJECT_NAME=heavyweight
PROJECT_URL=http://www.github.com/edwinek/$PROJECT_NAME
SRC_ARCHIVE=$PROJECT_NAME-src.tar
WAR_FILE=$PROJECT_NAME.war

function cleanup_containers_and_files() {
    rm builder/$SRC_ARCHIVE
    rm deployer/$WAR_FILE
	docker rm getter_container
	docker rm builder_container
	docker rm deployer_container
	docker rm mongo_container
}

cleanup_containers_and_files

docker run --name getter_container -tid edwinek/alpine-git:latest sh
docker exec -ti getter_container git clone $PROJECT_URL /opt/src/$PROJECT_NAME
docker exec -ti getter_container sh -c "cd /opt/src/$PROJECT_NAME && git archive -o /tmp/$SRC_ARCHIVE master"
docker cp getter_container:/tmp/$SRC_ARCHIVE builder/$SRC_ARCHIVE
docker stop getter_container

docker build -t builder_image builder/.
docker run --name builder_container -tid builder_image sh
docker cp builder_container:/opt/src/build/libs/$WAR_FILE deployer/$WAR_FILE
docker stop builder_container

docker build -t deployer_image deployer/.
docker run --name mongo_container -d mongo
docker run --link mongo_container:mongoip --name deployer_container -ti -p 8888:8080 deployer_image
docker stop deployer_container
docker stop mongo_container

cleanup_containers_and_files
