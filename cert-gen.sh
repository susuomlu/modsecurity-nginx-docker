#!/bin/bash

set -e

CERT_DIR="modsec-data/certs"
CERT_FILE="$CERT_DIR/server.crt"
KEY_FILE="$CERT_DIR/server.key"

mkdir -p "$CERT_DIR"

# Check if both files exist
if [[ -f "$CERT_FILE" && -f "$KEY_FILE" ]]; then
  echo "[*] Certificate and key already exist. Checking validity..."

  # Check if cert is still valid (expiry at least 1 day from now)
  if openssl x509 -checkend 86400 -noout -in "$CERT_FILE" > /dev/null; then
    echo "[✔] Certificate is still valid. Skipping generation."
    exit 0
  else
    echo "[!] Certificate has expired or will expire within 24h. Regenerating..."
  fi
else
  echo "[*] Certificate or key missing. Generating..."
fi

# Generate new self-signed cert
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout "$KEY_FILE" \
  -out "$CERT_FILE" \
  -subj "/CN=localhost"

echo "[✔] Certificate generated at: $CERT_DIR/"

