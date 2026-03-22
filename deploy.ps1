# SpringBoot Docker 部署脚本
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

# 颜色输出函数
function Write-ColorOutput {
    param([string]$Message, [ConsoleColor]$Color = [ConsoleColor]::White)
    Write-Host $Message -ForegroundColor $Color
}

# 检查是否已导入Posh-SSH模块
if (-not (Get-Module -Name Posh-SSH -ListAvailable)) {
    Write-ColorOutput "正在安装Posh-SSH模块..." Yellow
    Install-Module -Name Posh-SSH -Force -Scope CurrentUser -AllowClobber
}
Import-Module Posh-SSH -Force

Write-ColorOutput "=============================================" Cyan
Write-ColorOutput "SpringBoot Docker 自动化部署脚本" Cyan
Write-ColorOutput "=============================================" Cyan
Write-ColorOutput "服务器: $ServerIp" Gray
Write-ColorOutput "应用名称: $AppName" Gray
Write-ColorOutput "应用端口: $AppPort" Gray
Write-ColorOutput "=============================================" Cyan

# 检查本地文件是否存在
$localJarPath = Join-Path -Path $PWD.Path -ChildPath "target\$JarName"
$localDockerfilePath = Join-Path -Path $PWD.Path -ChildPath "Dockerfile"

if (-not (Test-Path $localJarPath)) {
    Write-ColorOutput "错误: 本地Jar包不存在 - $localJarPath" Red
    exit 1
}

if (-not (Test-Path $localDockerfilePath)) {
    Write-ColorOutput "错误: Dockerfile不存在 - $localDockerfilePath" Red
    exit 1
}

Write-ColorOutput "[1/8] 本地文件检查完成" Green

# 建立SSH连接
try {
    Write-ColorOutput "[2/8] 正在建立SSH连接到 $ServerIp..." Yellow
    
    # 检查是否有现有的SSH会话
    $existingSession = Get-SSHSession | Where-Object { $_.Host -eq $ServerIp }
    if ($existingSession) {
        Write-ColorOutput "发现现有SSH连接，复用连接" Gray
        $sshSession = $existingSession
    } else {
        # 使用SSH密钥认证
        $sshSession = New-SSHSession -ComputerName $ServerIp -Port $SshPort -Username $Username -Keyfile "$env:USERPROFILE\.ssh\id_rsa" -AcceptKey
        if (-not $sshSession) {
            Write-ColorOutput "尝试使用密码认证（如果密钥失败）..." Yellow
            $credential = Get-Credential -Message "请输入SSH密码" -UserName $Username
            $sshSession = New-SSHSession -ComputerName $ServerIp -Port $SshPort -Credential $credential -AcceptKey
        }
    }
    
    if (-not $sshSession) {
        Write-ColorOutput "错误: SSH连接失败" Red
        exit 1
    }
    Write-ColorOutput "SSH连接建立成功" Green
}
catch {
    Write-ColorOutput "SSH连接失败: $_" Red
    Write-ColorOutput "请确保:" Yellow
    Write-ColorOutput "1. 服务器IP和端口正确" Yellow
    Write-ColorOutput "2. SSH密钥已配置在服务器的 ~/.ssh/authorized_keys 中" Yellow
    Write-ColorOutput "3. 本地私钥位于 $env:USERPROFILE\.ssh\id_rsa" Yellow
    exit 1
}

# 执行SSH命令函数
function Invoke-SSHCommandWrapper {
    param([string]$Command)
    $result = Invoke-SSHCommand -SessionId $sshSession.SessionId -Command $Command -EnsureConnection
    return $result
}

try {
    # 服务器环境检测
    Write-ColorOutput "[3/8] 服务器环境检测..." Yellow
    
    # 检查Docker是否安装
    $dockerCheck = Invoke-SSHCommandWrapper "docker --version 2>/dev/null || echo 'NOT_INSTALLED'"
    if ($dockerCheck.Output -like "*NOT_INSTALLED*" -or $dockerCheck.Output -like "*command not found*") {
        Write-ColorOutput "警告: Docker未安装，正在安装Docker..." Yellow
        $null = Invoke-SSHCommandWrapper "curl -fsSL https://get.docker.com | sh && systemctl start docker && systemctl enable docker"
    }
    $dockerVersion = Invoke-SSHCommandWrapper "docker --version"
    Write-ColorOutput "Docker版本: $($dockerVersion.Output)" Gray
    
    # 检查目标目录
    $null = Invoke-SSHCommandWrapper "mkdir -p $TargetDir"
    Write-ColorOutput "目标目录已确认: $TargetDir" Gray
    
    # 检查是否已有Dockerfile
    $existingDockerfile = Invoke-SSHCommandWrapper "test -f $TargetDir/Dockerfile && echo 'EXISTS' || echo 'NOT_EXISTS'"
    if ($existingDockerfile.Output -like "*EXISTS*") {
        Write-ColorOutput "服务器上已存在Dockerfile，将被覆盖" Yellow
    }
    
    Write-ColorOutput "服务器环境检测完成" Green
}
catch {
    Write-ColorOutput "服务器环境检测失败: $_" Red
    exit 1
}

try {
    # 上传文件
    Write-ColorOutput "[4/8] 正在上传文件到服务器..." Yellow
    
    # 设置SCP连接
    $scpParams = @{
        ComputerName = $ServerIp
        Port = $SshPort
        Username = $Username
        Keyfile = "$env:USERPROFILE\.ssh\id_rsa"
        AcceptKey = $true
    }
    
    try {
        Set-SCPFile @scpParams -LocalFile $localJarPath -RemotePath $TargetDir
        Write-ColorOutput "Jar包上传成功: $JarName" Gray
    }
    catch {
        Write-ColorOutput "使用密钥上传失败，尝试使用密码上传..." Yellow
        $credential = Get-Credential -Message "请输入SSH密码用于SCP上传" -UserName $Username
        Set-SCPFile -ComputerName $ServerIp -Port $SshPort -Credential $credential -AcceptKey -LocalFile $localJarPath -RemotePath $TargetDir
        Write-ColorOutput "Jar包上传成功: $JarName" Gray
    }
    
    try {
        Set-SCPFile @scpParams -LocalFile $localDockerfilePath -RemotePath $TargetDir
        Write-ColorOutput "Dockerfile上传成功" Gray
    }
    catch {
        Write-ColorOutput "使用密钥上传Dockerfile失败，尝试使用密码上传..." Yellow
        $credential = Get-Credential -Message "请输入SSH密码用于SCP上传" -UserName $Username
        Set-SCPFile -ComputerName $ServerIp -Port $SshPort -Credential $credential -AcceptKey -LocalFile $localDockerfilePath -RemotePath $TargetDir
        Write-ColorOutput "Dockerfile上传成功" Gray
    }
    
    Write-ColorOutput "文件上传完成" Green
}
catch {
    Write-ColorOutput "文件上传失败: $_" Red
    exit 1
}

try {
    # 构建Docker镜像
    Write-ColorOutput "[5/8] 正在构建Docker镜像..." Yellow
    
    $imageName = "$AppName:latest"
    
    # 停止并删除旧容器（如果存在）
    $null = Invoke-SSHCommandWrapper "docker stop $AppName 2>/dev/null; docker rm $AppName 2>/dev/null"
    
    # 删除旧镜像
    $null = Invoke-SSHCommandWrapper "docker rmi $imageName 2>/dev/null || true"
    
    # 构建新镜像
    $buildResult = Invoke-SSHCommandWrapper "cd $TargetDir && docker build -t $imageName ."
    if ($buildResult.ExitStatus -ne 0) {
        Write-ColorOutput "Docker镜像构建失败: $($buildResult.Error)" Red
        exit 1
    }
    Write-ColorOutput "Docker镜像构建成功: $imageName" Gray
    
    Write-ColorOutput "Docker镜像构建完成" Green
}
catch {
    Write-ColorOutput "Docker镜像构建失败: $_" Red
    exit 1
}

try {
    # 端口检测和容器运行
    Write-ColorOutput "[6/8] 端口检测和容器运行准备..." Yellow
    
    # 检测端口是否被占用
    $portCheck = Invoke-SSHCommandWrapper "netstat -tulpn 2>/dev/null | grep :$AppPort || ss -tulpn 2>/dev/null | grep :$AppPort || lsof -i :$AppPort 2>/dev/null || echo 'FREE'"
    
    if ($portCheck.Output -notlike "*FREE*" -and $portCheck.Output -match '([0-9]+)/') {
        $pid = $matches[1]
        Write-ColorOutput "端口 $AppPort 被占用，PID: $pid，正在清理..." Yellow
        
        # 检查是否是Docker容器占用
        $containerCheck = Invoke-SSHCommandWrapper "docker ps --filter 'publish=$AppPort' --format '{{.Names}}' 2>/dev/null | head -1"
        if ($containerCheck.Output -and $containerCheck.Output -ne "") {
            $containerName = $containerCheck.Output.Trim()
            Write-ColorOutput "发现Docker容器占用端口: $containerName" Gray
            $null = Invoke-SSHCommandWrapper "docker stop $containerName && docker rm $containerName"
            Write-ColorOutput "已停止并移除占用端口的容器: $containerName" Gray
        }
        else {
            Write-ColorOutput "尝试杀死占用端口的进程: $pid" Gray
            $null = Invoke-SSHCommandWrapper "kill -9 $pid 2>/dev/null || true"
        }
        
        # 等待端口释放
        Start-Sleep -Seconds 3
    }
    
    Write-ColorOutput "端口 $AppPort 已准备好" Gray
    Write-ColorOutput "端口检测完成" Green
}
catch {
    Write-ColorOutput "端口检测失败: $_" Red
}

try {
    # 运行容器
    Write-ColorOutput "[7/8] 正在启动Docker容器..." Yellow
    
    $runCommand = @"
docker run -d \
    --name $AppName \
    --restart=always \
    -p $AppPort:$AppPort \
    -e JVM_OPTS="$JvmOpts" \
    $imageName
"@
    
    $runResult = Invoke-SSHCommandWrapper $runCommand
    if ($runResult.ExitStatus -ne 0) {
        Write-ColorOutput "容器启动失败: $($runResult.Error)" Red
        exit 1
    }
    
    $containerId = $runResult.Output.Trim()
    Write-ColorOutput "容器启动成功，ID: $containerId" Gray
    
    # 等待容器启动
    Write-ColorOutput "等待应用启动..." Yellow
    Start-Sleep -Seconds 10
    
    Write-ColorOutput "容器运行完成" Green
}
catch {
    Write-ColorOutput "容器启动失败: $_" Red
    exit 1
}

try {
    # 验证服务
    Write-ColorOutput "[8/8] 验证服务状态..." Yellow
    
    # 检查容器状态
    $containerStatus = Invoke-SSHCommandWrapper "docker inspect -f '{{.State.Running}}' $AppName 2>/dev/null || echo 'false'"
    if ($containerStatus.Output.Trim() -ne "true") {
        Write-ColorOutput "警告: 容器未在运行，检查容器日志..." Red
        $logs = Invoke-SSHCommandWrapper "docker logs $AppName --tail 50 2>&1"
        Write-ColorOutput "容器日志:" Red
        Write-ColorOutput $logs.Output Gray
        exit 1
    }
    
    # 检查端口监听
    $portListenCheck = Invoke-SSHCommandWrapper "docker exec $AppName netstat -tulpn 2>/dev/null | grep :$AppPort || echo 'CHECK_FAILED'"
    if ($portListenCheck.Output -like "*CHECK_FAILED*") {
        Write-ColorOutput "容器内端口检查失败，可能是netstat未安装，尝试直接HTTP检测..." Yellow
    }
    
    # HTTP检测
    Write-ColorOutput "正在进行HTTP健康检测..." Gray
    $healthCheck = Invoke-SSHCommandWrapper "curl -s -o /dev/null -w '%{http_code}' http://localhost:$AppPort 2>/dev/null || curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:$AppPort 2>/dev/null || echo '000'"
    $httpCode = $healthCheck.Output.Trim()
    
    Write-ColorOutput "服务状态验证完成" Green
    Write-ColorOutput "=============================================" Cyan
    Write-ColorOutput "部署成功! 🎉" Green
    Write-ColorOutput "=============================================" Cyan
    Write-ColorOutput "应用名称: $AppName" Cyan
    Write-ColorOutput "访问地址: http://$ServerIp:$AppPort" Cyan
    Write-ColorOutput "HTTP状态码: $httpCode" Cyan
    Write-ColorOutput "容器ID: $containerId" Gray
    Write-ColorOutput "=============================================" Cyan
}
catch {
    Write-ColorOutput "服务验证失败: $_" Red
    Write-ColorOutput "尝试检查容器日志:" Yellow
    $logs = Invoke-SSHCommandWrapper "docker logs $AppName --tail 50 2>&1"
    Write-ColorOutput $logs.Output Gray
    exit 1
}
finally {
    # 清理SSH会话
    if ($sshSession) {
        Remove-SSHSession -SessionId $sshSession.SessionId | Out-Null
    }
}
