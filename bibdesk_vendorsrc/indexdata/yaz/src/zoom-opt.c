/*
 * Copyright (C) 1995-2005, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: zoom-opt.c,v 1.5 2005/10/17 12:28:20 mike Exp $
 */
/**
 * \file zoom-opt.c
 * \brief Implements ZOOM options handling
 */
#include <assert.h>
#include "zoom-p.h"

#include <yaz/xmalloc.h>

ZOOM_API(ZOOM_options)
ZOOM_options_create_with_parent (ZOOM_options parent)
{
    return ZOOM_options_create_with_parent2(parent, 0);
}

ZOOM_API(ZOOM_options)
ZOOM_options_create (void)
{
    return ZOOM_options_create_with_parent (0);
}


ZOOM_API(ZOOM_options)
ZOOM_options_create_with_parent2 (ZOOM_options parent1, ZOOM_options parent2)
{
    ZOOM_options opt = (ZOOM_options) xmalloc (sizeof(*opt));

    opt->refcount = 1;
    opt->callback_func = 0;
    opt->callback_handle = 0;
    opt->entries = 0;
    opt->parent1= parent1;
    if (parent1)
        (parent1->refcount)++;
    opt->parent2= parent2;
    if (parent2)
        (parent2->refcount)++;
    return opt;
}


void ZOOM_options_addref (ZOOM_options opt)
{
    (opt->refcount)++;
}

ZOOM_API(ZOOM_options_callback)
ZOOM_options_set_callback (
    ZOOM_options opt,
    ZOOM_options_callback callback_func,
    void *callback_handle)
{
    ZOOM_options_callback callback_old;

    assert (opt);
    callback_old = opt->callback_func;
    opt->callback_func = callback_func;
    opt->callback_handle = callback_handle;
    return callback_old;
}

ZOOM_API(void)
ZOOM_options_destroy (ZOOM_options opt)
{
    if (!opt)
        return;
    (opt->refcount)--;
    if (opt->refcount == 0)
    {
        struct ZOOM_options_entry *e;
        
        ZOOM_options_destroy (opt->parent1);
        ZOOM_options_destroy (opt->parent2);
        e = opt->entries;
        while (e)
        {
            struct ZOOM_options_entry *e0 = e;
            xfree (e->name);
            xfree (e->value);
            e = e->next;
            xfree (e0);
        }
        xfree (opt);
    }
}

/* PRIVATE to ZOOM_options_setl() */
static void
_set_value(struct ZOOM_options_entry **e, const char *value, int len)
{
    (*e)->value = 0;
    (*e)->len = 0;
    if (value)
    {
        (*e)->value = (char *) xmalloc (len+1);
        memcpy ((*e)->value, value, len);
        (*e)->value[len] = '\0';
        (*e)->len = len;
    }
}

ZOOM_API(void)
ZOOM_options_setl (ZOOM_options opt, const char *name, const char *value,
                   int len)
{
    struct ZOOM_options_entry **e;

    e = &opt->entries;
    while (*e)
    {
        if (!strcmp((*e)->name, name))
        {
            xfree ((*e)->value);
            _set_value(e, value, len);
            return;
        }
        e = &(*e)->next;
    }
    *e = (struct ZOOM_options_entry *) xmalloc (sizeof(**e));
    (*e)->name = xstrdup (name);
    _set_value(e, value, len);
    (*e)->next = 0;
}

ZOOM_API(void)
ZOOM_options_set (ZOOM_options opt, const char *name, const char *value)
{
    ZOOM_options_setl (opt, name, value, value ? strlen(value): 0);
}

ZOOM_API(const char *)
ZOOM_options_getl (ZOOM_options opt, const char *name, int *lenp)
{
    const char *v = 0;
    if (!opt)
        return 0;
    if (opt->callback_func)
        v = (*opt->callback_func)(opt->callback_handle, name);
    if (!v)
    {
        struct ZOOM_options_entry *e;
        for (e = opt->entries; e; e = e->next)
            if (!strcmp(e->name, name))
            {
                v = e->value;
                *lenp = e->len;
                break;
            }
    }
    if (!v)
        v = ZOOM_options_getl(opt->parent1, name, lenp);
    if (!v)
        v = ZOOM_options_getl(opt->parent2, name, lenp);
    return v;
}

ZOOM_API(const char *)
ZOOM_options_get (ZOOM_options opt, const char *name)
{
    int dummy;
    return ZOOM_options_getl(opt, name, &dummy);
}

ZOOM_API(int)
ZOOM_options_get_bool (ZOOM_options opt, const char *name, int defa)
{
    const char *v = ZOOM_options_get (opt, name);

    if (!v)
        return defa;
    if (!strcmp (v, "1") || !strcmp(v, "T"))
        return 1;
    return 0;
}

ZOOM_API(int)
ZOOM_options_get_int (ZOOM_options opt, const char *name, int defa)
{
    const char *v = ZOOM_options_get (opt, name);

    if (!v || !*v)
        return defa;
    return atoi(v);
}

ZOOM_API(void)
ZOOM_options_set_int(ZOOM_options opt, const char *name, int value)
{
    char s[40];

    sprintf (s, "%d", value);
    ZOOM_options_set (opt, name, s);
}
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

