FROM alpine:3.22.4

RUN apk update \
	&& apk add --no-cache \
	vsftpd \
	tini \
	gettext-envsubst

COPY ./conf/vsftpd.conf /etc/vsftpd/vsftpd.conf.template
COPY ./tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 21 21000-21010

ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/entrypoint.sh"]
CMD ["vsftpd", "/etc/vsftpd/vsftpd.conf"]
