/*
 * Copyright (C) 1995-2005, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: odr_seq.c,v 1.5 2005/08/11 14:21:55 adam Exp $
 */
/**
 * \file odr_seq.c
 * \brief Implements ODR SEQUENCE codec
 */
#if HAVE_CONFIG_H
#include <config.h>
#endif

#include "odr-priv.h"

int odr_sequence_begin(ODR o, void *p, int size, const char *name)
{
    char **pp = (char**) p;

    if (o->error)
        return 0;
    if (o->t_class < 0)
    {
        o->t_class = ODR_UNIVERSAL;
        o->t_tag = ODR_SEQUENCE;
    }
    if (o->direction == ODR_DECODE)
        *pp = 0;
    if (odr_constructed_begin(o, p, o->t_class, o->t_tag, name))
    {
        if (o->direction == ODR_DECODE && size)
            *pp = (char *)odr_malloc(o, size);
        return 1;
    }
    else
        return 0;
}

int odr_set_begin(ODR o, void *p, int size, const char *name)
{
    char **pp = (char**) p;

    if (o->error)
        return 0;
    if (o->t_class < 0)
    {
        o->t_class = ODR_UNIVERSAL;
        o->t_tag = ODR_SET;
    }
    if (o->direction == ODR_DECODE)
        *pp = 0;
    if (odr_constructed_begin(o, p, o->t_class, o->t_tag, name))
    {
        if (o->direction == ODR_DECODE && size)
            *pp = (char *)odr_malloc(o, size);
        return 1;
    }
    else
        return 0;
}

int odr_sequence_end(ODR o)
{
    return odr_constructed_end(o);    
}

int odr_set_end(ODR o)
{
    return odr_constructed_end(o);    
}

static int odr_sequence_more(ODR o)
{
    return odr_constructed_more(o);
}

static int odr_sequence_x (ODR o, Odr_fun type, void *p, int *num)
{
    char ***pp = (char***) p;  /* for dereferencing */
    char **tmp = 0;
    int size = 0, i;

    switch (o->direction)
    {
        case ODR_DECODE:
            *num = 0;
            *pp = (char **)odr_nullval();
            while (odr_sequence_more(o))
            {
                /* outgrown array? */
                if (*num * (int) sizeof(void*) >= size)
                {
                    /* double the buffer size */
                    tmp = (char **)odr_malloc(o, sizeof(void*) *
                                              (size += size ? size : 128));
                    if (*num)
                    {
                        memcpy(tmp, *pp, *num * sizeof(void*));
                        /*
                         * For now, we just throw the old *p away, since we use
                         * nibble memory anyway (disgusting, isn't it?).
                         */
                    }
                    *pp = tmp;
                }
                if (!(*type)(o, (*pp) + *num, 0, 0))
                    return 0;
                (*num)++;
            }
            break;
        case ODR_ENCODE: case ODR_PRINT:
            for (i = 0; i < *num; i++)
            {
                if (!(*type)(o, *pp + i, 0, 0))
                    return 0;
            }
            break;
        default:
            odr_seterror(o, OOTHER, 47);
            return 0;
    }
    return odr_sequence_end(o);
}

int odr_set_of(ODR o, Odr_fun type, void *p, int *num, const char *name)
{
    if (!odr_set_begin(o, p, 0, name)) {
        if (o->direction == ODR_DECODE)
            *num = 0;
        return 0;
    }
    return odr_sequence_x (o, type, p, num);
}

int odr_sequence_of(ODR o, Odr_fun type, void *p, int *num,
                    const char *name)
{
    if (!odr_sequence_begin(o, p, 0, name)) {
        if (o->direction == ODR_DECODE)
            *num = 0;
        return 0;
    }
    return odr_sequence_x (o, type, p, num);
}

/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

