# Containerized WAF with ModSecurity + NGINX

### Network Ports

- **8080/8443** or **80/443** must be open and unused

---

## Directory Structure Explained

```bash
nginx-waf/
├── cert-gen.sh
├── docker-compose.yml
├── Dockerfile
├── modsec-data
│   ├── conf.d
│   │   └── node.conf
│   ├── crs
│   │   ├── crs-setup.conf
│   │   └── rules
│   │       ├── iis-errors.data
│   │       ├── java-classes.data
│   │       ├── java-errors.data
│   │       ├── lfi-os-files.data
│   │       ├── php-errors.data
│   │       ├── php-errors-pl2.data
│   │       ├── php-function-names-933150.data
│   │       ├── php-variables.data
│   │       ├── REQUEST-901-INITIALIZATION.conf
│   │       ├── REQUEST-905-COMMON-EXCEPTIONS.conf
│   │       ├── REQUEST-911-METHOD-ENFORCEMENT.conf
│   │       ├── REQUEST-913-SCANNER-DETECTION.conf
│   │       ├── REQUEST-920-PROTOCOL-ENFORCEMENT.conf
│   │       ├── REQUEST-921-PROTOCOL-ATTACK.conf
│   │       ├── REQUEST-922-MULTIPART-ATTACK.conf
│   │       ├── REQUEST-930-APPLICATION-ATTACK-LFI.conf
│   │       ├── REQUEST-931-APPLICATION-ATTACK-RFI.conf
│   │       ├── REQUEST-932-APPLICATION-ATTACK-RCE.conf
│   │       ├── REQUEST-933-APPLICATION-ATTACK-PHP.conf
│   │       ├── REQUEST-934-APPLICATION-ATTACK-GENERIC.conf
│   │       ├── REQUEST-941-APPLICATION-ATTACK-XSS.conf
│   │       ├── REQUEST-942-APPLICATION-ATTACK-SQLI.conf
│   │       ├── REQUEST-943-APPLICATION-ATTACK-SESSION-FIXATION.conf
│   │       ├── REQUEST-944-APPLICATION-ATTACK-JAVA.conf
│   │       ├── REQUEST-949-BLOCKING-EVALUATION.conf
│   │       ├── RESPONSE-950-DATA-LEAKAGES.conf
│   │       ├── RESPONSE-951-DATA-LEAKAGES-SQL.conf
│   │       ├── RESPONSE-952-DATA-LEAKAGES-JAVA.conf
│   │       ├── RESPONSE-953-DATA-LEAKAGES-PHP.conf
│   │       ├── RESPONSE-954-DATA-LEAKAGES-IIS.conf
│   │       ├── RESPONSE-955-WEB-SHELLS.conf
│   │       ├── RESPONSE-959-BLOCKING-EVALUATION.conf
│   │       ├── RESPONSE-980-CORRELATION.conf
│   │       ├── restricted-files.data
│   │       ├── restricted-upload.data
│   │       ├── scanners-user-agents.data
│   │       ├── sql-errors.data
│   │       ├── ssrf.data
│   │       ├── unix-shell.data
│   │       ├── web-shells-asp.data
│   │       ├── web-shells-php.data
│   │       └── windows-powershell-commands.data
│   ├── custom-rules.conf
│   ├── html
│   │   ├── custom_403.html
│   │   ├── custom_403.html.ol
│   │   └── tailwind.css
│   ├── logs
│   │   ├── access.log
│   │   ├── audit.log
│   │   └── error.log
│   ├── modsecurity.conf
│   ├── nginx.conf
│   └── ssl
│       ├── cert.pem
│       ├── privkey.pem
│       ├── server.crt
│       └── server.key
├── nginx-waf-modsec.tar
├── nodeapp
│   ├── app.js
│   └── Dockerfile
├── README.md
├── update-crs.sh
└── watcher.sh
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

---
## Build & Run
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
