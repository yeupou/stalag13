# ls 
alias ls='ls --color'
alias ll='ls -l'
alias la='ls -A'
alias l='ls -CF'

# directories (no test whatsoever; the link to the NFS server is broken, 
# the process would get stalled) 
LAN=/mnt/stalag13.ici
if [[ -d /mnt/lan/gate.stalag13.ici ]]; then LAN=/mnt/lan/gate.stalag13.ici; fi
if [[ -d /mnt/gate.stalag13.ici ]]; then LAN=/mnt/gate.stalag13.ici; fi
alias musique='cd $LAN/musique'
alias videos='cd $LAN/videos'
alias suxor='cd $LAN/suxor'


# cleanup
function mrclean { 
    find $1 \( -name "#*#" -or -name ".#*" -or -name "*~" -or -name ".*~" \) -exec rm -rfv {} \; 
}

### BASHism stuff from now on
[ -z "$BASH_VERSION" ] && return

# decompression with an unusual name (so faster completion)
pluck() {
    local c i

    (($#)) || return

    for i; do
        c=''

        if [[ ! -r $i ]]; then
            echo "$0: file is unreadable: \`$i'" >&2
            continue
        fi

        case $i in
            *.t@(gz|lz|xz|b@(2|z?(2))|a@(z|r?(.@(Z|bz?(2)|gz|lzma|xz)))) ) c='tar xvf';;
            *.7z)  c='7z x' ;;
            *.Z)   c='uncompress' ;;
            *.bz2) c='bunzip2' ;;
            *.@(exe|cab)) echo AAAA && c='cabextract' ;;
            *.gz)  c='gunzip' ;;
            *.ace) c='unace x' ;;
            *.rar) c='unrar x' ;;
            *.xz)  c='unxz' ;;
            *.zip) c='unzip' ;;
            *)    
	    echo "$0: unrecognized file extension: \`$i'" >&2
            continue ;;
        esac

        if [[ ! `which $c` ]]; then
            echo "$0: command not found: \``basename $c`'" >&2
            continue
        fi
	
        command $c "$i"
    done
}
alias extract='echo "Going to pluck()" && pluck'

[ ! -z "$DEBUG" ] && echo "$BASH_SOURCE completely sourced"
# EOF
