/* ------------------------------------------------------------------------
@NAME       : biblex.c
@INPUT      : a single BibTeX file
@OUTPUT     : dumps the token stream to stdout
@RETURNS    : 
@DESCRIPTION: Evil, naughty, badly-behaved example program for the btparse
              library.  This goes poking rudly about in the internals of
              both the library and its lexical scanner to perform only
              lexical analysis on a BibTeX file.  It uses this to dump the
              token stream to stdout.

              This could actually be useful for quickly (ie. without a full
              parse) constructing an index of a BibTeX file.  Eventually,
              I'd like to put this sort of functionality into the library
              itself, so this program would be reduced to just calling some
              mythical bt_next_token() in a loop, or maybe a single call to
              bt_token_stream() (also mythical).
@CREATED    : Winter 1997, Greg Ward
@MODIFIED   : 
@VERSION    : $Id: biblex.c,v 1.1 1997/09/06 23:19:14 greg Rel $
@COPYRIGHT  : Copyright (c) 1996-97 by Gregory P. Ward.  All rights reserved.

              This file is part of the btparse distribution (but not part
              of the library itself).  This is free software; you can
              redistribute it and/or modify it under the terms of the GNU
              General Public License as published by the Free Software
              Foundation; either version 2 of the License, or (at your
              option) any later version.
-------------------------------------------------------------------------- */

#include <stdio.h>
#include <btparse.h>
#include "stdpccts.h"                   /* poke about btparse's private bits */

int main (int argc, char *argv[])
{
   extern char * InputFilename;         /* from input.c in the library */
   char  * filename;
   FILE  * infile;

/*
   static char zztoktext[ZZLEXBUFSIZE]; 

   zzlextext = zztoktext;
*/
   zzbufsize = ZZLEXBUFSIZE;
   alloc_lex_buffer (zzbufsize);

   if (argc != 2)
   {
      fprintf (stderr, "usage: biblex file.bib\n");
      exit (1);
   }

   filename = argv[1];
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

   InputFilename = filename;
   zzrdstream (infile);
   while (!feof (infile))
   {
      zzgettok ();
      printf ("%3d   %4d-%4d  %2d=%-10s  >%s<\n",
              zzline, zzbegcol, zzendcol, 
              zztoken, zztokens[zztoken], zzlextext);
      if (zzbufovf)
      {
         printf ("OH NO!! buffer overflowed!\n");
      }
   }

   free_lex_buffer ();
   return 0;
}
