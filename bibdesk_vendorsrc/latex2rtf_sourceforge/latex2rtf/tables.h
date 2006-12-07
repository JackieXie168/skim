/* $Id: tables.h,v 1.6 2002/09/23 14:34:42 prahl Exp $ */

#define TABBING   5
#define TABULAR   1
#define TABULAR_STAR 2
#define TABULAR_LONG 3
#define TABULAR_LONG_STAR 4

#define TABLE 2
#define TABLE_1 3

void            CmdTabjump(void);
void            CmdTabset(void);
void            CmdTabular(int code);
void            CmdTabbing(int code);
void            CmdTable(int code);
void            CmdMultiCol(int code);
void 			CmdHline(int code);
