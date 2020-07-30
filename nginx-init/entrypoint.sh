#!/bin/sh

#openssl dhparam -out /var/lib/nginx/dhparam.pem 2048

echo $DOMAINS > /DOMAINS
echo $EMAIL > /EMAIL
echo $STAGE > /STAGE

if [ -z $EMAIL ]; then
    OPT_EMAIL="--register-unsafely-without-email"
else
    OPT_EMAIL="--email $EMAIL"
fi

OPT_STAGE=""
if [ $STAGE != "production" ]; then
    OPT_STAGE="--staging"
fi


NGINX_INIT="/nginx-init"
TEMPLATE_INDEX="$NGINX_INIT/templates/index.html"
TEMPLATE_CONF="$NGINX_INIT/templates/DOMAIN.conf"
TEMPLATE_PROXY_SSL_CONF="$NGINX_INIT/templates/DOMAIN.proxy.ssl.conf"
TEMPLATE_STATIC_SSL_CONF="$NGINX_INIT/templates/DOMAIN.static.ssl.conf"

python3 -c "import re; [print(d.strip()) for d in re.split(r'\s*,\s*', '$DOMAINS')]" | while read -r LINE || [ "$LINE" ]; do
    SERVER_NAME=$(python3 -c "import re; print(re.split(r'\s*->\s*', '$LINE'.strip())[0].strip())")
    PROXY_PASS=$(python3 -c "import re; print(''.join(re.split(r'\s*->\s*', '$LINE')[1:]).strip())")

    echo "Generate: ssl certificates for $SERVER_NAME"
    certbot certonly --standalone --non-interactive --quiet \
        --agree-tos \
        --keep-until-expiring \
        $OPT_EMAIL \
        $OPT_STAGE \
        --domain $SERVER_NAME

    NGINX_CONFD="/etc/nginx/conf.d/"

    echo "Configure: redirect HTTP traffic to HTTPS"
    cat $TEMPLATE_CONF | sed -e "s|SERVER_NAME|$SERVER_NAME|g" > "$NGINX_CONFD/$SERVER_NAME.conf"

    SERVER_NAME_SSL_CONF="$NGINX_CONFD/$SERVER_NAME.ssl.conf"
    if [ "$PROXY_PASS" ] ;then
        echo "Configure: proxy HTTPS traffic to $PROXY_PASS"
        cat $TEMPLATE_PROXY_SSL_CONF | sed -e "s|PROXY_PASS|$PROXY_PASS|g" | sed -e "s|SERVER_NAME|$SERVER_NAME|g" > $SERVER_NAME_SSL_CONF
    else
        echo "Configure: notify no web site"
        VHOST="/var/www/vhosts/$SERVER_NAME"
        mkdir -p $VHOST
        cat $TEMPLATE_INDEX | sed -e "s|SERVER_NAME|$SERVER_NAME|g" > "$VHOST/index.html"
        cat $TEMPLATE_STATIC_SSL_CONF | sed -e "s|SERVER_NAME|$SERVER_NAME|g" > $SERVER_NAME_SSL_CONF
    fi
done

if [ -e /etc/letsencrypt/live/ ]; then 
    rm -rf /certificates/*
    cp -R --dereference /etc/letsencrypt/live/* /certificates/
fi

echo "Start cron"
cron

echo "Start nginx"
nginx -g "daemon off;"