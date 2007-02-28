/*
 * Copyright (C) 1995-2007, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: odr_int.c,v 1.6 2007/01/03 08:42:15 adam Exp $
 */
/**
 * \file odr_int.c
 * \brief Implements ODR INTEGER codec
 */
#if HAVE_CONFIG_H
#include <config.h>
#endif

#include "odr-priv.h"

/*
 * Top level integer en/decoder.
 * Returns 1 on success, 0 on error.
 */
int odr_integer(ODR o, int **p, int opt, const char *name)
{
    int res, cons = 0;

    if (o->error)
        return 0;
    if (o->t_class < 0)
    {
        o->t_class = ODR_UNIVERSAL;
        o->t_tag = ODR_INTEGER;
    }
    if ((res = ber_tag(o, p, o->t_class, o->t_tag, &cons, opt, name)) < 0)
        return 0;
    if (!res)
        return odr_missing(o, opt, name);
    if (o->direction == ODR_PRINT)
    {
        odr_prname(o, name);
        odr_printf(o, "%d\n", **p);
        return 1;
    }
    if (cons)
    {
        odr_seterror(o, OPROTO, 1);
        return 0;
    }
    if (o->direction == ODR_DECODE)
        *p = (int *)odr_malloc(o, sizeof(int));
    return ber_integer(o, *p);
}
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

