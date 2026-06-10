FROM alpine:3.22.4

RUN apk update \
	&& apk add --no-cache \
	curl \
	jq \
	tini

RUN curl -Lo /tmp/portainer.tar.gz \
	https://github.com/portainer/portainer/releases/download/2.21.0/portainer-2.21.0-linux-amd64.tar.gz \
	&& tar -xzf /tmp/portainer.tar.gz -C /usr/local/bin --strip-components=1 \
	&& rm /tmp/portainer.tar.gz

EXPOSE 9443

COPY ./tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/entrypoint.sh"]
