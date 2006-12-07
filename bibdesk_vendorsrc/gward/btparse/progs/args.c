/* ------------------------------------------------------------------------
@NAME       : args.c
@DESCRIPTION: Data related to the command-line arguments, and code to
              parse them.
@GLOBALS    : 
@CALLS      : 
@CREATED    : 1997/01/09-10, Greg Ward
@MODIFIED   : 
@VERSION    : $Id: args.c,v 1.7 1998/03/14 16:38:04 greg Rel $
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

#include "getopt.h"
#include "args.h"


/* default options -- "full processing" */
#if 0
parser_options options = 
{ 
   {
      0,                                /* check_only */
      1,                                /* delete_quotes */
      1,                                /* expand_macros */
      1,                                /* paste_strings */
      1                                 /* collapse_whitespace */
   },
   0,                                   /* dump_ast */
   0                                    /* whole_file */
};
#endif

static boolean quote_strings = FALSE;
static boolean convert_numbers = TRUE;
static boolean expand_macros = TRUE;
static boolean paste_strings = TRUE;
static boolean collapse_whitespace = TRUE;

static boolean check_only = FALSE;
static boolean dump_ast = FALSE;
static boolean whole_file = FALSE;

struct option option_table[] = 
{
   { "check",      0, &check_only, 1 },
   { "noquotes",   0, &quote_strings, 0 },
   { "quote",      0, &quote_strings, 1 },
   { "convert",    0, &convert_numbers, 1 },
   { "noconvert",  0, &convert_numbers, 0 },
   { "expand",     0, &expand_macros, 1 },
   { "noexpand",   0, &expand_macros, 0 },
   { "paste",      0, &paste_strings, 1 },
   { "nopaste",    0, &paste_strings, 0 },
   { "collapse",   0, &collapse_whitespace, 1 },
   { "nocollapse", 0, &collapse_whitespace, 0 },
   { "dump",       0, &dump_ast, 1 },
   { "nodump",     0, &dump_ast, 0 },
   { "wholefile",  0, &whole_file, 1 },
   { NULL, 0, 0, 0 }
};

parser_options *parse_args (int argc, char **argv)
{
   int     c;
   parser_options *options;

   while (1)
   {
      c = getopt_long_only (argc, argv, "", option_table, NULL);
      if (c == -1) break;      /* last option? */

      switch (c)
      {
         case ':':
         case '?':
            fprintf (stderr, "%s: error in command-line\n", argv[0]);
            exit (1);
            break;
      }
   }

   options = (parser_options *) malloc (sizeof (parser_options));

   options->string_opts = 0;
   options->string_opts |= (convert_numbers ? BTO_CONVERT : 0);
   options->string_opts |= (expand_macros ? BTO_EXPAND : 0);
   options->string_opts |= (paste_strings ? BTO_PASTE : 0);
   options->string_opts |= (collapse_whitespace ? BTO_COLLAPSE : 0);
   
   options->other_opts = 0;       /* do store macro text */
   
   options->quote_strings = quote_strings;
   options->check_only = check_only;
   options->dump_ast = dump_ast;
   options->whole_file = whole_file;

   return options;

} /* parse_args () */
