# ModSecurity NGINX WAF - by HSOC

# Containerized WAF with ModSecurity + NGINX

### Network Ports

- **8080/8443** or **80/443** must be open and unused

---

## Directory Structure Explained

```bash
modsecuirty/
├── cert-gen.sh                  # TLS cert generator
├── docker-compose.yml           # Compose file for standalone WAF
├── docker-compose.override.yml  # WAF in front of app
├── modsec-data/
│   ├── certs/                   # TLS certs
│   ├── crs/                     # OWASP Core Rule Set
│   ├── custom-rules.conf        # Your ModSecurity rules
│   ├── modsecurity.conf         # Main WAF config
│   ├── nginx.conf               # NGINX config (standalone)
│   ├── nginx.conf.reverse.proxy # NGINX config (reverse proxy)
│   └── logs/                    # ModSecurity logs
├── nodeapp/
│   ├── app.js                   # Node.js backend
│   └── Dockerfile               # Dockerfile for Node app
├── update-crs.sh                # CRS updater
├── watcher.sh                   # Auto-reload for rule changes
```

Visit: `https://<your-ip>:8443`

---

## ModSecurity Custom Rules (Example)

```apache
# Block a specific parameter
SecRule ARGS:testparam "@streq test" "id:10001,phase:2,deny,log,status:403,msg:'Test parameter blocked'"

# Block curl User-Agent
SecRule REQUEST_HEADERS:User-Agent "@contains curl" "id:10002,phase:1,deny,log,status:403,msg:'Curl blocked'"

# Basic SQLi pattern
SecRule ARGS "@rx (?i)(union(.*?)select|select.+from)" "id:10003,phase:2,deny,log,status:403,msg:'SQLi blocked'"
```

---

## Security Best Practices Implemented

* `server_tokens off` to hide version info
* HTTPS enforced with redirect from HTTP
* Rate limiting per IP (10r/s)
* Secure headers: `X-Frame-Options`, `X-XSS-Protection`, `Referrer-Policy`, `Permissions-Policy`
* TLS certificate auto-generation via `cert-gen.sh`
* Runtime user separation (optional)
* Auto reload of rules via watcher



# --------------------------------- Build & Run ---------------------------------
build: 
* docker compose -f docker-compose.yml build --no-cache 

up: 
* docker compose -f docker-compose.yml up -d 

down: 
* docker compose -f docker-compose.yml down 

logs: 
* docker-compose logs -f

watch:
* docker exec -it modsec /usr/local/bin/watcher.sh
