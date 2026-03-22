FROM openjdk:8-jre-alpine

LABEL maintainer="market-app"
LABEL version="1.0.0"
LABEL description="SpringBoot Market Application"

WORKDIR /app

COPY dogFooding.jar /app/app.jar

EXPOSE 10011

ENV JVM_OPTS="-Xms256m -Xmx512m"

ENTRYPOINT ["sh", "-c", "java $JVM_OPTS -Djava.security.egd=file:/dev/./urandom -jar /app/app.jar"]
