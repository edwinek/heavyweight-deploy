FROM alpine:3.3

ENV JAVA_HOME=/usr/lib/jvm/default-jvm \ 
	PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:/bin 
RUN apk add --update openjdk8 \
    && apk add --update --repository http://dl-3.alpinelinux.org/alpine/edge/community/ --allow-untrusted maven \
    && rm -rf /var/cache/apk/*
ADD heavyweight-src.tar /opt/src
WORKDIR /opt/src
RUN mvn package
CMD tail -f /dev/null
