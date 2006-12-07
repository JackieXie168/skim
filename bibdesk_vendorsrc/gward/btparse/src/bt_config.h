/* src/bt_config.h.  Generated automatically by configure.  */
/* ------------------------------------------------------------------------
@NAME       : bt_config.h
@DESCRIPTION: Site-specific options needed to compile the btparse library.

              (Actually, bt_config.h is generated from bt_config.h.in by
              the `configure' script.)
@GLOBALS    : 
@CREATED    : 1997/09/06, Greg Ward
@MODIFIED   : 
@VERSION    : $Id$
-------------------------------------------------------------------------- */

#ifndef BT_CONFIG_H
#define BT_CONFIG_H

/* 
 * strlwr() and strupr() generally seem to be available with MS-DOS
 * compilers, but I've never seen them on a Unix system.  I have no idea
 * about other Microsloth operating systems, 'though I suspect they would
 * be there.
 */

#define HAVE_STRLWR 0
#define HAVE_STRUPR 0


/* so names.c will know if it can include <alloca.h> */
#define HAVE_ALLOCA_H 1


/* 
 * vsnprintf() is used to generate error messages, if available (it's 
 * part of the GNU C Library, but isn't standard -- so I look for it
 * in configure).
 */
#define HAVE_VSNPRINTF 1


/* 
 * This is to accomodate an apparent problem with AIX: including <string.h>
 * doesn't give us a declaration for strdup().  I try to detect
 * this problem in configure, and overcome it here.
 */
#define HAVE_STRDUP_DECL 1
#if !HAVE_STRDUP_DECL
extern char *strdup (const char *s);
#endif


/* 
 * The dmalloc library is handy for finding memory leaks and other malloc
 * errors; I use it in the development version of the library.  Here, we
 * just turn on DMALLOC_FUNC_CHECK (to do even more checking); we don't
 * include <dmalloc.h> until we get to my_dmalloc.h.  That's because
 * <dmalloc.h> is supposed to be the *last* header included, but
 * bt_config.h is the first.  Ugh.
 */

#ifdef DMALLOC
# define DMALLOC_FUNC_CHECK
# define strdup(str) xstrdup(str)
#endif

#endif /* BT_CONFIG_H */
