#!/usr/bin/python

import sys
import re
import codecs

argc = len(sys.argv)

if argc != 3:
    sys.stderr.write('Error: wrong number of arguments.\n')
    exit(1)

input = sys.argv[1]
output = sys.argv[2]
    
locline = re.compile(r'^"(.*)" = "(.*)";$')

inputfile = codecs.open(input, 'r', 'utf-16')
lines = inputfile.readlines()
inputfile.close()

outputfile = codecs.open(output, 'w', 'utf-16')
outputfile.seek(0)

for line in lines:
    line = locline.sub(r'"\2" = "\2";', line, 1)
    outputfile.write(line)

outputfile.close()
