/* ------------------------------------------------------------------------
@NAME       : error.c
@DESCRIPTION: Anything relating to reporting or recording errors and 
              warnings.
@GLOBALS    : errclass_names
              err_actions
              err_handlers
              errclass_counts
              error_buf
@CALLS      : 
@CREATED    : 1996/08/28, Greg Ward
@MODIFIED   : 
@VERSION    : $Id: error.c,v 2.5 1999/11/29 01:13:10 greg Rel $
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
#include <stdarg.h>
#include <string.h>
#include "btparse.h"
#include "error.h"
#include "my_dmalloc.h"


#define NUM_ERRCLASSES ((int) BTERR_INTERNAL + 1)


static char *errclass_names[NUM_ERRCLASSES] = 
{
   NULL,                        /* BTERR_NOTIFY */
   "warning",                   /* BTERR_CONTENT */ 
   "warning",                   /* BTERR_LEXWARN */
   "warning",                   /* BTERR_USAGEWARN */
   "error",                     /* BTERR_LEXERR */
   "syntax error",              /* BTERR_SYNTAX */
   "fatal error",               /* BTERR_USAGEERR */
   "internal error"             /* BTERR_INTERNAL */
};

static bt_erraction err_actions[NUM_ERRCLASSES] =
{
   BTACT_NONE,                  /* BTERR_NOTIFY */  
   BTACT_NONE,                  /* BTERR_CONTENT */ 
   BTACT_NONE,                  /* BTERR_LEXWARN */ 
   BTACT_NONE,                  /* BTERR_USAGEWARN */
   BTACT_NONE,                  /* BTERR_LEXERR */   
   BTACT_NONE,                  /* BTERR_SYNTAX */  
   BTACT_CRASH,                 /* BTERR_USAGEERR */
   BTACT_ABORT                  /* BTERR_INTERNAL */
};

void print_error (bt_error *err);

static bt_err_handler err_handlers[NUM_ERRCLASSES] =
{
   print_error,
   print_error,
   print_error,
   print_error,
   print_error,
   print_error,
   print_error,
   print_error
};

static int errclass_counts[NUM_ERRCLASSES] = { 0, 0, 0, 0, 0, 0, 0, 0 };
static char error_buf[MAX_ERROR+1];


/* ----------------------------------------------------------------------
 * Error-handling functions.
 */

void print_error (bt_error *err)
{
   char *  name;
   boolean something_printed;

   something_printed = FALSE;

   if (err->filename)
   {
      fprintf (stderr, err->filename);
      something_printed = TRUE;
   }
   if (err->line > 0)                   /* going to print a line number? */
   {
      if (something_printed)
         fprintf (stderr, ", ");
      fprintf (stderr, "line %d", err->line);
      something_printed = TRUE;
   }
   if (err->item_desc && err->item > 0) /* going to print an item number? */
   {
      if (something_printed)
         fprintf (stderr, ", ");
      fprintf (stderr, "%s %d", err->item_desc, err->item);
      something_printed = TRUE;
   }

   name = errclass_names[(int) err->class];
   if (name)
   {
      if (something_printed)
         fprintf (stderr, ", ");
      fprintf (stderr, name);
      something_printed = TRUE;
   }

   if (something_printed)
      fprintf (stderr, ": ");

   fprintf (stderr, "%s\n", err->message);

} /* print_error() */



/* ----------------------------------------------------------------------
 * Error-reporting functions: these are called anywhere in the library
 * when we encounter an error.
 */

void
report_error (bt_errclass class, 
              char *      filename,
              int         line,
              char *      item_desc,
              int         item,
              char *      fmt,
              va_list     arglist)
{
   bt_error  err;
#if !HAVE_VSNPRINTF
   int       msg_len;
#endif

   err.class = class;
   err.filename = filename;
   err.line = line;
   err.item_desc = item_desc;
   err.item = item;

   errclass_counts[(int) class]++;


   /* 
    * Blech -- we're writing to a static buffer because there's no easy
    * way to know how long the error message is going to be.  (Short of
    * reimplementing printf(), or maybe printf()'ing to a dummy file
    * and using the return value -- ugh!)  The GNU C library conveniently
    * supplies vsnprintf(), which neatly solves this problem by truncating
    * the output string if it gets too long.  (I could check for this
    * truncation if I wanted to, but I don't think it's necessary given the
    * ample size of the message buffer.)  For non-GNU systems, though,
    * we're stuck with using vsprintf()'s return value.  This can't be
    * trusted on all systems -- thus there's a check for it in configure.
    * Also, this won't necessarily trigger the internal_error() if we
    * do overflow; it's conceivable that vsprintf() itself would crash.  
    * At least doing it this way we avoid the possibility of vsprintf() 
    * silently corrupting some memory, and crashing unpredictably at some
    * later point.
    */

#if HAVE_VSNPRINTF
   vsnprintf (error_buf, MAX_ERROR, fmt, arglist);
#else
   msg_len = vsprintf (error_buf, fmt, arglist);
   if (msg_len > MAX_ERROR)
      internal_error ("static error message buffer overflowed");
#endif

   err.message = error_buf;
   if (err_handlers[class])
      (*err_handlers[class]) (&err);

   switch (err_actions[class])
   {
      case BTACT_NONE: return;
      case BTACT_CRASH: exit (1);
      case BTACT_ABORT: abort ();
      default: internal_error ("invalid error action %d for class %d (%s)", 
                               (int) err_actions[class],
                               (int) class, errclass_names[class]);
   }

} /* report_error() */


GEN_ERRFUNC (general_error,
             (bt_errclass class, 
              char *      filename,
              int         line,
              char *      item_desc,
              int         item,
              char *      fmt,
              ...),
             class, filename, line, item_desc, item, fmt)

GEN_ERRFUNC (error,
             (bt_errclass class,
              char *      filename, 
              int         line, 
              char *      fmt,
              ...),
             class, filename, line, NULL, -1, fmt)

GEN_ERRFUNC (ast_error,
             (bt_errclass class,
              AST *       ast,
              char *      fmt,
              ...),
             class, ast->filename, ast->line, NULL, -1, fmt)

GEN_ERRFUNC (notify,
             (char * fmt, ...),
             BTERR_NOTIFY, NULL, -1, NULL, -1, fmt)

GEN_ERRFUNC (usage_warning,
             (char * fmt, ...),
             BTERR_USAGEWARN, NULL, -1, NULL, -1, fmt)

GEN_ERRFUNC (usage_error,
             (char * fmt, ...),
             BTERR_USAGEERR, NULL, -1, NULL, -1, fmt)

GEN_ERRFUNC (internal_error,
             (char * fmt, ...),
             BTERR_INTERNAL, NULL, -1, NULL, -1, fmt)


/* ======================================================================
 * Functions to be used outside of the library
 */

/* ------------------------------------------------------------------------
@NAME       : bt_reset_error_counts()
@INPUT      : 
@OUTPUT     : 
@RETURNS    : 
@DESCRIPTION: Resets all the error counters to zero.
@GLOBALS    : 
@CALLS      : 
@CREATED    : 1997/01/08, GPW
@MODIFIED   : 
-------------------------------------------------------------------------- */
void bt_reset_error_counts (void)
{
   int  i;

   for (i = 0; i < NUM_ERRCLASSES; i++)
      errclass_counts[i] = 0;
}


/* ------------------------------------------------------------------------
@NAME       : bt_get_error_count()
@INPUT      : errclass
@OUTPUT     : 
@RETURNS    : 
@DESCRIPTION: Returns number of errors seen in the specified class.
@GLOBALS    : errclass_counts
@CALLS      : 
@CREATED    : 
@MODIFIED   : 
-------------------------------------------------------------------------- */
int bt_get_error_count (bt_errclass errclass)
{
   return errclass_counts[errclass];
}


/* ------------------------------------------------------------------------
@NAME       : bt_get_error_counts()
@INPUT      : counts - pointer to an array big enough to hold all the counts
                       if NULL, the array will be allocated for you (and you
                       must free() it when done with it)
@OUTPUT     : 
@RETURNS    : counts - either the passed-in pointer, or the newly-
                       allocated array if you pass in NULL
@DESCRIPTION: Returns a newly-allocated array with the number of errors
              in each error class, indexed by the members of the
              eclass_t enum.
@GLOBALS    : errclass_counts
@CALLS      : 
@CREATED    : 1997/01/06, GPW
@MODIFIED   : 
-------------------------------------------------------------------------- */
int *bt_get_error_counts (int *counts)
{
   int    i;

   if (counts == NULL)
      counts = (int *) malloc (sizeof (int) * NUM_ERRCLASSES);
   for (i = 0; i < NUM_ERRCLASSES; i++)
      counts[i] = errclass_counts[i];

   return counts;
}


/* ------------------------------------------------------------------------
@NAME       : bt_error_status
@INPUT      : saved_counts - an array of error counts as returned by 
                             bt_get_error_counts, or NULL not to compare
                             to a previous checkpoint
@OUTPUT     : 
@RETURNS    : 
@DESCRIPTION: Computes a bitmap where a bit is set for each error class
              that has more errors now than it used to have (or, if 
              saved_counts is NULL, the bit is set of there are have been
              any errors in the corresponding error class).

              Eg. "x & (1<<E_SYNTAX)" (where x is returned by bt_error_status)
              is true if there have been any syntax errors.
@GLOBALS    : 
@CALLS      : 
@CREATED    : 
@MODIFIED   : 
-------------------------------------------------------------------------- */
ushort bt_error_status (int *saved_counts)
{
   int     i;
   ushort  status;

   status = 0;

   if (saved_counts)
   {
      for (i = 0; i < NUM_ERRCLASSES; i++)
         status |= ( (errclass_counts[i] > saved_counts[i]) << i);
   }
   else
   {
      for (i = 0; i < NUM_ERRCLASSES; i++)
         status |= ( (errclass_counts[i] > 0) << i);
   }

   return status;
} /* bt_error_status () */
