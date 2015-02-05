#http://vimeo.com/89205175

KEY=fdqn

openssl req -new -x509 -days 3550 -nodes -out $KEY.pem -keyout $KEY.key
openssl x509 -in $KEY.pem -outform der -out $KEY.crt
