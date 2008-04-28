#!/bin/bash

# archivedmg (Skim)
#
# Usage: archivedmg SOURCE TARGET

source="$1"
target="$2"
[ "${source:0:1}" == "/" ] || source="${PWD}/${source}"
[ "${target:0:1}" == "/" ] || target="${PWD}/${target}"
name="${target##*/}"
name="${name%.*}"
tmpdir=`/usr/bin/mktemp -d /tmp/net.sourceforge.skim-app.XXXX`

cd "$tmpdir"
/usr/bin/hdiutil create -type SPARSE -fs "HFS+" -volname "$name" "${name}.sparseimage" && \
/usr/bin/hdiutil attach -nobrowse -mountpoint "$name" "${name}.sparseimage" && \
/bin/cp -R "$source" "$name"
/usr/bin/hdiutil detach "$name"
/usr/bin/hdiutil convert -format UDZO -o "${name}.dmg" "${name}.sparseimage" && \
/bin/cp "${name}.dmg" "$target"
/bin/rm -rf "$tmpdir"
