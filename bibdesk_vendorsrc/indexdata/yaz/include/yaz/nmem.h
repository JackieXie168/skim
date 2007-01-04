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
/* $Id: nmem.h,v 1.23 2006/10/27 12:19:15 adam Exp $ */

/**
 * \file nmem.h
 * \brief Header for Nibble Memory functions
 *
 * This is a simple and fairly wasteful little module for nibble memory
 * allocation. Evemtually we'll put in something better.
 */
#ifndef NMEM_H
#define NMEM_H

#include <stddef.h>
#include <yaz/yconfig.h>

#define NMEM_DEBUG 0

#ifndef NMEM_DEBUG
#define NMEM_DEBUG 0
#endif

YAZ_BEGIN_CDECL

/** \brief NMEM/YAZ MUTEX opaque pointer */
typedef struct nmem_mutex *NMEM_MUTEX;
/** \brief create Mutex */
YAZ_EXPORT void nmem_mutex_create(NMEM_MUTEX *);
/** \brief enter critical section / AKA lock */
YAZ_EXPORT void nmem_mutex_enter(NMEM_MUTEX);
/** \brief leave critical section / AKA unlock */
YAZ_EXPORT void nmem_mutex_leave(NMEM_MUTEX);
/** \brief destroy MUTEX */
YAZ_EXPORT void nmem_mutex_destroy(NMEM_MUTEX *);

/** \brief NMEM handle (an opaque pointer to memory) */
typedef struct nmem_control *NMEM;

/** \brief release all memory associaged with an NMEM handle */
YAZ_EXPORT void nmem_reset(NMEM n);
/** \brief returns size in bytes of memory for NMEM handle */
YAZ_EXPORT int nmem_total(NMEM n);

/** \brief allocates string on NMEM handle (similar strdup) */
YAZ_EXPORT char *nmem_strdup (NMEM mem, const char *src);
/** \brief allocates string on NMEM handle - allows NULL ptr buffer */
YAZ_EXPORT char *nmem_strdup_null (NMEM mem, const char *src);
/** \brief allocates string of certain size on NMEM handle */
YAZ_EXPORT char *nmem_strdupn (NMEM mem, const char *src, size_t n);

/** \brief allocates sub strings out of string using certain delimitors
    \param nmem NMEM handle
    \param delim delimitor chars (splits on each char in there) 
    \param dstr string to be split
    \param darray result string array for each sub string
    \param num number of result strings
*/
YAZ_EXPORT void nmem_strsplit(NMEM nmem, const char *delim,
                              const char *dstr,
                              char ***darray, int *num);

/** \brief splits string into sub strings delimited by blanks
    \param nmem NMEM handle
    \param dstr string to be split
    \param darray result string array for each sub string
    \param num number of result strings
*/
YAZ_EXPORT void nmem_strsplit_blank(NMEM nmem, const char *dstr,
                                    char ***darray, int *num);

/** \brief creates and allocates integer for NMEM */
YAZ_EXPORT int *nmem_intdup (NMEM mem, int v);

/** \brief transfers memory from one NMEM handle to another  */
YAZ_EXPORT void nmem_transfer (NMEM dst, NMEM src);

/** \brief internal (do not use) */
YAZ_EXPORT void nmem_critical_enter (void);
/** \brief internal (do not use) */
YAZ_EXPORT void nmem_critical_leave (void);

#if NMEM_DEBUG

YAZ_EXPORT NMEM nmem_create_f(const char *file, int line);
YAZ_EXPORT void nmem_destroy_f(const char *file, int line, NMEM n);
YAZ_EXPORT void *nmem_malloc_f(const char *file, int line, NMEM n, int size);
#define nmem_create() nmem_create_f(__FILE__, __LINE__)
#define nmem_destroy(x) nmem_destroy_f(__FILE__, __LINE__, (x))
#define nmem_malloc(x, y) nmem_malloc_f(__FILE__, __LINE__, (x), (y))

YAZ_EXPORT void nmem_print_list (void);
YAZ_EXPORT void nmem_print_list_l (int level);

#else

/** \brief returns new NMEM handle */
YAZ_EXPORT NMEM nmem_create(void);

/** \brief destroys NMEM handle and memory associated with it */
YAZ_EXPORT void nmem_destroy(NMEM n);

/** \brief allocate memory block on NMEM handle */
YAZ_EXPORT void *nmem_malloc(NMEM n, int size);

#define nmem_print_list()

#endif

/** \brief initializes NMEM system
    This function increments a usage counter for NMEM.. Only
    on first usage the system is initialized.. The \fn nmem_exit
    decrements the counter. So these must be called in pairs
*/
YAZ_EXPORT void nmem_init (void);

/** \brief destroys NMEM system */
YAZ_EXPORT void nmem_exit (void);

YAZ_EXPORT int yaz_errno (void);
YAZ_EXPORT void yaz_set_errno (int v);
YAZ_EXPORT void yaz_strerror(char *buf, int max);

/** \brief returns memory in use (by application) 
    \param p pointer to size (in bytes)
 */
YAZ_EXPORT void nmem_get_memory_in_use(size_t *p);
/** \brief returns memory in free (for later reuse) 
 */
YAZ_EXPORT void nmem_get_memory_free(size_t *p);

YAZ_END_CDECL

#endif
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

