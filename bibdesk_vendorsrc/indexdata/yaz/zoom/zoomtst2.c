/* $Id: zoomtst2.c,v 1.8 2006/04/21 10:28:08 adam Exp $  */

/** \file zoomtst2.c
    \brief Asynchronous single-target client performing search (no retrieval)
*/

#include <stdio.h>
#include <stdlib.h>

#include <yaz/zoom.h>

int main(int argc, char **argv)
{
    ZOOM_connection z;
    ZOOM_resultset r;
    int error;
    const char *errmsg, *addinfo, *diagset;

    if (argc < 3)
    {
        fprintf (stderr, "usage:\n%s target query\n", *argv);
        fprintf (stderr,
                 "Verify: asynchronous single-target client\n");
        exit (1);
    }

    /* create connection (don't connect yet) */
    z = ZOOM_connection_create(0);

    /* option: set sru/get operation (only applicable if http: is used) */
    ZOOM_connection_option_set (z, "sru", "post");

    /* option: set async operation */
    ZOOM_connection_option_set (z, "async", "1");

    /* connect to target and initialize */
    ZOOM_connection_connect (z, argv[1], 0);

    /* search using prefix query format */
    r = ZOOM_connection_search_pqf (z, argv[2]);

    /* block here: only one connection */
    while (ZOOM_event (1, &z))
        ;

    /* see if any error occurred */
    if ((error = ZOOM_connection_error_x(z, &errmsg, &addinfo, &diagset)))
    {
        fprintf (stderr, "Error: %s: %s (%d) %s\n", diagset, errmsg, error,
                         addinfo);
        exit (2);
    }
    else /* OK print hit count */
        printf ("Result count: %ld\n", (long) ZOOM_resultset_size(r));  
    ZOOM_resultset_destroy (r);
    ZOOM_connection_destroy (z);
    exit (0);
}
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

