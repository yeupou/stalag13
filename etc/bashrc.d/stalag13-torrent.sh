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
alias torrent-download='tcdcheck && cd $TORRENT_BASEDIR/download'
alias torrent-log='watch && tail -n 100 log'
alias torrent-status='watch && cat status'
alias torrent-done='watch && ls *.trs+'

[ ! -z "$DEBUG" ] && echo "$BASH_SOURCE sourced"
# EOF
