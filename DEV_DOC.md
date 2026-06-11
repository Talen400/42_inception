# DEV_DOC — Developer Documentation

## Prerequisites

- Debian 12 VM (recommended, or any Linux with Docker support)
- Docker Engine 24+
- Docker Compose v2
- `make`
- `git`

### Install Docker on Debian
```sh
sudo apt update
sudo apt install -y ca-certificates curl gnupg
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo usermod -aG docker $USER
```

---

## Environment Setup

### 1. Clone the repository
```sh
git clone <repo_url>
cd inception
```

### 2. Configure the `.env` file
Located at `srcs/.env`. Edit to match your setup:

```env
USER_NAME=tlavared
WEB_PORT=443
WP_PORT=9000
DB_PORT=3306
REDIS_PORT=6379
DOMAIN_NAME=${USER_NAME}.42.fr
FTP_HOST=${DOMAIN_NAME}
ADMINER_PORT=8080
STATIC_PORT=8081
PORTAINER_PORT=9000
VOLUME_WORDPRESS=/home/${USER_NAME}/data/wordpress
VOLUME_MARIADB=/home/${USER_NAME}/data/mariadb
VOLUME_REDIS=/home/${USER_NAME}/data/redis
VOLUME_PORTAINER=/home/${USER_NAME}/data/portainer
DOCKER_COMPOSE_FILE=./srcs/docker-compose.yml
```

### 3. Create secrets
```sh
mkdir -p secrets
echo -n "wordpress"       > secrets/db_name
echo -n "wpuser"          > secrets/db_user
echo -n "wppassword"      > secrets/db_password
echo -n "rootpassword"    > secrets/db_root_password
echo -n "admin"           > secrets/wp_admin_user
echo -n "adminpass"       > secrets/wp_admin_pass
echo -n "editor"          > secrets/wp_user
echo -n "editorpass"      > secrets/wp_user_pass
echo -n "redispass"       > secrets/redis_password
echo -n "ftpuser"         > secrets/ftp_user
echo -n "ftppass"         > secrets/ftp_password
echo -n "portainer"       > secrets/portainer_user
echo -n "portainerpass"   > secrets/portainer_password
```
> ⚠️ Use strong passwords in production. The `secrets/` directory is gitignored.

### 4. Configure DNS resolution
```sh
echo "127.0.0.1 tlavared.42.fr" | sudo tee -a /etc/hosts
```

---

## Building and Launching

### Full build and start
```sh
make
```

### Build only (no cache)
```sh
make build
```

### Start already-built containers
```sh
make up
```

---

## Project Structure

```
inception/
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
├── test.sh
├── secrets/                    ← gitignored, credentials
└── srcs/
    ├── .env
    ├── docker-compose.yml
    └── requirements/
        ├── nginx/
        │   ├── Dockerfile
        │   ├── conf/
        │   │   ├── nginx.conf          ← template, envsubst on boot
        │   │   └── openssl.conf        ← TLS cert generation config
        │   └── tools/entrypoint.sh
        ├── wordpress/
        │   ├── Dockerfile
        │   ├── conf/www.conf           ← php-fpm pool config
        │   └── tools/entrypoint.sh     ← wp-cli install + redis setup
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── conf/mariadb.conf       ← template, envsubst on boot
        │   └── tools/entrypoint.sh     ← temp server init pattern
        └── bonus/
            ├── redis/
            ├── ftp/
            ├── adminer/
            ├── static/
            └── portainer/
```

---

## Container Management

### View running containers
```sh
docker ps
```

### Follow all logs
```sh
make logs
```

### Follow logs for one service
```sh
docker logs -f <container_name>
```

### Execute a command inside a container
```sh
docker exec -it <container_name> sh
```

### Restart a single service
```sh
docker compose -f ./srcs/docker-compose.yml restart <service_name>
```

### Rebuild a single service
```sh
docker compose -f ./srcs/docker-compose.yml build --no-cache <service_name>
docker compose -f ./srcs/docker-compose.yml up -d <service_name>
```

---

## Data Persistence

All persistent data is stored on the host at:

| Service | Host path |
|---|---|
| WordPress files | `/home/tlavared/data/wordpress` |
| MariaDB data | `/home/tlavared/data/mariadb` |
| Redis data | `/home/tlavared/data/redis` |
| Portainer data | `/home/tlavared/data/portainer` |

These paths are mounted via named Docker volumes using the local driver with bind mount options, satisfying both the subject requirement (data in /home/tlavared/data/) and making volumes visible via docker volume ls.

### Check volume contents
```sh
docker volume ls
```
or

```sh
ls /home/tlavared/data/mariadb
ls /home/tlavared/data/wordpress
...
```

### Backup MariaDB
```sh
docker exec mariadb mariadb-dump \
  -u root -p"$(cat secrets/db_root_password)" \
  "$(cat secrets/db_name)" > backup.sql
```

### Restore MariaDB
```sh
docker exec -i mariadb mariadb \
  -u root -p"$(cat secrets/db_root_password)" \
  "$(cat secrets/db_name)" < backup.sql
```

---

## Initialization Flow

### MariaDB
1. `mariadb-install-db` creates system tables
2. Temporary server starts with `--skip-networking`
3. SQL runs to create database, user, set root password
4. Temporary server is killed
5. `exec mariadbd` starts the real server as PID 1

### WordPress
1. Waits for MariaDB to accept connections
2. Waits for Redis to respond to ping
3. `wp core download` + `wp config create` + `wp core install`
4. Creates second user, installs and enables Redis cache plugin
5. `exec php-fpm82` starts as PID 1

### NGINX
1. `envsubst` substitutes `$DOMAIN_NAME` and `$WP_PORT` in nginx.conf
2. `openssl req` generates self-signed TLS certificate
3. `exec nginx` starts as PID 1

---

## Common Issues

| Problem | Cause | Fix |
|---|---|---|
| `address already in use :21` | vsftpd running natively | `sudo systemctl stop vsftpd && sudo systemctl disable vsftpd` |
| `Could not resolve host: domain.42.fr` | Missing /etc/hosts entry | `echo "127.0.0.1 domain.42.fr" \| sudo tee -a /etc/hosts` |
| WordPress redirects to old domain | DB has old URL | `docker exec wordpress wp option update siteurl/home "https://new.42.fr" --allow-root` |
| MariaDB init timeout | Slow first start | Increase `RETRIES` in wordpress entrypoint |
| Permission denied on volume mkdir | Previous sudo rm left root-owned dir | Use `sudo mkdir -p` in Makefile volumes target |
