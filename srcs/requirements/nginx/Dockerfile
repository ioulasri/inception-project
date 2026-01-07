FROM debian:12

RUN apt-get update && apt-get install -y nginx openssl curl && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /sbin/nologin nginx_user

COPY conf/nginx.conf /etc/nginx/nginx.conf
RUN mkdir -p /etc/nginx/ssl

RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/key.pem \
    -out /etc/nginx/ssl/cert.pem \
    -subj "/C=MA/ST=Marrakech-safi/L=Benguerir/O=1337/CN=imoulasr.42.fr"

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]
