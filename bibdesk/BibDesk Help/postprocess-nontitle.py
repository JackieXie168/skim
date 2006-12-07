#!/usr/bin/python

import sys

fnames = sys.argv[1:]

for fname in fnames:

    f = open(fname)
    lines = f.readlines()

    teximetaline = 0
    metaline = 0

    for line in lines:
        if line[:34] == "<meta name=\"description\" content=\"":
            teximetaline = lines.index(line)
        if line[:34] == "<META NAME=\"DESCRIPTION\" CONTENT=\"":
            metaline = lines.index(line)

    f.close()

    if teximetaline > 0 and metaline > 0:

        lines[teximetaline] = lines[teximetaline][:34] + lines[metaline][34:]
        lines[metaline] = ""

        f = open(fname, 'w')
        f.seek(0)
        for line in lines:
            f.write(line)
        f.close()
