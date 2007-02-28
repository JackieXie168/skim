/* $Id: zoomtst8.c,v 1.6 2007/01/03 08:42:17 adam Exp $  */

/** \file zoomtst8.c
    \brief Asynchronous multi-target client doing scan
*/

#include <stdio.h>
#include <string.h>

#include <yaz/nmem.h>
#include <yaz/xmalloc.h>
#include <yaz/zoom.h>

int main(int argc, char **argv)
{
    int i;
    int no = argc-2;
    ZOOM_connection z[500]; /* allow at most 500 connections */
    ZOOM_scanset s[500];  /* and scan sets .. */
    ZOOM_options o = ZOOM_options_create ();

    if (argc < 3)
    {
        fprintf (stderr, "usage:\n%s target1 target2 ... targetN scan\n",
                 *argv);
        exit (1);
    }
    if (no > 500)
        no = 500;

    /* async mode */
    ZOOM_options_set (o, "async", "1");

    /* connect to all */
    for (i = 0; i<no; i++)
    {
        /* create connection - pass options (they are the same for all) */
        z[i] = ZOOM_connection_create (o);

        /* connect and init */
        ZOOM_connection_connect (z[i], argv[1+i], 0);
        
    }
    /* scan all */
    for (i = 0; i<no; i++)
    {
        /* set number of scan terms to be returned. */
        ZOOM_connection_option_set (z[i], "number", "7");
        /* and perform scan */
        s[i] = ZOOM_connection_scan (z[i], argv[argc-1]);
    }

    /* network I/O. pass number of connections and array of connections */
    while (ZOOM_event (no, z))
        ;

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
            int j;
            printf ("%s\n", ZOOM_connection_option_get(z[i], "host"));
            for (j = 0; j<ZOOM_scanset_size (s[i]); j++)
            {
                int occur, len;
                const char *term;
                term = ZOOM_scanset_term (s[i], j, &occur, &len);
                if (term)
                    printf ("%d %.*s %d\n", j, len, term, occur);
            }
        }
    }

    /* destroy and exit */
    for (i = 0; i<no; i++)
    {
        ZOOM_scanset_destroy (s[i]);
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

