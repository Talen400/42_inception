*This project has been created as part of the 42 curriculum by tlavared.*

# Inception

## Description

Inception is a system administration project from the 42 curriculum. The goal is to build a small infrastructure composed of multiple services using **Docker** and **Docker Compose**, running inside a virtual machine.

The stack includes:
- **NGINX** — sole entry point, TLS only (TLSv1.2/1.3).
- **WordPress** + php-fpm — CMS served behind NGINX
- **MariaDB** — relational database for WordPress
- **Redis** *(bonus)* — object cache for WordPress
- **vsftpd** *(bonus)* — FTP server mapped to the WordPress volume
- **Adminer** *(bonus)* — web-based database management interface
- **Static site** *(bonus)* — personal portfolio served via NGINX
- **Portainer** *(bonus)* — Docker management UI

All services run in dedicated Alpine-based containers, built from scratch — no pre-built application images.

---

### Design Choices

#### Virtual Machines vs Docker

| Virtual Machines | Docker |
|---|---|
| Full OS per VM, heavy resource usage | Shares host kernel, lightweight |
| Strong isolation (separate kernel) | Process-level isolation via namespaces/cgroups |
| Slower startup (minutes) | Fast startup (seconds) |
| Ideal for strong security boundaries | Ideal for reproducible, portable services |

In this project, Docker runs **inside** a VM — combining the security of VM isolation with the reproducibility of containers.

#### Secrets vs Environment Variables

| Environment Variables | Docker Secrets |
|---|---|
| Visible to all processes in the container | Stored as files in `/run/secrets/`, access-controlled |
| Exposed via `docker inspect` | Not exposed in inspect output |
| Risk of accidental logging | Safer for sensitive data |

This project uses Docker Secrets for all credentials (passwords, usernames) and environment variables only for non-sensitive configuration (ports, domain name).

#### Docker Network vs Host Network

| Docker Network | Host Network |
|---|---|
| Containers communicate via internal DNS | Containers share the host's network stack |
| Isolated from host by default | No network isolation |
| Services addressable by container name | Services addressable by localhost |

This project uses a single bridge network (`inception_network`). Only NGINX (443) and vsftpd (21, 21000-21010) expose ports to the host. All other services communicate internally by container name.

#### Docker Volumes vs Bind Mounts

| Docker Volumes | Bind Mounts |
|---|---|
| Managed by Docker, stored in Docker's area | Directly maps a host path to a container path |
| Portable, easier to backup | Explicit host path control |
| Less transparent | Required by subject: data in `/home/login/data/` |

This project uses bind mounts to satisfy the subject requirement that data persists in `/home/tlavared/data/` on the host machine.

---

## Instructions

### Prerequisites

- Docker and Docker Compose installed
- A Debian-based VM (recommended: Debian 12)
- `make` installed

### Setup

1. Clone the repository:
```sh
git clone <repo_url>
cd inception
```

2. Create the secrets directory and files:
```sh
mkdir -p secrets
echo -n "your_db_name"        > secrets/db_name
echo -n "your_db_user"        > secrets/db_user
echo -n "your_db_password"    > secrets/db_password
echo -n "your_root_password"  > secrets/db_root_password
echo -n "your_wp_admin"       > secrets/wp_admin_user
echo -n "your_wp_admin_pass"  > secrets/wp_admin_pass
echo -n "your_wp_user"        > secrets/wp_user
echo -n "your_wp_user_pass"   > secrets/wp_user_pass
echo -n "your_redis_pass"     > secrets/redis_password
echo -n "your_ftp_user"       > secrets/ftp_user
echo -n "your_ftp_pass"       > secrets/ftp_password
echo -n "your_portainer_user" > secrets/portainer_user
echo -n "your_portainer_pass" > secrets/portainer_password
```

3. Add the domain to `/etc/hosts`:
```sh
echo "127.0.0.1 tlavared.42.fr" | sudo tee -a /etc/hosts
```

4. Build and start:
```sh
make
```

5. Access the site at `https://tlavared.42.fr`

### Makefile targets

| Target | Description |
|---|---|
| `make` | Build images and start all containers |
| `make build` | Build all images without cache |
| `make up` | Start containers |
| `make down` | Stop containers |
| `make clean` | Stop and remove containers and volumes |
| `make fclean` | Full cleanup including images and data |
| `make re` | Full rebuild from scratch |
| `make logs` | Follow container logs |
| `make stats` | Show container resource usage |

---

## Resources

### Documentation
- [Docker official docs](https://docs.docker.com/)
- [Docker Compose reference](https://docs.docker.com/compose/)
- [MariaDB documentation](https://mariadb.com/kb/en/)
- [NGINX documentation](https://nginx.org/en/docs/)
- [WordPress WP-CLI](https://wp-cli.org/)
- [Redis documentation](https://redis.io/docs/)
- [vsftpd man page](https://linux.die.net/man/8/vsftpd)
- [Portainer documentation](https://docs.portainer.io/)

### Articles & Tutorials
- [Docker networking overview](https://docs.docker.com/network/)
- [Docker secrets](https://docs.docker.com/engine/swarm/secrets/)
- [TLS/SSL explained](https://www.cloudflare.com/learning/ssl/what-is-ssl/)
- [PHP-FPM and NGINX](https://www.nginx.com/resources/wiki/start/topics/examples/phpfcgi/)

### AI Usage

**Claude (Anthropic)** was used throughout this project as a learning and debugging assistant:

- **Architecture understanding** — explaining NGINX/php-fpm communication, Docker networking internals, TLS handshake flow
- **Debugging** — identifying shell script errors (variable spacing, wrong binary names, redirect issues), Docker build errors, MariaDB bootstrap SQL issues
- **Security concepts** — Docker secrets vs environment variables, rootless containers, supply chain attacks, TLS version enforcement
- **Code review** — reviewing entrypoint scripts, Dockerfiles, and docker-compose configuration
- **Documentation** — generating the structure and content of this README, USER_DOC, and DEV_DOC

AI was used as a pedagogical tool — explaining concepts before implementation rather than generating copy-paste solutions. All code was written and understood by the author.
