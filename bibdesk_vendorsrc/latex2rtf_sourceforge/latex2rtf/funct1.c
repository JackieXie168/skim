
/* funct1.c - interpret various LaTeX commands and produce RTF

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
	1995      Fernando Dorner, Andreas Granzer, Freidrich Polzer, Gerhard Trisko
    1995-1997 Ralf Schlatterbeck
    1998-2000 Georg Lehner
    2001-2002 Scott Prahl
*/

#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include "main.h"
#include "convert.h"
#include "funct1.h"
#include "commands.h"
#include "stack.h"
#include "l2r_fonts.h"
#include "cfg.h"
#include "ignore.h"
#include "util.h"
#include "encode.h"
#include "parser.h"
#include "counters.h"
#include "lengths.h"
#include "definitions.h"
#include "preamble.h"
#include "xref.h"
#include "equation.h"
#include "direct.h"
#include "style.h"

extern bool twocolumn;          /* true if twocolumn-mode is enabled */
int g_right_margin_indent;
int g_left_margin_indent;

void CmdPagestyle( /* @unused@ */ int code);
void CmdHeader(int code);
char *roman_item(int n, bool upper);

static bool g_paragraph_no_indent = FALSE;
static bool g_paragraph_inhibit_indent = FALSE;
static bool g_page_new = FALSE;
static bool g_column_new = FALSE;
static int g_vertical_space_to_add = 0;
bool g_processing_list_environment = FALSE;

void CmdStartParagraph(int code)

/******************************************************************************
     purpose : RTF codes to create a new paragraph.  If the paragraph should
               not be indented then emit \fi0 otherwise use the current value
               of \parindent as the indentation of the first line.
               
               Sometimes it is necessary to know what the next paragraph will
               be before it has been parsed.  For example, a section command
               should create a paragraph for the section title and then the
               next paragraph encountered should be handled like as a first 
               paragraph.  So status is set to 2 and decremented to 1 when the
               section title paragraph is started.
               
               If the status is 1, then it is the first paragraph in a section.
               Usually the first paragraph is not indented.  However, when the
               document is being typeset in french it should have normal indentation.
               Another special case occurs when the paragraph being typeset is
               in a list environment.  In this case, we need to indent according
               to the current parindent to obtain the proper hanging indentation
               
               If the status is 0, then use the default is to indent according to
               the current parindent.  However, if the g_paragraph_inhibit_indent
               flag or the g_paragraph_no_indent flag is TRUE, then do not indent
               the next line.  Typically these flags are set just after a figure
               or equation or table.
               
               Note that when the code is ANY_PAR, the status flag is not touched.
 ******************************************************************************/
{
    static int status;
    int parindent;

    if (code == TITLE_PAR)
        status = 2;
    if (code == FIRST_PAR)
        status = 1;

    parindent = getLength("parindent");

    diagnostics(5, "CmdStartParagraph mode = %s", TexModeName[GetTexMode()]);
    diagnostics(5, "Noindent is         %s", (g_paragraph_no_indent) ? "TRUE" : "FALSE");
    diagnostics(5, "Inhibit is          %s", (g_paragraph_inhibit_indent) ? "TRUE" : "FALSE");
    diagnostics(5, "indent is           %d", g_left_margin_indent);
    diagnostics(5, "right indent is     %d", g_right_margin_indent);
    diagnostics(5, "paragraph indent is %d", getLength("parindent"));

    if (g_page_new) {
        fprintRTF("\\page ");   /* causes new page */
        g_page_new = FALSE;
        g_column_new = FALSE;
    }

    if (g_column_new) {
        fprintRTF("\\column "); /* causes new page */
        g_column_new = FALSE;
    }

    fprintRTF("\\q%c", alignment);

    if (g_vertical_space_to_add > 0)
        fprintRTF("\\sb%d ", g_vertical_space_to_add);
    g_vertical_space_to_add = 0;

    if (g_left_margin_indent != 0)
        fprintRTF("\\li%d", g_left_margin_indent);

    if (g_right_margin_indent != 0)
        fprintRTF("\\ri%d", g_right_margin_indent);

    /* titles are never indented */
    if (status == 2)
        parindent = 0;

    /* French indents the first paragraph */
    if (status == 1 && !FrenchMode && !g_processing_list_environment)
        parindent = 0;

    /* use indent flags for ANY_PAR */
    if (status <= 0 && (g_paragraph_no_indent || g_paragraph_inhibit_indent))
        parindent = 0;

    fprintRTF("\\fi%d ", parindent);

    SetTexMode(-MODE_HORIZONTAL);   /* negative value avoids calling CmdStartParagraph! */

    if (!g_processing_list_environment) {
        g_paragraph_no_indent = FALSE;
        g_paragraph_inhibit_indent = FALSE;
    }

    status--;
}

void CmdEndParagraph(int code)

/******************************************************************************
     purpose : ends the current paragraph and return to MODE_VERTICAL.
 ******************************************************************************/
{
    int mode = GetTexMode();

    diagnostics(5, "CmdEndParagraph mode = %d", GetTexMode());
    if (mode != MODE_VERTICAL) {
        fprintRTF("\\par\n");
        SetTexMode(-MODE_VERTICAL); /* negative value avoids calling CmdEndParagraph! */
    }

    g_paragraph_inhibit_indent = FALSE;
}

static void DirectVspace(int vspace)
{
    g_vertical_space_to_add = vspace;
}

void CmdVspace(int code)

/******************************************************************************
     purpose : vspace, vspace*, and vskip
     		   code ==  0 if vspace or vspace*
     		   code == -1 if vskip
     		   code ==  1 if \smallskip
     		   code ==  2 if \medskip
     		   code ==  3 if \bigskip
 ******************************************************************************/
{
    int vspace;
    char c;

    switch (code) {
        case VSPACE_VSPACE:
            vspace = getDimension();
            break;

        case VSPACE_VSKIP:
            while ((c = getTexChar()) && c != '{') {
            }
            vspace = getDimension();
            parseBrace();
            break;

        case VSPACE_SMALL_SKIP:
            vspace = getLength("smallskipamount");
            break;

        case VSPACE_MEDIUM_SKIP:
            vspace = getLength("medskipamount");
            break;

        case VSPACE_BIG_SKIP:
            vspace = getLength("bigskipamount");
            break;
    }

    DirectVspace(vspace);
}

void CmdNewDef(int code)

/******************************************************************************
     purpose : handles \def \newcommand \renewcommand
 ******************************************************************************/
{
    char *name, *opt_param, *def, cThis;
    char *params = NULL;
    int param = 0;

    if (code == DEF_DEF) {

        name = getSimpleCommand();
        if (name == NULL) {
            diagnostics(WARNING, "Definition does not start with '\\' skipping");
            return;
        }

        /* handle simple parameters (discard delimiters) e.g., #1#2#3 */
        while ((cThis = getTexChar()) && cThis != '{') {
            if (isdigit((int) cThis))
                param++;
        }
        ungetTexChar('{');

        opt_param = NULL;
        def = getBraceParam();
        UpdateLineNumber(def);
        newDefinition(name + 1, opt_param, def, param);
    }

    if (code == DEF_NEW || code == DEF_RENEW) {
        name = getBraceParam();
        params = getBracketParam();
        opt_param = getBracketParam();
        def = getBraceParam();
        UpdateLineNumber(name);
        UpdateLineNumber(params);
        if (opt_param)
            UpdateLineNumber(opt_param);
        UpdateLineNumber(def);
        param = 0;
        if (params) {
            if ('0' <= *params && *params <= '9')
                param = *params - '0';
            else
                diagnostics(ERROR, "non-numeric number of parameters in newcommand");
        }


        if (code == DEF_NEW)
            newDefinition(name + 1, opt_param, def, param);
        else
            renewDefinition(name + 1, opt_param, def, param);

    }

    diagnostics(3, "CmdNewDef name=<%s> param=%d opt_param=<%s> def=<%s>", name, param, (opt_param) ? opt_param : "",
      def);
    free(name);
    free(def);
    if (params)
        free(params);
    if (opt_param)
        free(opt_param);
}

void CmdNewEnvironment(int code)
{
    char *name, *opt_param, *begdef, *enddef, *params;
    int param;

    name = getBraceParam();
    params = getBracketParam();
    opt_param = getBracketParam();
    begdef = getBraceParam();
    enddef = getBraceParam();
    UpdateLineNumber(name);
    UpdateLineNumber(params);
    if (opt_param)
        UpdateLineNumber(opt_param);
    UpdateLineNumber(begdef);
    UpdateLineNumber(enddef);
    param = 0;
    if (params) {
        if ('0' <= *params && *params <= '9')
            param = *params - '0';
        else
            diagnostics(ERROR, "non-numeric number of parameters in newcommand");
    }

    diagnostics(3, "CmdNewEnvironment name=<%s> param=%d", name, param);
    diagnostics(3, "CmdNewEnvironment begdef=<%s>", begdef);
    diagnostics(3, "CmdNewEnvironment enddef=<%s>", enddef);

    if (code == DEF_NEW)
        newEnvironment(name, opt_param, begdef, enddef, param);
    else
        renewEnvironment(name, opt_param, begdef, enddef, param);

    if (opt_param)
        free(opt_param);
    free(name);
    free(begdef);
    free(enddef);
    if (params)
        free(params);

}

void CmdNewTheorem(int code)
{
    char *name, *caption, *numbered_like, *within;

    name = getBraceParam();
    numbered_like = getBracketParam();
    caption = getBraceParam();
    within = getBracketParam();

    UpdateLineNumber(name);
    UpdateLineNumber(numbered_like);
    UpdateLineNumber(caption);
    UpdateLineNumber(within);

    diagnostics(3, "CmdNewTheorem name=<%s>", name);
    diagnostics(3, "CmdNewTheorem caption=<%s>", caption);
    diagnostics(3, "CmdNewTheorem like=<%s>", (numbered_like) ? numbered_like : "");
    newTheorem(name, caption, numbered_like, within);

    free(name);
    free(caption);
    if (numbered_like)
        free(numbered_like);
    if (within)
        free(within);
}

void CmdIndent(int code)

/******************************************************************************
 purpose : set flags so that CmdStartParagraph() does the right thing
     
     	   INDENT_INHIBIT allows the next paragraph to be indented if
     	   a paragraph break occurs before CmdStartParagraph() is called
     			     		
           INDENT_NONE tells CmdStartParagraph() to not indent the next paragraph
           
           INDENT_USUAL has CmdStartParagraph() use the value of \parindent
 ******************************************************************************/
{
    diagnostics(5, "CmdIndent mode = %d", GetTexMode());
    if (code == INDENT_NONE)
        g_paragraph_no_indent = TRUE;

    else if (code == INDENT_INHIBIT)
        g_paragraph_inhibit_indent = TRUE;

    else if (code == INDENT_USUAL) {
        g_paragraph_no_indent = FALSE;
        g_paragraph_inhibit_indent = FALSE;
    }
    diagnostics(5, "Noindent is %d", (int) g_paragraph_no_indent);
    diagnostics(5, "Inhibit  is %d", (int) g_paragraph_inhibit_indent);
}

void CmdSlashSlash(int code)

/***************************************************************************
 purpose: handle \\, \\[1pt], \\*[1pt] 
 ***************************************************************************/
{
    char cThis, *vertical_space;

    if (g_processing_arrays) {  /* array */
        cThis = getNonBlank();
        ungetTexChar(cThis);
        fprintRTF("%c", g_field_separator);
        return;
    }

    cThis = getTexChar();
    if (cThis != '*')
        ungetTexChar(cThis);

    vertical_space = getBracketParam();
    if (vertical_space)         /* ignore for now */
        free(vertical_space);

    if (g_processing_eqnarray) {    /* eqnarray */
        if (g_processing_fields)
            fprintRTF("}}{\\fldrslt }}");
        if (g_show_equation_number && !g_suppress_equation_number) {
            char number[20];

            for (; g_equation_column < 3; g_equation_column++)
                fprintRTF("\\tab ");
            incrementCounter("equation");

            fprintRTF("\\tab{\\b0 (");
            snprintf(number, 20, "%d", getCounter("equation"));
            InsertBookmark(g_equation_label, number);
            if (g_equation_label) {
                free(g_equation_label);
                g_equation_label = NULL;
            }
            fprintRTF(")}");
        }

        fprintRTF("\\par\n\\tab ");
        if (g_processing_fields)
            fprintRTF("{\\field{\\*\\fldinst{ EQ ");

        g_suppress_equation_number = FALSE;
        g_equation_column = 1;
        return;
    }

/* this should only happen for an array environment */
    if (g_processing_tabular) { /* tabular or array environment */
        if (GetTexMode() == MODE_MATH || GetTexMode() == MODE_DISPLAYMATH) {    /* array */
            fprintRTF("\\par\n\\tab ");
            return;
        }
        for (; actCol < colCount; actCol++) {
            fprintRTF("\\cell\\pard\\intbl");
        }
        actCol = 0;
        fprintRTF("\\row\n\\pard\\intbl\\q%c ", colFmt[actCol]);
        return;
    }

/* I don't think this should happen anymore either! */
    if (g_processing_tabbing) {
        PopBrace();
        PushBrace();
    }

    /* simple end of line ... */
    CmdEndParagraph(0);
    CmdIndent(INDENT_INHIBIT);

    tabcounter = 0;
}

void CmdBeginEnd(int code)

/***************************************************************************
 purpose: reads the parameter after the \begin or \end-command; ( see also getBraceParam )
	      after reading the parameter the CallParamFunc-function calls the
	      handling-routine for that special environment
 parameter: code: CMD_BEGIN: start of environment
		          CMD_END:   end of environment
 ***************************************************************************/
{
    int i;
    char *str, *option;
    char *s = getBraceParam();

    if (code == CMD_BEGIN)
        diagnostics(5, "\\begin{%s}", s);
    else
        diagnostics(5, "\\end{%s}", s);

    if (strcmp(s, "document") == 0) {
        free(s);
        EndSource();            /* done! */
        return;
    }

/* hack to avoid problems with multicols */
    if (strcmp(s, "multicols") == 0) {
        free(s);
        return;
    }

/* user defined environments */
    i = existsEnvironment(s);
    if (i > -1) {
        str = expandEnvironment(i, code);
        ConvertString(str);
        free(str);
        free(s);
        return;
    }

/* theorem environment */
    i = existsTheorem(s);
    if (i > -1) {
        if (code == CMD_BEGIN) {
            option = getBracketParam();
            str = expandTheorem(i, option);
            CmdEndParagraph(0);
            CmdVspace(VSPACE_SMALL_SKIP);
            CmdStartParagraph(FIRST_PAR);
            fprintRTF("{\\b %s} {\\i ", str);
            PushBrace();
            if (option)
                free(option);
            free(str);
        } else {
            PopBrace();
            fprintRTF("}");
            CmdEndParagraph(0);
            CmdVspace(VSPACE_SMALL_SKIP);
            CmdIndent(INDENT_INHIBIT);
        }
        free(s);
        return;
    }

/* usual environments */
    if (code == CMD_BEGIN) {
        diagnostics(4, "\\begin{%s}", s);
        (void) CallParamFunc(s, ON);
    } else {
        diagnostics(4, "\\end{%s}", s);
        (void) CallParamFunc(s, OFF);
        CmdIndent(INDENT_INHIBIT);
    }
    free(s);
}

void CmdAlign(int code)

/*****************************************************************************
    purpose : sets the alignment for a paragraph
  parameter : code: alignment centered, justified, left or right
     globals: alignment: alignment of paragraphs
 ********************************************************************************/
{
    char *s;
    static char old_alignment_before_center = JUSTIFIED;
    static char old_alignment_before_right = JUSTIFIED;
    static char old_alignment_before_left = JUSTIFIED;
    static char old_alignment_before_centerline = JUSTIFIED;

    if (code == PAR_VCENTER) {
        s = getBraceParam();
        free(s);
        return;
    }

    CmdEndParagraph(0);
    switch (code) {
        case (PAR_CENTERLINE):
            old_alignment_before_centerline = alignment;
            alignment = CENTERED;
            fprintRTF("{");
            diagnostics(4, "Entering Convert from CmdAlign (centerline)");
            Convert();
            diagnostics(4, "Exiting Convert from CmdAlign (centerline)");
            alignment = old_alignment_before_centerline;
            CmdEndParagraph(0);
            fprintRTF("}");
            break;

        case (PAR_RAGGEDRIGHT):
            old_alignment_before_centerline = alignment;
            alignment = LEFT;

/*		fprintRTF("{"); */
            diagnostics(4, "Entering Convert from CmdAlign (centerline)");
            Convert();
            diagnostics(4, "Exiting Convert from CmdAlign (centerline)");
            alignment = old_alignment_before_centerline;
            CmdEndParagraph(0);

/*		fprintRTF("}");*/
            break;

        case (PAR_CENTER | ON):
            CmdIndent(INDENT_NONE);
            old_alignment_before_center = alignment;
            alignment = CENTERED;
            break;
        case (PAR_CENTER | OFF):
            alignment = old_alignment_before_center;
            CmdEndParagraph(0);
            CmdIndent(INDENT_INHIBIT);
            break;

        case (PAR_RIGHT | ON):
            old_alignment_before_right = alignment;
            alignment = RIGHT;
            CmdIndent(INDENT_NONE);
            break;
        case (PAR_RIGHT | OFF):
            alignment = old_alignment_before_right;
            CmdIndent(INDENT_INHIBIT);
            break;

        case (PAR_LEFT | ON):
            old_alignment_before_left = alignment;
            alignment = LEFT;
            CmdIndent(INDENT_NONE);
            break;
        case (PAR_LEFT | OFF):
            alignment = old_alignment_before_left;
            CmdIndent(INDENT_INHIBIT);
            break;
        case (PAR_CENTERING):
            CmdIndent(INDENT_NONE);
            old_alignment_before_center = alignment;
            alignment = CENTERED;
            break;
    }
}

void CmdToday(int code)

/******************************************************************************
    purpose: converts LaTeX \today into RTF \chdate
 ******************************************************************************/
{
    SetTexMode(MODE_HORIZONTAL);
    fprintRTF("\\chdate ");
}


void CmdIgnore(int code)

/******************************************************************************
 purpose: allows handling of constructs that do not require changes to RTF
 ******************************************************************************/
{
}

void CmdLdots( /* @unused@ */ int code)

/******************************************************************************
 purpose: converts the LaTeX-\ldots-command into "..." in Rtf
 ******************************************************************************/
{
    if (GetTexMode() != MODE_MATH && GetTexMode() != MODE_DISPLAYMATH)
        SetTexMode(MODE_HORIZONTAL);

    fprintRTF("...");
}

void Environment(int code)

/******************************************************************************
  purpose: pushes/pops the new environment-commands on/from the stack
parameter: code includes the type of the environment
 ******************************************************************************/
{
    if (code & ON) {
        code &= ~(ON);          /* mask MSB */
        diagnostics(4, "Entering Environment (%d)", code);
        PushEnvironment(code);
    } else {                    /* off switch */
        CmdEndParagraph(0);
        diagnostics(4, "Exiting  Environment (%d)", code);
        PopEnvironment();
    }
}

char *FormatUnitNumber(char *name)

/******************************************************************************
  purpose: returns the x.x.x number for the specified sectional unit.
 ******************************************************************************/
{
    char label[20];

    label[0] = '\0';
    if (strcmp(name, "part") == 0) {
        char *s = roman_item(getCounter(name), TRUE);

        snprintf(label, 20, "%s", s);
        free(s);
    }

    else if (strcmp(name, "chapter") == 0) {
        snprintf(label, 20, "%d", getCounter(name));
    }

    else if (strcmp(name, "section") == 0) {
        if (g_document_type == FORMAT_ARTICLE)
            snprintf(label, 20, "%d", getCounter("section"));
        else
            snprintf(label, 20, "%d.%d", getCounter("chapter"), getCounter("section"));
    }

    else if (strcmp(name, "subsection") == 0) {
        if (g_document_type == FORMAT_ARTICLE)
            snprintf(label, 20, "%d.%d", getCounter("section"), getCounter("subsection"));
        else
            snprintf(label, 20, "%d.%d.%d", getCounter("chapter"), getCounter("section"), getCounter("subsection"));
    }

    else if (strcmp(name, "subsubsection") == 0) {
        if (g_document_type == FORMAT_ARTICLE)
            snprintf(label, 20, "%d.%d.%d", getCounter("section"),
              getCounter("subsection"), getCounter("subsubsection"));
        else
            snprintf(label, 20, "%d.%d.%d.%d", getCounter("chapter"),
              getCounter("section"), getCounter("subsection"), getCounter("subsubsection"));
    }

    else if (strcmp(name, "paragraph") == 0) {
        if (g_document_type == FORMAT_ARTICLE)
            snprintf(label, 20, "%d.%d.%d.%d", getCounter("section"),
              getCounter("subsection"), getCounter("subsubsection"), getCounter("paragraph"));
        else
            snprintf(label, 20, "%d.%d.%d.%d.%d", getCounter("chapter"),
              getCounter("section"), getCounter("subsection"), getCounter("subsubsection"), getCounter("paragraph"));
    }

    else if (strcmp(name, "subparagraph") == 0) {
        if (g_document_type == FORMAT_ARTICLE)
            snprintf(label, 20, "%d.%d.%d.%d.%d", getCounter("section"),
              getCounter("subsection"), getCounter("subsubsection"),
              getCounter("paragraph"), getCounter("subparagraph"));
        else
            snprintf(label, 20, "%d.%d.%d.%d.%d.%d", getCounter("chapter"),
              getCounter("section"), getCounter("subsection"),
              getCounter("subsubsection"), getCounter("paragraph"), getCounter("subparagraph"));
    }

    return strdup(label);
}

void CmdSection(int code)

/******************************************************************************
  purpose: converts the LaTeX-section-commands into similar Rtf-styles
parameter: code: type of section-recursion-level
 ******************************************************************************/
{
    char *toc_entry;
    char *heading;
    char *unit_label;

    toc_entry = getBracketParam();
    heading = getBraceParam();

    if (toc_entry) {
        diagnostics(4, "entering CmdSection [%s]{%s}", toc_entry, heading);
        free(toc_entry);
    } else
        diagnostics(4, "entering CmdSection {%s}", heading);

    CmdEndParagraph(0);

    switch (code) {
        case SECT_PART:
        case SECT_PART_STAR:
            CmdNewPage(NewPage);
            CmdStartParagraph(TITLE_PAR);
            fprintRTF("{");
            InsertStyle("part");
            fprintRTF(" ");
            ConvertBabelName("PARTNAME");
            if (code == SECT_PART) {
                incrementCounter("part");
                unit_label = FormatUnitNumber("part");
                fprintRTF(" %s\\par ", unit_label);
                free(unit_label);
            }
            ConvertString(heading);
            CmdEndParagraph(0);
            fprintRTF("}\n");
            CmdNewPage(NewPage);
            break;

        case SECT_CHAPTER:
        case SECT_CHAPTER_STAR:
            CmdNewPage(NewPage);
            CmdStartParagraph(TITLE_PAR);
            fprintRTF("{");
            InsertStyle("chapter");
            fprintRTF(" ");
            ConvertBabelName("CHAPTERNAME");
            if (code == SECT_CHAPTER && getCounter("secnumdepth") >= -1) {
                incrementCounter("chapter");
                setCounter("section", 0);
                setCounter("subsection", 0);
                setCounter("subsubsection", 0);
                setCounter("paragraph", 0);
                setCounter("subparagraph", 0);
        		setCounter("figure",0);
       			setCounter("table",0);
                resetTheoremCounter("chapter");
                unit_label = FormatUnitNumber("chapter");
                fprintRTF(" ");
                InsertBookmark(g_section_label, unit_label);
                free(unit_label);
            }
            fprintRTF("\\par\\par\n");
            ConvertString(heading);
            CmdEndParagraph(0);
            fprintRTF("}");
            CmdVspace(VSPACE_SMALL_SKIP);
            break;

        case SECT_NORM:
        case SECT_NORM_STAR:
            CmdVspace(VSPACE_BIG_SKIP);
            CmdStartParagraph(TITLE_PAR);
            fprintRTF("{");
            InsertStyle("section");
            fprintRTF(" ");
            if (code == SECT_NORM && getCounter("secnumdepth") >= 0) {
                incrementCounter("section");
                setCounter("subsection", 0);
                setCounter("subsubsection", 0);
                setCounter("paragraph", 0);
                setCounter("subparagraph", 0);
                resetTheoremCounter("section");
                unit_label = FormatUnitNumber("section");
                InsertBookmark(g_section_label, unit_label);
                fprintRTF("  ");
                free(unit_label);
            }
            ConvertString(heading);
            CmdEndParagraph(0);
            fprintRTF("}");
            CmdVspace(VSPACE_SMALL_SKIP);
            break;

        case SECT_SUB:
        case SECT_SUB_STAR:
            CmdVspace(VSPACE_MEDIUM_SKIP);
            CmdStartParagraph(TITLE_PAR);
            fprintRTF("{");
            InsertStyle("subsection");
            fprintRTF(" ");
            if (code == SECT_SUB && getCounter("secnumdepth") >= 1) {
                incrementCounter("subsection");
                setCounter("subsubsection", 0);
                setCounter("paragraph", 0);
                setCounter("subparagraph", 0);
                resetTheoremCounter("subsection");
                unit_label = FormatUnitNumber("subsection");
                InsertBookmark(g_section_label, unit_label);
                fprintRTF("  ");
                free(unit_label);
            }
            ConvertString(heading);
            CmdEndParagraph(0);
            fprintRTF("}");
            CmdVspace(VSPACE_SMALL_SKIP);
            break;

        case SECT_SUBSUB:
        case SECT_SUBSUB_STAR:
            CmdVspace(VSPACE_MEDIUM_SKIP);
            CmdStartParagraph(TITLE_PAR);
            fprintRTF("{");
            InsertStyle("subsubsection");
            fprintRTF(" ");
            if (code == SECT_SUBSUB && (getCounter("secnumdepth") > 2 ||
                (g_document_type == FORMAT_ARTICLE && getCounter("secnumdepth") == 2))) {
                incrementCounter("subsubsection");
                setCounter("paragraph", 0);
                setCounter("subparagraph", 0);
                resetTheoremCounter("subsubsection");
                unit_label = FormatUnitNumber("subsubsection");
                InsertBookmark(g_section_label, unit_label);
                fprintRTF("  ");
                free(unit_label);
            }
            ConvertString(heading);
            CmdEndParagraph(0);
            fprintRTF("}");
            CmdVspace(VSPACE_SMALL_SKIP);
            break;

        case SECT_SUBSUBSUB:
        case SECT_SUBSUBSUB_STAR:
            CmdVspace(VSPACE_MEDIUM_SKIP);
            CmdStartParagraph(TITLE_PAR);
            fprintRTF("{");
            InsertStyle("paragraph");
            fprintRTF(" ");
            if (code == SECT_SUBSUBSUB && getCounter("secnumdepth") >= 3) {
                incrementCounter("paragraph");
                resetTheoremCounter("paragraph");
                unit_label = FormatUnitNumber("paragraph");
                setCounter("subparagraph", 0);
                InsertBookmark(g_section_label, unit_label);
                fprintRTF("  ");
                free(unit_label);
            }
            ConvertString(heading);
            CmdEndParagraph(0);
            fprintRTF("} ");
            CmdVspace(VSPACE_SMALL_SKIP);
            break;

        case SECT_SUBSUBSUBSUB:
        case SECT_SUBSUBSUBSUB_STAR:
            CmdVspace(VSPACE_MEDIUM_SKIP);
            CmdStartParagraph(TITLE_PAR);
            fprintRTF("{");
            InsertStyle("subparagraph");
            fprintRTF(" ");
            if (code == SECT_SUBSUBSUBSUB && getCounter("secnumdepth") >= 4) {
                incrementCounter("subparagraph");
                resetTheoremCounter("subparagraph");
                unit_label = FormatUnitNumber("subparagraph");
                InsertBookmark(g_section_label, unit_label);
                fprintRTF("  ");
                free(unit_label);
            }
            ConvertString(heading);
            CmdEndParagraph(0);
            fprintRTF("} ");
            CmdVspace(VSPACE_SMALL_SKIP);
            break;
    }

    if (heading)
        free(heading);
    if (g_section_label) {
        free(g_section_label);
        g_section_label = NULL;
    }
}


void CmdCaption(int code)

/******************************************************************************
 purpose: converts \caption from LaTeX to Rtf
 ******************************************************************************/
{
    char *thecaption;
    char *lst_entry;
    int n, vspace;
    char old_align;
    char number[20];

    old_align = alignment;
    alignment = CENTERED;

    lst_entry = getBracketParam();

    if (lst_entry) {
        diagnostics(4, "entering CmdCaption [%s]", lst_entry);
        free(lst_entry);
    } else
        diagnostics(4, "entering CmdCaption");

    if (GetTexMode() != MODE_VERTICAL)
        CmdEndParagraph(0);
    vspace = getLength("abovecaptionskip");
    DirectVspace(vspace);
    CmdStartParagraph(FIRST_PAR);
    fprintRTF("{");

    if (g_processing_figure) {
        incrementCounter("figure");
        ConvertBabelName("FIGURENAME");
        n = getCounter("figure");
    } else {
        incrementCounter("table");
        ConvertBabelName("TABLENAME");
        n = getCounter("table");
    }

    fprintRTF(" ");
    if (g_document_type != FORMAT_ARTICLE)
        snprintf(number, 20, "%d.%d", getCounter("chapter"), n);
    else
        snprintf(number, 20, "%d", n);

    if (g_processing_figure && g_figure_label)
        InsertBookmark(g_figure_label, number);

    else if (g_processing_table && g_table_label)
        InsertBookmark(g_table_label, number);

    else
        fprintRTF("%s", number);

    fprintRTF(":  ");
    thecaption = getBraceParam();
    diagnostics(4, "in CmdCaption [%s]", thecaption);
    ConvertString(thecaption);
    free(thecaption);
    fprintRTF("}");
    CmdEndParagraph(0);
    vspace = getLength("belowcaptionskip") + getLength("textfloatsep");
    DirectVspace(vspace);
    alignment = old_align;
    diagnostics(4, "exiting CmdCaption");
}

void CmdCounter(int code)

/******************************************************************************
 purpose: handles \newcounter, \setcounter, \addtocounter, \value
 ******************************************************************************/
{
    char *s, *s2, *s3, *s4;
    int num;

    s = getBraceParam();

    diagnostics(4, "Entering CmdCounter(), <%s>", s);

    if (code == COUNTER_ADD || code == COUNTER_SET) {

        s2 = getBraceParam();

        if ((s3 = strchr(s2, '{')) && (s4 = strchr(s2, '}'))) {
            s3++;
            *s4 = '\0';
            diagnostics(4, "CmdCounter() processing \\value{%s}", s3);
            num = getCounter(s3);

        } else if (sscanf(s2, "%d", &num) != 1) {

            fprintf(stderr, "\nBad parameter in set/addcounter{%s}{%s}\n", s, s2);
            free(s2);
            free(s);
            return;
        }

        free(s2);
        if (code == COUNTER_ADD)
            setCounter(s, getCounter(s) + num);
        else
            setCounter(s, num);

    } else if (code == COUNTER_NEW)
        setCounter(s, 0);

    free(s);
}

void CmdLength(int code)

/******************************************************************************
 purpose: handles \newlength, \setlength, \addtolength
 purpose: handle \textwidth=0.8in or \moveright0.1\textwidth
 ******************************************************************************/
{
    char *s, *s1;
    char cThis;
    int num;


    if (code == LENGTH_ADD || code == LENGTH_SET || code == LENGTH_NEW) {
        s = getBraceParam();
        if (strlen(s) <= 1) {
            free(s);
            diagnostics(WARNING, "missing argument in \\newlength \\addtolength or \\setlength");
            return;
        }
        s1 = s + 1;             /* skip initial '\\' */
        diagnostics(4, "Entering CmdLength(), <%s>", s1);
        if (code == LENGTH_ADD || code == LENGTH_SET) {

            cThis = getNonSpace();

            if (cThis == '{') {
                num = getDimension();

                diagnostics(3, "size is <%d> twips", num);
                cThis = getTexChar();

                while (cThis && cThis != '}')
                    cThis = getTexChar();

                if (code == LENGTH_ADD)
                    setLength(s1, getLength(s1) + num);
                else
                    setLength(s1, num);
            } else
                diagnostics(WARNING, "bad parameter to \\addtolength or \\setlength");

        } else
            setLength(s1, 0);

        free(s);

    } else {
        skipSpaces();
        cThis = getTexChar();

        if (cThis == '=')       /* optional '=' */
            skipSpaces();
        else
            ungetTexChar(cThis);

        num = getDimension();   /* discard for now */
    }
}

void CmdQuote(int code)

/******************************************************************************
  purpose: handles \begin{quote} ... \end{quote} 
                   \begin{quotation} ... \end{quotation}
  globals:   indent which is the left-indent-position
 ******************************************************************************/
{
    CmdEndParagraph(0);

    switch (code) {
        case (QUOTATION | ON):
            PushEnvironment(GENERIC_ENV);
            diagnostics(4, "Entering \\begin{quotation}");
            CmdVspace(VSPACE_SMALL_SKIP);
            g_left_margin_indent += 512;
            g_right_margin_indent += 512;
            CmdIndent(INDENT_USUAL);
            break;

        case (QUOTE | ON):
            PushEnvironment(GENERIC_ENV);
            diagnostics(4, "Entering \\begin{quote}");
            CmdVspace(VSPACE_SMALL_SKIP);
            g_left_margin_indent += 512;
            g_right_margin_indent += 512;
            setLength("parindent", 0);
            CmdIndent(INDENT_USUAL);
            break;

        case (QUOTATION | OFF):
        case (QUOTE | OFF):
            PopEnvironment();
            diagnostics(4, "Exiting \\end{quote} or \\end{quotation}");
            CmdIndent(INDENT_INHIBIT);
            CmdVspace(VSPACE_SMALL_SKIP);
    }
}

void CmdList(int code)

/******************************************************************************
  purpose : set indentation and counters for itemize, description and enumerate
 globals  : indent
 ******************************************************************************/
{
    int vspace;
    int amount = 300;

    vspace = getLength("topsep") + getLength("parskip");

    if (GetTexMode() == MODE_VERTICAL)
        vspace += getLength("partopsep");
    else
        CmdEndParagraph(0);

    switch (code) {
        case (ITEMIZE | ON):
            DirectVspace(vspace);
            PushEnvironment(ITEMIZE);
            setLength("parindent", -amount);
            g_left_margin_indent += 2 * amount;
            CmdIndent(INDENT_USUAL);
            break;

        case (ENUMERATE | ON):
            DirectVspace(vspace);
            PushEnvironment(ENUMERATE);
            g_enumerate_depth++;
            CmdItem(RESET_ITEM_COUNTER);
            setLength("parindent", -amount);
            g_left_margin_indent += 2 * amount;
            CmdIndent(INDENT_USUAL);
            break;

        case (DESCRIPTION | ON):
            DirectVspace(vspace);
            PushEnvironment(DESCRIPTION);
            setLength("parindent", -amount);
            g_left_margin_indent += amount;
            CmdIndent(INDENT_USUAL);
            break;

        case (ENUMERATE | OFF):
            g_enumerate_depth--;    /* fall through */
        case (ITEMIZE | OFF):
        case (DESCRIPTION | OFF):
            PopEnvironment();
            CmdIndent(INDENT_USUAL);    /* need to reset INDENT_NONE from CmdItem */
            g_processing_list_environment = FALSE;
            DirectVspace(vspace);
            break;
    }
}

void CmdItem(int code)

/******************************************************************************
 purpose : handles \item command.  Since the \item command is delimited by 
           a later \item command or the ending of an environment (\end{itemize})
           this routine will get called recursively.
 ******************************************************************************/
{
    char *itemlabel, thechar;
    static int item_number[4];
    int vspace;

    if (code == RESET_ITEM_COUNTER) {
        item_number[g_enumerate_depth] = 1;
        return;
    }

    diagnostics(4, "Entering CmdItem depth=%d item=%d", g_enumerate_depth, item_number[g_enumerate_depth]);

    g_processing_list_environment = TRUE;
    CmdEndParagraph(0);
    vspace = getLength("itemsep") + getLength("parsep");
    DirectVspace(vspace);

    CmdIndent(INDENT_USUAL);
    CmdStartParagraph(FIRST_PAR);

    itemlabel = getBracketParam();
    if (itemlabel) {            /* \item[label] */
        fprintRTF("{");
        if (code == DESCRIPTION)
            fprintRTF("\\b ");
        diagnostics(5, "Entering ConvertString from CmdItem");
        ConvertString(itemlabel);
        diagnostics(5, "Exiting ConvertString from CmdItem");
        fprintRTF("}");
        if (code != DESCRIPTION)
            fprintRTF("\\tab ");
    }

    switch (code) {
        case ITEMIZE:
            if (!itemlabel) {
                if (FrenchMode)
                    fprintRTF("\\endash\\tab ");
                else
                    fprintRTF("\\bullet\\tab ");
            }
            break;

        case ENUMERATE:
            if (itemlabel)
                break;
            switch (g_enumerate_depth) {
                case 1:
                    fprintRTF("%d.", item_number[g_enumerate_depth]);
                    break;

                case 2:
                    fprintRTF("(%c)", 'a' + item_number[g_enumerate_depth] - 1);
                    break;

                case 3:
                    fprintRTF("%s.", roman_item(item_number[g_enumerate_depth], FALSE));
                    break;

                case 4:
                    fprintRTF("%c.", 'A' + item_number[g_enumerate_depth] - 1);
                    break;
            }
            fprintRTF("\\tab ");
            item_number[g_enumerate_depth]++;
            break;

        case DESCRIPTION:
            fprintRTF(" ");
            break;
    }

    if (itemlabel)
        free(itemlabel);
    thechar = getNonBlank();
    ungetTexChar(thechar);
    CmdIndent(INDENT_NONE);
}

void CmdBox(int code)

/******************************************************************************
  purpose: converts the LaTeX \box-commands into  an similar Rtf-style
 ******************************************************************************/
{
    char BoxName[5][10] = { "hbox", "vbox", "mbox", "fbox", "parbox" };
    int mode = GetTexMode();

    diagnostics(2, "Entering CmdBox() [%s]", BoxName[code - 1]);
    if (g_processing_fields)
        g_processing_fields++;  /* hack to stop fields within fields */

    if (code == BOX_HBOX || code == BOX_MBOX)
        SetTexMode(MODE_RESTRICTED_HORIZONTAL);

    if (code == BOX_PARBOX) {
        char *position, *width;

        position = getBracketParam();
        width = getBraceParam();
        if (position)
            free(position);
        free(width);
    }

    diagnostics(4, "Entering Convert() from CmdBox");
    Convert();
    diagnostics(4, "Exiting Convert() from CmdBox");

    if (g_processing_fields)
        g_processing_fields--;

    if (code == BOX_VBOX) {
        CmdEndParagraph(0);
        CmdIndent(INDENT_INHIBIT);

    } else {
        SetTexMode(mode);
    }

    diagnostics(2, "Exited CmdBox() [%s]", BoxName[code - 1]);
}

void CmdVerb(int code)

/******************************************************************************
 purpose: converts the LaTeX-verb-environment to a similar Rtf-style
 		  \url probably does not handle line feeds properly
 ******************************************************************************/
{
    char cThis, *text, *s;
    char markingchar;
    int num;

    SetTexMode(MODE_HORIZONTAL);
    num = TexFontNumber("Typewriter");
    fprintRTF("{\\b0\\i0\\scaps0\\f%d ", num);

    if (code == VERB_URL) {
        cThis = getNonSpace();
        if (cThis == '{') {     /* \url{http://} */
            text = getDelimitedText('{', '}', TRUE);
            s = text;
            diagnostics(4, "CmdVerbatim \\url{%s}", text);
            while (*s) {
                putRtfChar(*s);
                s++;
            }
            fprintRTF("}");
            free(text);
            return;
        } else
            markingchar = cThis;    /* \url|http://| */

    }

    if (code == VERB_STAR || code == VERB_VERB) {

        while ((cThis = getRawTexChar())) {
            if ((cThis != ' ') && (cThis != '*') && !isalpha((int) cThis)) {
                markingchar = cThis;
                break;
            }
        }
    }


    while ((cThis = getRawTexChar()) && cThis != markingchar)
        putRtfChar(cThis);

    fprintRTF("}");
}

void CmdVerbatim(int code)

/******************************************************************************
	convert characters 1:1 until \end{verbatim} or \end{Verbatim} is reached
	VERBATIM_1	 for \begin{verbatim} ... \end{verbatim}
	VERBATIM_2   for \begin{Verbatim} ... \end{Verbatim}
******************************************************************************/
{
    char *verbatim_text, *vptr, *endtag;
    int num;
    int true_code = code & ~ON;

    if (code & ON) {

        diagnostics(4, "Entering CmdVerbatim");

        if (true_code != VERBATIM_4) {

            CmdEndParagraph(0);
            CmdIndent(INDENT_NONE);
            CmdStartParagraph(FIRST_PAR);
            num = TexFontNumber("Typewriter");
            fprintRTF("\\pard\\ql\\b0\\i0\\scaps0\\f%d ", num);
        }

        switch (true_code) {
            case VERBATIM_1:
                endtag = strdup("\\end{verbatim}");
                break;
            case VERBATIM_2:
                endtag = strdup("\\end{Verbatim}");
                break;
            case VERBATIM_3:
                endtag = strdup("\\end{alltt}");
                break;
            case VERBATIM_4:
                endtag = strdup("\\end{comment}");
                break;
        }

        verbatim_text = getTexUntil(endtag, 1);
        UpdateLineNumber(verbatim_text);
        vptr = verbatim_text;

        if (true_code == VERBATIM_3)
            /* alltt environment */
            ConvertAllttString(verbatim_text);

        else if (true_code == VERBATIM_1 || true_code == VERBATIM_2) {

            while (*vptr) {
                diagnostics(5, "Verbatim character <%c>", *vptr);
                putRtfChar(*vptr++);
            }
        }

        free(verbatim_text);
        ConvertString(endtag);
        free(endtag);

    } else {
        diagnostics(4, "Exiting CmdVerbatim");

        if (true_code != VERBATIM_4)
            CmdEndParagraph(0);
    }

}

void CmdVerse(int code)

/******************************************************************************
  purpose: converts the LaTeX-Verse-environment to a similar Rtf-style
 ******************************************************************************/
{
    CmdEndParagraph(0);
    switch (code) {
        case ON:
            PushEnvironment(GENERIC_ENV);
            CmdIndent(INDENT_USUAL);
            g_left_margin_indent += 1134;
            setLength("parindent", 0);
            break;
        case OFF:
            PopEnvironment();
            diagnostics(4, "Exiting \\end{verse}");
            CmdIndent(INDENT_INHIBIT);
            CmdVspace(VSPACE_SMALL_SKIP);
            break;
    }
}


void CmdIgnoreDef( /* @unused@ */ int code)

/*****************************************************************************
 purpose: newenvironments or newcommands which are defined by the user aren't
	      converted into Rtf and so they must be ignored
 ******************************************************************************/
{
    char cThis;

    while ((cThis = getTexChar()) && cThis != '{') {
    }

    parseBrace();

}

void TranslateGerman(void)

/***************************************************************************
purpose: called on active german-mode and " character in input file to
	 handle " as an active (meta-)character.
 ***************************************************************************/
{
    char cThis;

    cThis = getTexChar();

    switch (cThis) {
        case 'a':
            fprintRTF("\\'e4");
            break;
        case 'o':
            fprintRTF("\\'f6");
            break;
        case 'u':
            fprintRTF("\\'fc");
            break;
        case 's':
            fprintRTF("\\'df");
            break;
        case 'A':
            fprintRTF("\\'c4");
            break;
        case 'O':
            fprintRTF("\\'d6");
            break;
        case 'U':
            fprintRTF("\\'dc");
            break;
        case '|':
            break;              /* ignore */
        case '-':
            break;              /* ignore */
        case '"':
            break;              /* ignore */
        case '\'':
            fprintRTF("\\ldblquote ");
            break;
        case '`':
            fprintRTF("{\\'84}");
            break;
        case '<':
            break;
        case '>':
            break;
        default:
            fprintRTF("%c", cThis);
    }
}

void GermanPrint(int code)
{
    switch (code) {
        case GP_CK:
            fprintRTF("ck");
            break;
        case GP_LDBL:
            fprintRTF("{\\'84}");
            break;
        case GP_L:
            fprintRTF(",");
            break;
        case GP_R:
            fprintRTF("\\lquote");
            break;
        case GP_RDBL:
            fprintRTF("\\ldblquote");
    }
}


void CmdIgnoreLet( /* @unused@ */ int code)

/******************************************************************************
     purpose : ignore \let 
	   Format: \let\XXXXX = \YYYYYY or \let\XXXXX\YYYYYY
 ******************************************************************************/
{
    char cThis;

    while ((cThis = getTexChar()) && cThis != ' ' && cThis != '\\') {
    }

    if (cThis == ' ') {
        skipSpaces();
        while ((cThis = getTexChar()) && cThis != ' ') {
        }
        skipSpaces();
    }
}

void CmdQuad(int kk)

/******************************************************************************
 purpose: inserts kk quad spaces (D. Taupin)
 ******************************************************************************/
{
    int z;

    fprintRTF("{\\emspace ");
    for (z = 0; z < kk; z++)
        fprintRTF(" ");
    fprintRTF("}");
}

void CmdSpace(float kk)

/******************************************************************************
 purpose: inserts a space of width kk*space 
 ******************************************************************************/
{
    int size = CurrentFontSize() * kk;

    fprintRTF("{\\fs%d  }", size);
}

void CmdFigure(int code)

/******************************************************************************
  purpose: Process \begin{figure} ... \end{figure} environment
  		   This is only complicated because we need to know what to
  		   label the caption before the caption is processed.  So 
  		   we just slurp the figure environment, extract the tag, and
  		   then process the environment as usual.
 ******************************************************************************/
{
    char *loc, *figure_contents;
    char *endfigure = ((code & ~ON) == FIGURE) ? "\\end{figure}" : "\\end{figure*}";
	static char     oldalignment;
			
    if (code & ON) {
		CmdEndParagraph(0);
		oldalignment = alignment;
		alignment = JUSTIFIED;

		CmdVspace(VSPACE_BIG_SKIP);
		CmdStartParagraph(0);
        loc = getBracketParam();
        diagnostics(4, "entering CmdFigure [%s]", (loc) ? loc : "");
        g_processing_figure = TRUE;
        if (loc)
            free(loc);
        figure_contents = getTexUntil(endfigure, TRUE);
        g_figure_label = ExtractLabelTag(figure_contents);
        if (g_latex_figures) {
            char *caption, *label;

            caption = ExtractAndRemoveTag("\\caption", figure_contents);
            label = ExtractAndRemoveTag("\\label", figure_contents);
            CmdEndParagraph(0);
            CmdVspace(VSPACE_SMALL_SKIP);
            CmdStartParagraph(FIRST_PAR);
            WriteLatexAsBitmap("\\begin{figure}", figure_contents, "\\end{figure}");
            ConvertString(caption);
            if (label)
                free(label);
            if (caption)
                free(caption);
        } else
            ConvertString(figure_contents);
        ConvertString(endfigure);
        free(figure_contents);
    } else {
        if (g_figure_label)
            free(g_figure_label);
        g_processing_figure = FALSE;
        diagnostics(4, "exiting CmdFigure");
		alignment = oldalignment;
		CmdEndParagraph(0);
		CmdVspace(VSPACE_BIG_SKIP);
    }
}

void CmdIgnoreEnviron(int code)

/******************************************************************************
  purpose: function to ignore \begin{environ} ... \end{environ}
 ******************************************************************************/
{
    char *endtag = NULL;
    char *s = NULL;

    if (code & ON) {

        switch (code & ~(ON)) {

            case IGNORE_MINIPAGE:
                endtag = strdup("\\end{minipage}");
                break;

            case IGNORE_HTMLONLY:
                endtag = strdup("\\end{htmlonly}");
                break;

            case IGNORE_RAWHTML:
                endtag = strdup("\\end{rawhtml}");
                break;
        }

        if (endtag) {
            s = getTexUntil(endtag, 0);
            ConvertString(endtag);
            if (s)
                free(s);
            free(endtag);
        }
    }
}

void FixTildes(char *s)
{
    char *p, *p3;

    while ((p = strstr(s, "\\~{}")) != NULL) {
        *p = '~';
        p++;
        p3 = p + 3;
        while (*p3) {
            *p++ = *p3++;
        }
        *p = '\0';
    }
}

void CmdTextColor(int code)

/******************************************************************************
  purpose: hyperlatex support for \textcolor{color}{words to be in color}
******************************************************************************/
{
    char *color, *text, *color1, *text1;
    int n;

    diagnostics(4, "Entering CmdTextColor");
    color1 = getBraceParam();
    text1 = getBraceParam();
    color = strdup_noendblanks(color1);
    text = strdup_noendblanks(text1);
    free(color1);
    free(text1);

    n = -1;
    if (strcmp(color, "black") == 0)
        n = 1;
    else if (strcmp(color, "blue") == 0)
        n = 2;
    else if (strcmp(color, "cyan") == 0)
        n = 3;
    else if (strcmp(color, "green") == 0)
        n = 4;
    else if (strcmp(color, "magenta") == 0)
        n = 5;
    else if (strcmp(color, "red") == 0)
        n = 6;
    else if (strcmp(color, "yellow") == 0)
        n = 7;
    else if (strcmp(color, "white") == 0)
        n = 8;
    else if (strcmp(color, "gray") == 0)
        n = 16;

    if (n > 0) {
        fprintRTF("{\\cf%d ", n);
        ConvertString(text);
        fprintRTF("}");
    }

    free(text);
    free(color);
}

void CmdLink(int code)

/******************************************************************************
  purpose: hyperlatex support for \link{anchor}[ltx]{label}
                              and \xlink{anchor}[printed reference]{URL}
******************************************************************************/
{
    char *anchor, *latex, *url;

    diagnostics(4, "Entering hyperlatex \\link command");
    anchor = getBraceParam();
    latex = getBracketParam();
    url = getBraceParam();

    FixTildes(url);
    fprintRTF("{\\field\\fldedit{\\*\\fldinst { HYPERLINK \"%s\" \\\\* MERGEFORMAT }}", url);
    fprintRTF("{\\fldrslt {\\cs15\\ul\\cf2 ");
    ConvertString(anchor);
    fprintRTF("}}}");

    if (latex)
        free(latex);
    free(anchor);
    free(url);
}

void CmdColumn(int code)

/******************************************************************************
  purpose: chooses between one/two-columns
parameter: number of columns
 globals: twocolumn: true if twocolumn-mode is set
 ******************************************************************************/
{
    switch (code) {
        case One_Column:
            fprintRTF("\\page \\colsx709\\endnhere ");  /* new page & one column */
            twocolumn = FALSE;
            break;
        case Two_Column:
            fprintRTF("\\page \\cols2\\colsx709\\endnhere ");   /* new page & two * columns */
            twocolumn = TRUE;
            break;
    }                           /* switch */
}

void CmdNewPage(int code)

/******************************************************************************
  purpose: starts a new page
parameter: code: newpage or newcolumn-option
 globals: twocolumn: true if twocolumn-mode is set
 ******************************************************************************/
{
    switch (code) {
        case NewPage:
            g_page_new = TRUE;
            break;

        case NewColumn:
            g_column_new = TRUE;
            break;
    }
}

void Cmd_OptParam_Without_braces( /* @unused@ */ int code)

/******************************************************************************
 purpose: gets an optional parameter which isn't surrounded by braces but by spaces
 ******************************************************************************/
{
    char cNext = ' ';
    char cLast = ' ';

    do {
        cLast = cNext;
        cNext = getTexChar();
    } while ((cNext != ' ') &&
      (cNext != '\\') &&
      (cNext != '{') && (cNext != '\n') && (cNext != ',') && ((cNext != '.') || (isdigit((int) cLast))) &&
      /* 
       * . doesn't mean the end of an command inside an number of the type
       * real
       */
      (cNext != '}') && (cNext != '\"') && (cNext != '[') && (cNext != '$'));

    ungetTexChar(cNext);
}

void CmdBottom(int code)

/******************************************************************************
  purpose: ignore raggedbottom command
 ******************************************************************************/
{
}

/******************************************************************************
parameter: code: on/off-option
 globals : article and titlepage from the documentstyle
 ******************************************************************************/
void CmdAbstract(int code)
{
    static char oldalignment;

    CmdEndParagraph(0);

    if (code == ON) {
        if (g_document_type == FORMAT_REPORT || titlepage)
            CmdNewPage(NewPage);

        CmdStartParagraph(FIRST_PAR);
        fprintRTF("\\qc{\\b ");
        ConvertBabelName("ABSTRACTNAME");
        fprintRTF("}");
        CmdEndParagraph(0);
        g_left_margin_indent += 1024;
        g_right_margin_indent += 1024;
        oldalignment = alignment;
        alignment = JUSTIFIED;

    } else {
        g_left_margin_indent -= 1024;
        g_right_margin_indent -= 1024;
        alignment = oldalignment;
        CmdVspace(VSPACE_MEDIUM_SKIP);  /* put \medskip after abstract */
    }
}

void
CmdAcknowledgments(int code)
{
	static char     oldalignment;

	CmdEndParagraph(0);
	
	if (code == ON) {
		
		CmdVspace(VSPACE_BIG_SKIP);
		CmdStartParagraph(0);
		fprintRTF("\n{\\b ");
		fprintRTF("Acknowledgments"); /* should be in cfg file, but it is not */
		fprintRTF("}\n");
		CmdEndParagraph(0);
		oldalignment = alignment;
		alignment = JUSTIFIED;

	} else {
		alignment = oldalignment;
		CmdVspace(VSPACE_BIG_SKIP);				/* put \medskip after acknowledgments */
	}
}


void 
CmdTitlepage(int code)
/******************************************************************************
  purpose: \begin{titlepage} ... \end{titlepage}
           add pagebreaks before and after this environment
 ******************************************************************************/
{
    CmdNewPage(NewPage);
    switch (code && 0) {
        case ON:
            fprintRTF("\n\\par\\pard \\page "); /* new page */
            fprintRTF("\n\\par\\q%c ", alignment);
            break;
        case OFF:
            fprintRTF("\\pard ");
            fprintRTF("\n\\par\\q%c \\page ", alignment);
            break;
    }
}

void CmdMinipage(int code)

/******************************************************************************
  purpose: recognize and parse Minipage parameters
  		   currently this does nothing
 ******************************************************************************/
{
    char *v_align, *width;

    switch (code) {
        case ON:
            v_align = getBracketParam();
            width = getBraceParam();
            if (v_align)
                free(v_align);
            free(width);
            break;
        case OFF:
            break;
    }
}

void CmdColsep(int code)

/***************************************************************************
 * purpose: hyperlatex support, handles '&' as in Convert() in convert.c
 only called by \S
 ***************************************************************************/
{
    if (!g_processing_tabular) {
        fprintRTF("{\\'a7}");
        return;
    }
    actCol++;

    if (GetTexMode() == MODE_DISPLAYMATH) { /* in an eqnarray or array environment */
        fprintRTF("\\tab ");
    } else {
        fprintRTF("\\cell\\pard\\intbl ");
        if (colFmt == NULL)
            diagnostics(WARNING, "Fatal, Fatal! CmdColsep called whith colFmt == NULL.");
        else
            fprintRTF("\\q%c ", colFmt[actCol]);
    }
}

void CmdVerbosityLevel(int code)

/***************************************************************************
 * purpose: insert \verbositylevel{5} in the tex file to set the verbosity 
            in the LaTeX file!
 ***************************************************************************/
{
    char *s = getBraceParam();

    g_verbosity_level = atoi(s);
    free(s);

}


/* convert integer to roman number --- only works up correctly up to 39 */

char *roman_item(int n, bool upper)
{
    char s[50];
    int i = 0;

    while (n >= 10) {
        n -= 10;
        s[i] = (upper) ? 'X' : 'x';
        i++;
    }

    if (n == 9) {
        s[i] = (upper) ? 'I' : 'i';
        i++;
        s[i] = (upper) ? 'X' : 'x';
        i++;
        s[i] = '\0';
        return strdup(s);
    }
    if (n >= 5) {
        n -= 5;
        s[i] = (upper) ? 'V' : 'v';
        i++;
    }
    if (n == 4) {
        s[i] = (upper) ? 'I' : 'i';
        i++;
        s[i] = (upper) ? 'V' : 'v';
        i++;
        s[i] = '\0';
        return strdup(s);
    }
    while (n >= 1) {
        n -= 1;
        s[i] = (upper) ? 'I' : 'i';
        i++;
    }

    s[i] = '\0';
    return strdup(s);
}

void CmdNonBreakSpace(int code)
{
    char cThis = getNonSpace();

    ungetTexChar(cThis);
    fprintRTF("\\~");
}

void CmdInclude(int code)

/******************************************************************************
 purpose: handles \input file, \input{file}, \include{file}
 ******************************************************************************/
{
    char name[50], *s, *t, cNext;
    int i;

    cNext = getNonSpace();

    if (cNext == '{') {         /* \input{gnu} or \include{gnu} */
        ungetTexChar(cNext);
        s = getBraceParam();

    } else {                    /* \input gnu */
        name[0] = cNext;
        for (i = 1; i < 50; i++) {
            name[i] = getTexChar();
            if (isspace((int) name[i])) {
                name[i] = '\0';
                break;
            }
        }
        s = strdup(name);
    }

    if (strstr(s, ".tex") == NULL) {    /* append .tex if missing */
        t = strdup_together(s, ".tex");
        free(s);
        s = t;
    }

    if (PushSource(s, NULL) == 0)
        diagnostics(WARNING, "Including file <%s>", t);
    free(s);
}

void CmdIf(int code)

/******************************************************************************
 purpose: handles \ifx by skippint to next \fi
 ******************************************************************************/
{
    char *s = getTexUntil("\\fi", FALSE);

    if (s)
        free(s);
}

void CmdEndInput(int code)

/******************************************************************************
 purpose: handles \endinput
 ******************************************************************************/
{
    PopSource();
}
