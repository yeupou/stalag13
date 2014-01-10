# Wild assumption?
if [ -d /home/torrent/watch ]; then
    TORRENT_BASEDIR=/home/torrent
else if 
    TORRENT_BASEDIR=$LAN
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

alias torwatch='tcdcheck && cd $TORRENT_BASEDIR/watch'
alias tordown='tcdcheck && cd $TORRENT_BASEDIR/download'
alias torlog='torwatch && tail -n 100 log'
alias torstat='torwatch && cat status'
alias torfinished='torwatch && ls *.trs+'

[ ! -z "$DEBUG" ] && echo "$BASH_SOURCE sourced"
# EOF
