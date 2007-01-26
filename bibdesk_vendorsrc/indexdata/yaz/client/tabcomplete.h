/*
 * Copyright (C) 1995-2007, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: tabcomplete.h,v 1.8 2007/01/03 08:42:13 adam Exp $
 */

/* 
   This file contains the compleaters for the different commands.
*/

char* complete_querytype(const char* text, int state);
char* complete_format(const char* text, int state);
char* complete_schema(const char* text, int state);
char* complete_attributeset(const char* text, int state);
char* complete_auto_reconnect(const char *text, int state);
char *complete_from_list(char* completions[], const char *text, int state);
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

