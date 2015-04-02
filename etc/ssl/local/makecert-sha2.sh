#!/bin/sh
echo "Type your server fully qualified domain name (mx.domain.net)"
read FQDN

# build up .pem and .key
openssl req -newkey rsa:4096 -x509 -nodes -sha512 -days 3550 -out $FQDN.pem -keyout $FQDN.key
# build .crt (binary der) of the .pem
openssl x509 -in $FQDN.pem -outform der -out $FQDN.crt
# read only and only for root
chmod 400 $FQDN.*

# EOF
