#!/usr/bin/python

import sys
import re
import codecs

argc = len(sys.argv)

if argc != 3:
    sys.stderr.write('error: wrong number of arguments.\n')
    exit(1)

input = sys.argv[1]
output = sys.argv[2]
    
locre = re.compile(r'^"(.*)" = "(.*)";$')
commentre = re.compile(r'^(/\*.*\*/)|(//.*)$')

inputfile = codecs.open(input, 'r', 'utf-16')
lines = inputfile.readlines()
inputfile.close()

if len (lines) > 0:
    
    outputfile = codecs.open(output, 'w', 'utf-16')
    outputfile.seek(0)
    
    foundstrings = set()
    comment = None
    
    for line in lines:
        if commentre.match(line) != None:
            comment = line
        else:
            match = locre.match(line)
            if match != None:
                string = match.group(2)
                if string not in foundstrings:
                    foundstrings.add(string)
                    outputfile.write('\n')
                    if comment != None:
                        outputfile.write(comment)
                    line = match.expand(r'"\2" = "\2";\n')
                    outputfile.write(line)
                comment = None
            elif line != '\n':
                sys.stderr.write('warning: confused about line in {0}:\n{1}\n'.format(input, line))
    
    outputfile.close()
