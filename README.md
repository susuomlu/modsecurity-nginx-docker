# Containerized WAF with ModSecurity + NGINX

A production-ready Web Application Firewall (WAF) implementation using ModSecurity 3.x with NGINX, containerized with Docker for easy deployment and management.

## 🚀 Features

- **ModSecurity 3.x** with OWASP Core Rule Set (CRS)
- **NGINX** as reverse proxy with security hardening
- **TLS/SSL** encryption with auto-generated certificates
- **Custom rule support** with hot-reload capability
- **Rate limiting** and DDoS protection
- **Security headers** automatically configured
- **Comprehensive logging** (access, error, and audit logs)
- **Custom error pages** with modern UI
- **Docker containerization** for portability

## 🏗️ Architecture
```
┌─────────────┐         ┌──────────────┐         ┌─────────────┐
│   Client    │────────▶│  NGINX WAF   │────────▶│  Backend    │
│             │  HTTPS  │ + ModSecurity│  HTTP   │  Application│
└─────────────┘         └──────────────┘         └─────────────┘
                              │
                              ▼
                        ┌──────────┐
                        │   Logs   │
                        │  & Audit │
                        └──────────┘
```

## 📁 Directory Structure
```
modsecurity-nginx-docker/
├── cert-gen.sh                    # SSL certificate generation script
├── docker-compose.yml             # Docker orchestration file
├── Dockerfile                     # NGINX + ModSecurity container
├── watcher.sh                     # Auto-reload script for rule changes
├── update-crs.sh                  # OWASP CRS update utility
├── README.md                      # This file
│
├── modsec-data/                   # ModSecurity configuration directory
│   ├── nginx.conf                 # Main NGINX configuration
│   ├── modsecurity.conf           # ModSecurity core configuration
│   ├── custom-rules.conf          # Your custom ModSecurity rules
│   │
│   ├── conf.d/                    # NGINX server blocks
│   │   └── node.conf              # Backend proxy configuration
│   │
│   ├── crs/                       # OWASP Core Rule Set
│   │   ├── crs-setup.conf         # CRS configuration
│   │   └── rules/                 # CRS rule files
│   │       ├── REQUEST-901-*.conf # Initialization rules
│   │       ├── REQUEST-9XX-*.conf # Attack detection rules
│   │       ├── RESPONSE-9XX-*.conf# Response inspection rules
│   │       └── *.data             # Supporting data files
│   │
│   ├── html/                      # Custom error pages
│   │   ├── custom_403.html        # Blocked request page
│   │   └── tailwind.css           # Styling
│   │
│   ├── logs/                      # Log files (generated at runtime)
│   │   ├── access.log             # HTTP access logs
│   │   ├── error.log              # NGINX error logs
│   │   └── audit.log              # ModSecurity audit logs
│   │
│   └── ssl/                       # TLS certificates
│       ├── cert.pem               # Certificate
│       └── privkey.pem            # Private key
│
└── nodeapp/                       # Example backend application
    ├── Dockerfile
    └── app.js
```

## 🚦 Quick Start

### 1. Clone and Navigate
```bash
git clone https://github.com/susuomlu/modsecurity-nginx-docker.git
cd modsecurity-nginx-docker/
```

### 2. Generate SSL Certificates (Optional)
```bash
chmod +x cert-gen.sh
./cert-gen.sh
```

### 3. Build the Container
```bash
docker compose -f docker-compose.yml build --no-cache
```

### 4. Start the Services
```bash
docker compose -f docker-compose.yml up -d
```

### 5. Verify Deployment
```bash
# Check container status
docker ps -a

# View logs
docker compose logs -f

# Test HTTPS access
curl -k https://localhost:8443
```

## 🔧 Configuration

### ModSecurity Settings

Edit `modsec-data/modsecurity.conf`:
```apache
# Enable ModSecurity
SecRuleEngine On

# Set paranoia level (1-4, higher = more strict)
SecAction "id:900000,phase:1,nolog,pass,t:none,setvar:tx.paranoia_level=2"

# Logging
SecAuditEngine RelevantOnly
SecAuditLog /var/log/modsec/audit.log
```

### NGINX Configuration

Edit `modsec-data/nginx.conf` for global settings:
```nginx
# Worker processes
worker_processes auto;

# Rate limiting zone
limit_req_zone $binary_remote_addr zone=waf_limit:10m rate=10r/s;
```

Edit `modsec-data/conf.d/node.conf` for backend configuration:
```nginx
server {
    listen 8443 ssl http2;
    server_name _;
    
    # Backend proxy
    location / {
        proxy_pass http://nodeapp:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### Custom Rules

Add custom ModSecurity rules in `modsec-data/custom-rules.conf`:
```apache
# Block specific parameter
SecRule ARGS:testparam "@streq test" \
    "id:10001,phase:2,deny,log,status:403,msg:'Test parameter blocked'"

# Block curl User-Agent
SecRule REQUEST_HEADERS:User-Agent "@contains curl" \
    "id:10002,phase:1,deny,log,status:403,msg:'Curl blocked'"

# Block SQL injection patterns
SecRule ARGS "@rx (?i)(union(.*?)select|select.+from)" \
    "id:10003,phase:2,deny,log,status:403,msg:'SQLi attempt blocked'"

# Block XSS attempts
SecRule ARGS "@rx (?i)(<script|javascript:|onerror=)" \
    "id:10004,phase:2,deny,log,status:403,msg:'XSS attempt blocked'"

# Block path traversal
SecRule REQUEST_URI "@rx (\.\./|\.\.\\)" \
    "id:10005,phase:1,deny,log,status:403,msg:'Path traversal blocked'"
```

### Hot-Reload Rules

Enable automatic rule reloading:
```bash
docker exec -it modsec /usr/local/bin/watcher.sh
```

Or manually reload:
```bash
docker compose restart
```

## 🛡️ Security Features

### 1. OWASP Core Rule Set Protection

- SQL Injection (SQLi)
- Cross-Site Scripting (XSS)
- Remote File Inclusion (RFI)
- Local File Inclusion (LFI)
- Remote Code Execution (RCE)
- Session Fixation
- Scanner Detection
- Protocol Violations
- Data Leakage Prevention

### 2. Security Headers

Automatically configured:
```
X-Frame-Options: DENY
X-Content-Type-Options: nosniff
X-XSS-Protection: 1; mode=block
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: geolocation=(), microphone=(), camera=()
```

### 3. Rate Limiting

- Default: 10 requests/second per IP
- Burst allowance: 20 requests
- Configurable per location

### 4. TLS/SSL

- TLS 1.2 and 1.3 only
- Strong cipher suites
- HTTP to HTTPS redirect
- HSTS enabled

## 📊 Monitoring & Logging

### View Live Logs
```bash
# All logs
docker compose logs -f

# Access logs only
docker exec modsec tail -f /var/log/nginx/access.log

# ModSecurity audit logs
docker exec modsec tail -f /var/log/modsec/audit.log

# Error logs
docker exec modsec tail -f /var/log/nginx/error.log
```

### Log Locations

Inside container:
- Access: `/var/log/nginx/access.log`
- Error: `/var/log/nginx/error.log`
- Audit: `/var/log/modsec/audit.log`

On host (mounted):
- `modsec-data/logs/access.log`
- `modsec-data/logs/error.log`
- `modsec-data/logs/audit.log`

## 🧪 Testing

### Test Basic Access
```bash
curl -k https://localhost:8443
```

### Test SQL Injection Block
```bash
curl -k "https://localhost:8443/?id=1' OR '1'='1"
# Expected: 403 Forbidden
```

### Test XSS Block
```bash
curl -k "https://localhost:8443/?name=<script>alert('xss')</script>"
# Expected: 403 Forbidden
```

### Test Custom Rule
```bash
curl -k "https://localhost:8443/?testparam=test"
# Expected: 403 Forbidden
```

### Test User-Agent Block
```bash
curl -k https://localhost:8443
# Expected: 403 Forbidden (curl is blocked by custom rule)
```

## 🔄 Management Commands

### Start Services
```bash
docker compose up -d
```

### Stop Services
```bash
docker compose down
```

### Restart Services
```bash
docker compose restart
```

### Rebuild After Changes
```bash
docker compose down
docker compose build --no-cache
docker compose up -d
```

### Update OWASP CRS
```bash
chmod +x update-crs.sh
./update-crs.sh
docker compose restart
```

### Access Container Shell
```bash
docker exec -it modsec /bin/sh
```

## 🎯 Tuning & Optimization

### Adjust Paranoia Level

Higher paranoia = more false positives but better security:
```apache
# In modsec-data/crs/crs-setup.conf
SecAction "id:900000,phase:1,nolog,pass,t:none,setvar:tx.paranoia_level=2"
```

Levels:
- **1**: Basic security (recommended for start)
- **2**: Elevated security
- **3**: High security (more false positives)
- **4**: Maximum security (many false positives)

### Whitelist Specific IPs
```nginx
# In nginx.conf or server block
geo $whitelist {
    default 0;
    10.0.0.0/8 1;
    192.168.1.100 1;
}

# In custom-rules.conf
SecRule REMOTE_ADDR "@ipMatch 192.168.1.100" \
    "id:10100,phase:1,pass,nolog,ctl:ruleEngine=Off"
```

### Disable Specific Rules
```apache
# In custom-rules.conf
SecRuleRemoveById 942100
SecRuleRemoveByMsg "SQL Injection Attack"
```

## 🐛 Troubleshooting

### Port Already in Use
```bash
# Check what's using the port
sudo lsof -i :8443

# Change ports in docker-compose.yml
ports:
  - "9443:8443"  # For example, use 9443 instead
```

### Permission Denied on Logs
```bash
# Fix log directory permissions
chmod -R 755 modsec-data/logs/
```

### Too Many False Positives

1. Review audit logs to identify problematic rules
2. Temporarily disable the rule
3. Whitelist legitimate patterns
4. Lower paranoia level

## 🔐 Production Recommendations

1. **Use Valid SSL Certificates**: Replace self-signed certs with Let's Encrypt or commercial certificates
2. **Configure Monitoring**: Integrate with ELK, Splunk, or similar
3. **Regular Updates**: Keep CRS and ModSecurity updated
4. **Tune Rules**: Start with paranoia level 1, gradually increase
5. **Backup Configuration**: Version control your custom rules
6. **Resource Limits**: Set appropriate Docker resource constraints
7. **Network Segmentation**: Place WAF in DMZ
8. **Regular Audits**: Review logs and rules monthly

## 📚 Additional Resources

- [ModSecurity Documentation](https://github.com/SpiderLabs/ModSecurity)
- [OWASP CRS](https://coreruleset.org/)
- [NGINX Documentation](https://nginx.org/en/docs/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)

## 📝 License

This project configuration is provided as-is for educational and production use.

## 🤝 Contributing

Feel free to submit issues, fork the repository, and create pull requests for any improvements.

---

**Note**: Always test thoroughly in a staging environment before deploying to production.
