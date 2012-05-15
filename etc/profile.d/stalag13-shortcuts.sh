# tar.[bz2|gz] decompression in 4 chars. 
alias targ='tar zxvf'
alias tarb='tar jxvf'

# ls 
alias ls='ls --color'
alias ll='ls -l'
alias la='ls -A'
alias l='ls -CF'

# directories
if [ -d /mnt/lan/gate.stalag13.ici/musique ]; then
    alias musique='cd /mnt/lan/gate.stalag13.ici/musique'
fi
if [ -d /mnt/lan/gate.stalag13.ici/videos ]; then
    alias videos='cd /mnt/lan/gate.stalag13.ici/videos'
fi
if [ -d /mnt/lan/gate.stalag13.ici/suxor ]; then
    alias suxor='cd /mnt/lan/gate.stalag13.ici/suxor'
fi


# cleanup
function mrclean { 
    find $1 \( -name "#*#" -or -name ".#*" -or -name "*~" -or -name ".*~" \) -exec rm -rfv {} \; 
}

# EOF
