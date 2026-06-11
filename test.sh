#!/bin/bash

NAME=tlavared
DOMAIN="${DOMAIN_NAME:-${NAME}.42.fr}"
PASS=0
FAIL=0

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

ok()   { echo -e "${GREEN}[PASS]${NC} $1"; PASS=$((PASS+1)); }
fail() { echo -e "${RED}[FAIL]${NC} $1"; FAIL=$((FAIL+1)); }
info() { echo -e "${YELLOW}[INFO]${NC} $1"; }

# 1. Containers running (Mandatory + Bonus)
info "Checking if all containers are running..."
for name in nginx mariadb wordpress redis ftp adminer; do
	status=$(docker inspect --format='{{.State.Running}}' "$name" 2>/dev/null)
	if [ "$status" = "true" ]; then
		ok "Container '$name' is running"
	else
		fail "Container '$name' is NOT running"
	fi
done

# 2. Restart policy (Mandatory + Bonus)
info "Checking restart policy..."
for name in nginx mariadb wordpress redis ftp adminer; do
	policy=$(docker inspect --format='{{.HostConfig.RestartPolicy.Name}}' "$name" 2>/dev/null)
	if [ "$policy" = "unless-stopped" ] || [ "$policy" = "always" ]; then
		ok "Container '$name' restart policy: $policy"
	else
		fail "Container '$name' restart policy is '$policy' (expected unless-stopped or always)"
	fi
done

# 3. HTTPS response
info "Checking HTTPS..."
http_code=$(curl -sk -o /dev/null -w "%{http_code}" "https://$DOMAIN")
if [ "$http_code" = "200" ] || [ "$http_code" = "301" ] || [ "$http_code" = "302" ]; then
	ok "HTTPS responds with HTTP $http_code"
else
	fail "HTTPS returned HTTP $http_code (expected 200/301/302)"
fi

# 4. TLS version
info "Checking TLS versions..."
curl -sk --tls-max 1.1 "https://$DOMAIN" > /dev/null 2>&1
if [ $? -ne 0 ]; then
	ok "TLS 1.1 correctly rejected"
else
	fail "TLS 1.1 was NOT rejected"
fi
 
tls_version=$(curl -vsk "https://$DOMAIN" 2>&1 | grep -oE 'TLSv[0-9.]+' | head -1)
if [ "$tls_version" = "TLSv1.2" ] || [ "$tls_version" = "TLSv1.3" ]; then
	ok "Connection uses $tls_version"
else
	fail "Could not confirm TLS 1.2/1.3 (got: $tls_version)"
fi

# 5. Check port exposure (Nginx and FTP are exceptions)
info "Checking ports exposure..."
CONTAINERS=$(docker compose -f ./srcs/docker-compose.yml ps -q)

for id in $CONTAINERS; do
	name=$(docker inspect "$id" --format='{{.Name}}' | sed 's/\///')

	# Nginx e FTP precisam expor portas para o host funcionar externa/internamente
	if [ "$name" == "nginx" ] || [ "$name" == "ftp" ]; then
		info "Skip $name (allowed to expose ports)."
		continue
	fi

	bindings=$(docker inspect "$id" --format='{{json .HostConfig.PortBindings}}')

	if [ "$bindings" != "{}" ] && [ "$bindings" != "null" ]; then
		fail "The container $name is exposing ports to the host! (Check your docker-compose)"
	else
		ok "$name is isolated inside the network"
	fi
done

# 6. Wordpress users
info "Checking Wordpress users..."
user_count=$(docker exec wordpress wp user list --allow-root --format=count 2>/dev/null)
if [ "$user_count" -ge 2 ] 2>/dev/null; then
	ok "WordPress has $user_count users (minimum 2 required)"
else
	fail "WordPress has $user_count user(s) — needs at least 2"
fi

admin_user=$(docker exec wordpress wp user list --allow-root --role=administrator --field=user_login 2>/dev/null)
if echo "$admin_user" | grep -qi "^admin$"; then
	fail "Admin username is 'admin' — subject forbids this"
else
	ok "Admin username is '$admin_user' (not 'admin')"
fi

# 7. Secrets not in environment
info "Checking secrets not exposed as env vars"
for secret in DB_PASSWORD MYSQL_PASSWORD WORDPRESS_DB_PASSWORD REDIS_PASSWORD FTP_PASSWORD; do
	for container in mariadb wordpress nginx redis ftp adminer; do
		value=$(docker exec "$container" sh -c "echo \${$secret}" 2>/dev/null)
		if [ -n "$value" ]; then
			fail "Secret '$secret' found as env var in '$container'"
		fi
	done
done
ok "No sensitive passwords found as environment variables"

# 8. No passwords in Dockerfiles 
info "Checking Dockerfiles for hardcoded secrets..."
found=0
for df in srcs/requirements/*/Dockerfile srcs/requirements/*/*/Dockerfile; do
	[ -f "$df" ] || continue
	if grep -iE "(password|passwd|secret)\s*=" "$df" > /dev/null 2>&1; then
		fail "Possible hardcoded secret in $df"
		found=1
	fi
done
[ "$found" -eq 0 ] && ok "No hardcoded secrets found in Dockerfiles"

# 9. .env and secrets not in git
info "Checking .gitignore..."
for entry in "secrets/"; do
	if git check-ignore -q "$entry" 2>/dev/null || grep -q "$entry" .gitignore 2>/dev/null; then
		ok "'$entry' is in .gitignore"
	else
		fail "'$entry' is NOT in .gitignore — risk of committing secrets"
	fi
done

# ==============================================================================
# BONUS FUNCTIONAL CHECKS
# ==============================================================================
info "Running specific Bonus validations..."

# B1. Redis Object Cache connection check
redis_status=$(docker exec wordpress wp redis status --allow-root 2>/dev/null | grep -i "Status:")
if echo "$redis_status" | grep -qi "Connected"; then
	ok "Redis Cache: WordPress is successfully connected to Redis!"
else
	fail "Redis Cache: WordPress is NOT connected to Redis (Got: $redis_status)"
fi

# B2. Adminer web accessibility check
adminer_code=$(curl -sk -o /dev/null -w "%{http_code}" "https://$DOMAIN/adminer/")
if [ "$adminer_code" = "200" ]; then
	ok "Adminer: Web panel is reachable through Nginx (HTTP 200)"
else
	fail "Adminer: Web panel returned HTTP $adminer_code (expected 200)"
fi

# B3. FTP port availability check
if [ -x "$(command -v nc)" ]; then
	nc -z -w3 localhost 21 > /dev/null 2>&1
	if [ $? -eq 0 ]; then
		ok "FTP: Port 21 is open and responding on localhost"
	else
		fail "FTP: Port 21 is NOT responding on localhost"
	fi
else
	info "FTP: 'nc' command not found, skipping port scan (Container status checked in step 1)"
fi

# B4. Acess portainer

portainer_code=$(curl -skL -o /dev/null -w "%{http_code}" "https://$DOMAIN/portainer/")
if [ "$portainer_code" = "200" ] || [ "$portainer_code" = "302" ]; then
    ok "Portainer: Web panel reachable (HTTP $portainer_code)"
else
    fail "Portainer: returned HTTP $portainer_code"
fi

# B5. static

static_code=$(curl -skL -o /dev/null -w "%{http_code}" "https://$DOMAIN/static/")
if [ "$static_code" = "200" ] || [ "$portainer_code" = "302" ]; then
    ok "Static site: reachable via NGINX proxy"
else
    fail "Static site: returned HTTP $static_code"
fi

# B6. Volumes

for vol in data/mariadb data/wordpress data/redis; do
    if [ -d "/home/${NAME}/$vol" ]; then
        ok "Volume /home/${NAME}/$vol exists"
    else
        fail "Volume /home/${NAME}/$vol missing"
    fi
done

echo -e "\nFinal Results: ${GREEN}$PASS passed${NC} / ${RED}$FAIL failed${NC}"
[ $FAIL -eq 0 ] && exit 0 || exit 1
