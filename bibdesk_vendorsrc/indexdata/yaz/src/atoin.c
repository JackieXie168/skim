/*
 * Copyright (C) 1995-2007, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: atoin.c,v 1.8 2007/01/03 08:42:15 adam Exp $
 */

/** 
 * \file atoin.c
 * \brief Implements atoi_n function.
 */

#if HAVE_CONFIG_H
#include <config.h>
#endif

#include <string.h>
#include <ctype.h>
#include <yaz/marcdisp.h>

/**
 * atoi_n: like atoi but reads at most len characters.
 */
int atoi_n (const char *buf, int len)
{
    int val = 0;

    while (--len >= 0)
    {
        if (isdigit (*(const unsigned char *) buf))
            val = val*10 + (*buf - '0');
        buf++;
    }
    return val;
}

/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

