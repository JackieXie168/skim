/* ------------------------------------------------------------------------
@NAME       : macros.c
@DESCRIPTION: Front-end to the standard PCCTS symbol table code (sym.c)
              to abstract my "macro table".
@GLOBALS    : 
@CALLS      : 
@CREATED    : 1997/01/12, Greg Ward
@MODIFIED   : 
@VERSION    : $Id: macros.c,v 1.19 1999/11/29 01:13:10 greg Rel $
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
#include "sym.h"
#include "prototypes.h"
#include "error.h"
#include "my_dmalloc.h"
#include "bt_debug.h"


/*
 * NUM_MACROS and STRING_SIZE define the size of the static data
 * structure that holds the macro table.  The defaults are to allocate
 * 4096 bytes of string space that will be divided up amongst 547
 * macros.  This should be fine for most applications, but if you have a
 * big macro table you might need to change these and recompile (don't
 * forget to rebuild and reinstall Text::BibTeX if you're using it!).
 * You can set these as high as you like; just remember that a block of
 * STRING_SIZE bytes will be allocated and not freed as long as you're
 * using btparse.  Also, NUM_MACROS defines the size of a hashtable, so
 * it should probably be a prime a bit greater than a power of 2 -- or
 * something like that.  I'm not sure of the exact Knuthian
 * specification.
 */
#define NUM_MACROS 547
#define STRING_SIZE 4096

Sym *AllMacros = NULL;                  /* `scope' so we can get back list */
                                        /* of all macros when done */


GEN_PRIVATE_ERRFUNC (macro_warning,
                     (char * filename, int line, char * fmt, ...),
                     BTERR_CONTENT, filename, line, NULL, -1, fmt)


/* ------------------------------------------------------------------------
@NAME       : init_macros()
@INPUT      : 
@OUTPUT     : 
@RETURNS    : 
@DESCRIPTION: Initializes the symbol table used to store macro values.
@GLOBALS    : AllMacros
@CALLS      : zzs_init(), zzs_scope() (sym.c)
@CALLERS    : bt_initialize() (init.c)
@CREATED    : Jan 1997, GPW
-------------------------------------------------------------------------- */
void
init_macros (void)
{
   zzs_init (NUM_MACROS, STRING_SIZE);
   zzs_scope (&AllMacros);
}


/* ------------------------------------------------------------------------
@NAME       : done_macros()
@INPUT      : 
@OUTPUT     : 
@RETURNS    : 
@DESCRIPTION: Frees up all the macro values in the symbol table, and 
              then frees up the symbol table itself.
@GLOBALS    : AllMacros
@CALLS      : zzs_rmscope(), zzs_done()
@CALLERS    : bt_cleanup() (init.c)
@CREATED    : Jan 1997, GPW
-------------------------------------------------------------------------- */
void
done_macros (void)
{
   bt_delete_all_macros ();
   zzs_done ();
}


static void
delete_macro_entry (Sym * sym)
{
   Sym * cur;
   Sym * prev;

   /* 
    * Yechh!  All this mucking about with the scope list really
    * ought to be handled by the symbol table code.  Must write
    * my own someday.
    */

   /* Find this entry in the list of all macro table entries */
   cur = AllMacros;
   prev = NULL;
   while (cur != NULL && cur != sym)
   {
      prev = cur;
      cur = cur->scope;
   }

   if (cur == NULL)                     /* uh-oh -- wasn't found! */
   {
      internal_error ("macro table entry for \"%s\" not found in scope list",
                      sym->symbol);
   }

   /* Now unlink from the "scope" list */
   if (prev == NULL)                    /* it's the head of the list */
      AllMacros = cur->scope;
   else
      prev->scope = cur->scope;

   /* Remove it from the macro hash table */
   zzs_del (sym);

   /* And finally, free up the entry's text and the entry itself */
   if (sym->text) free (sym->text);
   free (sym);
} /* delete_macro_entry() */


/* ------------------------------------------------------------------------
@NAME       : bt_add_macro_value()
@INPUT      : assignment - AST node representing "macro = value"
              options    - string-processing options that were used to
                           process this string after parsing
@OUTPUT     : 
@RETURNS    : 
@DESCRIPTION: Adds a value to the symbol table used for macros.

              If the value was not already post-processed as a macro value
              (expand macros, paste substrings, but don't collapse 
              whitespace), then this post-processing is done before adding
              the macro text to the table.

              If the macro is already defined, a warning is printed and
              the old text is overridden.
@GLOBALS    : 
@CALLS      : bt_add_macro_text()
              bt_postprocess_field()
@CALLERS    : bt_postprocess_entry() (post_parse.c)
@CREATED    : Jan 1997, GPW
-------------------------------------------------------------------------- */
void
bt_add_macro_value (AST *assignment, ushort options)
{
   AST *   value;
   char *  macro;
   char *  text;
   boolean free_text;

   if (assignment == NULL || assignment->down == NULL) return;
   value = assignment->down;

   /* 
    * If the options that were used to process the macro's expansion text 
    * are anything other than BTO_MACRO, then we'll have to do it ourselves.
    */

   if ((options & BTO_STRINGMASK) != BTO_MACRO)
   {
      text = bt_postprocess_field (assignment, BTO_MACRO, FALSE);
      free_text = TRUE;                 /* because it's alloc'd by */
                                        /* bt_postprocess_field() */
   }
   else
   {
      /* 
       * First a sanity check to make sure that the presumed post-processing
       * had the desired effect.
       */

      if (value->nodetype != BTAST_STRING || value->right != NULL)
      {
         internal_error ("add_macro: macro value was not " 
                         "correctly preprocessed");
      }

      text = assignment->down->text;
      free_text = FALSE;
   }

   macro = assignment->text;
   bt_add_macro_text (macro, text, assignment->filename, assignment->line);
   if (free_text && text != NULL)
      free (text);

} /* bt_add_macro_value() */


/* ------------------------------------------------------------------------
@NAME       : bt_add_macro_text()
@INPUT      : macro - the name of the macro to define
              text  - the macro text
              filename, line - where the macro is defined; pass NULL
                for filename if no file, 0 for line if no line number
                (just used to generate warning message)
@OUTPUT     : 
@RETURNS    : 
@DESCRIPTION: Sets the text value for a macro.  If the macro is already
              defined, a warning is printed and the old value is overridden.
@GLOBALS    : 
@CALLS      : zzs_get(), zzs_newadd()
@CALLERS    : bt_add_macro_value()
              (exported from library)
@CREATED    : 1997/11/13, GPW (from code in bt_add_macro_value())
@MODIFIED   : 
-------------------------------------------------------------------------- */
void
bt_add_macro_text (char * macro, char * text, char * filename, int line)
{
   Sym * sym;
   Sym * new_rec;

#if DEBUG == 1
   printf ("adding macro \"%s\" = \"%s\"\n", macro, text);
#elif DEBUG >= 2
   printf ("add_macro: macro = %p (%s)\n"
           "            text = %p (%s)\n",
           macro, macro, text, text);
#endif

   if ((sym = zzs_get (macro)))
   {
      macro_warning (filename, line,
                     "overriding existing definition of macro \"%s\"", 
                     macro);
      delete_macro_entry (sym);
   }

   new_rec = zzs_newadd (macro);
   new_rec->text = (text != NULL) ? strdup (text) : NULL;
   DBG_ACTION
      (2, printf ("           saved = %p (%s)\n",
                  new_rec->text, new_rec->text);)

} /* bt_add_macro_text() */


/* ------------------------------------------------------------------------
@NAME       : bt_delete_macro()
@INPUT      : macro - name of macro to delete
@DESCRIPTION: Deletes a macro from the macro table.
@CALLS      : zzs_get()
@CALLERS    : 
@CREATED    : 1998/03/01, GPW
@MODIFIED   : 
-------------------------------------------------------------------------- */
void
bt_delete_macro (char * macro)
{
   Sym * sym;

   sym = zzs_get (macro);
   if (! sym) return;
   delete_macro_entry (sym);
}


/* ------------------------------------------------------------------------
@NAME       : bt_delete_all_macros()
@DESCRIPTION: Deletes all macros from the macro table.
@CALLS      : zzs_rmscore()
@CALLERS    : 
@CREATED    : 1998/03/01, GPW
@MODIFIED   : 
-------------------------------------------------------------------------- */
void
bt_delete_all_macros (void)
{
   Sym  *cur, *next;

   DBG_ACTION (2, printf ("bt_delete_all_macros():\n");)

   /* 
    * Use the current `scope' (same one for all macros) to get access to
    * a linked list of all macros.  Then traverse the list, free()'ing
    * both the text (which was strdup()'d in add_macro(), below) and 
    * the records themselves (which are calloc()'d by zzs_new()).
    */

   cur = zzs_rmscope (&AllMacros);
   while (cur != NULL)
   {
      DBG_ACTION
         (2, printf ("  freeing macro \"%s\" (%p=\"%s\") at %p\n",
                     cur->symbol, cur->text, cur->text, cur);)

      next = cur->scope;
      if (cur->text != NULL) free (cur->text);
      free (cur);
      cur = next;
   }
}


/* ------------------------------------------------------------------------
@NAME       : bt_macro_length()
@INPUT      : macro - the macro name
@OUTPUT     : 
@RETURNS    : length of the macro's text, or zero if the macro is undefined
@DESCRIPTION: Returns length of a macro's text.
@GLOBALS    : 
@CALLS      : zzs_get()
@CALLERS    : bt_postprocess_value()
              (exported from library)
@CREATED    : Jan 1997, GPW
-------------------------------------------------------------------------- */
int
bt_macro_length (char *macro)
{
   Sym   *sym;

   DBG_ACTION
      (2, printf ("bt_macro_length: looking up \"%s\"\n", macro);)

   sym = zzs_get (macro);
   if (sym)
      return strlen (sym->text);
   else
      return 0;   
}


/* ------------------------------------------------------------------------
@NAME       : bt_macro_text()
@INPUT      : macro - the macro name
              filename, line - where the macro was invoked; NULL for
                `filename' and zero for `line' if not applicable
@OUTPUT     : 
@RETURNS    : The text of the macro, or NULL if it's undefined. 
@DESCRIPTION: Fetches a macros text; prints warning and returns NULL if 
              macro is undefined.
@CALLS      : zzs_get()
@CALLERS    : bt_postprocess_value()
@CREATED    : Jan 1997, GPW
-------------------------------------------------------------------------- */
char *
bt_macro_text (char * macro, char * filename, int line)
{
   Sym *  sym;

   DBG_ACTION
      (2, printf ("bt_macro_text: looking up \"%s\"\n", macro);)

   sym = zzs_get (macro);
   if (!sym)
   {
      macro_warning (filename, line, "undefined macro \"%s\"", macro);
      return NULL;
   }

   return sym->text;
}
