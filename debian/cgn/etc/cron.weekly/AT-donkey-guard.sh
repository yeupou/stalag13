#!/bin/bash

. /etc/hosts.nib.sh
if [ ! $SERVER ]; then exit ; fi
if [ `hostname` != $SERVER ]; then exit ; fi 

su mldonkey -c "/usr/local/bin/AT-server.donkey-guard.sh"



