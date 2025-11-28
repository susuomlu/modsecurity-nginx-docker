#!/bin/sh
echo "[*] Watching for ModSecurity rule changes..."
while inotifywait -e modify,create,delete -r /usr/local/nginx/conf/modsec/; do
  echo "[+] Rule change detected. Reloading NGINX..."
  nginx -s reload
done
