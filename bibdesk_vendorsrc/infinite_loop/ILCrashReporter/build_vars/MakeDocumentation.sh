#! /bin/sh
#
# LocalizeStrings
#  Build a localizable dictionary of text strings


mkdir -p build/Documentation
/usr/bin/headerdoc2html -o build/Documentation Source/Framework/ILCrashReporter.h
cd build/Documentation
ln -s ILCrashReporter/index.html
