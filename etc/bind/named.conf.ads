// this can be used to ban ads servers content from generating trafic on you network
// add a file /etc/cron.weekly/update-bind-ads-blocks if you want to use it with content like
//
//  #!/bin/sh
//  /usr/local/bin/update-bind-ads-blocks.pl > /etc/bind/named.conf.ads
//  /etc/init.d/bind9 reload 2>/dev/null 1>/dev/null
//
// It will overwrite this file.
