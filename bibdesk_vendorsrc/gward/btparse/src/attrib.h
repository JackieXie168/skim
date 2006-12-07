/* ------------------------------------------------------------------------
@NAME       : attrib.h
@DESCRIPTION: Definition of the Attrib type needed by the PCCTS-
              generated parser.
@CREATED    : Summer 1996, Greg Ward
@MODIFIED   : 
@VERSION    : $Id: attrib.h,v 1.3 1999/11/29 01:13:10 greg Rel $
@COPYRIGHT  : Copyright (c) 1996-99 by Gregory P. Ward.  All rights reserved.

              This file is part of the btparse library.  This library is
              free software; you can redistribute it and/or modify it under
              the terms of the GNU Library General Public License as
              published by the Free Software Foundation; either version 2
              of the License, or (at your option) any later version.
-------------------------------------------------------------------------- */

#ifndef ATTRIB_H
#define ATTRIB_H

/*
 * Defining Attrib this way (as opposed to making it a pointer to a struct)
 * avoid the expense of allocating/deallocating a structure for each token;
 * this way, PCCTS statically allocates the whole stack once and that's
 * it.  (Of course, the stack is four times bigger than it would have been
 * otherwise.)
 */

typedef struct {
   int    line;
   int    offset;
   int    token;
   char  *text;
} Attrib;

#endif /* ATTRIB_H */
