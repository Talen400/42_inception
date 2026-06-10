FROM alpine:3.22.4

RUN apk update \
	&& apk add --no-cache \
	nginx \
	tini \
	gettext-envsubst

COPY ./www /var/www/html

COPY ./conf/default.conf /etc/nginx/http.d/default.conf.template
COPY ./tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE ${STATIC_PORT:-8081}

ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
