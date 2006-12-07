/* $Id: commands.h,v 1.23 2004/10/03 03:26:15 prahl Exp $ */

#define PREAMBLE 1
#define DOCUMENT 2
#define ITEMIZE 3
#define ENUMERATE 4
#define DESCRIPTION 5
#define LETTER 8
#define IGN_ENV_CMD   9
#define HYPERLATEX   10
#define FIGURE_ENV   11
#define GERMAN_MODE  12
#define FRENCH_MODE  13
#define RUSSIAN_MODE 14
#define GENERIC_ENV  15
#define CZECH_MODE   16
#define APACITE_MODE 17
#define NATBIB_MODE  18
#define HARVARD_MODE 19
#define AUTHORDATE_MODE 20

#define ON 0x4000
#define OFF 0x0000

void            PushEnvironment(int code);
void            PopEnvironment();
bool            CallCommandFunc(char *cCommand);
void            CallParamFunc(char *cCommand, int AddParam);
int             CurrentEnvironmentCount(void);
