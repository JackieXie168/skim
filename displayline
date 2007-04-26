#!/bin/sh

# displayline.sh (Skim)
#
# Usage: displayline.sh LINE PDFFILE [TEXSOURCEFILE]

line=$1
file="$2"
if [ $# -gt 3 ]; then
source="$3"
else
source="$2"
fi

/usr/bin/osascript -e "tell application \"Skim\"" -e "activate" -e "display TeX line "${line}" in \""${file}"\" from source \""${source}"\"" -e "end tell"
