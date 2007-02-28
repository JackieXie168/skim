/* ------------------------------------------------------------------------
@NAME       : traversal.c
@DESCRIPTION: Routines for traversing the AST for a single entry.
@GLOBALS    : 
@CALLS      : 
@CREATED    : 1997/01/21, Greg Ward
@MODIFIED   : 
@VERSION    : $Id: traversal.c,v 1.17 1999/11/29 01:13:10 greg Rel $
@COPYRIGHT  : Copyright (c) 1996-99 by Gregory P. Ward.  All rights reserved.

              This file is part of the btparse library.  This library is
              free software; you can redistribute it and/or modify it under
              the terms of the GNU Library General Public License as
              published by the Free Software Foundation; either version 2
              of the License, or (at your option) any later version.
-------------------------------------------------------------------------- */
#include "bt_config.h"
#include <stdlib.h>
#include "btparse.h"
#include "parse_auxiliary.h"
#include "prototypes.h"
#include "my_dmalloc.h"


AST *bt_next_entry (AST *entry_list, AST *prev_entry)
{
   if (entry_list == NULL || entry_list->nodetype != BTAST_ENTRY)
      return NULL;

   if (prev_entry)
   {
      if (prev_entry->nodetype != BTAST_ENTRY) 
         return NULL;
      else
         return prev_entry->right;
   }
   else
      return entry_list;
}


bt_metatype bt_entry_metatype (AST *entry)
{
   if (!entry) return BTE_UNKNOWN;
   if (entry->nodetype != BTAST_ENTRY)
      return BTE_UNKNOWN;
   else
      return entry->metatype;
}


char *bt_entry_type (AST *entry)
{
   if (!entry) return NULL;
   if (entry->nodetype != BTAST_ENTRY)
      return NULL;
   else
      return entry->text;
}


char *bt_entry_key (AST *entry)
{
   if (entry->metatype == BTE_REGULAR &&
       entry->down && entry->down->nodetype == BTAST_KEY)
   {
      return entry->down->text;
   }
   else
   {
      return NULL;
   }
}


AST *bt_next_field (AST *entry, AST *prev, char **name)
{
   AST  *field;
   bt_metatype metatype;

   *name = NULL;
   if (!entry || !entry->down) return NULL; /* protect against empty entry */

   metatype = entry->metatype;
   if (metatype != BTE_MACRODEF && metatype != BTE_REGULAR)
      return NULL;

   if (prev == NULL)                    /* no previous field -- they must */ 
   {                                    /* want the first one */
      field = entry->down;
      if (metatype == BTE_REGULAR && field->nodetype == BTAST_KEY)
         field = field->right;          /* skip over citation key if present */
   }
   else                                 /* they really do want the next one */
   {
      field = prev->right;
   }

   if (!field) return NULL;             /* protect against field-less entry */
   if (name) *name = field->text;
   return field;
} /* bt_next_field() */


AST *bt_next_macro (AST *entry, AST *prev, char **name)
{
   return bt_next_field (entry, prev, name);
}


AST *bt_next_value (AST *top, AST *prev, bt_nodetype *nodetype, char **text)
{
   bt_nodetype nt;                    /* type of `top' node (to check) */
   bt_metatype mt;
   AST *         value;

   if (nodetype) *nodetype = BTAST_BOGUS;
   if (text) *text = NULL;

   if (!top) return NULL;
   /*   get_node_type (top, &nt, &mt); */
   nt = top->nodetype;
   mt = top->metatype;

   if ((nt == BTAST_FIELD) || 
       (nt == BTAST_ENTRY && (mt == BTE_COMMENT || mt == BTE_PREAMBLE)))
   {
      if (prev == NULL)                 /* no previous value -- give 'em */
      {                                 /* the first one */
         value = top->down;
         if (!value) return NULL;
         if (nodetype) *nodetype = value->nodetype;
      }
      else
      {
         value = prev->right;
         if (!value) return NULL;
         if (nodetype) *nodetype = value->nodetype;
      }

      if (nt == BTAST_ENTRY && value->nodetype != BTAST_STRING)
         internal_error ("found comment or preamble with non-string value");
   }
   else
   {
      value = NULL;
   }

   if (text && value) *text = value->text;

   return value;
} /* bt_next_value() */


char *bt_get_text (AST *node)
{
   ushort pp_options = BTO_FULL;        /* options for full processing: */
                                        /* expand macros, paste strings, */
                                        /* collapse whitespace */
   bt_nodetype nt;
   bt_metatype mt;

   nt = node->nodetype;
   mt = node->metatype;

   if (nt == BTAST_FIELD)
   {
#if DEBUG
      char   *value;

      dump_ast ("bt_get_text (pre): node =\n", node);
      value = bt_postprocess_field (node, pp_options, FALSE);
      dump_ast ("bt_get_text (post): node =\n", node);
      return value;
#else
      return bt_postprocess_field (node, pp_options, FALSE);
#endif
   }
   else if (nt == BTAST_ENTRY && (mt == BTE_COMMENT || mt == BTE_PREAMBLE))
   {
      return bt_postprocess_value (node->down, pp_options, FALSE);
   }
   else
   {
      return NULL;
   }
}
