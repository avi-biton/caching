#!/bin/sh
set -ex

CERT_DIR="/etc/squid/certs"
SPOOL_DIR="/var/spool/squid"
SSL_DB_DIR="$SPOOL_DIR/ssl_db"
SQUID_HELPER_PATH="/usr/lib64/squid/security_file_certgen"

echo "Preparing directories..."
mkdir -p "$CERT_DIR" "$SPOOL_DIR"

# Ensure proper permissions for the spool directory
chown -R root:root "$SPOOL_DIR"
chmod -R 755 "$SPOOL_DIR"

# Only clean SSL DB if it doesn't exist or if incomplete
if [ ! -d "$SSL_DB_DIR" ] || [ ! -f "$SSL_DB_DIR/index.txt" ]; then
    echo "SSL DB not found or incomplete, initializing..."
    rm -rf "$SSL_DB_DIR"
    echo "Initializing SSL DB at $SSL_DB_DIR..."
    # Let the helper utility create the database directory itself
    "$SQUID_HELPER_PATH" -c -s "$SSL_DB_DIR" -M 4MB
else
    echo "SSL DB already initialized, skipping initialization and preserving existing certificates..."
fi
echo "SSL DB initialized."

echo "Copying certificates..."
cp /mnt/squid-secret/tls.crt "$CERT_DIR/tls.crt"
cp /mnt/squid-secret/tls.key "$CERT_DIR/tls.key"

echo "Setting final permissions..."
# Set ownership for all required directories and files
chown -R {{ .Values.securityContext.runAsUser }}:{{ .Values.securityContext.runAsGroup }} "$CERT_DIR" "$SPOOL_DIR"
# Set restrictive permissions
chmod -R 700 "$CERT_DIR" "$SPOOL_DIR"
# Set more restrictive permissions for certificate files
chmod 644 "$CERT_DIR/tls.crt"
chmod 600 "$CERT_DIR/tls.key"

echo "Initialization and permissions complete."
