# Virtual Machine Setup Guide for Inception Testing

This guide will help you create a VM to test your inception project in an environment similar to 42's evaluation machines.

---

## Table of Contents
1. [VM Software Options](#vm-software-options)
2. [Recommended Specifications](#recommended-specifications)
3. [Setup Instructions](#setup-instructions)
4. [Installing Dependencies](#installing-dependencies)
5. [Transferring Your Project](#transferring-your-project)
6. [Testing in VM](#testing-in-vm)
7. [Troubleshooting](#troubleshooting)

---

## VM Software Options

### For macOS (Your Current System)

**Option 1: UTM (Recommended for Apple Silicon M1/M2/M3)**
- **Pros:** Free, native Apple Silicon support, good performance
- **Cons:** Newer, less documentation than VirtualBox
- **Download:** https://mac.getutm.app/

**Option 2: VirtualBox (Recommended for Intel Macs)**
- **Pros:** Free, widely used, lots of documentation
- **Cons:** Limited Apple Silicon support
- **Download:** https://www.virtualbox.org/

**Option 3: VMware Fusion**
- **Pros:** Professional grade, excellent performance
- **Cons:** Paid (free for personal use with registration)
- **Download:** https://www.vmware.com/products/fusion.html

**Option 4: Parallels Desktop**
- **Pros:** Best performance on macOS, easy to use
- **Cons:** Paid subscription
- **Download:** https://www.parallels.com/

---

## Recommended Specifications

### Minimum VM Configuration
```
OS:        Debian 12 (Bookworm) - 64-bit
RAM:       4 GB minimum, 8 GB recommended
CPU:       2 cores minimum, 4 cores recommended
Disk:      30 GB minimum, 50 GB recommended
Network:   NAT or Bridged (for internet access)
```

### Why Debian 12?
Your project uses `debian:12` as the base image (penultimate stable), so testing on Debian 12 ensures compatibility with the exact environment your containers will run in.

---

## Setup Instructions

### Method 1: Using UTM (Apple Silicon Macs)

#### Step 1: Download Debian ISO
```bash
# Visit: https://www.debian.org/download
# Download: debian-12.x.x-arm64-netinst.iso (for Apple Silicon)
# Or: debian-12.x.x-amd64-netinst.iso (for Intel)
```

#### Step 2: Create VM in UTM
1. Open UTM
2. Click "Create a New Virtual Machine"
3. Select "Virtualize" (not Emulate)
4. Choose "Linux"
5. Browse and select the Debian ISO
6. Configure:
   - Memory: 8192 MB (8 GB)
   - CPU Cores: 4
   - Storage: 50 GB
7. Click "Save" and name it "Inception-Test"

#### Step 3: Install Debian
1. Start the VM
2. Select "Install" (not Graphical Install for faster setup)
3. Follow prompts:
   - Hostname: `inception-vm`
   - Domain: leave blank or `42.fr`
   - Root password: choose something simple for testing
   - Create user: `imoulasr` (or your 42 login)
   - Partition: "Guided - use entire disk"
   - Software selection: 
     - ✅ SSH server
     - ✅ Standard system utilities
     - ❌ Desktop environment (not needed)
4. Complete installation and reboot

---

### Method 2: Using VirtualBox (Intel Macs)

#### Step 1: Download Debian ISO
```bash
# Visit: https://www.debian.org/download
# Download: debian-12.x.x-amd64-netinst.iso
```

#### Step 2: Create VM in VirtualBox
1. Open VirtualBox
2. Click "New"
3. Configure:
   - Name: `Inception-Test`
   - Type: Linux
   - Version: Debian (64-bit)
   - Memory: 8192 MB
   - Hard disk: Create a virtual hard disk (VDI, Dynamically allocated, 50 GB)
4. Settings → Storage → Add ISO to optical drive
5. Settings → Network → Adapter 1 → NAT (or Bridged for easier access)

#### Step 3: Install Debian (Same as UTM instructions above)

---

## Installing Dependencies

Once Debian is installed and you've logged in, install the required software:

### Step 1: Update System
```bash
su -  # Switch to root
apt update && apt upgrade -y
```

### Step 2: Install Docker
```bash
# Install prerequisites
apt install -y apt-transport-https ca-certificates curl gnupg lsb-release

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Set up Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Verify installation
docker --version
docker compose version
```

### Step 3: Add User to Docker Group
```bash
# Add your user to docker group (replace imoulasr with your username)
usermod -aG docker imoulasr

# Log out and back in, or use:
newgrp docker

# Test without sudo
docker ps
```

### Step 4: Install Additional Tools
```bash
apt install -y make git vim curl wget sudo

# Add user to sudo group if needed
usermod -aG sudo imoulasr
```

### Step 5: Exit root
```bash
exit  # Back to regular user
```

---

## Transferring Your Project

### Method 1: Git (Recommended)
```bash
# In your macOS terminal (host)
cd ~/inception
git init
git add .
git commit -m "Initial commit"
git push origin main  # Push to GitHub/GitLab

# In VM
git clone https://github.com/yourusername/inception.git
cd inception
```

### Method 2: SCP (Secure Copy)
```bash
# First, find VM's IP address
# In VM:
ip addr show

# In macOS terminal:
cd ~/inception
scp -r * imoulasr@<VM_IP>:~/inception/

# Example:
scp -r * imoulasr@192.168.64.3:~/inception/
```

### Method 3: Shared Folder

**For UTM:**
1. Settings → Sharing → Enable shared directory
2. Select your inception folder
3. In VM, mount the shared folder

**For VirtualBox:**
1. Devices → Shared Folders → Add
2. Select inception folder, make auto-mount
3. In VM: `sudo mount -t vboxsf inception /mnt/inception`

### Method 4: Create Archive and Transfer
```bash
# On macOS
cd ~/inception
tar -czf inception.tar.gz ./*

# Transfer via SCP or download link, then in VM:
tar -xzf inception.tar.gz -C ~/inception/
```

---

## Testing in VM

⚠️ **Important**: In the VM, you'll use Linux paths (`/home/imoulasr/data/`) instead of macOS paths (`/Users/imadoulasri/data/`). This matches the 42 school environment exactly.

### Step 1: Setup Project Structure
```bash
cd ~/inception

# Create necessary directories (matching 42 requirements)
mkdir -p /home/imoulasr/data/wordpress /home/imoulasr/data/mariadb
mkdir -p secrets

# Create secrets files (use same passwords for consistency)
echo "RootPasswordSecure123" > secrets/db_root_password.txt
echo "WpUserPasswordSecure456" > secrets/db_password.txt
echo "AdminPasswordEOkTx9ZYnIEzoS9L" > secrets/wp_admin_password.txt

# Set permissions
chmod 600 secrets/*.txt

# Verify data directories
ls -la /home/imoulasr/data/
```

### Step 2: Verify docker-compose.yml Volume Paths
```bash
# Check that your docker-compose.yml uses correct paths
cd ~/inception/srcs
grep "device:" docker-compose.yml

# Should show:
#   device: /home/imoulasr/data/wordpress
#   device: /home/imoulasr/data/mariadb

# If it shows /Users/imadoulasri/data, you need to update it!
```

### Step 3: Update Configuration
```bash
# Edit /etc/hosts to add domain
sudo sh -c 'echo "127.0.0.1 imoulasr.42.fr" >> /etc/hosts'

# Verify
grep imoulasr.42.fr /etc/hosts
```

### Step 4: Build and Start
```bash
cd ~/inception
make build
make up
make status
```

### Step 5: Check Everything Works
```bash
# 1. Verify containers are running
docker ps

# 2. Check logs
make logs

# 3. Test HTTPS
curl -k https://localhost:443

# 4. Test from VM terminal browser (optional)
curl -k https://imoulasr.42.fr

# 5. Verify database users
docker exec wordpress mysql -h mariadb -u wpuser \
  -p$(cat secrets/db_password.txt) wordpress \
  -e "SELECT user_login FROM wp_users;"

# 6. Verify volumes exist and have content
ls -la /home/imoulasr/data/wordpress/
ls -la /home/imoulasr/data/mariadb/
```

### Step 6: Access from Host Browser (Optional)

**Find VM's IP:**
```bash
# In VM
ip addr show | grep inet
```

**Add to host /etc/hosts:**
```bash
# On macOS
sudo nano /etc/hosts
# Add line:
192.168.64.3 imoulasr.42.fr  # Replace with your VM's IP
```

**Access from macOS browser:**
- Open: https://imoulasr.42.fr

---

## Pre-Evaluation Checklist in VM

Run these commands to verify everything:

```bash
cd ~/inception

# 1. Clean slate
make down
docker system prune -af --volumes
rm -rf /home/imoulasr/data/wordpress/* /home/imoulasr/data/mariadb/*

# 2. Fresh build
make build

# 3. Start services
make up

# 4. Wait for services to be healthy
sleep 30
make status

# 5. Run all checks
./pre-eval-check.sh  # If you have this script

# 6. Manual verification
docker ps  # All 3 containers should be "Up" and "healthy"
docker images  # Check no :latest tags
ls /home/imoulasr/data/wordpress/  # Should have files
ls /home/imoulasr/data/mariadb/    # Should have files

# 7. Test persistence
make down
make up
# WordPress should still be installed (no setup page)
```

---

## Common VM Issues and Solutions

### Issue 1: VM is Slow
**Solution:**
- Increase RAM allocation (8 GB minimum)
- Increase CPU cores (4 minimum)
- Enable hardware acceleration in VM settings
- Disable unnecessary services in VM

### Issue 2: Docker Permission Denied
**Solution:**
```bash
sudo usermod -aG docker $USER
newgrp docker
# Or logout and login again
```

### Issue 3: Network Issues in VM
**Solution:**
```bash
# Check network is up
ip addr show

# Restart networking
sudo systemctl restart networking

# Test internet
ping -c 3 google.com

# Check DNS
cat /etc/resolv.conf
```

### Issue 4: Can't Access VM from Host Browser
**Solution:**
- Change VM network from NAT to Bridged
- Or setup port forwarding:
  ```bash
  # In VirtualBox: Settings → Network → Advanced → Port Forwarding
  # Host: 443 → Guest: 443
  ```

### Issue 5: Not Enough Disk Space
**Solution:**
```bash
# Clean Docker
docker system prune -af --volumes

# Check disk usage
df -h
du -sh ~/data/*

# Remove old kernels (if needed)
sudo apt autoremove
```

### Issue 6: Time Sync Issues
**Solution:**
```bash
# Install NTP
sudo apt install -y systemd-timesyncd
sudo timedatectl set-ntp true

# Verify
timedatectl
```

---

## Quick Start Commands

### Create VM Snapshot (Before Evaluation)
**VirtualBox:**
```bash
# In VirtualBox GUI: Machine → Take Snapshot
# Name it: "Clean State - Before Evaluation"
```

**UTM:**
```bash
# Not available in free version
# Use backup instead: tar the VM folder
```

### Restore to Clean State
```bash
# In VM
cd ~/inception
make down
docker system prune -af --volumes
rm -rf /home/imoulasr/data/wordpress/* /home/imoulasr/data/mariadb/*
make build
make up
```

---

## Automated Testing Script

Create this script to automate testing:

```bash
# In VM: ~/inception/vm-test.sh
#!/bin/bash

echo "🚀 Starting Inception VM Test..."

# Clean environment
echo "🧹 Cleaning environment..."
cd ~/inception
make down 2>/dev/null
docker system prune -af --volumes -f
rm -rf /home/imoulasr/data/wordpress/* /home/imoulasr/data/mariadb/*

# Build
echo "🔨 Building images..."
make build
if [ $? -ne 0 ]; then
    echo "❌ Build failed"
    exit 1
fi

# Start
echo "🚀 Starting services..."
make up
if [ $? -ne 0 ]; then
    echo "❌ Start failed"
    exit 1
fi

# Wait for health checks
echo "⏳ Waiting for services to be healthy..."
sleep 45

# Check status
echo "📊 Checking container status..."
make status

# Run tests
echo "🧪 Running tests..."

echo "1. Checking TLS..."
echo | openssl s_client -connect localhost:443 2>&1 | grep Protocol

echo "2. Checking volumes..."
ls -la /home/imoulasr/data/wordpress/ | head -5
ls -la /home/imoulasr/data/mariadb/ | head -5

echo "3. Checking network..."
docker network ls | grep inception

echo "4. Checking no infinite loops..."
docker exec nginx ps aux | head -10

echo "✅ VM Test Complete!"
```

Make it executable:
```bash
chmod +x ~/inception/vm-test.sh
```

---

## Comparison: VM vs Your Mac

| Aspect | Your Mac | VM (Debian 12) | 42 School |
|--------|----------|----------------|-----------|
| OS | macOS | Debian 12 | Debian/Ubuntu |
| Docker | Docker Desktop | Docker Engine | Docker Engine |
| File Paths | /Users/imoulasr/ | /home/imoulasr/ | /home/login/ |
| Performance | Fast | Slower | Medium |
| Network | Direct | NAT/Bridge | School Network |
| Data Location | /Users/imoulasr/data/ | /home/imoulasr/data/ | /home/login/data/ |

**Key Differences to Watch:**
1. **File path**: `/Users/` → `/home/` (CRITICAL for volumes!)
2. **Docker Desktop vs Docker Engine** (minor differences)
3. **Network configuration** may differ
4. **Data directory** must be `/home/imoulasr/data/` in VM and at 42

---

## Final Pre-Push Checklist

Before pushing to 42 repo:

```bash
# 1. Test in VM one last time
cd ~/inception
make down
make build
make up

# 2. Verify no secrets in git
git ls-files | grep -E "(\.env|secrets/)"
# Should return nothing

# 3. Check .gitignore
cat .gitignore | grep -E "(\.env|secrets)"

# 4. Verify all files are tracked
git status

# 5. Final commit
git add .
git commit -m "Final version - tested in VM"
git push origin main
```

---

## At 42 School

When you arrive at 42:

```bash
# 1. Clone your repo
git clone <your_repo_url> ~/inception
cd ~/inception

# 2. Create secrets directory and files
mkdir -p secrets
echo "your_root_password" > secrets/db_root_password.txt
echo "your_db_password" > secrets/db_password.txt
echo "your_admin_password" > secrets/wp_admin_password.txt
chmod 600 secrets/*

# 3. Create data directories (CRITICAL: Use full path)
mkdir -p /home/imoulasr/data/wordpress /home/imoulasr/data/mariadb

# Verify directories were created
ls -la /home/imoulasr/data/

# 4. Update domain in .env if needed
nano srcs/.env
# Change DOMAIN_NAME to your 42 login

# 5. Build and run
make build
make up
make status

# 6. Add domain to hosts
sudo sh -c 'echo "127.0.0.1 yourslogin.42.fr" >> /etc/hosts'
```

---

## Resources

- **Docker Documentation:** https://docs.docker.com/
- **Debian Documentation:** https://www.debian.org/doc/
- **NGINX Documentation:** https://nginx.org/en/docs/
- **WordPress CLI:** https://wp-cli.org/
- **MariaDB Documentation:** https://mariadb.com/kb/en/

---

## Summary

**What You've Accomplished:**
1. ✅ Created a VM that mirrors 42's environment
2. ✅ Installed all necessary dependencies
3. ✅ Transferred and tested your inception project
4. ✅ Verified everything works in a clean environment
5. ✅ Prepared for evaluation at 42

**Next Steps:**
1. Test in VM thoroughly
2. Fix any issues that appear
3. Push to 42's git repository
4. Do evaluation with confidence!

---

**Good luck with your evaluation! 🚀**

*Remember: Testing in a VM is exactly what evaluators will do, so if it works in your VM, it will work at 42!*
