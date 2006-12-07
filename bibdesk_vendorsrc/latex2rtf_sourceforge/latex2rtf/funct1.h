/* funct1.h

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
*/

#define THANKS 2

#define CMD_BEGIN 1
#define CMD_END 2

#define PAR_CENTER     1
#define PAR_RIGHT      2
#define PAR_LEFT       3
#define PAR_CENTERLINE 4
#define PAR_VCENTER    5
#define PAR_RAGGEDRIGHT 6
#define PAR_CENTERING  7

#define BOX_HBOX       1
#define BOX_VBOX       2
#define BOX_MBOX 	   3
#define BOX_FBOX       4
#define BOX_PARBOX     5

#define FIRST_PAR      1
#define ANY_PAR        2
#define TITLE_PAR      3

#define INDENT_NONE    1
#define INDENT_INHIBIT 2
#define INDENT_USUAL   3

#define VERBATIM_1   1
#define VERBATIM_2   2
#define VERBATIM_3   3
#define VERBATIM_4   4
      
#define VERB_VERB    1
#define VERB_STAR    2
#define VERB_URL     3

#define VSPACE_VSPACE     -1
#define VSPACE_VSKIP       0
#define VSPACE_SMALL_SKIP  1
#define VSPACE_MEDIUM_SKIP 2
#define VSPACE_BIG_SKIP    3

void            CmdBeginEnd(int code);
void            CmdStartParagraph(int code);
void            CmdEndParagraph(int code);
void            CmdIndent(int code);
void            CmdVspace(int code);
void            CmdSlashSlash(int code);

#define DEF_NEW    1
#define DEF_RENEW  2
#define DEF_DEF    3

void            CmdNewDef(int code);
void            CmdNewEnvironment(int code);

void            CmdAlign(int code);
void            CmdToday(int code);
void            CmdIgnore(int code);
void            CmdLdots(int code);
void            Environment(int code);

#define SECT_PART               1
#define SECT_CHAPTER            2
#define SECT_NORM               3
#define SECT_SUB                4
#define SECT_SUBSUB             5
#define SECT_SUBSUBSUB          6
#define SECT_SUBSUBSUBSUB       7

#define SECT_PART_STAR         11
#define SECT_CHAPTER_STAR      12
#define SECT_NORM_STAR         13
#define SECT_SUB_STAR          14
#define SECT_SUBSUB_STAR       15
#define SECT_SUBSUBSUB_STAR    16
#define SECT_SUBSUBSUBSUB_STAR 17

#define SECT_CAPTION            8
void            CmdSection(int code);

#define QUOTE 1
#define QUOTATION 2
void            CmdQuote(int code);

#define RESET_ITEM_COUNTER 0

void            CmdList(int code);

#define COUNTER_NEW   1
#define COUNTER_SET   2
#define COUNTER_ADD   3
#define COUNTER_VALUE 4

void            CmdCounter(int code);

#define LENGTH_NEW   1
#define LENGTH_SET   2
#define LENGTH_ADD   3

void            CmdLength(int code);
void            CmdCaption(int code);
void            CmdBox(int code);
void            CmdVerb(int code);
void            CmdVerbatim(int code);
void            CmdVerse(int code);
void            TranslateGerman(void);
void            GermanPrint(int code);

#define GP_CK 1
#define GP_LDBL 2
#define GP_L 3
#define GP_R 4
#define GP_RDBL 5

void            CmdIgnoreLet(int code);
void            CmdIgnoreDef(int code);
void            CmdItem(int code);
void            CmdMinipage(int code);

#define FIGURE 1
#define FIGURE_1 5

#define IGNORE_HTMLONLY  1
#define IGNORE_PICTURE   2
#define IGNORE_MINIPAGE  3
#define IGNORE_RAWHTML   4

#define No_Opt_One_NormParam 01
#define No_Opt_Two_NormParam 02
#define No_Opt_Three_NormParam 03
#define One_Opt_No_NormParam 10
#define One_Opt_One_NormParam 11
#define One_Opt_Two_NormParam 12
#define One_Opt_Three_NormParam 13
#define Two_Opt_No_NormParam 20
#define Two_Opt_One_NormParam 21
#define Two_Opt_Two_NormParam 22
#define Two_Opt_Three_NormParam 23

#define One_Column 1
#define Two_Column 2

#define NewPage 1
#define NewColumn 2

extern bool  g_processing_list_environment;

void            CmdIgnoreEnviron(int code);
void            CmdFigure(int code);
void            Cmd_OptParam_Without_braces(int code);
void            CmdColumn(int code);
void            CmdNewPage(int code);
void            GetInputParam(char *, int);
void            CmdBottom(int code);
void            CmdAbstract(int code);
void            CmdAcknowledgments(int code);
void            CmdTitlepage(int code);
void            CmdAnnotation(int code);
void            CmdLink(int code);
void            CmdTextColor(int code);
void            GetRequiredParam(char *string, int size);
void            CmdQuad(int kk);
void            CmdColsep(int code);
void            CmdSpace(float kk);
void            CmdVerbosityLevel(int code);
void            CmdNonBreakSpace(int code);
char            *FormatUnitNumber(char *name);
void            CmdNewTheorem(int code);
void            CmdInclude(int code);
void			CmdEndInput(int code);
void			CmdIf(int code);
