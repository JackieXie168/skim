
/* definitions.c - Routines to handle TeX \def and LaTeX \newcommand 

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
*/

#include <stdlib.h>
#include <string.h>
#include "main.h"
#include "convert.h"
#include "definitions.h"
#include "parser.h"
#include "funct1.h"
#include "util.h"
#include "cfg.h"
#include "counters.h"
#include "funct1.h"

#define MAX_DEFINITIONS 200
#define MAX_ENVIRONMENTS 20
#define MAX_THEOREMS 20

struct {
    char *name;
    char *opt_param;
    char *def;
    int params;
} Definitions[MAX_DEFINITIONS];

struct {
    char *name;
    char *opt_param;
    char *begname;
    char *endname;
    char *begdef;
    char *enddef;
    int params;
} NewEnvironments[MAX_ENVIRONMENTS];

struct {
    char *name;
    char *numbered_like;
    char *caption;
    char *within;
} NewTheorems[MAX_THEOREMS];

static int iDefinitionCount = 0;
static int iNewEnvironmentCount = 0;
static int iNewTheoremCount = 0;

static int strequal(char *a, char *b)
{
    if (a == NULL || b == NULL)
        return 0;

    while (*a && *b && *a == *b) {
        a++;
        b++;
    }

    if (*a || *b)
        return 0;
    else
        return 1;
}

/* static void printDefinitions(void)
{
int i=0;
	fprintf(stderr, "\n");
	while(i < iDefinitionCount ) {
		fprintf(stderr, "[%d] name     =<%s>\n",i, Definitions[i].name);
		fprintf(stderr, "    opt_param=<%s>\n", Definitions[i].opt_param);
		fprintf(stderr, "    def      =<%s>\n", Definitions[i].def);
		fprintf(stderr, "    params   =<%d>\n", Definitions[i].params);
		i++;
	}
}

static void printTheorems(void)
{
int i=0;
	fprintf(stderr, "\n");
	for (i=0; i< iNewTheoremCount; i++) {
		fprintf(stderr, "[%d] name   =<%s>\n",i, NewTheorems[i].name);
		fprintf(stderr, "    caption    =<%s>\n", NewTheorems[i].caption);
		fprintf(stderr, "    like =<%s>\n", NewTheorems[i].numbered_like);
		fprintf(stderr, "    within    =<%s>\n", NewTheorems[i].within);
	}
}
*/

static char *expandmacro(char *macro, char *opt_param, int params)

/**************************************************************************
     purpose: retrieves and expands a defined macro 
              care is taken to avoid buffer overruns
**************************************************************************/
{
    int i = 0, param;
    char *args[9], *dmacro, *macro_piece, *next_piece, *expanded, *buffer=NULL, *cs;
    int buff_size = 512;   /* extra slop for macro expansion */

    if (params <= 0)
        return strdup(macro);

    if (opt_param) {
        args[0] = getBracketParam();
        if (!args[0])
            args[0] = strdup(opt_param);
        buff_size += strlen(args[0]);
        i = 1;
    }

    for (; i < params; i++) {
        args[i] = getBraceParam();
        buff_size += strlen(args[i]);
        diagnostics(3, "argument #%d <%s>", i + 1, args[i]);
    }

    dmacro = strdup(macro);
    macro_piece = dmacro;
	buff_size += strlen(macro_piece);

	diagnostics(3, "buff_size in expandmacro = %d\n", buff_size);
	if(buff_size > 0)
		buffer = (char*) calloc(sizeof(char) * buff_size, sizeof(char));
 	
	expanded = buffer;

    /* convert "\csname" to "\" */
    while ((cs = strstr(dmacro, "\\csname")) != NULL)
        strcpy(cs + 1, cs + 7);

    /* remove "\endcsname" */
    while ((cs = strstr(dmacro, "\\endcsname")) != NULL)
        strcpy(cs, cs + 10);

    /* do not use strtok because it may be used elsewhere */
    while (macro_piece && *macro_piece) {

        next_piece = strchr(macro_piece, '#');
        if (next_piece) {
            *next_piece = '\0';
            next_piece++;
            if (*next_piece == '#')
                param = 101;    /* just a flag for below */
            else
                param = *next_piece - '1';
            next_piece++;
        } else
            param = -1;

        diagnostics(3, "expandmacro piece =<%s>", macro_piece);
        strcpy(expanded, macro_piece);
        expanded += strlen(macro_piece);
        if (param > -1) {
            if (param == 101) {
                diagnostics(3, "expandmacro ## = #");
                if (expanded+1<buffer+buff_size) {
                	strcpy(expanded, "#");
                	expanded++;
                } else 
                    diagnostics(WARNING, "insufficient buffer to expand macro <%s>", macro);

            } else if (param < params) {
                diagnostics(3, "expandmacro arg =<%s>", args[param]);
                if (expanded+strlen(args[param]) <buffer+buff_size) {
                    strcpy(expanded, args[param]);
                    expanded += strlen(args[param]);
                } else 
                    diagnostics(WARNING, "insufficient buffer to expand macro <%s>", macro);

            } else
                diagnostics(WARNING, "confusing definition in macro=<%s>", macro);
        }

        macro_piece = next_piece;
    }

    expanded = strdup(buffer);
    
    for (i = 0; i < params; i++) {
        if (args[i])
            free(args[i]);
	}
	
    if (dmacro)
        free(dmacro);

    if (buffer)
    	free(buffer);

    diagnostics(3, "expandmacro expanded=<%s>", expanded);
    
    return expanded;
}

int maybeDefinition(char *s, size_t n)

/**************************************************************************
     purpose: checks to see if a named TeX definition possibly exists
     returns: the array index of the named TeX definition
**************************************************************************/
{
    int i;

    if (n == 0)
        return TRUE;

    for (i = 0; i < iDefinitionCount; i++) {
        diagnostics(6, "seeking=<%s>, i=%d, current=<%s>", s, i, Definitions[i].name);
        if (strncmp(s, Definitions[i].name, n) == 0)
            return TRUE;
    }

    return FALSE;
}

int existsDefinition(char *s)

/**************************************************************************
     purpose: checks to see if a named TeX definition exists
     returns: the array index of the named TeX definition
**************************************************************************/
{
    int i;

    for (i = 0; i < iDefinitionCount; i++) {
        diagnostics(6, "seeking=<%s>, i=%d, current=<%s>", s, i, Definitions[i].name);
        if (strcmp(s, Definitions[i].name) == 0)
            break;
    }

    if (i == iDefinitionCount)
        return -1;
    else
        return i;
}

void newDefinition(char *name, char *opt_param, char *def, int params)

/**************************************************************************
     purpose: allocates and initializes a named TeX definition 
              name should not begin with a '\'  for example to
              define \hd, name = "hd"
**************************************************************************/
{
    diagnostics(3, "Adding macro <%s>=<%s>", name, def);

    if (strcmp(name, "LaTeX") == 0)
        return;
    if (strcmp(name, "TeX") == 0)
        return;
    if (strcmp(name, "AmSTeX") == 0)
        return;
    if (strcmp(name, "BibTex") == 0)
        return;
    if (strcmp(name, "LaTeXe") == 0)
        return;
    if (strcmp(name, "AmSLaTeX") == 0)
        return;

    if (iDefinitionCount == MAX_DEFINITIONS) {
        diagnostics(WARNING, "Too many definitions, ignoring %s", name);
        return;
    }

    Definitions[iDefinitionCount].params = params;

    Definitions[iDefinitionCount].name = strdup(name);

    if (Definitions[iDefinitionCount].name == NULL) {
        diagnostics(ERROR, "\nCannot allocate name for definition \\%s\n", name);
    }

    if (opt_param) {
        Definitions[iDefinitionCount].opt_param = strdup(opt_param);

        if (Definitions[iDefinitionCount].opt_param == NULL) {
            diagnostics(ERROR, "\nCannot allocate opt_param for definition \\%s\n", name);
        }
    } else {
        Definitions[iDefinitionCount].opt_param = NULL;
    }

    Definitions[iDefinitionCount].def = strdup(def);

    if (Definitions[iDefinitionCount].def == NULL) {
        diagnostics(ERROR, "\nCannot allocate def for definition \\%s\n", name);
    }

    iDefinitionCount++;
    diagnostics(3, "Successfully added macro #%d", iDefinitionCount);
}

void renewDefinition(char *name, char *opt_param, char *def, int params)

/**************************************************************************
     purpose: allocates (if necessary) and sets a named TeX definition 
**************************************************************************/
{
    int i;

    diagnostics(3, "renewDefinition seeking <%s>\n", name);
    i = existsDefinition(name);

    if (i < 0) {
        newDefinition(name, opt_param, def, params);
        diagnostics(WARNING, "No existing definition for \\%s", name);

    } else {
        free(Definitions[i].def);
        if (Definitions[i].opt_param)
            free(Definitions[i].opt_param);
        Definitions[i].params = params;
        if (opt_param) {
            Definitions[i].opt_param = strdup(opt_param);
            if (Definitions[i].opt_param == NULL) {
                diagnostics(ERROR, "\nCannot allocate opt_param for definition \\%s\n", name);
            }
        } else {
            Definitions[i].opt_param = NULL;
        }

        Definitions[i].def = strdup(def);
        if (Definitions[i].def == NULL) {
            diagnostics(WARNING, "\nCannot allocate def for definition \\%s\n", name);
            exit(1);
        }
    }
}

char *expandDefinition(int thedef)

/**************************************************************************
     purpose: retrieves and expands a \newcommand macro 
**************************************************************************/
{

    if (thedef < 0 || thedef >= iDefinitionCount)
        return NULL;

    diagnostics(3, "expandDefinition name     =<%s>", Definitions[thedef].name);
    diagnostics(3, "expandDefinition opt_param=<%s>",
      (Definitions[thedef].opt_param) ? Definitions[thedef].opt_param : "");
    diagnostics(3, "expandDefinition def      =<%s>", Definitions[thedef].def);
    diagnostics(3, "expandDefinition params   =<%d>", Definitions[thedef].params);

    return expandmacro(Definitions[thedef].def, Definitions[thedef].opt_param, Definitions[thedef].params);
}

int existsEnvironment(char *s)

/**************************************************************************
     purpose: checks to see if a user created environment exists
     returns: the array index of the \newenvironment
**************************************************************************/
{
    int i = 0;
    size_t n;

    n = strlen(s);
    while (i < iNewEnvironmentCount && !strequal(s, NewEnvironments[i].name)) {
        diagnostics(4, "e seeking=<%s>, i=%d, current=<%s>", s, i, NewEnvironments[i].name);
        i++;
    }

    if (i == iNewEnvironmentCount)
        return -1;
    else
        return i;
}

int maybeEnvironment(char *s, size_t n)

/**************************************************************************
     purpose: checks to see if a named TeX environment possibly exists
     returns: the array index of the named TeX definition
**************************************************************************/
{
    int i;

    if (n == 0)
        return TRUE;

    for (i = 0; i < iNewEnvironmentCount; i++) {
        diagnostics(6, "seeking=<%s>, i=%d, current=<%s>", s, i, NewEnvironments[i].name);
        if (strncmp(s, NewEnvironments[i].begname, n) == 0 || strncmp(s, NewEnvironments[i].endname, n) == 0) {
            diagnostics(6, "possible");
            return TRUE;
        }
    }

    diagnostics(6, "not possible");
    return FALSE;
}

void newEnvironment(char *name, char *opt_param, char *begdef, char *enddef, int params)

/**************************************************************************
     purpose: allocates and initializes a \newenvironment 
              name should not begin with a '\' 
**************************************************************************/
{
    if (iNewEnvironmentCount == MAX_ENVIRONMENTS) {
        diagnostics(WARNING, "Too many newenvironments, ignoring %s", name);
        return;
    }

    NewEnvironments[iNewEnvironmentCount].name = strdup(name);
    NewEnvironments[iNewEnvironmentCount].begname = strdup_together("\\begin{", name);
    NewEnvironments[iNewEnvironmentCount].endname = strdup_together("\\end{", name);
    NewEnvironments[iNewEnvironmentCount].begdef = strdup(begdef);
    NewEnvironments[iNewEnvironmentCount].enddef = strdup(enddef);
    NewEnvironments[iNewEnvironmentCount].params = params;

    if (opt_param) {
        NewEnvironments[iNewEnvironmentCount].opt_param = strdup(opt_param);

        if (NewEnvironments[iNewEnvironmentCount].opt_param == NULL) {
            diagnostics(ERROR, "\nCannot allocate opt_param for \\newenvironment{%s}", name);
        }
    } else {
        NewEnvironments[iNewEnvironmentCount].opt_param = NULL;
    }


    if (NewEnvironments[iNewEnvironmentCount].name == NULL ||
      NewEnvironments[iNewEnvironmentCount].begdef == NULL ||
      NewEnvironments[iNewEnvironmentCount].begname == NULL ||
      NewEnvironments[iNewEnvironmentCount].endname == NULL || NewEnvironments[iNewEnvironmentCount].enddef == NULL) {
        diagnostics(ERROR, "Cannot allocate memory for \\newenvironment{%s}", name);
    }

    iNewEnvironmentCount++;
}

void renewEnvironment(char *name, char *opt_param, char *begdef, char *enddef, int params)

/**************************************************************************
     purpose: allocates and initializes a \renewenvironment 
**************************************************************************/
{
    int i;

    i = existsEnvironment(name);

    if (i < 0) {
        newEnvironment(name, opt_param, begdef, enddef, params);
        diagnostics(WARNING, "No existing \\newevironment{%s}", name);

    } else {
        free(NewEnvironments[i].begdef);
        free(NewEnvironments[i].enddef);
        free(NewEnvironments[i].begname);
        free(NewEnvironments[i].endname);
        if (NewEnvironments[i].opt_param)
            free(NewEnvironments[i].opt_param);
        if (opt_param) {
            NewEnvironments[i].opt_param = strdup(opt_param);
            if (NewEnvironments[i].opt_param == NULL) {
                diagnostics(ERROR, "\nCannot allocate opt_param for \\renewenvironment{%s}", name);
            }
        } else {
            NewEnvironments[i].opt_param = NULL;
        }
        NewEnvironments[i].params = params;
        NewEnvironments[i].begdef = strdup(begdef);
        NewEnvironments[i].enddef = strdup(enddef);
        if (NewEnvironments[i].begdef == NULL || NewEnvironments[i].enddef == NULL) {
            diagnostics(ERROR, "Cannot allocate memory for \\renewenvironment{%s}", name);
        }
    }
}

char *expandEnvironment(int thedef, int code)

/**************************************************************************
     purpose: retrieves and expands a \newenvironment 
**************************************************************************/
{
    if (thedef < 0 || thedef >= iNewEnvironmentCount)
        return NULL;

    if (code == CMD_BEGIN) {

        diagnostics(3, "\\begin{%s} <%s>", NewEnvironments[thedef].name, NewEnvironments[thedef].begdef);
        return expandmacro(NewEnvironments[thedef].begdef,
          NewEnvironments[thedef].opt_param, NewEnvironments[thedef].params);

    } else {

        diagnostics(3, "\\end{%s} <%s>", NewEnvironments[thedef].name, NewEnvironments[thedef].enddef);
        return expandmacro(NewEnvironments[thedef].enddef, NULL, 0);
    }
}

void newTheorem(char *name, char *caption, char *numbered_like, char *within)

/**************************************************************************
     purpose: allocates and initializes a \newtheorem 
**************************************************************************/
{
    if (iNewTheoremCount == MAX_THEOREMS) {
        diagnostics(WARNING, "Too many \\newtheorems, ignoring %s", name);
        return;
    }

    NewTheorems[iNewTheoremCount].name = strdup(name);

    NewTheorems[iNewTheoremCount].caption = strdup(caption);

    if (numbered_like)
        NewTheorems[iNewTheoremCount].numbered_like = strdup(numbered_like);
    else
        NewTheorems[iNewTheoremCount].numbered_like = strdup(name);

    if (within)
        NewTheorems[iNewTheoremCount].within = strdup(within);
    else
        NewTheorems[iNewTheoremCount].within = NULL;

    setCounter(NewTheorems[iNewTheoremCount].numbered_like, 0);

    iNewTheoremCount++;
}

int existsTheorem(char *s)

/**************************************************************************
     purpose: checks to see if a user created environment exists
     returns: the array index of the \newtheorem
**************************************************************************/
{
    int i = 0;

    while (i < iNewTheoremCount && !strequal(s, NewTheorems[i].name)) {
        diagnostics(6, "seeking=<%s>, i=%d, current=<%s>", s, i, NewTheorems[i].name);
        i++;
    }

    if (i == iNewTheoremCount)
        return -1;
    else
        return i;
}

char *expandTheorem(int i, char *option)

/**************************************************************************
     purpose: retrieves and expands a \newtheorem into a string
**************************************************************************/
{
    char s[128], *num;
    int ithm;

    if (i < 0 || i >= iNewTheoremCount)
        return strdup("");

    incrementCounter(NewTheorems[i].numbered_like);
    ithm = getCounter(NewTheorems[i].numbered_like);

    if (NewTheorems[i].within) {
        num = FormatUnitNumber(NewTheorems[i].within);
        if (option)
            snprintf(s, 128, "%s %s.%d (%s)", NewTheorems[i].caption, num, ithm, option);
        else
            snprintf(s, 128, "%s %s.%d", NewTheorems[i].caption, num, ithm);
        free(num);
    } else {
        if (option)
            snprintf(s, 128, "%s %d (%s)", NewTheorems[i].caption, ithm, option);
        else
            snprintf(s, 128, "%s %d", NewTheorems[i].caption, ithm);
    }

    return strdup(s);
}

void resetTheoremCounter(char *unit)

/**************************************************************************
     purpose: resets theorem counters based on unit
**************************************************************************/
{
    int i;

    for (i = 0; i < iNewTheoremCount; i++) {
        if (strequal(unit, NewTheorems[i].within))
            setCounter(NewTheorems[i].numbered_like, 0);
    }
}
