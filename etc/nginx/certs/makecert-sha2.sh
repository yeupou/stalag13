KEY=fdqn

openssl req -newkey rsa:4096 -x509 -nodes -sha512 -days 3550 -out $KEY.pem -keyout $KEY.key
openssl x509 -in $KEY.pem -outform der -out $KEY.crt

