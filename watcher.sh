#!/bin/sh
echo "[*] Watching for ModSecurity rule changes..."
while inotifywait -e modify,create,delete -r /etc/nginx/conf/modsec/; do
  echo "[+] Rule change detected. Reloading NGINX..."
  nginx -c /etc/nginx/conf/nginx.conf -s reload
done
