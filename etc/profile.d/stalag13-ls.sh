if [ "$TERM" != "dumb" ]; then
    if [ -e "$HOME/.dircolors" ]; then 
	DIRCOLORSRC="$HOME/.dircolors"
    fi
    eval `dircolors -b $DIRCOLORSRC`
    alias ls='ls --color'
fi

alias ll='ls -l'
alias la='ls -A'
alias l='ls -CF'
