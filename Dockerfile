FROM openjdk:8-jdk-alpine

LABEL maintainer="market-app"
LABEL version="1.0.0"
LABEL description="SpringBoot Market Application"

WORKDIR /app

ENV JAVA_OPTS="-Xms256m -Xmx512m"
ENV TZ=Asia/Shanghai

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

COPY GLM.jar app.jar
COPY data ./data

EXPOSE 10012

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -Djava.security.egd=file:/dev/./urandom -jar app.jar"]
