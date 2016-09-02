#
# FILE DISCONTINUED HERE
# UPDATED VERSION AT
#         https://gitlab.com/yeupou/stalag13/raw/master/etc/bashrc.d/stalag13-50-torrent.sh
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
# Wild assumption?
if [ -d /home/torrent/watch ]; then
    TORRENT_BASEDIR=/home/torrent
else
    TORRENT_BASEDIR=$LAN
fi

# Wild assumption?
if [ -d $TORRENT_BASEDIR/watch ]; then
    TORRENT_WATCHDIR=$TORRENT_BASEDIR/watch
else
    TORRENT_WATCHDIR=$TORRENT_BASEDIR/torrent
fi

# Run
function tcdcheck {
    if [ ! -d "$TORRENT_BASEDIR" ]; then 
	 echo "TORRENT_BASEDIR ($TORRENT_BASEDIR) does not exists."
	 echo "(It should point to the directory that contains watch & download)"
	 return 1
    fi
    return 0
}

alias torwatch='tcdcheck && cd $TORRENT_WATCHDIR'
alias tordown='tcdcheck && cd $TORRENT_BASEDIR/download'
alias torlog='torwatch && tail -n 100 log'
alias torstat='torwatch && cat status'
alias torfinished='torwatch && ls *.trs+'

[ ! -z "$DEBUG" ] && echo "$BASH_SOURCE sourced"
# EOF
