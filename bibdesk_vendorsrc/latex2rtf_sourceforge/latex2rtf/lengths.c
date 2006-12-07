
/* lengths.c - commands that access TeX variables that contain TeX lengths

Copyright (C) 2001-2002 The Free Software Foundation

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

This file is available from http://sourceforge.net/projects/latex2rtf/
 
Authors:
    2001-2002 Scott Prahl

By convention all the values stored should be twips  20 twips = 1 pt
*/

#include <stdlib.h>
#include <string.h>
#include "main.h"
#include "util.h"
#include "lengths.h"
#include "parser.h"

#define MAX_LENGTHS 50

struct {
    char *name;
    int distance;
} Lengths[MAX_LENGTHS];

static int iLengthCount = 0;

static int existsLength(char *s)

/**************************************************************************
     purpose: checks to see if a named TeX dimension exists
     returns: the array index of the named TeX dimension
**************************************************************************/
{
    int i = 0;

    while (i < iLengthCount && strstr(Lengths[i].name, s) == NULL)
        i++;

    if (i == iLengthCount)
        return -1;
    else
        return i;
}

static void newLength(char *s, int d)

/**************************************************************************
     purpose: allocates and initializes a named TeX dimension 
**************************************************************************/
{
    if (iLengthCount == MAX_LENGTHS) {
        diagnostics(WARNING, "Too many lengths, ignoring %s", s);
        return;
    }

    Lengths[iLengthCount].distance = d;
    Lengths[iLengthCount].name = strdup(s);

    if (Lengths[iLengthCount].name == NULL) {
        fprintf(stderr, "\nCannot allocate name for length \\%s\n", s);
        exit(1);
    }

    iLengthCount++;
}

void setLength(char *s, int d)

/**************************************************************************
     purpose: allocates (if necessary) and sets a named TeX dimension 
**************************************************************************/
{
    int i;

    i = existsLength(s);

    if (i < 0)
        newLength(s, d);
    else
        Lengths[i].distance = d;
}

int getLength(char *s)

/**************************************************************************
     purpose: retrieves a named TeX dimension 
**************************************************************************/
{
    int i;

    i = existsLength(s);

    if (i < 0) {
        diagnostics(WARNING, "No length of type %s", s);
        return 0;
    }

    return Lengths[i].distance;
}

void CmdSetTexLength(int code)
{
    int d;
    char c;

    c = getNonSpace();
    if (c == '=')               /* optional '=' */
        skipSpaces();
    else
        ungetTexChar(c);

    d = getDimension();
    diagnostics(4, "CmdSetTexLength size = %d", d);

    switch (code) {

        case SL_HOFFSET:
            setLength("hoffset", d);
            break;
        case SL_VOFFSET:
            setLength("voffset", d);
            break;
        case SL_PARINDENT:
            setLength("parindent", d);
            break;
        case SL_PARSKIP:
            setLength("parskip", d);
            break;
        case SL_BASELINESKIP:
            setLength("baselineskip", d);
            break;
        case SL_TOPMARGIN:
            setLength("topmargin", d);
            break;
        case SL_TEXTHEIGHT:
            setLength("textheight", d);
            break;
        case SL_HEADHEIGHT:
            setLength("headheight", d);
            break;
        case SL_HEADSEP:
            setLength("headsep", d);
            break;
        case SL_TEXTWIDTH:
            setLength("textwidth", d);
            break;
        case SL_ODDSIDEMARGIN:
            setLength("oddsidemargin", d);
            break;
        case SL_EVENSIDEMARGIN:
            setLength("evensidemargin", d);
            break;
    }
}
