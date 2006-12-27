/*
 * Copyright (C) 1995-2005, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: ber_tag.c,v 1.6 2005/08/11 14:21:55 adam Exp $
 */

/** 
 * \file ber_tag.c
 * \brief Implements BER tags encoding and decoding
 *
 * This source file implements BER encoding and decoding of
 * the tags.
 */
#if HAVE_CONFIG_H
#include <config.h>
#endif

#include <stdio.h>
#include "odr-priv.h"

/**
 * \brief Encode/decode BER tags
 *
 * On encoding:
 * \verbatim
 *      if  p: write tag. return 1 (success) or -1 (error).
 *      if !p: return 0.
 * \endverbatim
 * On decoding:
 * \verbatim
 *      if tag && zclass match up, advance pointer and return 1. set cons.
 *      else leave pointer unchanged. Return 0.
 * \endverbatim
 */
int ber_tag(ODR o, void *p, int zclass, int tag, int *constructed, int opt,
            const char *name)
{
    struct Odr_ber_tag *odr_ber_tag = &o->op->odr_ber_tag;
    int rd;
    char **pp = (char **)p;

    if (o->direction == ODR_DECODE)
        *pp = 0;
    o->t_class = -1;
    if (ODR_STACK_EMPTY(o))
    {
        odr_seek(o, ODR_S_SET, 0);
        o->top = 0;
        o->bp = o->buf;
        odr_ber_tag->lclass = -1;
    }
    switch (o->direction)
    {
    case ODR_ENCODE:
        if (!*pp)
        {
            if (!opt)
            {
                odr_seterror(o, OREQUIRED, 24);
                odr_setelement (o, name);
            }
            return 0;
        }
        if ((rd = ber_enctag(o, zclass, tag, *constructed)) < 0)
            return -1;
        return 1;
    case ODR_DECODE:
        if (ODR_STACK_NOT_EMPTY(o) && !odr_constructed_more(o))
        {
            if (!opt)
            {
                odr_seterror(o, OREQUIRED, 25);
                odr_setelement(o, name);
            }
            return 0;
        }
        if (odr_ber_tag->lclass < 0)
        {
            if ((odr_ber_tag->br =
                 ber_dectag(o->bp, &odr_ber_tag->lclass,
                            &odr_ber_tag->ltag, &odr_ber_tag->lcons,
                            odr_max(o))) <= 0)
            {
                odr_seterror(o, OPROTO, 26);
                odr_setelement(o, name);
                return 0;
            }
        }
        if (zclass == odr_ber_tag->lclass && tag == odr_ber_tag->ltag)
        {
            o->bp += odr_ber_tag->br;
            *constructed = odr_ber_tag->lcons;
            odr_ber_tag->lclass = -1;
            return 1;
        }
        else
        {
            if (!opt)
            {
                odr_seterror(o, OREQUIRED, 27);
                odr_setelement(o, name);
            }
            return 0;
        }
    case ODR_PRINT:
        if (!*pp && !opt)
        {
            odr_seterror(o,OREQUIRED, 28);
            odr_setelement(o, name);
        }
        return *pp != 0;
    default:
        odr_seterror(o, OOTHER, 29);
        odr_setelement(o, name);
        return 0;
    }
}

/**
 * \brief BER-encode a zclass/tag/constructed package (identifier octets).
 *
 * Return number of bytes encoded, or -1 if out of bounds.
 */
int ber_enctag(ODR o, int zclass, int tag, int constructed)
{
    int cons = (constructed ? 1 : 0), n = 0;
    unsigned char octs[sizeof(int)], b;

    b = (zclass << 6) & 0XC0;
    b |= (cons << 5) & 0X20;
    if (tag <= 30)
    {
        b |= tag & 0X1F;
        if (odr_putc(o, b) < 0)
            return -1;
        return 1;
    }
    else
    {
        b |= 0X1F;
        if (odr_putc(o, b) < 0)
            return -1;
        do
        {
            octs[n++] = tag & 0X7F;
            tag >>= 7;
        }
        while (tag);
        while (n--)
        {
            unsigned char oo;

            oo = octs[n] | ((n > 0) << 7);
            if (odr_putc(o, oo) < 0)
                return -1;
        }
        return 0;
    }
}

/** 
 * \brief Decodes BER identifier octets.
 *
 * Returns number of bytes read or -1 for error.
 */
int ber_dectag(const unsigned char *b, int *zclass, int *tag,
               int *constructed, int max)
{
    int l = 1;

    if (l > max)
        return -1;

    *zclass = *b >> 6;
    *constructed = (*b >> 5) & 0X01;
    if ((*tag = *b & 0x1F) <= 30)
        return 1;
    *tag = 0;
    do
    {
        if (l >= max)
            return -1;
        *tag <<= 7;
        *tag |= b[l] & 0X7F;
    }
    while (b[l++] & 0X80);
    return l;
}
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

