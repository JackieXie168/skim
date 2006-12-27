/*
 * Copyright (C) 1995-2006, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: matchstr.c,v 1.6 2006/10/24 08:07:02 adam Exp $
 */

/**
 * \file matchstr.c
 * \brief Implements loose string matching 
 */

#if HAVE_CONFIG_H
#include <config.h>
#endif

#include <stdio.h>
#include <assert.h>
#include <ctype.h>
#include <string.h>
#include <yaz/yaz-util.h>

int yaz_matchstr(const char *s1, const char *s2)
{
    while (*s1 && *s2)
    {
        unsigned char c1 = *s1;
        unsigned char c2 = *s2;

        if (c2 == '?')
            return 0;
        if (c1 == '-')
            c1 = *++s1;
        if (c2 == '-')
            c2 = *++s2;
        if (!c1 || !c2)
            break;
        if (c2 != '.')
        {
            if (isupper(c1))
                c1 = tolower(c1);
            if (isupper(c2))
                c2 = tolower(c2);
            if (c1 != c2)
                break;
        }
        s1++;
        s2++;
    }
    return *s1 || *s2;
}

int yaz_strcmp_del(const char *a, const char *b, const char *b_del)
{
    while (*a && *b)
    {
        if (*a != *b)
            return *a - *b;
        a++;
        b++;
    }
    if (b_del && strchr(b_del, *b))
        return *a;
    return *a - *b;
}

#ifdef __GNUC__
#ifdef __CHECKER__
void __assert_fail (const char *assertion, const char *file, 
                    unsigned int line, const char *function)
{
    fprintf (stderr, "%s in file %s line %d func %s\n",
             assertion, file, line, function);
    abort ();
}
#endif
#endif
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

