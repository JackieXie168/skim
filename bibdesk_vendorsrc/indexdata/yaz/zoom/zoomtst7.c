/* $Id: zoomtst7.c,v 1.16 2007/01/03 08:42:17 adam Exp $  */

/** \file zoomtst7.c
    \brief Mix of operations
*/

#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

#include <yaz/xmalloc.h>
#include <yaz/nmem.h>
#include <yaz/log.h>
#include <yaz/zoom.h>

int main(int argc, char **argv)
{
    int block;
    int i, j;
    ZOOM_connection z;
    ZOOM_resultset r[10];  /* and result sets .. */
    ZOOM_options o;

    nmem_init ();
    o = ZOOM_options_create ();

    z = ZOOM_connection_new ("localhost", 9999);
    if (ZOOM_connection_error (z, 0, 0))
    {
        printf ("error - couldn't connect?\n");
        exit (1);
    }
        
    ZOOM_connection_destroy (z);

    for (block = 0; block < 3; block++)
    {
        switch (block)
        {
        case 0:
            printf ("blocking - not calling ZOOM_events\n");
            break;
        case 1:
            printf ("blocking - calling ZOOM_events\n");
            break;
        case 2:
            printf ("non-blocking - calling ZOOM_events\n");
            break;
        }
        if (block > 1)
            ZOOM_options_set (o, "async", "1");
        for (i = 0; i<10; i++)
        {
            char host[40];

            printf ("session %2d", i);
            sprintf (host, "localhost:9999/%d", i);
            z = ZOOM_connection_create (o);
            ZOOM_connection_connect (z, host, 0);
            
            for (j = 0; j < 10; j++)
            {
                ZOOM_record recs[2];
                char query[40];
                ZOOM_query s = ZOOM_query_create ();
                
                sprintf (query, "i%dr%d", i, j);
                
                if (ZOOM_query_prefix (s, query))
                {
                    printf ("bad PQF: %s\n", query);
                    exit (2);
                }
                ZOOM_options_set (o, "start", "0");
                ZOOM_options_set (o, "count", "0");
                
                r[j] = ZOOM_connection_search (z, s); /* non-piggy */
                
                ZOOM_resultset_records (r[j], recs, 0, 2);  /* first two */
                
                ZOOM_resultset_records (r[j], recs, 1, 2);  /* third */

                ZOOM_resultset_records (r[j], recs, 0, 0);  /* ignored */

                if (ZOOM_resultset_size (r[j]) > 2)
                {
                    if (!recs[0])
                    {
                        fprintf (stderr, "\nrecord missing\n");
                        exit (1);
                    }
                }
                
                ZOOM_query_destroy (s);

                printf (".");
                if (block > 0)
                    while (ZOOM_event (1, &z))
                        ;
            }
            for (j = 0; j<i; j++)
                ZOOM_resultset_destroy (r[j]);
            ZOOM_connection_destroy (z);
            for (; j < 10; j++)
                ZOOM_resultset_destroy (r[j]);
            printf ("10 searches, 20 presents done\n");

        }

        for (i = 0; i<1; i++)
        {
            ZOOM_query q = ZOOM_query_create ();
            char host[40];

            printf ("session %2d", i+10);
            sprintf (host, "localhost:9999/%d", i);
            z = ZOOM_connection_create (o);
            ZOOM_connection_connect (z, host, 0);
            
            for (j = 0; j < 10; j++)
            {
                char query[40];
                
                sprintf (query, "i%dr%d", i, j);
                
                ZOOM_options_set (o, "count", "0");
                
                r[j] = ZOOM_connection_search_pqf (z, query);

                printf (".");
                if (block > 0)
                    while (ZOOM_event (1, &z))
                        ;
            }

            ZOOM_connection_destroy (z);
            
            for (j = 0; j < 10; j++)
            {
                ZOOM_resultset_records (r[j], 0, 0, 1);
            }
            for (j = 0; j < 10; j++)
                ZOOM_resultset_destroy (r[j]);
            ZOOM_query_destroy (q);
            printf ("10 searches, 10 ignored presents done\n");
        }


        for (i = 0; i<1; i++)
        {
            char host[40];
            ZOOM_scanset scan = 0;

            printf ("session %2d", i);
            sprintf (host, "localhost:9999/%d", i);
            z = ZOOM_connection_create (o);
            ZOOM_connection_connect (z, host, 0);

            scan = ZOOM_connection_scan (z, "@attr 1=4 a");
            if (block > 0)
                while (ZOOM_event (1, &z))
                    ;
            printf (" scan size = %ld\n", (long) ZOOM_scanset_size(scan));
            for (j = 0; j<ZOOM_scanset_size (scan); j++)
            {
                int occur, len;
                const char *term;
                term = ZOOM_scanset_term (scan, j, &occur, &len);
                if (term)
                    printf ("%d %.*s %d\n", j, len, term, occur);
                
            }
            ZOOM_scanset_destroy (scan);
            ZOOM_connection_destroy (z);
        }

    }
    ZOOM_options_destroy (o);
    exit (0);
}

/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

