/*
 * Copyright (C) 1995-2007, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: ber_any.c,v 1.6 2007/01/03 08:42:15 adam Exp $
 */

/** 
 * \file ber_any.c
 * \brief Implements BER ANY encoding and decoding.
 *
 * This source file implements BER encoding and decoding of
 * the ANY type.
 */

#if HAVE_CONFIG_H
#include <config.h>
#endif

#include <assert.h>
#include "odr-priv.h"

int ber_any(ODR o, Odr_any **p)
{
    int res;
    
    switch (o->direction)
    {
    case ODR_DECODE:
        if ((res = completeBER(o->bp, odr_max(o))) <= 0)        /* FIX THIS */
        {
            odr_seterror(o, OPROTO, 2);
            return 0;
        }
        (*p)->buf = (unsigned char *)odr_malloc(o, res);
        memcpy((*p)->buf, o->bp, res);
        (*p)->len = (*p)->size = res;
        o->bp += res;
        return 1;
    case ODR_ENCODE:
        if (odr_write(o, (*p)->buf, (*p)->len) < 0)
            return 0;
        return 1;
    default: odr_seterror(o, OOTHER, 3); return 0;
    }
}

#define BER_ANY_DEBUG 0

int completeBER_n(const unsigned char *buf, int len, int level)
{
    int res, ll, zclass, tag, cons;
    const unsigned char *b = buf;
    
    if (level > 1000)
    {
#if BER_ANY_DEBUG
        yaz_log(YLOG_LOG, "completeBER lev=%d len=%d", level, len);
#endif
        return -2;
    }
    if (len < 2)
        return 0;
    if (!buf[0] && !buf[1])
        return -2;
    if ((res = ber_dectag(b, &zclass, &tag, &cons, len)) <= 0)
        return 0;
    b += res;
    len -= res;
    assert (len >= 0);
    res = ber_declen(b, &ll, len);
    if (res == -2)
    {
#if BER_ANY_DEBUG
        yaz_log(YLOG_LOG, "<<<<<<<<< return1 lev=%d res=%d", level, res);
#endif
        return -1;  /* error */
    }
    if (res == -1)  
    {
#if BER_ANY_DEBUG
        yaz_log(YLOG_LOG, "<<<<<<<<< return2 lev=%d res=%d", level, res);
#endif
        return 0;    /* incomplete length */
    }
    b += res;
    len -= res;
    if (ll >= 0)
    {   /* definite length */
        if (len < ll)
        {
#if BER_ANY_DEBUG
            yaz_log(YLOG_LOG, "<<<<<<<<< return5 lev=%d len=%d ll=%d",
                    level, len, ll);
#endif
            return 0;
        }
        return ll + (b-buf);
    }
    /* indefinite length */
    if (!cons)
    {   /* if primitive, it's an error */
#if BER_ANY_DEBUG
        yaz_log(YLOG_LOG, "<<<<<<<<< return6 lev=%d ll=%d len=%d res=%d",
                level, ll, len, res);
#endif
        return -1;   /* error */
    }
    /* constructed - cycle through children */
    while (len >= 2)
    {
        if (b[0] == 0 && b[1] == 0)
            break;
        if (!(res = completeBER_n(b, len, level+1)))
            return 0;
        if (res == -1)
            return -1;
        b += res;
        len -= res;
    }
    if (len < 2)
        return 0;
    return (b - buf) + 2;
}

int completeBER(const unsigned char *buf, int len)
{
    int res = completeBER_n(buf, len, 0);
#if BER_ANY_DEBUG
    yaz_log(YLOG_LOG, "completeBER len=%d res=%d", len, res);
#endif
    if (res < 0)
        return len;
    return res;
}
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

