#!/bin/bash

SERVER_IP="49.235.161.106"
SERVER_USER="root"
SERVER_PORT="22"
TARGET_DIR="/opt/apps/memo-app"
APP_NAME="market-app"
APP_VERSION="1.0.0"
APP_PORT="10012"
JAR_NAME="GLM.jar"
JAVA_OPTS="-Xms256m -Xmx512m"

echo "=========================================="
echo "  SpringBoot Docker Deployment Script"
echo "=========================================="

echo ""
echo "[Step 1] Maven Build..."
mvn clean package -DskipTests
if [ $? -ne 0 ]; then
    echo "Maven build failed!"
    exit 1
fi

echo ""
echo "[Step 2] Copy JAR to GLM.jar..."
cp target/simple-shop-1.0.0.jar GLM.jar

echo ""
echo "[Step 3] Check Server Environment..."
ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP} "docker --version"

echo ""
echo "[Step 4] Create Target Directory..."
ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP} "mkdir -p ${TARGET_DIR}"

echo ""
echo "[Step 5] Upload Files to Server..."
scp -o StrictHostKeyChecking=no GLM.jar ${SERVER_USER}@${SERVER_IP}:${TARGET_DIR}/${JAR_NAME}
scp -o StrictHostKeyChecking=no Dockerfile ${SERVER_USER}@${SERVER_IP}:${TARGET_DIR}/Dockerfile
scp -o StrictHostKeyChecking=no -r data ${SERVER_USER}@${SERVER_IP}:${TARGET_DIR}/

echo ""
echo "[Step 6] Stop and Remove Existing Container..."
EXISTING_CONTAINER=$(ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP} "docker ps -a --filter 'publish=${APP_PORT}' -q")
if [ -n "$EXISTING_CONTAINER" ]; then
    echo "Stopping container on port ${APP_PORT}..."
    ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP} "docker stop \$(docker ps -a --filter 'publish=${APP_PORT}' -q) && docker rm \$(docker ps -a --filter 'publish=${APP_PORT}' -q)"
fi

ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP} "docker rm -f ${APP_NAME} 2>/dev/null || true"

echo ""
echo "[Step 7] Build Docker Image..."
ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP} "cd ${TARGET_DIR} && docker build -t ${APP_NAME}:${APP_VERSION} -t ${APP_NAME}:latest ."

echo ""
echo "[Step 8] Run Container..."
ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP} "docker run -d --name ${APP_NAME} --restart=always -p ${APP_PORT}:${APP_PORT} -e JAVA_OPTS='${JAVA_OPTS}' -v ${TARGET_DIR}/data:/app/data ${APP_NAME}:${APP_VERSION}"

echo ""
echo "[Step 9] Verify Service..."
sleep 5
ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP} "docker ps --filter name=${APP_NAME} && docker logs --tail 20 ${APP_NAME}"

echo ""
echo "[Step 10] Health Check..."
HTTP_CODE=$(ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP} "curl -s -o /dev/null -w '%{http_code}' http://localhost:${APP_PORT}/")
if [ "$HTTP_CODE" == "200" ] || [ "$HTTP_CODE" == "302" ]; then
    echo "Service is running! HTTP Code: ${HTTP_CODE}"
else
    echo "Service may have issues. HTTP Code: ${HTTP_CODE}"
fi

echo ""
echo "=========================================="
echo "  Deployment Complete!"
echo "=========================================="
echo ""
echo "Access URL: http://${SERVER_IP}:${APP_PORT}/"
echo ""
