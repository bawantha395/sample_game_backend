@echo off
echo Building the application...

REM Check if Java is available locally
java -version >nul 2>&1
if %errorlevel% == 0 (
    echo Java found locally. Building with Maven wrapper...
    mvnw.cmd clean package -DskipTests
    echo Build completed successfully!
    echo JAR file created at: target/api.jar
) else (
    echo Java not found locally. Please use Docker to build:
    echo docker-compose up --build
) 