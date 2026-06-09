FROM alpine:3.22.4

# Install Ngnic, OpenSSL and gettext (env)
RUN apk update \
	&& apk add --no-cache \
	mariadb \
	mariadb-client \
	tini \
	gettext-envsubst

RUN mkdir -p /var/lib/mysql \
	&& mkdir -p /etc/my.cnf.d \
	&& mkdir -p /run/mysqld \
	&& chown -R mysql:mysql /var/lib/mysql /run/mysqld

COPY ./conf/mariadb.conf /etc/mariadb.template

COPY ./tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 3306

ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/entrypoint.sh"]
CMD ["mariadb"]
