#!/bin/bash

set -e

CRS_DIR="./modsec-data/crs"
TMP_DIR="./tmp-crs"

echo "[+] Downloading latest CRS..."
git clone --depth 1 https://github.com/coreruleset/coreruleset "$TMP_DIR"

echo "[+] Backing up old CRS rules..."
cp -r "$CRS_DIR" "$CRS_DIR.bak.$(date +%s)"

echo "[+] Updating CRS..."
cp "$TMP_DIR/crs-setup.conf.example" "$CRS_DIR/crs-setup.conf"
rm -rf "$CRS_DIR/rules" && mkdir -p "$CRS_DIR/rules"
cp "$TMP_DIR/rules/"*.conf "$CRS_DIR/rules/"

rm -rf "$TMP_DIR"

echo "[+] Reloading NGINX inside container..."
docker exec modsec nginx -s reload

echo "[+] CRS update complete."
