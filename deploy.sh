#! /usr/bin/sh

if [ ! -d getter ]; then
	mkdir getter
fi

touch getter/Dockerfile

cat > getter/Dockerfile <<EOL
FROM debian:8

RUN apt-get -y update && apt-get install -y git
RUN git clone https://github.com/edwinek/heavyweight.git 
WORKDIR heavyweight
RUN git archive master > /tmp/src.tar
EOL

if [ ! -d builder ]; then
	mkdir builder
fi

touch builder/Dockerfile

cat > builder/Dockerfile <<EOL
FROM debian:8

RUN apt-get -y update && apt-get install -y maven openjdk-7-jdk
ADD src.tar /opt/src
WORKDIR /opt/src
RUN mvn package
EOL

if [ ! -d deployer ]; then
  mkdir deployer
fi

touch deployer/Dockerfile

cat > deployer/Dockerfile <<EOL
FROM tomcat:8-jre7

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

rm getter/*
rm builder/*
rm deployer/*
rmdir getter builder deployer

docker run -it --rm -p 8888:8080 deployer

