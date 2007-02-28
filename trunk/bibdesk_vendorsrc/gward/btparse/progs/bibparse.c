/* ------------------------------------------------------------------------
@NAME       : bibparse.c
@DESCRIPTION: Parses a series of BibTeX files, with command-line options
              to control the string post-processing behaviour of the
              library.  Prints the parsed entries out in a slightly
              different form that should be dead easy to parse in any
              language (most punctuation and whitespace gone, format is
              fixed and strictly line-based).
@GLOBALS    : 
@CREATED    : May 1996, Greg Ward
@MODIFIED   : 
@VERSION    : $Id: bibparse.c,v 1.24 1998/03/14 16:39:16 greg Rel $
@COPYRIGHT  : Copyright (c) 1996-97 by Gregory P. Ward.  All rights reserved.

              This file is part of the btparse distribution (but not part
              of the library itself).  This is free software; you can
              redistribute it and/or modify it under the terms of the GNU
              General Public License as published by the Free Software
              Foundation; either version 2 of the License, or (at your
              option) any later version.
-------------------------------------------------------------------------- */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <limits.h>
#include <stdarg.h>
#include <assert.h>
#include <btparse.h>

#include "getopt.h"                     /* for optind */
#include "args.h"

#define DEBUG 0

extern void dump_ast (char *msg, AST *root); /* stolen from btparse */

char *  Usage = "usage: bibparse [options] file [...]\n";
char *  Help = 
"\n"
"Options:\n"
"  -check         check syntax only (ie. don't print entries out)\n"
"  -noquote       don't quote strings [default]\n"
"  -quote         put quotes around strings (warning: not bulletproof)\n"
"  -convert       convert numeric values to strings\n"
"  -noconvert     don't\n"
"  -expand        expand macros [default]\n"
"  -noexand       don't\n"
"  -paste         paste strings together (ie. obey # operator) [default]\n"
"  -nopaste       don't\n"
"  -collapse      collapse whitespace within strings [default]\n"
"  -nocollapse    don't\n"
"\n"
"Default behaviour is \"fully processed\":\n"
"  -noquote -convert -expand -paste -collapse\n"
"\n";

#if 0
#if DEBUG
void dprintf (char *format, ...)
{
   va_list  arglist;

   va_start (arglist, format);
   vfprintf (stdout, format, arglist);
   va_end (arglist);
}
#else
void dprintf (char *format, ...) {}
#endif
#endif

/* ------------------------------------------------------------------------
@NAME       : print_assigned_entry()
@INPUT      : stream
              top
@OUTPUT     : 
@RETURNS    : 
@DESCRIPTION: Prints out a "field-assignment"-type entry (ie. a macro 
              definition or regular entry).
@GLOBALS    : 
@CALLS      : btparse traversal functions
@CALLERS    : print_entry()
@CREATED    : 1997/08/12, GPW
@MODIFIED   : 
-------------------------------------------------------------------------- */
static void
print_assigned_entry (FILE *stream, AST *top, boolean quote_strings)
{
   char  *type, *key;
   char  *field_name;
   AST   *field;

   type = bt_entry_type (top);
   key = bt_entry_key (top);

   fprintf (stream, "@%s", type);
   if (key) fprintf (stream, " %s", key);
   fputc ('\n', stream);

   field = NULL;
   while ((field = bt_next_field (top, field, &field_name)))
   {
      AST *   value;
      bt_nodetype nodetype;
      char *  text;
      boolean first;

      fprintf (stream, "%s=", field_name);

      value = NULL;
      first = TRUE;
      
      while ((value = bt_next_value (field, value, &nodetype, &text)))
      {
         if (!first) fputc ('#', stream);
         if (text) 
         {
            if (nodetype == BTAST_STRING && quote_strings)
               fprintf (stream, "{%s}", text);
            else
               fputs (text, stream);
         }
         first = FALSE;
      }

      fputc ('\n', stream);             /* newline between fields */
   }

   fputc ('\n', stream);                /* blank line to end the entry */
} /* print_assigned_entry() */


/* ------------------------------------------------------------------------
@NAME       : print_value_entry()
@INPUT      : stream
              top
@OUTPUT     : 
@RETURNS    : 
@DESCRIPTION: Prints out a "value-only" entry (ie. comment or preamble).
@GLOBALS    : 
@CALLS      : btparse traversal functions
@CALLERS    : print_entry()
@CREATED    : 1997/08/13, GPW
@MODIFIED   : 
-------------------------------------------------------------------------- */
static void
print_value_entry (FILE *stream, AST *top)
{
   char *  type;
   AST *   value;
   char *  text;

   type = bt_entry_type (top);
   fprintf (stream, "@%s\n", type);

   value = NULL;
      
   while ((value = bt_next_value (top, value, NULL, &text)))
   {
      if (text) fprintf (stream, "%s\n", text);
   }

   fputc ('\n', stream);
   
} /* print_value_entry() */


/* ------------------------------------------------------------------------
@NAME       : print_entry()
@INPUT      : 
@OUTPUT     : 
@RETURNS    : 
@DESCRIPTION: Prints a BibTeX entry in a very simplistic form by calling
              either print_assigned_entry() or print_value_entry().  These
              in turn work by calling the AST traversal routines in the
              btparse library, providing canonical examples of how to use
              these routines.
@GLOBALS    : 
@CALLS      : 
@CREATED    : 1997/01/22, GPW
@MODIFIED   : 1997/08/13, GPW: changed to differentiate between the two,
                               ahem, meta-meta-types of entries
-------------------------------------------------------------------------- */
static void
print_entry (FILE *stream, AST *top, boolean quote_strings)
{

#if DEBUG
   dump_ast ("print_entry: AST before traversing =\n", top);
#endif

   switch (bt_entry_metatype (top))
   {
      case BTE_MACRODEF:
      case BTE_REGULAR:
         print_assigned_entry (stream, top, quote_strings);
         break;

      case BTE_COMMENT:
      case BTE_PREAMBLE:
         print_value_entry (stream, top);
         break;

      default:
         fprintf (stderr, "warning: unknown entry type \"%s\"\n",
                  bt_entry_type (top));
         break;
   }
#if DEBUG
   dump_ast ("print_entry: AST after traversing =\n", top);
#endif
} /* print_entry() [2nd version] */


/* ------------------------------------------------------------------------
@NAME       : process_file
@INPUT      : filename
@OUTPUT     : 
@RETURNS    : true if there were no errors or only trivial errors
              false if there were serious errors
@DESCRIPTION: Parses an entire BibTeX file one entry at a time.  Each 
              entry is separately read, parsed, and printed back out
              to minimize memory use.
@GLOBALS    : 
@CALLS      : 
@CREATED    : Jan 1997, GPW
@MODIFIED   : 
@COMMENTS   : this *might* eventually wind up in the library, with
              a function pointer argument to specify what to do 
              to each entry
-------------------------------------------------------------------------- */
static int
process_file (char *filename, parser_options *options)
{
   FILE   *infile;
   AST    *cur_entry;
   boolean status, overall_status;

   /*
    * If a string was given, and it's *not* "-", then open that filename.
    * Otherwise just use stdin.
    */

   if (filename != NULL && strcmp (filename, "-") != 0)
   {
      infile = fopen (filename, "r");
      if (infile == NULL)
      {
         perror (filename);
         return 0;
      }
   }
   else
   {
      filename = "(stdin)";
      infile = stdin;
   }

   bt_set_stringopts (BTE_MACRODEF, options->string_opts);
   bt_set_stringopts (BTE_REGULAR, options->string_opts);
   bt_set_stringopts (BTE_COMMENT, options->string_opts);
   bt_set_stringopts (BTE_PREAMBLE, options->string_opts);
      
   overall_status = 1;                  /* assume success */
   while (1)
   {
      cur_entry = bt_parse_entry (infile, filename, 
                                  options->other_opts,
                                  &status);
      overall_status &= status;
      if (!cur_entry) break;
      if (!options->check_only)
         print_entry (stdout, cur_entry, options->quote_strings);
      if (options->dump_ast)
         dump_ast ("AST for whole entry:\n", cur_entry);
      bt_free_ast (cur_entry);
   }

   fclose (infile);
   return overall_status;

} /* process_file() */


int main (int argc, char *argv[])
{
   parser_options   *options;

   options = parse_args (argc, argv);
   bt_initialize ();

   if (argv[optind])            /* any leftover arguments (filenames) */
   {
      int i;

      for (i = optind; i < argc; i++)
         process_file (argv[i], options);
   }
   else
   {
      fprintf (stderr, Usage);
      fprintf (stderr, Help);
      fprintf (stderr, "Not enough arguments\n");
      exit (1);
   }

   bt_cleanup ();
   free (options);
   exit (bt_error_status (NULL));
}
