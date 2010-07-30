#!/bin/sh

KERNEL=$1
NEWKERNEL=$2
if [ ! $KERNEL ] || [ ! $NEWKERNEL ] || [ ! $KERNEL ] && [ ! $NEWKERNEL ]; then
    echo "\$1 (version à patcher) ou \$2 (version du patch) non définis"
    exit
fi

# capital
cd /usr/src # juste pour être sur
if [ $KERNEL != $NEWKERNEL ]; then
    rm -rf linux-$KERNEL linux linux-$NEWKERNEL # suppr ancien dossiers
    tar xfj linux-$KERNEL.tar.bz2 # decomp source
    mv -v linux-$KERNEL linux-$NEWKERNEL # dossier source au nom ok
    ln -sf linux-$NEWKERNEL linux # symlink ok
    bzcat patch-$NEWKERNEL.bz2 | patch -p0 # patch de version
fi 


# patch lm-sensors
patch="lm-sensors"
echo "$patch ? (N)"
read void
if [ "$void" != "N" ]; then
    cd /usr/src/lm-sensors/lm-sensors
    mkpatch/mkpatch.pl . /usr/src/linux | patch -p1 -E -d /usr/src/linux
else 
    echo "$patch skipped."
fi

# patch debian logo
cd /usr/src
LOGOPATCH=kernel-patches/all/apply/debianlogo
cat $LOGOPATCH | sed s@$KERNEL@$NEWKERNEL@g > tmp 
mv -f tmp $LOGOPATCH
chmod +x $LOGOPATCH
cd linux
../$LOGOPATCH

# patch tekram dc315u
patch="tekram dc315u"
echo "$patch ? (N)"
read void
if [ "$void" != "N" ]; then
    ../kernel-patches/all/apply/tekram-dc3x5
else 
    echo "$patch skipped."
fi



