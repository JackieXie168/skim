/* $Id: zoomtst1.c,v 1.6 2007/01/03 08:42:17 adam Exp $  */

/** \file zoomtst1.c
    \brief Synchronous single-target client doing search (but no retrieval)
*/

#include <stdlib.h>
#include <stdio.h>
#include <yaz/xmalloc.h>
#include <yaz/zoom.h>

int main(int argc, char **argv)
{
    ZOOM_connection z;
    ZOOM_resultset r;
    int error;
    const char *errmsg, *addinfo;

    if (argc != 3)
    {
        fprintf (stderr, "usage:\n%s target query\n", *argv);
        fprintf (stderr, " eg.  bagel.indexdata.dk/gils computer\n");
        exit (1);
    }
    z = ZOOM_connection_new (argv[1], 0);
    
    if ((error = ZOOM_connection_error(z, &errmsg, &addinfo)))
    {
        fprintf (stderr, "Error: %s (%d) %s\n", errmsg, error, addinfo);
        exit (2);
    }

    r = ZOOM_connection_search_pqf (z, argv[2]);
    if ((error = ZOOM_connection_error(z, &errmsg, &addinfo)))
        fprintf (stderr, "Error: %s (%d) %s\n", errmsg, error, addinfo);
    else
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

