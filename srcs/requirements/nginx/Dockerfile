FROM alpine:3.22.4

# Install Ngnic, OpenSSL and gettext (envsubst) and tini
RUN apk update \
	&& apk add --no-cache \
	nginx \
	openssl \
	tini \
	gettext-envsubst

RUN mkdir -p /etc/nginx/ssl

# Copy the config to http.d
COPY ./conf/nginx.conf /etc/nginx/http.d/default.conf.template

# Copy how the template of configuration
COPY ./conf/openssl.conf /etc/nginx/ssl/openssl.conf.template

# COpy the script of entrypoint.sh and to permission of execution
COPY ./tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 443

ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
