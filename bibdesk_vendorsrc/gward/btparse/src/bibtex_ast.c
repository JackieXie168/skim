/* ------------------------------------------------------------------------
@NAME       : bibtex_ast.c
@DESCRIPTION: Data and functions for internal display/manipulation of AST
              nodes.  (Stuff for external consumption, and for processing
              whole trees, is to be found in traversal.c.)
@GLOBALS    : 
@CREATED    : 1997/08/12, Greg Ward
@MODIFIED   : 
@VERSION    : $Id: bibtex_ast.c,v 1.6 1999/11/29 01:13:10 greg Rel $
@COPYRIGHT  : Copyright (c) 1996-99 by Gregory P. Ward.  All rights reserved.

              This file is part of the btparse library.  This library is
              free software; you can redistribute it and/or modify it under
              the terms of the GNU Library General Public License as
              published by the Free Software Foundation; either version 2
              of the License, or (at your option) any later version.
-------------------------------------------------------------------------- */

#include "bt_config.h"
#include "btparse.h"
#include "prototypes.h"
#include "my_dmalloc.h"


char *nodetype_names[] = 
{
   "bogus", "entry", "key", "field", "string", "number", "macro"
};


static void dump (AST *root, int depth)
{
   AST  *cur;

   if (root == NULL)
   {
      printf ("[empty]\n");
      return;
   }

   cur = root;
   while (cur != NULL)
   {
      printf ("%*s[%s]: ", 2*depth, "", nodetype_names[cur->nodetype]);
      if (cur->text != NULL)
         printf ("(%s)\n", cur->text);
      else
         printf ("(null)\n");

      if (cur->down != NULL)
         dump (cur->down, depth+1);
      cur = cur->right;   
   }
}      


void dump_ast (char *msg, AST *root)
{
   if (msg != NULL)
      printf (msg);
   dump (root, 0);
   printf ("\n");
}
