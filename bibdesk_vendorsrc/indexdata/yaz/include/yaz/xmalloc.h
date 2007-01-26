/*
 * Copyright (c) 1995-2007, Index Data
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
/* $Id: xmalloc.h,v 1.9 2007/01/03 08:42:14 adam Exp $ */

/**
 * \file xmalloc.h
 * \brief Header for malloc interface.
 */

#ifndef XMALLOC_H
#define XMALLOC_H

#include <stddef.h>

#include <yaz/yconfig.h>

YAZ_BEGIN_CDECL

#define xrealloc(o, x) xrealloc_f(o, x, __FILE__, __LINE__)
#define xmalloc(x) xmalloc_f(x, __FILE__, __LINE__)
#define xcalloc(x,y) xcalloc_f(x,y, __FILE__, __LINE__)
#define xfree(x) xfree_f(x, __FILE__, __LINE__)
#define xstrdup(s) xstrdup_f(s, __FILE__, __LINE__)
#define xmalloc_trav(s) xmalloc_trav_f(s, __FILE__, __LINE__)
    
YAZ_EXPORT void *xrealloc_f (void *o, size_t size, const char *file, int line);
YAZ_EXPORT void *xmalloc_f (size_t size, const char *file, int line);
YAZ_EXPORT void *xcalloc_f (size_t nmemb, size_t size,
                            const char *file, int line);
YAZ_EXPORT char *xstrdup_f (const char *p, const char *file, int line);
YAZ_EXPORT void xfree_f (void *p, const char *file, int line);
YAZ_EXPORT void xmalloc_trav_f(const char *s, const char *file, int line);

YAZ_END_CDECL

#endif
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

