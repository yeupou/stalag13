# tar.[bz2|gz] decompression in 4 chars. 
alias targ='tar zxvf'
alias tarb='tar jxvf'

# ls 
alias ls='ls --color'
alias ll='ls -l'
alias la='ls -A'
alias l='ls -CF'

# cleanup
function mrclean { find $1 \( -name "#*#" -or -name ".#*" -or -name "*~" -or -name ".*~" \) -exec rm -rfv {} \; }

# EOF
