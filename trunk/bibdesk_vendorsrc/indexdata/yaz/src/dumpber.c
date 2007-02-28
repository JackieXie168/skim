/*
 * Copyright (C) 1995-2007, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: dumpber.c,v 1.5 2007/01/03 08:42:15 adam Exp $
 */

/**
 * \file dumpber.c
 * \brief Implements BER dumping
 */

#if HAVE_CONFIG_H
#include <config.h>
#endif

#include <stdio.h>
#include "odr-priv.h"

static int do_dumpBER(FILE *f, const char *buf, int len, int level, int offset)
{
    int res, ll, zclass, tag, cons, lenlen, taglen;
    const char *b = buf, *bp = buf;
    
    if (!len)
        return 0;
    if (!buf[0] && !buf[1])
        return 0;
    if ((res = ber_dectag((unsigned char*)b, &zclass, &tag, &cons, len)) <= 0)
        return 0;
    if (res > len)
    {
        fprintf(stderr, "Unexpected end of buffer\n");
        return 0;
    }
    fprintf(f, "%5d: %*s", offset, level * 4, "");
    if (zclass == ODR_UNIVERSAL)
    {
        static char *nl[] =
        {
            "[Univ 0]", "BOOLEAN", "INTEGER", "BIT STRING", "OCTET STRING",
            "NULL", "OID", "OBJECT DESCIPTOR", "EXTERNAL", "REAL",
            "ENUM", "[UNIV 11]", "[UNIV 12]", "[UNIV 13]", "[UNIV 14]",
            "[UNIV 15]", "SEQUENCE", "SET", "NUMERICSTRING", "PRINTABLESTRING",
            "[UNIV 20]", "[UNIV 21]", "[UNIV 22]", "[UNIV 23]", "[UNIV 24]",
            "GRAPHICSTRING", "VISIBLESTRING", "GENERALSTRING", "[UNIV 28]"
        };

        if (tag >= 0 && tag < 28)
            fprintf(f, "%s", nl[tag]);
        else
            fprintf(f, "[UNIV %d]", tag);
    }
    else if (zclass == ODR_CONTEXT)
        fprintf(f, "[%d]", tag);
    else
        fprintf(f, "[%d:%d]", zclass, tag);
    b += res;
    taglen = res;
    len -= res;
    bp = b;
    if ((res = ber_declen((unsigned char*)b, &ll, len)) <= 0)
    {
        fprintf(f, "\n%*sBad length\n", level*4+5, "");
        return 0;
    }
    lenlen = res;
    b += res;
    len -= res;
    if (ll >= 0)
        fprintf(f, " len=%d", ll);
    else
        fprintf(f, " len=?");
    fprintf(f, "       tl=%d, ll=%d cons=%d\n", taglen, lenlen, cons);
    if (!cons)
    {
        if (ll < 0 || ll > len)
        {
            fprintf(f, "%*sBad length on primitive type. ll=%d len=%d\n",
                    level*4+5, "", ll, len);
            return 0;
        }
        return ll + (b - buf);
    }
    if (ll >= 0)
    {
        if (ll > len)
        {
            fprintf(f, "%*sBad length of constructed type ll=%d len=%d.\n",
                    level*4+5, "", ll, len);
            return 0;
        }
        len = ll;
    }
    /* constructed - cycle through children */
    while ((ll == -1 && len >= 2) || (ll >= 0 && len))
    {
        if (ll == -1 && *b == 0 && *(b + 1) == 0)
            break;
        if (!(res = do_dumpBER(f, b, len, level + 1, offset + (b - buf))))
        {
            fprintf(f, "%*sDump of content element failed.\n", level*4+5, "");
            return 0;
        }
        b += res;
        len -= res;
        if (len < 0)
        {
            fprintf(f, "%*sBad length\n", level*4+5, "");
            return 0;
        }
    }
    if (ll == -1)
    {
        if (len < 2)
        {
            fprintf(f, "%*sBuffer too short in indefinite length.\n",
                    level*4+5, "");
            return 0;
        }
        return (b - buf) + 2;
    }
    return b - buf;
}

int odr_dumpBER(FILE *f, const char *buf, int len)
{
    return do_dumpBER(f, buf, len, 0, 0);
}
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

