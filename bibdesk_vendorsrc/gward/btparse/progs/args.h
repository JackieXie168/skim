/* ------------------------------------------------------------------------
@NAME       : args.h
@DESCRIPTION: Typedef and prototype needed for command-line processing
              by the bibparse program.
@CREATED    : January 1997, Greg Ward
@MODIFIED   : 
@VERSION    : $Id: args.h,v 1.5 1997/11/11 00:16:43 greg Rel $
@COPYRIGHT  : Copyright (c) 1996-97 by Gregory P. Ward.  All rights reserved.

              This file is part of the btparse distribution (but not part
              of the library itself).  This is free software; you can
              redistribute it and/or modify it under the terms of the GNU
              General Public License as published by the Free Software
              Foundation; either version 2 of the License, or (at your
              option) any later version.
-------------------------------------------------------------------------- */
#ifndef ARGS_H
#define ARGS_H

#include <btparse.h>

typedef struct
{
   ushort    string_opts;
   ushort    other_opts;
   boolean   check_only;
   boolean   quote_strings;
   boolean   dump_ast;
   boolean   whole_file;
} parser_options;

parser_options *parse_args (int argc, char **argv);

#endif /* ARGS_H */
