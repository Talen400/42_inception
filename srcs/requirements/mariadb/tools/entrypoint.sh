#!/bin/sh

DB_NAME=$(cat /run/secrets/db_name)
DB_USER=$(cat /run/secrets/db_user)
DB_PASSWORD=$(cat /run/secrets/db_password)
DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)

if [ -z "$DB_NAME" ]; then
	echo "Error: secret db_name is empty"
	exit 1
fi

if [ -z "$DB_USER" ]; then
	echo "Error: secret db_user is empty"
	exit 1
fi

if [ -z "$DB_PASSWORD" ]; then
	echo "Error: secret db_password is empty"
	exit 1
fi

if [ -z "$DB_ROOT_PASSWORD" ]; then
	echo "Error: secret db_root_password is empty"
	exit 1
fi

DB_DIR=/var/lib/mysql

envsubst '$DB_PORT' < /etc/mariadb.template > /etc/my.cnf.d/mariadb-server.cnf


if [ ! -d "$DB_DIR/mysql" ]; then

	echo "Initializing MariaDB..."
	mariadb-install-db \
		--user=mysql \
		--datadir="$DB_DIR" \
		--basedir=/usr \
		--skip-test-db \
		--auth-root-authentication-method=normal

	echo "Temp mariadb generate..."
	mariadbd \
		--user=mysql \
		--datadir="$DB_DIR" \
		--basedir=/usr \
		--skip-networking &

	MARIADB_PID=$!

	echo "wating to ready..."
	for i in $(seq 30 -1 0); do
		if mariadb -u root --socket=/run/mysqld/mysqld.sock -e "SELECT 1" > /dev/null 2>&1; then
			break
		else
			echo "Connection failed (exit code $?)"
		fi
		if [ "$i" = 0 ]; then
			echo "Error: MariaDB init timeout"
			exit 1
		fi
		sleep 1
	done

	mariadb -u root --socket=/run/mysqld/mysqld.sock << SQL
	DELETE FROM mysql.user WHERE User NOT IN ('root', 'mysql') OR Host NOT in ('localhost');
	SET PASSWORD FOR 'root'@'localhost' = PASSWORD('$DB_ROOT_PASSWORD');
	CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`;
	CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
	GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'%';
	FLUSH PRIVILEGES;
SQL

	kill $MARIADB_PID
	wait $MARIADB_PID
	echo "MariaDB initialized."
else
	echo "MariaDB already initialized."
fi

echo "Starting mariadb..."
exec mariadbd --user=mysql --datadir="$DB_DIR" --console
