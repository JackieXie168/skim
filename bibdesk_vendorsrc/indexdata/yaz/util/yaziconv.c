/*
 * Copyright (C) 1995-2005, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: yaziconv.c,v 1.5 2006/04/21 10:28:07 adam Exp $
 */

#if HAVE_CONFIG_H
#include <config.h>
#endif

#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <ctype.h>

#include <yaz/yaz-util.h>

#define CHUNK_IN 64
#define CHUNK_OUT 64

void convert (FILE *inf, yaz_iconv_t cd, int verbose)
{
    char inbuf0[CHUNK_IN], *inbuf = inbuf0;
    char outbuf0[CHUNK_OUT], *outbuf = outbuf0;
    size_t inbytesleft = CHUNK_IN;
    size_t outbytesleft = CHUNK_OUT;
    int mustread = 1;

    while (1)
    {
        size_t r;
        if (mustread)
        {
            r = fread (inbuf, 1, inbytesleft, inf);
            if (inbytesleft != r)
            {
                if (ferror(inf))
                {
                    fprintf (stderr, "yaziconv: error reading file\n");
                    exit (6);
                }
                if (r == 0)
                {
                    if (outbuf != outbuf0)
                        fwrite (outbuf0, 1, outbuf - outbuf0, stdout);
                    break;
                }
                inbytesleft = r;
            }
        }
        if (verbose > 1)
        {
            fprintf (stderr, "yaz_iconv: inbytesleft=%ld outbytesleft=%ld\n",
                     (long) inbytesleft, (long) outbytesleft);

        }
        r = yaz_iconv (cd, &inbuf, &inbytesleft, &outbuf, &outbytesleft);
        if (r == (size_t)(-1))
        {
            int e = yaz_iconv_error(cd);
            if (e == YAZ_ICONV_EILSEQ)
            {
                fprintf (stderr, "invalid sequence\n");
                return ;
            }
            else if (e == YAZ_ICONV_EINVAL) /* incomplete input */
            { 
                size_t i;
                for (i = 0; i<inbytesleft; i++)
                    inbuf0[i] = inbuf[i];

                r = fread(inbuf0 + i, 1, CHUNK_IN - i, inf);
                if (r != CHUNK_IN - i)
                {
                    if (ferror(inf))
                    {
                        fprintf (stderr, "yaziconv: error reading file\n");
                        exit(6);
                    }
                }
                if (r == 0)
                {
                    fprintf (stderr, "invalid sequence\n");
                    return ;
                }
                inbytesleft += r;
                inbuf = inbuf0;
                mustread = 0;
            }
            else if (e == YAZ_ICONV_E2BIG) /* no more output space */
            {
                fwrite (outbuf0, 1, outbuf - outbuf0, stdout);
                outbuf = outbuf0;
                outbytesleft = CHUNK_OUT;
                mustread = 0;
            }
            else
            {
                fprintf (stderr, "yaziconv: unknown error\n");
                exit (7);
            }
        }
        else
        {
            inbuf = inbuf0;
            inbytesleft = CHUNK_IN;

            fwrite (outbuf0, 1, outbuf - outbuf0, stdout);
            outbuf = outbuf0;
            outbytesleft = CHUNK_OUT;

            mustread = 1;
        }
    }
}

int main (int argc, char **argv)
{
    int ret;
    int verbose = 0;
    char *from = 0;
    char *to = 0;
    char *arg;
    yaz_iconv_t cd;
    FILE *inf = stdin;

    while ((ret = options ("vf:t:", argv, argc, &arg)) != -2)
    {
        switch (ret)
        {
        case 0:
            inf = fopen (arg, "rb");
            if (!inf)
            {
                fprintf (stderr, "yaziconv: cannot open %s", arg);
                exit (2);
            }
            break;
        case 'f':
            from = arg;
            break;
        case 't':
            to = arg;
            break;
        case 'v':
            verbose++;
            break;
        default:
            fprintf (stderr, "yaziconv: Usage\n"
                     "siconv -f encoding -t encoding [-v] [file]\n");
            exit(1);
        }
    }
    if (!to)
    {
        fprintf (stderr, "yaziconv: -t encoding missing\n");
        exit (3);
    }
    if (!from)
    {
        fprintf (stderr, "yaziconv: -f encoding missing\n");
        exit (4);
    }
    cd = yaz_iconv_open (to, from);
    if (!cd)
    {
        fprintf (stderr, "yaziconv: unsupported encoding\n");
        exit (5);
    }
    else
    {
        if (verbose)
        {
            fprintf (stderr, "yaziconv: using %s\n",
                     yaz_iconv_isbuiltin(cd) ? "YAZ" : "iconv");
        }
    }
    convert (inf, cd, verbose);
    yaz_iconv_close (cd);
    return 0;
}
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

