#!/bin/sh

envsubst '$STATIC_PORT' < /etc/nginx/http.d/default.conf.template > /etc/nginx/http.d/default.conf

echo "Starting static ngnix..."

exec "$@"

