/* $Id: zoomtst10.c,v 1.3 2006/10/24 09:53:42 adam Exp $  */

/** \file zoomtst10.c
    \brief Synchronous single-target search using CCL conversion
*/

#include <stdlib.h>
#include <stdio.h>
#include <yaz/xmalloc.h>
#include <yaz/zoom.h>

int main(int argc, char **argv)
{
    ZOOM_connection z;
    ZOOM_resultset r;
    ZOOM_query q = ZOOM_query_create();
    int error;
    const char *errmsg, *addinfo;
    int ccl_error_code, ccl_error_pos;
    const char *ccl_error_string;

    if (argc != 3)
    {
        fprintf (stderr, "usage:\n%s target cclquery\n", *argv);
        fprintf (stderr, " eg.  bagel.indexdata.dk/gils \"ti=utah\"\n");
        exit (1);
    }

    if (ZOOM_query_ccl2rpn(q, argv[2], 
                           "term t=l,r s=al\n" "ti u=4 s=pw\n",
                           &ccl_error_code, &ccl_error_string, &ccl_error_pos))
    {
        printf("CCL Error %d: %s\n", ccl_error_code, ccl_error_string);
        if (ccl_error_pos >= 0)
            printf("%s\n%*s^\n", argv[2], ccl_error_pos, "");
        ZOOM_query_destroy(q);
    }
    else
    {
        z = ZOOM_connection_new (argv[1], 0);
        
        if ((error = ZOOM_connection_error(z, &errmsg, &addinfo)))
        {
            fprintf (stderr, "Error: %s (%d) %s\n", errmsg, error, addinfo);
            exit (2);
        }
        
        r = ZOOM_connection_search (z, q);
        ZOOM_query_destroy(q);
        if ((error = ZOOM_connection_error(z, &errmsg, &addinfo)))
            fprintf (stderr, "Error: %s (%d) %s\n", errmsg, error, addinfo);
        else
            printf ("Result count: %ld\n", (long) ZOOM_resultset_size(r));
        ZOOM_resultset_destroy (r);
        ZOOM_connection_destroy (z);
    }
    exit (0);
}
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

