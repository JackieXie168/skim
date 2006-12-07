/* ------------------------------------------------------------------------
@NAME       : postprocess.c
@DESCRIPTION: Operations applied to the AST (or strings in it) after 
              parsing is complete.
@GLOBALS    : 
@CALLS      : 
@CREATED    : 1997/01/12, Greg Ward (from code in bibparse.c, lex_auxiliary.c)
@MODIFIED   : 
@VERSION    : $Id: postprocess.c,v 1.25 2000/05/02 23:06:31 greg Exp $
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
#include <assert.h>
#include "btparse.h"
#include "error.h"
#include "parse_auxiliary.h"
#include "prototypes.h"
#include "my_dmalloc.h"

#define DEBUG 1


/* ------------------------------------------------------------------------
@NAME       : bt_postprocess_string ()
@INPUT      : s
              options
@OUTPUT     : s (modified in place according to the flags)
@RETURNS    : (void)
@DESCRIPTION: Make a pass over string s (which is modified in-place) to
              optionally collapse whitespace according to BibTeX rules
              (if the BTO_COLLAPSE bit in options is true).

              Rules for collapsing whitespace are:
                 * whitespace at beginning/end of string is deleted
                 * within the string, each whitespace sequence is replaced by
                   a single space

              Note that part of the work is done by the lexer proper,
              namely conversion of tabs and newlines to spaces.
@GLOBALS    : 
@CALLS      : 
@CREATED    : originally in lex_auxiliary.c; moved here 1997/01/12
@MODIFIED   : 
@COMMENTS   : this only collapses whitespace now -- rename it???
-------------------------------------------------------------------------- */
void 
bt_postprocess_string (char * s, ushort options)
{
   boolean collapse_whitespace;
   char *i, *j;
   int   len;

   if (s == NULL) return;               /* quit if no string supplied */

#if DEBUG > 1
   printf ("bt_postprocess_string: looking at >%s<\n", s);
#endif

   /* Extract any relevant options (just one currently) to local flags. */
   collapse_whitespace = options & BTO_COLLAPSE;

   /*
    * N.B. i and j will both point into s; j is always >= i, and
    * we copy characters from j to i.  Whitespace is collapsed/deleted
    * by advancing j without advancing i.
    */
   i = j = s;                           /* start both at beginning of string */

   /*
    * If we're supposed to collapse whitespace, then advance j to the
    * first non-space character.
    */
   if (collapse_whitespace)
   {
      while (*j == ' ' && *j != (char) 0)
         j++;
   }

   while (*j != (char) 0)
   {
      /*
       * If we're in a string of spaces (ie. current and previous char.
       * are both space), and we're supposed to be collapsing whitespace,
       * then skip until we hit a non-space character (or end of string).
       */
      if (collapse_whitespace && *j == ' ' && *(j-1) == ' ') 
      {
         while (*j == ' ') j++;         /* skip spaces */
         if (*j == (char) 0)            /* reached end of string? */
            break;
      }

      /* Copy the current character from j down to i */
      *(i++) = *(j++);
   }
   *i = (char) 0;                       /* ensure string is terminated */


   /*
    * And mop up whitespace (if any) at end of string -- note that if there
    * was any whitespace there, it has already been collapsed to exactly
    * one space.
    */
   len = strlen (s);
   if (len > 0 && collapse_whitespace && s[len-1] == ' ')
   {
      s[--len] = (char) 0;
   }

#if DEBUG > 1
   printf ("                transformed to >%s<\n", s);
#endif

} /* bt_postprocess_string */


/* ------------------------------------------------------------------------
@NAME       : bt_postprocess_value()
@INPUT      : 
@OUTPUT     : 
@RETURNS    : 
@DESCRIPTION: Post-processes a series of strings (compound value),
              frequently found as the value of a "field = value" or "macro
              = value" assignment.  The actions taken here are governed by
              the bits in 'options', but there are two distinct modes of
              operation: pasting or not.  

              We paste strings if and only if the BTO_PASTE bit in options
              is set and there are two or more simple values in the
              compound value.  In this case, the BTO_EXPAND bit must be set
              (it would be very silly to paste together strings with
              unexpanded macro names!), and we make two passes over the
              data: one to postprocess individual strings and accumulate
              the one big string, and a second to postprocess the big
              string.  In the first pass, the caller-supplied 'options'
              variable is largely ignored; we will never collapse
              whitespace in the individual strings.  The caller's wishes
              are fully respected when we make the final post-processing
              pass over the concatenation of the individual strings,
              though.

              If we're not pasting strings, then the character of the
              individual simple values will be preserved; macros might not
              be expanded (depending on the BTO_EXPAND bit), numbers will
              stay numbers, and strings will be post-processed
              independently according to the 'options' variable.  (Beware
              -- this means you might collapse whitespace in individual
              sub-strings, which would be bad if you intend to concatenate
              them later in the BibTeX sense.)

              The 'replace' parameter is used to govern whether the
              existing strings in the AST should be replaced with their
              post-processed versions.  This can extend as far as
              collapsing a series of simple values into a single BTAST_STRING
              node, if we paste sub-strings together.  If replace is FALSE,
              the returned string is allocated here, and you must free() it
              later.
@GLOBALS    : 
@CALLS      : 
@CREATED    : 1997/01/10, GPW
@MODIFIED   : 1997/08/25, GPW: renamed from bt_postprocess_field(), and changed
                               to take the head of a list of simple values,
                               rather than the parent of that list
-------------------------------------------------------------------------- */
char *
bt_postprocess_value (AST * value, ushort options, boolean replace)
{
   AST *   simple_value;                /* current simple value */
   boolean pasting;
   ushort  string_opts;                 /* what to do to individual strings */
   int     tot_len;                     /* total length of pasted string */
   char *  new_string;                  /* in case of string pasting */
   char *  tmp_string;
   boolean free_tmp;                    /* should we free() tmp_string? */

   if (value == NULL) return NULL;
   if (value->nodetype != BTAST_STRING &&
       value->nodetype != BTAST_NUMBER &&
       value->nodetype != BTAST_MACRO)
   {
      usage_error ("bt_postprocess_value: invalid AST node (not a value)");
   }
      

   /* 
    * We will paste strings iff the user wants us to, and there are at least
    * two simple values in the list headed by 'value'.
    */

   pasting = (options & BTO_PASTE) && (value->right);

   /* 
    * If we're to concatenate (paste) sub-strings, we need to know the
    * total length of them.  So make a pass over all the sub-strings
    * (simple values), adding up their lengths.
    */

   tot_len = 0;                         /* these are out here to keep */
   new_string = NULL;                   /* gcc -Wall happy */
   tmp_string = NULL;

   if (pasting)
   {
      simple_value = value;
      while (simple_value)
      {
         switch (simple_value->nodetype)
         {
            case BTAST_MACRO:
               tot_len += bt_macro_length (simple_value->text);
               break;
            case BTAST_STRING:
               tot_len += (simple_value->text) 
                  ? (strlen (simple_value->text)) : 0;
               break;
            case BTAST_NUMBER:
               tot_len += (simple_value->text)
                  ? (strlen (simple_value->text)) : 0;
               break;
            default:
               internal_error ("simple value has bad nodetype (%d)",
                               (int) simple_value->nodetype);
         }
         simple_value = simple_value->right;
      }

      /* Now allocate the buffer in which we'll accumulate the whole string */

      new_string = (char *) calloc (tot_len+1, sizeof (char));
   }


   /* 
    * Before entering the main loop, figure out just what
    * bt_postprocess_string() is supposed to do -- eg. if pasting strings,
    * we should not (yet) collapse whitespace.  (That'll be done on the
    * final, concatenated string -- assuming the caller put BTO_COLLAPSE in
    * the options bitmap.)
    */

   if (pasting)
   {
      string_opts = options & ~BTO_COLLAPSE;     /* turn off collapsing */
   }
   else
   {
      string_opts = options;            /* leave it alone */
   }

   /*
    * Sanity check: if we continue blindly on, we might stupidly
    * concatenate a macro name and a literal string.  So check for that.
    * Converting numbers is superficial, but requiring that it be done
    * keeps people honest.
    */

   if (pasting && ! (options & (BTO_CONVERT|BTO_EXPAND)))
   {
      usage_error ("bt_postprocess_value(): "
                   "must convert numbers and expand macros " 
                   "when pasting substrings");
   }

   /*
    * Now the main loop to process each string, and possibly tack it onto
    * new_string.
    */

   simple_value = value;
   while (simple_value)
   {
      tmp_string = NULL;
      free_tmp = FALSE;

      /* 
       * If this simple value is a macro and we're supposed to expand
       * macros, then do so.  We also have to post-process the string
       * returned from the macro table, because they're stored there
       * without whitespace collapsed; if we're supposed to be doing that
       * to the current value (and we're not pasting), this is where it
       * will get done.
       */
      if (simple_value->nodetype == BTAST_MACRO && (options & BTO_EXPAND))
      {
         tmp_string = bt_macro_text (simple_value->text, 
                                     simple_value->filename,
                                     simple_value->line);
         if (tmp_string != NULL)
         {
            tmp_string = strdup (tmp_string);
            free_tmp = TRUE;
            bt_postprocess_string (tmp_string, string_opts);
         }

         if (replace)
         {
            simple_value->nodetype = BTAST_STRING;
            if (simple_value->text)
               free (simple_value->text);
            simple_value->text = tmp_string;
            free_tmp = FALSE;           /* mustn't free, it's now in the AST */
         }
      }

      /* 
       * If the current simple value is a literal string, then just 
       * post-process it.  This will be done in-place if 'replace' is
       * true, otherwise a copy of the string will be post-processed.
       */
      else if (simple_value->nodetype == BTAST_STRING && simple_value->text)
      {
         if (replace)
         {
            tmp_string = simple_value->text;
         }
         else
         {
            tmp_string = strdup (simple_value->text);
            free_tmp = TRUE;
         }

         bt_postprocess_string (tmp_string, string_opts);
      }

      /*
       * Finally, if the current simple value is a number, change it to a
       * string (depending on options) and get its value.  We generally
       * treat strings as numbers as equivalent, except of course numbers
       * aren't post-processed -- there can't be any whitespace in them!
       * The BTO_CONVERT option is mainly a sop to my strong-typing
       * tendencies.
       */
      if (simple_value->nodetype == BTAST_NUMBER)
      {
         if (replace && (options & BTO_CONVERT))
            simple_value->nodetype = BTAST_STRING;

         if (simple_value->text)
         {
            if (replace)
               tmp_string = simple_value->text;
            else
            {
               tmp_string = strdup (simple_value->text);
               free_tmp = TRUE;
            }
         }
      }

      if (pasting)
      {
         if (tmp_string)
            strcat (new_string, tmp_string);
         if (free_tmp)
            free (tmp_string);
      }
      else
      {
         /* 
          * N.B. if tmp_string is NULL (eg. from a single undefined macro)
          * we make a strdup() of the empty string -- this is so we can
          * safely free() the string returned from this function
          * at some future point.
          *
          * This strdup() seems to cause a 1-byte memory leak in some
          * circumstances.  I s'pose I should look into that some rainy
          * afternoon...
          */

         new_string = (tmp_string != NULL) ? tmp_string : strdup ("");
      }

      simple_value = simple_value->right;
   }

   if (pasting)
   {
      int    len;

      len = strlen (new_string);
      assert (len <= tot_len);          /* hope we alloc'd enough! */

      bt_postprocess_string (new_string, options);

      /* 
       * If replacing data in the AST, delete all but first child of
       * `field', and replace text for first child with new_string.
       */

      if (replace)
      {
         assert (value->right != NULL); /* there has to be > 1 simple value! */
         zzfree_ast (value->right);     /* free from second simple value on */
         value->right = NULL;           /* remind ourselves they're gone */
         if (value->text)               /* free text of first simple value */
            free (value->text);
         value->text = new_string;      /* and replace it with concatenation */
      }
   }

   return new_string;
   
} /* bt_postprocess_value() */


/* ------------------------------------------------------------------------
@NAME       : bt_postprocess_field()
@INPUT      : 
@OUTPUT     : 
@RETURNS    : 
@DESCRIPTION: Postprocesses all the strings in a single "field = value"
              assignment subtree.  Just checks that 'field' does indeed
              point to an BTAST_FIELD node (presumably the parent of a list
              of simple values), downcases the field name, and calls
              bt_postprocess_value() on the value.
@GLOBALS    : 
@CALLS      : 
@CALLERS    : 
@CREATED    : 1997/08/25, GPW
@MODIFIED   : 
-------------------------------------------------------------------------- */
char *
bt_postprocess_field (AST * field, ushort options, boolean replace)
{
   if (field == NULL) return NULL;
   if (field->nodetype != BTAST_FIELD)
      usage_error ("bt_postprocess_field: invalid AST node (not a field)");

   strlwr (field->text);                /* downcase field name */
   return bt_postprocess_value (field->down, options, replace);

} /* bt_postprocess_field() */



/* ------------------------------------------------------------------------
@NAME       : bt_postprocess_entry() 
@INPUT      : 
@OUTPUT     : 
@RETURNS    : 
@DESCRIPTION: Postprocesses all the strings in an entry: collapse whitespace,
              concatenate substrings, expands macros, and whatnot.
@GLOBALS    : 
@CALLS      : 
@CREATED    : 1997/01/10, GPW
@MODIFIED   : 
-------------------------------------------------------------------------- */
void
bt_postprocess_entry (AST * top, ushort options)
{
   AST   *cur;
   
   if (top == NULL) return;     /* not even an entry at all! */
   if (top->nodetype != BTAST_ENTRY)
      usage_error ("bt_postprocess_entry: "
                   "invalid node type (not entry root)");
   strlwr (top->text);          /* downcase entry type */

   if (top->down == NULL) return; /* no children at all */
   
   cur = top->down;
   if (cur->nodetype == BTAST_KEY)
      cur = cur->right;

   switch (top->metatype)
   {
      case BTE_REGULAR:
      case BTE_MACRODEF:
      {
         while (cur)
         {
            bt_postprocess_field (cur, options, TRUE);
            if (top->metatype == BTE_MACRODEF && ! (options & BTO_NOSTORE))
               bt_add_macro_value (cur, options);

            cur = cur->right;
         }
         break;
      }

      case BTE_COMMENT:
      case BTE_PREAMBLE:
         bt_postprocess_value (cur, options, TRUE);
         break;
      default:
         internal_error ("bt_postprocess_entry: unknown entry metatype (%d)",
                         (int) top->metatype);
   }

} /* bt_postprocess_entry() */
