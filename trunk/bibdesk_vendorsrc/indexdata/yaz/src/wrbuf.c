/*
 * Copyright (C) 1995-2007, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: wrbuf.c,v 1.15 2007/01/06 16:05:24 adam Exp $
 */

/**
 * \file wrbuf.c
 * \brief Implements WRBUF (growing buffer)
 */

#if HAVE_CONFIG_H
#include <config.h>
#endif

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>

#include <yaz/wrbuf.h>
#include <yaz/yaz-iconv.h>

WRBUF wrbuf_alloc(void)
{
    WRBUF n;

    if (!(n = (WRBUF)xmalloc(sizeof(*n))))
        abort();
    n->buf = 0;
    n->size = 0;
    n->pos = 0;
    return n;
}

void wrbuf_free(WRBUF b, int free_buf)
{
    if (free_buf && b->buf)
        xfree(b->buf);
    xfree(b);
}

void wrbuf_destroy(WRBUF b)
{
    wrbuf_free(b, 1);
}

void wrbuf_rewind(WRBUF b)
{
    b->pos = 0;
}

int wrbuf_grow(WRBUF b, int minsize)
{
    int togrow;

    if (!b->size)
        togrow = 1024;
    else
        togrow = b->size;
    if (togrow < minsize)
        togrow = minsize;
    if (b->size && !(b->buf =(char *)xrealloc(b->buf, b->size += togrow)))
        abort();
    else if (!b->size && !(b->buf = (char *)xmalloc(b->size = togrow)))
        abort();
    return 0;
}

int wrbuf_write(WRBUF b, const char *buf, int size)
{
    if (size <= 0)
        return 0;
    if (b->pos + size >= b->size)
        wrbuf_grow(b, size);
    memcpy(b->buf + b->pos, buf, size);
    b->pos += size;
    return 0;
}

int wrbuf_puts(WRBUF b, const char *buf)
{
    wrbuf_write(b, buf, strlen(buf)+1);  /* '\0'-terminate as well */
    (b->pos)--;                          /* don't include '\0' in count */
    return 0;
}

int wrbuf_puts_replace_char(WRBUF b, const char *buf, 
                            const char from, const char to)
{
    while(*buf){
        if (*buf == from)
            wrbuf_putc(b, to);
        else
            wrbuf_putc(b, *buf);
        buf++;
    }
    wrbuf_putc(b, 0);
    (b->pos)--;                          /* don't include '\0' in count */
    return 0;
}

void wrbuf_chop_right(WRBUF b)
{
    while (b->pos && b->buf[b->pos-1] == ' ')
    {
        (b->pos)--;
        b->buf[b->pos] = '\0';
    }
}

int wrbuf_xmlputs(WRBUF b, const char *cp)
{
    return wrbuf_xmlputs_n(b, cp, strlen(cp));
}

int wrbuf_xmlputs_n(WRBUF b, const char *cp, int size)
{
    while (--size >= 0)
    {
        /* only TAB,CR,LF of ASCII CTRL are allowed in XML 1.0! */
        if (*cp >= 0 && *cp <= 31)
            if (*cp != 9 && *cp != 10 && *cp != 13)
            {
                cp++;  /* we silently ignore (delete) these.. */
                continue;
            }
        switch(*cp)
        {
        case '<':
            wrbuf_puts(b, "&lt;");
            break;
        case '>':
            wrbuf_puts(b, "&gt;");
            break;
        case '&':
            wrbuf_puts(b, "&amp;");
            break;
        case '"':
            wrbuf_puts(b, "&quot;");
            break;
        case '\'':
            wrbuf_puts(b, "&apos;");
            break;
        default:
            wrbuf_putc(b, *cp);
        }
        cp++;
    }
    wrbuf_putc(b, 0);
    (b->pos)--;
    return 0;
}

void wrbuf_printf(WRBUF b, const char *fmt, ...)
{
    va_list ap;
    char buf[4096];

    va_start(ap, fmt);
#ifdef WIN32
    _vsnprintf(buf, sizeof(buf)-1, fmt, ap);
#else
/* !WIN32 */
#if HAVE_VSNPRINTF
    vsnprintf(buf, sizeof(buf)-1, fmt, ap);
#else
    vsprintf(buf, fmt, ap);
#endif
#endif
    wrbuf_puts (b, buf);

    va_end(ap);
}

static int wrbuf_iconv_write_x(WRBUF b, yaz_iconv_t cd, const char *buf,
                               int size, int cdata)
{
    if (cd)
    {
        char outbuf[12];
        size_t inbytesleft = size;
        const char *inp = buf;
        while (inbytesleft)
        {
            size_t outbytesleft = sizeof(outbuf);
            char *outp = outbuf;
            size_t r = yaz_iconv(cd, (char**) &inp,  &inbytesleft,
                                 &outp, &outbytesleft);
            if (r == (size_t) (-1))
            {
                int e = yaz_iconv_error(cd);
                if (e != YAZ_ICONV_E2BIG)
                    break;
            }
            if (cdata)
                wrbuf_xmlputs_n(b, outbuf, outp - outbuf);
            else
                wrbuf_write(b, outbuf, outp - outbuf);
        }
    }
    else
    {
        if (cdata)
            wrbuf_xmlputs_n(b, buf, size);
        else
            wrbuf_write(b, buf, size);
    }
    return wrbuf_len(b);
}

int wrbuf_iconv_write(WRBUF b, yaz_iconv_t cd, const char *buf, int size)
{
    return wrbuf_iconv_write_x(b, cd, buf, size, 0);
}

int wrbuf_iconv_puts(WRBUF b, yaz_iconv_t cd, const char *strz)
{
    return wrbuf_iconv_write(b, cd, strz, strlen(strz));
}

int wrbuf_iconv_putchar(WRBUF b, yaz_iconv_t cd, int ch)
{
    char buf[1];
    buf[0] = ch;
    return wrbuf_iconv_write(b, cd, buf, 1);
}

int wrbuf_iconv_write_cdata(WRBUF b, yaz_iconv_t cd, const char *buf, int size)
{
    return wrbuf_iconv_write_x(b, cd, buf, size, 1);
}

const char *wrbuf_cstr(WRBUF b)
{
    wrbuf_write(b, "", 1);  /* '\0'-terminate as well */
    (b->pos)--;             /* don't include '\0' in count */
    return b->buf;
}

/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

