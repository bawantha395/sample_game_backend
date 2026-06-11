#!/bin/bash
# wait-for-mysql.sh - wait for MySQL to be ready
# Reads MYSQL_HOST and MYSQL_PORT from environment variables
# Falls back to "mysql" and "3306" for Docker Compose compatibility

set -e

# Use environment variables, with defaults for Docker Compose
host="${MYSQL_HOST:-mysql}"
port="${MYSQL_PORT:-3306}"

# Get the command to run (everything after script name)
cmd="$@"

echo "Waiting for MySQL at $host:$port to be ready..."

# Wait for MySQL to be ready
until nc -z "$host" "$port"; do
  echo "MySQL is not ready yet - sleeping"
  sleep 2
done

echo "MySQL is up - executing command"
exec $cmd 