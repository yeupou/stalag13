#
# FILE DISCONTINUED HERE
# UPDATED VERSION AT
#         https://gitlab.com/yeupou/stalag13/raw/master/etc/ssl/local/makecert.DEPRECATED.sh
#
#                                 |     |
#                                 \_V_//
#                                 \/=|=\/
#                                  [=v=]
#                                __\___/_____
#                               /..[  _____  ]
#                              /_  [ [  M /] ]
#                             /../.[ [ M /@] ]
#                            <-->[_[ [M /@/] ]
#                           /../ [.[ [ /@/ ] ]
#      _________________]\ /__/  [_[ [/@/ C] ]
#     <_________________>>0---]  [=\ \@/ C / /
#        ___      ___   ]/000o   /__\ \ C / /
#           \    /              /....\ \_/ /
#        ....\||/....           [___/=\___/
#       .    .  .    .          [...] [...]
#      .      ..      .         [___/ \___]
#      .    0 .. 0    .         <---> <--->
#   /\/\.    .  .    ./\/\      [..]   [..]
#
# OUTDATED!
# http://articles.slicehost.com/2007/12/19/ubuntu-gutsy-self-signed-ssl-certific
ates-and-nginx

#KEY=webmail
KEY=nginx

openssl genrsa -des3 -out cert-$KEY.key 2048

openssl req -new -key cert-$KEY.key -out cert-$KEY.csr

cp cert-$KEY.key cert-$KEY.key.orig
openssl rsa -in cert-$KEY.key.orig -out cert-$KEY.key

openssl x509 -req -days 990 -in cert-$KEY.csr -signkey cert-$KEY.key -out cert-$KEY.crt

