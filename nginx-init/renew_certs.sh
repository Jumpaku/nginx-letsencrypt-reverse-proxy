#!/bin/bash

DOMAINS=$(cat /DOMAINS)
STAGE=$(cat /STAGE)

NGINX_INIT="/nginx-init"

python3 -c "import re; [print(d.strip()) for d in re.split(r'\s*,\s*', '$DOMAINS')]" | while read -r LINE || [ "$LINE" ]; do

    SERVER_NAME=$(python3 -c "import re; print(re.split(r'\s*->\s*', '$LINE'.strip())[0].strip())")
    PROXY_PASS=$(python3 -c "import re; print(''.join(re.split(r'\s*->\s*', '$LINE')[1:]).strip())")

    CERT_PATH="/certificates/$STAGE/$SERVER_NAME"

    $NGINX_INIT/gen_cert.sh $STAGE $SERVER_NAME $CERT_PATH nginx
done