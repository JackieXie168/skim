/* $Id: zoom-ka.c,v 1.1 2006/09/19 19:41:32 adam Exp $  */

/** \file zoom-ka.c
    \brief Test ZOOM Keepalive / reconnect
*/

#include <stdlib.h>
#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <yaz/wrbuf.h>

#include <yaz/nmem.h>
#include <yaz/xmalloc.h>
#include <yaz/zoom.h>

int main(int argc, char **argv)
{
    ZOOM_connection z;
    ZOOM_options o = ZOOM_options_create ();
    const char *errmsg, *addinfo;
    
    if (argc != 4)
    {
        fprintf (stderr, "usage:\nzoom-ka sleepinterval target query\n");
        exit(1);
    }
    /* async mode */
    ZOOM_options_set (o, "async", "1");

    z = ZOOM_connection_create(o);

    while(1)
    {
        int i, error;
        ZOOM_resultset rset;
        ZOOM_connection_connect (z, argv[2], 0);
        rset = ZOOM_connection_search_pqf(z, argv[3]);
        
        while ((i = ZOOM_event(1, &z)))
        {
            printf ("no = %d event = %d\n", i-1,
                    ZOOM_connection_last_event(z));
        }
        if ((error = ZOOM_connection_error(z, &errmsg, &addinfo)))
        {
            fprintf(stderr, "%s error: %s (%d) %s\n",
                    ZOOM_connection_option_get(z, "host"),
                    errmsg, error, addinfo);
        }
        ZOOM_resultset_destroy(rset);
        sleep(atoi(argv[1]));
    }
    ZOOM_connection_destroy (z);
    ZOOM_options_destroy(o);
}
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

