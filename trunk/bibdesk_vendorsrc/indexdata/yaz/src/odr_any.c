/*
 * Copyright (C) 1995-2007, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: odr_any.c,v 1.6 2007/01/03 08:42:15 adam Exp $
 */

/**
 * \file odr_any.c
 * \brief Implements ODR ANY codec
 */

#if HAVE_CONFIG_H
#include <config.h>
#endif

#include "odr-priv.h"

/**
 * This is a catch-all type. It stuffs a random ostring (assumed to be properly
 * encoded) into the stream, or reads a full data element. Implicit tagging
 * does not work, and neither does the optional flag, unless the element
 * is the last in a sequence.
 */
int odr_any(ODR o, Odr_any **p, int opt, const char *name)
{
    if (o->error)
        return 0;
    if (o->direction == ODR_PRINT)
    {
        odr_prname(o, name);
        odr_printf(o, "ANY (len=%d)\n", (*p)->len);
        return 1;
    }
    if (o->direction == ODR_DECODE)
        *p = (Odr_oct *)odr_malloc(o, sizeof(**p));
    if (ber_any(o, p))
        return 1;
    *p = 0;
    return odr_missing(o, opt, name);
}
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

