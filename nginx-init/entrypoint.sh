#!/bin/sh

#openssl dhparam -out /var/lib/nginx/dhparam.pem 2048

if [ ! -e /DOMAINS ]; then
    python3 -c "import re; [print(domain.strip()) for domain in re.split(r'\s*,\s*', '$DOMAINS')]" > /DOMAINS
fi

echo "Start cron"
#cron

echo "Start nginx"
nginx -g "daemon off;"