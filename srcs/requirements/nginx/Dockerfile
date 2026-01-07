FROM debian:12

RUN apt-get update && apt-get install -y nginx openssl curl && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /sbin/nologin nginx_user

COPY conf/nginx.conf /etc/nginx/nginx.conf
RUN mkdir -p /etc/nginx/ssl

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]
