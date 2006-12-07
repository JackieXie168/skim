
/* style.c - Convert simple LaTeX commands using direct.cfg 

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
    2004 Scott Prahl
*/

#include <stdlib.h>
#include <string.h>
#include "main.h"
#include "direct.h"
#include "l2r_fonts.h"
#include "cfg.h"
#include "util.h"
#include "parser.h"

void InsertBasicStyle(const char *rtf, bool include_header_info)

/******************************************************************************
  purpose: uses data from style.cfg to try and insert RTF commands
           that correspond to the appropriate style sheet or character style
           for example
           		ApplyStyle("section", FALSE);
           		
        rtf="\rtfsequence,\rtfheader"
 ******************************************************************************/
{
    const char *style;
    char *comma;

    if (rtf == NULL)
        return;

    style = rtf;

/* skip over 0,0, */
    comma = strchr(style, ',') + 1;
    style = strchr(comma, ',') + 1;

    while (*style == ' ')
        style++;                /* skip blanks */

    comma = strchr(style, ',');
    if (comma == NULL)
        return;
    if (include_header_info)
        *comma = ' ';
    else
        *comma = '\0';

    while (*style != '\0') {

        if (*style == '*')
            WriteFontName(&style);
        else
            fprintRTF("%c", *style);

        style++;
    }

    *comma = ',';               /* change back to a comma */
}

static void StyleCount(char *rtfline, int *optional, int *mandated)
{
    int n;

    *optional = 0;
    *mandated = 0;

    n = sscanf(rtfline, " %d , %d ,", optional, mandated);

    if (n != 2)
        diagnostics(ERROR, "bad rtf line <%s> in style.cfg", rtfline);

    if (*optional < 0 || *optional > 9)
        diagnostics(ERROR, "bad number of optional parameters in rtf command <%s> style.cfg", rtfline);

    if (*mandated < 0 || *mandated > 9)
        diagnostics(ERROR, "bad number of mandatory parameters in rtf command <%s> style.cfg", rtfline);
}

void InsertStyle(char *command)
{
    const char *rtf;

    rtf = SearchRtfCmd(command, STYLE_A);
    if (rtf == NULL)
        diagnostics(WARNING, "Cannot find style <%s>", command);
    else
        InsertBasicStyle(rtf, FALSE);
}


bool TryStyleConvert(char *command)

/******************************************************************************
  purpose: uses data from style.cfg to try and convert some
           LaTeX commands into RTF commands using stylesheet info.  
 ******************************************************************************/
{
    char *rtf;
    char *RtfCommand;
    char *TexCommand;
    char *option[9];

/*	char *	option_header[9];*/
    char *mandatory[9];

/*	char *  mandatory_header[9];*/
    char *rtf_piece[40];
    char *comma;
    int optional;
    int mandated;
    int i;

    TexCommand = strdup_together("\\", command);
    RtfCommand = SearchRtfCmd(TexCommand, STYLE_A);
    if (RtfCommand == NULL)
        return FALSE;

    rtf = RtfCommand;
    StyleCount(rtf, &optional, &mandated);

    /* read all the optional and mandatory parameters */
    for (i = 0; i < optional; i++) {
        option[i] = getBracketParam();
    }

    for (i = 0; i < mandated; i++) {
        mandatory[i] = getBraceParam();
    }

    /* read and duplicate the RTF pieces into an array */
    for (i = 0; i < mandated + optional + 1; i++) {
        comma = strchr(rtf, ',');
        if (comma == NULL)
            diagnostics(ERROR, "Not enough commas in style command <%s>", RtfCommand);

        *comma = '\0';
        rtf_piece[i] = strdup(rtf);
        diagnostics(1, "piece %d is %s", i, rtf_piece[i]);
        *comma = ',';
        rtf = comma + 1;
    }


/* free all the pieces */
    for (i = 0; i < optional; i++) {
        if (option[i])
            free(option[i]);
    }

    for (i = 0; i < mandated; i++) {
        if (mandatory[i])
            free(mandatory[i]);
    }

    for (i = 0; i < mandated + optional + 1; i++) {
        if (rtf_piece[i])
            free(rtf_piece[i]);
    }

    free(TexCommand);
    return TRUE;
}
