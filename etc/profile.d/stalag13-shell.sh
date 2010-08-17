# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# See http://www.tldp.org/HOWTO/Bash-Prompt-HOWTO/index.html
red='\[\033[0;31m\]'
RED='\[\033[1;31m\]'
green='\[\033[0;32m\]'
GREEN='\[\033[1;32m\]'
yellow='\[\033[0;33m\]'
YELLOW='\[\033[1;33m\]'
blue='\[\033[0;34m\]'
BLUE='\[\033[1;34m\]'
magenta='\[\033[0;35m\]'
MAGENTA='\[\033[1;35m\]'
cyan='\[\033[0;36m\]'
CYAN='\[\033[1;36m\]'
grey='\[\033[0;37m\]'
GREY='\[\033[1;37m\]'
NC='\[\033[0m\]'

# Nice colored prompt (with a space before the pwd, to ease copy/paste)
showuser=''
if [ "`id -u`" != 0 ]; then showuser="\u@"; fi
PS1="${yellow}\! ${magenta}\$(date +%H:%M) ${cyan}${showuser}\h: ${green}\w${NC}\n  ${yellow}"'\$'"${NC} "

# update window title only if we have an X terminal
case $TERM in
    xterm|rxvt*|konsole|aterm|wterm)
	# Why not using directly PS1?: because it mess up other things
	PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME%%.*}: ${PWD/$HOME/~}\007"'
esac	


# This shell is running under the One.
if [ "$EMACS" == "t" ]; then
 # No colors here.
    alias ls='ls --color=never'
 # must not set a window title
    unset PROMPT_COMMAND
fi