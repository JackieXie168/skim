/* ------------------------------------------------------------------------
@NAME       : modify.c
@DESCRIPTION: Routines for modifying the AST for a single entry.
@GLOBALS    : 
@CALLS      : 
@CREATED    : 1999/11/25, Greg Ward (based on code supplied by
              Stéphane Genaud <genaud@icps.u-strasbg.fr>)
@MODIFIED   : 
@VERSION    : $Id: modify.c,v 1.2 1999/11/29 01:13:10 greg Rel $
@COPYRIGHT  : Copyright (c) 1996-99 by Gregory P. Ward.  All rights reserved.

              This file is part of the btparse library.  This library is
              free software; you can redistribute it and/or modify it under
              the terms of the GNU Library General Public License as
              published by the Free Software Foundation; either version 2
              of the License, or (at your option) any later version.
-------------------------------------------------------------------------- */
#include "bt_config.h"
#include <stdlib.h>
#include <string.h>
#include "btparse.h"
#include "error.h"
#include "my_dmalloc.h"


/* ------------------------------------------------------------------------
@NAME       : bt_set_text ()
@INPUT      : node
              new_text
@OUTPUT     : node->text
@RETURNS    : 
@DESCRIPTION: Replace the text member of an AST node with a new string.
              The passed in string, 'new_text', is duplicated, so the
              caller may free it without worry.
@GLOBALS    : 
@CALLS      : 
@CALLERS    : 
@CREATED    : 1999/11/25, GPW (from Stéphane Genaud)
@MODIFIED   : 
-------------------------------------------------------------------------- */
void bt_set_text (AST * node, char * new_text)
{
   free(node->text);
   node->text = strdup (new_text);
}


/* ------------------------------------------------------------------------
@NAME       : bt_entry_set_key ()
@INPUT      : entry
              new_key
@OUTPUT     : entry->down->text
@RETURNS    : 
@DESCRIPTION: Changes the key of a regular entry to 'new_key'.  If 'entry'
              is not a regular entry, or if it doesn't already have a child
              node holding an entry key, bombs via 'usage_error()'.
              Otherwise a duplicate of 'new_key' is copied into the entry
              AST (so the caller can free that string without worry).
@CALLS      : bt_set_text ()
@CREATED    : 1999/11/25, GPW (from Stéphane Genaud)
@MODIFIED   : 
-------------------------------------------------------------------------- */
void bt_entry_set_key (AST * entry, char * new_key)
{
   if (entry->metatype == BTE_REGULAR &&
       entry->down && entry->down->nodetype == BTAST_KEY)
   {
      bt_set_text (entry->down, new_key);
   }
   else
   {
      usage_error ("can't set entry key -- not a regular entry, "
                   "or doesn't have a key already");
   }
}
