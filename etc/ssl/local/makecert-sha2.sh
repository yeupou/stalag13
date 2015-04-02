#!/bin/sh
echo "Type your server fully qualified domain name (mx.domain.net)"
read FQDN

# build up .crt and .key
openssl req -newkey rsa:4096 -x509 -nodes -sha512 -days 3550 -out $FQDN.crt -keyout $FQDN.key
# link .crt to .pem since both extensions are often used in default setup
# (ex: exim use .crt while nginx use .pem)
ln -s $FQDN.crt $FQDN.pem
# build .der (binary der) of the .pem, sometimes necessary
openssl x509 -in $FQDN.pem -outform der -out $FQDN.der

# read only 
chmod -v 440 $FQDN.*
# try to set it to group ssl-cert
# (exim needs to be able to read the file on its own)
chgrp ssl-cert $FQDN.*

# EOF
