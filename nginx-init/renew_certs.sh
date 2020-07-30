#!/bin/bash


DOMAINS=$(cat /DOMAINS)
EMAIL=$(cat /EMAIL)
STAGE=$(cat /STAGE)

if [ -z $EMAIL ]; then
    OPT_EMAIL="--register-unsafely-without-email"
else
    OPT_EMAIL="--email $EMAIL"
fi

OPT_STAGE=""
if [ $STAGE != "production" ]; then
    OPT_STAGE="--staging"
fi

python3 -c "import re; [print(d.strip()) for d in re.split(r'\s*,\s*', '$DOMAINS')]" | while read -r LINE || [ "$LINE" ]; do
    DOMAIN=$(python3 -c "import re; print(re.split(r'\s*->\s*', '$LINE'.strip())[0].strip())")

    echo "Try update: ssl certificates for $DOMAIN"
    certbot certonly --nginx --non-interactive --quiet \
        --agree-tos \
        --keep-until-expiring \
        $OPT_EMAIL \
        $OPT_STAGE \
        --domain $DOMAIN
done

if [ -e /etc/letsencrypt/live/ ]; then 
    rm -rf /certificates/*
    cp -R --dereference /etc/letsencrypt/live/* /certificates/
fi
