#!/bin/bash
#
# Copyright (c) 2010 Mathieu Roy <yeupou--gnu.org>
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307
#   USA

# Set codecs used to reencode:
MENCODER_OPTS="-oac lavc -ovc x264"
FFMPEG_OPTS="-vcodec libx264 -vpre normal -acodec libvorbis"


# Start logging
echo -e `date`":\n" >> dir2x264log

# Go thru the list of files here
LIST="*.avi *.mpg *.mpeg *.mkv"
for file in $LIST; do
    if [ -e "$file" ]; then
	# save original filesize
	MEMO="\t$file "`ls -sh "$file" | cut -d " " -f 1`" ->";

	# determine current file format
	ext=${file##*.}

	# set newfile name
	newfile=`basename "$file" .$ext`
	newfile="$newfile.mp4"

       	if [ $ext != "mkv" ]; then
	    # usual run
	    #BUGGYmencoder "$file" $MENCODER_OPTS -o "$newfile";
	    ffmpeg -i "$file" $FFMPEG_OPTS "$newfile"
	else
	    # Workaround for MKV:
	    # mencoder sometimes complains about
	    #   "Too many audio packets in the buffer",
	    # being unable to process the MKV file.
	    # The workaround consist of extract the audio stream and 
	    # then reincorporate it. Clumsy but it works.

	    # separate audio and video with ffmpeg, as mplayer may be as 
	    # unreliable as mencoder
	    rm -f temp.wav temp.mkv
	    ffmpeg -i "$file" -vn -acodec pcm_s16le temp.wav
	    ffmpeg -i "$file" -an -vcodec copy temp.mkv

	    # reencode
	    mencoder -audiofile temp.wav temp.mkv $MENCODER_OPTS -o "$newfile";

	    # remove the temp files
	    rm -f temp.wav temp.mkv
	fi

	# log original file size plus new filesize
	echo -e "$MEMO "`ls -sh "$newfile" | cut -d " " -f 1` >> dir2x264log
    fi
done

# log overal space gain, assuming that all mp4 were issued by this script
echo -e "\n\t\t\t "`du -shc $LIST 2>> /dev/null| tail -n 1 | cut -d " " -f 1`" => "`du -shc *.mp4 2>> /dev/null| tail -n 1 | cut -d \t -f 1`"\n\n" >> dir2x264log