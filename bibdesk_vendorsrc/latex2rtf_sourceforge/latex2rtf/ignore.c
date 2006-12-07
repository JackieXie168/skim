
/* ignore.c - ignore commands found in ignore.cfg

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
#include <ctype.h>
#include <string.h>
#include "main.h"
#include "direct.h"
#include "l2r_fonts.h"
#include "cfg.h"
#include "ignore.h"
#include "funct1.h"
#include "commands.h"
#include "parser.h"
#include "convert.h"

static void IgnoreVar(void);
static void IgnoreCmd(void);

bool TryVariableIgnore(char *command)

/****************************************************************************
purpose : ignores variable-formats shown in file "ignore.cfg"
returns : TRUE if variable was ignored correctly, otherwise FALSE

#  NUMBER        simple numeric value
#  MEASURE : numeric value with following unit of measure
#  OTHER: ignores anything to the first character after '='
#	 and from there to next space. eg. \setbox\bak=\hbox
#  COMMAND       ignores anything to next '\' and from there to occurence
#	             of anything but a letter. eg. \newbox\bak
#  SINGLE        ignore single command. eg. \noindent
#  PARAMETER	 ignores a command with one paramter
#  PACKAGE		 does not produce a Warning message if PACKAGE is encountered
#  ENVCMD		 proceses contents of unknown environment as if it were plain latex
#  ENVIRONMENT   ignores contentents of that environment
 ****************************************************************************/
{
    const char *RtfCommand;
    char TexCommand[128];
    bool result = TRUE;

    if (strlen(command) >= 100) {
        diagnostics(WARNING, "Command <%s> is too long", command);
        return FALSE;           /* command too long */
    }
    TexCommand[0] = '\\';
    TexCommand[1] = '\0';
    strcat(TexCommand, command);

    RtfCommand = SearchRtfCmd(TexCommand, IGNORE_A);
    if (RtfCommand == NULL)
        result = FALSE;
    else if (strcmp(RtfCommand, "NUMBER") == 0)
        IgnoreVar();
    else if (strcmp(RtfCommand, "MEASURE") == 0)
        IgnoreVar();
    else if (strcmp(RtfCommand, "OTHER") == 0)
        IgnoreVar();
    else if (strcmp(RtfCommand, "COMMAND") == 0)
        IgnoreCmd();
    else if (strcmp(RtfCommand, "SINGLE") == 0) {
    } else if (strcmp(RtfCommand, "PARAMETER") == 0)
        CmdIgnoreParameter(No_Opt_One_NormParam);
    else if (strcmp(RtfCommand, "TWOPARAMETER") == 0)
        CmdIgnoreParameter(No_Opt_Two_NormParam);

/*	else if (strcmp(RtfCommand, "LINE") == 0) skipToEOL(); */
    else if (strcmp(RtfCommand, "ENVIRONMENT") == 0) {
        char *str;

        str = malloc(strlen(command) + 5);  /* envelope: end{..} */
        if (str == NULL)
            diagnostics(ERROR, "malloc error -> out of memory!\n");
        strcpy(str, "end{");
        strcat(str, command);
        strcat(str, "}");
        Ignore_Environment(str);
        free(str);
    } else if (strcmp(RtfCommand, "ENVCMD") == 0)
        PushEnvironment(IGN_ENV_CMD);
    else if (strcmp(RtfCommand, "PACKAGE") == 0) {
    } else
        result = FALSE;
    return (result);
}


void IgnoreVar(void)

/****************************************************************************
purpose : ignores anything till a space or a newline
 ****************************************************************************/
{
    char c;

    while ((c = getTexChar()) && c != '\n' && c != ' ') {
    }
}


void IgnoreCmd(void)

/****************************************************************************
purpose : ignores anything till an alphanumeric character
 ****************************************************************************/
{
    char c;

    while ((c = getTexChar()) && c != '\\') {
    }
    while ((c = getTexChar()) && !isalpha((int) c)) {
    }
    ungetTexChar(c);
}

void Ignore_Environment(char *cCommand)

/******************************************************************************
  purpose: function, which ignores an unconvertable environment in LaTex
           and writes text unchanged into the Rtf-file.
parameter: searchstring : includes the string to search for
	   example: \begin{unknown} ... \end{unknown}
		    searchstring="end{unknown}"
 ******************************************************************************/
{
    char unknown_environment[100];
    char *buffer;
    int font;

    diagnostics(4, "Entering IgnoreEnvironment <%s>", cCommand);

    snprintf(unknown_environment, 100, "\\%s%s%s", "end{", cCommand, "}");
    font = TexFontNumber("Typewriter");
    CmdEndParagraph(0);
    CmdStartParagraph(FIRST_PAR);
    fprintRTF("\\qc [Sorry. Ignored ");
    fprintRTF("{\\plain\\f%d\\\\begin\\{%s\\} ... \\\\end\\{%s\\}}]", font, cCommand, cCommand);
    CmdEndParagraph(0);
    CmdIndent(INDENT_INHIBIT);

    buffer = getTexUntil(unknown_environment, 0);
    ConvertString(unknown_environment);
    free(buffer);

    diagnostics(4, "Exiting IgnoreEnvironment");
}
