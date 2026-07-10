#!/bin/sh
# =============================================================================
# setup_secrets.sh — generates the secrets/ directory for Inception
# =============================================================================
#
# Usage:
#   ./setup_secrets.sh
#
# Creates secrets/ at the project root with default values.
# Edit the values below before running, or edit the files afterwards.
# =============================================================================

set -e

SECRETS_DIR="secrets"

if [ -d "$SECRETS_DIR" ]; then
    echo "Warning: '$SECRETS_DIR' already exists."
    printf "Overwrite existing secrets? [y/N]: "
    read answer
    case "$answer" in
        y|Y) ;;
        *) echo "Aborted."; exit 0 ;;
    esac
fi

mkdir -p "$SECRETS_DIR"

# -----------------------------------------------------------------------------
# Edit these values as needed
# -----------------------------------------------------------------------------
DB_NAME="wordpress"
DB_USER="wpuser"
DB_PASSWORD="wppassword"
DB_ROOT_PASSWORD="rootpassword"

WP_ADMIN_USER="tlavared"
WP_ADMIN_PASS="adminpass"
WP_USER="editor"
WP_USER_PASS="editorpass"

REDIS_PASSWORD="redispass"

FTP_USER="ftpuser"
FTP_PASSWORD="ftppass"

PORTAINER_USER="portainer"
PORTAINER_PASSWORD="portainerpass"

# -----------------------------------------------------------------------------
# Write secrets (no trailing newline)
# -----------------------------------------------------------------------------
write_secret() {
    printf '%s' "$2" > "$SECRETS_DIR/$1"
    echo "  created $SECRETS_DIR/$1"
}

echo "Generating secrets in '$SECRETS_DIR'..."

write_secret db_name             "$DB_NAME"
write_secret db_user             "$DB_USER"
write_secret db_password         "$DB_PASSWORD"
write_secret db_root_password    "$DB_ROOT_PASSWORD"

write_secret wp_admin_user       "$WP_ADMIN_USER"
write_secret wp_admin_pass       "$WP_ADMIN_PASS"
write_secret wp_user             "$WP_USER"
write_secret wp_user_pass        "$WP_USER_PASS"

write_secret redis_password      "$REDIS_PASSWORD"

write_secret ftp_user            "$FTP_USER"
write_secret ftp_password        "$FTP_PASSWORD"

write_secret portainer_user      "$PORTAINER_USER"
write_secret portainer_password  "$PORTAINER_PASSWORD"

chmod 777 "$SECRETS_DIR"/*

echo ""
echo "Done. 13 secret files created in '$SECRETS_DIR/' with permissions 600."
echo "Edit the values inside this script before running again, or edit the files directly."
