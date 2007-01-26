/* $Id: zoomtst3.c,v 1.13 2007/01/10 13:25:46 adam Exp $  */

/** \file zoomtst3.c
    \brief Asynchronous multi-target client
    
    Performs search and piggyback retrieval of records
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#include <yaz/xmalloc.h>

#include <yaz/zoom.h>

int main(int argc, char **argv)
{
    int i;
    int same_target = 0;
    int no = argc-2;
    ZOOM_connection z[500]; /* allow at most 500 connections */
    ZOOM_resultset r[500];  /* and result sets .. */
    ZOOM_options o = ZOOM_options_create ();

    if (argc < 3)
    {
        fprintf (stderr, "usage:\n%s target1 target2 ... targetN query\n"
                         "%s number target query\n", *argv, *argv);
        exit (1);
    }
    if (argc == 4 && isdigit(argv[1][0]) && !strchr(argv[1],'.'))
    {
        no = atoi(argv[1]);
        same_target = 1;
    }

    if (no > 500)
        no = 500;

    /* async mode */
    ZOOM_options_set (o, "async", "1");

    /* get first 10 records of result set (using piggyback) */
    ZOOM_options_set (o, "count", "10");

    /* preferred record syntax */
    ZOOM_options_set (o, "preferredRecordSyntax", "usmarc");
    ZOOM_options_set (o, "elementSetName", "F");

    /* connect to all */
    for (i = 0; i<no; i++)
    {
        /* create connection - pass options (they are the same for all) */
        z[i] = ZOOM_connection_create (o);

        /* connect and init */
        if (same_target)
            ZOOM_connection_connect (z[i], argv[2], 0);
        else
            ZOOM_connection_connect (z[i], argv[1+i], 0);
    }
    /* search all */
    for (i = 0; i<no; i++)
        r[i] = ZOOM_connection_search_pqf (z[i], argv[argc-1]);

    /* network I/O. pass number of connections and array of connections */
    while ((i = ZOOM_event (no, z)))
    {
        int peek = ZOOM_connection_peek_event(z[i-1]);
        printf ("no = %d peek = %d event = %d\n", i-1,
                peek,
                ZOOM_connection_last_event(z[i-1]));
    }
    
    /* no more to be done. Inspect results */
    for (i = 0; i<no; i++)
    {
        int error;
        const char *errmsg, *addinfo;
        const char *tname = (same_target ? argv[2] : argv[1+i]);
        /* display errors if any */
        if ((error = ZOOM_connection_error(z[i], &errmsg, &addinfo)))
            fprintf (stderr, "%s error: %s (%d) %s\n", tname, errmsg,
                     error, addinfo);
        else
        {
            /* OK, no major errors. Look at the result count */
            int pos;
            printf ("%s: %ld hits\n", tname, (long) ZOOM_resultset_size(r[i]));
            /* go through all records at target */
            for (pos = 0; pos < 10; pos++)
            {
                int len; /* length of buffer rec */
                const char *rec =
                    ZOOM_record_get (
                        ZOOM_resultset_record (r[i], pos), "render", &len);
                /* if rec is non-null, we got a record for display */
                if (rec)
                {
                    printf ("%d\n", pos+1);
                    if (rec)
                        fwrite (rec, 1, len, stdout);
                    printf ("\n");
                }
            }
        }
    }
    /* destroy and exit */
    for (i = 0; i<no; i++)
    {
        ZOOM_resultset_destroy (r[i]);
        ZOOM_connection_destroy (z[i]);
    }
    ZOOM_options_destroy(o);
    exit (0);
}
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

