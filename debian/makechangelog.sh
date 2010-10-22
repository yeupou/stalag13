#!/bin/bash

if [ `basename $PWD` != "debian" ]; then cd debian ; fi
if [ `basename $PWD` != "debian" ]; then echo "Pas possible de rentrer dans debian, exit." && exit ; fi

if [ ! $1 ]; then echo "Pas de version précisée (\$1), exit." && exit ; fi

echo "stalag13-utils (2.$1-`date +%Y%m%d`) unstable; urgency=low" > tmp
echo " " >> tmp  
echo "  * Upstream release" >> tmp
echo " " >> tmp
echo " -- Mathieu Roy <`whoami`@`hostname -f`>  `date --rfc-822`" >> tmp
echo " " >> tmp

mv -f changelog tmp2
mv -f tmp changelog
cat tmp2 >> changelog
rm -f tmp*
