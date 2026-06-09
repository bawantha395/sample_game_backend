FROM eclipse-temurin:17-jdk-jammy

WORKDIR /app

# Install netcat for wait-for-it script
RUN apt-get update && apt-get install -y netcat-openbsd && rm -rf /var/lib/apt/lists/*

# Copy Maven wrapper and pom.xml first for better caching
COPY mvnw .
COPY mvnw.cmd .
COPY .mvn .mvn
COPY pom.xml .

# Copy source code
COPY src ./src

# Make mvnw executable and build the application
RUN chmod +x mvnw && \
    ./mvnw clean package -DskipTests

# Copy wait scripts
COPY wait-for-it.sh .
COPY wait-for-mysql.sh .
RUN chmod +x wait-for-it.sh wait-for-mysql.sh


# Use environment variables for MySQL host (Docker Compose uses "mysql", ECS/RDS uses actual hostname)
# wait-for-mysql.sh reads MYSQL_HOST and MYSQL_PORT from environment variables
ENTRYPOINT ["./wait-for-mysql.sh", "java", "-jar", "target/api.jar"]