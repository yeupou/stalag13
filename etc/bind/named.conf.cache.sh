#
# FILE DISCONTINUED HERE
# UPDATED VERSION AT
#         https://gitlab.com/yeupou/stalag13/raw/master/etc/bind/named.conf.cache.sh
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
#!/bin/sh

DNSS="192.168.1 10.0.0 10.0.1"
DOMAINS=""

# comment this if you dont cache steam
# (note: nginx cache must also cover this)
DOMAINS="$DOMAINS cs.steampowered.com content1.steampowered.com content2.steampowered.com content3.steampowered.com content4.steampowered.com content5.steampowered.com content6.steampowered.com content7.steampowered.com content8.steampowered.com content9.steampowered.com hsar.steampowered.com.edgesuite.net akamai.steamstatic.com content-origin.steampowered.com client-download.steampowered.com"
# comment this if you dont cache debian
DOMAINS="$DOMAINS http.debian.net ftp.fr.debian.org ftp.debian.org security.debian.org"
# comment this if you dont cache devuan
DOMAINS="$DOMAINS packages.devuan.org"
# comment this if you dont cache ubuntu
DOMAINS="$DOMAINS fr.archive.ubuntu.com security.ubuntu.com"

for dns in $DNSS; do
    out=named.conf.cache$dns
    echo "// build by ${0}" > $out
    echo "// re-run it commenting relevant domains if you dont cache them all" > $out
    for domain in $DOMAINS; do
	echo zone \"$domain\"  \{ type master\; notify no\; file \"/etc/bind/db.cache$dns\"\; \}\; >> $out
    done
    echo "// EOF" >> $out
done
    
# EOF
