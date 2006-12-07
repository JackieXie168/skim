
/* convert.c - high level routines for LaTeX to RTF conversion

Copyright (C) 2002 The Free Software Foundation

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

TeX has six modes:
	
	MODE_VERTICAL              Building the main vertical list, from which the 
	                           pages of output are derived
	              
	MODE_INTERNAL_VERTICAL     Building a vertical list from a vbox
	
	MODE_HORIZONTAL            Building a horizontal list for a paragraph
	
	MODE_RESTICTED_HORIZONTAL  Building a horizontal list for an hbox
	
	MODE_MATH                  Building a mathematical formula to be placed in a 
	                           horizontal list
	                           
	MODE_DISPLAYMATH           Building a mathematical formula to be placed on a
	                           line by itself, temporarily interrupting the current paragraph
	                           
LaTeX has three modes: paragraph mode, math mode, or left-to-right mode.
This is not a particularly useful, since paragraph mode is a combination of
vertical and horizontal modes. 
                         
Why bother keeping track of modes?  Mostly so that paragraph indentation gets handled
correctly, as well as vertical and horizontal space.

*/

#include <string.h>
#include <stdlib.h>
#include <errno.h>
#include <ctype.h>
#include "main.h"
#include "convert.h"
#include "commands.h"
#include "chars.h"
#include "funct1.h"
#include "l2r_fonts.h"
#include "stack.h"
#include "tables.h"
#include "equation.h"
#include "direct.h"
#include "ignore.h"
#include "cfg.h"
#include "encode.h"
#include "util.h"
#include "parser.h"
#include "lengths.h"
#include "counters.h"
#include "preamble.h"

static void TranslateCommand(); /* converts commands */

static int ret = 0;
static int g_TeX_mode = MODE_VERTICAL;

char TexModeName[7][25] = { "bad", "internal vertical", "horizontal",
    "restricted horizontal", "math", "displaymath", "vertical"
};

void SetTexMode(int mode)
{
    if (abs(mode) != g_TeX_mode)
        diagnostics(4, "TeX mode changing from [%s] -> [%s]", TexModeName[g_TeX_mode], TexModeName[abs(mode)]);

    if (mode < 0) {             /* hack to allow CmdStartParagraph to set mode directly */
        g_TeX_mode = -mode;
        return;
    }

    if (g_TeX_mode == MODE_VERTICAL && mode == MODE_HORIZONTAL)
        CmdStartParagraph(ANY_PAR);

    if (g_TeX_mode == MODE_HORIZONTAL && mode == MODE_VERTICAL)
        CmdEndParagraph(0);

    g_TeX_mode = mode;
}

int GetTexMode(void)
{
    return g_TeX_mode;
}

void ConvertString(char *string)

/******************************************************************************
     purpose : converts string in TeX-format to Rtf-format
 ******************************************************************************/
{
    char temp[256];

    if (string == NULL)
        return;

    if (strlen(string) < 250)
        strncpy(temp, string, 250);
    else {
        strncpy(temp, string, 125);
        strncpy(temp + 125, "\n...\n", 5);
        strncpy(temp + 130, string + strlen(string) - 125, 125);
        temp[255] = '\0';
    }

    if (PushSource(NULL, string) == 0) {
        diagnostics(4, "Entering Convert() from StringConvert()\n******\n%s\n*****", temp);

        while (StillSource())
            Convert();

        PopSource();
        diagnostics(4, "Exiting Convert() from StringConvert()");
    }
}

void ConvertAllttString(char *s)

/******************************************************************************
     purpose : converts string in TeX-format to Rtf-format
			   according to the alltt environment, which is like
			   verbatim environment except that \, {, and } have
			   their usual meanings
******************************************************************************/
{
    char cThis;

    if (s == NULL)
        return;
    diagnostics(4, "Entering Convert() from StringAllttConvert()");

    if (PushSource(NULL, s) == 0) {

        while (StillSource()) {

            cThis = getRawTexChar();    /* it is a verbatim like environment */
            switch (cThis) {

                case '\\':
                    PushLevels();
                    TranslateCommand();
                    CleanStack();
                    break;

                case '{':
                    PushBrace();
                    fprintRTF("{");
                    break;

                case '}':
                    ret = RecursionLevel - PopBrace();
                    fprintRTF("}");
                    break;

                default:
                    putRtfChar(cThis);
                    break;
            }
        }
        PopSource();
    }
    diagnostics(4, "Exiting Convert() from StringAllttConvert()");
}

void Convert()

/****************************************************************************
purpose: converts inputfile and writes result to outputfile
globals: fTex, fRtf and all global flags for convert (see above)
 ****************************************************************************/
{
    char cThis = '\n';
    char cLast = '\0';
    char cNext;
    int mode, count, pending_new_paragraph;

    diagnostics(3, "Entering Convert ret = %d", ret);
    RecursionLevel++;
    PushLevels();

    while ((cThis = getTexChar()) && cThis != '\0') {

        if (cThis == '\n')
            diagnostics(5, "Current character is '\\n' mode = %d ret = %d level = %d", GetTexMode(), ret,
              RecursionLevel);
        else
            diagnostics(5, "Current character is '%c' mode = %d ret = %d level = %d", cThis, GetTexMode(), ret,
              RecursionLevel);

        mode = GetTexMode();

        pending_new_paragraph--;

        switch (cThis) {

            case '\\':
                PushLevels();

                TranslateCommand();

                CleanStack();

                if (ret > 0) {
                    diagnostics(5, "Exiting Convert via TranslateCommand ret = %d level = %d", ret, RecursionLevel);
                    ret--;
                    RecursionLevel--;
                    return;
                }
                break;


            case '{':
                if (mode == MODE_VERTICAL)
                    SetTexMode(MODE_HORIZONTAL);

                CleanStack();
                PushBrace();
                fprintRTF("{");
                break;

            case '}':
                CleanStack();
                ret = RecursionLevel - PopBrace();
                fprintRTF("}");
                if (ret > 0) {
                    diagnostics(5, "Exiting Convert via '}' ret = %d level = %d", ret, RecursionLevel);
                    ret--;
                    RecursionLevel--;
                    return;
                }
                break;

            case ' ':
                if (mode == MODE_VERTICAL || mode == MODE_MATH || mode == MODE_DISPLAYMATH)
                    cThis = cLast;

                else if (cLast != ' ' && cLast != '\n') {

                    if (GetTexMode() == MODE_RESTRICTED_HORIZONTAL)
                        fprintRTF("\\~");
                    else
                        fprintRTF(" ");
                }

                break;

            case '\n':
                tabcounter = 0;

                if (mode == MODE_MATH || mode == MODE_DISPLAYMATH) {

                    cNext = getNonBlank();
                    ungetTexChar(cNext);

                } else {
                    cNext = getNonSpace();

                    if (cNext == '\n') {    /* new paragraph ... skip all ' ' and '\n' */
                        pending_new_paragraph = 2;
                        CmdEndParagraph(0);
                        cNext = getNonBlank();
                        ungetTexChar(cNext);

                    } else {    /* add a space if needed */
                        ungetTexChar(cNext);
                        if (mode != MODE_VERTICAL && cLast != ' ')
                            fprintRTF(" ");
                    }
                }
                break;


            case '$':
                cNext = getTexChar();
                diagnostics(5, "Processing $, next char <%c>", cNext);

                if (cNext == '$' && GetTexMode() != MODE_MATH)
                    CmdEquation(EQN_DOLLAR_DOLLAR | ON);
                else {
                    ungetTexChar(cNext);
                    CmdEquation(EQN_DOLLAR | ON);
                }

                /* 
                   Formulas need to close all Convert() operations when they end This works for \begin{equation} but
                   not $$ since the BraceLevel and environments don't get pushed properly.  We do it explicitly here. */
                /* 
                   if (GetTexMode() == MODE_MATH || GetTexMode() == MODE_DISPLAYMATH) PushBrace(); else { ret =
                   RecursionLevel - PopBrace(); if (ret > 0) { ret--; RecursionLevel--; diagnostics(5, "Exiting Convert 
                   via Math ret = %d", ret); return; } } */
                break;

            case '&':
                if (g_processing_arrays) {
                    fprintRTF("%c", g_field_separator);
                    break;
                }

                if (GetTexMode() == MODE_MATH || GetTexMode() == MODE_DISPLAYMATH) {    /* in eqnarray */
                    fprintRTF("\\tab ");
                    g_equation_column++;
                    break;
                }

                if (g_processing_tabular) { /* in tabular */
                    actCol++;
                    fprintRTF("\\cell\\pard\\intbl\\q%c ", colFmt[actCol]);
                    break;
                }
                fprintRTF("&");
                break;

            case '~':
                fprintRTF("\\~");
                break;

            case '^':
                CmdSuperscript(0);
                break;

            case '_':
                CmdSubscript(0);
                break;

            case '-':
                if (mode == MODE_MATH || mode == MODE_DISPLAYMATH)
                    fprintRTF("-");
                else {
                    SetTexMode(MODE_HORIZONTAL);

                    count = getSameChar('-') + 1;

                    if (count == 1)
                        fprintRTF("-");
                    else if (count == 2)
                        fprintRTF("\\endash ");
                    else if (count == 3)
                        fprintRTF("\\emdash ");
                    else
                        while (count--)
                            fprintRTF("-");
                }
                break;

            case '|':
                if (mode == MODE_MATH || mode == MODE_DISPLAYMATH)
                    fprintRTF("|");
                else
                    fprintRTF("\\emdash ");
                break;

            case '\'':
                if (mode == MODE_MATH || mode == MODE_DISPLAYMATH)
                    fprintRTF("'");
                else {
                    SetTexMode(MODE_HORIZONTAL);
                    count = getSameChar('\'') + 1;
                    if (count == 2)
                        fprintRTF("\\rdblquote ");
                    else
                        while (count--)
                            fprintRTF("\\rquote ");
                }
                break;

            case '`':
                SetTexMode(MODE_HORIZONTAL);
                count = getSameChar('`') + 1;
                if (count == 2)
                    fprintRTF("\\ldblquote ");
                else
                    while (count--)
                        fprintRTF("\\lquote ");
                break;

            case '\"':
                SetTexMode(MODE_HORIZONTAL);
                if (GermanMode)
                    TranslateGerman();
                else
                    fprintRTF("\"");
                break;

            case '<':
                if (mode == MODE_VERTICAL)
                    SetTexMode(MODE_HORIZONTAL);
                if (GetTexMode() == MODE_HORIZONTAL) {
                    cNext = getTexChar();
                    if (cNext == '<') {
                        if (FrenchMode) {   /* not quite right */
                            skipSpaces();
                            cNext = getTexChar();
                            if (cNext == '~')
                                skipSpaces();
                            else
                                ungetTexChar(cNext);
                            fprintRTF("\\'ab\\~");

                        } else
                            fprintRTF("\\'ab");
                    } else {
                        ungetTexChar(cNext);
                        fprintRTF("<");
                    }
                } else
                    fprintRTF("<");

                break;

            case '>':
                if (mode == MODE_VERTICAL)
                    SetTexMode(MODE_HORIZONTAL);
                if (GetTexMode() == MODE_HORIZONTAL) {
                    cNext = getTexChar();
                    if (cNext == '>')
                        fprintRTF("\\'bb");
                    else {
                        ungetTexChar(cNext);
                        fprintRTF(">");
                    }
                } else
                    fprintRTF(">");
                break;

            case '!':
                if (mode == MODE_MATH || mode == MODE_DISPLAYMATH)
                    fprintRTF("!");
                else {
                    SetTexMode(MODE_HORIZONTAL);
                    if ((cNext = getTexChar()) && cNext == '`') {
                        fprintRTF("\\'a1 ");
                    } else {
                        fprintRTF("! ");
                        ungetTexChar(cNext);
                    }
                }
                break;

            case '?':
                SetTexMode(MODE_HORIZONTAL);
                if ((cNext = getTexChar()) && cNext == '`') {
                    fprintRTF("\\'bf ");
                } else {
                    fprintRTF("? ");
                    ungetTexChar(cNext);
                }
                break;

            case ':':
                if (mode == MODE_MATH || mode == MODE_DISPLAYMATH)
                    fprintRTF(":");
                else {
                    SetTexMode(MODE_HORIZONTAL);
                    if (FrenchMode)
                        fprintRTF("\\~:");
                    else
                        fprintRTF(":");
                }
                break;

            case '.':
                if (mode == MODE_MATH || mode == MODE_DISPLAYMATH)
                    fprintRTF(".");
                else {
                    SetTexMode(MODE_HORIZONTAL);
                    fprintRTF(".");

                    /* try to simulate double spaces after sentences */
                    cNext = getTexChar();
                    if (0 && cNext == ' ' && (isalpha((int) cLast) && !isupper((int) cLast)))
                        fprintRTF(" ");
                    ungetTexChar(cNext);
                }
                break;

            case '\t':
                diagnostics(WARNING, "This should not happen, ignoring \\t");
                cThis = ' ';
                break;

            case '\r':
                diagnostics(WARNING, "This should not happen, ignoring \\r");
                cThis = ' ';
                break;

            case '%':
                diagnostics(WARNING, "This should not happen, ignoring %%");
                cThis = ' ';
                break;

            case '(':
                if (g_processing_fields && g_escape_parent)
                    fprintRTF("\\\\(");
                else
                    fprintRTF("(");
                break;

            case ')':
                if (g_processing_fields && g_escape_parent)
                    fprintRTF("\\\\)");
                else
                    fprintRTF(")");
                break;

            case ';':
                if (g_field_separator == ';' && g_processing_fields)
                    fprintRTF("\\\\;");
                else if (FrenchMode)
                    fprintRTF("\\~;");
                else
                    fprintRTF(";");
                break;

            case ',':
                if (g_field_separator == ',' && g_processing_fields)
                    fprintRTF("\\\\,");
                else
                    fprintRTF(",");
                break;

            default:
                if (mode == MODE_MATH || mode == MODE_DISPLAYMATH) {
                	if (('a' <= cThis && cThis <= 'z') || ('A' <= cThis && cThis <= 'Z')) {
                    	if (CurrentFontSeries() == F_SERIES_BOLD)    /* do not italicize */
                        	fprintRTF("%c", cThis);
                        else if (CurrentFontShape() == F_SHAPE_MATH_UPRIGHT)
                        	fprintRTF("%c", cThis);
						else
                        	fprintRTF("{\\i %c}", cThis);
                	} else
                        fprintRTF("%c", cThis);
                

                } else {

                    SetTexMode(MODE_HORIZONTAL);
                    fprintRTF("%c", cThis);
                }
                break;
        }

        tabcounter++;
        cLast = cThis;
    }
    RecursionLevel--;
    diagnostics(5, "Exiting Convert via exhaustion ret = %d", ret);
}

void TranslateCommand()

/****************************************************************************
purpose: The function is called on a backslash in input file and
	 tries to call the command-function for the following command.
returns: success or not
globals: fTex, fRtf, command-functions have side effects or recursive calls;
         global flags for convert
 ****************************************************************************/
{
    char cCommand[MAXCOMMANDLEN];
    int i, mode;
    int cThis;


    cThis = getTexChar();
    mode = GetTexMode();

    diagnostics(5, "Beginning TranslateCommand() \\%c", cThis);

    switch (cThis) {
        case '}':
            if (mode == MODE_VERTICAL)
                SetTexMode(MODE_HORIZONTAL);
            fprintRTF("\\}");
            return;
        case '{':
            if (mode == MODE_VERTICAL)
                SetTexMode(MODE_HORIZONTAL);
            fprintRTF("\\{");
            return;
        case '#':
            if (mode == MODE_VERTICAL)
                SetTexMode(MODE_HORIZONTAL);
            fprintRTF("#");
            return;
        case '$':
            if (mode == MODE_VERTICAL)
                SetTexMode(MODE_HORIZONTAL);
            fprintRTF("$");
            return;
        case '&':
            if (mode == MODE_VERTICAL)
                SetTexMode(MODE_HORIZONTAL);
            fprintRTF("&");
            return;
        case '%':
            if (mode == MODE_VERTICAL)
                SetTexMode(MODE_HORIZONTAL);
            fprintRTF("%%");
            return;
        case '_':
            if (mode == MODE_VERTICAL)
                SetTexMode(MODE_HORIZONTAL);
            fprintRTF("_");
            return;

        case '\\':             /* \\[1mm] or \\*[1mm] possible */
            CmdSlashSlash(0);
            return;

        case ' ':
        case '\n':
            if (mode == MODE_VERTICAL)
                SetTexMode(MODE_HORIZONTAL);
            fprintRTF(" ");     /* ordinary interword space */
            skipSpaces();
            return;

/* \= \> \< \+ \- \' \` all have different meanings in a tabbing environment */

        case '-':
            if (mode == MODE_VERTICAL)
                SetTexMode(MODE_HORIZONTAL);
            if (g_processing_tabbing) {
                (void) PopBrace();
                PushBrace();
            } else
                fprintRTF("\\-");
            return;

        case '+':
            if (mode == MODE_VERTICAL)
                SetTexMode(MODE_HORIZONTAL);
            if (g_processing_tabbing) {
                (void) PopBrace();
                PushBrace();
            }
            return;

        case '<':
            if (mode == MODE_VERTICAL)
                SetTexMode(MODE_HORIZONTAL);
            if (g_processing_tabbing) {
                (void) PopBrace();
                PushBrace();
            }
            return;

        case '>':
            if (mode == MODE_VERTICAL)
                SetTexMode(MODE_HORIZONTAL);
            if (g_processing_tabbing) {
                (void) PopBrace();
                CmdTabjump();
                PushBrace();
            } else
                CmdSpace(0.50); /* medium space */
            return;

        case '`':
            if (mode == MODE_VERTICAL)
                SetTexMode(MODE_HORIZONTAL);
            if (g_processing_tabbing) {
                (void) PopBrace();
                PushBrace();
            } else
                CmdLApostrophChar(0);
            return;

        case '\'':
            if (mode == MODE_VERTICAL)
                SetTexMode(MODE_HORIZONTAL);
            if (g_processing_tabbing) {
                (void) PopBrace();
                PushBrace();
                return;
            } else
                CmdRApostrophChar(0);   /* char ' =?= \' */
            return;

        case '=':
            if (mode == MODE_VERTICAL)
                SetTexMode(MODE_HORIZONTAL);
            if (g_processing_tabbing) {
                (void) PopBrace();
                CmdTabset();
                PushBrace();
            } else
                CmdMacronChar(0);
            return;

        case '~':
            if (mode == MODE_VERTICAL)
                SetTexMode(MODE_HORIZONTAL);
            CmdTildeChar(0);
            return;
        case '^':
            if (mode == MODE_VERTICAL)
                SetTexMode(MODE_HORIZONTAL);
            
            cThis = getTexChar();
            if (cThis=='^') {		/* replace \^^M with space */
            	cThis = getTexChar();
            	fprintRTF(" ");
            } else {
            	ungetTexChar(cThis);
				CmdHatChar(0);
            }
            return;
        case '.':
            if (mode == MODE_VERTICAL)
                SetTexMode(MODE_HORIZONTAL);
            CmdDotChar(0);
            return;
        case '\"':
            if (mode == MODE_VERTICAL)
                SetTexMode(MODE_HORIZONTAL);
            CmdUmlauteChar(0);
            return;
        case '(':
            CmdEquation(EQN_RND_OPEN | ON);
            /* PushBrace(); */
            return;
        case '[':
            CmdEquation(EQN_BRACKET_OPEN | ON);
            /* PushBrace(); */
            return;
        case ')':
            CmdEquation(EQN_RND_CLOSE | OFF);
            /* ret = RecursionLevel - PopBrace(); */
            return;
        case ']':
            CmdEquation(EQN_BRACKET_CLOSE | OFF);
            /* ret = RecursionLevel - PopBrace(); */
            return;
        case '/':
            CmdIgnore(0);       /* italic correction */
            return;
        case '!':
            CmdIgnore(0);       /* \! negative thin space */
            return;
        case ',':
            if (mode == MODE_VERTICAL)
                SetTexMode(MODE_HORIZONTAL);
            CmdSpace(0.33);     /* \, produces a small space */
            return;
        case ';':
            if (mode == MODE_VERTICAL)
                SetTexMode(MODE_HORIZONTAL);
            CmdSpace(0.75);     /* \; produces a thick space */
            return;
        case '@':
            CmdIgnore(0);       /* \@ produces an "end of sentence" space */
            return;
        case '3':
            if (mode == MODE_VERTICAL)
                SetTexMode(MODE_HORIZONTAL);
            fprintRTF("{\\'df}");   /* german symbol 'á' */
            return;
    }


    /* LEG180498 Commands consist of letters and can have an optional * at the end */
    for (i = 0; i < MAXCOMMANDLEN-1; i++) {
        if (!isalpha((int) cThis) && (cThis != '*')) {
            bool found_nl = FALSE;

            if (cThis == '%') { /* put the % back and get the next char */
                ungetTexChar('%');
                cThis = getTexChar();
            }

            /* all spaces after commands are ignored, a single \n may occur */
            while (cThis == ' ' || (cThis == '\n' && !found_nl)) {
                if (cThis == '\n')
                    found_nl = TRUE;
                cThis = getTexChar();
            }

            ungetTexChar(cThis);    /* put back first non-space char after command */
            break;              /* done skipping spaces */
        } else
            cCommand[i] = cThis;

        cThis = getRawTexChar();    /* Necessary because % ends a command */
    }

    cCommand[i] = '\0';         /* mark end of string with zero */
    diagnostics(5, "TranslateCommand() <%s>", cCommand);

	if (i==MAXCOMMANDLEN-1) {
	    diagnostics(WARNING, "Skipping absurdly long command <%s>", cCommand);
	    return;
	}

    if (i == 0)
        return;

    if (strcmp(cCommand, "begin") == 0) {
        fprintRTF("{");
        PushBrace();
    }

    if (CallCommandFunc(cCommand)) {    /* call handling function for command */
        if (strcmp(cCommand, "end") == 0) {
            ret = RecursionLevel - PopBrace();
            fprintRTF("}");
        }
        return;
    }

    if (TryDirectConvert(cCommand))
        return;

    if (TryVariableIgnore(cCommand))
        return;

    diagnostics(WARNING, "Command \\%s not found - ignored", cCommand);
}
