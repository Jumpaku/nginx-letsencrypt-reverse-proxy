#!/bin/sh

#openssl dhparam -out /var/lib/nginx/dhparam.pem 2048

echo $DOMAINS > /DOMAINS
echo $STAGE > /STAGE

NGINX_INIT="/nginx-init"

python3 -c "import re; [print(d.strip()) for d in re.split(r'\s*,\s*', '$DOMAINS')]" | while read -r LINE || [ "$LINE" ]; do

    echo $LINE
    SERVER_NAME=$(python3 -c "import re; print(re.split(r'\s*->\s*', '$LINE'.strip())[0].strip())")
    PROXY_PASS=$(python3 -c "import re; print(''.join(re.split(r'\s*->\s*', '$LINE')[1:]).strip())")

    CERT_PATH="/certificates/$STAGE/$SERVER_NAME"

    $NGINX_INIT/gen_cert.sh $STAGE $SERVER_NAME $CERT_PATH standalone

    $NGINX_INIT/init_nginx.sh $CERT_PATH $SERVER_NAME $PROXY_PASS
done

echo "Start cron"
cron

echo "Start nginx"
nginx -g "daemon off;"