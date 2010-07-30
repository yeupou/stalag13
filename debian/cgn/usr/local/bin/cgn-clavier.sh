#!/bin/sh

case "$1" in
mute)
amixer set Master mute
;;

unmute)
amixer set Master unmute
;;

vol+)
amixer set Master 2%+
;;

vol-)
amixer set Master 2%-
;;

esac
exit 0 