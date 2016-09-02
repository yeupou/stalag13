#
# FILE DISCONTINUED HERE
# UPDATED VERSION AT
#         https://gitlab.com/yeupou/stalag13/raw/master/usr/share/squirrelmail/plugins/custom_from/config/custom_from_access_table_example.php
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
<?php /*

#
#   Sample Custom From access table
#
#   List one user per line - each listing must identify a user's
#   exact username (as per their actual IMAP login).
#
#   Usernames can contain the wildcards * and ? which indicate
#   "any number of (or zero) characters" and "one alphanumeric
#   character" respectively.
#
#   For example, the username "jose_r*@domain.com" would match the
#   username "jose_rodriguez@domain.com" as well as
#   "jose_riviera@domain.com".
#
#   "jose?@domain.com" would match "jose5@domain.com", but not
#   "jose@domain.com", although the pattern "jose*@domain.com" would
#   match both.
#


user1@mydomain.com
user2@somewhere.org


# wildcard example
#
user?@domain.*


*/
