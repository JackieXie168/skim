/*
 * Copyright (C) 1995-2007, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: fhistory.h,v 1.1 2007/01/24 11:50:18 adam Exp $
 */
/** \file fhistory.h
 *  \brief file history header
 */


#ifndef YAZ_FHISTORY_H
#define YAZ_FHISTORY_H

#include <yaz/wrbuf.h>

YAZ_BEGIN_CDECL

typedef struct file_history *file_history_t;

file_history_t file_history_new(void);
void file_history_destroy(file_history_t *fhp);
void file_history_add_line(file_history_t fh, const char *line);
int file_history_save(file_history_t fh);
int file_history_load(file_history_t fh);
int file_history_trav(file_history_t fh, void *client_data,
                      void (*callback)(void *client_data, const char *line));

YAZ_END_CDECL

#endif
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

