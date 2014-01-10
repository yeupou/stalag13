#!/bin/bash

if [ `basename $PWD` != "debian" ]; then cd debian ; fi
if [ `basename $PWD` != "debian" ]; then echo "No way to enter debian, exit." && exit ; fi

# major version almost never change
if [ ! $1 ]; then echo "No major version (\$1), exit." && exit ; fi
# minor change every release
if [ ! $2 ]; then echo "No version (\$2), exit." && exit ; fi
# additional change every preleases
if [ ! $3 ]; then
    VERSION=$1.$2
    COMMITS=`cat ../LATESTIS | tail -1`
else 
    VERSION=$1.$2+$3
fi

echo "stalag13-utils ($VERSION-`date +%Y%m%d`) unstable; urgency=low" > tmp
echo " " >> tmp  
if [ ! $3 ]; then
    # release
    git log --stat --name-status -n $COMMITS | grep -vE LATESTIS$\|debian/changelog$ | grep -E ^\(M\|A\|R\)"\s" | sort | uniq
    echo " "
    echo "What did you do? [Cosmetics/trivial fixes] by default"
    # changes description
    read THEHECK
    if [ "$THEHECK" == "" ]; then THEHECK="Cosmetics/trivial fixes"; fi
    echo "  * $THEHECK" >> tmp
    # files changed since latest major update
    git log --stat --name-status -n $COMMITS | grep -vE LATESTIS$\|debian/changelog$ | grep -E ^\(M\|A\|R\)"\s" | sed  "s/^\(.\)\s/    \1 /g" | sort | uniq >> tmp
else 
    # prerelease
    echo "  * Upstream prerelease" >> tmp
fi
echo " " >> tmp
echo " -- Mathieu Roy <`whoami`@`hostname -f`>  `date --rfc-822`" >> tmp
echo " " >> tmp


# release
if [ ! $3 ]; then
    cat tmp changelog.full > tmp2 && mv tmp2 changelog.full
fi
cat tmp changelog.prereleases > tmp3 && mv tmp3 changelog.prereleases

rm -f tmp*

# EOF
