/*
 * Copyright (C) 1995-2007, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: mime.h,v 1.4 2007/01/03 08:42:15 adam Exp $
 */

/** \file mime.h
    \brief Small utility to manage MIME types
*/

#ifndef MIME_H
#define MIME_H

typedef struct yaz_mime_info *yaz_mime_types;

yaz_mime_types yaz_mime_types_create(void);
void yaz_mime_types_add(yaz_mime_types t, const char *suffix,
                        const char *mime_type);
const char *yaz_mime_lookup_suffix(yaz_mime_types t, const char *suffix);
const char *yaz_mime_lookup_fname(yaz_mime_types t, const char *fname);
void yaz_mime_types_destroy(yaz_mime_types t);

#endif

