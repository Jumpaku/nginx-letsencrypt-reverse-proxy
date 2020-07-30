#!/bin/sh

CERT_PATH=$1
SERVER_NAME=$2
PROXY_PASS=$3

NGINX_INIT="/nginx-init"
TEMPLATE_INDEX="$NGINX_INIT/templates/index.html"
TEMPLATE_CONF="$NGINX_INIT/templates/DOMAIN.conf"
TEMPLATE_PROXY_SSL_CONF="$NGINX_INIT/templates/DOMAIN.proxy.ssl.conf"
TEMPLATE_STATIC_SSL_CONF="$NGINX_INIT/templates/DOMAIN.static.ssl.conf"

NGINX_CONFD="/etc/nginx/conf.d/"

echo "Configure: redirect HTTP traffic on $SERVER_NAME to HTTPS"
cat $TEMPLATE_CONF | sed -e "s|SERVER_NAME|$SERVER_NAME|g" > "$NGINX_CONFD/$SERVER_NAME.conf"

SERVER_NAME_SSL_CONF="$NGINX_CONFD/$SERVER_NAME.ssl.conf"
SSL_CERT="$CERT_PATH/cert.pem"
SSL_CERT_KEY="$CERT_PATH/privkey.pem"
if [ -n "$PROXY_PASS" ] ;then
    echo "Configure: proxy HTTPS traffic on $SERVER_NAME to $PROXY_PASS"
    cat $TEMPLATE_PROXY_SSL_CONF \
        | sed -e "s|PROXY_PASS|$PROXY_PASS|g" \
        | sed -e "s|SERVER_NAME|$SERVER_NAME|g" \
        | sed -e "s|SSL_CERT_KEY|$SSL_CERT_KEY|g" \
        | sed -e "s|SSL_CERT|$SSL_CERT|g" \
        > $SERVER_NAME_SSL_CONF
else
    echo "Configure: notify no web site exists on $SERVER_NAME"
    VHOST="/var/www/vhosts/$SERVER_NAME"
    mkdir -p $VHOST
    cat $TEMPLATE_INDEX | sed -e "s|SERVER_NAME|$SERVER_NAME|g" > "$VHOST/index.html"
    cat $TEMPLATE_STATIC_SSL_CONF \
        | sed -e "s|SERVER_NAME|$SERVER_NAME|g" \
        | sed -e "s|SSL_CERT_KEY|$SSL_CERT_KEY|g" \
        | sed -e "s|SSL_CERT|$SSL_CERT|g" \
        > $SERVER_NAME_SSL_CONF
fi
