#!/bin/sh

STAGE=$1
SERVER_NAME=$2
CERT_PATH=$3
PLUGIN=$4

echo "Generate certificate ($STAGE) for $SERVER_NAME at $CERT_PATH"

mkdir -p $CERT_PATH

if [ $STAGE != "staging" -a $STAGE != "production" ]; then
    openssl req -new -newkey rsa:2048 -nodes -out "$CERT_PATH/ca_csr.pem" -keyout "$CERT_PATH/ca_privkey.pem" -subj="/C=JP"
    openssl req -x509 -key "$CERT_PATH/ca_privkey.pem" -in "$CERT_PATH/ca_csr.pem" -out "$CERT_PATH/ca_cert.pem" -days 356

    openssl req -new -newkey rsa:2048 -nodes -out "$CERT_PATH/csr.pem" -keyout "$CERT_PATH/privkey.pem" -subj="/CN=$SERVER_NAME"
    SERIAL="0x$(echo -n $SERVER_NAME | sha256sum | awk '{print $1}')"
    openssl x509 -req -CA "$CERT_PATH/ca_cert.pem" -CAkey "$CERT_PATH/ca_privkey.pem" -set_serial $SERIAL -in "$CERT_PATH/csr.pem" -out "$CERT_PATH/cert.pem" -days 365
    cp "$CERT_PATH/cert.pem" "$CERT_PATH/chain.pem"
    cp "$CERT_PATH/cert.pem" "$CERT_PATH/fullchain.pem"
else 
    OPT_STAGE=$(python3 -c "if '$STAGE' != 'production': print('--staging') ")
    certbot certonly --$PLUGIN --non-interactive --quiet \
        --agree-tos \
        --register-unsafely-without-email \
        $OPT_STAGE \
        --domain $SERVER_NAME
    rm -f $CERT_PATH/*
    cp -R --dereference /etc/letsencrypt/live/$SERVER_NAME/* $CERT_PATH
fi
