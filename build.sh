#!/bin/bash

echo "Building the application..."

# Check if Java is available locally
if command -v java &> /dev/null; then
    echo "Java found locally. Building with Maven wrapper..."
    ./mvnw clean package -DskipTests
    echo "Build completed successfully!"
    echo "JAR file created at: target/api.jar"
else
    echo "Java not found locally. Please use Docker to build:"
    echo "docker-compose up --build"
fi 