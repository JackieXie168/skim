/* $Id: cql2pqf.c,v 1.9 2007/01/03 08:42:16 adam Exp $
   Copyright (C) 1995-2007, Index Data ApS
   Index Data Aps

This file is part of the YAZ toolkit.

See the file LICENSE.
*/

#include <stdlib.h>
#include <stdio.h>

#include <yaz/cql.h>
#include <yaz/options.h>

static void usage(void)
{
    fprintf (stderr, "usage\n cql2pqf [-n <n>] <properties> [<query>]\n");
    exit (1);
}

int main(int argc, char **argv)
{
    cql_transform_t ct;
    int r = 0;
    int i, iterations = 1;
    CQL_parser cp = cql_parser_create();
    char *query = 0;
    char *fname = 0;

    int ret;
    char *arg;

    while ((ret = options("n:", argv, argc, &arg)) != -2)
    {
        switch (ret)
        {
        case 0:
            if (!fname)
                fname = arg;
            else
                query = arg;
            break;
        case 'n':
            iterations = atoi(arg);
            break;
        default:
            usage();
        }
    }
    if (!fname)
        usage();
    ct = cql_transform_open_fname(fname);
    if (!ct)
    {
        fprintf (stderr, "failed to read properties %s\n", fname);
        exit (1);
    }

    if (query)
    {
        for (i = 0; i<iterations; i++)
            r = cql_parser_string(cp, query);
    }
    else
        r = cql_parser_stdio(cp, stdin);

    if (r)
        fprintf (stderr, "Syntax error\n");
    else
    {
        r = cql_transform_FILE(ct, cql_parser_result(cp), stdout);
        printf("\n");
        if (r)
        {
            const char *addinfo;
            cql_transform_error(ct, &addinfo);
            printf ("Transform error %d %s\n", r, addinfo ? addinfo : "");
        }
        else
        {
            FILE *null = fopen("/dev/null", "w");
            for (i = 1; i<iterations; i++)
                cql_transform_FILE(ct, cql_parser_result(cp), null);
            fclose(null);
        }
    }
    cql_transform_close(ct);
    cql_parser_destroy(cp);
    return 0;
}
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

