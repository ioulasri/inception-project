# Developer Documentation - Inception

## Overview

This document provides technical details for developers who want to understand, modify, or extend the Inception project infrastructure.

---

## Architecture

### System Components

```
inception/
├── Makefile                   # Build automation
├── srcs/
│   ├── docker-compose.yml     # Service orchestration
│   ├── .env                   # Environment variables
│   └── requirements/
│       ├── nginx/            # Reverse proxy service
│       ├── wordpress/        # Application service
│       └── mariadb/          # Database service
└── secrets/                  # Credentials and certificates
```

### Service Dependencies

```
nginx (port 443)
  ↓ depends on
wordpress (port 9000)
  ↓ depends on
mariadb (port 3306)
```

---

## Setting Up Environment from Scratch

### Prerequisites Installation

#### On Debian/Ubuntu:
```bash
# Update package list
sudo apt update

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Install Docker Compose plugin
sudo apt install docker-compose-plugin

# Install Make
sudo apt install make

# Install OpenSSL
sudo apt install openssl
```

#### Verify Installation:
```bash
docker --version          # Should show 20.10 or higher
docker compose version    # Should show 2.0 or higher
make --version           # Any version
openssl version          # Any version
```

### Clone and Configure

1. **Clone Repository**
   ```bash
   git clone <repository_url> ~/inception
   cd ~/inception
   ```

2. **Create Data Directories**
   ```bash
   mkdir -p ~/data/wordpress ~/data/mariadb
   ```

3. **Create Secrets Directory**
   ```bash
   mkdir -p secrets
   chmod 700 secrets  # Restrict access
   ```

4. **Generate SSL Certificates**
   ```bash
   chmod +x generate-certs.sh
   ./generate-certs.sh
   ```

   This creates:
   - `secrets/cert.pem`: SSL certificate
   - `secrets/key.pem`: Private key

5. **Create Password Files**
   ```bash
   # Generate strong passwords
   openssl rand -base64 32 > secrets/db_root_password.txt
   openssl rand -base64 32 > secrets/db_password.txt
   openssl rand -base64 32 > secrets/wp_admin_password.txt
   
   # Secure permissions
   chmod 600 secrets/*.txt
   ```

6. **Create Environment File**
   ```bash
   cat > srcs/.env << 'EOF'
DOMAIN_NAME=imoulasr.42.fr
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
WP_ADMIN_USER=adminer_user
WP_ADMIN_EMAIL=admin@imoulasr.42.fr
EOF
   ```

7. **Configure Hosts File**
   ```bash
   sudo sh -c 'echo "127.0.0.1 imoulasr.42.fr" >> /etc/hosts'
   ```

---

## Building the Project

### Build Process

The Makefile orchestrates the build process:

```bash
make build
```

**What happens:**
1. Reads `srcs/docker-compose.yml`
2. Builds three Docker images:
   - `nginx` from `srcs/requirements/nginx/Dockerfile`
   - `wordpress` from `srcs/requirements/wordpress/Dockerfile`
   - `mariadb` from `srcs/requirements/mariadb/Dockerfile`
3. Images are tagged with service names
4. Base image (Debian 12) is downloaded if not cached

**Build time**: 3-5 minutes on first run, ~30 seconds on subsequent builds (cached layers).

### Build Options

**Force rebuild (no cache):**
```bash
cd srcs && docker compose build --no-cache
```

**Build specific service:**
```bash
cd srcs && docker compose build nginx
```

---

## Launching the Project

### Standard Launch

```bash
make up
```

**Process:**
1. Creates Docker network: `srcs_inception_network`
2. Creates Docker volumes: `srcs_wordpress_data`, `srcs_db_data`
3. Starts containers in order:
   - `mariadb` (waits for health check)
   - `wordpress` (waits for mariadb health check)
   - `nginx` (waits for wordpress health check)

**Launch time**: 30-60 seconds for all health checks to pass.

### Health Check Mechanism

Each service has health checks defined in `docker-compose.yml`:

**MariaDB:**
```yaml
test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "root", "-p$$(cat /run/secrets/db_root_password)"]
interval: 30s
timeout: 10s
retries: 5
start_period: 30s
```

**WordPress:**
```yaml
test: ["CMD-SHELL", "pidof php-fpm8.2 || exit 1"]
interval: 30s
timeout: 10s
retries: 3
start_period: 10s
```

**NGINX:**
```yaml
test: ["CMD", "curl", "-f", "-k", "https://localhost/"]
interval: 30s
timeout: 10s
retries: 3
start_period: 10s
```

---

## Managing Containers and Volumes

### Container Management Commands

```bash
# List running containers
docker ps

# List all containers (including stopped)
docker ps -a

# View container logs
docker logs <container_name>

# Follow logs in real-time
docker logs -f <container_name>

# Execute command in running container
docker exec -it <container_name> bash

# Restart specific container
docker restart <container_name>

# Stop specific container
docker stop <container_name>

# Remove stopped container
docker rm <container_name>
```

### Container Examples

**Access MariaDB shell:**
```bash
docker exec -it mariadb mysql -u root -p$(cat secrets/db_root_password.txt)
```

**Access WordPress container:**
```bash
docker exec -it wordpress bash
```

**View NGINX configuration:**
```bash
docker exec nginx cat /etc/nginx/nginx.conf
```

### Volume Management

```bash
# List volumes
docker volume ls

# Inspect volume details
docker volume inspect srcs_wordpress_data

# View volume contents
ls -la ~/data/wordpress/
ls -la ~/data/mariadb/
```

### Network Management

```bash
# List networks
docker network ls

# Inspect network
docker network inspect srcs_inception_network

# View network connections
docker network inspect srcs_inception_network --format='{{range .Containers}}{{.Name}} {{.IPv4Address}}{{"\n"}}{{end}}'
```

---

## Data Storage and Persistence

### Volume Configuration

Volumes are defined in `docker-compose.yml`:

```yaml
volumes:
  wordpress_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/imoulasr/data/wordpress
  db_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/imoulasr/data/mariadb
```

### Data Locations

| Service | Container Path | Host Path |
|---------|---------------|-----------|
| WordPress Files | `/var/www/html` | `~/data/wordpress/` |
| MariaDB Data | `/var/lib/mysql` | `~/data/mariadb/` |

### Data Persistence Behavior

- ✅ **Survives**: `make down`, `make restart`, container crashes
- ❌ **Lost**: Manual deletion of `~/data/` directories

### Backup Strategy

**Create backup:**
```bash
# Stop services
make down

# Create timestamped backups
tar -czf backup-$(date +%Y%m%d-%H%M%S)-wordpress.tar.gz ~/data/wordpress/
tar -czf backup-$(date +%Y%m%d-%H%M%S)-mariadb.tar.gz ~/data/mariadb/

# Restart services
make up
```

**Restore backup:**
```bash
make down
sudo rm -rf ~/data/wordpress/* ~/data/mariadb/*
tar -xzf backup-YYYYMMDD-HHMMSS-wordpress.tar.gz -C ~/
tar -xzf backup-YYYYMMDD-HHMMSS-mariadb.tar.gz -C ~/
make up
```

---

## Docker Compose Deep Dive

### Service Configuration Breakdown

#### NGINX Service
```yaml
nginx:
  container_name: nginx
  image: nginx
  build:
    context: ./requirements/nginx
    dockerfile: Dockerfile
  ports:
    - "443:443"                    # Expose HTTPS port
  volumes:
    - wordpress_data:/var/www/html:ro  # Read-only WordPress files
    - ../secrets/cert.pem:/etc/nginx/ssl/cert.pem:ro
    - ../secrets/key.pem:/etc/nginx/ssl/key.pem:ro
  networks:
    - inception_network
  restart: unless-stopped
  depends_on:
    wordpress:
      condition: service_healthy
```

#### WordPress Service
```yaml
wordpress:
  container_name: wordpress
  image: wordpress
  build:
    context: ./requirements/wordpress
    dockerfile: Dockerfile
  expose:
    - "9000"                      # Internal FastCGI port
  volumes:
    - wordpress_data:/var/www/html
  environment:
    - MYSQL_DB_HOST=mariadb
    - MYSQL_DATABASE=${MYSQL_DATABASE}
    - MYSQL_USER=${MYSQL_USER}
    - DOMAIN_NAME=${DOMAIN_NAME}
    - WP_ADMIN_USER=${WP_ADMIN_USER}
    - WP_ADMIN_EMAIL=${WP_ADMIN_EMAIL}
  secrets:
    - db_password
    - wp_admin_password
  networks:
    - inception_network
  restart: unless-stopped
  depends_on:
    mariadb:
      condition: service_healthy
```

#### MariaDB Service
```yaml
mariadb:
  container_name: mariadb
  image: mariadb
  build:
    context: ./requirements/mariadb
    dockerfile: Dockerfile
  expose:
    - "3306"                      # Internal MySQL port
  volumes:
    - db_data:/var/lib/mysql
  environment:
    - MYSQL_DATABASE=${MYSQL_DATABASE}
    - MYSQL_USER=${MYSQL_USER}
  secrets:
    - db_root_password
    - db_password
  networks:
    - inception_network
  restart: unless-stopped
```

---

## Dockerfile Analysis

### NGINX Dockerfile
```dockerfile
FROM debian:12

# Install NGINX, OpenSSL, curl
RUN apt-get update && apt-get install -y nginx openssl curl && rm -rf /var/lib/apt/lists/*

# Create nginx user
RUN useradd -m -s /sbin/nologin nginx_user

# Copy configuration
COPY conf/nginx.conf /etc/nginx/nginx.conf
RUN mkdir -p /etc/nginx/ssl

EXPOSE 443

# Run in foreground (PID 1)
CMD ["nginx", "-g", "daemon off;"]
```

**Key Points:**
- Uses Debian 12 (penultimate stable)
- Cleans apt cache to reduce image size
- Runs as PID 1 (required for Docker)
- `daemon off` prevents container exit

### WordPress Dockerfile
```dockerfile
FROM debian:12

# Install PHP-FPM and dependencies
RUN apt-get update && apt-get install -y \
    php-fpm php-mysql php-curl php-gd php-xml php-json \
    wget curl mariadb-client && rm -rf /var/lib/apt/lists/*

# Download WordPress
WORKDIR /var/www/html
RUN wget -q https://wordpress.org/latest.tar.gz && \
    tar -xzf latest.tar.gz --strip-components=1 && rm latest.tar.gz

# Copy configurations
COPY conf/php-fpm.conf /etc/php/8.2/fpm/php-fpm.conf
COPY conf/wp-config-setup.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/wp-config-setup.sh

# Set permissions
RUN chown -R www-data:www-data /var/www/html
RUN mkdir -p /run/php && chown www-data:www-data /run/php

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/wp-config-setup.sh"]
CMD ["php-fpm8.2", "-F"]
```

**Key Points:**
- PHP 8.2 (Debian 12 default)
- Downloads official WordPress
- Setup script waits for database
- `-F` flag runs PHP-FPM in foreground

### MariaDB Dockerfile
```dockerfile
FROM debian:12

# Install MariaDB
RUN apt-get update && apt-get install -y mariadb-server && rm -rf /var/lib/apt/lists/*

# Copy configuration
COPY conf/my.cnf /etc/mysql/my.cnf

# Set permissions
RUN mkdir -p /var/lib/mysql /var/run/mysqld && \
    chown -R mysql:mysql /var/lib/mysql /var/run/mysqld

# Copy and enable setup script
COPY tools/setup.sh /docker-entrypoint-initdb.d/setup.sh
RUN chmod +x /docker-entrypoint-initdb.d/setup.sh

EXPOSE 3306

ENTRYPOINT ["/docker-entrypoint-initdb.d/setup.sh"]
CMD ["mysqld"]
```

**Key Points:**
- MariaDB from Debian repos
- Initialization script creates database
- Runs mysqld in foreground (PID 1)

---

## Makefile Targets

```makefile
build:          # Build all Docker images
up:             # Start containers in detached mode
down:           # Stop and remove containers, volumes, networks
restart:        # Restart all containers
status:         # Show container status
logs:           # Follow logs from all services
logs-%:         # Follow logs from specific service (e.g., logs-nginx)
clean:          # Prune unused containers and images
rebuild:        # Full rebuild (down + clean + build + up)
help:           # Show available targets
```

---

## Troubleshooting for Developers

### Build Failures

**Error: "Cannot connect to Docker daemon"**
```bash
# Solution: Start Docker service
sudo systemctl start docker

# Verify
docker ps
```

**Error: "Context canceled" during build**
```bash
# Solution: Increase Docker resources or clean up
docker system prune -af
```

### Container Issues

**Container exits immediately:**
```bash
# Check logs
docker logs <container_name>

# Common causes:
# - Missing secrets files
# - Incorrect entrypoint/cmd
# - Configuration errors
```

**Health check fails:**
```bash
# Inspect health status
docker inspect --format='{{json .State.Health}}' <container_name> | jq

# Check health check logs
docker inspect <container_name> | jq '.[].State.Health.Log'
```

### Network Issues

**Cannot reach service from another container:**
```bash
# Verify network connectivity
docker exec wordpress ping -c 3 mariadb

# Check DNS resolution
docker exec wordpress nslookup mariadb
```

### Volume Issues

**Permission denied errors:**
```bash
# Fix ownership
sudo chown -R $(whoami):$(whoami) ~/data/

# Check permissions
ls -la ~/data/wordpress/
ls -la ~/data/mariadb/
```

---

## Development Workflow

### Making Changes

1. **Edit configuration/code files**
2. **Rebuild affected service:**
   ```bash
   cd srcs && docker compose build <service_name>
   ```
3. **Restart service:**
   ```bash
   docker restart <service_name>
   ```
4. **Test changes**
5. **Check logs:**
   ```bash
   make logs-<service_name>
   ```

### Testing Locally

```bash
# Clean slate
make down
sudo rm -rf ~/data/wordpress/* ~/data/mariadb/*

# Fresh build and start
make build
make up

# Verify
make status
curl -Ik https://localhost:443
```

---

## Security Considerations

### Secrets Management

- ✅ Use Docker secrets for passwords
- ❌ Never hardcode passwords in Dockerfiles
- ❌ Never commit secrets to git
- ✅ Use .gitignore for secrets/ and .env

### Network Security

- ✅ Only NGINX exposed on port 443
- ✅ Internal services use Docker network
- ✅ TLSv1.2/1.3 only
- ❌ No HTTP (port 80) exposure

### File Permissions

```bash
# Secrets should be readable only by owner
chmod 600 secrets/*.txt

# Scripts should be executable
chmod +x *.sh
```

---

## Performance Optimization

### Image Size Reduction

- Use multi-stage builds
- Clean package manager cache: `rm -rf /var/lib/apt/lists/*`
- Minimize layers by combining RUN commands

### Runtime Optimization

- Use health checks to ensure proper startup order
- Set appropriate resource limits in docker-compose.yml
- Use volumes for data (not COPY in Dockerfile)

---

## Additional Resources

- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)
- [Dockerfile Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [NGINX Configuration](https://nginx.org/en/docs/)
- [PHP-FPM Configuration](https://www.php.net/manual/en/install.fpm.configuration.php)
- [MariaDB Documentation](https://mariadb.com/kb/en/documentation/)

---

**Document Version**: 1.0  
**Last Updated**: January 2026  
**Maintained By**: imoulasr
