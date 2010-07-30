#!/bin/bash

cd $HOME/racine
for file in `ls -a --color=never`; do 
    if [ ! -d $file ] ; then
	ln -svf $HOME/racine/$file $HOME/$file
    fi
done