/* ------------------------------------------------------------------------
@NAME       : util.c
@INPUT      : 
@OUTPUT     : 
@RETURNS    : 
@DESCRIPTION: Miscellaneous utility functions.  So far, just:
                 strlwr
                 strupr
@CREATED    : Summer 1996, Greg Ward
@MODIFIED   : 
@VERSION    : $Id: util.c,v 1.6 1999/11/29 01:13:10 greg Rel $
@COPYRIGHT  : Copyright (c) 1996-99 by Gregory P. Ward.  All rights reserved.

              This file is part of the btparse library.  This library is
              free software; you can redistribute it and/or modify it under
              the terms of the GNU Library General Public License as
              published by the Free Software Foundation; either version 2
              of the License, or (at your option) any later version.
-------------------------------------------------------------------------- */

#include "bt_config.h"
#include <string.h>
#include <ctype.h>
#include "prototypes.h"
#include "my_dmalloc.h"

/* ------------------------------------------------------------------------
@NAME       : strlwr()
@INPUT      : 
@OUTPUT     : 
@RETURNS    : 
@DESCRIPTION: Converts a string to lowercase in place.
@GLOBALS    : 
@CALLS      : 
@CREATED    : 1996/01/06, GPW
@MODIFIED   : 
@COMMENTS   : This should work the same as strlwr() in DOS compilers --
              why this isn't mandated by ANSI is a mystery to me...
-------------------------------------------------------------------------- */
#if !HAVE_STRLWR
char *strlwr (char *s)
{
   int  len, i;

   len = strlen (s);
   for (i = 0; i < len; i++)
      s[i] = tolower (s[i]);

   return s;
}
#endif



/* ------------------------------------------------------------------------
@NAME       : strupr()
@INPUT      : 
@OUTPUT     : 
@RETURNS    : 
@DESCRIPTION: Converts a string to uppercase in place.
@GLOBALS    : 
@CALLS      : 
@CREATED    : 1996/01/06, GPW
@MODIFIED   : 
@COMMENTS   : This should work the same as strupr() in DOS compilers --
              why this isn't mandated by ANSI is a mystery to me...
-------------------------------------------------------------------------- */
#if !HAVE_STRUPR
char *strupr (char *s)
{
   int  len, i;

   len = strlen (s);
   for (i = 0; i < len; i++)
      s[i] = toupper (s[i]);

   return s;
}
#endif
