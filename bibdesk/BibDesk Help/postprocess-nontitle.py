#!/usr/bin/python

import sys

fnames = sys.argv[1:]

for fname in fnames:

    f = open(fname, 'r+')
    lines = f.readlines()

    teximetaline = 0
    metaline = 0

    for line in lines:
        if line[:34] == "<meta name=\"description\" content=\"":
            teximetaline = lines.index(line)
        if line[:24] == "<META NAME=\"DESCRIPTION\"":
            metaline = lines.index(line)

    if teximetaline > 0 and metaline > 0:
        lines[teximetaline] = lines[metaline]
        lines[metaline] = ""

    f.seek(0)
    for line in lines:
        f.write(line)
