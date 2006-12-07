#define FOOTNOTE            1
#define FOOTNOTE_TEXT       2
#define FOOTNOTE_THANKS     3

#define LABEL_LABEL			1
#define LABEL_HYPERREF		2
#define LABEL_REF			3
#define LABEL_HYPERCITE  	4
#define LABEL_CITE			5
#define LABEL_HYPERPAGEREF	6
#define LABEL_PAGEREF		7
#define LABEL_HTMLADDNORMALREF 8
#define LABEL_HTMLREF       9

#define BIBSTYLE_STANDARD   1
#define BIBSTYLE_APALIKE    2
#define BIBSTYLE_APACITE    3
#define BIBSTYLE_NATBIB     4
#define BIBSTYLE_AUTHORDATE 5

#define CITE_CITE           1
#define CITE_FULL           2
#define CITE_SHORT          3
#define CITE_CITE_NP        4
#define CITE_FULL_NP        5
#define CITE_SHORT_NP       6
#define CITE_CITE_A         7
#define CITE_FULL_A         8
#define CITE_SHORT_A        9
#define CITE_CITE_AUTHOR   10
#define CITE_FULL_AUTHOR   11
#define CITE_SHORT_AUTHOR  12
#define CITE_YEAR          13
#define CITE_YEAR_NP       14

#define CITE_T             16
#define CITE_T_STAR        17
#define CITE_P             18
#define CITE_P_STAR        19
#define CITE_ALT           20
#define CITE_ALP           21
#define CITE_ALT_STAR      22
#define CITE_ALP_STAR      23
#define CITE_TEXT          24
#define CITE_AUTHOR        25
#define CITE_AUTHOR_STAR   26
#define CITE_YEAR_P        27

void    CmdFootNote(int code);
void    CmdLabel(int code);
void 	CmdNoCite(int code);
void	CmdBibliographyStyle(int code);
void 	CmdBibliography(int code);
void 	CmdThebibliography(int code);
void 	CmdBibitem(int code);
void 	CmdNewblock(int code);
void	CmdIndex(int code);
void	CmdPrintIndex(int code);
void 	CmdHtml(int code);
void	InsertBookmark(char *name, char *text);
void	CmdCite(int code);
void	CmdBCAY(int code);
void	CmdApaCite(int code);
void    set_longnamesfirst(void);
void	CmdCiteName(int code);
