#!/bin/bash

if [ ! "$1" ] || [ ! -e "$1" ]; then
    echo "Impossible de trouver $1 (\$1)"
    exit
fi

cd "$1"
ls --color=always

echo "Quel(s) dossier(s), fichier(s) à archiver ?"
read TOARCH

echo "Quelle abbréviation significative (BG2 par exemple) ?"
read ABBREV

rm -f sav-$ABBREV-`date +%Y%m%d`
zip sav-$ABBREV-`date +%Y%m%d` -r $TOARCH 
scp sav-$ABBREV-`date +%Y%m%d`.zip hephaistos:/var/www/suxor/sav
rm -f sav-$ABBREV-`date +%Y%m%d`





