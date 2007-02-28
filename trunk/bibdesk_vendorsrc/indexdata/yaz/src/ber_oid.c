/*
 * Copyright (C) 1995-2007, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: ber_oid.c,v 1.9 2007/01/03 08:42:15 adam Exp $
 */

/** 
 * \file ber_oid.c
 * \brief Implements BER OID encoding and decoding
 *
 * This source file implements BER encoding and decoding of
 * the OID type.
 */
#if HAVE_CONFIG_H
#include <config.h>
#endif

#include "odr-priv.h"

int ber_oidc(ODR o, Odr_oid *p, int max_oid_size)
{
    int len, lenp, end;
    int pos, n, res, id;
    unsigned char octs[8];

    switch (o->direction)
    {
    case ODR_DECODE:
        if ((res = ber_declen(o->bp, &len, odr_max(o))) < 1)
        {
            odr_seterror(o, OPROTO, 18);
            return 0;
        }
        if (len < 0)
        {
            odr_seterror(o, OPROTO, 19);
            return 0;
        }
        o->bp += res;
        if (len > odr_max(o))
        {
            odr_seterror(o, OPROTO, 20);
            return 0;
        }
        pos = 0;
        while (len)
        {
            int id = 0;
            do
            {
                if (!len)
                {
                    odr_seterror(o, OPROTO, 21);
                    return 0;
                }
                id <<= 7;
                id |= *o->bp & 0X7F;
                len--;
            }
            while (*(o->bp++) & 0X80);

            if (id < 0)
            {
                odr_seterror(o, ODATA, 23);
                return 0;
            }
            if (pos > 0)
                p[pos++] = id;
            else
            {
                p[0] = id / 40;
                if (p[0] > 2)
                    p[0] = 2;
                p[1] = id - p[0] * 40;
                pos = 2;
            }
            if (pos >= max_oid_size)
            {
                odr_seterror(o, OPROTO, 55);
                return 0;
            }
        }
        if (pos < 2 || p[0] < 0 || p[1] < 0)
        {
            odr_seterror(o, ODATA, 23);
            return 0;
        }
        p[pos] = -1;
        return 1;
    case ODR_ENCODE:
        /* we'll allow ourselves the quiet luxury of only doing encodings
           shorter than 127 */
        lenp = odr_tell(o);
        if (odr_putc(o, 0) < 0)   /* dummy */
            return 0;
        if (p[0] < 0 || p[1] < 0)
        {
            odr_seterror(o, ODATA, 23);
            return 0;
        }
        for (pos = 1; p[pos] != -1; pos++)
        {
            n = 0;
            if (pos == 1)
                id = p[0]*40 + p[1];
            else 
                id = p[pos];
            do
            {
                octs[n++] = id & 0X7F;
                id >>= 7;
            }
            while (id);
            while (n--)
            {
                unsigned char p;

                p = octs[n] | ((n > 0) << 7);
                if (odr_putc(o, p) < 0)
                    return 0;
            }
        }
        end = odr_tell(o);
        odr_seek(o, ODR_S_SET, lenp);
        if (ber_enclen(o, (end - lenp) - 1, 1, 1) != 1)
        {
            odr_seterror(o, OOTHER, 52);
            return 0;
        }
        odr_seek(o, ODR_S_END, 0);
        return 1;
    default: 
        odr_seterror(o, OOTHER, 22);
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

