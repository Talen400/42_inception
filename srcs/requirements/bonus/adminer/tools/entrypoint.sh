#!/bin/sh
set -e

rm -f /etc/php82/php-fpm.d/www.conf

envsubst '$ADMINER_PORT' < /etc/php82/php-fpm.d/adminer.conf.template > /etc/php82/php-fpm.d/adminer.conf

chown -R nobody:nobody /var/www/adminer
echo "Adminer PHP_FPM ready"

exec "$@"
