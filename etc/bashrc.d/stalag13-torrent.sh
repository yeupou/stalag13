# Wild assumption?
if [ -d /home/torrent/watch ]; then
    TORRENT_BASEDIR=/home/torrent
else
    TORRENT_BASEDIR=/mnt/lan/gate.stalag13.ici
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

alias torrent-watch='tcdcheck && cd $TORRENT_BASEDIR/watch'
alias torwatch='torrent-watch'
alias torrent-download='tcdcheck && cd $TORRENT_BASEDIR/download'
alias tordown='torrent-download'
alias torrent-log='torrent-watch && tail -n 100 log'
alias torlog='torrent-log'
alias torrent-status='torrent-watch && cat status'
alias torstat='torrent-status'
alias torrent-finished='torrent-watch && ls *.trs+'
alias torfinish='torrent-finished'

[ ! -z "$DEBUG" ] && echo "$BASH_SOURCE sourced"
# EOF
