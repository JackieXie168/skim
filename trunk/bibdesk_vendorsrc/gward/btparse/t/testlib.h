/* ------------------------------------------------------------------------
@NAME       : testlib.h
@DESCRIPTION: Macros and prototypes common to all the btparse test programs.
@CREATED    : 1997/09/26, Greg Ward
@MODIFIED   : 
@VERSION    : $Id: testlib.h,v 1.1 1997/09/26 13:15:35 greg Rel $
-------------------------------------------------------------------------- */

#ifndef TESTLIB_H
#define TESTLIB_H

#include "btparse.h"

#define DATA_DIR "data"

#define CHECK(cond)                                             \
if (! (cond))                                                   \
{                                                               \
   fprintf (stderr, "failed check: %s, at %s line %d\n",        \
            #cond, __FILE__, __LINE__);                         \
   ok = FALSE;                                                  \
}

#define CHECK_ESCAPE(cond,escape,what)                          \
if (! (cond))                                                   \
{                                                               \
   fprintf (stderr, "failed check: %s, at %s line %d\n",        \
            #cond, __FILE__, __LINE__);                         \
   if (what)                                                    \
   {                                                            \
      fprintf (stderr, "(skipping the rest of this %s)\n",      \
               what);                                           \
   }                                                            \
   ok = FALSE;                                                  \
   escape;                                                      \
}


FILE *open_file (char *basename, char *dirname, char *filename);
void set_all_stringopts (ushort options);


#endif /* TESTLIB_H */
