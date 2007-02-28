/* $Id: benchmark.c,v 1.10 2007/01/03 08:42:16 adam Exp $
 * Copyright (C) 1995-2007, Index Data ApS
 *
 * This file is part of the YAZ toolkit.
 *
 * See the file LICENSE.
 *
 * This is an elementary benchmarker for server performance.  It works
 * by repeatedly connecting to, seaching in and retrieving from the
 * specified server, and keeps statistics about the minimum, maximum
 * and average times for each operation.
 */

#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <yaz/options.h>
#include <stdarg.h>

#include <yaz/zoom.h>


struct boptions {
    int nconnect;               /* number of connections to make */
    int nsearch;                /* number of searches on each connection */
    int npresent;               /* number of presents for each search */
    int full;                   /* 1 = fetch full records, 0 = brief */
    int delay;                  /* number of ms to delay between ops */
    int random;                 /* if true, delay is random 0-specified */
    int verbosity;              /* 0 = quiet, higher => more verbose */
} boptions = {
    3,
    3,
    3,
    0,
    1000,
    1,
    0,
};


static int test(char *host, int port);
static void db_printf(int level, char *fmt, ...);
static void usage(const char *prog);

int main(int argc, char **argv)
{
    char *host = 0;
    int port = 0;
    int c;
    int i;
    int ok;
    int nok = 0;
    char *arg;
    
    while ((c = options("c:s:p:fbd:rv:", argv, argc, &arg)) != -2) {
        switch (c) {
        case 0:
            if (!host)
                host = arg;
            else if (!port)
                port = atoi(arg);
            else
                usage(*argv);
            break;
        case 'c': boptions.nconnect = atoi(arg); break;
        case 's': boptions.nsearch = atoi(arg); break;
        case 'p': boptions.npresent = atoi(arg); break;
        case 'f': boptions.full = 1; break;
        case 'b': boptions.full = 0; break;
        case 'd': boptions.delay = atoi(arg); break;
        case 'r': boptions.random = 1; break;
        case 'v': boptions.verbosity = atoi(arg); break;
        default: usage(*argv);
        }
    }

    if (!host || !port)
        usage(*argv);

    for (i = 0; i < boptions.nconnect; i++) {
        db_printf(2, "iteration %d of %d", i+1, boptions.nconnect);
        ok = test(host, port);
        if (ok) nok++;
    }

    db_printf(1, "passed %d of %d tests", nok, boptions.nconnect);
    if (nok < boptions.nconnect)
        printf("Failed %d of %d tests\n",
               boptions.nconnect-nok, boptions.nconnect);

    return 0;
}

static void usage(const char *prog)
{
    fprintf(stderr, "Usage: %s [options] <host> <port>\n"
"       -c <n>  Make <n> connection to the server [default: 3]\n"
"       -s <n>  Perform <n> searches on each connection [3]\n"
"       -p <n>  Make <n> present requests after each search [3]\n"
"       -f      Fetch full records [default: brief]\n"
"       -b      Fetch brief records\n"
"       -d <n>  Delay <n> ms after each operation\n"
"       -r      Delays are random between 0 and the specified number of ms\n"
"       -v <n>  Set verbosity level to <n> [0, silent on success]\n"
            , prog);
    exit(1);
}

static int test(char *host, int port)
{
    ZOOM_connection conn;
    int error;
    const char *errmsg, *addinfo;

    conn = ZOOM_connection_new(host, port);
    if ((error = ZOOM_connection_error(conn, &errmsg, &addinfo))) {
        fprintf(stderr, "ZOOM error: %s (%d): %s\n", errmsg, error, addinfo);
        return 0;
    }

    ZOOM_connection_destroy(conn);
    return 1;
}

static void db_printf(int level, char *fmt, ...)
{
    va_list ap;

    if (level > boptions.verbosity)
        return;

    fprintf(stderr, "DEBUG(%d): ", level);
    va_start(ap, fmt);
    vfprintf(stderr, fmt, ap);
    fputc('\n', stderr);
    va_end(ap);
}
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

