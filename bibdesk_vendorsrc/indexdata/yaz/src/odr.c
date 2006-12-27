/*
 * Copyright (C) 1995-2005, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: odr.c,v 1.13 2005/08/11 14:21:55 adam Exp $
 *
 */

/**
 * \file odr.c
 * \brief Implements fundamental ODR functionality
 */

#if HAVE_CONFIG_H
#include <config.h>
#endif

#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>

#include "xmalloc.h"
#include "log.h"
#include "odr-priv.h"

static int log_level=0;
static int log_level_initialized=0;

Odr_null *ODR_NULLVAL = (Odr_null *) "NULL";  /* the presence of a null value */

Odr_null *odr_nullval (void)
{
    return ODR_NULLVAL;
}

char *odr_errlist[] =
{
    "No (unknown) error",
    "Memory allocation failed",
    "System error",
    "No space in buffer",
    "Required data element missing",
    "Unexpected tag",
    "Other error",
    "Protocol error",
    "Malformed data",
    "Stack overflow",
    "Length of constructed type different from sum of members",
    "Overflow writing definite length of constructed type",
    "Bad HTTP Request"
};

char *odr_errmsg(int n)
{
    return odr_errlist[n];
}

void odr_perror(ODR o, const char *message)
{
    const char *e = odr_getelement(o);
    const char **element_path = odr_get_element_path(o);
    int err, x;

    err =  odr_geterrorx(o, &x);
    fprintf(stderr, "%s: %s (code %d:%d)", message, odr_errlist[err], err, x);
    if (e && *e)
        fprintf(stderr, " element %s", e);
    
    fprintf(stderr, "\n");
    if (element_path)
    {
        fprintf(stderr, "Element path:");
        while (*element_path)
            fprintf(stderr, " %s", *element_path++);
        fprintf(stderr, "\n");
    }
}

int odr_geterror(ODR o)
{
    return o->error;
}

int odr_geterrorx(ODR o, int *x)
{
    if (x)
        *x = o->op->error_id;
    return o->error;
}

const char *odr_getelement(ODR o)
{
    return o->op->element;
}

const char **odr_get_element_path(ODR o)
{
    int cur_sz = 0;
    struct odr_constack *st;

    for (st = o->op->stack_top; st; st = st->prev)
        cur_sz++;
    if (o->op->tmp_names_sz < cur_sz + 1)
    {
        o->op->tmp_names_sz = 2 * cur_sz + 5;
        o->op->tmp_names_buf = (const char **)
            odr_malloc(o, o->op->tmp_names_sz * sizeof(char*));
    }
    o->op->tmp_names_buf[cur_sz] = 0;
    for (st = o->op->stack_top; st; st = st->prev)
    {
        cur_sz--;
        o->op->tmp_names_buf[cur_sz] = st->name;
    }
    assert(cur_sz == 0);
    return o->op->tmp_names_buf;
}

void odr_seterror(ODR o, int error, int id)
{
    o->error = error;
    o->op->error_id = id;
    o->op->element[0] = '\0';
}

void odr_setelement(ODR o, const char *element)
{
    if (element)
    {
        strncpy(o->op->element, element, sizeof(o->op->element)-1);
        o->op->element[sizeof(o->op->element)-1] = '\0';
    }
}

void odr_FILE_write(ODR o, void *handle, int type,
                    const char *buf, int len)
{
    int i;
#if 0
    if (type  == ODR_OCTETSTRING)
    {
        const char **stack_names = odr_get_element_path(o);
        for (i = 0; stack_names[i]; i++)
            fprintf((FILE*) handle, "[%s]", stack_names[i]);
        fputs("\n", (FILE*) handle);
    }
#endif
    for (i = 0; i<len; i++)
    {
        unsigned c = ((const unsigned char *) buf)[i];
        if (i == 2000 && len > 3100)
        {
            fputs(" ..... ", (FILE*) handle);
                i = len - 1000;
        }
        if (strchr("\r\n\f\t", c) || (c >= ' ' && c <= 126))
            putc(c, (FILE*) handle);
        else
        {
            char x[5];
            sprintf(x, "\\X%02X", c);
            fputs(x, (FILE*) handle);
        }
    }
}

void odr_FILE_close(void *handle)
{
    FILE *f = (FILE *) handle;
    if (f && f != stderr && f != stdout)
        fclose(f);
}

void odr_setprint(ODR o, FILE *file)
{
    odr_set_stream(o, file, odr_FILE_write, odr_FILE_close);
}

void odr_set_stream(ODR o, void *handle,
                    void (*stream_write)(ODR o, 
                                         void *handle, int type,
                                         const char *buf, int len),
                    void (*stream_close)(void *handle))
{
    o->print = (FILE*) handle;
    o->op->stream_write = stream_write;
    o->op->stream_close = stream_close;
}

int odr_set_charset(ODR o, const char *to, const char *from)
{
    if (o->op->iconv_handle)
        yaz_iconv_close (o->op->iconv_handle);
    o->op->iconv_handle = 0;
    if (to && from)
    {
        o->op->iconv_handle = yaz_iconv_open (to, from);
        if (o->op->iconv_handle == 0)
            return -1;
    }
    return 0;
}


ODR odr_createmem(int direction)
{
    ODR o;
    if (!log_level_initialized)
    {
        log_level=yaz_log_module_level("odr");
        log_level_initialized=1;
    }

    if (!(o = (ODR)xmalloc(sizeof(*o))))
        return 0;
    o->direction = direction;
    o->buf = 0;
    o->size = o->pos = o->top = 0;
    o->can_grow = 1;
    o->mem = nmem_create();
    o->enable_bias = 1;
    o->op = (struct Odr_private *) xmalloc (sizeof(*o->op));
    o->op->odr_ber_tag.lclass = -1;
    o->op->iconv_handle = 0;
    odr_setprint(o, stderr);
    odr_reset(o);
    yaz_log (log_level, "odr_createmem dir=%d o=%p", direction, o);
    return o;
}

void odr_reset(ODR o)
{
    if (!log_level_initialized)
    {
        log_level=yaz_log_module_level("odr");
        log_level_initialized=1;
    }

    odr_seterror(o, ONONE, 0);
    o->bp = o->buf;
    odr_seek(o, ODR_S_SET, 0);
    o->top = 0;
    o->t_class = -1;
    o->t_tag = -1;
    o->indent = 0;
    o->op->stack_first = 0;
    o->op->stack_top = 0;
    o->op->tmp_names_sz = 0;
    o->op->tmp_names_buf = 0;
    nmem_reset(o->mem);
    o->choice_bias = -1;
    o->lenlen = 1;
    if (o->op->iconv_handle != 0)
        yaz_iconv(o->op->iconv_handle, 0, 0, 0, 0);
    yaz_log (log_level, "odr_reset o=%p", o);
}
    
void odr_destroy(ODR o)
{
    nmem_destroy(o->mem);
    if (o->buf && o->can_grow)
       xfree(o->buf);
    if (o->op->stream_close)
        o->op->stream_close(o->print);
    if (o->op->iconv_handle != 0)
        yaz_iconv_close (o->op->iconv_handle);
    xfree(o->op);
    xfree(o);
    yaz_log (log_level, "odr_destroy o=%p", o);
}

void odr_setbuf(ODR o, char *buf, int len, int can_grow)
{
    odr_seterror(o, ONONE, 0);
    o->bp = (unsigned char *) buf;

    o->buf = (unsigned char *) buf;
    o->can_grow = can_grow;
    o->top = o->pos = 0;
    o->size = len;
}

char *odr_getbuf(ODR o, int *len, int *size)
{
    *len = o->top;
    if (size)
        *size = o->size;
    return (char*) o->buf;
}

void odr_printf(ODR o, const char *fmt, ...)
{
    va_list ap;
    char buf[4096];

    va_start(ap, fmt);
#ifdef WIN32
    _vsnprintf(buf, sizeof(buf)-1, fmt, ap);
#else
#if HAVE_VSNPRINTF
    vsnprintf(buf, sizeof(buf), fmt, ap);
#else
    vsprintf(buf, fmt, ap);
#endif
#endif
    o->op->stream_write(o, o->print, ODR_VISIBLESTRING, buf, strlen(buf));
    va_end(ap);
}
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

