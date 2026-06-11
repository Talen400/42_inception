#!/bin/sh
set -e

DB_NAME=$(cat /run/secrets/db_name)
DB_USER=$(cat /run/secrets/db_user)
DB_PASS=$(cat /run/secrets/db_password)
DB_HOST_NAME="mariadb"
DB_HOST="${DB_HOST_NAME}:${DB_PORT}"

[ -z "$DB_NAME" ]	&& echo "Error: secret db_name is empty" && exit 1
[ -z "$DB_USER" ]	&& echo "Error: secret db_user is empty" && exit 1
[ -z "$DB_PASS" ]	&& echo "Error: secret db_pass is empty" && exit 1

WP_ADMIN_USER=$(cat /run/secrets/wp_admin_user)
WP_ADMIN_PASS=$(cat /run/secrets/wp_admin_pass)
WP_USER=$(cat /run/secrets/wp_user)
WP_USER_PASS=$(cat /run/secrets/wp_user_pass)

REDIS_PASSWORD=$(cat /run/secrets/redis_password)

[ -z "$WP_ADMIN_USER" ]	&& echo "Error: secret wp_admin_user is empty" && exit 1
[ -z "$WP_ADMIN_PASS" ]	&& echo "Error: secret wp_admin_pass is empty" && exit 1
[ -z "$WP_USER" ]	&& echo "Error: secret wp_user is empty" && exit 1
[ -z "$WP_USER_PASS" ]	&& echo "Error: secret wp_user_pass is empty" && exit 1
[ -z "$REDIS_PASSWORD" ]	&& echo "Error: secret redis_password is empty" && exit 1

WP_URL="https://${DOMAIN_NAME}"
WP_TITLE=${WP_TITLE-"Inception"}
WP_PORT=${WP_PORT-"9000"}

echo "URL: ${WP_URL}"
echo "TITLE: ${WP_TITLE}"

envsubst '$WP_PORT' < /etc/php82/php-fpm.d/www.conf.template > /etc/php82/php-fpm.d/www.conf

echo "Waiting mariadb ($DB_HOST)..."
RETRIES=30

until mariadb -h "$DB_HOST_NAME" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" -e "SELECT 1";do #> /dev/null 2>&1; do
	echo "Trying: ${RETRIES}"
	RETRIES=$((RETRIES-1))
	if [ $RETRIES -le 0 ]; then
		echo "Erro: Maria not working"
		exit 1
	fi
	sleep 2
done

echo "Waiting for Redis ($REDIS_PORT)..."
RETRIES=30

until redis-cli -h redis -p "${REDIS_PORT}" -a "${REDIS_PASSWORD}" ping > /dev/null 2>&1; do
    RETRIES=$((RETRIES-1))
    [ $RETRIES -le 0 ] && echo "Error: Redis not ready" && exit 1
    sleep 1
done

echo "MariaDB is already"

# configuration of wp-config.php

if [ ! -f wp-config.php ]; then
	echo "Download WordPress..."
	wp core download --allow-root

	echo "Creating wp-config.php..."
	wp config create \
		--dbname="$DB_NAME" \
		--dbuser="$DB_USER" \
		--dbpass="$DB_PASS" \
		--dbhost="$DB_HOST" \
		--allow-root

	echo "Install WordPress..."
	wp core install \
		--url="$WP_URL" \
		--title="$WP_TITLE" \
		--admin_user="$WP_ADMIN_USER" \
		--admin_password="$WP_ADMIN_PASS" \
		--skip-email \
		--admin_email="${WP_ADMIN_USER}@42.fr" \
		--allow-root

	echo "Creating a second user..."
	wp user create \
		"${WP_USER}" \
		"${WP_USER}@42.fr" \
		--allow-root \
		--user_pass="${WP_USER_PASS}" \
		--role=author
	
	# check permissions
	chown -R nobody:nobody /var/www/html
	find /var/www/html -type d -exec chmod 755 {} \;
	find /var/www/html -type f -exec chmod 644 {} \;
	mkdir -p /var/www/html/wp-content/uploads
	chmod -R 775 /var/www/html/wp-content/uploads

	echo "Configuration Redis cache..."
	wp plugin install redis-cache --activate --allow-root
	wp config set WP_REDIS_HOST redis --allow-root
	wp config set WP_REDIS_PORT "${REDIS_PORT}" --allow-root
	wp config set WP_REDIS_PASSWORD "${REDIS_PASSWORD}" --allow-root
	wp config set WP_CACHE true --raw --allow-root
	wp redis enable --allow-root

	echo "WordPress installed"

else
	echo "WordPress already, update permissions"

	echo "Volumes..."
	chown -R nobody:nobody /var/www/html
	mkdir -p /var/www/html/wp-content/uploads
	chmod -R 775 /var/www/html/wp-content/uploads

	echo "wp-config..."
	wp config set DB_NAME "$DB_NAME" --allow-root
	wp config set DB_USER "$DB_USER" --allow-root
	wp config set DB_PASSWORD "$DB_PASS" --allow-root
	wp config set DB_HOST "$DB_HOST" --allow-root

	echo "wp-option Domain..."
	wp option update siteurl "https://${DOMAIN_NAME}" --allow-root
	wp option update home "https://${DOMAIN_NAME}" --allow-root

	echo "redis..."
	wp config set WP_REDIS_HOST redis --allow-root
	wp config set WP_REDIS_PORT "${REDIS_PORT}" --allow-root
	wp config set WP_REDIS_PASSWORD "${REDIS_PASSWORD}" --allow-root
	wp config set WP_CACHE true --raw --allow-root
	wp redis enable --allow-root

	echo "Permissions updated"
fi

echo "Wordpress service initialization sucessfully"
exec "$@"
