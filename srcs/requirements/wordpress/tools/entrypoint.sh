#!/bin/sh
set -e

DB_NAME=$(cat /run/secrets/db_name)
DB_USER=$(cat /run/secrets/db_user)
DB_PASS=$(cat /run/secrets/db_password)
DB_HOST_NAME="mariadb"
DB_HOST="${DB_HOST_NAME}:${DB_PORT}"

if [ -z "$DB_NAME" ]; then
	echo "Error: secret db_name is empty"
	exit 1
fi

if [ -z "$DB_USER" ]; then
	echo "Error: secret db_user is empty"
	exit 1
fi

if [ -z "$DB_PASS" ]; then
	echo "Error: secret db_password is empty"
	exit 1
fi

# or  WP_ADMIN_USER=$(cat /run/secrets/wp_admin_user 2>/dev/null || echo "admin")
WP_ADMIN_USER=$(cat /run/secrets/wp_admin_user)
WP_ADMIN_PASS=$(cat /run/secrets/wp_admin_pass)
WP_USER=$(cat /run/secrets/wp_user)
WP_USER_PASS=$(cat /run/secrets/wp_user_pass)

if [ -z "$WP_ADMIN_USER" ]; then
	echo "Error: secret wp_admin_user in empty"
	exit 1
fi

if [ -z "$WP_ADMIN_PASS" ]; then
	echo "Error: secret wp_admin_user in empty"
	exit 1
fi

if [ -z "$WP_USER" ]; then
	echo "Error: secret wp_admin_user in empty"
	exit 1
fi

if [ -z "$WP_USER_PASS" ]; then
	echo "Error: secret wp_admin_user in empty"
	exit 1
fi

echo

WP_URL="https://${DOMAIN_NAME}"
WP_TITLE=${WP_TITLE-"Inception"}
WP_PORT=${WP_PORT-"9000"}

echo "URL: ${WP_URL}"
echo "TITLE: ${WP_TITLE}"

envsubst '$WP_PORT' < /etc/php82/php-fpm.d/www.conf.template > /etc/php82/php-fpm.d/www.conf

echo "testing mariadb ($DB_HOST)..."
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

	echo "WordPress installed"

else
	echo "WordPress already, update permissions"

	chown -R nobody:nobody /var/www/html
	mkdir -p /var/www/html/wp-content/uploads
	chmod -R 775 /var/www/html/wp-content/uploads

	wp config set DB_NAME "$DB_NAME" --allow-root
	wp config set DB_USER "$DB_USER" --allow-root
	wp config set DB_PASSWORD "$DB_PASS" --allow-root
	wp config set DB_HOST "$DB_HOST" --allow-root
fi

echo "Wordpress service initialization sucessfully"
exec "$@"
