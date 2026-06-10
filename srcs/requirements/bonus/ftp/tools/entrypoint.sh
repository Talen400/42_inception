#!/bin/sh
set -e

FTP_USER=$(cat /run/secrets/ftp_user)
FTP_PASSWORD=$(cat /run/secrets/ftp_password)

[ -z "$FTP_USER" ]		&& echo "Error: ftp_user empty" && exit 1
[ -z "$FTP_PASSWORD" ]	&& echo "Error: ftp_password empty" && exit 1

adduser -D -h /var/www/html "$FTP_USER"
echo "$FTP_USER:$FTP_PASSWORD" | chpasswd

envsubst '$FTP_HOST $FTP_PASV_MIN_PORT $FTP_PASV_MAX_PORT' < /etc/vsftpd/vsftpd.conf.template > /etc/vsftpd/vsftpd.conf

mkdir -p /var/run/vsftpd/empty

exec "$@"
