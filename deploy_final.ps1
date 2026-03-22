<#
.SYNOPSIS
SpringBoot Docker 一键部署脚本
.DESCRIPTION
自动化完成 SpringBoot 应用的 Docker 容器化部署
包括：打包、上传、构建、部署、验证
#>

param(
    [string]$ServerIp = "49.235.161.106",
    [int]$SshPort = 22,
    [string]$Username = "root",
    [string]$TargetDir = "/opt/apps/memo-app",
    [string]$AppName = "market-app",
    [string]$JarName = "dogFooding.jar",
    [int]$AppPort = 10011,
    [string]$JvmOpts = "-Xms256m -Xmx512m"
)

$ErrorActionPreference = "Stop"

function Write-Step { param([int]$Step, [int]$Total, [string]$Message) Write-Host "[$Step/$Total] $Message" -ForegroundColor Yellow }
function Write-Success { param([string]$Message) Write-Host "[成功] $Message" -ForegroundColor Green }
function Write-Warn { param([string]$Message) Write-Host "[警告] $Message" -ForegroundColor Yellow }
function Write-Error { param([string]$Message) Write-Host "[错误] $Message" -ForegroundColor Red }

Write-Host "`n=============================================" -ForegroundColor Cyan
Write-Host "  SpringBoot Docker 一键部署脚本" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  服务器: $ServerIp`:$SshPort" -ForegroundColor Gray
Write-Host "  应用: $AppName" -ForegroundColor Gray
Write-Host "  端口: $AppPort" -ForegroundColor Gray
Write-Host "=============================================`n" -ForegroundColor Cyan

try {
    # 1. 本地打包
    Write-Step 1 6 "开始本地 Maven 打包..."
    if (-not (Test-Path "pom.xml")) { Write-Error "未找到 pom.xml，请在项目根目录执行"; exit 1 }
    
    Write-Host "  执行: mvn clean package -DskipTests" -ForegroundColor Gray
    mvn clean package -DskipTests
    if ($LASTEXITCODE -ne 0) { Write-Error "Maven 打包失败"; exit 1 }
    
    Write-Host "  重命名 jar 包为: $JarName" -ForegroundColor Gray
    $sourceJar = Get-ChildItem -Path target -Filter "*.jar" | Where-Object { $_.Name -like "*.jar" -and $_.Name -notlike "*original*" } | Select-Object -First 1
    if (-not $sourceJar) { Write-Error "未找到生成的 jar 包"; exit 1 }
    Copy-Item $sourceJar.FullName "target\$JarName" -Force
    Write-Success "本地打包完成"

    # 2. 检查 Dockerfile
    Write-Step 2 6 "检查 Dockerfile..."
    if (-not (Test-Path "Dockerfile")) {
        Write-Host "  生成 Dockerfile..." -ForegroundColor Gray
@"
FROM openjdk:8-jre-alpine
LABEL maintainer="$AppName"
LABEL version="1.0.0"
WORKDIR /app
COPY $JarName /app/app.jar
EXPOSE $AppPort
ENV JVM_OPTS="$JvmOpts"
ENTRYPOINT ["sh", "-c", "java \$JVM_OPTS -Djava.security.egd=file:/dev/./urandom -jar /app/app.jar"]
"@ | Out-File -FilePath "Dockerfile" -Encoding utf8
    }
    Write-Success "Dockerfile 就绪"

    # 3. 上传文件
    Write-Step 3 6 "上传文件到服务器..."
    Write-Host "  创建远程目录: $TargetDir" -ForegroundColor Gray
    ssh -p $SshPort $Username@$ServerIp "mkdir -p $TargetDir"
    if ($LASTEXITCODE -ne 0) { Write-Error "SSH 连接失败，请确认密钥配置或网络连接"; exit 1 }

    Write-Host "  上传: $JarName" -ForegroundColor Gray
    scp -P $SshPort "target\$JarName" "$Username@$ServerIp`:$TargetDir/"
    if ($LASTEXITCODE -ne 0) { Write-Error "Jar 包上传失败"; exit 1 }

    Write-Host "  上传: Dockerfile" -ForegroundColor Gray
    scp -P $SshPort "Dockerfile" "$Username@$ServerIp`:$TargetDir/"
    if ($LASTEXITCODE -ne 0) { Write-Error "Dockerfile 上传失败"; exit 1 }
    Write-Success "文件上传完成"

    # 4. 构建镜像
    Write-Step 4 6 "构建 Docker 镜像..."
    $buildCmd = @"
cd $TargetDir && \
docker stop $AppName 2>/dev/null; \
docker rm $AppName 2>/dev/null; \
docker rmi $AppName 2>/dev/null; \
docker build -t $AppName .
"@
    ssh -p $SshPort $Username@$ServerIp $buildCmd
    if ($LASTEXITCODE -ne 0) { Write-Error "Docker 镜像构建失败"; exit 1 }
    Write-Success "Docker 镜像构建完成"

    # 5. 启动容器
    Write-Step 5 6 "启动 Docker 容器..."
    Write-Host "  检查并清理端口占用..." -ForegroundColor Gray
    $runCmd = @"
OLD_CONTAINER=\$(docker ps --filter 'publish=$AppPort' --format '{{.Names}}' 2>/dev/null | head -1); \
if [ ! -z "\$OLD_CONTAINER" ]; then \
    echo "  停止占用端口的容器: \$OLD_CONTAINER"; \
    docker stop \$OLD_CONTAINER && docker rm \$OLD_CONTAINER; \
fi; \
docker run -d --name $AppName --restart=always -p $AppPort:$AppPort -e JVM_OPTS="$JvmOpts" $AppName
"@
    $containerId = ssh -p $SshPort $Username@$ServerIp $runCmd
    if ($LASTEXITCODE -ne 0 -or -not $containerId) { Write-Error "容器启动失败"; exit 1 }
    Write-Host "  容器 ID: $containerId" -ForegroundColor Gray
    Write-Success "容器启动完成"

    # 6. 验证服务
    Write-Step 6 6 "验证服务状态..."
    Write-Host "  等待服务启动 (15秒)..." -ForegroundColor Gray
    Start-Sleep -Seconds 15
    
    $status = ssh -p $SshPort $Username@$ServerIp "docker inspect -f '{{.State.Running}}' $AppName 2>/dev/null"
    if ($status.Trim() -ne "true") {
        Write-Warn "容器状态异常，检查日志..."
        ssh -p $SshPort $Username@$ServerIp "docker logs $AppName --tail 20"
        exit 1
    }
    
    Write-Success "部署成功! 🎉"
    Write-Host "`n=============================================" -ForegroundColor Cyan
    Write-Host "  应用名称: $AppName" -ForegroundColor Cyan
    Write-Host "  访问地址: http://$ServerIp`:$AppPort" -ForegroundColor Cyan
    Write-Host "  容器名称: $AppName" -ForegroundColor Gray
    Write-Host "  容器 ID: $containerId" -ForegroundColor Gray
    Write-Host "=============================================`n" -ForegroundColor Cyan
}
catch {
    Write-Error "部署过程发生异常: $_"
    exit 1
}
