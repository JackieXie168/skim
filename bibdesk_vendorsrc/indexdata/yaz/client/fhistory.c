/* 
 * Copyright (C) 1995-2007, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: fhistory.c,v 1.2 2007/01/24 23:09:48 adam Exp $
 */
/** \file fhistory.c
 *  \brief file history implementation
 */

#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <time.h>
#include <ctype.h>
#if HAVE_SYS_TYPES_H
#include <sys/types.h>
#endif

#include "fhistory.h"


struct file_history {
    WRBUF wr;
};

file_history_t file_history_new()
{
    file_history_t fh = xmalloc(sizeof(*fh));
    fh->wr = wrbuf_alloc();
    return fh;
}

void file_history_destroy(file_history_t *fhp)
{
    if (*fhp)
    {
        wrbuf_destroy((*fhp)->wr);
        xfree(*fhp);
        *fhp = 0;
    }
}

void file_history_add_line(file_history_t fh, const char *line)
{
    wrbuf_puts(fh->wr, line);
    wrbuf_puts(fh->wr, "\n");
}

int file_history_load(file_history_t fh)
{
    FILE *f;
    char* homedir = getenv("HOME");
    char fname[1024];
    int ret = 0;

    wrbuf_rewind(fh->wr);
    sprintf(fname, "%.500s%s%s", homedir ? homedir : "",
            homedir ? "/" : "", ".yazclient.history");

    f = fopen(fname, "r");
    if (f)
    {
        int c;
        while ((c = fgetc(f)) != EOF)
            wrbuf_putc(fh->wr, c);
        fclose(f);
    }
    return ret;
}

int file_history_save(file_history_t fh)
{
    FILE *f;
    char* homedir = getenv("HOME");
    char fname[1024];
    int ret = 0;
    int sz = wrbuf_len(fh->wr);

    if (!sz)
        return 0;
    sprintf(fname, "%.500s%s%s", homedir ? homedir : "",
            homedir ? "/" : "", ".yazclient.history");

    f = fopen(fname, "w");
    if (!f)
    {
        ret = -1;
    }
    else
    {
        size_t w = fwrite(wrbuf_buf(fh->wr), 1, sz, f);
        if (w != sz)
            ret = -1;
        if (fclose(f))
            ret = -1;
    }
    return ret;
}

int file_history_trav(file_history_t fh, void *client_data,
                      void (*callback)(void *client_data, const char *line))
{
    int off = 0;

    while (off < wrbuf_len(fh->wr))
    {
        int i;
        for (i = off; i < wrbuf_len(fh->wr); i++)
        {
            if (wrbuf_buf(fh->wr)[i] == '\n')
            {
                wrbuf_buf(fh->wr)[i] = '\0';
                callback(client_data, wrbuf_buf(fh->wr) + off);
                wrbuf_buf(fh->wr)[i] = '\n';
                i++;
                break;
            }
        }
        off = i;
    }
    return 0;
}

/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

