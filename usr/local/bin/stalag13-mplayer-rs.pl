#!/usr/bin/perl
use strict;

# kills redshift before starting, put it back afterwards
system("killall",
       "-TERM",
       "redshift");

# starts mplayer with given args (we use perl because a basic sh would
# easily mess up here)
system("mplayer", 
       @ARGV);

# when mplayer died, restart redshift, with nohup so it is kept up even
# if this script was called in a xterm killed afterwards.
exec("nohup",
     "redshift",
     "-l 48.799:2.505",
     "-t 6500:9300",
     ">/dev/null",
     "2>/dev/null");

# EOF
