FROM debian:12

RUN apt-get update && apt-get install -y \
    php-fpm php-mysql php-curl php-gd php-xml php-json \
    wget curl mariadb-client && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /sbin/nologin www-data || true

WORKDIR /var/www/html

RUN wget -q https://wordpress.org/latest.tar.gz && \
    tar -xzf latest.tar.gz --strip-components=1 && rm latest.tar.gz

RUN wget -q https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && mv wp-cli.phar /usr/local/bin/wp

COPY conf/php-fpm.conf /etc/php/8.2/fpm/php-fpm.conf
RUN chown -R www-data:www-data /var/www/html
RUN mkdir -p /run/php && chown www-data:www-data /run/php

COPY conf/wp-config-setup.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/wp-config-setup.sh

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/wp-config-setup.sh"]
CMD ["php-fpm8.2", "-F"]
