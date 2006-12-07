
/* direct.c - Convert simple LaTeX commands using direct.cfg 

Copyright (C) 1995-2002 The Free Software Foundation

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
    1995-1997 Ralf Schlatterbeck
    1998-2000 Georg Lehner
    2001-2002 Scott Prahl
*/

#include <stdlib.h>
#include <string.h>
#include "main.h"
#include "direct.h"
#include "l2r_fonts.h"
#include "cfg.h"
#include "util.h"

#define MAXFONTLEN 100

void WriteFontName(const char **buffpoint)

/******************************************************************************
  purpose: reads the fontname at buffpoint and writes the appropriate font
           number into the RTF stream.  This supports the *FONTNAME* syntax
           found in direct.cfg and in style.cfg
 ******************************************************************************/
{
    char fontname[MAXFONTLEN + 1];
    int i;
    int fnumber;
    const char *buff;

    (*buffpoint)++;             /* move past initial '*' */

    buff = *buffpoint;
    if (**buffpoint == '*') {
        fprintRTF("*");
        return;
    }

    i = 0;
    while (**buffpoint != '*') {
        if ((i >= MAXFONTLEN) || (**buffpoint == '\0'))
            diagnostics(ERROR, "No terminating '*' in font name\nFound in cfg file command <%s>", buff);

        fontname[i] = **buffpoint;
        i++;
        (*buffpoint)++;
    }

    fontname[i] = '\0';
    fnumber = RtfFontNumber(fontname);

    if (fnumber < 0)
        diagnostics(ERROR, "Unknown font <%s>\nFound in cfg file command <%s>", fontname, buff);
    else
        fprintRTF("%u", (unsigned int) fnumber);
}

bool TryDirectConvert(char *command)

/******************************************************************************
  purpose: uses data from direct.cfg to try and immediately convert some
           LaTeX commands into RTF commands.  
 ******************************************************************************/
{
    const char *buffpoint;
    const char *RtfCommand;
    char *TexCommand;

    TexCommand = strdup_together("\\", command);
    RtfCommand = SearchRtfCmd(TexCommand, DIRECT_A);
    if (RtfCommand == NULL)
        return FALSE;

    buffpoint = RtfCommand;
    diagnostics(4, "Directly converting %s to %s", TexCommand, RtfCommand);
    while (buffpoint[0] != '\0') {
        if (buffpoint[0] == '*')
            WriteFontName(&buffpoint);
        else
            fprintRTF("%c", *buffpoint);

        ++buffpoint;

    }
    free(TexCommand);
    return TRUE;
}
