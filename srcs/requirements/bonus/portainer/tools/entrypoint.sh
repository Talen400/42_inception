#!/bin/sh
set -e

PORTAINER_USER=$(cat /run/secrets/portainer_user)
PORTAINER_PASSWORD=$(cat /run/secrets/portainer_password)

[ -z "$PORTAINER_USER" ]	 && echo "Error: portainer_user empty" && exit 1
[ -z "$PORTAINER_PASSWORD" ] && echo "Error: portainer_password empty" && exit 1

# initial portainer

/usr/local/bin/portainer \
	--no-analytics \
	-H unix:///var/run/docker.sock \
	--bind :${PORTAINER_PORT:-9000} \
	--base-url "/portainer/" &
PORTAINER_PID=$!

echo "Waiting for Portainer API..."
until wget -qO- "http://localhost:${PORTAINER_PORT:-9000}/api/status" > /dev/null 2>&1; do
	sleep 1
done

# Generate json with jq

JSON_PAYLOAD=$(jq -n --arg user "$PORTAINER_USER" --arg pass "$PORTAINER_PASSWORD" \
	'{Username: $user, Password: $pass}')

# Create admin

if wget -qO- --post-data "$JSON_PAYLOAD" \
	--header "Content-Type: application/json" \
	"http://localhost:${PORTAINER_PORT:-9000}/api/users/admin/init" > /dev/null 2>&1; then
	echo "Portainer admin created."
else
	echo "Portainer admin already initialized (or init failed)."
fi

wait $PORTAINER_PID
