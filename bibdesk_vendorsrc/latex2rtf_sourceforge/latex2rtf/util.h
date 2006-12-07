/* util.h - handy strings routines

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
    2001-2003 Scott Prahl
*/

int     odd(int n);
int     even(int n);
int     strstr_count(char *s, char *t);
char *  my_strndup(char *s, size_t n);
char *  strdup_together(char *s, char *t);
char *	strdup_noblanks(char *s);
char *	strdup_nocomments(char *s);
char *	strdup_nobadchars(char *s);
char *	strdup_noendblanks(char *s);
char *	ExtractLabelTag(char *text);
char *	ExtractAndRemoveTag(char *tag, char *text);
