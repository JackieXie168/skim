/*
 * Copyright (C) 1995-2005, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: ber_oct.c,v 1.4 2005/06/25 15:46:03 adam Exp $
 */

/** 
 * \file ber_oct.c
 * \brief Implements ber_octetstring
 *
 * This source file implements BER encoding and decoding of
 * the OCTETSTRING type.
 */

#if HAVE_CONFIG_H
#include <config.h>
#endif

#include "odr-priv.h"

int ber_octetstring(ODR o, Odr_oct *p, int cons)
{
    int res, len;
    const unsigned char *base;
    unsigned char *c;

    switch (o->direction)
    {
    case ODR_DECODE:
        if ((res = ber_declen(o->bp, &len, odr_max(o))) < 0)
        {
            odr_seterror(o, OPROTO, 14);
            return 0;
        }
        o->bp += res;
        if (cons)       /* fetch component strings */
        {
            base = o->bp;
            while (odp_more_chunks(o, base, len))
                if (!odr_octetstring(o, &p, 0, 0))
                    return 0;
            return 1;
        }
        /* primitive octetstring */
        if (len < 0)
        {
            odr_seterror(o, OOTHER, 15);
            return 0;
        }
        if (len > odr_max(o))
        {
            odr_seterror(o, OOTHER, 16);
            return 0;
        }
        if (len + 1 > p->size - p->len)
        {
            c = (unsigned char *)odr_malloc(o, p->size += len + 1);
            if (p->len)
                memcpy(c, p->buf, p->len);
            p->buf = c;
        }
        if (len)
            memcpy(p->buf + p->len, o->bp, len);
        p->len += len;
        o->bp += len;
        /* the final null is really not part of the buffer, but */
        /* it helps somes applications that assumes C strings */
        if (len)
            p->buf[p->len] = '\0';
        return 1;
    case ODR_ENCODE:
        if ((res = ber_enclen(o, p->len, 5, 0)) < 0)
            return 0;
        if (p->len == 0)
            return 1;
        if (odr_write(o, p->buf, p->len) < 0)
            return 0;
        return 1;
    case ODR_PRINT:
        return 1;
    default:
        odr_seterror(o, OOTHER, 17);
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

