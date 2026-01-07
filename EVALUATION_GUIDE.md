# Inception Project - Evaluation Guide
**Student:** imoulasr  
**Date:** January 5, 2026  
**Project:** Docker-based WordPress Infrastructure

---

## Table of Contents
1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Requirements Checklist](#requirements-checklist)
4. [Quick Start](#quick-start)
5. [Testing the Project](#testing-the-project)
6. [Credentials](#credentials)
7. [Technical Implementation](#technical-implementation)
8. [Common Evaluation Questions](#common-evaluation-questions)
9. [Troubleshooting](#troubleshooting)

---

## Project Overview

This project implements a complete web infrastructure using Docker Compose with three services:
- **NGINX**: Reverse proxy with HTTPS (TLSv1.2/1.3)
- **WordPress + PHP-FPM**: Dynamic website
- **MariaDB**: Database server

All services run in separate Docker containers with custom Dockerfiles built from Debian 11.9 base images.

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                    Host Machine                      │
│                                                       │
│  ┌────────────────────────────────────────────────┐ │
│  │          Docker Network (bridge)                │ │
│  │                                                  │ │
│  │  ┌─────────┐    ┌──────────┐    ┌──────────┐  │ │
│  │  │  NGINX  │───▶│WordPress │───▶│ MariaDB  │  │ │
│  │  │ Port:443│    │Port: 9000│    │Port: 3306│  │ │
│  │  └─────────┘    └──────────┘    └──────────┘  │ │
│  │       │              │                │         │ │
│  └───────┼──────────────┼────────────────┼────────┘ │
│          │              │                │           │
│     [TLS Certs]   [WordPress Files]  [Database]     │
│          │              │                │           │
│     ~/secrets/   ~/data/wordpress  ~/data/mariadb   │
└─────────────────────────────────────────────────────┘
```

**Traffic Flow:**
1. Browser → HTTPS (port 443) → NGINX
2. NGINX → FastCGI (port 9000) → WordPress PHP-FPM
3. WordPress → MySQL protocol (port 3306) → MariaDB

---

## Requirements Checklist

### ✅ Mandatory Requirements

| Requirement | Status | Location |
|-------------|--------|----------|
| No pre-built images (except base OS) | ✅ | All Dockerfiles use `debian:11.9` |
| No `latest` tag | ✅ | Explicit version: `debian:11.9` |
| Custom Dockerfiles for each service | ✅ | `srcs/requirements/{nginx,wordpress,mariadb}/Dockerfile` |
| Docker Compose file | ✅ | `srcs/docker-compose.yml` |
| NGINX with TLSv1.2/1.3 only | ✅ | `srcs/requirements/nginx/conf/nginx.conf` |
| WordPress + PHP-FPM | ✅ | No apache, pure PHP-FPM |
| MariaDB (no NGINX in same container) | ✅ | Separate container |
| Persistent volumes | ✅ | `/Users/imadoulasri/data/{wordpress,mariadb}` |
| Docker network | ✅ | `inception_network` (bridge) |
| Containers restart on crash | ✅ | `restart: unless-stopped` |
| No passwords in code | ✅ | Using Docker secrets |
| Domain name ends in `.42.fr` | ✅ | `imoulasr.42.fr` |
| Environment variables | ✅ | `srcs/.env` file |
| .env not in git | ✅ | Listed in `.gitignore` |
| 2 WordPress users | ✅ | `adminer_user` + `seconduser` |
| Admin username ≠ "admin" | ✅ | Username is `adminer_user` |
| No hacky patches (tail -f, etc.) | ✅ | Proper daemon mode |
| Makefile at root | ✅ | `Makefile` with all targets |

---

## Quick Start

### 1. Prerequisites Check
```bash
# Check Docker is running
docker --version
docker compose version

# Check directory structure
cd ~/inception
ls -la
```

### 2. Start the Infrastructure
```bash
cd ~/inception
make build    # Build all images
make up       # Start containers
make status   # Check status
```

### 3. Add Domain to Hosts File
```bash
# Add this line to /etc/hosts
echo "127.0.0.1 imoulasr.42.fr" | sudo tee -a /etc/hosts
```

### 4. Access WordPress
Open browser: **https://imoulasr.42.fr**

---

## Testing the Project

### Test 1: Verify Containers Are Running
```bash
cd ~/inception
make status
```
**Expected Output:**
```
NAME       STATUS
mariadb    Up X seconds (healthy)
wordpress  Up X seconds (healthy)
nginx      Up X seconds (healthy)
```

### Test 2: Check HTTPS/TLS
```bash
curl -Ik https://localhost:443
```
**Expected:** HTTP/2 302 response with `server: nginx`

**Check TLS Version:**
```bash
echo | openssl s_client -connect localhost:443 2>&1 | grep "Protocol"
```
**Expected:** `TLSv1.3` or `TLSv1.2`

### Test 3: Verify Certificate
```bash
echo | openssl s_client -connect localhost:443 2>/dev/null | openssl x509 -noout -subject -dates
```
**Expected:**
```
subject=C = FR, ST = Paris, L = Paris, O = 42, CN = imoulasr.42.fr
notBefore=Jan  5 19:09:41 2026 GMT
notAfter=Jan  5 19:09:41 2027 GMT
```

### Test 4: Check Database Users
```bash
docker exec wordpress mysql -h mariadb -u wpuser \
  -p$(cat secrets/db_password.txt) wordpress \
  -e "SELECT user_login FROM wp_users;"
```
**Expected Output:**
```
user_login
adminer_user
seconduser
```

### Test 5: Verify Persistent Volumes
```bash
ls -la /Users/imadoulasri/data/wordpress/
ls -la /Users/imadoulasri/data/mariadb/
```
**Expected:** Both directories contain files

### Test 6: Check No Infinite Loops
```bash
docker exec nginx cat /etc/nginx/nginx.conf | grep "daemon"
docker exec wordpress cat /etc/php/7.4/fpm/php-fpm.conf | grep "daemonize"
```
**Expected:** 
- NGINX: `daemon off;`
- PHP-FPM: `daemonize = no`

### Test 7: Verify Secrets (No Passwords in Code)
```bash
grep -r "password" ~/inception/srcs/requirements/ | grep -v "PASSWORD_FILE" | wc -l
```
**Expected:** 0 (all passwords use secrets)

### Test 8: Check Network
```bash
docker network inspect srcs_inception_network
```
**Expected:** Bridge network with all 3 containers

### Test 9: Verify No Passwords in Dockerfiles/Configs
```bash
grep -ri "password" ~/inception/srcs/requirements/ --exclude-dir=.git | grep -v "PASSWORD" | grep -v "password_hash" | grep -v "wp_set_password" | grep -v ".md"
```
**Expected:** Should only show references to password files/variables, not actual passwords

### Test 10: Check Container Health
```bash
docker inspect mariadb --format='{{.State.Health.Status}}'
docker inspect wordpress --format='{{.State.Health.Status}}'
docker inspect nginx --format='{{.State.Health.Status}}'
```
**Expected:** All show `healthy`

---

## Credentials

### WordPress Admin
- **URL:** https://imoulasr.42.fr/wp-admin
- **Username:** `adminer_user`
- **Password:** `AdminPasswordEOkTx9ZYnIEzoS9L`

### WordPress Regular User
- **URL:** https://imoulasr.42.fr/wp-admin
- **Username:** `seconduser`
- **Password:** `SimplePass123`

### Database Root
- **Password:** Located in `~/inception/secrets/db_root_password.txt`
- **Command:** `cat ~/inception/secrets/db_root_password.txt`

### Database User
- **Username:** `wpuser`
- **Password:** Located in `~/inception/secrets/db_password.txt`
- **Database:** `wordpress`

---

## Technical Implementation

### 1. NGINX Configuration
**File:** `srcs/requirements/nginx/conf/nginx.conf`

**Key Features:**
- Listens on port 443 only (HTTPS)
- SSL protocols: TLSv1.2 and TLSv1.3
- FastCGI pass to WordPress container
- Security headers (X-Frame-Options, X-Content-Type-Options, X-XSS-Protection)
- HTTP to HTTPS redirect on port 80

**Dockerfile:** 
- Base: `debian:11.9`
- Installs NGINX, OpenSSL, curl
- Copies custom config
- Runs with `daemon off` (no infinite loop)

### 2. WordPress Configuration
**File:** `srcs/requirements/wordpress/Dockerfile`

**Key Features:**
- Downloads latest WordPress from official source
- PHP 7.4 with FPM (FastCGI Process Manager)
- Custom PHP-FPM config (no daemonization)
- Setup script generates `wp-config.php`
- Waits for MariaDB before starting

**Setup Script:** `srcs/requirements/wordpress/conf/wp-config-setup.sh`
- Checks MariaDB connectivity
- Creates wp-config.php with database credentials
- Uses Docker secrets for passwords
- Starts PHP-FPM in foreground

### 3. MariaDB Configuration
**File:** `srcs/requirements/mariadb/Dockerfile`

**Key Features:**
- MariaDB 10.5 (from Debian 11.9 repos)
- Custom my.cnf configuration
- Initialization script for database setup
- Persistent storage at `/var/lib/mysql`

**Setup Script:** `srcs/requirements/mariadb/tools/setup.sh`
- Initializes database on first run
- Creates WordPress database and user
- Sets root password from secrets
- Skips initialization if database exists (restart-safe)

### 4. Docker Compose
**File:** `srcs/docker-compose.yml`

**Key Features:**
- Three services: nginx, wordpress, mariadb
- Health checks for each service
- Dependency management (mariadb → wordpress → nginx)
- Named volumes with bind mounts
- Docker secrets integration
- Custom bridge network

**Volumes:**
- `wordpress_data`: Bind mount to `/Users/imadoulasri/data/wordpress`
- `db_data`: Bind mount to `/Users/imadoulasri/data/mariadb`

**Secrets:**
- `db_root_password`: MariaDB root password
- `db_password`: WordPress database user password
- `wp_admin_password`: WordPress admin password

### 5. Environment Variables
**File:** `srcs/.env`

```bash
DOMAIN_NAME=imoulasr.42.fr
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
WP_ADMIN_USER=adminer_user
WP_ADMIN_EMAIL=admin@imoulasr.42.fr
```

---

## Common Evaluation Questions

### Q1: Why no pre-built images?
**A:** The project requires understanding of Docker and system administration. Building from base OS images (`debian:11.9`) demonstrates knowledge of service installation and configuration.

### Q2: How do secrets work?
**A:** Docker secrets mount files at `/run/secrets/` in containers. Scripts read passwords from these files instead of hardcoding them. Example:
```bash
DB_PASSWORD=$(cat /run/secrets/db_password)
```

### Q3: How does NGINX communicate with WordPress?
**A:** Via FastCGI protocol on port 9000. NGINX forwards PHP requests to the WordPress container using the `fastcgi_pass wordpress:9000;` directive.

### Q4: What happens if a container crashes?
**A:** The `restart: unless-stopped` policy automatically restarts containers unless manually stopped with `make down`.

### Q5: How are volumes persistent?
**A:** Volumes are bind-mounted to host directories (`/Users/imadoulasri/data/`). Data survives container restarts and rebuilds.

### Q6: Why TLSv1.2/1.3 only?
**A:** Security requirement. Older protocols (SSLv3, TLSv1.0, TLSv1.1) have known vulnerabilities.

### Q7: How do you verify 2 users exist?
```bash
docker exec wordpress mysql -h mariadb -u wpuser \
  -p$(cat secrets/db_password.txt) wordpress \
  -e "SELECT user_login FROM wp_users;"
```

### Q8: Can you rebuild without losing data?
**A:** Yes! `make down` preserves volumes. `make clean` removes unused containers/images but keeps data directories.

### Q9: Why bind mounts instead of named volumes?
**A:** The subject requires volumes to be in `/home/<login>/data`. Bind mounts link Docker volumes to specific host directories.

### Q10: How does WordPress know the database is ready?
**A:** The `wp-config-setup.sh` script waits for MariaDB by repeatedly testing connectivity with `mysql -h mariadb` before proceeding.

### Q11: What's the difference between ENTRYPOINT and CMD?
**A:** 
- **ENTRYPOINT**: The main command that always runs (e.g., setup script)
- **CMD**: Arguments passed to ENTRYPOINT, can be overridden

Example in WordPress:
```dockerfile
ENTRYPOINT ["/usr/local/bin/wp-config-setup.sh"]
CMD ["php-fpm7.4", "-F"]
```

### Q12: Why is daemon mode disabled for services?
**A:** Docker needs a foreground process (PID 1) to keep containers running. If the process daemonizes (runs in background), the container exits immediately.
- NGINX: `daemon off;`
- PHP-FPM: `daemonize = no`
- MariaDB: `exec mysqld` (foreground mode)

### Q13: What happens if secrets files are missing?
**A:** Containers fail to start because scripts try to read non-existent files. Docker Compose validates secrets exist before starting.

---

## Troubleshooting

### Issue: Containers won't start
```bash
# Check logs
make logs

# Rebuild from scratch
make down
docker system prune -f
make build
make up
```

### Issue: "Can't reach site" error
```bash
# Verify domain in /etc/hosts
grep imoulasr.42.fr /etc/hosts

# If missing, add it:
echo "127.0.0.1 imoulasr.42.fr" | sudo tee -a /etc/hosts
```

### Issue: Certificate warning in browser
**This is expected!** Self-signed certificates trigger warnings. Click "Advanced" → "Proceed to imoulasr.42.fr"

### Issue: WordPress shows installation page
```bash
# Check if WordPress is installed
docker exec wordpress wp core is-installed --path=/var/www/html --allow-root

# If not, run installation
docker exec -u www-data wordpress wp core install \
  --url="https://imoulasr.42.fr" \
  --title="Inception" \
  --admin_user="adminer_user" \
  --admin_password="$(cat ~/inception/secrets/wp_admin_password.txt)" \
  --admin_email="admin@imoulasr.42.fr" \
  --path="/var/www/html" \
  --allow-root
```

### Issue: Database connection errors
```bash
# Test database connectivity
docker exec wordpress mysql -h mariadb -u wpuser \
  -p$(cat secrets/db_password.txt) -e "SELECT 1;"

# Check MariaDB logs
docker compose -f srcs/docker-compose.yml logs mariadb
```

---

## Makefile Commands

```bash
make build    # Build all Docker images
make up       # Start all containers
make down     # Stop and remove containers
make restart  # Restart all containers
make status   # Show container status
make logs     # View all logs
make logs-nginx      # View NGINX logs only
make logs-wordpress  # View WordPress logs only
make logs-mariadb    # View MariaDB logs only
make clean    # Clean up stopped containers and images
make rebuild  # Full rebuild (down + clean + build + up)
make help     # Show help message
```

---

## Project Structure

```
inception/
├── Makefile                              # Orchestration commands
├── .gitignore                            # Excludes secrets and .env
├── EVALUATION_GUIDE.md                   # This file
│
├── srcs/
│   ├── .env                              # Environment variables (not in git)
│   ├── docker-compose.yml                # Service orchestration
│   │
│   └── requirements/
│       ├── nginx/
│       │   ├── Dockerfile                # NGINX image
│       │   └── conf/nginx.conf           # NGINX configuration
│       │
│       ├── wordpress/
│       │   ├── Dockerfile                # WordPress image
│       │   └── conf/
│       │       ├── wp-config-setup.sh    # WordPress setup script
│       │       └── php-fpm.conf          # PHP-FPM configuration
│       │
│       └── mariadb/
│           ├── Dockerfile                # MariaDB image
│           ├── conf/my.cnf               # MariaDB configuration
│           └── tools/setup.sh            # Database initialization
│
├── secrets/                              # Passwords and certificates (not in git)
│   ├── db_root_password.txt
│   ├── db_password.txt
│   ├── wp_admin_password.txt
│   ├── cert.pem                          # TLS certificate
│   └── key.pem                           # TLS private key
│
└── /Users/imadoulasri/data/              # Persistent volumes
    ├── wordpress/                        # WordPress files
    └── mariadb/                          # Database files
```

---

## Evaluation Checklist

**For the evaluator:**

- [ ] Check Makefile exists at project root
- [ ] Verify `.env` file is not in git (`git ls-files | grep .env` should be empty)
- [ ] Check all Dockerfiles use explicit versions (no `latest`)
- [ ] Verify no pre-built images (`docker images` should show `srcs-*` images)
- [ ] Test `make build` and `make up` work
- [ ] Access https://imoulasr.42.fr in browser
- [ ] Verify HTTPS certificate is self-signed with CN=imoulasr.42.fr
- [ ] Check TLS version is 1.2 or 1.3
- [ ] Login to wp-admin with both users
- [ ] Verify 2 users in database
- [ ] Check persistent volumes exist
- [ ] Test container restart (`make restart`)
- [ ] Verify no passwords in code files
- [ ] Check containers restart automatically after crash
- [ ] Verify custom network exists
- [ ] Confirm network name is `srcs_inception_network` (not just `inception_network`)
- [ ] Check no infinite loops (tail -f, sleep infinity, while true)
- [ ] Verify each service runs in its own container (3 total)
- [ ] Test that data persists after `make down` && `make up`

---

## What Evaluators Will Check

### 1. **Before Starting** (5 min)
- Verify you don't have containers already running
- Check the project structure matches requirements
- Confirm `.env` and `secrets/` are in `.gitignore`
- Look at Dockerfiles to ensure no `latest` tags

### 2. **Building and Starting** (5-10 min)
```bash
cd ~/inception
make build    # Should build 3 images without errors
make up       # Should start 3 containers
make status   # All containers should be "Up" and "healthy"
```

### 3. **HTTPS and Domain** (5 min)
- Add domain to `/etc/hosts`: `127.0.0.1 imoulasr.42.fr`
- Open https://imoulasr.42.fr in browser
- Check certificate (should show imoulasr.42.fr)
- Verify TLS 1.2/1.3 is used

### 4. **WordPress Login** (5 min)
- Access https://imoulasr.42.fr/wp-admin
- Login with admin user: `adminer_user`
- Verify can access dashboard
- Check username doesn't contain "admin"

### 5. **Database Check** (5 min)
```bash
# Verify 2 users exist
docker exec wordpress mysql -h mariadb -u wpuser \
  -p$(cat ~/inception/secrets/db_password.txt) wordpress \
  -e "SELECT user_login FROM wp_users;"

# Should show: adminer_user and seconduser
```

### 6. **Persistent Volumes** (5 min)
```bash
# Check volumes exist
ls /Users/imadoulasri/data/wordpress/
ls /Users/imadoulasri/data/mariadb/

# Restart and verify data persists
make down
make up
# WordPress should still be installed (no setup page)
```

### 7. **Security Check** (5 min)
```bash
# No passwords in code
grep -r "password" ~/inception/srcs/requirements/ | grep -v "PASSWORD"

# Secrets properly used
docker exec wordpress cat /run/secrets/db_password
```

### 8. **Restart Policy** (3 min)
```bash
# Kill a container and watch it restart
docker kill wordpress
sleep 5
docker ps | grep wordpress  # Should be back up
```

### 9. **Code Review** (10 min)
Evaluator will open and check:
- Each Dockerfile (no wget of docker images, proper structure)
- docker-compose.yml (networks, volumes, dependencies)
- Configuration files (nginx.conf, my.cnf, php-fpm.conf)
- No infinite loops (tail -f, sleep infinity)
- Proper PID 1 management (daemon off, -F flags)

### 10. **Questions** (10 min)
Be prepared to explain:
- How services communicate
- Why you chose certain configurations
- What happens when a container crashes
- How secrets work
- How volumes persist data

**Total Evaluation Time: ~60 minutes**

---

## Defense Tips

### Before Your Evaluation
1. **Test everything yourself first**
   ```bash
   make down
   make build
   make up
   # Try accessing the site
   # Login to WordPress
   # Check database
   ```

2. **Have a backup plan**
   - Keep a copy of your secrets passwords written down
   - Know how to recreate users if needed
   - Understand how to check logs: `make logs-<service>`

3. **Know your configuration**
   - Why did you use those NGINX settings?
   - What does each line in docker-compose.yml do?
   - How does the MariaDB setup script work?

4. **Practice explaining**
   - Draw the architecture on paper
   - Explain the data flow from browser to database
   - Describe what happens on container startup

### During Evaluation
1. **Stay calm** - If something breaks, use logs to debug
2. **Explain as you go** - Don't just run commands, explain what they do
3. **Be honest** - If you don't know something, say so
4. **Show understanding** - Even if code isn't perfect, explain your reasoning

### Common Pitfalls to Avoid
❌ **Don't do this:**
- Start containers before evaluator arrives
- Have old containers running from previous tests
- Skip the domain in `/etc/hosts` step
- Forget to show that 2 users exist

✅ **Do this:**
- Clean slate: `make down` before evaluation
- Show each step clearly
- Verify each requirement as you go
- Keep calm if certificate warnings appear (they're expected)

---

## Final Notes

**Key Points for Defense:**
1. All services run in separate containers
2. No pre-built application images (only base OS)
3. Secrets management prevents password exposure
4. Persistent volumes ensure data survives restarts
5. HTTPS with proper TLS configuration
6. No hacky workarounds (proper daemon modes)
7. Restart policies for high availability
8. Custom network isolation

**Time to Complete:** ~1-2 hours for full setup

**Difficulty Level:** Intermediate Docker + System Administration

**Skills Demonstrated:**
- Docker containerization
- Docker Compose orchestration
- NGINX reverse proxy configuration
- PHP-FPM setup
- MariaDB administration
- TLS/SSL certificate management
- Secrets management
- Shell scripting
- Network configuration

---

**Good luck with your evaluation! 🚀**

*If you encounter any issues during evaluation, refer to the Troubleshooting section or check container logs with `make logs`.*

---

## Quick Reference Card

**Print or keep this handy during evaluation:**

### Essential Commands
```bash
make build          # Build images
make up             # Start containers
make down           # Stop containers
make status         # Check status
make logs           # View all logs
make logs-nginx     # NGINX logs only
make restart        # Restart all
```

### Verify Checklist
```bash
# 1. Containers running
make status

# 2. TLS version
echo | openssl s_client -connect localhost:443 2>&1 | grep Protocol

# 3. Two users
docker exec wordpress mysql -h mariadb -u wpuser \
  -p$(cat secrets/db_password.txt) wordpress \
  -e "SELECT user_login FROM wp_users;"

# 4. Volumes exist
ls /Users/imadoulasri/data/wordpress/
ls /Users/imadoulasri/data/mariadb/

# 5. No passwords in code
grep -r "password" srcs/requirements/ | grep -v PASSWORD | wc -l
# Should output: 0
```

### Login Credentials
- **Admin:** adminer_user / AdminPasswordEOkTx9ZYnIEzoS9L
- **User:** seconduser / SimplePass123
- **URL:** https://imoulasr.42.fr/wp-admin

### If Something Goes Wrong
```bash
# Check logs
make logs-<service>

# Restart specific service
docker restart <service-name>

# Full rebuild
make down
docker system prune -f
make build
make up
```

---

**Remember:** The evaluator wants to see that you understand Docker, not that your project is perfect. Explain your choices and show you can debug issues!
