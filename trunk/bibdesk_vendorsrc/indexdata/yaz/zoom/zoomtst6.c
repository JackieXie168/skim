/* $Id: zoomtst6.c,v 1.13 2007/01/03 08:42:17 adam Exp $  */

/** \file zoomtst6.c
    \brief Asynchronous multi-target client with two searches
*/

#include <stdio.h>
#include <yaz/nmem.h>
#include <yaz/xmalloc.h>

#include <yaz/zoom.h>

static void display_records (const char *tname, ZOOM_resultset r)
{
    /* OK, no major errors. Look at the result count */
    int pos;
    printf ("%s: %ld hits\n", tname, (long) ZOOM_resultset_size(r));
    /* go through all records at target */
    for (pos = 0; pos < 4; pos++)
    {
        ZOOM_record rec = ZOOM_resultset_record (r, pos);
        if (rec)
        {
            /* get database for record and record itself at pos */
            const char *db = ZOOM_record_get (rec, "database", 0);
            int len;
            const char *render = ZOOM_record_get (rec, "render", &len);
            /* if rec is non-null, we got a record for display */
            if (rec)
            {
                printf ("%d %s\n", pos+1, (db ? db : "unknown"));
                if (render)
                    fwrite (render, 1, len, stdout);
                printf ("\n");
            }
        }
    }
}

int main(int argc, char **argv)
{
    int i;
    int no = argc-3;
    ZOOM_connection z[500];  /* allow at most 500 connections */
    ZOOM_resultset r1[500];  /* and result sets .. */
    ZOOM_resultset r2[500];  /* and result sets .. */
    ZOOM_query q;
    ZOOM_options o;

    o = ZOOM_options_create ();
    if (argc < 4)
    {
        fprintf (stderr, "usage:\n%s target1 .. targetN query1 query2\n",
                 *argv);
        exit (1);
    }
    if (no > 500)
        no = 500;

    ZOOM_options_set (o, "async", "1");

    /* get 3 (at most) records from beginning */
    ZOOM_options_set (o, "count", "3");

    ZOOM_options_set (o, "preferredRecordSyntax", "sutrs");
    ZOOM_options_set (o, "elementSetName", "B");

    /* create query */
    q = ZOOM_query_create ();
    if (ZOOM_query_prefix (q, argv[argc-2]))
    {
        printf ("bad PQF: %s\n", argv[argc-2]);
        exit (2);
    }
    /* connect - and search all */
    for (i = 0; i<no; i++)
    {
        z[i] = ZOOM_connection_create (o);
        ZOOM_connection_connect (z[i], argv[i+1], 0);
        r1[i] = ZOOM_connection_search (z[i], q);
    }
    if (ZOOM_query_prefix (q, argv[argc-1]))
    {
        printf ("bad prefix query: %s\n", argv[argc-1]);
        exit (2);
    }
    /* queue second search */
    for (i = 0; i<no; i++)
        r2[i] = ZOOM_connection_search (z[i], q);

    /* fetch 5th record from first result set as well */
    for (i = 0; i<no; i++)
        ZOOM_resultset_records (r1[i], 0, 4, 1);

    /* network I/O */
    while (ZOOM_event (no, z))
        ;

    /* handle errors */
    for (i = 0; i<no; i++)
    {
        int error;
        const char *errmsg, *addinfo;
        if ((error = ZOOM_connection_error(z[i], &errmsg, &addinfo)))
            fprintf (stderr, "%s error: %s (%d) %s\n",
                     ZOOM_connection_option_get(z[i], "host"),
                     errmsg, error, addinfo);
        else
        {
            display_records (ZOOM_connection_option_get(z[i], "host"), r1[i]);
            display_records (ZOOM_connection_option_get(z[i], "host"), r2[i]);
        }
    }
    /* destroy stuff and exit */
    ZOOM_query_destroy (q);
    for (i = 0; i<no; i++)
    {
        ZOOM_connection_destroy (z[i]);
        ZOOM_resultset_destroy (r1[i]);
        ZOOM_resultset_destroy (r2[i]);
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

