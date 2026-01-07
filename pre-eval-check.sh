#!/bin/bash

# Inception Project - Pre-Evaluation Check Script
# Run this before your evaluation to verify everything works

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASS=0
FAIL=0

echo -e "${BLUE}╔═══════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Inception Project - Pre-Evaluation Check        ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════╝${NC}\n"

# Check 1: Docker running
echo -e "${YELLOW}[1/12] Checking Docker is running...${NC}"
if docker ps > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Docker is running${NC}\n"
    ((PASS++))
else
    echo -e "${RED}❌ Docker is not running${NC}\n"
    ((FAIL++))
fi

# Check 2: Project structure
echo -e "${YELLOW}[2/12] Verifying project structure...${NC}"
if [ -f "Makefile" ] && [ -f "srcs/docker-compose.yml" ] && [ -f "srcs/.env" ]; then
    echo -e "${GREEN}✅ Project structure correct${NC}\n"
    ((PASS++))
else
    echo -e "${RED}❌ Missing required files${NC}\n"
    ((FAIL++))
fi

# Check 3: Dockerfiles exist
echo -e "${YELLOW}[3/12] Checking Dockerfiles...${NC}"
if [ -f "srcs/requirements/nginx/Dockerfile" ] && \
   [ -f "srcs/requirements/wordpress/Dockerfile" ] && \
   [ -f "srcs/requirements/mariadb/Dockerfile" ]; then
    echo -e "${GREEN}✅ All Dockerfiles present${NC}\n"
    ((PASS++))
else
    echo -e "${RED}❌ Missing Dockerfiles${NC}\n"
    ((FAIL++))
fi

# Check 4: Secrets exist
echo -e "${YELLOW}[4/12] Verifying secrets...${NC}"
if [ -f "secrets/db_root_password.txt" ] && \
   [ -f "secrets/db_password.txt" ] && \
   [ -f "secrets/wp_admin_password.txt" ] && \
   [ -f "secrets/cert.pem" ] && \
   [ -f "secrets/key.pem" ]; then
    echo -e "${GREEN}✅ All secrets present${NC}\n"
    ((PASS++))
else
    echo -e "${RED}❌ Missing secrets${NC}\n"
    ((FAIL++))
fi

# Check 5: .gitignore
echo -e "${YELLOW}[5/12] Checking .gitignore...${NC}"
if grep -q "srcs/.env" .gitignore && grep -q "secrets/" .gitignore; then
    echo -e "${GREEN}✅ .env and secrets in .gitignore${NC}\n"
    ((PASS++))
else
    echo -e "${RED}❌ .env or secrets not in .gitignore${NC}\n"
    ((FAIL++))
fi

# Check 6: No latest tags
echo -e "${YELLOW}[6/12] Checking for 'latest' tags in FROM statements...${NC}"
if grep -E "^FROM.*:latest" srcs/requirements/*/Dockerfile > /dev/null 2>&1; then
    echo -e "${RED}❌ Found 'latest' tag in FROM statements${NC}\n"
    ((FAIL++))
else
    echo -e "${GREEN}✅ No 'latest' tags in FROM statements${NC}\n"
    ((PASS++))
fi

# Check 7: Containers running
echo -e "${YELLOW}[7/12] Checking containers status...${NC}"
cd srcs
if docker compose ps | grep -q "nginx" && \
   docker compose ps | grep -q "wordpress" && \
   docker compose ps | grep -q "mariadb"; then
    echo -e "${GREEN}✅ All containers running${NC}\n"
    ((PASS++))
else
    echo -e "${RED}❌ Not all containers running${NC}\n"
    echo "Run: make up"
    ((FAIL++))
fi
cd ..

# Check 8: HTTPS accessible
echo -e "${YELLOW}[8/12] Testing HTTPS connection...${NC}"
if curl -sk https://localhost > /dev/null 2>&1; then
    echo -e "${GREEN}✅ HTTPS accessible${NC}\n"
    ((PASS++))
else
    echo -e "${RED}❌ HTTPS not accessible${NC}\n"
    ((FAIL++))
fi

# Check 9: Database connection
echo -e "${YELLOW}[9/12] Testing database connection...${NC}"
if docker exec wordpress mysql -h mariadb -u wpuser \
   -p$(cat secrets/db_password.txt) wordpress -e "SELECT 1;" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Database connection works${NC}\n"
    ((PASS++))
else
    echo -e "${RED}❌ Database connection failed${NC}\n"
    ((FAIL++))
fi

# Check 10: Two WordPress users
echo -e "${YELLOW}[10/12] Verifying WordPress users...${NC}"
USER_COUNT=$(docker exec wordpress mysql -h mariadb -u wpuser \
   -p$(cat secrets/db_password.txt) wordpress \
   -e "SELECT COUNT(*) FROM wp_users;" 2>/dev/null | tail -1)
if [ "$USER_COUNT" -eq 2 ]; then
    echo -e "${GREEN}✅ Exactly 2 users in database${NC}\n"
    ((PASS++))
else
    echo -e "${RED}❌ Expected 2 users, found $USER_COUNT${NC}\n"
    ((FAIL++))
fi

# Check 11: Volumes exist
echo -e "${YELLOW}[11/12] Checking persistent volumes...${NC}"
if [ -d "/Users/imadoulasri/data/wordpress" ] && \
   [ "$(ls -A /Users/imadoulasri/data/wordpress)" ] && \
   [ -d "/Users/imadoulasri/data/mariadb" ] && \
   [ "$(ls -A /Users/imadoulasri/data/mariadb)" ]; then
    echo -e "${GREEN}✅ Volumes exist and contain data${NC}\n"
    ((PASS++))
else
    echo -e "${RED}❌ Volumes missing or empty${NC}\n"
    ((FAIL++))
fi

# Check 12: TLS version
echo -e "${YELLOW}[12/12] Verifying TLS version...${NC}"
TLS_VERSION=$(echo | openssl s_client -connect localhost:443 2>&1 | grep -E "TLSv1\.[23]")
if [ -n "$TLS_VERSION" ]; then
    echo -e "${GREEN}✅ TLS 1.2/1.3 configured${NC}\n"
    ((PASS++))
else
    echo -e "${RED}❌ TLS version issue${NC}\n"
    ((FAIL++))
fi

# Summary
echo -e "${BLUE}╔═══════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║               SUMMARY                             ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════╝${NC}\n"

echo -e "${GREEN}Passed: $PASS${NC}"
echo -e "${RED}Failed: $FAIL${NC}\n"

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}╔═══════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ✅ ALL CHECKS PASSED - READY FOR EVALUATION!    ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════╝${NC}\n"
    echo -e "Your credentials:"
    echo -e "  Admin: adminer_user / $(cat secrets/wp_admin_password.txt)"
    echo -e "  User:  seconduser / SimplePass123"
    echo -e "\n  Access: https://imoulasr.42.fr\n"
else
    echo -e "${RED}╔═══════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  ⚠️  SOME CHECKS FAILED - FIX BEFORE EVAL        ║${NC}"
    echo -e "${RED}╚═══════════════════════════════════════════════════╝${NC}\n"
    echo -e "Run 'make logs' to debug issues\n"
fi
