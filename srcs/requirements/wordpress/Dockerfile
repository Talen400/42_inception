FROM alpine:3.22.4

# install base libs

RUN apk update \
	&& apk add --no-cache \
	curl \
	mariadb-client \
	bash \
	redis \
	tini \
	gettext-envsubst

# install php

RUN apk update \
	&& apk add --no-cache \
	php82 \
	php82-cli \
	php82-fpm \
	php82-json \
	php82-curl \
	php82-dom \
	php82-mysqli \
	php82-fileinfo \
	php82-mbstring \
	php82-openssl \
	php82-xml \
	php82-zip \
	php82-phar \
	php82-tokenizer \
	php82-opcache \
	php82-gd \
	php82-intl \
	php82-bcmath

# creating link to WP-CLI
RUN ln -s /usr/bin/php82 /usr/bin/php

# config of PHP_FPM (www.conf)
COPY conf/www.conf /etc/php82/php-fpm.d/www.conf

# config of OPcache ( cache of operation codes from page loaders) and logs
# from docker wordpress

RUN mkdir -p /etc/php82/conf.d; \
	{ \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=2'; \
	} > /etc/php82/conf.d/opcache-recommended.ini; \
	{ \
		echo 'error_reporting = E_ERROR | E_WARNING | E_PARSE | E_CORE_ERROR | E_CORE_WARNING | E_COMPILE_ERROR | E_COMPILE_WARNING | E_RECOVERABLE_ERROR'; \
		echo 'display_errors = Off'; \
		echo 'display_startup_errors = Off'; \
		echo 'log_errors = On'; \
		echo 'error_log = /dev/stderr'; \
		echo 'log_errors_max_len = 1024'; \
		echo 'ignore_repeated_errors = On'; \
		echo 'ignore_repeated_source = Off'; \
		echo 'html_errors = Off'; \
	} > /etc/php82/conf.d/error-logging.ini; \
	{ \
		echo 'memory_limit = 512M'; \
	} > /etc/php82/conf.d/memory-limit.ini


RUN curl -o /usr/local/bin/wp \
	https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
	&& chmod +x /usr/local/bin/wp

#COPY conf/www.conf /usr/local/etc/php-fpm.d/www.conf

WORKDIR /var/www/html

COPY conf/www.conf /etc/php82/php-fpm.d/www.conf.template
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 9000

ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/entrypoint.sh"]

CMD ["php-fpm82", "--nodaemonize"]
