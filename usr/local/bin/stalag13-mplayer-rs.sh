#!/bin/sh

# kills redshift before starting, put it back afterwards
killall -TERM redshift
# starts mplayer with given args
mplayer "$*"
# when mplayer died, restart redshift, with nohup so it is kept up even
# if this script was called in a xterm killed afterwards.
nohup redshift -l 48.799:2.505 -t 6500:9300 >/dev/null 2>/dev/null &

# EOF