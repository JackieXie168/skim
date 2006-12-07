#!/bin/sh
rm -rf OmniAppKit.framework
rm -rf OmniFoundation.framework
echo "Now unpacking entire frameworks"
tar zxvf OmniFrameworks.tgz
echo "Done"
