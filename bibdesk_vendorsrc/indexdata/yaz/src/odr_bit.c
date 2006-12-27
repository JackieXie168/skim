/*
 * Copyright (C) 1995-2005, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: odr_bit.c,v 1.5 2005/06/25 15:46:04 adam Exp $
 */

/**
 * \file odr_bit.c
 * \brief Implements ODR BITSTRING codec
 */

#if HAVE_CONFIG_H
#include <config.h>
#endif

#include <string.h>
#include "odr-priv.h"

/*
 * Top level bitstring string en/decoder.
 * Returns 1 on success, 0 on error.
 */
int odr_bitstring(ODR o, Odr_bitmask **p, int opt, const char *name)
{
    int res, cons = 0;

    if (o->error)
        return 0;
    if (o->t_class < 0)
    {
        o->t_class = ODR_UNIVERSAL;
        o->t_tag = ODR_BITSTRING;
    }
    if ((res = ber_tag(o, p, o->t_class, o->t_tag, &cons, opt, name)) < 0)
        return 0;
    if (!res)
        return odr_missing(o, opt, name);
    if (o->direction == ODR_PRINT)
    {
        odr_prname(o, name);
        odr_printf(o, "BITSTRING(len=%d)\n",(*p)->top + 1);
        return 1;
    }
    if (o->direction == ODR_DECODE)
    {
        *p = (Odr_bitmask *)odr_malloc(o, sizeof(Odr_bitmask));
        memset((*p)->bits, 0, ODR_BITMASK_SIZE);
        (*p)->top = -1;
    }
#if 0
    /* ignoring the cons helps with at least one target. 
     * http://bugzilla.indexdata.dk/cgi-bin/bugzilla/show_bug.cgi?id=24
     */
    return ber_bitstring(o, *p, 0);
#else
    return ber_bitstring(o, *p, cons);
#endif
}
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

