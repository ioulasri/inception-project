FROM debian:12

RUN apt-get update && apt-get install -y mariadb-server && rm -rf /var/lib/apt/lists/*

COPY conf/my.cnf /etc/mysql/my.cnf
RUN mkdir -p /var/lib/mysql /var/run/mysqld && \
    chown -R mysql:mysql /var/lib/mysql /var/run/mysqld

COPY tools/setup.sh /docker-entrypoint-initdb.d/setup.sh
RUN chmod +x /docker-entrypoint-initdb.d/setup.sh

VOLUME ["/var/lib/mysql"]
EXPOSE 3306

ENTRYPOINT ["/docker-entrypoint-initdb.d/setup.sh"]
