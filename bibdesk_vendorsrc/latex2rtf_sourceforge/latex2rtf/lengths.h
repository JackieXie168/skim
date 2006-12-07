#define SL_HOFFSET         1
#define SL_VOFFSET         2
#define SL_PARINDENT       3
#define SL_PARSKIP         4
#define SL_BASELINESKIP    5
#define SL_TOPMARGIN       6
#define SL_TEXTHEIGHT      7
#define SL_HEADHEIGHT      8
#define SL_HEADSEP         9
#define SL_TEXTWIDTH      10
#define SL_ODDSIDEMARGIN  11
#define SL_EVENSIDEMARGIN 12

void setLength(char * s, int d);
int getLength(char * s);
void CmdSetTexLength(int code);
