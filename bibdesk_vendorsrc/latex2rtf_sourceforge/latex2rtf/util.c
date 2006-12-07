
/*
 * util.c - handy routines
 * 
 * Copyright (C) 1995-2002 The Free Software Foundation
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
 * Authors: 1995-1997 Ralf Schlatterbeck 1998-2000 Georg Lehner 2001-2002 Scott
 * Prahl
 */

#include <stdlib.h>
#include <string.h>
#include "main.h"
#include "util.h"
#include "parser.h"

/******************************************************************************
 purpose:  returns true if n is odd
******************************************************************************/
int odd(int n)
{
    return (n & 1);
}

/******************************************************************************
 purpose:  returns true if n is even
******************************************************************************/
int even(int n)
{
    return (!(n & 1));
}

/******************************************************************************
 purpose:  count the number of occurences of the string t in the string s
******************************************************************************/
int strstr_count(char *s, char *t)
{
    int n = 0;
    size_t len;
    char *p;

    if (t == NULL || s == NULL)
        return n;

    len = strlen(t);
    p = strstr(s, t);

    while (p) {
        n++;
        p = strstr(p + len - 1, t);
    }

    return n;
}

/******************************************************************************
 purpose:  returns a new string with n characters from s (with '\0' at the end)
******************************************************************************/
char *my_strndup(char *src, size_t n)
{
    char *dst;

    dst = (char *) calloc(n + 1, sizeof(char));
    if (dst == NULL)
        return NULL;

    strncpy(dst, src, n);

    return dst;
}

/******************************************************************************
 purpose:  returns a new string consisting of s+t
******************************************************************************/
char *strdup_together(char *s, char *t)
{
    char *both;

    if (s == NULL) {
        if (t == NULL)
            return NULL;
        return strdup(t);
    }
    if (t == NULL)
        return strdup(s);

    both = malloc(strlen(s) + strlen(t) + 1);
    if (both == NULL)
        diagnostics(ERROR, "Could not allocate memory for both strings.");

    strcpy(both, s);
    strcat(both, t);
    return both;
}

/******************************************************************************
 purpose:  duplicates a string but removes TeX  %comment\n
******************************************************************************/
char *strdup_nocomments(char *s)
{
    char *p, *dup;

    if (s == NULL)
        return NULL;

    dup = malloc(strlen(s) + 1);
    p = dup;

    while (*s) {
        while (*s == '%') {     /* remove comment */
            s++;                /* one char past % */
            while (*s && *s != '\n')
                s++;            /* find end of line */
            if (*s == '\0')
                goto done;
            s++;                /* first char after comment */
        }
        *p = *s;
        p++;
        s++;
    }
  done:
    *p = '\0';
    return dup;
}

/******************************************************************************
 purpose:  duplicates a string without including spaces or newlines
******************************************************************************/
char *strdup_noblanks(char *s)
{
    char *p, *dup;

    if (s == NULL)
        return NULL;
    while (*s == ' ' || *s == '\n')
        s++;                    /* skip to non blank */
    dup = malloc(strlen(s) + 1);
    p = dup;
    while (*s) {
        *p = *s;
        if (*p != ' ' && *p != '\n')
            p++;                /* increment if non-blank */
        s++;
    }
    *p = '\0';
    return dup;
}

/*************************************************************************
purpose: duplicate text with only a..z A..Z 0..9 and _
**************************************************************************/
char *strdup_nobadchars(char *text)
{
    char *dup, *s;

    dup = strdup_noblanks(text);
    s = dup;

    while (*s) {
        if (!('a' <= *s && *s <= 'z') && !('A' <= *s && *s <= 'Z') && !('0' <= *s && *s <= '9'))
            *s = '_';
        s++;
    }

    return dup;
}

/******************************************************************************
 purpose:  duplicates a string without spaces or newlines at front or end
******************************************************************************/
char *strdup_noendblanks(char *s)
{
    char *p, *t;

    if (s == NULL)
        return NULL;
    if (*s == '\0')
        return strdup("");

    t = s;
    while (*t == ' ' || *t == '\n')
        t++;                    /* first non blank char */

    p = s + strlen(s) - 1;
    while (p >= t && (*p == ' ' || *p == '\n'))
        p--;                    /* last non blank char */

    if (t > p)
        return strdup("");
    return my_strndup(t, (size_t) (p - t + 1));
}

/******************************************************************************
  purpose: return a copy of tag from \label{tag} in the string text
 ******************************************************************************/
char *ExtractLabelTag(char *text)
{
    char *s, *label_with_spaces, *label;

    s = strstr(text, "\\label{");
    if (!s)
        s = strstr(text, "\\label ");
    if (!s)
        return NULL;

    s += strlen("\\label");
    PushSource(NULL, s);
    label_with_spaces = getBraceParam();
    PopSource();
    label = strdup_nobadchars(label_with_spaces);
    free(label_with_spaces);

    diagnostics(4, "LabelTag = <%s>", (label) ? label : "missing");
    return label;
}

/******************************************************************************
  purpose: remove 'tag{contents}' from text and return contents
           note that tag should typically be "\\caption"
 ******************************************************************************/
char *ExtractAndRemoveTag(char *tag, char *text)
{
    char *s, *contents, *start, *end;

    s = text;
    diagnostics(5, "target tag = <%s>", tag);
    diagnostics(5, "original text = <%s>", text);

    while (s) {                 /* find start of caption */
        start = strstr(s, tag);
        if (!start)
            return NULL;
        s = start + strlen(tag);
        if (*s == ' ' || *s == '{')
            break;
    }

    PushSource(NULL, s);
    contents = getBraceParam();
    PopSource();

    if (!contents)
        return NULL;

    end = strstr(s, contents) + strlen(contents) + 1;   /* end just after '}' */

    free(contents);
    contents = my_strndup(start, (size_t) (end - start));

    do
        *start++ = *end++;
    while (*end);               /* erase "tag{contents}" */
    *start = '\0';

    diagnostics(5, "final contents = <%s>", contents);
    diagnostics(5, "final text = <%s>", text);

    return contents;
}
