# SpringBoot Docker Deployment Summary

## Deployment Information

| Item | Value |
|------|-------|
| **App Name** | market-app |
| **Version** | 1.0.0 |
| **Container Name** | market-app |
| **Image Name** | market-app:latest |
| **Server Port** | 10013 |
| **JVM Options** | -Xms256m -Xmx512m |

## Server Configuration

| Item | Value |
|------|-------|
| **Server IP** | 49.235.161.106 |
| **SSH Port** | 22 |
| **Username** | root |
| **Remote Directory** | /opt/apps/memo-app |

## Access URLs

- **External Access**: http://49.235.161.106:10013
- **Internal Access**: http://localhost:10013

## Deployment Status

| Step | Status |
|------|--------|
| Maven Build | Success |
| Dockerfile Check | Exists |
| Environment Check | Docker Installed |
| File Upload | Success (kimi.jar + Dockerfile) |
| Docker Image Build | Success |
| Container Start | Success |
| Health Check | HTTP 302 (OK - Redirect to login) |

## Container Status

```
CONTAINER ID   IMAGE               STATUS          PORTS
c07d886a4e54   market-app:latest   Up 36 seconds   0.0.0.0:10013->10013/tcp
```

## Files Created

1. **Dockerfile** - Docker image configuration
2. **deploy.ps1** - Automated deployment script
3. **target/kimi.jar** - Application JAR file

## Deployment Script Usage

Run the following command to deploy:

```powershell
.\deploy.ps1
```

## What the Script Does

1. Builds the project with Maven
2. Checks Dockerfile exists
3. Connects to server and checks Docker installation
4. Uploads kimi.jar and Dockerfile to server
5. Checks if port 10013 is in use and stops existing containers
6. Removes old Docker image and container
7. Builds new Docker image
8. Runs new container with port mapping 10013:10013
9. Verifies container is running
10. Performs health check
11. Displays access URLs and container logs

## Notes

- The application uses port 10013 inside the container
- Data directory is mounted at `/app/data`
- Container auto-restarts unless stopped
- JVM heap settings: 256MB min, 512MB max
