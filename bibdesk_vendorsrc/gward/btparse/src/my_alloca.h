/* ------------------------------------------------------------------------
@NAME       : my_alloca.h
@DESCRIPTION: All-out assault at making alloca() available on any Unix
              platform.  Stolen from the GNU Autoconf manual.
@CREATED    : 1997/10/30, Greg Ward
@VERSION    : $Id: my_alloca.h,v 1.1 1997/10/31 03:56:17 greg Rel $
@COPYRIGHT  : This file is part of the btparse library.  This library is
              free software; you can redistribute it and/or modify it under
              the terms of the GNU Library General Public License as
              published by the Free Software Foundation; either version 2
              of the License, or (at your option) any later version.
-------------------------------------------------------------------------- */

#ifndef MY_ALLOCA_H
#define MY_ALLOCA_H

#ifdef __GNUC__
# ifndef alloca
#  define alloca __builtin_alloca
# endif
#else
# if HAVE_ALLOCA_H
#  include <alloca.h>
# else
#  ifdef _AIX
#   pragma alloca
#  else
#   ifndef alloca                       /* predefined by HP cc +Olibcalls */
char *alloca ();
#   endif
#  endif
# endif
#endif

#endif /* MY_ALLOCA_H */
