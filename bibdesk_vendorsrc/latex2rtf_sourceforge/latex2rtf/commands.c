
/* commands.c - Defines subroutines to translate LaTeX commands to RTF

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
#include "cfg.h"
#include "main.h"
#include "convert.h"
#include "chars.h"
#include "l2r_fonts.h"
#include "preamble.h"
#include "funct1.h"
#include "tables.h"
#include "equation.h"
#include "letterformat.h"
#include "commands.h"
#include "parser.h"
#include "xref.h"
#include "ignore.h"
#include "lengths.h"
#include "definitions.h"
#include "graphics.h"

typedef struct commandtag {
    char *cpCommand;            /* LaTeX command name without \ */
    void (*func) (int);         /* function to convert LaTeX to RTF */
    int param;                  /* used in various ways */
} CommandArray;

static int iEnvCount = 0;       /* number of active environments */
static int iAllCommands = 0;       /* number of (lists of commands) */
static CommandArray *Environments[100]; /* list of active environments */
static CommandArray *All_Commands[100]; /* list of (list of commands) */
static int g_par_indent_array[100];
static int g_left_indent_array[100];
static int g_right_indent_array[100];
static char g_align_array[100];

static CommandArray commands[] = {
    {"begin", CmdBeginEnd, CMD_BEGIN},
    {"end", CmdBeginEnd, CMD_END},
    {"today", CmdToday, 0},
    {"footnote", CmdFootNote, FOOTNOTE},

	{"rmfamily", CmdFontFamily, F_FAMILY_ROMAN  },
    {"rm", CmdFontFamily, F_FAMILY_ROMAN_1},
    {"mathrm", CmdFontFamily, F_FAMILY_ROMAN_2},
    {"textrm", CmdFontFamily, F_FAMILY_ROMAN_2},

    {"sffamily", CmdFontFamily, F_FAMILY_SANSSERIF},
    {"sf", CmdFontFamily, F_FAMILY_SANSSERIF_1},
    {"mathsf", CmdFontFamily, F_FAMILY_SANSSERIF_2},
    {"textsf", CmdFontFamily, F_FAMILY_SANSSERIF_2},

    {"ttfamily", CmdFontFamily, F_FAMILY_TYPEWRITER},
    {"tt", CmdFontFamily, F_FAMILY_TYPEWRITER_1},
    {"mathtt", CmdFontFamily, F_FAMILY_TYPEWRITER_2},
    {"texttt", CmdFontFamily, F_FAMILY_TYPEWRITER_2},

    {"cal", CmdFontFamily, F_FAMILY_CALLIGRAPHIC_1},
    {"mathcal", CmdFontFamily, F_FAMILY_CALLIGRAPHIC_2},

    {"bfseries", CmdFontSeries, F_SERIES_BOLD},
    {"bf", CmdFontSeries, F_SERIES_BOLD_1},
    {"textbf", CmdFontSeries, F_SERIES_BOLD_2},
    {"mathbf", CmdFontSeries, F_SERIES_BOLD_2},

    {"mdseries", CmdFontSeries, F_SERIES_MEDIUM},
    {"textmd", CmdFontSeries, F_SERIES_MEDIUM_2},
    {"mathmd", CmdFontSeries, F_SERIES_MEDIUM_2},

    {"itshape", CmdFontShape, F_SHAPE_ITALIC},
    {"it", CmdFontShape, F_SHAPE_ITALIC_1},
    {"mit", CmdFontShape, F_SHAPE_ITALIC_1},
    {"textit", CmdFontShape, F_SHAPE_ITALIC_2},
    {"mathit", CmdFontShape, F_SHAPE_ITALIC_2},

    {"upshape", CmdFontShape, F_SHAPE_UPRIGHT},
    {"textup", CmdFontShape, F_SHAPE_UPRIGHT_2},
    {"mathup", CmdFontShape, F_SHAPE_UPRIGHT_2},

    {"scfamily", CmdFontShape, F_SHAPE_CAPS},
    {"scshape", CmdFontShape, F_SHAPE_CAPS},
    {"sc", CmdFontShape, F_SHAPE_CAPS_1},
    {"textsc", CmdFontShape, F_SHAPE_CAPS_2},
    {"mathsc", CmdFontShape, F_SHAPE_CAPS_2},

    {"slshape", CmdFontShape, F_SHAPE_SLANTED},
    {"sl", CmdFontShape, F_SHAPE_SLANTED_1},
    {"textsl", CmdFontShape, F_SHAPE_SLANTED_2},
    {"mathsl", CmdFontShape, F_SHAPE_SLANTED_2},

    {"tiny", CmdFontSize, 10},
    {"ssmall", CmdFontSize, 12},    /* from moresize.sty */
    {"scriptsize", CmdFontSize, 14},
    {"footnotesize", CmdFontSize, 16},
    {"enotesize", CmdFontSize, 16},
    {"small", CmdFontSize, 18},
    {"normalsize", CmdFontSize, 20},
    {"large", CmdFontSize, 24},
    {"Large", CmdFontSize, 28},
    {"LARGE", CmdFontSize, 34},
    {"huge", CmdFontSize, 40},
    {"Huge", CmdFontSize, 50},
    {"HUGE", CmdFontSize, 60},  /* from moresize.sty */

    /* ---------- OTHER FONT STUFF ------------------- */
    {"em", CmdEmphasize, F_EMPHASIZE_1},
    {"emph", CmdEmphasize, F_EMPHASIZE_2},
    {"underline", CmdUnderline, 0},
    {"textnormal", CmdTextNormal, F_TEXT_NORMAL_2},
    {"normalfont", CmdTextNormal, F_TEXT_NORMAL_2},
    {"mathnormal", CmdTextNormal, F_TEXT_NORMAL_3},

    {"raggedright", CmdAlign, PAR_RAGGEDRIGHT},
    {"centerline", CmdAlign, PAR_CENTERLINE},
    {"vcenter", CmdAlign, PAR_VCENTER},

    /* ---------- LOGOS ------------------- */
    {"LaTeX", CmdLogo, CMD_LATEX},
    {"LaTeXe", CmdLogo, CMD_LATEXE},
    {"TeX", CmdLogo, CMD_TEX},
    {"SLiTeX", CmdLogo, CMD_SLITEX},
    {"BibTeX", CmdLogo, CMD_BIBTEX},
    {"AmSTeX", CmdLogo, CMD_AMSTEX},
    {"AmSLaTeX", CmdLogo, CMD_AMSLATEX},
    {"LyX", CmdLogo, CMD_LYX},

    /* ---------- SPECIAL CHARACTERS ------------------- */
    {"hat", CmdHatChar, 0},
    {"check", CmdHacekChar, 0},
    {"breve", CmdBreveChar, 0},
    {"acute", CmdRApostrophChar, 0},
    {"grave", CmdLApostrophChar, 0},
    {"tilde", CmdTildeChar, 0},
    {"bar", CmdMacronChar, 0},
    {"vec", CmdVecChar, 0},
    {"dot", CmdDotChar, 0},
    {"ddot", CmdUmlauteChar, 0},
    {"u", CmdBreveChar, 0},
    {"d", CmdUnderdotChar, 0},
    {"v", CmdHacekChar, 0},
    {"r", CmdOaccentChar, 0},
    {"b", CmdUnderbarChar, 0},
    {"c", CmdCedillaChar, 0},
    {"i", CmdDotlessChar, 0},
    {"j", CmdDotlessChar, 1},

/* sectioning commands */
    {"part", CmdSection, SECT_PART},
    {"part*", CmdSection, SECT_PART_STAR},
    {"chapter", CmdSection, SECT_CHAPTER},
    {"chapter*", CmdSection, SECT_CHAPTER_STAR},
    {"section", CmdSection, SECT_NORM},
    {"section*", CmdSection, SECT_NORM_STAR},
    {"subsection", CmdSection, SECT_SUB},
    {"subsection*", CmdSection, SECT_SUB_STAR},
    {"subsubsection", CmdSection, SECT_SUBSUB},
    {"subsubsection*", CmdSection, SECT_SUBSUB_STAR},
    {"paragraph", CmdSection, SECT_SUBSUBSUB},
    {"paragraph*", CmdSection, SECT_SUBSUBSUB_STAR},
    {"subparagraph", CmdSection, SECT_SUBSUBSUBSUB},
    {"subparagraph*", CmdSection, SECT_SUBSUBSUBSUB_STAR},

    {"ldots", CmdLdots, 0},
    {"maketitle", CmdMakeTitle, 0},
    {"par", CmdEndParagraph, 0},
    {"noindent", CmdIndent, INDENT_NONE},
    {"indent", CmdIndent, INDENT_USUAL},
    {"caption", CmdCaption, 0},
    {"appendix", CmdIgnore, 0},
    {"protect", CmdIgnore, 0},
    {"clearpage", CmdNewPage, NewPage},
    {"cleardoublepage", CmdNewPage, NewPage},
    {"newpage", CmdNewPage, NewColumn},
    {"pagebreak", CmdNewPage, NewPage},
    {"mbox", CmdBox, BOX_MBOX},
    {"hbox", CmdBox, BOX_HBOX},
    {"vbox", CmdBox, BOX_VBOX},
    {"fbox", CmdBox, BOX_FBOX},
    {"parbox", CmdBox, BOX_PARBOX},
    {"frenchspacing", CmdIgnore, 0},
    {"nonfrenchspacing", CmdIgnore, 0},
    {"include", CmdIgnoreParameter, No_Opt_One_NormParam},  /* should not happen */
    {"input", CmdIgnoreParameter, No_Opt_One_NormParam},    /* should not happen */
    {"verb", CmdVerb, VERB_VERB},
    {"verb*", CmdVerb, VERB_STAR},
    {"url", CmdVerb, VERB_URL},
    {"onecolumn", CmdColumn, One_Column},
    {"twocolumn", CmdColumn, Two_Column},
    {"includegraphics", CmdGraphics, 0},
    {"epsffile", CmdGraphics, 1},
    {"epsfbox", CmdGraphics, 2},
    {"BoxedEPSF", CmdGraphics, 3},
    {"psfig", CmdGraphics, 4},
    {"includegraphics*", CmdGraphics, 0},
    {"moveleft", CmdLength, 0},
    {"moveright", CmdLength, 0},
    {"hsize", CmdLength, 0},
    {"letterspace", CmdLength, 0},
    {"footnotemark", CmdIgnoreParameter, One_Opt_No_NormParam},
    {"endnotemark", CmdIgnoreParameter, One_Opt_No_NormParam},
    {"label", CmdLabel, LABEL_LABEL},
    {"ref", CmdLabel, LABEL_REF},
    {"eqref", CmdLabel, LABEL_EQREF},
    {"pageref", CmdLabel, LABEL_PAGEREF},
    {"cite", CmdCite, CITE_CITE},
	{"onlinecite", CmdCite, CITE_CITE},
	{"citeonline", CmdCite, CITE_CITE},
    {"bibliography", CmdBibliography, 0},
    {"bibliographystyle", CmdBibliographyStyle, 0},
    {"bibitem", CmdBibitem, 0},
    {"newblock", CmdNewblock, 0},
    {"newsavebox", CmdIgnoreParameter, No_Opt_One_NormParam},
    {"usebox", CmdIgnoreParameter, No_Opt_One_NormParam},

/*	{"fbox", CmdIgnoreParameter, No_Opt_One_NormParam}, */
    {"quad", CmdQuad, 1},
    {"qquad", CmdQuad, 2},
    {"textsuperscript", CmdSuperscript, 1},
    {"textsubscript", CmdSubscript, 1},
    {"hspace", CmdIgnoreParameter, No_Opt_One_NormParam},
    {"hspace*", CmdIgnoreParameter, No_Opt_One_NormParam},
    {"vspace", CmdVspace, 0},
    {"vspace*", CmdVspace, 0},
    {"vskip", CmdVspace, -1},
    {"smallskip", CmdVspace, 1},
    {"medskip", CmdVspace, 2},
    {"bigskip", CmdVspace, 3},
    {"addvspace", CmdIgnoreParameter, No_Opt_One_NormParam},
    {"addcontentsline", CmdIgnoreParameter, No_Opt_Three_NormParam},
    {"addcontents", CmdIgnoreParameter, No_Opt_Two_NormParam},
    {"stretch", CmdIgnoreParameter, No_Opt_One_NormParam},
    {"typeaout", CmdIgnoreParameter, No_Opt_One_NormParam},
    {"index", CmdIndex, 0},
    {"printindex", CmdPrintIndex, 0},
    {"indexentry", CmdIgnoreParameter, No_Opt_Two_NormParam},
    {"glossary", CmdIgnoreParameter, No_Opt_One_NormParam},
    {"glossaryentry", CmdIgnoreParameter, No_Opt_Two_NormParam},
    {"typeout", CmdIgnoreParameter, No_Opt_One_NormParam},
    {"Typein", CmdIgnoreParameter, One_Opt_One_NormParam},
    {"includeonly", CmdIgnoreParameter, No_Opt_One_NormParam},
    {"nocite", CmdNoCite, No_Opt_One_NormParam},
    {"stepcounter", CmdIgnoreParameter, No_Opt_One_NormParam},
    {"refstepcounter", CmdIgnoreParameter, No_Opt_One_NormParam},
    {"fnsymbol", CmdIgnoreParameter, No_Opt_One_NormParam},
    {"Alph", CmdIgnoreParameter, No_Opt_One_NormParam},
    {"alph", CmdIgnoreParameter, No_Opt_One_NormParam},
    {"Roman", CmdIgnoreParameter, No_Opt_One_NormParam},
    {"roman", CmdIgnoreParameter, No_Opt_One_NormParam},
    {"arabic", CmdIgnoreParameter, No_Opt_One_NormParam},
    {"newcount", CmdIgnoreDef, 0},
    {"output", CmdIgnoreDef, 0},
    {"value", CmdCounter, COUNTER_VALUE},
    {"makebox", CmdIgnoreParameter, Two_Opt_One_NormParam},
    {"framebox", CmdIgnoreParameter, Two_Opt_One_NormParam},
    {"sbox", CmdIgnoreParameter, No_Opt_Two_NormParam},
    {"savebox", CmdIgnoreParameter, Two_Opt_Two_NormParam},
    {"rule", CmdIgnoreParameter, One_Opt_Two_NormParam},
    {"raisebox", CmdIgnoreParameter, Two_Opt_Two_NormParam},
    {"newfont", CmdIgnoreParameter, No_Opt_Two_NormParam},
    {"settowidth", CmdIgnoreParameter, No_Opt_Two_NormParam},
    {"nopagebreak", CmdIgnoreParameter, One_Opt_No_NormParam},
    {"samepage", CmdIgnore, 0},
    {"linebreak", CmdIgnoreParameter, One_Opt_No_NormParam},
    {"nolinebreak", CmdIgnoreParameter, One_Opt_No_NormParam},
    {"typein", CmdIgnoreParameter, One_Opt_One_NormParam},
    {"marginpar", CmdIgnoreParameter, One_Opt_One_NormParam},
    {"baselineskip", Cmd_OptParam_Without_braces, 0},
    {"psfrag", CmdIgnoreParameter, No_Opt_Two_NormParam},
    {"lineskip", Cmd_OptParam_Without_braces, 0},
    {"vsize", Cmd_OptParam_Without_braces, 0},
    {"setbox", Cmd_OptParam_Without_braces, 0},
    {"thanks", CmdFootNote, FOOTNOTE_THANKS},
    {"bibliographystyle", CmdIgnoreParameter, No_Opt_One_NormParam},
    {"let", CmdIgnoreLet, 0},
    {"multicolumn", CmdMultiCol, 0},
    {"frac", CmdFraction, 0},
    {"dfrac", CmdFraction, 0},
    {"Frac", CmdFraction, 0},
    {"sqrt", CmdRoot, 0},
    {"lim", CmdLim, 0},
    {"limsup", CmdLim, 1},
    {"liminf", CmdLim, 2},
    {"int", CmdIntegral, 0},
    {"iint", CmdIntegral, 3},
    {"iiint", CmdIntegral, 4},
    {"sum", CmdIntegral, 1},
    {"prod", CmdIntegral, 2},
    {"left", CmdLeftRight, 0},
    {"right", CmdLeftRight, 1},
    {"stackrel", CmdStackrel, 0},
    {"matrix", CmdMatrix, 0},
    {"leftrightarrows", CmdArrows, LEFT_RIGHT},
    {"leftleftarrows", CmdArrows, LEFT_LEFT},
    {"rightrightarrows", CmdArrows, RIGHT_RIGHT},
    {"rightleftarrows", CmdArrows, RIGHT_LEFT},
    {"longleftrightarrows", CmdArrows, LONG_LEFTRIGHT},
    {"longrightleftarrows", CmdArrows, LONG_RIGHTLEFT},
    {"nonumber", CmdNonumber, EQN_NO_NUMBER},
    {"char", CmdChar, 0},
    {"htmladdnormallink", CmdHtml, LABEL_HTMLADDNORMALREF},
    {"htmlref", CmdHtml, LABEL_HTMLREF},
    {"nobreakspace", CmdNonBreakSpace, 0},
    {"abstract", CmdAbstract, 1},
    {"endinput", CmdEndInput, 0},
    {"textcolor", CmdTextColor, 0},
    {"tableofcontents", CmdListOf, TABLE_OF_CONTENTS},
    {"listoffigures", CmdListOf, LIST_OF_FIGURES},
    {"listoftables", CmdListOf, LIST_OF_TABLES},
    {"numberline", CmdNumberLine, 0},
    {"contentsline", CmdContentsLine, 0},
    {"centering", CmdAlign, PAR_CENTERING},

    {"", NULL, 0}
};

/********************************************************************
  commands found in the preamble of the LaTeX file
 ********************************************************************/
static CommandArray PreambleCommands[] = {
    {"documentclass", CmdDocumentStyle, 0},
    {"documentstyle", CmdDocumentStyle, 0},
    {"usepackage", CmdUsepackage, 0},
/*    {"begin", CmdPreambleBeginEnd, CMD_BEGIN},*/
    {"title", CmdTitle, TITLE_TITLE},
    {"author", CmdTitle, TITLE_AUTHOR},
    {"date", CmdTitle, TITLE_DATE},
    {"flushbottom", CmdBottom, 0},
    {"raggedbottom", CmdBottom, 0},
    {"addtolength", CmdLength, LENGTH_ADD},
    {"setlength", CmdLength, LENGTH_SET},
    {"newlength", CmdLength, LENGTH_NEW},
    {"newcounter", CmdCounter, COUNTER_NEW},
    {"setcounter", CmdCounter, COUNTER_SET},
    {"addtocounter", CmdCounter, COUNTER_ADD},
    {"cfoot", CmdHeadFoot, CFOOT},
    {"rfoot", CmdHeadFoot, RFOOT},
    {"lfoot", CmdHeadFoot, LFOOT},
    {"chead", CmdHeadFoot, CHEAD},
    {"rhead", CmdHeadFoot, RHEAD},
    {"lhead", CmdHeadFoot, LHEAD},
    {"thepage", CmdThePage, 0},
    {"hyphenation", CmdHyphenation, 0},
    {"def", CmdNewDef, DEF_DEF},
    {"newcommand", CmdNewDef, DEF_NEW},
    {"providecommand", CmdNewDef, DEF_NEW},
    {"DeclareRobustCommand", CmdNewDef, DEF_NEW},
    {"DeclareRobustCommand*", CmdNewDef, DEF_NEW},
    {"renewcommand", CmdNewDef, DEF_RENEW},
    {"newenvironment", CmdNewEnvironment, DEF_NEW},
    {"renewenvironment", CmdNewEnvironment, DEF_RENEW},
    {"newtheorem", CmdNewTheorem, 0},
    {"renewtheorem", CmdIgnoreParameter, One_Opt_Two_NormParam},
    {"pagestyle", CmdIgnoreParameter, No_Opt_One_NormParam},
    {"thispagestyle", CmdIgnoreParameter, No_Opt_One_NormParam},
    {"pagenumbering", CmdIgnoreParameter, No_Opt_One_NormParam},
    {"markboth", CmdIgnoreParameter, No_Opt_Two_NormParam},
    {"markright", CmdIgnoreParameter, No_Opt_One_NormParam},
    {"makeindex", CmdIgnoreParameter, 0},
    {"makeglossary", CmdIgnoreParameter, 0},
    {"listoffiles", CmdIgnoreParameter, 0},
    {"nofiles", CmdIgnoreParameter, 0},
    {"makelabels", CmdIgnoreParameter, 0},
    {"verbositylevel", CmdVerbosityLevel, 0},
    {"hoffset", CmdSetTexLength, SL_HOFFSET},
    {"voffset", CmdSetTexLength, SL_VOFFSET},
    {"parindent", CmdSetTexLength, SL_PARINDENT},
    {"parskip", CmdSetTexLength, SL_PARSKIP},
    {"baselineskip", CmdSetTexLength, SL_BASELINESKIP},
    {"topmargin", CmdSetTexLength, SL_TOPMARGIN},
    {"textheight", CmdSetTexLength, SL_TEXTHEIGHT},
    {"headheight", CmdSetTexLength, SL_HEADHEIGHT},
    {"headsep", CmdSetTexLength, SL_HEADSEP},
    {"textwidth", CmdSetTexLength, SL_TEXTWIDTH},
    {"oddsidemargin", CmdSetTexLength, SL_ODDSIDEMARGIN},
    {"evensidemargin", CmdSetTexLength, SL_EVENSIDEMARGIN},
    {"footnotetext", CmdFootNote, FOOTNOTE_TEXT},
    {"endnotetext", CmdFootNote, FOOTNOTE_TEXT | FOOTNOTE_ENDNOTE},
    {"include", CmdInclude, 0},
    {"input", CmdInclude, 0},
    {"htmladdnormallink", CmdHtml, LABEL_HTMLADDNORMALREF},
    {"htmlref", CmdHtml, LABEL_HTMLREF},
    {"nobreakspace", CmdNonBreakSpace, 0},
    {"signature", CmdSignature, 0},
    {"hline", CmdHline, 0},
    {"cline", CmdHline, 1},
    {"ifx", CmdIf, 0},
    {"theendnotes", CmdTheEndNotes, 0},
    {"", NULL, 0}
};                              /* end of list */

static CommandArray ItemizeCommands[] = {
    {"item", CmdItem, ITEMIZE},
    {"", NULL, 0}
};

static CommandArray DescriptionCommands[] = {
    {"item", CmdItem, DESCRIPTION},
    {"", NULL, 0}
};

static CommandArray EnumerateCommands[] = {
    {"item", CmdItem, ENUMERATE},
    {"", NULL, 0}
};

static CommandArray FigureCommands[] = {
    {"caption", CmdCaption, 0},
    {"center", CmdAlign, PAR_CENTER},
    {"", NULL, 0}
};

static CommandArray LetterCommands[] = {
    {"opening", CmdOpening, 0},
    {"closing", CmdClosing, 0},
    {"address", CmdAddress, 0},
    {"signature", CmdSignature, 0},
    {"ps", CmdPs, LETTER_PS},
    {"cc", CmdPs, LETTER_CC},
    {"encl", CmdPs, LETTER_ENCL},
    {"", NULL, 0}
};

static CommandArray GermanModeCommands[] = {
    {"ck", GermanPrint, GP_CK},
    {"glqq", GermanPrint, GP_LDBL},
    {"glq", GermanPrint, GP_L},
    {"grq", GermanPrint, GP_R},
    {"grqq", GermanPrint, GP_RDBL},
    {"", NULL, 0}
};

static CommandArray CzechModeCommands[] = {
    {"uv", CmdCzechAbbrev, 0},
    {"", NULL, 0}
};

static CommandArray FrenchModeCommands[] = {

/*    {"degree", CmdFrenchAbbrev, DEGREE}, */
    {"ier", CmdFrenchAbbrev, IERF},
    {"iere", CmdFrenchAbbrev, IEREF},
    {"iers", CmdFrenchAbbrev, IERSF},
    {"ieres", CmdFrenchAbbrev, IERESF},
    {"ieme", CmdFrenchAbbrev, IEMEF},
    {"iemes", CmdFrenchAbbrev, IEMESF},
    {"numero", CmdFrenchAbbrev, NUMERO},
    {"numeros", CmdFrenchAbbrev, NUMEROS},
    {"Numero", CmdFrenchAbbrev, CNUMERO},
    {"Numeros", CmdFrenchAbbrev, CNUMEROS},

/*    {"degres", CmdFrenchAbbrev, DEGREE}, */

/*    {"textdegree", CmdFrenchAbbrev, DEGREE}, */
    {"primo", CmdFrenchAbbrev, PRIMO},
    {"secundo", CmdFrenchAbbrev, SECUNDO},
    {"tertio", CmdFrenchAbbrev, TERTIO},
    {"quarto", CmdFrenchAbbrev, QUARTO},
    {"inferieura", CmdFrenchAbbrev, INFERIEURA},
    {"superieura", CmdFrenchAbbrev, SUPERIEURA},
    {"lq", CmdFrenchAbbrev, FRENCH_LQ},
    {"rq", CmdFrenchAbbrev, FRENCH_RQ},
    {"lqq", CmdFrenchAbbrev, FRENCH_LQQ},
    {"rqq", CmdFrenchAbbrev, FRENCH_RQQ},
    {"pointvirgule", CmdFrenchAbbrev, POINT_VIRGULE},
    {"pointexclamation", CmdFrenchAbbrev, POINT_EXCLAMATION},
    {"pointinterrogation", CmdFrenchAbbrev, POINT_INTERROGATION},
    {"dittomark", CmdFrenchAbbrev, DITTO_MARK},
    {"deuxpoints", CmdFrenchAbbrev, DEUX_POINTS},
    {"fup", CmdFrenchAbbrev, FUP},
    {"up", CmdFrenchAbbrev, FUP},
    {"LCS", CmdFrenchAbbrev, LCS},
    {"FCS", CmdFrenchAbbrev, FCS},
    {"og", CmdFrenchAbbrev, FRENCH_OG},
    {"fg", CmdFrenchAbbrev, FRENCH_FG},
    {"", NULL, 0}
};

/********************************************************************/

/* commands for Russian Mode */

/********************************************************************/
static CommandArray RussianModeCommands[] = {
    {"CYRA", CmdCyrillicChar, 0xC0},
    {"CYRB", CmdCyrillicChar, 0xC1},
    {"CYRV", CmdCyrillicChar, 0xC2},
    {"CYRG", CmdCyrillicChar, 0xC3},
    {"CYRD", CmdCyrillicChar, 0xC4},
    {"CYRE", CmdCyrillicChar, 0xC5},
    {"CYRZH", CmdCyrillicChar, 0xC6},
    {"CYRZ", CmdCyrillicChar, 0xC7},
    {"CYRI", CmdCyrillicChar, 0xC8},
    {"CYRISHRT", CmdCyrillicChar, 0xC9},
    {"CYRK", CmdCyrillicChar, 0xCA},
    {"CYRL", CmdCyrillicChar, 0xCB},
    {"CYRM", CmdCyrillicChar, 0xCC},
    {"CYRN", CmdCyrillicChar, 0xCD},
    {"CYRO", CmdCyrillicChar, 0xCE},
    {"CYRP", CmdCyrillicChar, 0xCF},
    {"CYRR", CmdCyrillicChar, 0xD0},
    {"CYRS", CmdCyrillicChar, 0xD1},
    {"CYRT", CmdCyrillicChar, 0xD2},
    {"CYRU", CmdCyrillicChar, 0xD3},
    {"CYRF", CmdCyrillicChar, 0xD4},
    {"CYRH", CmdCyrillicChar, 0xD5},
    {"CYRC", CmdCyrillicChar, 0xD6},
    {"CYRCH", CmdCyrillicChar, 0xD7},
    {"CYRSH", CmdCyrillicChar, 0xD8},
    {"CYRCHSH", CmdCyrillicChar, 0xD9},
    {"CYRHRDSN", CmdCyrillicChar, 0xDA},
    {"CYRERY", CmdCyrillicChar, 0xDB},
    {"CYRSFTSN", CmdCyrillicChar, 0xDC},
    {"CYREREV", CmdCyrillicChar, 0xDD},
    {"CYRYU", CmdCyrillicChar, 0xDE},
    {"CYRYA", CmdCyrillicChar, 0xDF},
    {"cyra", CmdCyrillicChar, 0xE0},
    {"cyrb", CmdCyrillicChar, 0xE1},
    {"cyrv", CmdCyrillicChar, 0xE2},
    {"cyrg", CmdCyrillicChar, 0xE3},
    {"cyrd", CmdCyrillicChar, 0xE4},
    {"cyre", CmdCyrillicChar, 0xE5},
    {"cyrzh", CmdCyrillicChar, 0xE6},
    {"cyrz", CmdCyrillicChar, 0xE7},
    {"cyri", CmdCyrillicChar, 0xE8},
    {"cyrishrt", CmdCyrillicChar, 0xE9},
    {"cyrk", CmdCyrillicChar, 0xEA},
    {"cyrl", CmdCyrillicChar, 0xEB},
    {"cyrm", CmdCyrillicChar, 0xEC},
    {"cyrn", CmdCyrillicChar, 0xED},
    {"cyro", CmdCyrillicChar, 0xEE},
    {"cyrp", CmdCyrillicChar, 0xEF},
    {"cyrr", CmdCyrillicChar, 0xF0},
    {"cyrs", CmdCyrillicChar, 0xF1},
    {"cyrt", CmdCyrillicChar, 0xF2},
    {"cyru", CmdCyrillicChar, 0xF3},
    {"cyrf", CmdCyrillicChar, 0xF4},
    {"cyrh", CmdCyrillicChar, 0xF5},
    {"cyrc", CmdCyrillicChar, 0xF6},
    {"cyrch", CmdCyrillicChar, 0xF7},
    {"cyrsh", CmdCyrillicChar, 0xF8},
    {"cyrchsh", CmdCyrillicChar, 0xF9},
    {"cyrhrdsn", CmdCyrillicChar, 0xFA},
    {"cyrery", CmdCyrillicChar, 0xFB},
    {"cyrsftsn", CmdCyrillicChar, 0xFC},
    {"cyrerev", CmdCyrillicChar, 0xFD},
    {"cyryu", CmdCyrillicChar, 0xFE},
    {"cyrya", CmdCyrillicChar, 0xFF},
    {"", NULL, 0}
};

/********************************************************************/

/* commands for begin-end environments */

/* only strings used in the form \begin{text} or \end{text} */

/********************************************************************/
static CommandArray params[] = {
    {"center", CmdAlign, PAR_CENTER},
    {"flushright", CmdAlign, PAR_RIGHT},
    {"flushleft", CmdAlign, PAR_LEFT},
    {"document", Environment, DOCUMENT},
    {"tabbing", CmdTabbing, TABBING},
    {"figure", CmdFigure, FIGURE},
    {"figure*", CmdFigure, FIGURE_1},
    {"picture", CmdPicture, 0},
    {"minipage", CmdMinipage, 0},
    {"music", CmdMusic, 0},

    {"quote", CmdQuote, QUOTE},
    {"quotation", CmdQuote, QUOTATION},
    {"enumerate", CmdList, ENUMERATE},
    {"list", CmdList, ITEMIZE},
    {"itemize", CmdList, ITEMIZE},
    {"description", CmdList, DESCRIPTION},
    {"verbatim", CmdVerbatim, VERBATIM_1},
    {"comment", CmdVerbatim, VERBATIM_4},
    {"verse", CmdVerse, 0},
    {"tabular", CmdTabular, TABULAR},
    {"tabular*", CmdTabular, TABULAR_STAR},
    {"longtable", CmdTabular, TABULAR_LONG},
    {"longtable*", CmdTabular, TABULAR_LONG_STAR},
    {"array", CmdArray, 1},

    {"displaymath", CmdEquation, EQN_DISPLAYMATH},
    {"equation", CmdEquation, EQN_EQUATION},
    {"equation*", CmdEquation, EQN_EQUATION_STAR},
    {"eqnarray*", CmdEquation, EQN_ARRAY_STAR},
    {"eqnarray", CmdEquation, EQN_ARRAY},
    {"math", CmdEquation, EQN_MATH},

    {"multicolumn", CmdMultiCol, 0},
    {"letter", CmdLetter, 0},
    {"table", CmdTable, TABLE},
    {"table*", CmdTable, TABLE_1},
    {"thebibliography", CmdThebibliography, 0},
    {"abstract", CmdAbstract, 0},
	{"acknowledgments", CmdAcknowledgments, 0},
    {"titlepage", CmdTitlepage, 0},

    {"em", CmdEmphasize, F_EMPHASIZE_3},
    {"rmfamily", CmdFontFamily, F_FAMILY_ROMAN_3},
    {"sffamily", CmdFontFamily, F_FAMILY_SANSSERIF_3},
    {"ttfamily", CmdFontFamily, F_FAMILY_TYPEWRITER_3},
    {"bfseries", CmdFontSeries, F_SERIES_BOLD_3},
    {"mdseries", CmdFontSeries, F_SERIES_MEDIUM_3},
    {"itshape", CmdFontShape, F_SHAPE_ITALIC_3},
    {"scshape", CmdFontShape, F_SHAPE_CAPS_3},
    {"slshape", CmdFontShape, F_SHAPE_SLANTED_3},
    {"it", CmdFontShape, F_SHAPE_ITALIC_4},
    {"sc", CmdFontShape, F_SHAPE_CAPS_4},
    {"sl", CmdFontShape, F_SHAPE_SLANTED_4},
    {"bf", CmdFontShape, F_SERIES_BOLD_4},
    {"sf", CmdFontFamily, F_FAMILY_ROMAN_4},
    {"tt", CmdFontFamily, F_FAMILY_SANSSERIF_4},
    {"rm", CmdFontFamily, F_FAMILY_TYPEWRITER_4},
    {"Verbatim", CmdVerbatim, VERBATIM_2},
    {"alltt", CmdVerbatim, VERBATIM_3},
    {"latexonly", CmdIgnore, 0},
    {"htmlonly", CmdIgnoreEnviron, IGNORE_HTMLONLY},
    {"rawhtml", CmdIgnoreEnviron, IGNORE_RAWHTML},
    {"theindex", CmdIgnoreEnviron, 0},
    {"", NULL, 0}
};                              /* end of list */


/********************************************************************
purpose: commands for hyperlatex package 
********************************************************************/
static CommandArray hyperlatex[] = {
    {"link", CmdLink, 0},
    {"xlink", CmdLink, 0},
    {"Cite", CmdLabel, LABEL_HYPERCITE},
    {"Ref", CmdLabel, LABEL_HYPERREF},
    {"Pageref", CmdLabel, LABEL_HYPERPAGEREF},
    {"S", CmdColsep, 0},
    {"", NULL, 0}
};                              /* end of list */

/********************************************************************
purpose: commands for apacite package 
********************************************************************/
static CommandArray apaciteCommands[] = {
    {"BBOP", CmdApaCite, 0},    /* Open parenthesis Default is "(" */
    {"BBAA", CmdApaCite, 1},    /* Last ``and'' Default is "\&" */
    {"BBAB", CmdApaCite, 2},    /* Last ``and'' Default is "and" */
    {"BBAY", CmdApaCite, 3},    /* Punctuation Default is ", " */
    {"BBC", CmdApaCite, 4},     /* Punctuation Default is "; " */
    {"BBN", CmdApaCite, 5},     /* Punctuation Default is ", " */
    {"BBCP", CmdApaCite, 6},    /* Closing parenthesis, Default is ")" */
    {"BBOQ", CmdApaCite, 7},    /* Opening quote Default is the empty string */
    {"BBCQ", CmdApaCite, 8},    /* Closing quote Default is the empty string */
    {"BCBT", CmdApaCite, 9},    /* Comma Default is "," */
    {"BCBL", CmdApaCite, 10},   /* Comma Default is "," */
    {"BOthers", CmdApaCite, 11},    /* Used for ``others'' Default is "et~al." */
    {"BIP", CmdApaCite, 12},    /* ``In press'', Default is "in press" */
    {"BAnd", CmdApaCite, 13},   /* Used as ``and'' Default is "and" */
    {"BED", CmdApaCite, 14},    /* Editor Default is "Ed." */
    {"BEDS", CmdApaCite, 15},   /* Editors Default is "Eds." */
    {"BTRANS", CmdApaCite, 16}, /* Translator. Default is "Trans." */
    {"BTRANSS", CmdApaCite, 17},    /* Translators. Default is "Trans." */
    {"BCHAIR", CmdApaCite, 18}, /* Chair Default is "Chair" */
    {"BCHAIRS", CmdApaCite, 19},    /* Chairs. Default is "Chairs" */
    {"BVOL", CmdApaCite, 20},   /* Volume, Default is "Vol." */
    {"BVOLS", CmdApaCite, 21},  /* Volumes, Default is "Vols." */
    {"BNUM", CmdApaCite, 22},   /* Number, Default is "No." */
    {"BNUMS", CmdApaCite, 23},  /* Numbers, Default is "Nos." */
    {"BEd", CmdApaCite, 24},    /* Edition, Default is "ed." */
    {"BPG", CmdApaCite, 25},    /* Page, default is "p." */
    {"BPGS", CmdApaCite, 26},   /* Pages, default is "pp." */
    {"BTR", CmdApaCite, 27},    /* technical report Default is "Tech.\ Rep." */
    {"BPhD", CmdApaCite, 28},   /* Default is "Doctoral dissertation" */
    {"BUPhD", CmdApaCite, 29},  /* Unpublished PhD Default is "Unpublished doctoral dissertation" */
    {"BMTh", CmdApaCite, 30},   /* MS thesis Default is "Master's thesis" */
    {"BUMTh", CmdApaCite, 31},  /* unpublished MS Default is "Unpublished master's thesis" */
    {"BOWP", CmdApaCite, 32},   /* default is "Original work published " */
    {"BREPR", CmdApaCite, 33},  /* default is "Reprinted from " */
    {"BCnt", CmdApaCite, 34},   /* convert number to letter */
    {"BCntIP", CmdApaCite, 34}, /* convert number to letter */
    {"BBA", CmdApaCite, 35},    /* "&" in paren, "and" otherwise */
    {"AX", CmdApaCite, 36},     /* index name */
    {"Bem", CmdEmphasize, F_EMPHASIZE_2},
    {"BCAY", CmdBCAY, 0},
    {"fullcite", CmdCite, CITE_FULL},
    {"shortcite", CmdCite, CITE_SHORT},
    {"citeNP", CmdCite, CITE_CITE_NP},
    {"fullciteNP", CmdCite, CITE_FULL_NP},
    {"shortciteNP", CmdCite, CITE_SHORT_NP},
    {"citeA", CmdCite, CITE_CITE_A},
    {"fullciteA", CmdCite, CITE_FULL_A},
    {"shortciteA", CmdCite, CITE_SHORT_A},
    {"citeauthor", CmdCite, CITE_CITE_AUTHOR},
    {"fullciteauthor", CmdCite, CITE_FULL_AUTHOR},
    {"shortciteauthor", CmdCite, CITE_SHORT_AUTHOR},
    {"citeyear", CmdCite, CITE_YEAR},
    {"citeyearNP", CmdCite, CITE_YEAR_NP},
    {"", NULL, 0}
};

/********************************************************************
purpose: commands for apacite package 
********************************************************************/
static CommandArray natbibCommands[] = {
    {"cite", CmdNatbibCite, CITE_CITE},
    {"citet", CmdNatbibCite, CITE_T},
    {"citet*", CmdNatbibCite, CITE_T_STAR},
    {"citep", CmdNatbibCite, CITE_P},
    {"citep*", CmdNatbibCite, CITE_P_STAR},
    {"citealt", CmdNatbibCite, CITE_ALT},
    {"citealp", CmdNatbibCite, CITE_ALP},
    {"citealt*", CmdNatbibCite, CITE_ALT_STAR},
    {"citealp*", CmdNatbibCite, CITE_ALP_STAR},
    {"citetext", CmdNatbibCite, CITE_TEXT},
    {"citeauthor", CmdNatbibCite, CITE_AUTHOR},
    {"citeauthor*", CmdNatbibCite, CITE_AUTHOR_STAR},
    {"citeyear", CmdNatbibCite, CITE_YEAR},
    {"citeyearpar", CmdNatbibCite, CITE_YEAR_P},
    {"Citet", CmdNatbibCite, CITE_T},
    {"Citep", CmdNatbibCite, CITE_P},
    {"Citealt", CmdNatbibCite, CITE_ALT},
    {"Citealp", CmdNatbibCite, CITE_ALP},
    {"Citeauthor", CmdNatbibCite, CITE_AUTHOR},
    {"bibpunct", CmdBibpunct, 0},
    {"", NULL, 0}
};

/********************************************************************
purpose: commands for harvard package 
********************************************************************/
static CommandArray harvardCommands[] = {
    {"cite", CmdHarvardCite, CITE_CITE},
    {"citeasnoun", CmdHarvardCite, CITE_AS_NOUN},
    {"possessivecite", CmdHarvardCite, CITE_POSSESSIVE},
    {"citeaffixed", CmdHarvardCite, CITE_AFFIXED},
    {"citeyear", CmdHarvardCite, CITE_YEAR},
    {"citeyear*", CmdHarvardCite, CITE_YEAR_STAR},
    {"citename", CmdHarvardCite, CITE_NAME},
    {"harvarditem", CmdHarvard, CITE_HARVARD_ITEM},
    {"harvardand", CmdHarvard, CITE_HARVARD_AND},
    {"harvardyearleft", CmdHarvard, CITE_HARVARD_YEAR_LEFT},
    {"harvardyearright", CmdHarvard, CITE_HARVARD_YEAR_RIGHT},
    {"", NULL, 0}
};

/********************************************************************
purpose: commands for authordate package 
********************************************************************/
static CommandArray authordateCommands[] = {
    {"citename", CmdCiteName, 0},
    {"shortcite", CmdCite, CITE_SHORT},
    {"", NULL, 0}
};

bool CallCommandFunc(char *cCommand)

/****************************************************************************
purpose: Tries to call the command-function for the commandname
params:  string with command name
returns: success or failure
globals: command-functions have side effects or recursive calls
 ****************************************************************************/
{
    int i, j;
    char *macro_string;

    diagnostics(5, "CallCommandFunc seeking <%s>, iAllCommands = %d", cCommand, iAllCommands);

    i = existsDefinition(cCommand);
    if (i > -1) {
        macro_string = expandDefinition(i);
        diagnostics(3, "CallCommandFunc <%s> expanded to <%s>", cCommand, macro_string);
        ConvertString(macro_string);
        free(macro_string);
        return TRUE;
    }

    for (j = iAllCommands - 1; j >= 0; j--) {
        i = 0;
        while (strcmp(All_Commands[j][i].cpCommand, "") != 0) {

 /*           if (i<5)
            	diagnostics(3,"CallCommandFunc (%d,%3d) Trying %s",j,i,All_Commands[j][i].cpCommand);
*/
            if (strcmp(All_Commands[j][i].cpCommand, cCommand) == 0) {
                if (All_Commands[j][i].func == NULL)
                    return FALSE;
                if (*All_Commands[j][i].func == CmdIgnoreParameter) {
                    diagnostics(WARNING, "Command \\%s ignored", cCommand);
                }

                diagnostics(5, "CallCommandFunc Found %s iAllCommands=%d number=%d", All_Commands[j][i].cpCommand, j, i);
                (*All_Commands[j][i].func) ((All_Commands[j][i].param));
                return TRUE;    /* Command Function found */
            }
            ++i;
        }
    }
    return FALSE;
}


void CallParamFunc(char *cCommand, int AddParam)

/****************************************************************************
purpose: Try to call the environment-function for the commandname
params:  cCommand - string with command name
	 AddParam - param "ORed"(||) to the int param of command-funct
returns: sucess or not
globals: command-functions have side effects or recursive calls
 ****************************************************************************/
{
    int i = 0;
    char unknown_environment[100];

    while (strcmp(params[i].cpCommand, "") != 0) {
        if (strcmp(params[i].cpCommand, cCommand) == 0) {
            assert(params[i].func != NULL);
            (*params[i].func) ((params[i].param) | AddParam);
            return;             /* command function found */
        }
        ++i;
    }

    /* unknown environment must be ignored */
    if (AddParam == ON) {
        snprintf(unknown_environment, 100, "\\%s%s%s", "end{", cCommand, "}");
        Ignore_Environment(cCommand);
        diagnostics(WARNING, "Environment <%s> ignored.  Not defined in commands.c", cCommand);
    }
}

int CurrentEnvironmentCount(void)

/****************************************************************************
purpose: to eliminate the iEnvCount global variable 
****************************************************************************/
{
    return iEnvCount;
}

void PushEnvironment(int code)

/****************************************************************************
purpose: adds the command list for a specific environment to the list
	 of commands searched through.
params:  constant identifying the environment
globals: changes Environment - array of active environments
		 iEnvCount   - counter of active environments
		 iAllCommands - counter for lists of commands
 ****************************************************************************/
{
    char *diag = "";
	int i;
	
    g_par_indent_array[iEnvCount] = getLength("parindent");
    g_left_indent_array[iEnvCount] = g_left_margin_indent;
    g_right_indent_array[iEnvCount] = g_right_margin_indent;
    g_align_array[iEnvCount] = alignment;

    switch (code) {
        case PREAMBLE:
            Environments[iEnvCount] = PreambleCommands;
            diag = "preamble";
            break;
        case DOCUMENT:
            Environments[iEnvCount] = commands;
            diag = "document";
            break;
        case ITEMIZE:
            Environments[iEnvCount] = ItemizeCommands;
            diag = "itemize";
            break;
        case ENUMERATE:
            Environments[iEnvCount] = EnumerateCommands;
            diag = "enumerate";
            break;
        case LETTER:
            Environments[iEnvCount] = LetterCommands;
            diag = "letter";
            break;
        case DESCRIPTION:
            Environments[iEnvCount] = DescriptionCommands;
            diag = "description";
            break;
        case GERMAN_MODE:
            Environments[iEnvCount] = GermanModeCommands;
            diag = "german";
            break;
        case FRENCH_MODE:
            Environments[iEnvCount] = FrenchModeCommands;
            diag = "french";
            break;
        case RUSSIAN_MODE:
            Environments[iEnvCount] = RussianModeCommands;
            diag = "russian";
            break;
        case CZECH_MODE:
            Environments[iEnvCount] = CzechModeCommands;
            diag = "czech";
            break;
        case FIGURE_ENV:
            Environments[iEnvCount] = FigureCommands;
            diag = "figure";
            break;
        case IGN_ENV_CMD:
            Environments[iEnvCount] = commands;
            diag = "*latex2rtf ignored*";
            break;
        case HYPERLATEX:
            Environments[iEnvCount] = hyperlatex;
            diag = "hyperlatex";
            break;
        case APACITE_MODE:
            Environments[iEnvCount] = apaciteCommands;
            diag = "apacite";
            break;
        case NATBIB_MODE:
            Environments[iEnvCount] = natbibCommands;
            diag = "natbib";
            break;
        case HARVARD_MODE:
            Environments[iEnvCount] = harvardCommands;
            diag = "harvard";
            break;
        case AUTHORDATE_MODE:
            Environments[iEnvCount] = authordateCommands;
            diag = "authordate";
            break;            
        case GENERIC_ENV:
            Environments[iEnvCount] = commands;
            diag = "Generic Environment";
            break;

        default:
            diagnostics(ERROR, "assertion failed at function PushEnvironment");
    }
    
    for (i=0; i<iAllCommands; i++) {
    	if (Environments[iEnvCount] == All_Commands[i])
    		break;
    }
    
    if (i==iAllCommands) {
    	All_Commands[iAllCommands] = Environments[iEnvCount];
    	iAllCommands++;
    }

    iEnvCount++;
    diagnostics(3, "Entered %s environment iEnvCount=%d iAllCommands=%d", diag, iEnvCount, iAllCommands);
}

void PopEnvironment()

/****************************************************************************
purpose: removes the environment-commands list added by last PushEnvironment;
globals: changes Environment - array of active environments
		 iEnvCount - counter of active environments
 ****************************************************************************/
{
    --iEnvCount;
    if (All_Commands[iAllCommands-1] == Environments[iEnvCount]){
    	All_Commands[iAllCommands-1] = NULL;
    	iAllCommands--;
    }
    	
    Environments[iEnvCount] = NULL;

    setLength("parindent", g_par_indent_array[iEnvCount]);
    g_left_margin_indent = g_left_indent_array[iEnvCount];
    g_right_margin_indent = g_right_indent_array[iEnvCount];
    alignment = g_align_array[iEnvCount];

    /* 
     * overlapping environments are not allowed !!! example:
     * \begin{verse}\begin{enumerate}\end{verse}\end{enumerate} ==>
     * undefined result extension possible
     */

    diagnostics(3, "Exited environment, iEnvCount now = %d", iEnvCount);
    return;
}
