#!/bin/sh

date >> /updated.txt
date
NGINX_INIT="/nginx-init"
INDEX_HTML="$NGINX_INIT/templates/index.html"
DOMAIN_CONF="$NGINX_INIT/templates/DOMAIN.conf"
DOMAIN_PROXY_SSL_CONF="$NGINX_INIT/templates/DOMAIN.proxy.ssl.conf"
DOMAIN_STATIC_SSL_CONF="$NGINX_INIT/templates/DOMAIN.static.ssl.conf"

NGINX_CONFD="/etc/nginx/conf.d/"

if [ -z $EMAIL ]; then
    OPT_EMAIL="--register-unsafely-without-email"
else
    OPT_EMAIL="--email $EMAIL"
fi

OPT_STAGE=""
if [ $STAGE != "production" ]; then
    OPT_STAGE="--staging"
fi

OPT_DOMAINS="--domains "`cat /DOMAINS | python3 -c "import sys; print(','.join([l.strip().split('->')[0] for l in sys.stdin]))"`

cat /DOMAINS | while read -r LINE || [ "$LINE" ]; do
    SERVER_NAME=`python3 -c "import re; print(re.split(r'\s*->\s*', '$LINE')[0])"`
    PROXY_PASS=`python3 -c "import re; print(''.join(re.split(r'\s*->\s*', '$LINE')[1:]))"`

    cat $DOMAIN_CONF | sed -e "s|SERVER_NAME|$SERVER_NAME|g" > "$NGINX_CONFD/$SERVER_NAME.conf"

    SERVER_NAME_SSL_CONF="$NGINX_CONFD/$SERVER_NAME.ssl.conf"
    if [ "$PROXY_PASS" ] ;then
        # Proxy
        cat $DOMAIN_PROXY_SSL_CONF | sed -e "s|PROXY_PASS|$PROXY_PASS|g" | sed -e "s|SERVER_NAME|$SERVER_NAME|g" > $SERVER_NAME_SSL_CONF
    else
        # No Proxy
        VHOST="/var/www/vhosts/$SERVER_NAME"
        mkdir -p $VHOST
        cat $INDEX_HTML | sed -e "s|SERVER_NAME|$SERVER_NAME|g" > "$VHOST/index.html"
        cat $DOMAIN_STATIC_SSL_CONF | sed -e "s|SERVER_NAME|$SERVER_NAME|g" > $SERVER_NAME_SSL_CONF
    fi
done
ls -l "$NGINX_CONFD"
ls -l "/var/www/vhosts/"

echo $OPT_DOMAINS
echo "certbot certonly --nginx --non-interactive --agree-tos $OPT_EMAIL $OPT_STAGE $OPT_DOMAINS"
certbot certonly --nginx --non-interactive --agree-tos $OPT_EMAIL $OPT_STAGE $OPT_DOMAINS

#nginx -s reload