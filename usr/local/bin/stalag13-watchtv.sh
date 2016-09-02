#
# FILE DISCONTINUED HERE
# UPDATED VERSION AT
#         https://gitlab.com/yeupou/stalag13/raw/master/usr/local/bin/stalag13-watchtv.sh
#
#                                 |     |
#                                 \_V_//
#                                 \/=|=\/
#                                  [=v=]
#                                __\___/_____
#                               /..[  _____  ]
#                              /_  [ [  M /] ]
#                             /../.[ [ M /@] ]
#                            <-->[_[ [M /@/] ]
#                           /../ [.[ [ /@/ ] ]
#      _________________]\ /__/  [_[ [/@/ C] ]
#     <_________________>>0---]  [=\ \@/ C / /
#        ___      ___   ]/000o   /__\ \ C / /
#           \    /              /....\ \_/ /
#        ....\||/....           [___/=\___/
#       .    .  .    .          [...] [...]
#      .      ..      .         [___/ \___]
#      .    0 .. 0    .         <---> <--->
#   /\/\.    .  .    ./\/\      [..]   [..]
#
#!/bin/sh
# -ao alsa,oss,sdl,arts : le son ne passe pas par le pc
# -vo gl2 : slurp CPU
mplayer-rs -stop-xscreensaver -aspect 16:10 -ontop -dr -vo xv -ao null -framedrop -vf pp=fd -contrast 10 -brightness 5 -hue 5 -saturation 5 -tv mjpeg:norm=PAL-BG:noaudio:driver=v4l2:device=/dev/video0:input=2:width=768:height=576  -nocache -quiet 'tv://' -identify
