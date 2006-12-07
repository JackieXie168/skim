/* ------------------------------------------------------------------------
@NAME       : input.c
@DESCRIPTION: Routines for input of BibTeX data.
@GLOBALS    : InputFilename
              StringOptions
@CALLS      : 
@CREATED    : 1997/10/14, Greg Ward (from code in bibparse.c)
@MODIFIED   : 
@VERSION    : $Id: input.c,v 1.18 1999/11/29 01:13:10 greg Rel $
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
#include <limits.h>
#include <assert.h>
#include "stdpccts.h"
#include "lex_auxiliary.h"
#include "prototypes.h"
#include "error.h"
#include "my_dmalloc.h"


char *   InputFilename;
ushort   StringOptions[NUM_METATYPES] = 
{
   0,                                   /* BTE_UNKNOWN */
   BTO_FULL,                            /* BTE_REGULAR */
   BTO_MINIMAL,                         /* BTE_COMMENT */
   BTO_MINIMAL,                         /* BTE_PREAMBLE */
   BTO_MACRO                            /* BTE_MACRODEF */
};


/* ------------------------------------------------------------------------
@NAME       : bt_set_filename
@INPUT      : filename
@OUTPUT     : 
@RETURNS    : 
@DESCRIPTION: Sets the current input filename -- used for generating
              error and warning messages.
@GLOBALS    : InputFilename
@CALLS      : 
@CREATED    : Feb 1997, GPW
@MODIFIED   : 
-------------------------------------------------------------------------- */
#if 0
void bt_set_filename (char *filename)
{
   InputFilename = filename;
}
#endif

/* ------------------------------------------------------------------------
@NAME       : bt_set_stringopts
@INPUT      : metatype
              options
@OUTPUT     : 
@RETURNS    : 
@DESCRIPTION: Sets the string-processing options for a particular 
              entry metatype.  Used later on by bt_parse_* to determine
              just how to post-process each particular entry.
@GLOBALS    : StringOptions
@CREATED    : 1997/08/24, GPW
@MODIFIED   : 
-------------------------------------------------------------------------- */
void bt_set_stringopts (bt_metatype metatype, ushort options)
{
   if (metatype < BTE_REGULAR || metatype > BTE_MACRODEF)
      usage_error ("bt_set_stringopts: illegal metatype");
   if (options & ~BTO_STRINGMASK)
      usage_error ("bt_set_stringopts: illegal options "
                   "(must only set string option bits");

   StringOptions[metatype] = options;
}


/* ------------------------------------------------------------------------
@NAME       : start_parse
@INPUT      : infile     input stream we'll read from (or NULL if reading 
                         from string)
              instring   input string we'll read from (or NULL if reading
                         from stream)
              line       line number of the start of the string (just
                         use 1 if the string is standalone and independent;
                         if it comes from a file, you should supply the
                         line number where it starts for better error
                         messages) (ignored if infile != NULL)
@OUTPUT     : 
@RETURNS    : 
@DESCRIPTION: Prepares things for parsing, in particular initializes the 
              lexical state and lexical buffer, prepares DLG for
              reading (either from a stream or a string), and reads
              the first token.
@GLOBALS    : 
@CALLS      : initialize_lexer_state()
              alloc_lex_buffer()
              zzrdstream() or zzrdstr()
              zzgettok()
@CALLERS    : 
@CREATED    : 1997/06/21, GPW
@MODIFIED   : 
-------------------------------------------------------------------------- */
static void
start_parse (FILE *infile, char *instring, int line)
{
   if ( (infile == NULL) == (instring == NULL) )
   {
      internal_error ("start_parse(): exactly one of infile and "
                      "instring may be non-NULL");
   }
   initialize_lexer_state ();
   alloc_lex_buffer (ZZLEXBUFSIZE);
   if (infile)
   {
      zzrdstream (infile);
   }
   else
   {
      zzrdstr (instring);
      zzline = line;
   }
      
   zzendcol = zzbegcol = 0;
   zzgettok ();
}



/* ------------------------------------------------------------------------
@NAME       : finish_parse()
@INPUT      : err_counts - pointer to error count list (which is local to
                           the parsing functions, hence has to be passed in)
@OUTPUT     : 
@RETURNS    : 
@DESCRIPTION: Frees up what was needed to parse a whole file or a sequence
              of strings: the lexical buffer and the error count list.
@GLOBALS    : 
@CALLS      : free_lex_buffer()
@CALLERS    : 
@CREATED    : 1997/06/21, GPW
@MODIFIED   : 
-------------------------------------------------------------------------- */
static void
finish_parse (int **err_counts)
{
   free_lex_buffer ();
   free (*err_counts);
   *err_counts = NULL;
}


/* ------------------------------------------------------------------------
@NAME       : parse_status()
@INPUT      : saved_counts
@OUTPUT     : 
@RETURNS    : false if there were serious errors in the recently-parsed input
              true otherwise (no errors or just warnings)
@DESCRIPTION: Gets the "error status" bitmap relative to a saved set of
              error counts and masks of non-serious errors.
@GLOBALS    : 
@CALLS      : 
@CALLERS    : 
@CREATED    : 1997/06/21, GPW
@MODIFIED   : 
-------------------------------------------------------------------------- */
static boolean
parse_status (int *saved_counts)
{
   ushort        ignore_emask;

   /* 
    * This bit-twiddling fetches the error status (which has a bit
    * for each error class), masks off the bits for trivial errors
    * to get "true" if there were any serious errors, and then 
    * returns the opposite of that.
    */
   ignore_emask =
      (1<<BTERR_NOTIFY) | (1<<BTERR_CONTENT) | (1<<BTERR_LEXWARN);
   return !(bt_error_status (saved_counts) & ~ignore_emask);
}   


/* ------------------------------------------------------------------------
@NAME       : bt_parse_entry_s()
@INPUT      : entry_text - string containing the entire entry to parse,
                           or NULL meaning we're done, please cleanup
              options    - standard btparse options bitmap
              line       - current line number (if that makes any sense)
                           -- passed to the parser to set zzline, so that
                           lexical and syntax errors are properly localized
@OUTPUT     : *top       - newly-allocated AST for the entry
                           (or NULL if entry_text was NULL, ie. at EOF)
@RETURNS    : 1 with *top set to AST for entry on successful read/parse
              1 with *top==NULL if entry_text was NULL, ie. at EOF
              0 if any serious errors seen in input (*top is still 
                set to the AST, but only for as much of the input as we
                were able to parse)
              (A "serious" error is a lexical or syntax error; "trivial"
              errors such as warnings and notifications count as "success"
              for the purposes of this function's return value.)
@DESCRIPTION: Parses a BibTeX entry contained in a string.
@GLOBALS    : 
@CALLS      : ANTLR
@CREATED    : 1997/01/18, GPW (from code in bt_parse_entry())
@MODIFIED   : 
-------------------------------------------------------------------------- */
AST * bt_parse_entry_s (char *    entry_text,
                        char *    filename,
                        int       line,
                        ushort    options,
                        boolean * status)
{
   AST *        entry_ast = NULL;
   static int * err_counts = NULL;

   if (options & BTO_STRINGMASK)        /* any string options set? */
   {
      usage_error ("bt_parse_entry_s: illegal options "
                   "(string options not allowed");
   }

   InputFilename = filename;
   err_counts = bt_get_error_counts (err_counts);

   if (entry_text == NULL)              /* signal to clean up */
   {
      finish_parse (&err_counts);
      if (status) *status = TRUE;
      return NULL;
   }

   zzast_sp = ZZAST_STACKSIZE;          /* workaround apparent pccts bug */
   start_parse (NULL, entry_text, line);

   entry (&entry_ast);                  /* enter the parser */
   ++zzasp;                             /* why is this done? */

   if (entry_ast == NULL)               /* can happen with very bad input */
   {
      if (status) *status = FALSE;
      return entry_ast;
   }

#if DEBUG
   dump_ast ("bt_parse_entry_s: single entry, after parsing:\n", 
             entry_ast);
#endif
   bt_postprocess_entry (entry_ast,
                         StringOptions[entry_ast->metatype] | options);
#if DEBUG
   dump_ast ("bt_parse_entry_s: single entry, after post-processing:\n",
             entry_ast);
#endif

   if (status) *status = parse_status (err_counts);
   return entry_ast;

} /* bt_parse_entry_s () */


/* ------------------------------------------------------------------------
@NAME       : bt_parse_entry()
@INPUT      : infile  - file to read next entry from
              options - standard btparse options bitmap
@OUTPUT     : *top    - AST for the entry, or NULL if no entries left in file
@RETURNS    : same as bt_parse_entry_s()
@DESCRIPTION: Starts (or continues) parsing from a file.
@GLOBALS    : 
@CALLS      : 
@CREATED    : Jan 1997, GPW
@MODIFIED   : 
-------------------------------------------------------------------------- */
AST * bt_parse_entry (FILE *    infile,
                      char *    filename,
                      ushort    options,
                      boolean * status)
{
   AST *         entry_ast = NULL;
   static int *  err_counts = NULL;
   static FILE * prev_file = NULL;

   if (prev_file != NULL && infile != prev_file)
   {
      usage_error ("bt_parse_entry: you can't interleave calls "
                   "across different files");
   }

   if (options & BTO_STRINGMASK)        /* any string options set? */
   {
      usage_error ("bt_parse_entry: illegal options "
                   "(string options not allowed)");
   }

   InputFilename = filename;
   err_counts = bt_get_error_counts (err_counts);

   if (feof (infile))
   {
      if (prev_file != NULL)            /* haven't already done the cleanup */
      {
         prev_file = NULL;
         finish_parse (&err_counts);
      }
      else
      {
         usage_warning ("bt_parse_entry: second attempt to read past eof");
      }

      if (status) *status = TRUE;
      return NULL;
   }

   /* 
    * Here we do some nasty poking about the innards of PCCTS in order to
    * enter the parser multiple times on the same input stream.  This code
    * comes from expanding the macro invokation:
    * 
    *    ANTLR (entry (top), infile);  
    * 
    * When LL_K, ZZINF_LOOK, and DEMAND_LOOK are all undefined, this
    * ultimately expands to
    * 
    *    zzbufsize = ZZLEXBUFSIZE;
    *    {
    *       static char zztoktext[ZZLEXBUFSIZE];
    *       zzlextext = zztoktext; 
    *       zzrdstream (f);
    *       zzgettok();
    *    }
    *    entry (top);
    *    ++zzasp;
    * 
    * (I'm expanding hte zzenterANTLR, zzleaveANTLR, and zzPrimateLookAhead
    * macros, but leaving ZZLEXBUFSIZE -- a simple constant -- alone.)
    * 
    * There are two problems with this: 1) zztoktext is a statically
    * allocated buffer, and when it overflows we just ignore further
    * characters that should belong to that lexeme; and 2) zzrdstream() and
    * zzgettok() are called every time we enter the parser, which means the
    * token left over from the previous entry will be discarded when we
    * parse entries 2 .. N.
    * 
    * I handle the static buffer problem with alloc_lex_buffer() and
    * realloc_lex_buffer() (in lex_auxiliary.c), and by rewriting the ZZCOPY
    * macro to call realloc_lex_buffer() when overflow is detected.
    * 
    * I handle the extra token-read by hanging on to a static file
    * pointer, prev_file, between calls to bt_parse_entry() -- when
    * the program starts it is NULL, and we reset it to NULL on
    * finishing a file.  Thus, any call that is the first on a given
    * file will allocate the lexical buffer and read the first token;
    * thereafter, we skip those steps, and free the buffer on reaching
    * end-of-file.  Currently, this method precludes interleaving
    * calls to bt_parse_entry() on different files -- perhaps I could
    * fix this with the zz{save,restore}_{antlr,dlg}_state()
    * functions?
    */

   zzast_sp = ZZAST_STACKSIZE;          /* workaround apparent pccts bug */

#if defined(LL_K) || defined(ZZINF_LOOK) || defined(DEMAND_LOOK)
# error One of LL_K, ZZINF_LOOK, or DEMAND_LOOK was defined
#endif
   if (prev_file == NULL)               /* only read from input stream if */
   {                                    /* starting afresh with a file */
      start_parse (infile, NULL, 0);
      prev_file = infile;
   }
   assert (prev_file == infile);

   entry (&entry_ast);                  /* enter the parser */
   ++zzasp;                             /* why is this done? */

   if (entry_ast == NULL)               /* can happen with very bad input */
   {
      if (status) *status = FALSE;
      return entry_ast;
   }

#if DEBUG
   dump_ast ("bt_parse_entry(): single entry, after parsing:\n", 
             entry_ast);
#endif
   bt_postprocess_entry (entry_ast,
                         StringOptions[entry_ast->metatype] | options);
#if DEBUG
   dump_ast ("bt_parse_entry(): single entry, after post-processing:\n", 
             entry_ast);
#endif

   if (status) *status = parse_status (err_counts);
   return entry_ast;

} /* bt_parse_entry() */


/* ------------------------------------------------------------------------
@NAME       : bt_parse_file ()
@INPUT      : filename - name of file to open.  If NULL or "-", we read
                         from stdin rather than opening a new file.
              options
@OUTPUT     : top
@RETURNS    : 0 if any entries in the file had serious errors
              1 if all entries were OK
@DESCRIPTION: Parses an entire BibTeX file, and returns a linked list 
              of ASTs (or, if you like, a forest) for the entries in it.
              (Any entries with serious errors are omitted from the list.)
@GLOBALS    : 
@CALLS      : bt_parse_entry()
@CREATED    : 1997/01/18, from process_file() in bibparse.c
@MODIFIED   : 
@COMMENTS   : This function bears a *striking* resemblance to bibparse.c's
              process_file().  Eventually, I plan to replace this with 
              a generalized process_file() that takes a function pointer
              to call for each entry.  Until I decide on the right interface
              for that, though, I'm sticking with this simpler (but possibly
              memory-intensive) approach.
-------------------------------------------------------------------------- */
AST * bt_parse_file (char *    filename, 
                     ushort    options, 
                     boolean * status)
{
   FILE *  infile;
   AST *   entries,
       *   cur_entry, 
       *   last;
   boolean entry_status,
           overall_status;

   if (options & BTO_STRINGMASK)        /* any string options set? */
   {
      usage_error ("bt_parse_file: illegal options "
                   "(string options not allowed");
   }

   /*
    * If a string was given, and it's *not* "-", then open that filename.
    * Otherwise just use stdin.
    */

   if (filename != NULL && strcmp (filename, "-") != 0)
   {
      InputFilename = filename;
      infile = fopen (filename, "r");
      if (infile == NULL)
      {
         perror (filename);
         return 0;
      }
   }
   else
   {
      InputFilename = "(stdin)";
      infile = stdin;
   }

   entries = NULL;
   last = NULL;
      
#if 1
   /* explicit loop over entries, with junk cleaned out by read_entry () */

   overall_status = TRUE;              /* assume success */
   while ((cur_entry = bt_parse_entry
          (infile, InputFilename, options, &entry_status)))
   {
      overall_status &= entry_status;
      if (!entry_status) continue;      /* bad entry -- try next one */
      if (!cur_entry) break;            /* at eof -- we're done */
      if (last == NULL)                 /* this is the first entry */
         entries = cur_entry;
      else                              /* have already seen one */
         last->right = cur_entry;

      last = cur_entry;
   }

#else
   /* let the PCCTS lexer/parser handle everything */

   initialize_lexer_state ();
   ANTLR (bibfile (top), infile);

#endif

   fclose (infile);
   InputFilename = NULL;
   if (status) *status = overall_status;
   return entries;

} /* bt_parse_file() */
