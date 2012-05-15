# tar.[bz2|gz] decompression 
alias targ='tar zxvf'
alias tarb='tar jxvf'

extract() {
    local c i

    (($#)) || return

    for i; do
        c=''

        if [[ ! -r $i ]]; then
            echo "$0: file is unreadable: \`$i'" >&2
            continue
        fi

        case $i in
            *.t@(gz|lz|xz|b@(2|z?(2))|a@(z|r?(.@(Z|bz?(2)|gz|lzma|xz))))) c='tar xvf';;
            *.7z)  c='7z x' ;;
            *.Z)   c='uncompress' ;;
            *.bz2) c='bunzip2' ;;
            *.exe) c='cabextract' ;;
            *.gz)  c='gunzip' ;;
            *.@(ace|cab)) c='unace x' ;;
            *.rar) c='unrar x' ;;
            *.xz)  c='unxz' ;;
            *.zip) c='unzip' ;;
            *)     echo "$0: unrecognized file extension: \`$i'" >&2
            continue ;;
        esac

        command $c "$i"
    done
}



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
