#!/bin/sh
set -e

export REDIS_PASSWORD=$(cat /run/secrets/redis_password)

[ -z "$REDIS_PASSWORD" ] && echo "Error: redis_password is empty" && exit 1

envsubst '$REDIS_PORT $REDIS_PASSWORD' < /etc/redis/redis.conf.template > /etc/redis/redis.conf

exec "$@"
