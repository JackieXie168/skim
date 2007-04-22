#!/bin/sh

line=$1
file="$2"
project="$2"
if [ $# -gt 3 ]; then
project="$2"
fi

/usr/bin/osascript -e "tell application \"Skim\"" -e "activate" -e "display TeX line "${line}" of file \""${file}"\" in project \""${project}"\"" -e "end tell"
