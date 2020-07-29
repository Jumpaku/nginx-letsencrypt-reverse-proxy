FROM ubuntu:20.04


RUN apt update -y && \
    apt install -y curl cron nginx certbot python3-certbot-nginx

RUN openssl dhparam -out /var/lib/nginx/dhparam.pem 2048

RUN mkdir -p /var/www/default/challenges/
RUN ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

COPY ./nginx-init/ /nginx-init/

RUN chmod +x /nginx-init/entrypoint.sh && \
    chmod +x /nginx-init/renew_certs.sh

RUN echo "* * * * * root certbot renew > /proc/\$(cat /run/nginx.pid)/fd/1 2>&1" >> /etc/crontab

WORKDIR /nginx-init

CMD ["/nginx-init/entrypoint.sh"]