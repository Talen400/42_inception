FROM alpine:3.22.4

RUN apk update \
	&& apk add --no-cache \
	php82 \
	php82-fpm \
	php82-session \
	php82-mysqli \
	curl \
	tini \
	gettext-envsubst

RUN mkdir -p /var/www/adminer && \
	curl -L -o /var/www/adminer/adminer.php https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1.php


COPY ./conf/adminer.conf /etc/php82/php-fpm.d/adminer.conf.template
COPY ./tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 8080

ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/entrypoint.sh"]
CMD ["php-fpm82", "-F"]
