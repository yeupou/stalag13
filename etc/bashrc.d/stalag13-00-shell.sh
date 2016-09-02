#
# FILE DISCONTINUED HERE
# UPDATED VERSION AT
#         https://gitlab.com/yeupou/stalag13/raw/master/etc/bashrc.d/stalag13-00-shell.sh
#
#                                 |     |
#                                 \_V_//
#                                 \/=|=\/
#                                  [=v=]
#                                __\___/_____
#                               /..[  _____  ]
#                              /_  [ [  M /] ]
#                             /../.[ [ M /@] ]
#                            <-->[_[ [M /@/] ]
#                           /../ [.[ [ /@/ ] ]
#      _________________]\ /__/  [_[ [/@/ C] ]
#     <_________________>>0---]  [=\ \@/ C / /
#        ___      ___   ]/000o   /__\ \ C / /
#           \    /              /....\ \_/ /
#        ....\||/....           [___/=\___/
#       .    .  .    .          [...] [...]
#      .      ..      .         [___/ \___]
#      .    0 .. 0    .         <---> <--->
#   /\/\.    .  .    ./\/\      [..]   [..]
#
# Only for bash
[ -z "$BASH_VERSION" ] && return

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
#
# THIS MUST BE COMMENTED OUT IN /etc/bash.bashrc
#   # set a fancy prompt (non-color, overwrite the one in /etc/profile)
#   PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
showuser=''
promptcolor=$yellow
if [ "`id -u`" != 0 ]; then
    # print username only if not root
    showuser="\u@"
else 
    # use a different prompt color for root
    promptcolor=$red
fi
PS1="${promptcolor}\! ${magenta}\$(date +%H:%M) ${cyan}${showuser}\h: ${green}\w${NC}\n  ${promptcolor}"'\$'"${NC} "

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

[ ! -z "$DEBUG" ] && echo "$BASH_SOURCE sourced"
# EOF
