# SpringBoot Docker 容器化部署总结

## 部署完成信息

| 项目 | 详情 |
|------|------|
| 应用名称 | market-app |
| 应用版本 | 1.0.0 |
| 服务器IP | 49.235.161.106 |
| 服务端口 | 10011 |
| 访问地址 | http://49.235.161.106:10011 |
| JVM参数 | -Xms256m -Xmx512m |
| 容器名称 | market-app |
| 部署目录 | /opt/apps/memo-app |

## 已完成的工作

1. **修改应用配置**
   - 修改 `application.yml` 将服务端口从 8080 改为 10011

2. **项目构建**
   - 使用 Maven 完成项目打包
   - 生成 jar 包并重命名为 `dogFooding.jar`

3. **创建 Dockerfile**
   ```dockerfile
   FROM openjdk:8-jre-alpine
   LABEL maintainer="market-app"
   LABEL version="1.0.0"
   WORKDIR /app
   COPY dogFooding.jar /app/app.jar
   EXPOSE 10011
   ENV JVM_OPTS="-Xms256m -Xmx512m"
   ENTRYPOINT ["sh", "-c", "java $JVM_OPTS -Djava.security.egd=file:/dev/./urandom -jar /app/app.jar"]
   ```

4. **文件上传**
   - 上传 `dogFooding.jar` 到服务器 `/opt/apps/memo-app/`
   - 上传 `Dockerfile` 到服务器 `/opt/apps/memo-app/`

5. **Docker 部署**
   - 构建 Docker 镜像: `market-app:latest`
   - 停止并移除旧容器（如果存在）
   - 启动新容器，端口映射 10011:10011
   - 配置容器自动重启

## 部署文件清单

```
├── target/
│   └── dogFooding.jar          # 应用jar包
├── Dockerfile                   # Docker构建文件
├── deploy.ps1                   # 完整PowerShell部署脚本
├── deploy_simple.ps1           # 简化版部署脚本
└── DEPLOYMENT_SUMMARY.md       # 部署总结文档
```

## 服务器操作命令

```bash
# 查看容器状态
docker ps --filter name=market-app

# 查看容器日志
docker logs market-app

# 重启容器
docker restart market-app

# 停止容器
docker stop market-app

# 进入容器
docker exec -it market-app sh
```

## 一键部署脚本使用

在 Windows PowerShell 中执行：

```powershell
# 确保已配置SSH密钥认证
# 然后执行简化版部署脚本
.\deploy_simple.ps1
```

## 验证服务

容器已成功启动，服务正在运行中。访问地址：
**http://49.235.161.106:10011**
