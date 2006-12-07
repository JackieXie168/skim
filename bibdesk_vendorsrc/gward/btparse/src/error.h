/* ------------------------------------------------------------------------
@NAME       : error.c
@DESCRIPTION: Prototypes for the error-generating functions (i.e. functions
              defined in error.c, and meant only for use elswhere in the
              library).
@CREATED    : Summer 1996, Greg Ward
@MODIFIED   : 
@VERSION    : $Id: error.h,v 1.11 1999/11/29 01:13:10 greg Rel $
@COPYRIGHT  : Copyright (c) 1996-99 by Gregory P. Ward.  All rights reserved.

              This file is part of the btparse library.  This library is
              free software; you can redistribute it and/or modify it under
              the terms of the GNU Library General Public License as
              published by the Free Software Foundation; either version 2
              of the License, or (at your option) any later version.
-------------------------------------------------------------------------- */

#ifndef ERROR_H
#define ERROR_H

#include <stdarg.h>
#include "btparse.h"                    /* for AST typedef */

#define MAX_ERROR 1024

#define ERRFUNC_BODY(class,filename,line,item_desc,item,format)            \
{                                                                          \
   va_list  arglist;                                                       \
                                                                           \
   va_start (arglist, format);                                             \
   report_error (class, filename, line, item_desc, item, format, arglist); \
   va_end (arglist);                                                       \
}

#define GEN_ERRFUNC(name,params,class,filename,line,item_desc,item,format) \
void name params                                                           \
ERRFUNC_BODY (class, filename, line, item_desc, item, format)

#define GEN_PRIVATE_ERRFUNC(name,params,                                  \
                            class,filename,line,item_desc,item,format)    \
static GEN_ERRFUNC(name,params,class,filename,line,item_desc,item,format)

/*
 * Prototypes for functions exported by error.c but only used within
 * the library -- functions that can be called by outsiders are declared
 * in btparse.h.
 */

void print_error (bt_error *err);
void report_error (bt_errclass class, 
                   char * filename, int line, char * item_desc, int item,
                   char * format, va_list arglist);

void general_error (bt_errclass class,
                    char * filename, int line, char * item_desc, int item,
                    char * format, ...);
void error (bt_errclass class, char * filename, int line, char * format, ...);
void ast_error (bt_errclass class, AST * ast, char * format, ...);

void notify (char *format,...);
void usage_warning (char * format, ...);
void usage_error (char * format, ...);
void internal_error (char * format, ...);

#endif
