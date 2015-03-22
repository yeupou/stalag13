SCAN2PDF_DIRECTORY=~/tmprm/scan
SCAN2PDF_DPI=300

# scan one A4 page and make a PDF out of it
function scan2pdf1 {
    cd $SCAN2PDF_DIRECTORY
    FILE=$1
    [ "$FILE" == "" ] && echo "filename: " && read FILE
    [ -e "$FILE".pdf ] && return
    echo -e "scanning \033[1;34m$FILE\033[0m..."
    # scan in A4 gray with decent contrast for text 
    scanimage -l 0 -t 0 -x 215 -y 297 --mode Gray  --brightness -20 --contrast 15 --resolution=$SCAN2PDF_DPI > "$FILE".pnm
    # convert to A4 postscript
    pnmtops -width 8.263 -height 11.69 -imagewidth 8.263 -imageheight 11.69 -dpi $SCAN2PDF_DPI "$FILE".pnm > "$FILE".ps
    # beep when scanning is done
    beep  -f 100 -l 25
    gs -q -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/ebook -dNOPAUSE -dBATCH -sOutputFile="$FILE".pdf "$FILE".ps
    rm -f "$FILE".pnm "$FILE".ps
}

# merge multiples PDF into one
function pdfmerge {
    ENDFILE=$1
    [ "$ENDFILE" == "" ] && echo "filename: " && read ENDFILE
    [ -e "$ENDFILE".pdf ] && return
    echo -e "merging \033[1;34m$ENDFILE*\033[0m..."
    gs -q -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -sOutputFile="$ENDFILE".pdf -f "$ENDFILE"*.pdf
    # beep when done
    beep  -f 100 -l 100
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
    [ "$ENDFILE" == "" ] && echo "filename: " && read ENDFILE
    for i in `seq --equal-width 999`; do
	scan2pdf1 "$ENDFILE"$i
	# beep when prompting user
	beep  -f 100 -l 25
	beep  -f 01 -l 25
	beep  -f 100 -l 25
	# by default scan another page
	echo -e "Another page? [\033[1;32mY\033[0m/\033[1;31mn\033[0m]"
	read NEXT
	[ "$NEXT" == "n" ] && break
	[ "$NEXT" == "N" ] && break
    done
    pdfmerge "$ENDFILE" "$ENDFILE"*.pdf
}

