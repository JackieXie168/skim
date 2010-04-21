#!/usr/bin/python

import sys
import re

fnames = sys.argv[1:]

titlenumber = re.compile(r'<title>([^:]+): (\d+|[A-Z]+)\. ')

for fname in fnames:

    f = open(fname)
    lines = f.readlines()

    teximetaline = 0
    metaline = 0
    titleline = 0

    for line in lines:
        if line[:34] == "<meta name=\"description\" content=\"":
            teximetaline = lines.index(line)
        if line[:34] == "<META NAME=\"DESCRIPTION\" CONTENT=\"":
            metaline = lines.index(line)
        if line[:7] == "<title>":
            titleline = lines.index(line)

    f.close()

    if (teximetaline > 0 and metaline > 0) or titleline > 0:

        if teximetaline > 0 and metaline > 0:

            lines[teximetaline] = lines[teximetaline][:34] + lines[metaline][34:]
            lines[metaline] = ""

        if titleline > 0:

            lines[titleline] = titlenumber.sub(r'<title>\1: ', lines[titleline], 1)

        f = open(fname, 'w')
        f.seek(0)
        for line in lines:
            f.write(line)
        f.close()
