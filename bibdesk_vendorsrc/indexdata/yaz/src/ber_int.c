/*
 * Copyright (C) 1995-2007, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: ber_int.c,v 1.7 2007/01/03 08:42:15 adam Exp $
 */

/** 
 * \file ber_int.c
 * \brief Implements BER INTEGER encoding and decoding.
 *
 * This source file implements BER encoding and decoding of
 * the INTEGER type.
 */

#if HAVE_CONFIG_H
#include <config.h>
#endif

#include <string.h>

#if HAVE_SYS_TYPES_H
#include <sys/types.h>
#endif

#ifdef WIN32
#include <winsock.h>
#else
#include <netinet/in.h>
#endif

#include "odr-priv.h"

static int ber_encinteger(ODR o, int val);
static int ber_decinteger(const unsigned char *buf, int *val, int max);

int ber_integer(ODR o, int *val)
{
    int res;

    switch (o->direction)
    {
    case ODR_DECODE:
        if ((res = ber_decinteger(o->bp, val, odr_max(o))) <= 0)
        {
            odr_seterror(o, OPROTO, 50);
            return 0;
        }
        o->bp += res;
        return 1;
    case ODR_ENCODE:
        if ((res = ber_encinteger(o, *val)) < 0)
            return 0;
        return 1;
    case ODR_PRINT:
        return 1;
    default:
        odr_seterror(o, OOTHER, 51);  return 0;
    }
}

/*
 * Returns: number of bytes written or -1 for error (out of bounds).
 */
int ber_encinteger(ODR o, int val)
{
    int a, len;
    union { int i; unsigned char c[sizeof(int)]; } tmp;

    tmp.i = htonl(val);   /* ensure that that we're big-endian */
    for (a = 0; a < (int) sizeof(int) - 1; a++)  /* skip superfluous octets */
        if (!((tmp.c[a] == 0 && !(tmp.c[a+1] & 0X80)) ||
            (tmp.c[a] == 0XFF && (tmp.c[a+1] & 0X80))))
            break;
    len = sizeof(int) - a;
    if (ber_enclen(o, len, 1, 1) != 1)
        return -1;
    if (odr_write(o, (unsigned char*) tmp.c + a, len) < 0)
        return -1;
    return 0;
}

/*
 * Returns: Number of bytes read or 0 if no match, -1 if error.
 */
int ber_decinteger(const unsigned char *buf, int *val, int max)
{
    const unsigned char *b = buf;
    unsigned char fill;
    int res, len, remains;
    union { int i; unsigned char c[sizeof(int)]; } tmp;

    if ((res = ber_declen(b, &len, max)) < 0)
        return -1;
    if (len+res > max || len < 0) /* out of bounds or indefinite encoding */
        return -1;  
    if (len > (int) sizeof(int))  /* let's be reasonable, here */
        return -1;
    b+= res;

    remains = sizeof(int) - len;
    memcpy(tmp.c + remains, b, len);
    if (*b & 0X80)
        fill = 0XFF;
    else
        fill = 0X00;
    memset(tmp.c, fill, remains);
    *val = ntohl(tmp.i);

    b += len;
    return b - buf;
}
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

