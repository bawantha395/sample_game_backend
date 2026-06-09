#!/bin/bash
# wait-for-it.sh - wait for a service to be ready

set -e

host="$1"
shift
cmd="$@"

# Extract host and port from the host argument
if [[ $host == *":"* ]]; then
    hostname="${host%:*}"
    port="${host#*:}"
else
    hostname="$host"
    port="3306"  # default port
fi

until nc -z "$hostname" "$port"; do
  echo "Waiting for $hostname:$port to be ready..."
  sleep 1
done

echo "$hostname:$port is up - executing command"
exec $cmd