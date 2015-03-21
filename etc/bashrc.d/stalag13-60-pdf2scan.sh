function scan2pdf {
    cd ~/tmprm/scan
    FILE=$1
    [ "$FILE" == "" ] && echo "filename: " && read FILE
    [ -e "$FILE".pdf ] && return
    echo -e "\033[0;32mscanning $FILE...\033[0m"
    # scan in A4 gray with decent contrast for text 
    scanimage -l 0 -t 0 -x 215 -y 297 --mode Gray  --brightness -20 --contrast 15 --resolution=300 > "$FILE".pnm
    # convert to A4 postscript
    pnmtops -width 8.263 -height 11.69 -imagewidth 8.263 -imageheight 11.69 -dpi 300 "$FILE".pnm > "$FILE".ps
    gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/ebook -dNOPAUSE -dBATCH -sOutputFile="$FILE".pdf "$FILE".ps
    rm -f "$FILE".pnm "$FILE".ps
}

function scan2pdfs {
    cd ~/tmprm/scan
    ENDFILE=$1
    LIST=""
    [ "$ENDFILE" == "" ] && echo "filename: " && read ENDFILE
    for i in `seq --equal-width 999`; do
	scan2pdf "$ENDFILE"$i
	LIST="$LIST $ENDFILE"$i".pdf"
	beep  -f 100 -l 25
	echo -e "Another page? [\033[1;34mY\033[0m/\033[1;34mn\033[0m]"
	read NEXT
	[ "$NEXT" == "n" ] && return
	[ "$NEXT" == "N" ] && return
    done
    gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -sOutputFile="$ENDFILE".pdf -f "$ENDFILE"*.pdf
    beep  -f 100 -l 100
    echo -e "Satisfactory final PDF? [\033[1;34mY\033[0m/\033[1;34mn\033[0m]"
    read OK    
    [ "$OK" == "n" ] && return
    [ "$OK" == "N" ] && return
    rm -f $LIST
}

