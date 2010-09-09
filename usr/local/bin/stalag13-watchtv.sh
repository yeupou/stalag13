#!/bin/sh
# -ao alsa,oss,sdl,arts : le son ne passe pas par le pc
# -vo gl2 : slurp CPU
mplayer-rs -stop-xscreensaver -aspect 16:10 -ontop -dr -vo xv -ao null -framedrop -vf pp=fd -contrast 10 -brightness 5 -hue 5 -saturation 5 -tv mjpeg:norm=PAL-BG:noaudio:driver=v4l2:device=/dev/video0:input=2:width=768:height=576  -nocache -quiet 'tv://' -identify
