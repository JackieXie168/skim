/* ------------------------------------------------------------------------
@NAME       : tex_tree.c
@DESCRIPTION: Functions for dealing with strings of TeX code: converting
              them to tree representation, traversing the trees to glean
              useful information, and converting back to string form.
@GLOBALS    : 
@CALLS      : 
@CALLERS    : 
@CREATED    : 1997/05/29, Greg Ward
@MODIFIED   : 
@VERSION    : $Id: tex_tree.c,v 1.4 1999/11/29 01:13:10 greg Rel $
@COPYRIGHT  : Copyright (c) 1996-99 by Gregory P. Ward.  All rights reserved.

              This file is part of the btparse library.  This library is
              free software; you can redistribute it and/or modify it under
              the terms of the GNU Library General Public License as
              published by the Free Software Foundation; either version 2
              of the License, or (at your option) any later version.
-------------------------------------------------------------------------- */

#include "bt_config.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "error.h"
#include "btparse.h"
#include "my_dmalloc.h"

/* blech! temp hack until I make error.c perfect and magical */
#define string_warning(w) fprintf (stderr, w);

typedef struct treestack_s
{
   bt_tex_tree * node;
   struct treestack_s
               * prev,
               * next;
} treestack;


/* ----------------------------------------------------------------------
 * Stack manipulation functions
 */

/* ------------------------------------------------------------------------
@NAME       : push_treestack()
@INPUT      : *stack
              node
@OUTPUT     : *stack
@RETURNS    : 
@DESCRIPTION: Creates and initializes new node in a stack, and pushes it
              onto the stack.
@GLOBALS    : 
@CALLS      : 
@CALLERS    : 
@CREATED    : 1997/05/29, GPW
@MODIFIED   : 
-------------------------------------------------------------------------- */
static void
push_treestack (treestack **stack, bt_tex_tree *node)
{
   treestack  *newtop;

   newtop = (treestack *) malloc (sizeof (treestack));
   newtop->node = node;
   newtop->next = NULL;
   newtop->prev = *stack;

   if (*stack != NULL)                  /* stack already has some entries */
   {
      (*stack)->next = newtop;
      *stack = newtop;
   }

   *stack = newtop;

} /* push_treestack() */


/* ------------------------------------------------------------------------
@NAME       : pop_treestack
@INPUT      : *stack
@OUTPUT     : *stack
@RETURNS    : 
@DESCRIPTION: Pops an entry off of a stack of tex_tree nodes, frees up
              the wrapper treestack node, and returns the popped tree node.
@GLOBALS    : 
@CALLS      : 
@CALLERS    : 
@CREATED    : 1997/05/29, GPW
@MODIFIED   : 
-------------------------------------------------------------------------- */
static bt_tex_tree *
pop_treestack (treestack **stack)
{
   treestack *   oldtop;
   bt_tex_tree * node;

   if (*stack == NULL)
      internal_error ("attempt to pop off empty stack");
   oldtop = (*stack)->prev;
   node = (*stack)->node;
   free (*stack);
   if (oldtop != NULL)
      oldtop->next = NULL;
   *stack = oldtop;
   return node;

} /* pop_treestack() */


/* ----------------------------------------------------------------------
 * Tree creation/destruction functions
 */

/* ------------------------------------------------------------------------
@NAME       : new_tex_tree
@INPUT      : start
@OUTPUT     : 
@RETURNS    : pointer to newly-allocated node
@DESCRIPTION: Allocates and initializes a bt_tex_tree node.
@GLOBALS    : 
@CALLS      : 
@CALLERS    : 
@CREATED    : 1997/05/29, GPW
@MODIFIED   : 
-------------------------------------------------------------------------- */
static bt_tex_tree *
new_tex_tree (char *start)
{
   bt_tex_tree * node;

   node = (bt_tex_tree *) malloc (sizeof (bt_tex_tree));
   node->start = start;
   node->len = 0;
   node->child = node->next = NULL;
   return node;
}


/* ------------------------------------------------------------------------
@NAME       : bt_build_tex_tree
@INPUT      : string
@OUTPUT     : 
@RETURNS    : pointer to a complete tree; call bt_free_tex_tree() to free
              the entire tree
@DESCRIPTION: Traverses a string looking for TeX groups ({...}), and builds
              a tree containing pointers into the string and describing
              its brace-structure.
@GLOBALS    : 
@CALLS      : 
@CALLERS    : 
@CREATED    : 1997/05/29, GPW
@MODIFIED   : 
-------------------------------------------------------------------------- */
bt_tex_tree *
bt_build_tex_tree (char * string)
{
   int     i;
   int     depth;
   int     len;
   bt_tex_tree
         * top,
         * cur,
         * new;
   treestack
         * stack;

   i = 0;
   depth = 0;
   len = strlen (string);
   top = new_tex_tree (string);
   stack = NULL;

   cur = top;
   
   while (i < len)
   {
      switch (string[i])
      {
         case '{':                      /* go one level deeper */
         {
            if (i == len-1)             /* open brace in last character? */
            {
               string_warning ("unbalanced braces: { at end of string");
               goto error;
            }

            new = new_tex_tree (string+i+1);
            cur->child = new;
            push_treestack (&stack, cur);
            cur = new;
            depth++;
            break;
         }
         case '}':                      /* pop level(s) off */
         {
            while (i < len && string[i] == '}')
            {
               if (stack == NULL)
               {
                  string_warning ("unbalanced braces: extra }");
                  goto error;
               }
               cur = pop_treestack (&stack);
               depth--;
               i++;
            }
            i--;

            if (i == len-1)             /* reached end of string? */
            {
               if (depth > 0)           /* but not at depth 0 */
               {
                  string_warning ("unbalanced braces: not enough }'s");
                  goto error;
               }

               /* 
                * if we get here, do nothing -- we've reached the end of 
                * the string and are at depth 0, so will just fall out
                * of the while loop at the end of this iteration
                */
            }
            else                        /* still have characters left */
            {                           /* to worry about */
               new = new_tex_tree (string+i+1);
               cur->next = new;
               cur = new;
            }

            break;
         }
         default:
         {
            cur->len++;
         }

      } /* switch */

      i++;

   } /* while i */

   if (depth > 0)
   {
      string_warning ("unbalanced braces (not enough }'s)");
      goto error;
   }

   return top;

error:
   bt_free_tex_tree (&top);
   return NULL;

} /* bt_build_tex_tree() */


/* ------------------------------------------------------------------------
@NAME       : bt_free_tex_tree
@INPUT      : *top
@OUTPUT     : *top (set to NULL after it's free()'d)
@RETURNS    : 
@DESCRIPTION: Frees up an entire tree created by bt_build_tex_tree().
@GLOBALS    : 
@CALLS      : itself, free()
@CALLERS    : 
@CREATED    : 1997/05/29, GPW
@MODIFIED   : 
-------------------------------------------------------------------------- */
void
bt_free_tex_tree (bt_tex_tree **top)
{
   if ((*top)->child) bt_free_tex_tree (&(*top)->child);
   if ((*top)->next) bt_free_tex_tree (&(*top)->next);
   free (*top);
   *top = NULL;
}



/* ----------------------------------------------------------------------
 * Tree traversal functions
 */

/* ------------------------------------------------------------------------
@NAME       : bt_dump_tex_tree
@INPUT      : node
              depth
              stream
@OUTPUT     : 
@RETURNS    : 
@DESCRIPTION: Dumps a TeX tree: one node per line, depth indented according
              to depth.
@GLOBALS    : 
@CALLS      : itself
@CALLERS    : 
@CREATED    : 1997/05/29, GPW
@MODIFIED   : 
-------------------------------------------------------------------------- */
void
bt_dump_tex_tree (bt_tex_tree *node, int depth, FILE *stream)
{
   char  buf[256];

   if (node == NULL)
      return;

   if (node->len > 255)
      internal_error ("augughgh! buf too small");
   strncpy (buf, node->start, node->len);
   buf[node->len] = (char) 0;

   fprintf (stream, "%*s[%s]\n", depth*2, "", buf);

   bt_dump_tex_tree (node->child, depth+1, stream);
   bt_dump_tex_tree (node->next, depth, stream);
   
}


/* ------------------------------------------------------------------------
@NAME       : count_length
@INPUT      : node
@OUTPUT     : 
@RETURNS    : 
@DESCRIPTION: Counts the total number of characters that will be needed
              to print a string reconstructed from a TeX tree.  (Length
              of string in each node, plus two [{ and }] for each down 
              edge.)
@GLOBALS    : 
@CALLS      : itself
@CALLERS    : bt_flatten_tex_tree
@CREATED    : 1997/05/29, GPW
@MODIFIED   : 
-------------------------------------------------------------------------- */
static int
count_length (bt_tex_tree *node)
{
   if (node == NULL) return 0;
   return
      node->len + 
      (node->child ? 2 : 0) +
      count_length (node->child) +
      count_length (node->next);
}


/* ------------------------------------------------------------------------
@NAME       : flatten_tree
@INPUT      : node
              *offset
@OUTPUT     : *buf
              *offset
@RETURNS    : 
@DESCRIPTION: Dumps a reconstructed string ("flat" representation of the 
              tree) into a pre-allocated buffer, starting at a specified
              offset.
@GLOBALS    : 
@CALLS      : itself
@CALLERS    : bt_flatten_tex_tree
@CREATED    : 1997/05/29, GPW
@MODIFIED   : 
-------------------------------------------------------------------------- */
static void
flatten_tree (bt_tex_tree *node, char *buf, int *offset)
{
   strncpy (buf + *offset, node->start, node->len);
   *offset += node->len;

   if (node->child)
   {
      buf[(*offset)++] = '{';
      flatten_tree (node->child, buf, offset);
      buf[(*offset)++] = '}';
   }

   if (node->next)
   {
      flatten_tree (node->next, buf, offset);
   }
}


/* ------------------------------------------------------------------------
@NAME       : bt_flatten_tex_tree
@INPUT      : top
@OUTPUT     : 
@RETURNS    : flattened string representation of the tree (as a string
              allocated with malloc(), so you should free() it when 
              you're done with it)
@DESCRIPTION: Counts the number of characters needed for a "flat"
              string representation of a tree, allocates a string of
              that size, and generates the string.
@GLOBALS    : 
@CALLS      : count_length, flatten_tree
@CALLERS    : 
@CREATED    : 1997/05/29, GPW
@MODIFIED   : 
-------------------------------------------------------------------------- */
char *
bt_flatten_tex_tree (bt_tex_tree *top)
{
   int    len;
   int    offset;
   char * buf;

   len = count_length (top);
   buf = (char *) malloc (sizeof (char) * (len+1));
   offset = 0;
   flatten_tree (top, buf, &offset);
   return buf;
}
