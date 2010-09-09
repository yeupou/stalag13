#!/usr/bin/perl
use strict;
use POSIX qw/setsid/;

# shut down redshift
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
my $pid = fork();
#     die parent
exit 0 if $pid;
#     free the child
setsid();
#     deal with STDIN/STDOUT
open(STDIN, "</dev/null");
open(STDOUT, ">/dev/null");
open(STDERR, ">&STDOUT");
#     make it redshift
exec("redshift",
     "-l 48.799:2.505",
     "-t 6500:9300");

# EOF
