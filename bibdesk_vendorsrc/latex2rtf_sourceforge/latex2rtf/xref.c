
/*
 * xref.c - commands for LaTeX cross references
 * 
 * Copyright (C) 2001-2002 The Free Software Foundation
 * 
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free
 * Software Foundation; either version 2 of the License, or (at your option)
 * any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
 * more details.
 * 
 * You should have received a copy of the GNU General Public License along with
 * this program; if not, write to the Free Software Foundation, Inc., 59
 * Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 * 
 * This file is available from http://sourceforge.net/projects/latex2rtf/
 * 
 * Authors: 2001-2002 Scott Prahl
 */

#include <stdlib.h>
#include <string.h>
#include "main.h"
#include "util.h"
#include "convert.h"
#include "funct1.h"
#include "commands.h"
#include "cfg.h"
#include "xref.h"
#include "parser.h"
#include "preamble.h"
#include "lengths.h"
#include "l2r_fonts.h"
#include "style.h"
#include "definitions.h"

char *g_figure_label = NULL;
char *g_table_label = NULL;
char *g_equation_label = NULL;
char *g_section_label = NULL;
int g_suppress_name = FALSE;

#define MAX_LABELS 200
#define MAX_CITATIONS 1000

char *g_label_list[MAX_LABELS];
int g_label_list_number = -1;

static char *g_all_citations[MAX_CITATIONS];
static int g_last_citation = 0;
static int g_current_cite_type = 0;
static int g_current_cite_seen = 0;
static int g_current_cite_paren = 0;
static char g_last_author_cited[201];
static char g_last_year_cited[51];
static int g_citation_longnamesfirst = 0;
static int g_current_cite_item = 0;

static char *g_bibpunct_open = NULL;
static char *g_bibpunct_close = NULL;
static char *g_bibpunct_cite_sep = NULL;
static char *g_bibpunct_author_date_sep = NULL;
static char *g_bibpunct_numbers_sep = NULL;
static char *g_bibpunct_postnote_sep = NULL;
static bool g_bibpunct_touched = FALSE;

void InitializeBibliography(void)
{
	g_bibpunct_open = strdup("(");
	g_bibpunct_close = strdup(")");
	g_bibpunct_cite_sep = strdup(",");
	g_bibpunct_author_date_sep = strdup(",");
	g_bibpunct_numbers_sep = strdup(",");
    g_bibpunct_postnote_sep = strdup(", ");
    g_bibpunct_touched = FALSE;
}

void set_longnamesfirst(void)
{
    g_citation_longnamesfirst = TRUE;
}

/*************************************************************************
 * return 1 if citation used otherwise return 0 and add citation to list
 ************************************************************************/
static int citation_used(char *citation)
{
    int i;

    for (i = 0; i < g_last_citation; i++) {
        if (strcmp(citation, g_all_citations[i]) == 0)
            return 1;
    }

    if (g_last_citation > MAX_CITATIONS - 1) {
        diagnostics(WARNING, "Too many citations ... increase MAX_CITATIONS");
    } else {
        g_all_citations[g_last_citation] = strdup(citation);
        g_last_citation++;
    }

    return 0;
}

/*************************************************************************
purpose: obtains a reference from .aux file
    code==0 means \token{reference}{number}       -> "number"
    code==1 means \token{reference}{{sect}{line}} -> "sect"
    code==2 means \token{reference}{a}{b}{c}      -> "{a}{b}{c}"
 ************************************************************************/
static char *ScanAux(char *token, char *reference, int code)
{
    static FILE *fAux = NULL;
    char AuxLine[2048];
    char target[512];
    char *s, *t;
    int braces;

    if (g_aux_file_missing || strlen(token) == 0) {
        return NULL;
    }
    diagnostics(4, "seeking in .aux for <%s>", reference);

    snprintf(target, 512, "\\%s{%s}", token, reference);

    if (fAux == NULL && (fAux = my_fopen(g_aux_name, "r")) == NULL) {
        diagnostics(WARNING, "No .aux file.  Run LaTeX to create %s\n", g_aux_name);
        g_aux_file_missing = TRUE;
        return NULL;
    }
    rewind(fAux);

    while (fgets(AuxLine, 2047, fAux) != NULL) {

        s = strstr(AuxLine, target);
        if (s) {

            s += strlen(target);    /* move to \token{reference}{ */
            
            if (code == 2) {
				diagnostics(4, "found <%s>", s);
				return strdup_noendblanks(s);
			}
            	
            if (code == 1)
                s++;            /* move to \token{reference}{{ */

            t = s;
            braces = 1;
            while (braces >= 1) {   /* skip matched braces */
                t++;
                if (*t == '{')
                    braces++;
                if (*t == '}')
                    braces--;
                if (*t == '\0')
                    return NULL;
            }

            *t = '\0';
            diagnostics(4, "found <%s>", s + 1);
            return strdup(s + 1);
        }
    }
    return NULL;
}

/******************************************************************************
 purpose: creates RTF so that endnotes will be emitted at this point
 ******************************************************************************/
void CmdTheEndNotes(int code)
{
    diagnostics(4, "Entering CmdTheEndNotes");

    CmdVspace(VSPACE_BIG_SKIP);
    CmdStartParagraph(TITLE_PAR);
    fprintRTF("{\\sect ");
    InsertStyle("section");
    fprintRTF(" Notes");
    CmdEndParagraph(0);

    fprintRTF("\\endnhere}");
}

/******************************************************************************
 purpose: converts footnotes and endnotes from LaTeX to Rtf
 params : code specifies whether it is a footnote or a thanks-mark
 ******************************************************************************/
void CmdFootNote(int code)
{
    char *number, *text, *end_note_extra = "";
    static int thankno = 1;
    int text_ref_upsize, foot_ref_upsize;
    int DefFont = DefaultFontFamily();

    diagnostics(4, "Entering ConvertFootNote");
    number = getBracketParam(); /* ignored by automatic footnumber * generation */
    text = getBraceParam();

    if (number)
        free(number);
    text_ref_upsize = (int) (0.8 * CurrentFontSize());
    foot_ref_upsize = (int) (0.8 * CurrentFontSize());

    if (code & FOOTNOTE_ENDNOTE) {
        code &= ~FOOTNOTE_ENDNOTE;
        end_note_extra = "\\ftnalt";
    }
    switch (code) {
        case FOOTNOTE_THANKS:
            thankno++;
            fprintRTF("{\\up%d %d}\n", text_ref_upsize, thankno);
            fprintRTF("{\\*\\footnote%s \\pard\\plain\\s246\\f%d", end_note_extra, DefFont);
            fprintRTF("\\fs%d {\\up%d %d}", CurrentFontSize(), foot_ref_upsize, thankno);
            break;

        case FOOTNOTE:
            fprintRTF("{\\up%d\\chftn}\n", text_ref_upsize);
            fprintRTF("{\\*\\footnote%s \\pard\\plain\\s246\\f%d", end_note_extra, DefFont);
            fprintRTF("\\fs%d {\\up%d\\chftn}", CurrentFontSize(), foot_ref_upsize);
            break;

        case FOOTNOTE_TEXT:
            fprintRTF("{\\*\\footnote%s \\pard\\plain\\s246\\f%d", end_note_extra, DefFont);
            fprintRTF("\\fs%d ", CurrentFontSize());
            break;
    }

    ConvertString(text);
    fprintRTF("}\n ");
    diagnostics(4, "Exiting CmdFootNote");
    free(text);
}

/******************************************************************************
 purpose: handle the \nocite{tag}
 ******************************************************************************/
void CmdNoCite(int code)
{
    free(getBraceParam());      /* just skip the parameter */
}

/******************************************************************************
 purpose: handle the \bibliographystyle
 ******************************************************************************/
void CmdBibliographyStyle(int code)
{
    char *s = getBraceParam();  /* throw away widest_label */

    free(s);
}

/******************************************************************************
 purpose: handle the \bibliography
 ******************************************************************************/
void CmdBibliography(int code)
{
    int err;
    char *s;

    s = getBraceParam();        /* throw away bibliography name */
    free(s);

    err = PushSource(g_bbl_name, NULL);

    if (!err) {
        diagnostics(4, "CmdBibliography ... begin Convert()");
        Convert();
        diagnostics(4, "CmdBibliography ... done Convert()");
        PopSource();
    } else
        diagnostics(WARNING, "Cannot open bibliography file.  Create %s using BibTeX", g_bbl_name);
}

/******************************************************************************
 purpose: handle the \thebibliography
 ******************************************************************************/
void CmdThebibliography(int code)
{
    int amount = 450;
    int i;

    if (code & ON) {
        char *s = getBraceParam();  /* throw away widest_label */

        free(s);

        CmdEndParagraph(0);
        CmdVspace(VSPACE_MEDIUM_SKIP);
        CmdStartParagraph(TITLE_PAR);

        fprintRTF("{\\plain\\b\\fs32 ");
        i = existsDefinition("refname");    /* see if refname has * been redefined */
        if (i > -1) {
            char *str = expandDefinition(i);

            ConvertString(str);
            free(str);
        } else {
            if (g_document_type == FORMAT_ARTICLE)
                ConvertBabelName("REFNAME");
            else
                ConvertBabelName("BIBNAME");
        }
        fprintRTF("}");
        CmdEndParagraph(0);
        CmdVspace(VSPACE_SMALL_SKIP);

        PushEnvironment(GENERIC_ENV);
        setLength("parindent", -amount);
        g_left_margin_indent += 2 * amount;
    } else {
        CmdEndParagraph(0);
        CmdVspace(VSPACE_SMALL_SKIP);
        PopEnvironment();
        g_processing_list_environment = FALSE;
    }
}

/******************************************************************************
 purpose: handle the \bibitem
 ******************************************************************************/
void CmdBibitem(int code)
{
    char *label, *key, *signet, *s, c;

    g_processing_list_environment = TRUE;
    CmdEndParagraph(0);
    CmdStartParagraph(FIRST_PAR);

    label = getBracketParam();
    key = getBraceParam();
    signet = strdup_nobadchars(key);
    s = ScanAux("bibcite", key, 0);

    if (label && !s) {          /* happens when file needs to be latex'ed again */
        diagnostics(WARNING, "file needs to be latexed again for references");
        fprintRTF("[");
        ConvertString(label);
        fprintRTF("]");
    } else {
        diagnostics(4, "CmdBibitem <%s>", s);
        if (g_document_bibstyle == BIBSTYLE_STANDARD) {
            fprintRTF("[");
            fprintRTF("{\\v\\*\\bkmkstart BIB_%s}", signet);
            ConvertString(s);
            fprintRTF("{\\*\\bkmkend BIB_%s}", signet);
            fprintRTF("]");
            fprintRTF("\\tab ");
        }
        /* else emit nothing for APALIKE */
    }

    if (s)
        free(s);
    if (label)
        free(label);
    free(signet);
    free(key);

    c = getNonBlank();
    ungetTexChar(c);
}

void CmdNewblock(int code)
{
    /* 
     * if openbib chosen then start a paragraph with 1.5em indent
     * otherwise do nothing
     */
}

/******************************************************************************
purpose: convert \index{classe!article@\textit{article}!section}
              to {\xe\v "classe:{\i article}:section"}
******************************************************************************/
void CmdIndex(int code)
{
    char cThis, *text, *r, *s, *t;

    cThis = getNonBlank();
    text = getDelimitedText('{', '}', TRUE);
    diagnostics(4, "CmdIndex \\index{%s}", text);
    fprintRTF("{\\xe{\\v ");

    t = text;
    while (t) {
        s = t;
        t = strchr(s, '!');
        if (t)
            *t = '\0';
        r = strchr(s, '@');
        if (r)
            s = r + 1;
        ConvertString(s);
        /* while (*s && *s != '@') putRtfChar(*s++); */
        if (t) {
            fprintRTF("\\:");
            t++;
        }
    }

    fprintRTF("}}");
    diagnostics(4, "leaving CmdIndex");
    free(text);
}

void CmdPrintIndex(int code)
{
    CmdEndParagraph(0);
    fprintRTF("\\page ");
    fprintRTF("{\\field{\\*\\fldinst{INDEX \\\\c 2}}{\\fldrslt{}}}");
}

static int ExistsBookmark(char *s)
{
    int i;

    if (!s)
        return FALSE;
    for (i = 0; i <= g_label_list_number; i++) {
        if (strcmp(s, g_label_list[i]) == 0)
            return TRUE;
    }
    return FALSE;
}

static void RecordBookmark(char *s)
{
    if (!s)
        return;
    if (g_label_list_number >= MAX_LABELS)
        diagnostics(WARNING, "Too many labels...some cross-references will fail");
    else {
        g_label_list_number++;
        g_label_list[g_label_list_number] = strdup(s);
    }
}

void InsertBookmark(char *name, char *text)
{
    char *signet;

    if (!name) {
        fprintRTF("%s", text);
        return;
    }
    signet = strdup_nobadchars(name);

    if (ExistsBookmark(signet)) {
        diagnostics(3, "bookmark %s already exists", signet);

    } else {
        diagnostics(3, "bookmark %s being inserted around <%s>", signet, text);
        RecordBookmark(signet);
        if (g_fields_use_REF)
            fprintRTF("{\\*\\bkmkstart BM%s}", signet);
        fprintRTF("%s", text);
        if (g_fields_use_REF)
            fprintRTF("{\\*\\bkmkend BM%s}", signet);
    }

    free(signet);
}

/******************************************************************************
purpose: handles \label \ref \pageref \cite
******************************************************************************/
void CmdLabel(int code)
{
    char *text, *signet, *s;
    char *option = NULL;
    int mode = GetTexMode();

    option = getBracketParam();
    text = getBraceParam();
    if (strlen(text) == 0) {
        free(text);
        return;
    }
    switch (code) {
        case LABEL_LABEL:
            if (g_processing_figure || g_processing_table)
                break;
            if (mode == MODE_DISPLAYMATH) {
                g_equation_label = strdup_nobadchars(text);
                diagnostics(3, "equation label is <%s>", text);
            } else
                InsertBookmark(text, "");
            break;

        case LABEL_HYPERREF:
        case LABEL_REF:
        case LABEL_EQREF:
            signet = strdup_nobadchars(text);
            s = ScanAux("newlabel", text, 1);
            if (code == LABEL_EQREF)
                fprintRTF("(");
            if (g_fields_use_REF) {
                fprintRTF("{\\field{\\*\\fldinst{\\lang1024 REF BM%s \\\\* MERGEFORMAT }}", signet);
                fprintRTF("{\\fldrslt{");
            }
            if (s)
                ConvertString(s);
            else
                fprintRTF("?");
            if (g_fields_use_REF)
                fprintRTF("}}}");
            if (code == LABEL_EQREF)
                fprintRTF(")");

            free(signet);
            if (s)
                free(s);
            break;

        case LABEL_HYPERPAGEREF:
        case LABEL_PAGEREF:
            signet = strdup_nobadchars(text);
            if (g_fields_use_REF) {
                fprintRTF("{\\field{\\*\\fldinst{\\lang1024 PAGEREF BM%s \\\\* MERGEFORMAT }}", signet);
                fprintRTF("{\\fldrslt{");
            }
            fprintRTF("%s", signet);
            if (g_fields_use_REF)
                fprintRTF("}}}");
            free(signet);
            break;
    }

    free(text);
    if (option)
        free(option);
}

/*
 * given s="name1,name2,name3" returns "name2,name3" and makes s="name1" no
 * memory is allocated, commas are replaced by '\0'
 */
static char *popCommaName(char *s)
{
    char *t;

    if (s == NULL || *s == '\0')
        return NULL;

    t = strchr(s, ',');
    if (!t)
        return NULL;

    *t = '\0';                  /* replace ',' with '\0' */
    return t + 1;               /* next string starts after ',' */
}

/******************************************************************************
  purpose: return bracketed parameter

  \item<1>  --->  "1"        \item<>   --->  ""        \item the  --->  NULL
       ^                           ^                         ^
  \item <1>  --->  "1"        \item <>  --->  ""        \item  the --->  NULL
       ^                           ^                         ^
 ******************************************************************************/
static char *getAngleParam(void)
{
    char c, *text;

    c = getNonBlank();

    if (c == '<') {
        text = getDelimitedText('<', '>', TRUE);
        diagnostics(5, "getAngleParam [%s]", text);

    } else {
        ungetTexChar(c);
        text = NULL;
        diagnostics(5, "getAngleParam []");
    }

    return text;
}

static int isEmptyName(char *s)
{
    if (s == NULL)
        return 1;
    if (s[0] == '\0')
        return 1;
    if (s[0] == '{' && s[1] == '}')
        return 1;
    return 0;
}

static void ConvertNatbib(char *s, int code, char *pre, char *post, int first)
{
    char *n, *year, *abbv, *full, *v;
    int author_repeated, year_repeated;

    PushSource(NULL, s);
    n = getBraceParam();
    year = getBraceParam();
    abbv = getBraceParam();
    full = getBraceParam();
    PopSource();
    diagnostics(5, "natbib pre=[%s] post=<%s> n=<%s> year=<%s> abbv=<%s> full=<%s>", pre, post, n, year, abbv, full);
    author_repeated = FALSE;
    year_repeated = FALSE;
    switch (code) {
        case CITE_CITE:
        case CITE_T:
        case CITE_T_STAR:
            v = abbv;
            if (CITE_T == code && g_citation_longnamesfirst && !g_current_cite_seen)
                if (!isEmptyName(full))
                    v = full;
            if (CITE_T_STAR == code)
                if (!isEmptyName(full))
                    v = full;
            if (CITE_CITE == code && g_citation_longnamesfirst)
                if (!isEmptyName(full))
                    v = full;

            if (strcmp(v, g_last_author_cited) == 0)
                author_repeated = TRUE;

            if (!first && !author_repeated) {
            	ConvertString(g_bibpunct_cite_sep);
                fprintRTF(" ");
            }

            if (!author_repeated) { /* suppress repeated names */
                ConvertString(v);
                strcpy(g_last_author_cited, v);
                strcpy(g_last_year_cited, year);
            }
            fprintRTF(" ");
            ConvertString(g_bibpunct_open);
            
            ConvertString(year);
            if (pre) {
             	ConvertString(g_bibpunct_postnote_sep);
                ConvertString(pre);
            }
            if (post) {
             	ConvertString(g_bibpunct_postnote_sep);
                ConvertString(post);
            }
            ConvertString(g_bibpunct_close);
            break;

        case CITE_P:
        case CITE_P_STAR:
            v = abbv;
            if (CITE_P == code && g_citation_longnamesfirst && !g_current_cite_seen)
                if (!isEmptyName(full))
                    v = full;
            if (CITE_P_STAR == code)
                if (!isEmptyName(full))
                    v = full;

            if (strcmp(v, g_last_author_cited) == 0)
                author_repeated = TRUE;

            if (strncmp(year, g_last_year_cited, 4) == 0)   /* over simplistic test * ... */
                year_repeated = TRUE;

            if (pre && post!=NULL && g_current_cite_item == 1) {
                if (*pre) {
                	ConvertString(pre);
                 	fprintRTF(" ");
                 }
            }
            if (!first && !author_repeated) {
            	ConvertString(g_bibpunct_cite_sep);
                fprintRTF(" ");
            }

            if (!author_repeated) { /* suppress repeated names */
                ConvertString(v);
                strcpy(g_last_author_cited, v);
                strcpy(g_last_year_cited, year);
             	ConvertString(g_bibpunct_author_date_sep);
                fprintRTF(" ");
                ConvertString(year);
            } else {
                if (!year_repeated) {
             		ConvertString(g_bibpunct_numbers_sep);
                    fprintRTF(" ");
                    ConvertString(year);
                } else {
                    char *s = strdup(year + 4);

                    fprintRTF(",");
                    ConvertString(s);
                    free(s);
                }
            }

            if (pre && post==NULL) {
             	ConvertString(g_bibpunct_postnote_sep);
                ConvertString(pre);
                fprintRTF(" ");
            }
            if (post && *post != '\0') {
             	ConvertString(g_bibpunct_postnote_sep);
                ConvertString(post);
                fprintRTF(" ");
            }
            break;

        case CITE_AUTHOR:
        case CITE_AUTHOR_STAR:
            v = abbv;
            if (!first) {
            	ConvertString(g_bibpunct_cite_sep);
                fprintRTF(" ");
            }
            if (CITE_AUTHOR == code && g_citation_longnamesfirst && !g_current_cite_seen)
                v = full;

            if (CITE_AUTHOR_STAR == code)
                if (!isEmptyName(full))
                    v = full;
            ConvertString(v);
            break;

        case CITE_YEAR:
        case CITE_YEAR_P:
            if (!first) {
            	ConvertString(g_bibpunct_cite_sep);
                fprintRTF(" ");
            }

            if (CITE_YEAR != code && pre && !isEmptyName(post)
              && g_current_cite_item == 1) {
                ConvertString(pre);
                fprintRTF(" ");
            }
            ConvertString(year);

            if (pre && isEmptyName(post)) {
             	ConvertString(g_bibpunct_postnote_sep);
                ConvertString(pre);
                fprintRTF(" ");
            }
            if (post && *post != '\0') {
             	ConvertString(g_bibpunct_postnote_sep);
                ConvertString(post);
                fprintRTF(" ");
            }
            break;
    }
    free(n);
    free(year);
    free(abbv);
    free(full);
}

static void ConvertHarvard(char *s, int code, char *pre, char *post, int first)
{
    char *year, *abbv, *full;
    int author_repeated, year_repeated;

    PushSource(NULL, s);
    full = getBraceParam();
    abbv = getBraceParam();
    year = getBraceParam();
    PopSource();
    diagnostics(2, "harvard pre=[%s] post=<%s> full=<%s> abbv=<%s> year=<%s>", pre, post, full, abbv, year);
    author_repeated = FALSE;
    year_repeated = FALSE;
    switch (code) {
        case CITE_AFFIXED:
        	if (first && pre) {
        		ConvertString(pre);
        		fprintRTF(" ");
        	}
            ConvertString(full);
            fprintRTF(" ");
            ConvertString(year);
            break;

        case CITE_CITE:
            ConvertString(full);
            fprintRTF(" ");
            ConvertString(year);
            break;

        case CITE_YEAR:
        case CITE_YEAR_STAR:
             ConvertString(year);
             break;
             
        case CITE_NAME:
             ConvertString(full);
             break;

        case CITE_AS_NOUN:
             ConvertString(full);
             fprintRTF(" (");
             ConvertString(year);
             fprintRTF(")");
             break;
             
        case CITE_POSSESSIVE:
             ConvertString(full);
             fprintRTF("\\rquote s (");
             ConvertString(year);
             fprintRTF(")");
             break;
    }
    free(year);
    free(abbv);
    free(full);
}

/******************************************************************************
 Use \bibpunct (in the preamble only) with 6 mandatory arguments:
    1. opening bracket for citation
    2. closing bracket
    3. citation separator (for multiple citations in one \cite)
    4. the letter n for numerical styles, s for superscripts
        else anything for author-year
    5. punctuation between authors and date
    6. punctuation between years (or numbers) when common authors missing

One optional argument is the character coming before post-notes. It 
appears in square braces before all other arguments. May be left off.
Example (and default) 
           \bibpunct[, ]{(}{)}{;}{a}{,}{,}
******************************************************************************/

void CmdBibpunct(int code) 
{
	char *s = NULL;
	
	s = getBracketParam();
	if (s) {
		if (g_bibpunct_postnote_sep)
			free(g_bibpunct_postnote_sep);
		g_bibpunct_postnote_sep=getBraceParam();
	}
	
	free(g_bibpunct_open);
	g_bibpunct_open=getBraceParam();

	free(g_bibpunct_close);
	g_bibpunct_close=getBraceParam();

	free(g_bibpunct_cite_sep);
	g_bibpunct_cite_sep=getBraceParam();

    /* not implemented */
	s=getBraceParam();
	free(s);

	free(g_bibpunct_author_date_sep);
	g_bibpunct_author_date_sep=getBraceParam();

	free(g_bibpunct_numbers_sep);
	g_bibpunct_numbers_sep=getBraceParam();

	g_bibpunct_touched = TRUE;
}

/******************************************************************************
purpose: handles \cite
******************************************************************************/
void CmdCite(int code)
{
    char *text, *str1;
    char *keys, *key, *next_keys;
    char *option = NULL;
    char *pretext = NULL;
    int first_key = TRUE;

    /* Setup punctuation and read options before citation */
    g_current_cite_paren = TRUE;
    g_last_author_cited[0] = '\0';
    g_last_year_cited[0] = '\0';

    if (g_document_bibstyle == BIBSTYLE_STANDARD) {
		free(g_bibpunct_open);
		free(g_bibpunct_close);
		g_bibpunct_open = strdup("[");
	    g_bibpunct_close = strdup("]");
        option = getBracketParam();
    }
    if (g_document_bibstyle == BIBSTYLE_APALIKE) {
        option = getBracketParam();
    }
    if (g_document_bibstyle == BIBSTYLE_AUTHORDATE) {
        option = getBracketParam();
    }

    if (g_document_bibstyle == BIBSTYLE_APACITE) {
        pretext = getAngleParam();
        option = getBracketParam();
        if (code != CITE_CITE && code != CITE_FULL && code != CITE_SHORT && code != CITE_YEAR)
            g_current_cite_paren = FALSE;
        g_current_cite_type = code;
    }
    
    text = getBraceParam();
    str1 = strdup_nocomments(text);
    free(text);
    text = str1;
        
    if (strlen(text) == 0) {
        free(text);
        if (pretext)
            free(pretext);
        if (option)
            free(option);
        return;
    }
    /* output text before citation */
    if (g_current_cite_paren) {
        fprintRTF("\n"); 
        ConvertString(g_bibpunct_open);
    }

    if (pretext && g_document_bibstyle == BIBSTYLE_APACITE) {
        ConvertString(pretext);
        fprintRTF(" ");
    }
    /* now start processing keys */
    keys = strdup_noblanks(text);
    free(text);
    key = keys;
    next_keys = popCommaName(key);

    g_current_cite_item = 0;
    while (key) {
        char *s, *t;

        g_current_cite_item++;

		s = ScanAux("bibcite", key, 0); /* look up bibliographic * reference */
            
        if (g_document_bibstyle == BIBSTYLE_APALIKE) {  /* can't use Word refs for APALIKE or APACITE */
            t = s ? s : key;
            if (!first_key) {
            	ConvertString(g_bibpunct_cite_sep);
                fprintRTF(" ");
            }
            ConvertString(t);
        }
        if (g_document_bibstyle == BIBSTYLE_AUTHORDATE) {
            if (!first_key) {
            	ConvertString(g_bibpunct_cite_sep);
                fprintRTF(" ");
            }
            t = s ? s : key;
            if (code == CITE_SHORT)
                g_suppress_name = TRUE;
            ConvertString(t);
            if (code == CITE_SHORT)
                g_suppress_name = FALSE;
        }
        if (g_document_bibstyle == BIBSTYLE_APACITE) {
            if (!first_key) {
            	ConvertString(g_bibpunct_cite_sep);
                fprintRTF(" ");
            }
            t = s ? s : key;
            g_current_cite_seen = citation_used(key);
            ConvertString(t);
        }
        
        if (g_document_bibstyle == BIBSTYLE_STANDARD) {
            char *signet = strdup_nobadchars(key);

            if (!first_key) {
            	ConvertString(g_bibpunct_cite_sep);
                fprintRTF(" ");
            }
            t = s ? s : signet; /* if .aux is missing or * incomplete use original * citation */
            if (g_fields_use_REF) {
                fprintRTF("{\\field{\\*\\fldinst{\\lang1024 REF BIB_%s \\\\* MERGEFORMAT }}", signet);
                fprintRTF("{\\fldrslt{");
            }
            ConvertString(t);
            if (g_fields_use_REF)
                fprintRTF("}}}");
            if (signet)
                free(signet);
        }
        
        first_key = FALSE;
        key = next_keys;
        next_keys = popCommaName(key);  /* key modified to be a * single key */
        if (s)
            free(s);
    }

    /* final text after citation */
    if (option && (g_document_bibstyle == BIBSTYLE_APACITE || 
                   g_document_bibstyle == BIBSTYLE_AUTHORDATE)) {
        fprintRTF("%s", g_bibpunct_postnote_sep);
        ConvertString(option);
    }

    if (g_current_cite_paren) {
        fprintRTF("\n"); 
        ConvertString(g_bibpunct_close);
    }

    if (keys)
        free(keys);
    if (option)
        free(option);
    if (pretext)
        free(pretext);
}

/******************************************************************************
purpose: handles \citations for natbib package
******************************************************************************/
void CmdNatbibCite(int code)
{
    char *text, *str1;
    char *keys, *key, *next_keys;
    char *option = NULL;
    char *pretext = NULL;
    int first_key = TRUE;

    /* Setup punctuation and read options before citation */
    g_current_cite_paren = TRUE;
    g_last_author_cited[0] = '\0';
    g_last_year_cited[0] = '\0';

	if (!g_bibpunct_touched) {
		free(g_bibpunct_cite_sep);
		g_bibpunct_cite_sep = strdup(";");
	}
	
	pretext = getBracketParam();
	option = getBracketParam();
	if (code != CITE_P && code != CITE_P_STAR && code != CITE_ALP && code != CITE_ALP_STAR && code != CITE_YEAR_P)
		g_current_cite_paren = FALSE;
    
    text = getBraceParam();
    str1 = strdup_nocomments(text);
    free(text);
    text = str1;
        
    if (strlen(text) == 0) {
        free(text);
        if (pretext)
            free(pretext);
        if (option)
            free(option);
        return;
    }
    
    /* output text before citation */
    if (g_current_cite_paren) {
        fprintRTF("\n"); 
        ConvertString(g_bibpunct_open);
    }

    /* now start processing keys */
    keys = strdup_noblanks(text);
    free(text);
    key = keys;
    next_keys = popCommaName(key);

    g_current_cite_item = 0;
    while (key) {
        char *s;

        g_current_cite_item++;

		s = ScanAux("bibcite", key, 0); /* look up bibliographic reference */
            
		diagnostics(2, "natbib key=[%s] <%s> ", key, s);
		if (s) {
			g_current_cite_seen = citation_used(key);
			ConvertNatbib(s, code, pretext, option, first_key);
		} else {
            if (!first_key) {
            	ConvertString(g_bibpunct_cite_sep);
                fprintRTF(" ");
            }
			ConvertString(key);
		}
        
        first_key = FALSE;
        key = next_keys;
        next_keys = popCommaName(key);  /* key modified to be a single key */
        if (s)
            free(s);
    }

    if (g_current_cite_paren) {
        fprintRTF("\n"); 
        ConvertString(g_bibpunct_close);
    }

    if (keys)
        free(keys);
    if (option)
        free(option);
    if (pretext)
        free(pretext);
}

/******************************************************************************
purpose: handles \citations for harvard.sty
******************************************************************************/
void CmdHarvardCite(int code)
{
    char *text, *s;
    char *keys, *key, *next_keys;
    char *posttext = NULL;
    char *pretext = NULL;
    int first_key = TRUE;

    /* Setup punctuation and read options before citation */
    g_current_cite_paren = TRUE;
    g_last_author_cited[0] = '\0';
    g_last_year_cited[0] = '\0';
	if (code == CITE_AS_NOUN || code == CITE_YEAR_STAR || 
		code == CITE_NAME || code == CITE_POSSESSIVE)
		g_current_cite_paren = FALSE;

	/* read citation entry */
	posttext = getBracketParam();    
    text = getBraceParam();
    if (code == CITE_AFFIXED) 
    	pretext = getBraceParam();
    s = strdup_nocomments(text);
    free(text);
    text = s;
        
    if (strlen(text) == 0) {
        free(text);
        if (pretext) free(pretext);
        if (posttext)free(posttext);
        return;
    }
    
    /* output text before citation */
    if (g_current_cite_paren) {
        fprintRTF("\n"); 
        ConvertString(g_bibpunct_open);
    }

    /* now start processing keys */
    keys = strdup_noblanks(text);
    free(text);
    key = keys;
    next_keys = popCommaName(key);

    g_current_cite_item = 0;
    while (key) {
        char *s;

        g_current_cite_item++;

        s = ScanAux("harvardcite", key, 2); /* look up bibliographic reference */
            
		diagnostics(2, "harvard key=[%s] <%s>", key, s);
		
		if (!first_key) {
			ConvertString(g_bibpunct_cite_sep);
			fprintRTF(" ");
		}

		if (s) {
			g_current_cite_seen = citation_used(key);
			ConvertHarvard(s, code, pretext, NULL, first_key);
		} else 
			ConvertString(key);
        
        first_key = FALSE;
        key = next_keys;
        next_keys = popCommaName(key);  /* key modified to be a single key */
        if (s)
            free(s);
    }

    /* final text after citation */
    if (posttext) {
        fprintRTF("%s", g_bibpunct_postnote_sep);
        ConvertString(posttext);
    }
    
    if (g_current_cite_paren) {
        fprintRTF("\n"); 
        ConvertString(g_bibpunct_close);
    }

    if (keys)
        free(keys);
    if (posttext)
        free(posttext);
    if (pretext)
        free(pretext);
}

/******************************************************************************
purpose: handles \htmladdnormallink{text}{link}
******************************************************************************/
void CmdHtml(int code)
{
    char *text, *ref, *s;

    if (code == LABEL_HTMLADDNORMALREF) {
        text = getBraceParam();
        ref = getBraceParam();

        while ((s = strstr(text, "\\~{}")) != NULL) {
            *s = '~';
            strcpy(s + 1, s + 4);
        }
        while ((s = strstr(ref, "\\~{}")) != NULL) {
            *s = '~';
            strcpy(s + 1, s + 4);
        }

        fprintRTF("{\\field{\\*\\fldinst{ HYPERLINK \"%s\" }{{}}}", ref);
        fprintRTF("{\\fldrslt{\\ul %s}}}", text);
        free(text);
        free(ref);
    } else if (code == LABEL_HTMLREF) {
        text = getBraceParam();
        ref = getBraceParam();
        ConvertString(text);
        free(text);
        free(ref);
    }
}

void CmdBCAY(int code)
{
    char *s, *t, *v, *year;

    s = getBraceParam();

    diagnostics(4, "Entering CmdBCAY", s);

    t = getBraceParam();
    year = getBraceParam();
    v = g_current_cite_seen ? t : s;

    diagnostics(4, "s    = <%s>", s);
    diagnostics(4, "t    = <%s>", t);
    diagnostics(4, "year = <%s>", year);
    diagnostics(4, "type = %d, seen = %d, item= %d", g_current_cite_type, g_current_cite_seen, g_current_cite_item);

    switch (g_current_cite_type) {

        case CITE_CITE:
        case CITE_CITE_NP:
        case CITE_CITE_A:
            if (strcmp(v, g_last_author_cited) != 0) {  /* suppress repeated names */
                ConvertString(v);
                strcpy(g_last_author_cited, v);
                strcpy(g_last_year_cited, year);

                if (g_current_cite_type == CITE_CITE_A)
                    fprintRTF(" (");
                else
                    fprintRTF(", ");
            }
            ConvertString(year);
            if (g_current_cite_type == CITE_CITE_A)
                fprintRTF(")");
            break;

        case CITE_CITE_AUTHOR:
            ConvertString(v);
            break;

        case CITE_FULL:
        case CITE_FULL_NP:
        case CITE_FULL_A:
            ConvertString(s);
            if (g_current_cite_type == CITE_FULL_A)
                fprintRTF(" (");
            else
                fprintRTF(", ");

            ConvertString(year);
            if (g_current_cite_type == CITE_FULL_A)
                fprintRTF(")");
            break;

        case CITE_FULL_AUTHOR:
            ConvertString(s);
            break;

        case CITE_SHORT:
        case CITE_SHORT_NP:
        case CITE_SHORT_A:
        case CITE_SHORT_AUTHOR:
            ConvertString(t);
            break;

        case CITE_YEAR:
        case CITE_YEAR_NP:
            ConvertString(year);
            break;

    }
    free(s);
    free(t);
    free(year);
}

/******************************************************************************
purpose: handles apacite stuff
******************************************************************************/
void CmdApaCite(int code)
{
    int n;
    char *s;

    switch (code) {
        case 0:
            fprintRTF("(");
            break;              /* BBOP */
        case 1:
            fprintRTF("&");
            break;              /* BBAA */
        case 2:
            fprintRTF("and");
            break;              /* BBAB */
        case 3:
            fprintRTF(", ");
            break;              /* BBAY */
        case 4:
            fprintRTF("; ");
            break;              /* BBC */
        case 5:
            fprintRTF(", ");
            break;              /* BBN */
        case 6:
            fprintRTF(")");
            break;              /* BBCP */
        case 7:
            fprintRTF("");
            break;              /* BBOQ */
        case 8:
            fprintRTF("");
            break;              /* BBCQ */
        case 9:
            fprintRTF(",");
            break;              /* BCBT */
        case 10:
            fprintRTF(",");
            break;              /* BCBL */
        case 11:
            fprintRTF("et al.");
            break;              /* BOthers */
        case 12:
            fprintRTF("in press");
            break;              /* BIP */
        case 13:
            fprintRTF("and");
            break;              /* BAnd */
        case 14:
            fprintRTF("Ed.");
            break;              /* BED */
        case 15:
            fprintRTF("Eds.");
            break;              /* BEDS */
        case 16:
            fprintRTF("Trans.");
            break;              /* BTRANS */
        case 17:
            fprintRTF("Trans.");
            break;              /* BTRANSS */
        case 18:
            fprintRTF("Chair");
            break;              /* BCHAIR */
        case 19:
            fprintRTF("Chairs");
            break;              /* BCHAIRS */
        case 20:
            fprintRTF("Vol.");
            break;              /* BVOL */
        case 21:
            fprintRTF("Vols.");
            break;              /* BVOLS */
        case 22:
            fprintRTF("No.");
            break;              /* BNUM */
        case 23:
            fprintRTF("Nos.");
            break;              /* BNUMS */
        case 24:
            fprintRTF("ed.");
            break;              /* BEd */
        case 25:
            fprintRTF("p.");
            break;              /* BPG */
        case 26:
            fprintRTF("pp.");
            break;              /* BPGS */
        case 27:
            fprintRTF("Tech. Rep.");
            break;              /* BTR */
        case 28:
            fprintRTF("Doctoral dissertation");
            break;              /* BPhD */
        case 29:
            fprintRTF("Unpublished doctoral dissertation");
            break;              /* BUPhD */
        case 30:
            fprintRTF("Master's thesis");
            break;              /* BMTh */
        case 31:
            fprintRTF("Unpublished master's thesis");
            break;              /* BUMTh */
        case 32:
            fprintRTF("Original work published ");
            break;              /* BOWP */
        case 33:
            fprintRTF("Reprinted from ");
            break;              /* BREPR */
        case 34:
            s = getBraceParam();
            if (sscanf(s, "%d", &n) == 1)
                fprintRTF("%c", (char) 'a' + n - 1);
            free(s);
            break;
        case 35:
            fprintRTF("%s", (g_current_cite_paren) ? "&" : "and");  /* BBA */
            break;
        case 36:
            s = getBraceParam();    /* \AX{entry} */
            diagnostics(4, "Ignoring \\AX{%s}", s);
            if (s)
                free(s);
            break;
        default:;
    }
}

/******************************************************************************
purpose: handles \citename from authordate bib style
******************************************************************************/
void CmdCiteName(int code)
{
    char *s;

    s = getBraceParam();

    diagnostics(4, "Entering CmdCitename", s);

    if (!g_suppress_name)
        ConvertString(s);

    free(s);

}

/******************************************************************************
purpose: handles \numberline{3.2.1}
******************************************************************************/
void CmdNumberLine(int code)
{
    char *number;

    number = getBraceParam();
    diagnostics(4, "Entering CmdNumberLine [%s]", number);
    ConvertString(number);
    fprintRTF("\\tab ");
    free(number);
}

/******************************************************************************
purpose: handles \harvarditem{a}{b}{c} \harvardyearleft \harvardyearright
******************************************************************************/
void CmdHarvard(int code)
{
    char *s=NULL;

	if (code == CITE_HARVARD_ITEM) {
		s = getBracketParam();
		if (s) free(s);
		s = getBraceParam();
		free(s);
		s = getBraceParam();
		free(s);
		s = getBraceParam();
		free(s);
	}
	
	if (code == CITE_HARVARD_YEAR_LEFT) 
		fprintRTF("(");

	if (code == CITE_HARVARD_YEAR_RIGHT) 
		fprintRTF(")");
		
	if (code == CITE_HARVARD_AND)
		fprintRTF("&");
}

/******************************************************************************
purpose: handles \citename from authordate bib style
******************************************************************************/
void CmdContentsLine(int code)
{
    char *type, *text, *num, *contents_type;

    type = getBraceParam();
    text = getBraceParam();
    num = getBraceParam();

    diagnostics(1, "Entering CmdContentsLine %s [%s]", type, text);

    CmdStartParagraph(TITLE_PAR);
    fprintRTF("{");
    contents_type = strdup_together("contents_", type);
    InsertStyle(contents_type);
    fprintRTF(" ");
    ConvertString(text);
    CmdEndParagraph(0);
    fprintRTF("}");

    free(type);
    free(text);
    free(num);
    free(contents_type);
}

/******************************************************************************
purpose: handles \listoffigures \tableofcontents \listoftables
******************************************************************************/
void CmdListOf(int code)
{
    /* 
     * FILE *fp=NULL; char *name;
     */

    diagnostics(4, "Entering CmdListOf");

    /* this it probably the wrong way to implement \tableofcontents ! */

    /* 
     * print appropriate heading CmdVspace(VSPACE_BIG_SKIP);
     * CmdStartParagraph(TITLE_PAR); fprintRTF("{"); if (g_document_type
     * == FORMAT_BOOK || g_document_type == FORMAT_REPORT)
     * InsertStyle("chapter"); else InsertStyle("section"); fprintRTF("
     * ");
     * 
     * if (code == LIST_OF_FIGURES) { ConvertBabelName("LISTFIGURENAME"); }
     * 
     * if (code == LIST_OF_TABLES) { name = g_lot_name;
     * ConvertBabelName("LISTTABLENAME"); }
     * 
     * if (code == TABLE_OF_CONTENTS) { name = g_toc_name;
     * ConvertBabelName("CONTENTSNAME"); }
     * 
     * CmdEndParagraph(0); fprintRTF("}"); CmdVspace(VSPACE_SMALL_SKIP);
     * 
     * now set things up so that we start reading from the appropriate
     * auxiliary file fp = my_fopen(name, "r"); if (fp == NULL) {
     * diagnostics(WARNING, "Missing latex .lot/.lof/.toc file.  Run
     * LaTeX to create %s\n", name); return; } else fclose(fp);
     * esting for existence to give better error message
     * 
     * PushSource(name,NULL);
     * 
     */
}
