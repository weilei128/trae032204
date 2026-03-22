# 简化版部署脚本 - 使用Git Bash/SSH命令

$ServerIp = "49.235.161.106"
$SshPort = 22
$Username = "root"
$TargetDir = "/opt/apps/memo-app"
$AppName = "market-app"
$JarName = "dogFooding.jar"
$AppPort = 10011
$JvmOpts = "-Xms256m -Xmx512m"

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "SpringBoot Docker 自动化部署脚本" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# 步骤1: 检查文件
Write-Host "[1/7] 检查本地文件..." -ForegroundColor Yellow
if (-not (Test-Path "target\$JarName")) {
    Write-Host "错误: Jar包不存在，请先执行Maven打包" -ForegroundColor Red
    exit 1
}
if (-not (Test-Path "Dockerfile")) {
    Write-Host "错误: Dockerfile不存在" -ForegroundColor Red
    exit 1
}
Write-Host "本地文件检查完成" -ForegroundColor Green

# 步骤2: 上传文件
Write-Host "[2/7] 上传文件到服务器..." -ForegroundColor Yellow
Write-Host "请确保已配置SSH密钥，或在提示时输入密码" -ForegroundColor Gray

# 上传Jar包
Write-Host "上传Jar包: $JarName" -ForegroundColor Gray
scp -P $SshPort "target\$JarName" "$Username@$ServerIp:$TargetDir/"
if ($LASTEXITCODE -ne 0) {
    Write-Host "Jar包上传失败" -ForegroundColor Red
    exit 1
}

# 上传Dockerfile
Write-Host "上传Dockerfile" -ForegroundColor Gray
scp -P $SshPort "Dockerfile" "$Username@$ServerIp:$TargetDir/"
if ($LASTEXITCODE -ne 0) {
    Write-Host "Dockerfile上传失败" -ForegroundColor Red
    exit 1
}
Write-Host "文件上传完成" -ForegroundColor Green

# 步骤3: 服务器端部署
Write-Host "[3/7] 服务器端部署..." -ForegroundColor Yellow

$sshCommand = @"
cd $TargetDir && \
echo '=== 检查Docker环境 ===' && \
docker --version || (echo '安装Docker...' && curl -fsSL https://get.docker.com | sh && systemctl start docker) && \
echo '=== 停止旧容器 ===' && \
docker stop $AppName 2>/dev/null; docker rm $AppName 2>/dev/null; \
echo '=== 删除旧镜像 ===' && \
docker rmi $AppName 2>/dev/null || true; \
echo '=== 构建新镜像 ===' && \
docker build -t $AppName . && \
echo '=== 检查端口占用 ===' && \
OLD_CONTAINER=\$(docker ps --filter 'publish=$AppPort' --format '{{.Names}}' 2>/dev/null | head -1); \
if [ ! -z \"\$OLD_CONTAINER\" ]; then \
    echo \"发现占用端口的容器: \$OLD_CONTAINER\"; \
    docker stop \$OLD_CONTAINER && docker rm \$OLD_CONTAINER; \
fi; \
echo '=== 启动新容器 ===' && \
docker run -d --name $AppName --restart=always -p $AppPort:$AppPort -e JVM_OPTS=\"$JvmOpts\" $AppName && \
echo '=== 容器启动成功，等待15秒... ===' && \
sleep 15 && \
echo '=== 检查容器状态 ===' && \
docker ps --filter name=$AppName && \
echo '=== 服务访问测试 ===' && \
HTTP_CODE=\$(curl -s -o /dev/null -w '%{http_code}' http://localhost:$AppPort 2>/dev/null || echo '000'); \
echo \"HTTP状态码: \$HTTP_CODE\"; \
if [ \"\$HTTP_CODE\" = \"000\" ]; then \
    echo '容器日志:'; \
    docker logs $AppName --tail 30; \
fi
"@

ssh -p $SshPort "$Username@$ServerIp" $sshCommand

if ($LASTEXITCODE -ne 0) {
    Write-Host "远程命令执行失败" -ForegroundColor Red
    exit 1
}

Write-Host "[4/7] 部署命令执行完成" -ForegroundColor Green

# 步骤4: 验证服务
Write-Host "[5/7] 验证服务状态..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

Write-Host "[6/7] 显示最终信息" -ForegroundColor Yellow
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "部署完成! 🎉" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "应用名称: $AppName" -ForegroundColor Cyan
Write-Host "访问地址: http://$ServerIp:$AppPort" -ForegroundColor Cyan
Write-Host "服务器端口: $AppPort" -ForegroundColor Cyan
Write-Host "容器名称: $AppName" -ForegroundColor Gray
Write-Host "=============================================" -ForegroundColor Cyan

Write-Host "[7/7] 全部完成!" -ForegroundColor Green
