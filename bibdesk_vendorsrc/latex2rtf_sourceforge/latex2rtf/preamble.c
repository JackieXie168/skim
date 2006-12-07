
/* preamble.c - Handles LaTeX commands that should only occur in the preamble.

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
*/

#include <stdlib.h>
#include <string.h>
#include "main.h"
#include "convert.h"
#include "util.h"
#include "preamble.h"
#include "l2r_fonts.h"
#include "cfg.h"
#include "encode.h"
#include "parser.h"
#include "funct1.h"
#include "lengths.h"
#include "ignore.h"
#include "commands.h"
#include "counters.h"
#include "xref.h"
#include "direct.h"
#include "style.h"

static bool g_preambleTwoside = FALSE;
static bool g_preambleTwocolumn = FALSE;
static bool g_preambleTitlepage = FALSE;
static bool g_preambleLandscape = FALSE;

static char *g_preambleTitle = NULL;
static char *g_preambleAuthor = NULL;
static char *g_preambleDate = NULL;
static char *g_preambleEncoding = NULL;

static char *g_preambleCFOOT = NULL;
static char *g_preambleLFOOT = NULL;
static char *g_preambleRFOOT = NULL;
static char *g_preambleCHEAD = NULL;
static char *g_preambleLHEAD = NULL;
static char *g_preambleRHEAD = NULL;

static void setPaperSize(char *size);
static void setDocumentOptions(char *optionlist);
static void WriteFontHeader(void);
static void WriteStyleHeader(void);
static void WritePageSize(void);

void setPackageBabel(char *option)
{
    if (strcmp(option, "german") == 0 || strcmp(option, "ngerman") == 0) {
        GermanMode = TRUE;
        PushEnvironment(GERMAN_MODE);
        ReadLanguage("german");
    }

    if (strcmp(option, "french") == 0 || strcmp(option, "frenchb") == 0) {
        FrenchMode = TRUE;
        PushEnvironment(FRENCH_MODE);
        ReadLanguage("french");
    }

    if (strcmp(option, "russian") == 0) {
        RussianMode = TRUE;
        PushEnvironment(RUSSIAN_MODE);
        ReadLanguage("russian");
    }

    if (strcmp(option, "czech") == 0) {
        CzechMode = TRUE;
        PushEnvironment(CZECH_MODE);
        ReadLanguage("czech");
        g_fcharset_number = 238;    /* East European in RTF Specification */
        strcpy(g_charset_encoding_name, "raw");
    }

}

void setPackageInputenc(char *option)
{
    g_preambleEncoding = strdup_noblanks(option);

    if (strcmp(option, "ansinew") == 0)
        strcpy(g_charset_encoding_name, "cp1252");

    else if (strcmp(option, "applemac") == 0 ||
      strcmp(option, "decmulti") == 0 ||
      strcmp(option, "latin1") == 0 ||
      strcmp(option, "latin2") == 0 ||
      strcmp(option, "latin3") == 0 ||
      strcmp(option, "latin4") == 0 ||
      strcmp(option, "latin5") == 0 ||
      strcmp(option, "latin9") == 0 ||
      strcmp(option, "next") == 0 ||
      strcmp(option, "cp437") == 0 ||
      strcmp(option, "cp437de") == 0 ||
      strcmp(option, "cp850") == 0 ||
      strcmp(option, "cp852") == 0 ||
      strcmp(option, "cp855") == 0 ||
      strcmp(option, "cp865") == 0 ||
      strcmp(option, "cp866") == 0 ||
      strcmp(option, "cp1250") == 0 ||
      strcmp(option, "cp1251") == 0 ||
      strcmp(option, "cp1252") == 0 ||
      strcmp(option, "437") == 0 ||
      strcmp(option, "437de") == 0 ||
      strcmp(option, "850") == 0 ||
      strcmp(option, "852") == 0 ||
      strcmp(option, "855") == 0 ||
      strcmp(option, "865") == 0 ||
      strcmp(option, "866") == 0 ||
      strcmp(option, "1250") == 0 ||
      strcmp(option, "1251") == 0 ||
      strcmp(option, "1252") == 0 ||
      strcmp(option, "maccyr") == 0 ||
      strcmp(option, "macukr") == 0 || strcmp(option, "koi8-r") == 0 || strcmp(option, "koi8-u") == 0) {

        strcpy(g_charset_encoding_name, option);
        g_fcharset_number = 0;  /* ANSI in RTF Specification */

    } else if (strcmp(option, "raw") == 0) {
        strcpy(g_charset_encoding_name, "raw");
        g_fcharset_number = 255;    /* OEM in RTF Specification */

    } else if (strcmp(option, "raw437") == 0) {
        g_fcharset_number = 254;    /* IBM PC in RTF Specification */
        strcpy(g_charset_encoding_name, "raw");

    } else if (strcmp(option, "raw852") == 0) {
        g_fcharset_number = 255;    /* Microsoft bug ... */
        strcpy(g_charset_encoding_name, "raw");

    } else if (strcmp(option, "raw1250") == 0) {
        g_fcharset_number = 238;    /* East European in RTF Specification */
        strcpy(g_charset_encoding_name, "raw");

    } else if (strcmp(option, "raw1251") == 0) {
        g_fcharset_number = 204;    /* Cyrillic in RTF Specification */
        strcpy(g_charset_encoding_name, "raw");

    } else if (strcmp(option, "raw1253") == 0) {
        g_fcharset_number = 161;    /* Greek in RTF Specification */
        strcpy(g_charset_encoding_name, "raw");

    } else
        diagnostics(WARNING, "\n Input Encoding <%s> not supported", option);
}

static void setPackageFont(char *font)
{
    int fnumber = -1;

    if (strcmp(font, "palatino") == 0)
        fnumber = RtfFontNumber("Palatino");

    else if (strstr(font, "times"))
        fnumber = RtfFontNumber("Times");

    else if (strstr(font, "chancery"))
        fnumber = RtfFontNumber("Zapf Chancery");

    else if (strstr(font, "courier"))
        fnumber = RtfFontNumber("Courier");

    else if (strstr(font, "avant"))
        fnumber = RtfFontNumber("Avant Garde");

    else if (strstr(font, "helvet"))
        fnumber = RtfFontNumber("Helvetica");

    else if (strstr(font, "newcen"))
        fnumber = RtfFontNumber("New Century Schoolbook");

    else if (strstr(font, "book"))
        fnumber = RtfFontNumber("Bookman");

    InitializeDocumentFont(fnumber, -1, -1, -1);
    if (fnumber == -1)
        fprintf(stderr, "\n Font Package <%s> not supported yet", font);
}

static void setThree(char *s, int ten, int eleven, int twelve)
{
    int n = DefaultFontSize();

    if (n == 20)
        setLength(s, ten * 20);
    else if (n == 22)
        setLength(s, eleven * 20);
    else
        setLength(s, twelve * 20);
}

static void setPaperSize(char *option)

/******************************************************************************
   Should also try to reset some of the other sizes at this time
******************************************************************************/
{
    if (strcmp(option, "landscape") == 0) {
        g_preambleLandscape = TRUE;

    } else if (strcmp(option, "a4paper") == 0) {

        setLength("pageheight", 845 * 20);
        setLength("hoffset", 0 * 20);
        setThree("oddsidemargin", 53, 46, 31);
        setLength("headheight", 12 * 20);
        setThree("textheight", 598, 596, 592);
        setLength("footskip", 30 * 20);
        setLength("marginparpush", 5 * 20);

        setLength("pagewidth", 598 * 20);
        setLength("voffset", 0 * 20);
        setLength("topmargin", 17 * 20);
        setLength("headsep", 25 * 20);
        setThree("textwidth", 345, 360, 390);
        setLength("marginparsep", 10 * 20);
        setLength("columnsep", 10 * 20);

    } else if (strcmp(option, "a4") == 0) {

        setLength("pageheight", 845 * 20);
        setLength("hoffset", 0 * 20);
        setThree("oddsidemargin", 40, 33, 14);
        setLength("headheight", 12 * 20);
        setThree("textheight", 646, 637, 621);
        setLength("footskip", 30 * 20);
        setLength("marginparpush", 5 * 20);

        setLength("pagewidth", 598 * 20);
        setLength("voffset", 0 * 20);
        setLength("topmargin", 0 * 20);
        setLength("headsep", 25 * 20);
        setThree("textwidth", 361, 376, 412);
        setLength("marginparsep", 10 * 20);
        setLength("columnsep", 10 * 20);

    } else if (strcmp(option, "a4wide") == 0) {

        setLength("pageheight", 845 * 20);
        setLength("hoffset", 0 * 20);
        setThree("oddsidemargin", 18, 9, 0);
        setLength("headheight", 12 * 20);
        setThree("textheight", 621, 637, 621);
        setLength("footskip", 30 * 20);
        setLength("marginparpush", 5 * 20);

        setLength("pagewidth", 598 * 20);
        setLength("voffset", 0 * 20);
        setLength("topmargin", 0 * 20);
        setLength("headsep", 25 * 20);
        setThree("textwidth", 425, 443, 461);
        setLength("marginparsep", 10 * 20);
        setLength("columnsep", 10 * 20);

    } else if (strcmp(option, "letterpaper") == 0) {

        setLength("pageheight", 795 * 20);
        setLength("hoffset", 0 * 20);
        setThree("oddsidemargin", 62, 54, 39);
        setLength("headheight", 12 * 20);
        setThree("textheight", 550, 541, 549);
        setLength("footskip", 30 * 20);
        setLength("marginparpush", 5 * 20);

        setLength("pagewidth", 614 * 20);
        setLength("voffset", 0 * 20);
        setLength("topmargin", 18 * 20);
        setLength("headsep", 25 * 20);
        setThree("textwidth", 345, 360, 390);
        setLength("marginparsep", 10 * 20);
        setLength("columnsep", 10 * 20);

    } else if (strcmp(option, "legalpaper") == 0) {

        setLength("pageheight", 1012 * 20);
        setLength("hoffset", 0 * 20);
        setThree("oddsidemargin", 62, 54, 39);
        setLength("headheight", 12 * 20);
        setThree("textheight", 766, 759, 766);
        setLength("footskip", 30 * 20);
        setLength("marginparpush", 5 * 20);

        setLength("pagewidth", 614 * 20);
        setLength("voffset", 0 * 20);
        setLength("topmargin", 18 * 20);
        setLength("headsep", 25 * 20);
        setThree("textwidth", 345, 360, 390);
        setLength("marginparsep", 10 * 20);
        setLength("columnsep", 10 * 20);

    } else if (strcmp(option, "a5paper") == 0) {

        setLength("pageheight", 598 * 20);
        setLength("hoffset", 0 * 20);
        setLength("oddsidemargin", 0 * 20);
        setLength("headheight", 12 * 20);
        setLength("textheight", 350 * 20);
        setLength("footskip", 30 * 20);
        setLength("marginparpush", 5 * 20);

        setLength("pagewidth", 421 * 20);
        setLength("voffset", 0 * 20);
        setLength("topmargin", 18 * 20);
        setLength("headsep", 25 * 20);
        setLength("textwidth", 276 * 20);
        setLength("marginparsep", 10 * 20);
        setLength("columnsep", 10 * 20);

    } else if (strcmp(option, "b5paper") == 0) {

        setLength("pageheight", 711 * 20);
        setLength("hoffset", 0 * 20);
        setLength("oddsidemargin", 0 * 20);
        setLength("headheight", 12 * 20);
        setLength("textheight", 460 * 20);
        setLength("footskip", 30 * 20);
        setLength("marginparpush", 5 * 20);

        setLength("pagewidth", 501 * 20);
        setLength("voffset", 0 * 20);
        setLength("topmargin", 19 * 20);
        setLength("headsep", 25 * 20);
        setLength("textwidth", 350 * 20);
        setLength("marginparsep", 10 * 20);
        setLength("columnsep", 10 * 20);
    }
}

static void setPointSize(char *option)
{
    if (strcmp(option, "10pt") == 0) {
        InitializeDocumentFont(-1, 20, -1, -1);
        setLength("baselineskip", 12 * 20);
        setLength("parindent", 15 * 20);
        setLength("parskip", 0 * 20);

    } else if (strcmp(option, "11pt") == 0) {
        InitializeDocumentFont(-1, 22, -1, -1);
        setLength("baselineskip", 14 * 20);
        setLength("parindent", 17 * 20);
        setLength("parskip", 0 * 20);

    } else {
        InitializeDocumentFont(-1, 24, -1, -1);
        setLength("baselineskip", (int) 14.5 * 20);
        setLength("parindent", 18 * 20);
        setLength("parskip", 0 * 20);
    }
}


static void setDocumentOptions(char *optionlist)
{
    char *option;

    option = strtok(optionlist, ",");

    while (option) {

/*		while (*option == ' ') option++;  skip leading blanks */
        diagnostics(3, " (setDocumentOptions) option <%s>", option);
        if (strcmp(option, "10pt") == 0 || strcmp(option, "11pt") == 0 || strcmp(option, "12pt") == 0)
            setPointSize(option);
        else if (strcmp(option, "a4") == 0 ||
          strcmp(option, "a4paper") == 0 ||
          strcmp(option, "a4wide") == 0 ||
          strcmp(option, "b5paper") == 0 ||
          strcmp(option, "a5paper") == 0 ||
          strcmp(option, "letterpaper") == 0 || strcmp(option, "landscape") == 0 || strcmp(option, "legalpaper") == 0)
            setPaperSize(option);
        else if (strcmp(option, "german") == 0 ||
          strcmp(option, "ngerman") == 0 ||
          strcmp(option, "spanish") == 0 ||
          strcmp(option, "english") == 0 ||
          strcmp(option, "russian") == 0 ||
          strcmp(option, "czech") == 0 || strcmp(option, "frenchb") == 0 || strcmp(option, "french") == 0)
            setPackageBabel(option);
        else if (strcmp(option, "twoside") == 0)
            g_preambleTwoside = TRUE;
        else if (strcmp(option, "twocolumn") == 0)
            g_preambleTwocolumn = TRUE;
        else if (strcmp(option, "titlepage") == 0)
            g_preambleTitlepage = TRUE;
        else if (strcmp(option, "isolatin1") == 0)
            setPackageInputenc("latin1");
        else if (strcmp(option, "hyperlatex") == 0)
            PushEnvironment(HYPERLATEX);
        else if (strcmp(option, "apalike") == 0)
            g_document_bibstyle = BIBSTYLE_APALIKE;
        else if (strcmp(option, "apanat1b") == 0)
            PushEnvironment(APACITE_MODE);
        else if (strcmp(option, "harvard") == 0) {
            PushEnvironment(HARVARD_MODE);
            g_document_bibstyle = BIBSTYLE_HARVARD;
        } else if (strcmp(option, "natbib") == 0) {
            PushEnvironment(NATBIB_MODE);
            g_document_bibstyle = BIBSTYLE_NATBIB;
        } else if (strcmp(option, "authordate") == 0 ||
          strcmp(option, "authordate1") == 0 ||
          strcmp(option, "authordate2") == 0 ||
          strcmp(option, "authordate3") == 0 ||
          strcmp(option, "authordate4") == 0 || strcmp(option, "authordate1-4") == 0) {
            PushEnvironment(AUTHORDATE_MODE);
            g_document_bibstyle = BIBSTYLE_AUTHORDATE;
        } else if (strcmp(option, "apacite") == 0 || strcmp(option, "apacitex") == 0) {
            PushEnvironment(APACITE_MODE);
            g_document_bibstyle = BIBSTYLE_APACITE;
        } else if (strcmp(option, "fancyhdr") == 0) {
            diagnostics(WARNING, "Only partial support for %s", option);
        } else if (strcmp(option, "textcomp") == 0 || strcmp(option, "fontenc") == 0) {
            /* do nothing ... but don't complain */
        } else if (strcmp(option, "color") == 0) {
            diagnostics(WARNING, "Color support limited to eight basic colors");
        } else if (strcmp(option, "endnotes") == 0) {
            diagnostics(WARNING, "Limited endnote support");
        } else if (!TryVariableIgnore(option)) {
            diagnostics(WARNING, "Unknown style option %s ignored", option);
        }
        option = strtok(NULL, ",");
    }
}

/******************************************************************************
 purpose: parse \documentstyle[options]{format} or \documentclass[options]{format}
 ******************************************************************************/
void CmdDocumentStyle(int code)
{
    char *format, *format_with_spaces;
    char *options, *options_with_spaces;

    options_with_spaces = getBracketParam();
    format_with_spaces = getBraceParam();

    format = strdup_noblanks(format_with_spaces);
    free(format_with_spaces);

    if (options_with_spaces)
        diagnostics(4, "Documentstyle/class[%s]{%s}", options_with_spaces, format);
    else
        diagnostics(4, "Documentstyle/class{%s}", format);

    g_document_type = FORMAT_ARTICLE;
    if (strcmp(format, "book") == 0)
        g_document_type = FORMAT_BOOK;

    else if (strcmp(format, "report") == 0)
        g_document_type = FORMAT_REPORT;

    else if (strcmp(format, "letter") == 0)
        g_document_type = FORMAT_LETTER;

    else if (strcmp(format, "article") == 0)
        g_document_type = FORMAT_ARTICLE;

    else if (strcmp(format, "slides") == 0)
        g_document_type = FORMAT_SLIDES;

    else
        fprintf(stderr, "\nDocument format <%s> unknown, using article format", format);

    if (options_with_spaces) {
        options = strdup_noblanks(options_with_spaces);
        free(options_with_spaces);
        setDocumentOptions(options);
        free(options);
    }
    free(format);
}

/******************************************************************************
 purpose: handle \usepackage[option]{packagename}
******************************************************************************/
void CmdUsepackage(int code)
{
    char *package, *package_with_spaces;
    char *options, *options_with_spaces;

    options = NULL;
    options_with_spaces = getBracketParam();
    package_with_spaces = getBraceParam();
    package = strdup_noblanks(package_with_spaces);
    free(package_with_spaces);

    if (options_with_spaces) {
        options = strdup_noblanks(options_with_spaces);
        free(options_with_spaces);
        diagnostics(4, "Package {%s} with options [%s]", package, options);
    } else
        diagnostics(4, "Package {%s} with no options", package);

    if (strcmp(package, "inputenc") == 0 && options)
        setPackageInputenc(options);

    else if (strcmp(package, "isolatin1") == 0)
        setPackageInputenc("latin1");

    else if (strcmp(package, "babel") == 0) {
        if (options)
            setPackageBabel(options);

    } else if (strcmp(package, "german") == 0 ||
      strcmp(package, "ngerman") == 0 ||
      strcmp(package, "czech") == 0 || strcmp(package, "frenchb") == 0 || strcmp(package, "french") == 0)
        setPackageBabel(package);

    else if (strcmp(package, "palatino") == 0 ||
      strcmp(package, "times") == 0 ||
      strcmp(package, "bookman") == 0 ||
      strcmp(package, "chancery") == 0 ||
      strcmp(package, "courier") == 0 ||
      strstr(package, "avant") || strstr(package, "newcen") || strstr(package, "helvet"))
        setPackageFont(package);

    else if (strcmp(package, "natbib") == 0) {
        if (strstr(options, ""))
            set_longnamesfirst();
        PushEnvironment(NATBIB_MODE);
        g_document_bibstyle = BIBSTYLE_NATBIB;
    } else
        setDocumentOptions(package);

    if (options)
        free(options);
    free(package);
}

void CmdTitle(int code)

/******************************************************************************
  purpose: saves title, author or date information
 ******************************************************************************/
{
    switch (code) {
        case TITLE_TITLE:
            g_preambleTitle = getBraceParam();
            UpdateLineNumber(g_preambleTitle);
            break;

        case TITLE_AUTHOR:
            g_preambleAuthor = getBraceParam();
            UpdateLineNumber(g_preambleAuthor);
            break;

        case TITLE_DATE:
            g_preambleDate = getBraceParam();
            UpdateLineNumber(g_preambleDate);
            break;

        case TITLE_TITLEPAGE:
            g_preambleTitlepage = TRUE;
            break;
    }
}

void CmdMakeTitle(int code)

/******************************************************************************
  purpose: Creates a title page based on saved values for author, title, and date
 ******************************************************************************/
{
    char title_begin[10];
    char author_begin[10];
    char date_begin[10];

    PushTrackLineNumber(FALSE);
    snprintf(title_begin, 10, "%s%2d", "\\fs", (30 * CurrentFontSize()) / 20);
    snprintf(author_begin, 10, "%s%2d", "\\fs", (24 * CurrentFontSize()) / 20);
    snprintf(date_begin, 10, "%s%2d", "\\fs", (24 * CurrentFontSize()) / 20);

    alignment = CENTERED;
    fprintRTF("\n\\par\\pard\\qc {%s ", title_begin);
    if (g_preambleTitle != NULL && strcmp(g_preambleTitle, "") != 0)
        ConvertString(g_preambleTitle);
    fprintRTF("}");

    fprintRTF("\n\\par\\qc {%s ", author_begin);
    if (g_preambleAuthor != NULL && strcmp(g_preambleAuthor, "") != 0)
        ConvertString(g_preambleAuthor);
    fprintRTF("}");

    fprintRTF("\n\\par\\qc {%s ", date_begin);
    if (g_preambleDate != NULL && strcmp(g_preambleDate, "") != 0)
        ConvertString(g_preambleDate);
    fprintRTF("}");

    CmdEndParagraph(0);
    alignment = JUSTIFIED;

    if (g_preambleTitlepage)
        fprintRTF("\\page ");

    PopTrackLineNumber();
}

void CmdPreambleBeginEnd(int code)

/***************************************************************************
   purpose: catch missed \begin{document} command 
***************************************************************************/
{
    char *cParam = getBraceParam();

    if (strcmp(cParam, "document"))
        diagnostics(ERROR, "\\begin{%s} found before \\begin{document}.  Giving up.  Sorry", cParam);

    CallParamFunc(cParam, ON);
    free(cParam);
}

void PlainPagestyle(void)

/******************************************************************************
  LEG030598
  purpose: sets centered page numbering at bottom in rtf-output

  globals : pagenumbering set to TRUE if pagenumbering is to occur, default
 ******************************************************************************/
{
    int fn = DefaultFontFamily();

    pagenumbering = TRUE;

    if (g_preambleTwoside) {
        fprintRTF("\n{\\footerr");
        fprintRTF("\\pard\\plain\\f%d\\qc", fn);
        fprintRTF("{\\field{\\*\\fldinst PAGE}{\\fldrslt ?}}\\par}");
        fprintRTF("\n{\\footerl");
        fprintRTF("\\pard\\plain\\f%d\\qc", fn);
        fprintRTF("{\\field{\\*\\fldinst PAGE}{\\fldrslt ?}}\\par}");
    } else {
        fprintRTF("\n{\\footer");
        fprintRTF("\\pard\\plain\\f%d\\qc", fn);
        fprintRTF("{\\field{\\*\\fldinst PAGE}{\\fldrslt ?}}\\par}");
    }
}

void CmdPagestyle( /* @unused@ */ int code)

/******************************************************************************
 * LEG030598
 purpose: sets page numbering in rtf-output
 parameter:

 globals : headings  set to TRUE if the pagenumber is to go into the header
           pagenumbering set to TRUE if pagenumbering is to occur- default

Produces latex-like headers and footers.
Needs to be terminated for:
- headings chapter, section informations and page numbering
- myheadings page nunmbering, combined with markboth, markright.
 ******************************************************************************/
{
    static char *style = "";

    style = getBraceParam();
    if (strcmp(style, "empty") == 0) {
        if (pagenumbering) {
            fprintRTF("{\\footer}");
            pagenumbering = FALSE;
        }
    } else if (strcmp(style, "plain") == 0)
        PlainPagestyle();
    else if (strcmp(style, "headings") == 0) {
        headings = TRUE;
        /* insert code to put section information in header, pagenumbering in header */
    } else if (strcmp(style, "myheadings") == 0) {
        headings = TRUE;

        /*--- insert code to put empty section information in header, will be
		      provided by markboth, markright
		      pagenumbering in header */
    } else {
        diagnostics(WARNING, "Unknown \\pagestyle{%s} ignored", style);
    }
}

void CmdHeader(int code)

/******************************************************************************
 purpose: converts the \markboth and \markright Command in Header information
 parameter: code: BOTH_SIDES, RIGHT_SIDE

 globals : twoside,
 ******************************************************************************/
{
    if (code == BOTH_SIDES) {
        if (g_preambleTwoside) {
            RtfHeader(LEFT_SIDE, NULL);
            RtfHeader(RIGHT_SIDE, NULL);
        } else
            diagnostics(WARNING, "\\markboth used in onesided documentstyle");
    } else
        RtfHeader(BOTH_SIDES, NULL);
}

void CmdThePage(int code)

/******************************************************************************
 purpose: handles \thepage in headers and footers
 ******************************************************************************/
{
    diagnostics(4, "CmdThePage");

    fprintRTF("\\chpgn ");
}

void RtfHeader(int where, char *what)

/******************************************************************************
  purpose: generates the header command in the rtf-output
  parameter: where: RIGHT_SIDE, LEFT_SIDE -handed page, BOTH_SIDES
           what:  NULL - Convert from LaTeX input, else put "what" into rtf
                  output
 ******************************************************************************/
{
    int fn = TexFontNumber("Roman");

    switch (where) {
        case RIGHT_SIDE:
            fprintRTF("\n{\\headerr \\pard\\plain\\f%d ", fn);
            break;
        case LEFT_SIDE:
            fprintRTF("\n{\\headerl \\pard\\plain\\f%d ", fn);
            break;
        case BOTH_SIDES:
            fprintRTF("\n{\\header \\pard\\plain\\f%d ", fn);
            break;
        default:
            diagnostics(ERROR, "\n error -> called RtfHeader with illegal parameter\n ");
    }
    if (what == NULL) {
        diagnostics(4, "Entering Convert() from RtfHeader");
        Convert();
        diagnostics(4, "Exiting Convert() from RtfHeader");
        fprintRTF("}");
    } else
        fprintRTF("%s}", what);
}


void CmdHyphenation(int code)

/******************************************************************************
 purpose: discard all hyphenation hints since they really only make sense when
          used with TeX's hyphenation algorithms 
 ******************************************************************************/
{
    char *hyphenparameter = getBraceParam();

    free(hyphenparameter);
}

static void WriteFontHeader(void)

/****************************************************************************
 *   purpose: writes fontnumbers and styles for headers into Rtf-File
 
 \fcharset0:    ANSI coding (codepage 1252)
 \fcharset1:    MAC coding
 \fcharset2:    PC coding   (codepage 437)
 \fcharset3:    PCA coding  (codepage 850)
 \fcharset204:  Cyrillic    (codepage 1251)
 \fcharset238:  E. European (codepage 852, 1250)
 ****************************************************************************/
{
    int i;
    ConfigEntryT **config_handle;
    char *font_type, *font_name;
    int charset;

    fprintRTF("{\\fonttbl");

    config_handle = CfgStartIterate(FONT_A);
    i = 3;
    while ((config_handle = CfgNext(FONT_A, config_handle)) != NULL) {

        font_type = (char *) (*config_handle)->TexCommand;
        font_name = (char *) (*config_handle)->RtfCommand;
        charset = g_fcharset_number;

        if (strncmp(font_name, "Symbol", 6) == 0)
            charset = 2;

        if (strncmp(font_type, "Cyrillic", 8) == 0)
            charset = 204;

        if (strncmp(font_type, "Latin2", 6) == 0)
            charset = 238;

        fprintRTF("{\\f%d\\fnil\\fcharset%d %s;}\n", i, charset, font_name);

        i++;
    }

    fprintRTF("}\n");
}

static void WriteStyleHeader(void)

/****************************************************************************
       --
      |   {\stylesheet{\fs20 \sbasedon222\snext10{keycode \shift...}
  A---|   {\s1 \ar \fs20 \sbasedon0\snext1 FLUSHRIGHT}{\s2\fi...}
      |   \sbasedon0snext2 IND:}}
       --
          ...
       --
      |  \widowctrl\ftnbj\ftnrestart \sectd \linex0\endnhere
      |  \pard\plain \fs20 This is Normal style.
  B---|  \par \pard\plain \s1
      |  This is right justified. I call this style FLUSHRIGHT.
      |  \par \pard\plain \s2
      |  This is an indented paragraph. I call this style IND...
       --
         \par}
 ****************************************************************************/
{
    ConfigEntryT **style;
    const char *rtf;

    fprintRTF("{\\stylesheet\n{\\s0\\fs%d\\snext0 Normal;}\n", CurrentFontSize());

    style = CfgStartIterate(STYLE_A);
    while ((style = CfgNext(STYLE_A, style)) != NULL) {
        rtf = (*style)->RtfCommand;
        diagnostics(4, "style <%s>=<%s>", (*style)->TexCommand, rtf);
        fprintRTF("{");
        InsertBasicStyle(rtf, TRUE);
        fprintRTF(";}\n");
    }
    fprintRTF("}\n");
}

static void WritePageSize(void)

/****************************************************************************
  \paperw<N>      The paper width (the default is 12,240).
  \paperh<N>      The paper height (the default is 15,840).
  \margl<N>       The left margin (the default is 1,800).
  \margr<N>       The right margin (the default is 1,800).
  \margt<N>       The top margin (the default is 1,440).
  \margb<N>       The bottom margin (the default is 1,440).

  \facingp        Facing pages (activates odd/even headers and gutters).
  \gutter<N>      The gutter width (the default is 0).
  \margmirror     Switches margin definitions on left and right pages.
  \landscape      Landscape format.
  \pgnstart<N>    The beginning page number (the default is 1).
  \widowctrl      Widow control.
  \ftnbj          Footnotes at bottom of page (bj = bottom justified)
  \aftnnar        Endnotes numbered in arabic numerals

  \headery<N>     The header is <N> twips from the top of the page (the default is 720).
  \footery<N>     The footer is <N> twips from the bottom of the page (the default is 720).
****************************************************************************/
{
	int n;
	int family = DefaultFontFamily();

	fprintRTF("\\paperw%d", getLength("pagewidth"));
	fprintRTF("\\paperh%d", getLength("pageheight"));
	if (g_preambleTwoside)
		fprintRTF("\\facingp");
	if (g_preambleLandscape)
		fprintRTF("\\landscape");
	if (g_preambleTwocolumn)
		fprintRTF("\\cols2\\colsx709");	 /* two columns -- space between columns 709 */

	n = getLength("hoffset") + 72*20 + getLength("oddsidemargin");
	fprintRTF("\\margl%d", n);
	diagnostics(4, "Writepagesize left margin   =%d pt", n/20);
	n = getLength("pagewidth") - (n + getLength("textwidth"));
	fprintRTF("\\margr%d", n);
	diagnostics(4, "Writepagesize right margin  =%d pt", n/20);
	n = getLength("voffset") + 72*20 + getLength("topmargin") + getLength("headheight")+getLength("headsep");
	fprintRTF("\\margt%d", n);
	diagnostics(4, "Writepagesize top    margin =%d pt", n/20);
	n = getLength("pageheight") - (n + getLength("textheight") + getLength("footskip"));
	fprintRTF("\\margb%d", n);
	diagnostics(4, "Writepagesize bottom margin =%d pt", n/20);
	
	fprintRTF("\\pgnstart%d", getCounter("page"));
	fprintRTF("\\widowctrl\\qj\\ftnbj\\f%d\n", family);
}

static void WriteHeadFoot(void)

/****************************************************************************
  \headerl        The header is on left pages only.
  \headerr        The header is on right pages only.
  \headerf        The header is on the first page only.
  \footerl        The footer is on left pages only.
  \footerr        The footer is on right pages only.
  \footerf        The footer is on the first page only.
****************************************************************************/
{

/*	fprintRTF("\\ftnbj\\sectd\\linex0\\endnhere\\qj\n"); */

    int textwidth = getLength("textwidth");

    if (g_preambleLFOOT || g_preambleCFOOT || g_preambleRFOOT) {
        fprintRTF("{\\footer\\pard\\plain\\tqc\\tx%d\\tqr\\tx%d ", textwidth / 2, textwidth);

        if (g_preambleLFOOT)
            ConvertString(g_preambleLFOOT);

        fprintRTF("\\tab ");
        if (g_preambleCFOOT)
            ConvertString(g_preambleCFOOT);

        if (g_preambleRFOOT) {
            fprintRTF("\\tab ");
            ConvertString(g_preambleRFOOT);
        }

        fprintRTF("\\par}\n");
    }

    if (g_preambleLHEAD || g_preambleCHEAD || g_preambleRHEAD) {
        fprintRTF("{\\header\\pard\\plain\\tqc\\tx%d\\tqr\\tx%d ", textwidth / 2, textwidth);

        if (g_preambleLHEAD)
            ConvertString(g_preambleLHEAD);

        fprintRTF("\\tab ");
        if (g_preambleCHEAD)
            ConvertString(g_preambleCHEAD);

        if (g_preambleRHEAD) {
            fprintRTF("\\tab ");
            ConvertString(g_preambleRHEAD);
        }

        fprintRTF("\\par}\n");
    }
}

void CmdHeadFoot(int code)

/******************************************************************************
 purpose: performs \cfoot, \lfoot, \rfoot, \chead, \lhead, \rhead commands (fancyhdr)
 adapted from code by Taupin in ltx2rtf
 ******************************************************************************/
{
    char *HeaderText = NULL;
    char *AlternText = NULL;

    AlternText = getBracketParam();
    if (AlternText)
        free(AlternText);

    HeaderText = getBraceParam();

    diagnostics(4, "CmdHeadFoot code=%d <%s>", code, HeaderText);
    switch (code) {
        case CFOOT:
            g_preambleCFOOT = HeaderText;
            break;
        case LFOOT:
            g_preambleLFOOT = HeaderText;
            break;
        case RFOOT:
            g_preambleRFOOT = HeaderText;
            break;
        case CHEAD:
            g_preambleCHEAD = HeaderText;
            break;
        case LHEAD:
            g_preambleLHEAD = HeaderText;
            break;
        case RHEAD:
            g_preambleRHEAD = HeaderText;
            break;
    }

    if (!g_processing_preamble)
        WriteHeadFoot();
}

static void WriteColorTable(void)

/****************************************************************************
     <colortbl>          '{' \colortbl <colordef>+ '}'
     <colordef>          \red ? & \green ? & \blue ? ';'
 ***************************************************************************/
{
    fprintRTF("{\\colortbl;\n");
    fprintRTF("\\red0\\green0\\blue0;\n");  /* black */
    fprintRTF("\\red0\\green0\\blue255;\n");    /* blue */
    fprintRTF("\\red0\\green255\\blue255;\n");  /* cyan */
    fprintRTF("\\red0\\green255\\blue0;\n");    /* green */
    fprintRTF("\\red255\\green0\\blue255;\n");  /* magenta */
    fprintRTF("\\red255\\green0\\blue0;\n");    /* red */
    fprintRTF("\\red255\\green255\\blue0;\n");  /* yellow */
    fprintRTF("\\red255\\green255\\blue255;\n");    /* white */
    fprintRTF("\\red0\\green0\\blue128;\n");    /* dark blue */
    fprintRTF("\\red0\\green128\\blue128;\n");  /* dark cyan */
    fprintRTF("\\red0\\green128\\blue0;\n");    /* dark green */
    fprintRTF("\\red128\\green0\\blue128;\n");  /* dark magenta */
    fprintRTF("\\red128\\green0\\blue0;\n");    /* dark red */
    fprintRTF("\\red128\\green128\\blue0;\n");  /* dark yellow */
    fprintRTF("\\red128\\green128\\blue128;\n");    /* dark gray */
    fprintRTF("\\red192\\green192\\blue192;\n");    /* light gray */
    fprintRTF("}\n");
}

static void WriteInfo(void)

/****************************************************************************
  \title          The title of the document
  \subject        The subject of the document
  \author         The author of the document
  \operator       The person who last made changes to the document
  \keywords       Selected keywords for the document
  \comment        Comments; text is ignored
  \version<N>     The version number of the document
  \doccomm        Comments displayed in Word's Summary Info dialog
  
{\info {\title This is a page} {\author \'ca}}
 ***************************************************************************/
{
}

void WriteRtfHeader(void)

/****************************************************************************
purpose: writes header info for the RTF file

\rtf1 <charset> \deff? <fonttbl> <filetbl>? <colortbl>? <stylesheet>? <listtables>? <revtbl>?
 ****************************************************************************/
{
    int family = DefaultFontFamily();

/*	int size   = DefaultFontSize(); */

    diagnostics(4, "Writing header for RTF file");

/*	fprintRTF("{\\rtf1\\ansi\\fs%d\\deff%d\\deflang1024\n", size, family); */
    fprintRTF("{\\rtf1\\ansi\\deff%d\\deflang1024\n", family);
    WriteFontHeader();
    WriteColorTable();
    WriteStyleHeader();
    WriteInfo();
    WriteHeadFoot();
    WritePageSize();
}
