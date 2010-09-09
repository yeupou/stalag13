#!/usr/bin/perl
use strict;
use POSIX qw/setsid/;

# kills redshift before starting, put it back afterwards
system("killall",
       "-TERM",
       "redshift");

# starts mplayer with given args (we use perl because a basic sh would
# easily mess up here)
system("mplayer", 
       @ARGV);

# when mplayer dies, restart redshift, with nohup so it is kept up even
# if this script was called in a xterm killed afterwards.
# (actually, mimic nohup but do not use it)
#     spawn a child,
fork();
#     die parent
exit 0;
#     free the child
setsid();
#     deal with STDIN/STDOUT
open(STDIN, "</dev/null");
open(STDOUT, ">/dev/null");
open(STDERR, ">&STDOUT");
#     exec redshift
exec("redshift",
     "-l 48.799:2.505",
     "-t 6500:9300");

# EOF
