/* ------------------------------------------------------------------------
@NAME       : prototypes.h
@INPUT      : 
@OUTPUT     : 
@RETURNS    : 
@DESCRIPTION: Prototype declarations for functions from various places.
              Only functions that are private to the library (but shared
              between files within the library) are declared here.  
              Functions that are "exported from" the library (ie. usable
              by and expected to be used by library user) are declared in
              btparse.h.              
@GLOBALS    : 
@CALLS      : 
@CREATED    : 1997/01/12, Greg Ward
@MODIFIED   : 
@VERSION    : $Id: prototypes.h,v 1.14 1999/11/29 01:13:10 greg Rel $
@COPYRIGHT  : Copyright (c) 1996-99 by Gregory P. Ward.  All rights reserved.

              This file is part of the btparse library.  This library is
              free software; you can redistribute it and/or modify it under
              the terms of the GNU Library General Public License as
              published by the Free Software Foundation; either version 2
              of the License, or (at your option) any later version.
-------------------------------------------------------------------------- */

#ifndef PROTOTYPES_H
#define PROTOTYPES_H

#include <stdio.h>
#include "btparse.h"                    /* for types */

/* util.c */
#if !HAVE_STRLWR
char *strlwr (char *s);
#endif
#if !HAVE_STRUPR
char *strupr (char *s);
#endif

/* macros.c */
void  init_macros (void);
void  done_macros (void);

/* bibtex_ast.c */
void dump_ast (char *msg, AST *root);

#endif /* PROTOTYPES_H */
