#! /bin/sh
#
# LocalizeStrings
#  Build a localizable dictionary of text strings

/usr/bin/genstrings -o  Source/Framework/Resources/English.lproj/ Source/Framework/*.m*
/usr/bin/genstrings -o  Source/CrashReporter/English.lproj/ Source/CrashReporter/*.m*

