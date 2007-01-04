/*
 * Copyright (c) 1995-2006, Index Data
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of Index Data nor the names of its contributors
 *       may be used to endorse or promote products derived from this
 *       software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE REGENTS AND CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
/* $Id: wrbuf.h,v 1.20 2006/10/09 21:02:41 adam Exp $ */

/**
 * \file wrbuf.h
 * \brief Header for WRBUF (growing buffer)
 */

#ifndef WRBUF_H
#define WRBUF_H

#include <yaz/xmalloc.h>
#include <yaz/yaz-iconv.h>

YAZ_BEGIN_CDECL

typedef struct wrbuf
{
    char *buf;
    int pos;
    int size;
} wrbuf, *WRBUF;

YAZ_EXPORT WRBUF wrbuf_alloc(void);
YAZ_EXPORT void wrbuf_free(WRBUF b, int free_buf);
YAZ_EXPORT void wrbuf_rewind(WRBUF b);
YAZ_EXPORT int wrbuf_grow(WRBUF b, int minsize);
YAZ_EXPORT int wrbuf_write(WRBUF b, const char *buf, int size);
YAZ_EXPORT int wrbuf_xmlputs_n(WRBUF b, const char *cp, int size);
YAZ_EXPORT int wrbuf_puts(WRBUF b, const char *buf);
YAZ_EXPORT int wrbuf_puts_replace_char(WRBUF b, const char *buf, 
                                       const char from, const char to);
YAZ_EXPORT int wrbuf_xmlputs(WRBUF b, const char *cp);
YAZ_EXPORT void wrbuf_printf(WRBUF b, const char *fmt, ...)
#ifdef __GNUC__
        __attribute__ ((format (printf, 2, 3)))
#endif
        ;

YAZ_EXPORT int wrbuf_iconv_write(WRBUF b, yaz_iconv_t cd, const char *buf,
                                 int size);
YAZ_EXPORT int wrbuf_iconv_write_cdata(WRBUF b, yaz_iconv_t cd,
                                       const char *buf, int size);
YAZ_EXPORT int wrbuf_iconv_puts(WRBUF b, yaz_iconv_t cd, const char *strz);

YAZ_EXPORT int wrbuf_iconv_putchar(WRBUF b, yaz_iconv_t cd, int ch);

YAZ_EXPORT void wrbuf_chop_right(WRBUF b);

#define wrbuf_len(b) ((b)->pos)
#define wrbuf_buf(b) ((b)->buf)

#define wrbuf_putc(b, c) \
    (((b)->pos >= (b)->size ? wrbuf_grow(b, 1) : 0),  \
    (b)->buf[(b)->pos++] = (c), 0)

YAZ_END_CDECL

#endif
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

