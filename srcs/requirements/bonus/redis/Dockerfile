FROM alpine:3.22.4

RUN apk update \
	&& apk add --no-cache \
	redis tini gettext-envsubst

COPY ./conf/redis.conf /etc/redis/redis.conf.template
COPY ./tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 6379
ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/entrypoint.sh"]

CMD ["redis-server", "/etc/redis/redis.conf"]
