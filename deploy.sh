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

docker build -t getter_image getter/.
docker run --name getter_container -d getter_image tail -f /dev/null
docker exec -ti getter_container sh -c "git clone $PROJECT_URL /opt/src/$PROJECT_NAME"
docker exec -ti getter_container sh -c "cd /opt/src/$PROJECT_NAME && git archive -o /tmp/$SRC_ARCHIVE master"
docker cp getter_container:/tmp/$SRC_ARCHIVE builder/$SRC_ARCHIVE
docker stop getter_container

docker build -t builder_image builder/.
docker run --name builder_container -d builder_image tail -f /dev/null
docker cp builder_container:/opt/src/target/$WAR_FILE deployer/$WAR_FILE
docker stop builder_container

docker build -t deployer_image deployer/.
docker run --name mongo_container -d mongo
docker run --link mongo_container:mongoip --name deployer_container -ti -p 8888:8080 deployer_image catalina.sh run
docker stop deployer_container
docker stop mongo_container

cleanup_containers_and_files