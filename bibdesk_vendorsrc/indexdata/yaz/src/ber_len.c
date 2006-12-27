/*
 * Copyright (C) 1995-2005, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: ber_len.c,v 1.5 2005/08/11 14:21:55 adam Exp $
 */

/** 
 * \file ber_len.c
 * \brief Implements BER length octet encoding and decoding
 *
 * This source file implements BER encoding and decoding of
 * the length octets.
 */

#if HAVE_CONFIG_H
#include <config.h>
#endif

#include <stdio.h>
#include "odr-priv.h"

/**
 * ber_enclen:
 * Encode BER length octets. If exact, lenlen is the exact desired
 * encoding size, else, lenlen is the max available space. Len < 0 =
 * Indefinite encoding.
 * Returns: >0   success, number of bytes encoded.
 * Returns: =0   success, indefinite start-marker set. 1 byte encoded.
 * Returns: -1   failure, out of bounds.
 */
int ber_enclen(ODR o, int len, int lenlen, int exact)
{
    unsigned char octs[sizeof(int)];
    int n = 0;
    int lenpos, end;

    if (len < 0)      /* Indefinite */
    {
        if (odr_putc(o, 0x80) < 0)
            return 0;
        return 0;
    }
    if (len <= 127 && (lenlen == 1 || !exact)) /* definite short form */
    {
        if (odr_putc(o, (unsigned char) len) < 0)
            return 0;
        return 1;
    }
    if (lenlen == 1)
    {
        if (odr_putc(o, 0x80) < 0)
            return 0;
        return 0;
    }
    /* definite long form */
    do
    {
        octs[n++] = len;
        len >>= 8;
    }
    while (len);
    if (n >= lenlen)
        return -1;
    lenpos = odr_tell(o); /* remember length-of-length position */
    if (odr_putc(o, 0) < 0)  /* dummy */
        return 0;
    if (exact)
        while (n < --lenlen)        /* pad length octets */
            if (odr_putc(o, 0) < 0)
                return 0;
    while (n--)
        if (odr_putc(o, octs[n]) < 0)
            return 0;
    /* set length of length */
    end = odr_tell(o);
    odr_seek(o, ODR_S_SET, lenpos);
    if (odr_putc(o, (end - lenpos - 1) | 0X80) < 0)
        return 0;
    odr_seek(o, ODR_S_END, 0);
    return odr_tell(o) - lenpos;
}

/**
 * ber_declen:
 * Decode BER length octets. Returns 
 *  > 0  : number of bytes read 
 *   -1  : not enough room to read bytes within max bytes
 *   -2  : other error
 *
 * After return:
 * len = -1   indefinite length.
 * len >= 0   definite length
 */
int ber_declen(const unsigned char *buf, int *len, int max)
{
    const unsigned char *b = buf;
    int n;

    if (max < 1)
        return -1;
    if (*b == 0X80)     /* Indefinite */
    {
        *len = -1;
        return 1;
    }
    if (!(*b & 0X80))   /* Definite short form */
    {
        *len = (int) *b;
        return 1;
    }
    if (*b == 0XFF)     /* reserved value */
        return -2;
    /* indefinite long form */ 
    n = *b & 0X7F;
    if (n >= max)
        return -1;
    *len = 0;
    b++;
    while (--n >= 0)
    {
        *len <<= 8;
        *len |= *(b++);
    }
    if (*len < 0)
        return -2;
    return (b - buf);
}
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

