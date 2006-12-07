/* ------------------------------------------------------------------------
@NAME       : init.c
@DESCRIPTION: Initialization and cleanup functions for the btparse library.
@GLOBALS    : 
@CALLS      : 
@CREATED    : 1997/01/19, Greg Ward
@MODIFIED   : 
@VERSION    : $Id: init.c,v 1.8 1999/11/29 01:13:10 greg Rel $
@COPYRIGHT  : Copyright (c) 1996-99 by Gregory P. Ward.  All rights reserved.

              This file is part of the btparse library.  This library is
              free software; you can redistribute it and/or modify it under
              the terms of the GNU Library General Public License as
              published by the Free Software Foundation; either version 2
              of the License, or (at your option) any later version.
-------------------------------------------------------------------------- */

#include "bt_config.h"
#include "stdpccts.h"                   /* for zzfree_ast() prototype */
#include "parse_auxiliary.h"            /* for fix_token_names() proto */
#include "prototypes.h"                 /* for other prototypes */
#include "my_dmalloc.h"

void bt_initialize (void)
{
   /* Initialize data structures */

   fix_token_names ();
   init_macros ();
}


void bt_free_ast (AST *ast)
{
   zzfree_ast (ast);
}


void bt_cleanup (void)
{
   done_macros ();
}
