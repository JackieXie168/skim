
/* parser.c - parser for LaTeX code

Copyright (C) 1998-2002 The Free Software Foundation

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
    1998-2000 Georg Lehner
    2001-2002 Scott Prahl
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#include "main.h"
#include "commands.h"
#include "cfg.h"
#include "stack.h"
#include "util.h"
#include "parser.h"
#include "l2r_fonts.h"
#include "lengths.h"
#include "definitions.h"
#include "funct1.h"

typedef struct InputStackType {
    char *string;
    char *string_start;
    FILE *file;
    char *file_name;
    long file_line;
} InputStackType;

#define PARSER_SOURCE_MAX 100

static InputStackType g_parser_stack[PARSER_SOURCE_MAX];

static int g_parser_depth = -1;
static char *g_parser_string = "stdin";
static FILE *g_parser_file = NULL;
static int g_parser_line = 1;
static int g_parser_include_level = 0;

static char g_parser_currentChar;   /* Global current character */
static char g_parser_lastChar;
static char g_parser_penultimateChar;
static int g_parser_backslashes;

#define TRACK_LINE_NUMBER_MAX 10
static int g_track_line_number_stack[TRACK_LINE_NUMBER_MAX];
static int g_track_line_number = -1;

static void parseBracket();

void PushTrackLineNumber(int flag)

/***************************************************************************
 purpose:    set whether or not line numbers should be tracked in LaTeX source file
****************************************************************************/
{
    if (g_track_line_number >= TRACK_LINE_NUMBER_MAX)
        diagnostics(ERROR, "scan ahead stack too large! Sorry.");

    g_track_line_number++;
    g_track_line_number_stack[g_track_line_number] = flag;
}

void PopTrackLineNumber(void)

/***************************************************************************
 purpose:    restore last state of line numbers tracking in LaTeX source file
****************************************************************************/
{
    if (g_track_line_number < 0)
        diagnostics(ERROR, "scan ahead stack too small! Sorry.");

    g_track_line_number--;
}

int CurrentLineNumber(void)

/***************************************************************************
 purpose:     returns the current line number of the text being processed
****************************************************************************/
{
    return g_parser_line;
}

void UpdateLineNumber(char *s)

/***************************************************************************
 purpose:    advances the line number for each '\n' in s
****************************************************************************/
{
    if (s == NULL)
        return;

    while (*s != '\0') {
        if (*s == '\n')
            g_parser_line++;
        s++;
    }
}

char *CurrentFileName(void)

/***************************************************************************
 purpose:     returns the filename of the text being processed
****************************************************************************/
{
    char *s = "(Not set)";

    if (g_parser_stack[g_parser_depth].file_name)
        return g_parser_stack[g_parser_depth].file_name;
    else
        return s;
}

/*
	The following two routines allow parsing of multiple files and strings
*/

int PushSource(char *filename, char *string)

/***************************************************************************
 purpose:     change the source used by getRawTexChar() to either file or string
 			  --> pass NULL for unused argument (both NULL means use stdin)
 			  --> PushSource duplicates string
****************************************************************************/
{
    char s[50];
    FILE *p = NULL;
    char *name = NULL;
    int i;
    int line = 1;

    if (0) {
        diagnostics(1, "Before PushSource** line=%d, g_parser_depth=%d, g_parser_include_level=%d",
          g_parser_line, g_parser_depth, g_parser_include_level);
        for (i = 0; i <= g_parser_depth; i++) {
            if (g_parser_stack[i].file)
                diagnostics(1, "i=%d file   =%s, line=%d", i, g_parser_stack[i].file_name, g_parser_stack[i].file_line);

            else {
                strncpy(s, g_parser_stack[i].string, 25);
                diagnostics(1, "i=%d string =%s, line=%d", i, s, g_parser_stack[i].file_line);
            }
        }
    }

    /* save current values for linenumber and string */
    if (g_parser_depth >= 0) {
        g_parser_stack[g_parser_depth].file_line = g_parser_line;
        g_parser_stack[g_parser_depth].string = g_parser_string;
    }

    /* first test to see if we should use stdin */
    if ((filename == NULL || strcmp(filename, "-") == 0) && string == NULL) {
        g_parser_include_level++;
        g_parser_line = 1;
        name = strdup("stdin");
        p = stdin;

        /* if not then try to open a file */
    } else if (filename) {
        p = my_fopen(filename, "rb");
        if (p == NULL)
            return 1;
        g_parser_include_level++;
        g_parser_line = 1;

    } else {
        name = CurrentFileName();
        line = CurrentLineNumber();
    }

    g_parser_depth++;

    if (g_parser_depth >= PARSER_SOURCE_MAX)
        diagnostics(ERROR, "More than %d PushSource() calls", (int) PARSER_SOURCE_MAX);

    g_parser_string = (string) ? strdup(string) : NULL;
    g_parser_stack[g_parser_depth].string = g_parser_string;
    g_parser_stack[g_parser_depth].string_start = g_parser_string;
    g_parser_stack[g_parser_depth].file = p;
    g_parser_stack[g_parser_depth].file_line = line;
    g_parser_stack[g_parser_depth].file_name = name;
    g_parser_file = p;
    g_parser_string = g_parser_stack[g_parser_depth].string;

    if (g_parser_file) {
        diagnostics(5, "Opening Source File %s", g_parser_stack[g_parser_depth].file_name);
    } else {
        strncpy(s, g_parser_string, 25);
        diagnostics(5, "Opening Source string <%s>", s);
    }

    if (0) {
        diagnostics(1, "After PushSource** line=%d, g_parser_depth=%d, g_parser_include_level=%d",
          g_parser_line, g_parser_depth, g_parser_include_level);
        for (i = 0; i <= g_parser_depth; i++) {
            if (g_parser_stack[i].file)
                diagnostics(1, "i=%d file   =%s, line=%d", i, g_parser_stack[i].file_name, g_parser_stack[i].file_line);

            else {
                strncpy(s, g_parser_stack[i].string, 25);
                diagnostics(1, "i=%d string =%s, line=%d", i, s, g_parser_stack[i].file_line);
            }
        }
    }
    return 0;
}

int StillSource(void)

/***************************************************************************
 purpose:     figure out if text remains to be processed
****************************************************************************/
{
    if (g_parser_file)
        return (!feof(g_parser_file));
    else
        return (*g_parser_string != '\0');
}

void EndSource(void)
{
    if (g_parser_file)
        fseek(g_parser_file, 0, SEEK_END);
    else
        *g_parser_string = NULL;

    return;
}

void PopSource(void)

/***************************************************************************
 purpose:     return to the previous source 
****************************************************************************/
{
    char s[50];
    int i;

    if (g_parser_depth < 0)
        diagnostics(ERROR, "More PopSource() calls than PushSource() ");

    if (0) {
        diagnostics(1, "Before PopSource** line=%d, g_parser_depth=%d, g_parser_include_level=%d",
          g_parser_line, g_parser_depth, g_parser_include_level);
        for (i = 0; i <= g_parser_depth; i++) {
            if (g_parser_stack[i].file)
                diagnostics(1, "i=%d file   =%s, line=%d", i, g_parser_stack[i].file_name, g_parser_stack[i].file_line);

            else {
                strncpy(s, g_parser_stack[i].string, 25);
                diagnostics(1, "i=%d string =%s, line=%d", i, s, g_parser_stack[i].file_line);
            }
        }
    }

    if (g_parser_file) {
        diagnostics(5, "Closing Source File %s", g_parser_stack[g_parser_depth].file_name);
        fclose(g_parser_file);
        free(g_parser_stack[g_parser_depth].file_name);
        g_parser_stack[g_parser_depth].file_name = NULL;
        g_parser_include_level--;
    }

    if (g_parser_string) {
        if (strlen(g_parser_stack[g_parser_depth].string_start) < 49)
            strcpy(s, g_parser_stack[g_parser_depth].string_start);
        else {
            strncpy(s, g_parser_stack[g_parser_depth].string_start, 49);
            s[49] = '\0';
        }

        diagnostics(5, "Closing Source string <%s>", s);
        free(g_parser_stack[g_parser_depth].string_start);
        g_parser_stack[g_parser_depth].string_start = NULL;
    }

    g_parser_depth--;

    if (g_parser_depth >= 0) {
        g_parser_string = g_parser_stack[g_parser_depth].string;
        g_parser_file = g_parser_stack[g_parser_depth].file;
    }

    if (g_parser_file && 0) {
        g_parser_line = g_parser_stack[g_parser_depth].file_line;
    }

    if (g_parser_file)
        diagnostics(5, "Resuming Source File %s", g_parser_stack[g_parser_depth].file_name);
    else {
        strncpy(s, g_parser_string, 25);
        diagnostics(5, "Resuming Source string <%s>", s);
    }

    if (0) {
        diagnostics(1, "After PopSource** line=%d, g_parser_depth=%d, g_parser_include_level=%d",
          g_parser_line, g_parser_depth, g_parser_include_level);
        for (i = 0; i <= g_parser_depth; i++) {
            if (g_parser_stack[i].file)
                diagnostics(1, "i=%d file   =%s, line=%d", i, g_parser_stack[i].file_name, g_parser_stack[i].file_line);

            else {
                strncpy(s, g_parser_stack[i].string, 25);
                diagnostics(1, "i=%d string =%s, line=%d", i, s, g_parser_stack[i].file_line);
            }
        }
    }
}

#define CR (char) 0x0d
#define LF (char) 0x0a

char getRawTexChar()

/***************************************************************************
 purpose:     get the next character from the input stream with minimal
              filtering  (CRLF or CR or LF ->  \n) and '\t' -> ' '
			  it also keeps track of the line number
              should only be used by \verb and \verbatim and getTexChar()
****************************************************************************/
{
    int thechar;

    if (g_parser_file) {
        thechar = getc(g_parser_file);
        if (thechar == EOF)
            if (!feof(g_parser_file))
                diagnostics(ERROR, "Unknown file I/O error reading latex file\n");
            else if (g_parser_include_level > 1) {
                PopSource();    /* go back to parsing parent */
                thechar = getRawTexChar();  /* get next char from parent file */
            } else
                thechar = '\0';
        else if (thechar == CR) {   /* convert CR, CRLF, or LF to \n */
            thechar = getc(g_parser_file);
            if (thechar != LF && !feof(g_parser_file))
                ungetc(thechar, g_parser_file);
            thechar = '\n';
        } else if (thechar == LF)
            thechar = '\n';
        else if (thechar == '\t')
            thechar = ' ';

        g_parser_currentChar = (char) thechar;

    } else {                    /* no need to sanitize strings! */
        if (g_parser_string && *g_parser_string) {
            g_parser_currentChar = *g_parser_string;
            g_parser_string++;
        } else
            g_parser_currentChar = '\0';
    }

    if (g_parser_currentChar == '\n' && g_track_line_number_stack[g_track_line_number])
        g_parser_line++;

    g_parser_penultimateChar = g_parser_lastChar;
    g_parser_lastChar = g_parser_currentChar;
    return g_parser_currentChar;
}

#undef CR
#undef LF

void ungetTexChar(char c)

/****************************************************************************
purpose: rewind the filepointer in the LaTeX-file by one
 ****************************************************************************/
{
    if (c == '\0')
        return;

    if (g_parser_file) {

        ungetc(c, g_parser_file);

    } else {
        g_parser_string--;
        if (g_parser_string && *g_parser_string) {
            *g_parser_string = c;
        }
    }

    if (c == '\n' && g_track_line_number_stack[g_track_line_number])
        g_parser_line--;

    g_parser_currentChar = g_parser_lastChar;
    g_parser_lastChar = g_parser_penultimateChar;
    g_parser_penultimateChar = '\0';    /* no longer know what that it was */
    g_parser_backslashes = 0;
    diagnostics(6, "after ungetTexChar=<%c> backslashes=%d line=%ld", c, g_parser_backslashes, g_parser_line);
}

char getTexChar()

/***************************************************************************
 purpose:     get the next character from the input stream
              This should be the usual place to access the LaTeX file
			  It filters the input stream so that % is handled properly
****************************************************************************/
{
    char cThis;
    char cSave = g_parser_lastChar;
    char cSave2 = g_parser_penultimateChar;

    cThis = getRawTexChar();
    while (cThis == '%' && even(g_parser_backslashes)) {
        skipToEOL();
        g_parser_penultimateChar = cSave2;
        g_parser_lastChar = cSave;
        cThis = getRawTexChar();
    }

    if (cThis == '\\')
        g_parser_backslashes++;
    else
        g_parser_backslashes = 0;
    diagnostics(6, "after getTexChar=<%c> backslashes=%d line=%d", cThis, g_parser_backslashes, g_parser_line);
    return cThis;
}

void skipToEOL(void)

/****************************************************************************
purpose: ignores anything from inputfile until the end of line.  
         uses getRawTexChar() because % are not important
 ****************************************************************************/
{
    char cThis;

    while ((cThis = getRawTexChar()) && cThis != '\n') {
    }
}

char getNonBlank(void)

/***************************************************************************
 Description: get the next non-blank character from the input stream
****************************************************************************/
{
    char c;

    while ((c = getTexChar()) && (c == ' ' || c == '\n')) {
    }
    return c;
}

char getNonSpace(void)

/***************************************************************************
 Description: get the next non-space character from the input stream
****************************************************************************/
{
    char c;

    while ((c = getTexChar()) && c == ' ') {
    }
    return c;
}

void skipSpaces(void)

/***************************************************************************
 Description: skip to the next non-space character from the input stream
****************************************************************************/
{
    char c;

    while ((c = getTexChar()) && c == ' ') {
    }
    ungetTexChar(c);
}

int getSameChar(char c)

/***************************************************************************
 Description: returns the number of characters that are the same as c
****************************************************************************/
{
    char cThis;
    int count = -1;

    do {
        cThis = getTexChar();
        count++;
    } while (cThis == c);

    ungetTexChar(cThis);

    return count;
}

char *getDelimitedText(char left, char right, bool raw)

/******************************************************************************
  purpose: general scanning routine that allocates and returns a string
  		   that is between "left" and "right" that accounts for escaping by '\'
  		   
  		   Example for getDelimitedText('{','}',TRUE) 
  		   
  		   "{the \{ is shown {\it by} a\\}" ----> "the \{ is shown {\it by} a\\"
  		    
  		    Note the missing opening brace in the example above
 ******************************************************************************/
{
    char buffer[5000];
    int size = -1;
    int lefts_needed = 1;
    char marker = ' ';
    char last_char = ' ';

    while (lefts_needed && size < 4999) {

        size++;
        last_char = marker;
        buffer[size] = (raw) ? getRawTexChar() : getTexChar();
        marker = buffer[size];

        if (buffer[size] != right || last_char == '\\') {   /* avoid \} */
            if (buffer[size] == left && last_char != '\\')  /* avoid \{ */
                lefts_needed++;
            else {
                if (buffer[size] == '\\' && last_char == '\\')  /* avoid \\} */
                    marker = ' ';
            }
        } else
            lefts_needed--;
    }

    buffer[size] = '\0';        /* overwrite final delimeter */
    if (size == 4999)
        diagnostics(ERROR, "Misplaced '%c' (Not found within 5000 chars)");

    return strdup(buffer);
}

void parseBrace(void)

/****************************************************************************
  Description: Skip text to balancing close brace                          
 ****************************************************************************/
{
    char *s = getDelimitedText('{', '}', FALSE);

    free(s);
}

void parseBracket(void)

/****************************************************************************
  Description: Skip text to balancing close bracket
 ****************************************************************************/
{
    char *s = getDelimitedText('[', ']', FALSE);

    free(s);
}

void CmdIgnoreParameter(int code)

/****************************************************************************
   Description: Ignore the parameters of a command 
   Example    : CmdIgnoreParameter(21) for \command[opt1]{reg1}{reg2}

   code is a decimal # of the form "op" where `o' is the number of
   optional parameters (0-9) and `p' is the # of required parameters.    
                                                
   The specified number of parameters is ignored.  The order of the parameters
   in the LaTeX file does not matter.                      
****************************************************************************/
{
    int optParmCount = code / 10;
    int regParmCount = code % 10;
    char cThis;

    diagnostics(4, "CmdIgnoreParameter [%d] {%d}", optParmCount, regParmCount);

    while (regParmCount) {
        cThis = getNonBlank();
        switch (cThis) {
            case '{':

                regParmCount--;
                parseBrace();
                break;

            case '[':

                optParmCount--;
                parseBracket();
                break;

            default:
                diagnostics(WARNING, "Ignored command missing {} expected %d - found %d", code % 10,
                  code % 10 - regParmCount);
                ungetTexChar(cThis);
                return;
        }
    }

    /* Check for trailing optional parameter e.g., \item[label] */

    if (optParmCount > 0) {
        cThis = getNonSpace();
        if (cThis == '[')
            parseBracket();
        else {
            ungetTexChar(cThis);
            return;
        }
    }
    return;
}

char *getSimpleCommand(void)

/**************************************************************************
     purpose: returns a simple command e.g., \alpha\beta will return "\beta"
                                                   ^
 **************************************************************************/
{
    char buffer[128];
    int size;

    buffer[0] = getTexChar();

    if (buffer[0] != '\\')
        return NULL;

    for (size = 1; size < 127; size++) {
        buffer[size] = getRawTexChar(); /* \t \r '%' all end command */

        if (!isalpha((int) buffer[size])) {
            ungetTexChar(buffer[size]);
            break;
        }
    }

    buffer[size] = '\0';
    if (size == 127) {
        diagnostics(WARNING, "Misplaced brace.");
        diagnostics(ERROR, "Cannot find close brace in 127 characters");
    }

    diagnostics(5, "getSimpleCommand result <%s>", buffer);
    return strdup(buffer);
}

char *getBracketParam(void)

/******************************************************************************
  purpose: return bracketed parameter
  			
  \item[1]   --->  "1"        \item[]   --->  ""        \item the  --->  NULL
       ^                           ^                         ^
  \item [1]  --->  "1"        \item []  --->  ""        \item  the --->  NULL
       ^                           ^                         ^
 ******************************************************************************/
{
    char c, *text;

    c = getNonBlank();
    PushTrackLineNumber(FALSE);

    if (c == '[') {
        text = getDelimitedText('[', ']', FALSE);
        diagnostics(5, "getBracketParam [%s]", text);

    } else {
        ungetTexChar(c);
        text = NULL;
        diagnostics(5, "getBracketParam []");
    }

    PopTrackLineNumber();
    return text;
}

char *getBraceParam(void)

/**************************************************************************
     purpose: allocates and returns the next parameter in the LaTeX file
              Examples:  (^ indicates the current file position)
              
     \alpha\beta   --->  "\beta"             \bar \alpha   --->  "\alpha"
           ^                                     ^
     \bar{text}    --->  "text"              \bar text     --->  "t"
         ^                                       ^
	_\alpha        ---> "\alpha"             _{\alpha}     ---> "\alpha"
	 ^                                        ^
	_2             ---> "2"                  _{2}          ---> "2"
	 ^                                        ^
 **************************************************************************/
{
    char s[2], *text;

    s[0] = getNonSpace();       /* skip spaces and one possible newline */
    if (s[0] == '\n')
        s[0] = getNonSpace();

    PushTrackLineNumber(FALSE);

    if (s[0] == '\\') {
        ungetTexChar(s[0]);
        text = getSimpleCommand();

    } else if (s[0] == '{')
        text = getDelimitedText('{', '}', TRUE);

    else {
        s[1] = '\0';
        text = strdup(s);
    }

    PopTrackLineNumber();
    diagnostics(5, "Leaving getBraceParam {%s}", text);
    return text;
}

char *getLeftRightParam(void)

/**************************************************************************
     purpose: get text between \left ... \right
 **************************************************************************/
{
    char text[5000], s, *command;
    int i = 0;
    int lrdepth = 1;

    text[0] = '\0';

    for (;;) {
        s = getTexChar();
        if (s == '\\') {
            ungetTexChar(s);
            command = getSimpleCommand();
            if (strcmp(command, "\\right") == 0) {
                lrdepth--;
                if (lrdepth == 0) {
                    free(command);
                    return strdup(text);
                }
            }
            strcat(text + i, command);
            i += strlen(command);
            if (i > 4950)
                diagnostics(ERROR, "Contents of \\left .. \\right too large.");
            if (strcmp(command, "\\left") == 0)
                lrdepth++;
            free(command);
        } else {
            text[i] = s;
            i++;
            text[i] = '\0';
        }
    }
    return NULL;
}




char *getTexUntil(char *target, int raw)

/**************************************************************************
     purpose: returns the portion of the file to the beginning of target
     returns: NULL if not found
 **************************************************************************/
{
    enum { BUFFSIZE = 8000 };
    char *s;
    char buffer[BUFFSIZE + 1] = { '\0' };
    int last_i = -1;
    int i = 0;                  /* size of string that has been read */
    size_t j = 0;               /* number of found characters */
    bool end_of_file_reached = FALSE;
    size_t len = strlen(target);

    PushTrackLineNumber(FALSE);

    diagnostics(5, "getTexUntil target = <%s> raw_search = %d ", target, raw);

    while (j < len && i < BUFFSIZE) {

        if (i > last_i) {
            buffer[i] = (raw) ? getRawTexChar() : getTexChar();
            last_i = i;
            if (buffer[i] != '\n')
                diagnostics(7, "next char = <%c>, %d, %d, %d", buffer[i], i, j, last_i);
            else
                diagnostics(7, "next char = <\\n>");

        }

        if (buffer[i] == '\0') {
            end_of_file_reached = TRUE;
            diagnostics(7, "end of file reached");
            break;
        }

        if (buffer[i] != target[j]) {
            if (j > 0) {        /* false start, put back what was found */
                diagnostics(8, "failed to match target[%d]=<%c> != buffer[%d]=<%c>", j, target[j], i, buffer[i]);
                i -= j;
                j = 0;
            }
        } else
            j++;

        i++;
    }

    if (i == BUFFSIZE)
        diagnostics(ERROR, "Could not find <%s> in %d characters", BUFFSIZE);

    if (!end_of_file_reached)   /* do not include target in returned string */
        buffer[i - len] = '\0';

    PopTrackLineNumber();

    diagnostics(3, "buffer size =[%d], actual=[%d]", strlen(buffer), i - len);

    s = strdup(buffer);
    diagnostics(3, "strdup result = %s", s);
    return s;
}

int getDimension(void)

/**************************************************************************
     purpose: reads a TeX dimension and returns size it twips
          eg: 3 in, -.013mm, 29 pc, + 42,1 dd, 1234sp
**************************************************************************/
{
    char cThis, buffer[20];
    int i = 0;
    float num;

    skipSpaces();

/* obtain optional sign */
    cThis = getTexChar();

/* skip "to" */
    if (cThis == 't') {
        cThis = getTexChar();
        cThis = getTexChar();
    }

/* skip "spread" */
    if (cThis == 's') {
        cThis = getTexChar();
        cThis = getTexChar();
        cThis = getTexChar();
        cThis = getTexChar();
        cThis = getTexChar();
        cThis = getTexChar();
    }

    if (cThis == '-' || cThis == '+') {
        buffer[i++] = cThis;
        skipSpaces();
        cThis = getTexChar();
    }

/* obtain number */
    if (cThis == '\\')
        buffer[i++] = '1';
    else {
        while (i < 19 && (isdigit((int) cThis) || cThis == '.' || cThis == ',')) {
            if (cThis == ',')
                cThis = '.';
            buffer[i++] = cThis;
            cThis = getTexChar();
        }
    }
    ungetTexChar(cThis);
    buffer[i] = '\0';
    diagnostics(4, "getDimension() raw number is <%s>", buffer);

    if (i == 19 || sscanf(buffer, "%f", &num) != 1) {
        diagnostics(WARNING, "Screwy number in TeX dimension");
        diagnostics(1, "getDimension() number is <%s>", buffer);
        return 0;
    }

/*	num *= 2;                    convert pts to twips */

/* obtain unit of measure */
    skipSpaces();
    buffer[0] = tolower((int) getTexChar());

/* skip "true" */
    if (buffer[0] == 't') {
        cThis = getTexChar();
        cThis = getTexChar();
        cThis = getTexChar();
        skipSpaces();
        buffer[0] = tolower((int) getTexChar());
    }

    if (buffer[0] != '\\') {
        buffer[1] = tolower((int) getTexChar());
        buffer[2] = '\0';

        diagnostics(4, "getDimension() dimension is <%s>", buffer);
        if (strstr(buffer, "pt"))
            return (int) (num * 20);
        else if (strstr(buffer, "pc"))
            return (int) (num * 12 * 20);
        else if (strstr(buffer, "in"))
            return (int) (num * 72.27 * 20);
        else if (strstr(buffer, "bp"))
            return (int) (num * 72.27 / 72 * 20);
        else if (strstr(buffer, "cm"))
            return (int) (num * 72.27 / 2.54 * 20);
        else if (strstr(buffer, "mm"))
            return (int) (num * 72.27 / 25.4 * 20);
        else if (strstr(buffer, "dd"))
            return (int) (num * 1238.0 / 1157.0 * 20);
        else if (strstr(buffer, "dd"))
            return (int) (num * 1238.0 / 1157 * 20);
        else if (strstr(buffer, "cc"))
            return (int) (num * 1238.0 / 1157.0 * 12.0 * 20);
        else if (strstr(buffer, "sp"))
            return (int) (num / 65536.0 * 20);
        else if (strstr(buffer, "ex"))
            return (int) (num * CurrentFontSize() * 0.5);
        else if (strstr(buffer, "em"))
            return (int) (num * CurrentFontSize());
        else if (strstr(buffer, "in"))
            return (int) (num * 72.27 * 20);
        else {
            ungetTexChar(buffer[1]);
            ungetTexChar(buffer[0]);
            return (int) num;
        }
    } else {
        char *s, *t;

        ungetTexChar(buffer[0]);
        s = getSimpleCommand();
        t = s + 1;              /* skip initial backslash */
        diagnostics(4, "getDimension() dimension is <%s>", t);
        num *= getLength(t);
        free(s);
        return (int) num;
    }

}

#define SECTION_BUFFER_SIZE 2048
static char *section_buffer = NULL;
static size_t section_buffer_size = SECTION_BUFFER_SIZE;

static void increase_buffer_size(void)
{
    char *new_section_buffer;

    new_section_buffer = malloc(2 * section_buffer_size + 1);
    if (new_section_buffer == NULL)
        diagnostics(ERROR, "Could not allocate enough memory to process file. Sorry.");
    memmove(new_section_buffer, section_buffer, section_buffer_size);
    section_buffer_size *= 2;
    free(section_buffer);
    section_buffer = new_section_buffer;
    diagnostics(4, "Expanded buffer size is now %ld", section_buffer_size);
}

void getSection(char **body, char **header, char **label)

/**************************************************************************
	purpose: obtain the next section of the latex file
	
	This is now a preparsing routine that breaks a file up into sections.  
	Macro expansion happens here as well.  \input and \include is also
	handled here.  The reason for this routine is allow \labels to refer
	to sections.  
	
	This routine reads text until a new section heading is found.  The text 
	is returned in body and the *next* header is returned in header.  If 
	no header follows then NULL is returned.
	
**************************************************************************/
{
    int possible_match, found;
    char cNext, *s, *text, *next_header, *str;
    int i;
    size_t delta;
    int match[35];
    char *command[35] = { "",   /* 0 entry is for user definitions */
        "",                     /* 1 entry is for user environments */
        "\\begin{verbatim}", "\\begin{figure}", "\\begin{figure*}", "\\begin{equation}",
        "\\begin{eqnarray}", "\\begin{table}", "\\begin{description}", "\\begin{comment}",
        "\\end{verbatim}", "\\end{figure}", "\\end{figure*}", "\\end{equation}",
        "\\end{eqnarray}", "\\end{table}", "\\end{description}", "\\end{comment}",
        "\\part", "\\chapter", "\\section", "\\subsection", "\\subsubsection",
        "\\section*", "\\subsection*", "\\subsubsection*",
        "\\label", "\\input", "\\include", "\\verb", "\\url",
        "\\newcommand", "\\def", "\\renewcommand", "\\endinput",
    };

    int ncommands = 35;

    const int b_verbatim_item = 2;
    const int b_figure_item = 3;
    const int b_figure_item2 = 4;
    const int b_equation_item = 5;
    const int b_eqnarray_item = 6;
    const int b_table_item = 7;
    const int b_description_item = 8;
    const int b_comment_item = 9;
    const int e_verbatim_item = 10;
    const int e_figure_item = 11;
    const int e_equation_item = 12;
    const int e_equation_item2 = 13;
    const int e_eqnarray_item = 14;
    const int e_table_item = 15;
    const int e_description_item = 16;
    const int e_comment_item = 17;

    const int label_item = 26;
    const int input_item = 27;
    const int include_item = 28;
    const int verb_item = 29;
    const int url_item = 30;
    const int new_item = 31;
    const int def_item = 32;
    const int renew_item = 33;
    const int endinput_item = 34;

    int bs_count = 0;
    size_t index = 0;
    int label_depth = 0;
    int n_target = strlen(InterpretCommentString);

    if (section_buffer == NULL) {
        section_buffer = malloc(section_buffer_size + 1);
        if (section_buffer == NULL)
            diagnostics(ERROR, "Could not allocate enough memory to process file. Sorry.");
    }

    text = NULL;
    next_header = NULL;         /* typically becomes \subsection{Cows eat grass} */
    *body = NULL;
    *header = NULL;
    *label = NULL;

    PushTrackLineNumber(FALSE);
    for (delta = 0;; delta++) {

        if (delta + 2 >= section_buffer_size)
            increase_buffer_size();

        cNext = getRawTexChar();
        while (cNext == '\0' && g_parser_depth > 0) {
            PopSource();
            cNext = getRawTexChar();
        }

        if (cNext == '\0')
            diagnostics(5, "[%ld] xchar=000 '\\0' (backslash count=%d)", delta, bs_count);
        else if (cNext == '\n')
            diagnostics(5, "[%ld] xchar=012 '\\n' (backslash count=%d)", delta, bs_count);
        else
            diagnostics(5, "[%ld] xchar=%03d '%c' (backslash count=%d)", delta, (int) cNext, cNext, bs_count);

        /* add character to buffer */
        *(section_buffer + delta) = cNext;

        if (cNext == '\0')
            break;

        /* slurp TeX comments but discard InterpretCommentString */
        if (cNext == '%' && even(bs_count)) {
            int n = 0;

            delta++;
            *(section_buffer + delta) = cNext;
            cNext = getRawTexChar();

            while (cNext != '\n' && cNext != '\0') {

                delta++;
                n++;
                *(section_buffer + delta) = cNext;

                if (delta + 2 >= section_buffer_size)
                    increase_buffer_size();

                /* handle %latex2rtf: */
                if (n == n_target && strncmp(InterpretCommentString, section_buffer + delta - n + 1, n_target) == 0)
                    break;

                cNext = getRawTexChar();
            }

            delta -= n + 2;     /* remove '% .... \n', or '% ... \0' or just '%latex2rtf:' */
            continue;           /* go get the next character */
        }

        /* begin search if backslash found */
        if (*(section_buffer + delta) == '\\') {
            bs_count++;
            if (odd(bs_count)) {    /* avoid "\\section" and "\\\\section" */
                for (i = 0; i < ncommands; i++)
                    match[i] = TRUE;
                index = 1;
                continue;
            }
        } else
            bs_count = 0;

        if (index == 0)
            continue;

        possible_match = FALSE;

/* slow... */
        if (match[0])           /* do any user defined commands possibly match? */
            match[0] = maybeDefinition(section_buffer + delta - index + 1, index - 1);

        /* do any user defined commands possibly match? */
        if (match[1])
            match[1] = maybeEnvironment(section_buffer + delta - index, index - 1);

        possible_match = match[0] || match[1];

        for (i = 2; i < ncommands; i++) {   /* test each command for match */
            if (!match[i])
                continue;

            if (*(section_buffer + delta) != command[i][index]) {
                match[i] = FALSE;

/*				diagnostics(2,"index = %d, char = %c, failed to match %s, size=%d", \
				index,*p,command[i],strlen(command[i]));
*/ continue;
            }
            possible_match = TRUE;
        }

        found = FALSE;

        if (match[0]) {         /* expand user macros */
            cNext = getRawTexChar();    /* wrong when cNext == '%' */
            ungetTexChar(cNext);
            if (!isalpha((int) cNext) && index > 1) {   /* is macro name complete? */

                *(section_buffer + delta + 1) = '\0';
                i = existsDefinition(section_buffer + delta - index + 1);
                if (i > -1) {
                    if (cNext == ' ') {
                        cNext = getNonSpace();
                        ungetTexChar(cNext);
                    }

                    delta -= index + 1; /* remove \macroname */
                    str = expandDefinition(i);
                    diagnostics(4, "getSection() expanded macro string is <%s>", str);
                    PushSource(NULL, str);
                    free(str);
                    index = 0;
                    continue;
                }
            }
        }

        if (match[1]) {         /* expand user environments */
            char *p = section_buffer + delta - index;

            cNext = getRawTexChar();    /* wrong when cNext == '%' */
            str = NULL;

            if (cNext == '}' && index > 5) {    /* is environ name complete? */
                *(p + index + 1) = '\0';
                if (*(p + 1) == 'e') {  /* find \\end{userenvironment} */
                    i = existsEnvironment(p + strlen("\\end{"));
                    str = expandEnvironment(i, CMD_END);
                } else if (index > 8) { /* find \\begin{userenvironment} */
                    i = existsEnvironment(p + strlen("\\begin{"));
                    str = expandEnvironment(i, CMD_BEGIN);
                }
            }

            if (str) {          /* found */
                char *str2;

                diagnostics(4, "matched <%s}>", p);
                diagnostics(4, "expanded <%s>", str);
                if (*(p + 1) == 'e')
                    str2 = strdup_together(str, "}");
                else
                    str2 = strdup_together("{", str);
                free(str);
                PushSource(NULL, str2);
                free(str2);
                delta -= index + 1; /* remove \begin{userenvironment} */
                index = 0;
                diagnostics(4, "getSection() expanded environment string is <%s>", str);
                continue;
            }

            ungetTexChar(cNext);    /* put the character back */
        }

        for (i = 2; i < ncommands; i++) {   /* discover any exact matches */
            if (!match[i])
                continue;
            if (index + 1 == strlen(command[i])) {
                found = TRUE;
                break;
            }
        }

        if (found) {            /* make sure the next char is the right sort */
            diagnostics(5, "matched %s", command[i]);
            cNext = getRawTexChar();
            ungetTexChar(cNext);

            if (i > e_description_item && i <= include_item && cNext != ' ' && cNext != '{') {
                found = FALSE;
                match[i] = FALSE;
                diagnostics(5, "oops! did not match %s", command[i]);
            }
        }

        if (!possible_match) {  /* no possible matches, reset and wait for next '\\' */
            index = 0;
            continue;
        } else
            index++;

        if (!found)
            continue;

        if (i == endinput_item) {
            delta -= 9;         /* remove \endinput */
            PopSource();
            index = 0;          /* keep looking */
            continue;
        }

        if (i == verb_item || i == url_item) {  /* slurp \verb#text# */
            if (i == url_item && cNext == '{')
                cNext = '}';
            delta++;
            *(section_buffer + delta) = getRawTexChar();
            delta++;
            while ((*(section_buffer + delta) = getRawTexChar()) != '\0' && *(section_buffer + delta) != cNext) {
                delta++;
                if (delta >= section_buffer_size)
                    increase_buffer_size();
            }
            index = 0;          /* keep looking */
            continue;
        }

        if (i == input_item || i == include_item) {
            char *s, *s2;

            s = getBraceParam();
            if (i == input_item)
                diagnostics(4, "\\input{%s}", s);
            else
                diagnostics(4, "\\include{%s}", s);

            if (strstr(s, "german.sty") != NULL) {
                GermanMode = TRUE;
                PushEnvironment(GERMAN_MODE);

            } else if (strstr(s, "french.sty") != NULL) {
                FrenchMode = TRUE;
                PushEnvironment(FRENCH_MODE);

            } else if (strcmp(s, "") == 0) {
                diagnostics(WARNING, "Empty or invalid filename in \\include{}");

            } else {

                if (strstr(s, ".ltx") == NULL && strstr(s, ".tex") == NULL) {
                    /* extension .tex is appended automatically if missing */
                    s2 = strdup_together(s, ".tex");
                    free(s);
                    s = s2;
                }

                PushSource(s, NULL);    /* ignore return value */
            }
            delta -= (i == input_item) ? 6 : 8; /* remove \input or \include */
            free(s);
            index = 0;          /* keep looking */
            continue;
        }

        if (i == label_item) {
            s = getBraceParam();
            diagnostics(4, "\\label{%s}", s);

            /* append \label{tag} to the buffer */
            delta++;
            *(section_buffer + delta) = '{';
            while (delta + strlen(s) + 1 >= section_buffer_size)
                increase_buffer_size();
            strcpy(section_buffer + delta + 1, s);
            delta += strlen(s) + 1;
            *(section_buffer + delta) = '}';

            if (!(*label) && strlen(s) && label_depth == 0)
                *label = strdup_nobadchars(s);

            free(s);
            index = 0;          /* keep looking */
            continue;
        }

        /* process any new definitions */
        if (i == def_item || i == new_item || i == renew_item) {
            cNext = getRawTexChar();    /* wrong when cNext == '%' */
            ungetTexChar(cNext);
            if (isalpha((int) cNext))   /* is macro name complete? */
                continue;

            delta -= strlen(command[i]);    /* do not include in buffer */

            if (i == def_item)
                CmdNewDef(DEF_DEF);
            else if (i == new_item)
                CmdNewDef(DEF_NEW);
            else
                CmdNewDef(DEF_RENEW);

            index = 0;          /* keep looking */
            continue;
        }

        if (i == b_figure_item || i == b_figure_item2 || i == b_equation_item || i == b_eqnarray_item ||
          i == b_table_item || i == b_description_item) {
            label_depth++;      /* labels now will not be the section label */
            index = 0;
            continue;
        }

        if (i == e_figure_item || i == e_equation_item || i == e_equation_item2 || i == e_eqnarray_item ||
          i == e_table_item || i == e_description_item) {
            label_depth--;      /* labels may now be the section label */
            index = 0;
            continue;
        }

        if (i == b_verbatim_item) { /* slurp environment to avoid inside */
            delta++;
            s = getTexUntil(command[e_verbatim_item], TRUE);

            while (delta + strlen(s) + strlen(command[e_verbatim_item]) + 1 >= section_buffer_size)
                increase_buffer_size();

            strcpy(section_buffer + delta, s);  /* append s */
            delta += strlen(s);

            strcpy(section_buffer + delta, command[e_verbatim_item]);   /* append command[i] */
            delta += strlen(command[e_verbatim_item]) - 1;
            free(s);
            index = 0;          /* keep looking */
            continue;
        }

        if (i == b_comment_item) {  /* slurp environment to avoid inside */
            delta++;
            s = getTexUntil(command[e_comment_item], TRUE);

            while (delta + strlen(s) + strlen(command[e_comment_item]) + 1 >= section_buffer_size)
                increase_buffer_size();

            strcpy(section_buffer + delta, s);  /* append s */
            delta += strlen(s);

            strcpy(section_buffer + delta, command[e_comment_item]);    /* append command[i] */
            delta += strlen(command[e_comment_item]) - 1;
            free(s);
            index = 0;          /* keep looking */
            continue;
        }

        diagnostics(5, "possible end of section");
        diagnostics(5, "label_depth = %d", label_depth);

        if (label_depth > 0)    /* still in a \begin{xxx} environment? */
            continue;

        /* actually found command to end the section */
        diagnostics(2, "getSection found command to end section");
        s = getBraceParam();
        next_header = malloc(strlen(command[i]) + strlen(s) + 3);
        strcpy(next_header, command[i]);
        strcpy(next_header + strlen(command[i]), "{");
        strcpy(next_header + strlen(command[i]) + 1, s);
        strcpy(next_header + strlen(command[i]) + 1 + strlen(s), "}");
        free(s);
        delta -= strlen(command[i]) - 1;
        *(section_buffer + delta) = '\0';
        break;
    }
    text = strdup(section_buffer);
    *body = text;
    *header = next_header;
    PopTrackLineNumber();
}
