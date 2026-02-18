#!/bin/sh
set -e

CERT_DIR="/etc/nginx/ssl"
CERT_FILE="${CERT_DIR}/nginx.crt"
KEY_FILE="${CERT_DIR}/nginx.key"

# Create SSL directory
mkdir -p "${CERT_DIR}"

# Generate self-signed certificate
if [ ! -f "${CERT_FILE}" ] || [ ! -f "${KEY_FILE}" ]; then
	echo "Generating self-signed certificate..."
	openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
		-keyout "${KEY_FILE}" \
		-out "${CERT_FILE}" \
		-subj "/C=US/ST=State/L=City/O=Organization/OU=Department/CN=hello-world-demo" \
		-addext "subjectAltName=DNS:localhost,DNS:*.elb.amazonaws.com,IP:127.0.0.1" 2>/dev/null ||
		openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
			-keyout "${KEY_FILE}" \
			-out "${CERT_FILE}" \
			-subj "/C=US/ST=State/L=City/O=Organization/OU=Department/CN=hello-world-demo"
	echo "Certificate generated successfully."
fi

# Set proper permissions
chmod 644 "${CERT_FILE}" 2>/dev/null || true
chmod 600 "${KEY_FILE}" 2>/dev/null || true

echo "Starting nginx..."
exec nginx -g "daemon off;" -c /etc/nginx/nginx.conf
