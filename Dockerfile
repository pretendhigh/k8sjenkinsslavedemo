FROM openjdk:8-jdk-alpine

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV TZ=Asia/Shanghai

RUN mkdir /app

WORKDIR /app

COPY target/javawebdemo-1.0-SNAPSHOT.jar  /app/javawebdemo.jar

EXPOSE <APP_PORT>

ENTRYPOINT ["java", "-Djava.security.egd=file:/dev/./urandom", "-jar", "--server.port=<APP_PORT>", "javawebdemo.jar"]
