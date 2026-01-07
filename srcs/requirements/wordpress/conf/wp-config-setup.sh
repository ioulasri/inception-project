#!/bin/bash

set -e

DB_HOST="${MYSQL_DB_HOST:-mariadb}"
DB_NAME="${MYSQL_DATABASE}"
DB_USER="${MYSQL_USER}"
DB_PASSWORD=$(cat /run/secrets/db_password)
DOMAIN_NAME="${DOMAIN_NAME}"
WP_ADMIN_USER="${WP_ADMIN_USER}"
WP_ADMIN_EMAIL="${WP_ADMIN_EMAIL}"
WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)

echo "Waiting for MariaDB..."
RETRY=30
while [ $RETRY -gt 0 ]; do
    if mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" -e "SELECT 1" > /dev/null 2>&1; then
        echo "MariaDB is ready!"
        break
    fi
    sleep 2
    RETRY=$((RETRY - 1))
done

if [ ! -f /var/www/html/wp-config.php ]; then
    echo "Generating wp-config.php..."
    cd /var/www/html
    
    cat > wp-config.php <<EOF
<?php
define('DB_NAME', '$DB_NAME');
define('DB_USER', '$DB_USER');
define('DB_PASSWORD', '$DB_PASSWORD');
define('DB_HOST', '$DB_HOST');
define('DB_CHARSET', 'utf8mb4');
define('DB_COLLATE', '');
define('WP_HOME', 'https://$DOMAIN_NAME');
define('WP_SITEURL', 'https://$DOMAIN_NAME');
define('SCRIPT_DEBUG', false);

define('AUTH_KEY',         'put_your_unique_phrase_here');
define('SECURE_AUTH_KEY',  'put_your_unique_phrase_here');
define('LOGGED_IN_KEY',    'put_your_unique_phrase_here');
define('NONCE_KEY',        'put_your_unique_phrase_here');
define('AUTH_SALT',        'put_your_unique_phrase_here');
define('SECURE_AUTH_SALT', 'put_your_unique_phrase_here');
define('LOGGED_IN_SALT',   'put_your_unique_phrase_here');
define('NONCE_SALT',       'put_your_unique_phrase_here');

\$table_prefix = 'wp_';

if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', __DIR__ . '/' );
}

require_once ABSPATH . 'wp-settings.php';
EOF

    echo "wp-config.php created!"
    
    # Install WordPress if not already installed
    if ! wp core is-installed --allow-root --path=/var/www/html 2>/dev/null; then
        echo "Installing WordPress..."
        wp core install \
            --url="https://$DOMAIN_NAME" \
            --title="Inception" \
            --admin_user="$WP_ADMIN_USER" \
            --admin_password="$WP_ADMIN_PASSWORD" \
            --admin_email="$WP_ADMIN_EMAIL" \
            --allow-root \
            --path=/var/www/html
        echo "WordPress installation completed!"
    else
        echo "WordPress is already installed."
    fi
fi

echo "Starting PHP-FPM..."
exec "$@"
