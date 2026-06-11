# USER_DOC — User Documentation

## Services Overview

This stack provides the following services:

| Service | Description | Access |
|---|---|---|
| **WordPress** | Personal website / CMS | `https://tlavared.42.fr` |
| **Adminer** | Database management panel | `https://tlavared.42.fr/adminer/` |
| **Portainer** | Docker management UI | `https://tlavared.42.fr/portainer/` |
| **Static Site** | Personal portfolio | `https://tlavared.42.fr/static/` |
| **FTP** | File transfer to WordPress volume | `ftp://tlavared.42.fr` (port 21) |

---

## Starting and Stopping the Project

### Start
```sh
make
```
Builds all images and starts all containers. On first run, databases and WordPress are initialized automatically.

### Stop (keep data)
```sh
make down
```
Stops all containers. Data in volumes is preserved.

### Full reset (destroys all data)
```sh
make fclean
make
```
Removes all containers, images, and data volumes. Next start will reinitialize everything from scratch.

---

## Accessing the Services

### WordPress Website
Open your browser and go to:
```
https://tlavared.42.fr
```
> The browser will show a security warning because the SSL certificate is self-signed. Click "Advanced" → "Proceed anyway".

### WordPress Admin Panel
```
https://tlavared.42.fr/wp-admin
```
Login with the credentials stored in `secrets/wp_admin_user` and `secrets/wp_admin_pass`.

### Adminer (Database)
```
https://tlavared.42.fr/adminer/
```
- **System:** MySQL
- **Server:** `mariadb`
- **Username:** value in `secrets/db_user`
- **Password:** value in `secrets/db_password`
- **Database:** value in `secrets/db_name`

### Portainer (Docker UI)
```
https://tlavared.42.fr/portainer/
```
Login with credentials from `secrets/portainer_user` and `secrets/portainer_password`.

### Static Site (Portfolio)
```
https://tlavared.42.fr/static/
```
No authentication required.

### FTP Access
```sh
ftp tlavared.42.fr
```
Login with credentials from `secrets/ftp_user` and `secrets/ftp_password`.

Or with curl:
```sh
curl -v ftp://tlavared.42.fr --user "$(cat secrets/ftp_user):$(cat secrets/ftp_password)"
```

---

## Credentials

All credentials are stored as plain text files in the `secrets/` directory at the root of the repository. This directory is excluded from git.

| File | Purpose |
|---|---|
| `secrets/db_name` | WordPress database name |
| `secrets/db_user` | WordPress database user |
| `secrets/db_password` | WordPress database password |
| `secrets/db_root_password` | MariaDB root password |
| `secrets/wp_admin_user` | WordPress admin username |
| `secrets/wp_admin_pass` | WordPress admin password |
| `secrets/wp_user` | WordPress secondary user |
| `secrets/wp_user_pass` | WordPress secondary user password |
| `secrets/redis_password` | Redis authentication password |
| `secrets/ftp_user` | FTP username |
| `secrets/ftp_password` | FTP password |
| `secrets/portainer_user` | Portainer admin username |
| `secrets/portainer_password` | Portainer admin password |

---

## Checking Service Health

### Quick status
```sh
docker ps
```
All containers should show `Up` status.

### Run the test suite
```sh
bash test.sh
```
Runs automated checks for all mandatory and bonus requirements.

### Check individual services
```sh
# WordPress
curl -sk https://tlavared.42.fr | head -5

# Redis cache
docker exec redis redis-cli -a "$(cat secrets/redis_password)" ping

# MariaDB
docker exec mariadb mariadb -u root -p"$(cat secrets/db_root_password)" -e "SHOW DATABASES;"

# Container logs
make logs
```

### Restart a specific container
```sh
docker restart <container_name>
```
