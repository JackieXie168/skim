/* ------------------------------------------------------------------------
@NAME       : bt_debug.h
@DESCRIPTION: Defines various macros needed for compile-time selection
              of debugging code.
@GLOBALS    : 
@CREATED    : 
@MODIFIED   : 
@VERSION    : $Id: bt_debug.h,v 1.2 1999/11/29 01:13:10 greg Rel $
@COPYRIGHT  : Copyright (c) 1996-99 by Gregory P. Ward.  All rights reserved.

              This file is part of the btparse library.  This library is
              free software; you can redistribute it and/or modify it under
              the terms of the GNU Library General Public License as
              published by the Free Software Foundation; either version 2
              of the License, or (at your option) any later version.
-------------------------------------------------------------------------- */

#ifndef BT_DEBUG_H
#define BT_DEBUG_H

/* 
 * DEBUG      is the debug level -- an integer, defaults to 0
 * DBG_ACTION is a macro to conditionally execute a bit of code --
 *            must have compiled with DEBUG true, and the debug level
 *            must be >= `level' (the macro argument)
 */

#ifndef DEBUG
# define DEBUG 0
#endif

#if DEBUG
# define DBG_ACTION(level,action) if (DEBUG >= level) { action; }
#else
# define DBG_ACTION(level,action)
#endif

#endif /* BT_DEBUG_H */
