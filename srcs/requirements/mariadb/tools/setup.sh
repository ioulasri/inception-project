#!/bin/bash

set -e

DB_NAME="${MYSQL_DATABASE}"
DB_USER="${MYSQL_USER}"
DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
DB_PASSWORD=$(cat /run/secrets/db_password)

# Check if database is already initialized
if [ -d "/var/lib/mysql/${DB_NAME}" ]; then
    echo "Database already initialized, starting MariaDB..."
    exec mysqld --user=mysql --datadir=/var/lib/mysql
fi

echo "Starting MariaDB initialization..."

if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MariaDB data directory..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql
fi

echo "Starting MariaDB temporarily..."
mysqld --user=mysql --datadir=/var/lib/mysql --skip-networking &
MYSQL_PID=$!

echo "Waiting for MariaDB to start..."
for i in {1..30}; do
    if mysqladmin ping -hlocalhost --silent; then
        echo "MariaDB is ready!"
        break
    fi
    sleep 1
done

echo "Setting up database and users..."
mysql -hlocalhost <<-EOSQL
    ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
    DELETE FROM mysql.user WHERE User='';
    DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
    DROP DATABASE IF EXISTS test;
    DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
    
    CREATE DATABASE IF NOT EXISTS ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
    
    CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
    GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'%';
    
    FLUSH PRIVILEGES;
EOSQL

echo "Database setup completed!"

echo "Stopping temporary MariaDB..."
mysqladmin -hlocalhost -uroot -p"${DB_ROOT_PASSWORD}" shutdown

wait $MYSQL_PID

echo "Starting MariaDB..."
exec mysqld --user=mysql --datadir=/var/lib/mysql
