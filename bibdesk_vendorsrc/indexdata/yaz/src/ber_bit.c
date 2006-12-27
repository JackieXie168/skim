/*
 * Copyright (C) 1995-2005, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: ber_bit.c,v 1.4 2005/06/25 15:46:03 adam Exp $
 */

/** 
 * \file ber_bit.c
 * \brief Implements BER BITSTRING encoding and decoding.
 *
 * This source file implements BER encoding and decoding of
 * the BITSTRING type.
 */

#if HAVE_CONFIG_H
#include <config.h>
#endif

#include "odr-priv.h"

int ber_bitstring(ODR o, Odr_bitmask *p, int cons)
{
    int res, len;
    const unsigned char *base;

    switch (o->direction)
    {
    case ODR_DECODE:
        if ((res = ber_declen(o->bp, &len, odr_max(o))) < 0)
        {
            odr_seterror(o, OPROTO, 4);
            return 0;
        }
        o->bp += res;
        if (cons)       /* fetch component strings */
        {
            base = o->bp;
            while (odp_more_chunks(o, base, len))
                if (!odr_bitstring(o, &p, 0, 0))
                    return 0;
            return 1;
        }
        /* primitive bitstring */
        if (len < 0)
        {
            odr_seterror(o, OOTHER, 5);
            return 0;
        }
        if (len == 0)
            return 1;
        if (len - 1 > ODR_BITMASK_SIZE)
        {
            odr_seterror(o, OOTHER, 6);
            return 0;
        }
        if (len > odr_max(o))
        {
            odr_seterror(o, OOTHER, 7);
            return 0;
        }
        o->bp++;      /* silently ignore the unused-bits field */
        len--;
        memcpy(p->bits + p->top + 1, o->bp, len);
        p->top += len;
        o->bp += len;
        return 1;
    case ODR_ENCODE:
        if ((res = ber_enclen(o, p->top + 2, 5, 0)) < 0)
            return 0;
        if (odr_putc(o, 0) < 0)    /* no unused bits here */
            return 0;
        if (p->top < 0)
            return 1;
        if (odr_write(o, p->bits, p->top + 1) < 0)
            return 0;
        return 1;
    case ODR_PRINT:
        return 1;
    default: 
        odr_seterror(o, OOTHER, 8);
        return 0;
    }
}
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

