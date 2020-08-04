#!/bin/sh

openssl dhparam -out /var/lib/nginx/dhparam.pem 2048

echo "$DOMAINS" > /DOMAINS
echo "$STAGE" > /STAGE
RENEW_SCHED=$(python3 -c "print('$RENEW_SCHED' if '$RENEW_SCHED' else '0 0 1 * *')")
echo "Cofigure: schedule of attempts to renew certificates by '$RENEW_SCHED'"
echo "$RENEW_SCHED root /nginx-init/renew_certs.sh > /proc/\$(cat /run/nginx.pid)/fd/1 2>&1" >> /etc/crontab


NGINX_INIT="/nginx-init"

NGINX_CONF=/etc/nginx/nginx.conf
cp -f "${NGINX_INIT}/nginx.conf" "${NGINX_CONF}"
Configure() {
    ENV_VAL=$1
    CONFIG_NAME=$2
    CONFIG_VALUE=$3
    DEFAULT_VALUE=$4
    echo "'$1', '$2', '$3', '$4'"
    if [ -z "${ENV_VAL}" ]; then
        sed -i -e "s|${CONFIG_NAME}|${DEFAULT_VALUE}|g" "${NGINX_CONF}"
    else
        sed -i -e "s|${CONFIG_NAME}|${CONFIG_VALUE}|g" "${NGINX_CONF}"
        echo "Configure: ${CONFIG_VALUE}, in ${NGINX_CONF}"
    fi
}
Configure "${CLIENT_MAX_BODY_SIZE}" "CLIENT_MAX_BODY_SIZE" "client_max_body_size ${CLIENT_MAX_BODY_SIZE};" ""

python3 -c "import re; [print(d.strip()) for d in re.split(r'\s*,\s*', '$DOMAINS')]" | while read -r LINE || [ "$LINE" ]; do

    SERVER_NAME=$(python3 -c "import re; print(re.split(r'\s*->\s*', '$LINE'.strip())[0].strip())")
    PROXY_PASS=$(python3 -c "import re; print(''.join(re.split(r'\s*->\s*', '$LINE')[1:]).strip())")

    CERT_PATH="/certificates/$STAGE/$SERVER_NAME"

    $NGINX_INIT/gen_cert.sh "$STAGE" "$SERVER_NAME" "$CERT_PATH" standalone

    $NGINX_INIT/init_nginx.sh "$CERT_PATH" "$SERVER_NAME" "$PROXY_PASS"
done

echo "Start cron"
cron

echo "Start nginx"
nginx -g "daemon off;"