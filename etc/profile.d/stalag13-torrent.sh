# Wild assumption
TORRENT_BASEDIR=/mnt/lan/gate.stalag13.ici

# Run
function tcdcheck {
    if [ ! -d "$TORRENT_BASEDIR" ]; then 
	 echo "TORRENT_BASEDIR ($TORRENT_BASEDIR) does not exists."
	 return 1
    fi
    return 0
}

alias tcd='tcdcheck && cd $TORRENT_BASEDIR/watch'
alias tcdd='tcdcheck && cd $TORRENT_BASEDIR/download'
alias tl='tcd && tail -n 100 log'
alias ts='tcd && cat status'
alias t='tcd && ls *.trs'
alias t+='tcd && ls *.trs+'

# EOF
