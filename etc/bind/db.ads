; File: null.zone
; Last modified: 07-10-2005

$TTL    86400   ; one day

@       IN      SOA     localhost.   root.localhost. (
                        2005071005       ; serial number YYYYMMDDNN
                        28800   ; refresh  8 hours
                        7200    ; retry    2 hours
                        864000  ; expire  10 days
                        86400 ) ; min ttl  1 day
                NS      localhost.

                A       127.0.0.1

*               IN      A       127.0.0.1
