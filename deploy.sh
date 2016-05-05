#! /bin/bash

function cleanup() {
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

function create() {
	for DIR_TO_CREATE in builder getter deployer
	do
		mkdir $DIR_TO_CREATE
		touch $DIR_TO_CREATE/Dockerfile
	done
}

cleanup
create

FILENAME=git-clone-$(date -u +"%Y%m%d%H%M%S").sh
LOCAL_FILE=getter/$FILENAME

touch $LOCAL_FILE
chmod +x $LOCAL_FILE

cat > "$LOCAL_FILE" <<EOL
#!/bin/bash
git clone https://github.com/edwinek/heavyweight.git
EOL
touch getter/Dockerfile

cat > getter/Dockerfile <<EOL
FROM debian:8.4

RUN apt-get -y update && apt-get install -y git
ADD $FILENAME . 
RUN ./$FILENAME
WORKDIR heavyweight
RUN git archive master > /tmp/src.tar
EOL

cat > builder/Dockerfile <<EOL
FROM debian:8.4

RUN apt-get -y update && apt-get install -y maven openjdk-7-jdk
ADD src.tar /opt/src
WORKDIR /opt/src
RUN mvn package
EOL

cat > deployer/Dockerfile <<EOL
FROM tomcat:8.0.33-jre7

RUN apt-get -y update && apt-get install -y mongodb
ADD heavyweight.war /usr/local/tomcat/webapps/heavyweight.war
ADD go.sh /opt/go.sh
CMD ["/opt/go.sh"]
EOL

touch deployer/go.sh
chmod +x deployer/go.sh

cat > deployer/go.sh <<EOL
#! /bin/bash
service mongodb start && catalina.sh run
EOL


docker build -t getter getter/.
docker run -d getter tail -f /dev/null
docker cp $(docker ps -q):/tmp/src.tar builder/src.tar
docker stop $(docker ps -q)

docker build -t builder builder/.
docker run -d builder tail -f /dev/null
docker cp $(docker ps -q):/opt/src/target/heavyweight.war deployer/heavyweight.war
docker stop $(docker ps -q)

docker build -t deployer deployer/.

cleanup

docker run -it --rm -p 8888:8080 deployer

