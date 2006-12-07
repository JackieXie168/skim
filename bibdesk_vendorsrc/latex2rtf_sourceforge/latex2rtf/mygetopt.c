
/*
 * my_getopt  is supposed to emulate the C Library getopt (which, according
 * to the man pages, is written by Henry Spencer to emulate the Bell Lab
 * version).
 * 
 * my_getopt is scanning argv[optind] (and, perhaps, following arguments),
 * looking for the first option starting with `-' and a character from
 * optstring[]. Therefore, if you are looking for options in argv[1] etc.,
 * you should initialize optind with 1 (not 0, as the manual erroneously
 * claims).
 * 
 * Experiments with getopt() established that when an argument consists of more
 * than one option, getopt() stores the pointer to the beginning of the
 * argument as a static variable, for re-use later.
 * 
 * See the getopt manual pages for more information on getopt.
 * 
 * Written by V.Menkov, IU, 1995
 */

#include "main.h"
#include <stdlib.h>
#include <string.h>
#include "mygetopt.h"

char *optarg = 0;
int optind = 1;

int my_getopt(int argc, char **argv, char *optstring)
{
    char *q;
    static char *rem = NULL;
    int c;
    int needarg = 0;

    optarg = NULL;

    diagnostics(4, "Processing option `%s'", argv[optind]);

    /* 
     * printf("optind = %d\n", optind);  if (rem) printf("rem=`%s'\n",
     * rem);
     */

    if (!rem) {
        if (optind < argc && argv[optind][0] == '-') {
            rem = argv[optind] + 1;
            if (*rem == 0)
                return EOF;     /* Treat lone "-" as a non-option arg */
            if (*rem == '-') {
                optind++;
                return EOF;
            }                   /* skip "--" and terminate */
        } else
            return EOF;
    }
    c = *rem;
    q = strchr(optstring, c);
    if (q && c != ':') {        /* matched */
        needarg = (q[1] == ':');
        if (needarg) {
            if (rem[1] != 0)
                optarg = rem + 1;
            else {
                optind++;
                if (optind < argc)
                    optarg = argv[optind];
                else {
                    fprintf(stderr, "Missing argument after -%c\n", c);
                    exit(1);
                }
            }
        } else
            rem++;
    } else {
        fprintf(stderr, "%s: illegal option -- %c\n", argv[0], c);
        c = '?';
        rem++;
    }
    if (needarg || *rem == 0) {
        rem = NULL;
        optind++;
    }
    return c;
}
