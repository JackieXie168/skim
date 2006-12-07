/* ------------------------------------------------------------------------
@NAME       : parse_auxiliary.h
@INPUT      : 
@OUTPUT     : 
@RETURNS    : 
@DESCRIPTION: Prototype declarations for functions in parse_auxiliary.c
@GLOBALS    : 
@CALLS      : 
@CREATED    : 1997/01/08, Greg Ward
@MODIFIED   : 
@VERSION    : $Id: parse_auxiliary.h,v 1.5 1999/11/29 01:13:10 greg Rel $
@COPYRIGHT  : Copyright (c) 1996-99 by Gregory P. Ward.  All rights reserved.

              This file is part of the btparse library.  This library is
              free software; you can redistribute it and/or modify it under
              the terms of the GNU Library General Public License as
              published by the Free Software Foundation; either version 2
              of the License, or (at your option) any later version.
-------------------------------------------------------------------------- */

#ifndef PARSE_AUXILIARY_H
#define PARSE_AUXILIARY_H

#include "stdpccts.h"                   /* for SetWordType typedef */

void fix_token_names (void);
void zzsyn (char *text, int tok, 
            char *egroup, SetWordType *eset, int etok,
            int k, char *bad_text);
void  check_field_name (AST * field);

#endif /* PARSE_AUXILIARY_H */
