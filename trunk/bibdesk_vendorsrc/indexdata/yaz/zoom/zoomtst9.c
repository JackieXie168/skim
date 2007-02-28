/* $Id: zoomtst9.c,v 1.5 2007/01/03 08:42:17 adam Exp $  */

/** \file zoomtst9.c
    \brief Extended Service Update
*/

#include <stdio.h>
#include <string.h>
#include <yaz/wrbuf.h>

#include <yaz/nmem.h>
#include <yaz/xmalloc.h>
#include <yaz/zoom.h>

static void usage(void)
{
    fprintf(stderr, "usage:\n"
            "zoomtst9 target [insert|delete|replace|update] id1 rec1 "
            "id2 rec2 ..\n");

    fprintf(stderr, "\nThis program illustrates the usage of"
            " extended services Update from ZOOM.\n");
    fprintf(stderr, "\nid "
            "is optional opaque record Id and is omitted if empty.\n");
    fprintf(stderr, "\nrec "
            "is optional record data and is omitted if empty.\n");
    exit (1);
}

int main(int argc, char **argv)
{
    ZOOM_connection z;
    ZOOM_options o = ZOOM_options_create ();
    int error;
    const char *errmsg, *addinfo;
    
    if (argc < 3)
        usage();

    z = ZOOM_connection_create (o);
    
    /* connect and init */
    ZOOM_connection_connect (z, argv[1], 0);
    
    if ((error = ZOOM_connection_error(z, &errmsg, &addinfo)))
    {
        fprintf(stderr, "%s error: %s (%d) %s\n",
                ZOOM_connection_option_get(z, "host"),
                errmsg, error, addinfo);
    }
    else
    {
        ZOOM_package pkg = ZOOM_connection_package(z, 0);
        const char *cmd = argv[2];
        int i;

        if (!strcmp(cmd, "insert"))
            ZOOM_package_option_set(pkg, "action", "recordInsert");
        else if (!strcmp(cmd, "update"))
            ZOOM_package_option_set(pkg, "action", "specialUpdate");
        else if (!strcmp(cmd, "replace"))
            ZOOM_package_option_set(pkg, "action", "recordReplace");
        else if (!strcmp(cmd, "delete"))
            ZOOM_package_option_set(pkg, "action", "recordDelete");
        else
        {
            fprintf(stderr, "Bad action %s\n", cmd);
            usage();
        }

        i = 3;
        while (i < argc-1)
        {
            ZOOM_package_option_set(pkg, "recordIdOpaque",
                                    argv[i][0] ? argv[i] : 0);
            i++;
            if (!strcmp(argv[i], "-"))
            {
                /* For -, read record buffer from stdin */
                WRBUF w = wrbuf_alloc();
                int ch;
                while ((ch = getchar()) != EOF)
                    wrbuf_putc(w, ch);
                wrbuf_putc(w, '\0');
                ZOOM_package_option_set(pkg, "record", wrbuf_buf(w));
            }
            else
            {
                ZOOM_package_option_set(pkg, "record",
                                        argv[i][0] ? argv[i] : 0);
            }
            i++;
            ZOOM_package_send(pkg, "update"); /* Update EXT service */

            if ((error = ZOOM_connection_error(z, &errmsg, &addinfo)))
            {
                fprintf(stderr, "%s error: %s (%d) %s\n",
                        ZOOM_connection_option_get(z, "host"),
                        errmsg, error, addinfo);
            }
        }
    }
    ZOOM_connection_destroy (z);
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

