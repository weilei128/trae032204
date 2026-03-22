# 使用OpenJDK 8作为基础镜像
FROM openjdk:8-jdk-alpine

# 设置工作目录
WORKDIR /app

# 设置时区为上海
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 复制jar包到容器中
COPY kimi.jar app.jar

# 创建数据目录
RUN mkdir -p /app/data

# 暴露端口
EXPOSE 10013

# 设置JVM参数并运行应用
ENV JAVA_OPTS="-Xms256m -Xmx512m"

# 启动命令
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar --server.port=10013"]
