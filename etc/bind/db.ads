#
# FILE DISCONTINUED HERE
# UPDATED VERSION AT
#         https://gitlab.com/yeupou/stalag13/raw/master/etc/bind/db.ads
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
; File: null.zone
; Last modified: 07-10-2005

$TTL    86400   ; one day

@       IN      SOA     localhost.   root.localhost. (
                        2005071005       ; serial number YYYYMMDDNN
                        28800   ; refresh  8 hours
                        7200    ; retry    2 hours
                        864000  ; expire  10 days
                        86400 ) ; min ttl  1 day
                NS      localhost.

                A       127.0.0.1

*               IN      A       127.0.0.1
