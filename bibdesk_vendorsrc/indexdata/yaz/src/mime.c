/*
 * Copyright (C) 1995-2007, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: mime.c,v 1.3 2007/01/03 08:42:15 adam Exp $
 */

/** \file mime.c
    \brief Small utility to manage MIME types
*/

#if HAVE_CONFIG_H
#include <config.h>
#endif

#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <yaz/xmalloc.h>

#include "mime.h"

struct yaz_mime_entry {
    char *suffix;
    char *mime_type;
    struct yaz_mime_entry *next;
};

struct yaz_mime_info {
    struct yaz_mime_entry *table;
};

yaz_mime_types yaz_mime_types_create()
{
    yaz_mime_types p = xmalloc(sizeof(*p));
    p->table = 0;
    return p;
}

void yaz_mime_types_add(yaz_mime_types t, const char *suffix,
                        const char *mime_type)
{
    struct yaz_mime_entry *e = xmalloc(sizeof(*e));
    e->mime_type  = xstrdup(mime_type);
    e->suffix = xstrdup(suffix);
    e->next = t->table;
    t->table = e;
}

const char *yaz_mime_lookup_suffix(yaz_mime_types t, const char *suffix)
{
    struct yaz_mime_entry *e = t->table;
    for (; e; e = e->next)
    {
        if (!strcmp(e->suffix, suffix))
            return e->mime_type;
    }
    return 0;
}

const char *yaz_mime_lookup_fname(yaz_mime_types t, const char *fname)
{
    const char *cp = strrchr(fname, '.');
    if (!cp) /* if no . return now */
        return 0;
    return yaz_mime_lookup_suffix(t, cp+1);  /* skip . */
}

void yaz_mime_types_destroy(yaz_mime_types t)
{
    struct yaz_mime_entry *e = t->table;
    while (e)
    {
        struct yaz_mime_entry *e_next = e->next;
        xfree(e->suffix);
        xfree(e->mime_type);
        xfree(e);
        e = e_next;
    }
    xfree(t);
}

/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

