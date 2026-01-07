# User Documentation - Inception

## Overview

This project provides a complete web hosting infrastructure with:
- **WordPress Website**: Modern content management system
- **HTTPS Security**: Encrypted connections via SSL/TLS
- **Database Backend**: Persistent data storage
- **Admin Dashboard**: Full website management capabilities

---

## Services Provided

### 1. WordPress Website
- **URL**: https://imoulasr.42.fr
- **Purpose**: Create and manage website content
- **Features**: Blog posts, pages, media library, themes, plugins

### 2. WordPress Administration
- **URL**: https://imoulasr.42.fr/wp-admin
- **Purpose**: Manage website settings, users, content
- **Access**: Requires admin credentials

### 3. Database Service
- **Type**: MariaDB (MySQL-compatible)
- **Purpose**: Stores all website data
- **Access**: Internal only (not publicly accessible)

### 4. Web Server
- **Type**: NGINX with HTTPS
- **Purpose**: Serves website securely
- **Protocol**: TLS 1.2 / TLS 1.3 encryption

---

## Starting the Project

### Prerequisites
Ensure the host machine has:
- Docker Engine installed and running
- At least 4GB free RAM
- At least 10GB free disk space

### Start All Services

```bash
cd ~/inception
make up
```

**Expected Output:**
```
Starting containers...
[+] Running 3/3
 ✔ Container mariadb    Healthy
 ✔ Container wordpress  Healthy
 ✔ Container nginx      Started
```

**Wait Time**: 30-60 seconds for all services to become healthy.

---

## Stopping the Project

### Stop All Services

```bash
cd ~/inception
make down
```

This stops and removes all containers but **preserves your data**.

### Complete Reset

To stop services AND remove all data:
```bash
make down
sudo rm -rf ~/data/wordpress/* ~/data/mariadb/*
```

⚠️ **Warning**: This deletes all website content and database!

---

## Accessing the Website

### Step 1: Add Domain to Hosts File

```bash
# Run once during initial setup
sudo sh -c 'echo "127.0.0.1 imoulasr.42.fr" >> /etc/hosts'
```

### Step 2: Open in Browser

Navigate to: **https://imoulasr.42.fr**

### Step 3: Accept Security Warning

Since we use a self-signed certificate, your browser will show a warning:
1. Click **"Advanced"** or **"Show Details"**
2. Click **"Proceed to imoulasr.42.fr"** or **"Accept Risk"**

This is **normal and expected** for development environments.

---

## Accessing the Administration Panel

### Login to WordPress Admin

1. Navigate to: **https://imoulasr.42.fr/wp-admin**
2. Enter your admin credentials (see Credentials section below)
3. Click **"Log In"**

### Admin Dashboard Features

Once logged in, you can:
- Create and edit posts
- Manage pages
- Upload media (images, videos)
- Install themes and plugins
- Manage users
- Configure site settings

---

## Managing Credentials

### Location of Credentials

All passwords are stored in the `secrets/` directory:

```
~/inception/secrets/
├── db_root_password.txt      # Database root password
├── db_password.txt           # WordPress database user password
├── wp_admin_password.txt     # WordPress admin password
├── cert.pem                  # SSL certificate
└── key.pem                   # SSL private key
```

### View WordPress Admin Password

```bash
cat ~/inception/secrets/wp_admin_password.txt
```

### View Database Passwords

```bash
# WordPress database user
cat ~/inception/secrets/db_password.txt

# Database root user
cat ~/inception/secrets/db_root_password.txt
```

### Change Passwords

1. Edit the password file:
   ```bash
   nano ~/inception/secrets/wp_admin_password.txt
   ```

2. Restart the services:
   ```bash
   make restart
   ```

⚠️ **Note**: Changing passwords after initial setup requires manual WordPress database updates.

---

## Checking Service Status

### View Container Status

```bash
make status
```

**Expected Output:**
```
Container Status:
NAME       SERVICE     STATUS
nginx      nginx       Up 5 minutes (healthy)
wordpress  wordpress   Up 5 minutes (healthy)
mariadb    mariadb     Up 5 minutes (healthy)
```

### Health Status Indicators

- ✅ **Up (healthy)**: Service is running correctly
- ⚠️ **Up (health: starting)**: Service is initializing
- ❌ **Unhealthy**: Service has issues, check logs
- ⏹️ **Exited**: Service has stopped

### View Service Logs

**All services:**
```bash
make logs
```

**Specific service:**
```bash
make logs-nginx       # Web server logs
make logs-wordpress   # WordPress logs
make logs-mariadb     # Database logs
```

**Exit logs**: Press `Ctrl+C`

---

## Troubleshooting

### Cannot Access Website

**Problem**: Browser shows "Site can't be reached"

**Solutions:**
1. Check if services are running: `make status`
2. Verify domain in hosts file: `grep imoulasr.42.fr /etc/hosts`
3. Restart services: `make restart`

### WordPress Shows Installation Screen

**Problem**: Website asks to install WordPress again

**Solution**: This means WordPress isn't configured yet. Wait 1-2 minutes after first `make up` for automatic setup.

### Certificate Security Warning

**Problem**: Browser shows "Your connection is not private"

**Solution**: This is **normal** for self-signed certificates. Click "Advanced" → "Proceed" to continue.

### Containers Keep Restarting

**Problem**: `make status` shows containers constantly restarting

**Solutions:**
1. Check logs: `make logs`
2. Verify secrets exist: `ls -la ~/inception/secrets/`
3. Check disk space: `df -h`
4. Rebuild: `make rebuild`

### Forgot Admin Password

**Solution:**
```bash
cat ~/inception/secrets/wp_admin_password.txt
```

---

## Data Backup

### What Data is Stored?

- **Website Files**: `~/data/wordpress/`
- **Database**: `~/data/mariadb/`

### Create Backup

```bash
# Stop services first
make down

# Backup WordPress files
tar -czf wordpress-backup-$(date +%Y%m%d).tar.gz ~/data/wordpress/

# Backup database
tar -czf database-backup-$(date +%Y%m%d).tar.gz ~/data/mariadb/

# Restart services
make up
```

### Restore Backup

```bash
# Stop services
make down

# Remove current data
sudo rm -rf ~/data/wordpress/* ~/data/mariadb/*

# Extract backups
tar -xzf wordpress-backup-YYYYMMDD.tar.gz -C ~/
tar -xzf database-backup-YYYYMMDD.tar.gz -C ~/

# Restart services
make up
```

---

## Quick Reference

### Essential Commands

| Command | Purpose |
|---------|---------|
| `make up` | Start all services |
| `make down` | Stop all services |
| `make restart` | Restart all services |
| `make status` | Check service status |
| `make logs` | View all logs |
| `make build` | Rebuild Docker images |

### URLs

| Service | URL |
|---------|-----|
| Website | https://imoulasr.42.fr |
| Admin Panel | https://imoulasr.42.fr/wp-admin |

### File Locations

| Item | Path |
|------|------|
| Project Root | `~/inception/` |
| Credentials | `~/inception/secrets/` |
| Website Data | `~/data/wordpress/` |
| Database Data | `~/data/mariadb/` |

---

## Support

For technical issues:
1. Check service logs: `make logs`
2. Review troubleshooting section above
3. Consult `DEV_DOC.md` for technical details
4. Contact system administrator

---

**Document Version**: 1.0  
**Last Updated**: January 2026
