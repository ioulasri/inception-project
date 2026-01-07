# Inception

*This project has been created as part of the 42 curriculum by imoulasr.*

## Description

Inception is a system administration project that focuses on virtualizing Docker images within a personal virtual machine. The project creates a complete web infrastructure using Docker Compose with three core services:

- **NGINX**: Reverse proxy with HTTPS (TLSv1.2/1.3 only)
- **WordPress + PHP-FPM**: Dynamic content management system
- **MariaDB**: Relational database server

All services run in separate Docker containers with custom Dockerfiles built from Debian 12 (penultimate stable version). The infrastructure uses Docker networks for secure inter-container communication, Docker secrets for credential management, and persistent named volumes for data storage.

## Instructions

### Prerequisites
- Docker Engine (20.10+)
- Docker Compose Plugin (2.0+)
- Make
- OpenSSL (for certificate generation)

### Setup

1. **Clone the repository**
   ```bash
   git clone <repository_url> ~/inception
   cd ~/inception
   ```

2. **Create required directories**
   ```bash
   mkdir -p ~/data/wordpress ~/data/mariadb
   mkdir -p secrets
   ```

3. **Generate SSL certificates**
   ```bash
   chmod +x generate-certs.sh
   ./generate-certs.sh
   ```

4. **Create secrets files**
   ```bash
   echo "your_root_password" > secrets/db_root_password.txt
   echo "your_db_password" > secrets/db_password.txt
   echo "your_admin_password" > secrets/wp_admin_password.txt
   chmod 600 secrets/*.txt
   ```

5. **Configure environment variables**
   - Edit `srcs/.env` if needed (domain name, database settings, etc.)

6. **Add domain to /etc/hosts**
   ```bash
   sudo sh -c 'echo "127.0.0.1 imoulasr.42.fr" >> /etc/hosts'
   ```

### Build and Run

```bash
make build    # Build all Docker images
make up       # Start all containers
make status   # Check container status
```

### Stop and Clean

```bash
make down     # Stop and remove containers
make clean    # Remove unused containers and images
make rebuild  # Full rebuild (down + clean + build + up)
```

### Access

- **Website**: https://imoulasr.42.fr
- **WordPress Admin**: https://imoulasr.42.fr/wp-admin

## Resources

### Official Documentation
- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose](https://docs.docker.com/compose/)
- [NGINX Documentation](https://nginx.org/en/docs/)
- [WordPress Documentation](https://wordpress.org/documentation/)
- [MariaDB Knowledge Base](https://mariadb.com/kb/en/)
- [PHP-FPM Documentation](https://www.php.net/manual/en/install.fpm.php)

### Tutorials and Articles
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Dockerizing WordPress](https://www.docker.com/blog/how-to-use-the-official-nginx-docker-image/)
- [Docker Networking](https://docs.docker.com/network/)
- [Docker Volumes](https://docs.docker.com/storage/volumes/)
- [SSL/TLS Configuration](https://ssl-config.mozilla.org/)

### AI Usage

AI tools were used in the following aspects of this project:

**Tasks Assisted by AI:**
- Documentation structure and formatting
- Debugging Docker Compose syntax issues
- Understanding PHP-FPM configuration options
- Generating explanatory comments for complex shell scripts
- Troubleshooting TLS configuration
- Creating comprehensive test scenarios

**Parts of the Project:**
- Initial Dockerfile templates were reviewed with AI for optimization
- Shell script logic for database initialization was validated
- NGINX configuration security headers were researched using AI
- Error handling in setup scripts was improved with AI suggestions

**AI Validation Process:**
All AI-generated content was:
1. Thoroughly reviewed and tested
2. Adapted to specific project requirements
3. Validated through peer review
4. Tested in multiple environments (macOS, VM)

## Project Description

### Use of Docker

This project leverages Docker containerization to create an isolated, reproducible infrastructure. Each service runs in its own container, ensuring:

- **Isolation**: Services don't interfere with each other
- **Portability**: The entire stack can run on any Docker-capable host
- **Consistency**: Development, testing, and production environments are identical
- **Scalability**: Services can be replicated and load-balanced easily

### Sources Included

The project contains:
- **Custom Dockerfiles**: One per service (nginx, wordpress, mariadb)
- **Configuration Files**: nginx.conf, php-fpm.conf, my.cnf
- **Setup Scripts**: Database initialization, WordPress configuration
- **Docker Compose**: Orchestration file defining services, networks, volumes
- **Secrets Management**: Password files and TLS certificates
- **Makefile**: Automation for building and running the stack

### Design Choices

#### Virtual Machines vs Docker

| Aspect | Virtual Machines | Docker Containers |
|--------|------------------|-------------------|
| **Resource Usage** | High (full OS per VM) | Low (shared kernel) |
| **Startup Time** | Minutes | Seconds |
| **Isolation** | Complete (hypervisor level) | Process-level |
| **Portability** | Limited (large images) | High (lightweight images) |
| **Use Case** | Full OS isolation needed | Application isolation |

**Choice**: Docker for efficient resource usage and fast deployment.

#### Secrets vs Environment Variables

| Aspect | Secrets | Environment Variables |
|--------|---------|----------------------|
| **Security** | Encrypted, not in shell history | Visible in `docker inspect`, process env |
| **Access** | Mounted as files in /run/secrets/ | Available as env vars |
| **Rotation** | Can be rotated without rebuilding | Requires container restart |
| **Best For** | Passwords, API keys, certificates | Configuration values, flags |

**Choice**: Docker secrets for passwords, environment variables for non-sensitive config.

#### Docker Network vs Host Network

| Aspect | Docker Network (Bridge) | Host Network |
|--------|------------------------|--------------|
| **Isolation** | Containers use internal IPs | Containers use host IP |
| **Port Conflicts** | No conflicts (internal ports) | Can conflict with host services |
| **Security** | Better (isolated network) | Lower (direct host access) |
| **Performance** | Slight overhead (NAT) | Direct (no NAT) |

**Choice**: Bridge network for better isolation and security.

#### Docker Volumes vs Bind Mounts

| Aspect | Named Volumes | Bind Mounts |
|--------|---------------|-------------|
| **Management** | Docker manages storage | User manages host path |
| **Portability** | Works across platforms | Path-dependent |
| **Performance** | Optimized by Docker | Direct filesystem access |
| **Permissions** | Docker handles | Manual configuration |
| **Backup** | Via Docker commands | Standard filesystem tools |

**Choice**: Named volumes with bind mount driver for data in `/home/imoulasr/data/` as required by subject.

### Architecture Overview

```
┌─────────────────────────────────────────┐
│          Host Machine (42 VM)           │
│                                         │
│  ┌───────────────────────────────────┐ │
│  │   Docker Bridge Network           │ │
│  │                                   │ │
│  │  ┌──────┐  ┌──────────┐  ┌─────┐ │ │
│  │  │NGINX │→ │WordPress │→ │Maria││ │
│  │  │:443  │  │PHP:9000  │  │DB   ││ │
│  │  └──────┘  └──────────┘  └─────┘│ │
│  │      │           │           │   │ │
│  └──────┼───────────┼───────────┼───┘ │
│         │           │           │     │
│    [TLS Cert]  [WP Files]  [Database] │
│         │           │           │     │
│    ~/secrets/  ~/data/wp/  ~/data/db/ │
└─────────────────────────────────────────┘
```

**Traffic Flow:**
1. Browser → HTTPS (443) → NGINX
2. NGINX → FastCGI (9000) → WordPress PHP-FPM
3. WordPress → MySQL Protocol (3306) → MariaDB

## Technical Highlights

- **Security**: TLSv1.2/1.3 only, Docker secrets, no hardcoded passwords
- **Performance**: PHP-FPM with FastCGI, optimized NGINX configuration
- **Reliability**: Health checks, automatic restart policies
- **Maintainability**: Modular Dockerfiles, clear separation of concerns
- **Compliance**: Follows 42 subject requirements strictly

---

**Project Version**: 5.2  
**Created**: January 2026  
**School**: 1337 Benguérir (42 Network)
