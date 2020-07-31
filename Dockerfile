FROM ubuntu:20.04


RUN apt update -y && \
    apt install -y curl cron nginx certbot python3-certbot-nginx

RUN openssl dhparam -out /var/lib/nginx/dhparam.pem 2048

RUN mkdir -p /var/www/default/challenges/
RUN ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

COPY ./nginx-init/ /nginx-init/
RUN mv /nginx-init/default_server.conf /etc/nginx/conf.d/default_server.conf && \
    rm -r /etc/nginx/sites-available && \
    rm -r /etc/nginx/sites-enabled


RUN chmod +x /nginx-init/entrypoint.sh && \
    chmod +x /nginx-init/renew_certs.sh && \
    chmod +x /nginx-init/gen_cert.sh && \
    chmod +x /nginx-init/init_nginx.sh

RUN echo "13 0 * * sat root /nginx-init/renew_certs.sh > /proc/\$(cat /run/nginx.pid)/fd/1 2>&1" >> /etc/crontab

WORKDIR /nginx-init

CMD ["/nginx-init/entrypoint.sh"]