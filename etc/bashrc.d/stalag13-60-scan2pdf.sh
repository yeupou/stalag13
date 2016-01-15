SCAN2PDF_DIRECTORY=~/tmprm/scan
# depends on your scanner speed
SCAN2PDF_DPI=300
# depends on what your scanner backend support 
SCAN2PDF_SCANIMAGE_OPTIONS="--mode Gray --brightness -20 --contrast 15"

# beep is broken in many stupid ways on ubuntu at the moment
# this function will beep with play/sox if beep is not available
function rebeep {
    # $1 frequency
    # $2 length
    BEEP=`which beep`
    PLAY=`which play`
    # need either beep or play (sox) installed
    [ ! -x "$BEEP" ] && [ ! -x "$PLAY" ] && return
    # by default use beep if available unless we are on ubuntu
    if [ `grep ^ID=ubuntu$ /etc/os-release` ] || [ ! -x "$BEEP" ]; then
	[ ! -x "$PLAY" ] && echo "unable to run play (sox)!" && return
	($PLAY /usr/share/sounds/KDE-Im-Message-In.ogg synth .$2 $1 >/dev/null 2>/dev/null &)
    else
	[ ! -x "$BEEP" ] && echo "unable to run beep!" && return
	($BEEP -f $1 -l $2 &) 
    fi

}


# scan one A4 page and make a PDF out of it
function scan2pdf1 {
    cd $SCAN2PDF_DIRECTORY
    FILE=$1
    # prompt user if no argument passed
    [ "$FILE" == "" ] && echo "filename: " && read FILE
    echo -e "scanning \033[1;34m$FILE\033[0m... \c"
    # skip existing scan, never overwrite
    [ -e "$FILE".pdf ] && echo "exists already" && return
    # scan in A4 gray with decent contrast for text
    echo -e ">pnm \c"
    scanimage -l 0 -t 0 -x 215 -y 297 $SCAN2PDF_SCANIMAGE_OPTIONS --resolution=$SCAN2PDF_DPI > "$FILE".pnm
    # beep when scanning is done (and so when the page can be changed)
    rebeep 100 025
    # convert to A4 postscript
    echo -e ">ps \c"
    pnmtops -width 8.263 -height 11.69 -imagewidth 8.263 -imageheight 11.69 -dpi $SCAN2PDF_DPI "$FILE".pnm > "$FILE".ps
    # select /printer quality for 300dpi, /ebook for less
    echo -e ">pdf \c"
    gs -q -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/printer -dNOPAUSE -dBATCH -sOutputFile="$FILE".pdf "$FILE".ps
    rm -f "$FILE".pnm "$FILE".ps
    echo -e ""
}

# merge multiples PDF into one
function pdfmerge {
    ENDFILE=$1
    [ "$ENDFILE" == "" ] && echo "filename: " && read ENDFILE
    # skip if endfile exists already
    [ -e "$ENDFILE".pdf ] && return
    echo -e "merging \033[1;34m$ENDFILE*\033[0m..."
    gs -q -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -sOutputFile="$ENDFILE".pdf -f "$ENDFILE"*.pdf
    # beep when done
    rebeep 100 100
    # optional: remove files passed as arguments, if any
    LIST=${@:2}
    [ "$LIST" == "" ] && return    
    echo -e "Is \033[1;34m$ENDFILE\033[0m.pdf ok? [\033[1;32mY\033[0m/\033[1;31mn\033[0m]"
    read OK    
    [ "$OK" == "n" ] && return
    [ "$OK" == "N" ] && return
    rm -f $LIST
}

# scan multiple A4 pages and merge them 
function scan2pdf {
    cd $SCAN2PDF_DIRECTORY
    ENDFILE=$1
    # prompt user if no argument passed
    [ "$ENDFILE" == "" ] && echo "filename: " && read ENDFILE
    # remove any ending .pdf from the name
    ENDFILE="${ENDFILE%.pdf}" 
    ENDFILE="${ENDFILE%.PDF}"   
    # exists already? then treat it as first (000) page + ending random string
    [ -e "$ENDFILE".pdf ] && mv "$ENDFILE".pdf "$ENDFILE"`mktemp --dry-run 000eXXX`.pdf && echo -e "\033[1;34m$ENDFILE\033[0m is now \033[1;34m$ENDFILE""000\033[0m"
    # scan one page at a time
    for i in `seq --equal-width 999`; do
	scan2pdf1 "$ENDFILE"$i
	# beep when prompting user
	rebeep 100 025
	rebeep 01 025
	rebeep 100 025
	# by default scan another page
	echo -e "another page? [\033[1;32mY\033[0m/\033[1;31mn\033[0m]"
	read NEXT
	[ "$NEXT" == "n" ] && break
	[ "$NEXT" == "N" ] && break
    done
    pdfmerge "$ENDFILE" "$ENDFILE"*.pdf
}

