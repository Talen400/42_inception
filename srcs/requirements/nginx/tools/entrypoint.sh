#!/bin/sh

# Use from .env DOMAIN_NAME in openssl.conf.template

envsubst '$DOMAIN_NAME' < /etc/nginx/ssl/openssl.conf.template > /etc/nginx/ssl/openssl.conf

# Generate the certificate SSL using configuration from openssl.conf
openssl req -config /etc/nginx/ssl/openssl.conf \
	-new -x509 -sha256 -newkey rsa:2048 -nodes -batch \
    -keyout /etc/nginx/ssl/nginx-selfsigned.key \
	-days 365 -out /etc/nginx/ssl/nginx-selfsigned.crt

# Use from .env DOMAIN_NAME in ngnix.conf.template
envsubst '$DOMAIN_NAME $WP_PORT $ADMINER_PORT $STATIC_PORT $PORTAINER_PORT' < /etc/nginx/http.d/default.conf.template > /etc/nginx/http.d/default.conf

exec "$@"
