# SpringBoot Docker Deployment Script
# Server Configuration
$SERVER_IP = "49.235.161.106"
$SERVER_PORT = "22"
$SERVER_USER = "root"
$SSH_KEY = "$env:USERPROFILE\.ssh\id_rsa"
$REMOTE_DIR = "/opt/apps/memo-app"

# Application Info
$APP_NAME = "market-app"
$APP_VERSION = "1.0.0"
$CONTAINER_NAME = "market-app"
$IMAGE_NAME = "market-app"
$PORT = "10013"

# Local File Paths
$LOCAL_JAR = "target\kimi.jar"
$LOCAL_DOCKERFILE = "Dockerfile"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SpringBoot Docker Deployment Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Local Maven Build
Write-Host "[Step 1/8] Building with Maven..." -ForegroundColor Yellow
mvn clean package -DskipTests
if ($LASTEXITCODE -ne 0) {
    Write-Host "Maven build failed!" -ForegroundColor Red
    exit 1
}

# Copy jar to kimi.jar
Copy-Item "target\simple-shop-1.0.0.jar" $LOCAL_JAR -Force
Write-Host "Maven build successful, kimi.jar generated" -ForegroundColor Green
Write-Host ""

# Step 2: Check Dockerfile
Write-Host "[Step 2/8] Checking Dockerfile..." -ForegroundColor Yellow
if (-not (Test-Path $LOCAL_DOCKERFILE)) {
    Write-Host "Dockerfile not found!" -ForegroundColor Red
    exit 1
}
Write-Host "Dockerfile exists" -ForegroundColor Green
Write-Host ""

# Step 3: SSH Connect and Check Environment
Write-Host "[Step 3/8] Connecting to server and checking environment..." -ForegroundColor Yellow

# Check if remote directory exists
$checkDirCmd = "if [ ! -d $REMOTE_DIR ]; then mkdir -p $REMOTE_DIR; fi; echo 'Directory check completed'"
ssh -p $SERVER_PORT -i $SSH_KEY ${SERVER_USER}@${SERVER_IP} $checkDirCmd

# Check if Docker is installed
$checkDockerCmd = "if command -v docker >/dev/null 2>&1; then echo 'Docker installed'; else echo 'Docker not installed'; fi"
$dockerStatus = ssh -p $SERVER_PORT -i $SSH_KEY ${SERVER_USER}@${SERVER_IP} $checkDockerCmd
Write-Host $dockerStatus

if ($dockerStatus -match "not installed") {
    Write-Host "Docker not installed on server, please install Docker first!" -ForegroundColor Red
    exit 1
}
Write-Host "Environment check completed" -ForegroundColor Green
Write-Host ""

# Step 4: Upload Files to Server
Write-Host "[Step 4/8] Uploading files to server..." -ForegroundColor Yellow

# Upload jar using SCP
scp -P $SERVER_PORT -i $SSH_KEY $LOCAL_JAR ${SERVER_USER}@${SERVER_IP}:${REMOTE_DIR}/
if ($LASTEXITCODE -ne 0) {
    Write-Host "Upload jar failed!" -ForegroundColor Red
    exit 1
}
Write-Host "kimi.jar uploaded successfully" -ForegroundColor Green

# Upload Dockerfile using SCP
scp -P $SERVER_PORT -i $SSH_KEY $LOCAL_DOCKERFILE ${SERVER_USER}@${SERVER_IP}:${REMOTE_DIR}/
if ($LASTEXITCODE -ne 0) {
    Write-Host "Upload Dockerfile failed!" -ForegroundColor Red
    exit 1
}
Write-Host "Dockerfile uploaded successfully" -ForegroundColor Green
Write-Host ""

# Step 5: Remote Deploy
Write-Host "[Step 5/8] Executing remote Docker deployment..." -ForegroundColor Yellow

# Create deploy script using single quotes to avoid PowerShell variable expansion
$deployScriptContent = '#!/bin/bash
cd ' + $REMOTE_DIR + '

echo "Checking if port ' + $PORT + ' is in use..."
CONTAINER_ID=$(docker ps -q --filter "publish=' + $PORT + '")
if [ -n "$CONTAINER_ID" ]; then
    echo "Port ' + $PORT + ' is in use, stopping related container..."
    docker stop $CONTAINER_ID
    docker rm $CONTAINER_ID
    echo "Container stopped and removed"
fi

echo "Stopping and removing old container (if exists)..."
docker stop ' + $CONTAINER_NAME + ' 2>/dev/null || true
docker rm ' + $CONTAINER_NAME + ' 2>/dev/null || true

echo "Removing old image (if exists)..."
docker rmi ' + $IMAGE_NAME + ':latest 2>/dev/null || true

echo "Building new image..."
docker build -t ' + $IMAGE_NAME + ':latest .

echo "Running new container..."
docker run -d --name ' + $CONTAINER_NAME + ' -p ' + $PORT + ':10013 -v ' + $REMOTE_DIR + '/data:/app/data --restart unless-stopped ' + $IMAGE_NAME + ':latest

echo "Deployment completed"'

# Save script to local temp file and upload
$localTempScript = "$env:TEMP\deploy.sh"
$deployScriptContent | Out-File -FilePath $localTempScript -Encoding ASCII

# Upload and execute script
scp -P $SERVER_PORT -i $SSH_KEY $localTempScript ${SERVER_USER}@${SERVER_IP}:/tmp/deploy.sh
ssh -p $SERVER_PORT -i $SSH_KEY ${SERVER_USER}@${SERVER_IP} "chmod +x /tmp/deploy.sh && bash /tmp/deploy.sh"

if ($LASTEXITCODE -ne 0) {
    Write-Host "Remote deployment failed!" -ForegroundColor Red
    exit 1
}
Write-Host "Remote deployment executed successfully" -ForegroundColor Green
Write-Host ""

# Step 6: Verify Service Startup
Write-Host "[Step 6/8] Verifying service startup status..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

$checkContainerCmd = "docker ps --filter name=${CONTAINER_NAME} --format '{{.Status}}'"
$containerStatus = ssh -p $SERVER_PORT -i $SSH_KEY ${SERVER_USER}@${SERVER_IP} $checkContainerCmd

if ($containerStatus -match "Up") {
    Write-Host "Container running normally: $containerStatus" -ForegroundColor Green
} else {
    Write-Host "Container may not have started properly, status: $containerStatus" -ForegroundColor Yellow
}

# Check service health
Write-Host "Waiting for service to start (10 seconds)..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

$healthCheckCmd = "curl -s -o /dev/null -w '%{http_code}' http://localhost:${PORT} || echo '000'"
$healthStatus = ssh -p $SERVER_PORT -i $SSH_KEY ${SERVER_USER}@${SERVER_IP} $healthCheckCmd

if ($healthStatus -match "200" -or $healthStatus -match "302" -or $healthStatus -match "404") {
    Write-Host "Service health check passed (HTTP $healthStatus)" -ForegroundColor Green
} else {
    Write-Host "Service health check returned: HTTP $healthStatus" -ForegroundColor Yellow
}
Write-Host ""

# Step 7: Output Access URLs
Write-Host "[Step 7/8] Deployment Summary" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "App Name: $APP_NAME" -ForegroundColor White
Write-Host "Version: $APP_VERSION" -ForegroundColor White
Write-Host "Container Name: $CONTAINER_NAME" -ForegroundColor White
Write-Host "Image Name: $IMAGE_NAME" -ForegroundColor White
Write-Host "Server Port: $PORT" -ForegroundColor White
Write-Host "----------------------------------------" -ForegroundColor Cyan
Write-Host "Access URLs:" -ForegroundColor Green
Write-Host "  - External: http://${SERVER_IP}:${PORT}" -ForegroundColor Green
Write-Host "  - Internal: http://localhost:${PORT}" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 8: View Container Logs
Write-Host "[Step 8/8] Viewing container logs (last 20 lines)..." -ForegroundColor Yellow
$logsCmd = "docker logs --tail 20 ${CONTAINER_NAME}"
ssh -p $SERVER_PORT -i $SSH_KEY ${SERVER_USER}@${SERVER_IP} $logsCmd

Write-Host ""
Write-Host "Deployment completed!" -ForegroundColor Green
