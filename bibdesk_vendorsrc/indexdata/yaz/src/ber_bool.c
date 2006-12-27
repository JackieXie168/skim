/*
 * Copyright (C) 1995-2005, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: ber_bool.c,v 1.5 2005/08/11 14:21:55 adam Exp $
 */

/** 
 * \file ber_bool.c
 * \brief Implements BER BOOLEAN encoding and decoding
 *
 * This source file implements BER encoding and decoding of
 * the BOOLEAN type.
 */

#if HAVE_CONFIG_H
#include <config.h>
#endif

#include <stdio.h>
#include "odr-priv.h"

int ber_boolean(ODR o, int *val)
{
    int res, len;

    switch (o->direction)
    {
    case ODR_ENCODE:
        if (ber_enclen(o, 1, 1, 1) != 1)
            return 0;
        if (odr_putc(o, *val) < 0)
            return 0;
        return 1;
    case ODR_DECODE:
        if ((res = ber_declen(o->bp, &len, odr_max(o))) < 0)
        {
            odr_seterror(o, OPROTO, 9);
            return 0;
        }
        o->bp+= res;
        if (len != 1 || odr_max(o) < len)
        {
            odr_seterror(o, OPROTO, 10);
            return 0;
        }
        *val = *o->bp;
        o->bp++;
        return 1;
    case ODR_PRINT:
        return 1;
    default: odr_seterror(o, OOTHER, 11); return 0;
    }
}
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

