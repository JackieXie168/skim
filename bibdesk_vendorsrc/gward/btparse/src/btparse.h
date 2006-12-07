/* src/btparse.h.  Generated automatically by configure.  */
/* ------------------------------------------------------------------------
@NAME       : btparse.h
@DESCRIPTION: Declarations and types for users of the btparse library.

              (Actually, btparse.h is generated from btparse.h.in by
              the `configure' script, in order to automatically determine
              the appropriate values of HAVE_USHORT and HAVE_BOOLEAN.)
@GLOBALS    : 
@CALLS      : 
@CREATED    : 1997/01/19, Greg Ward
@MODIFIED   : 
@VERSION    : $Id$
@COPYRIGHT  : Copyright (c) 1996-97 by Gregory P. Ward.  All rights reserved.

              This file is part of the btparse library.  This library is
              free software; you can redistribute it and/or modify it under
              the terms of the GNU Library General Public License as
              published by the Free Software Foundation; either version 2
              of the License, or (at your option) any later version.
-------------------------------------------------------------------------- */
#ifndef BTPARSE_H
#define BTPARSE_H

#include <sys/types.h>                  /* probably supplies 'ushort' */
#include <stdio.h>

/*
 * Here we attempt to define HAVE_USHORT if a typdef for `ushort' appears
 * in <sys/types.h>.  The detective work is actually done by the
 * `configure' script, so if compilation fails because of duplicate
 * definitions of `ushort', that's a bug in `configure' -- please tell me
 * about it!
 */

#define HAVE_USHORT_XSUB 1

#if defined(H_PERL) && HAVE_USHORT_XSUB
# ifndef HAVE_USHORT
#  define HAVE_USHORT 1
# endif
#endif

#ifndef HAVE_USHORT
# define HAVE_USHORT 1
#endif

#if ! HAVE_USHORT                       /* needed for various bitmaps */
typedef unsigned short ushort;
#endif


/* Likewise for boolean. */

#ifndef HAVE_BOOLEAN
# define HAVE_BOOLEAN 0
#endif

#if ! HAVE_BOOLEAN
typedef int boolean;
#endif

#ifndef TRUE
# define TRUE 1
# define FALSE 0
#endif

/* Parsing (and post-processing) options */

#define BTO_CONVERT   1                 /* convert numbers to strings? */
#define BTO_EXPAND    2                 /* expand macros? */
#define BTO_PASTE     4                 /* paste substrings together? */
#define BTO_COLLAPSE  8                 /* collapse whitespace? */

#define BTO_NOSTORE   16

#define BTO_FULL (BTO_CONVERT | BTO_EXPAND | BTO_PASTE | BTO_COLLAPSE)
#define BTO_MACRO (BTO_CONVERT | BTO_EXPAND | BTO_PASTE)
#define BTO_MINIMAL 0

#define BTO_STRINGMASK (BTO_CONVERT | BTO_EXPAND | BTO_PASTE | BTO_COLLAPSE)

#define BT_VALID_NAMEPARTS "fvlj"
#define BT_MAX_NAMEPARTS 4

typedef enum
{
   BTE_UNKNOWN,
   BTE_REGULAR,
   BTE_COMMENT,
   BTE_PREAMBLE,
   BTE_MACRODEF
/*
   BTE_ALIAS,
   BTE_MODIFY
*/
} bt_metatype;

#define NUM_METATYPES ((int) BTE_MACRODEF + 1)

typedef enum 
{ 
   BTAST_BOGUS,                           /* to detect uninitialized nodes */
   BTAST_ENTRY,
   BTAST_KEY,
   BTAST_FIELD,
   BTAST_STRING,
   BTAST_NUMBER,
   BTAST_MACRO
} bt_nodetype;

typedef enum
{ 
   BTN_FIRST, BTN_VON, BTN_LAST, BTN_JR, BTN_NONE 
} bt_namepart;

typedef enum
{
   BTJ_MAYTIE,                          /* "discretionary" tie between words */
   BTJ_SPACE,                           /* force a space between words */
   BTJ_FORCETIE,                        /* force a tie (~ in TeX) */
   BTJ_NOTHING                          /* nothing between words */
} bt_joinmethod;


#define USER_DEFINED_AST 1

#define zzcr_ast(ast,attr,tok,txt)              \
{                                               \
   (ast)->filename = InputFilename;             \
   (ast)->line = (attr)->line;                  \
   (ast)->offset = (attr)->offset;              \
   (ast)->text = strdup ((attr)->text);         \
}

#define zzd_ast(ast)                            \
/* printf ("zzd_ast: free'ing ast node with string %p (%s)\n", \
           (ast)->text, (ast)->text); */ \
   if ((ast)->text != NULL) free ((ast)->text);


#ifdef USER_DEFINED_AST
typedef struct _ast 
{
   struct _ast *right, *down;
   char *           filename;
   int              line;
   int              offset;
   bt_nodetype    nodetype;
   bt_metatype    metatype;
   char *           text;
} AST;
#endif /* USER_DEFINED_AST */


typedef struct
{
   /* 
    * `string' is the string that has been split; items[0] ...
    * items[num_items-1] are pointers into `string', or NULL for empty
    * substrings.  Note that `string' is actually a copy of the string
    * passed in to bt_split_list() with NULs inserted between substrings.
    */

   char *  string;
   int     num_items;
   char ** items;
} bt_stringlist;


typedef struct
{
   bt_stringlist * tokens;              /* flat list of all tokens in name */
   char ** parts[BT_MAX_NAMEPARTS];     /* each elt. is list of pointers */
                                        /* into `tokens->string' */
   int     part_len[BT_MAX_NAMEPARTS];  /* length in tokens */
} bt_name;


typedef struct tex_tree_s
{
   char * start;
   int    len;
   struct tex_tree_s
        * child,
        * next;
} bt_tex_tree;


typedef struct
{
   /* These determine the order (and presence) of parts in the name. */
   int         num_parts;
   bt_namepart parts[BT_MAX_NAMEPARTS];

   /* 
    * These lists are always in the order of the bt_namepart enum -- *not*
    * dependent on the particular order of parts the user specified!  (This
    * will make it a bit harder if I ever allow more than one occurrence of
    * a part in a format; since I don't allow that, I'm not [yet] worried
    * about it!)
    */
   char *       pre_part[BT_MAX_NAMEPARTS];
   char *       post_part[BT_MAX_NAMEPARTS];
   char *       pre_token[BT_MAX_NAMEPARTS];
   char *       post_token[BT_MAX_NAMEPARTS];
   boolean      abbrev[BT_MAX_NAMEPARTS];
   bt_joinmethod join_tokens[BT_MAX_NAMEPARTS];
   bt_joinmethod join_part[BT_MAX_NAMEPARTS];
} bt_name_format;


typedef enum 
{
   BTERR_NOTIFY,                /* notification about next action */
   BTERR_CONTENT,               /* warning about the content of a record */
   BTERR_LEXWARN,               /* warning in lexical analysis */
   BTERR_USAGEWARN,             /* warning about library usage */
   BTERR_LEXERR,                /* error in lexical analysis */
   BTERR_SYNTAX,                /* error in parser */
   BTERR_USAGEERR,              /* fatal error in library usage */
   BTERR_INTERNAL               /* my fault */
} bt_errclass;

typedef enum
{
   BTACT_NONE,                  /* do nothing on error */
   BTACT_CRASH,                 /* call exit(1) */
   BTACT_ABORT                  /* call abort() */
} bt_erraction;

typedef struct
{
   bt_errclass class;
   char *      filename;
   int         line;
   char *      item_desc;
   int         item;
   char *      message;
} bt_error;

typedef void (*bt_err_handler) (bt_error *);


#if defined(__cplusplus__) || defined(__cplusplus) || defined(c_plusplus)
extern "C" {
#endif

/* Function prototypes */

/* 
 * First, we might need a prototype for strdup() (because the zzcr_ast
 * macro uses it, and that macro is used in pccts/ast.c -- which I don't
 * want to modify if I can help it, because it's someone else's code).
 * This is to accomodate AIX, where including <string.h> apparently doesn't
 * declare strdup() (reported by Reiner Schlotte
 * <schlotte@geo.palmod.uni-bremen.de>), and compiling bibtex.c (which
 * includes pccts/ast.c) crashes because of this (yes, yes, I know it
 * should just be a warning -- I don't know what's going on there!).
 * 
 * Unfortunately, this duplicates code in bt_config.h -- I can't include
 * bt_config.h here, because this header must be freestanding; I don't want
 * to include bt_config.h in pccts/ast.c, because I don't want to touch the
 * PCCTS code if I can help it; but I don't want every source file that
 * uses strdup() to have to include btparse.h.  Hence the duplication.
 * Yuck.
 */
#define HAVE_STRDUP_DECL 1
#if !HAVE_STRDUP_DECL
extern char *strdup (const char *s);
#endif


/* init.c */
void  bt_initialize (void);
void  bt_free_ast (AST *ast);
void  bt_cleanup (void);

/* input.c */
void    bt_set_stringopts (bt_metatype metatype, ushort options);
AST * bt_parse_entry_s (char *    entry_text,
                        char *    filename,
                        int       line,
                        ushort    options,
                        boolean * status);
AST * bt_parse_entry   (FILE *    infile,
                        char *    filename,
                        ushort    options,
                        boolean * status);
AST * bt_parse_file    (char *    filename, 
                        ushort    options, 
                        boolean * overall_status);

/* post_parse.c */
void bt_postprocess_string (char * s, ushort options);
char * bt_postprocess_value (AST * value, ushort options, boolean replace);
char * bt_postprocess_field (AST * field, ushort options, boolean replace);
void bt_postprocess_entry (AST * entry, ushort options);

/* error.c */
void   bt_reset_error_counts (void);
int    bt_get_error_count (bt_errclass errclass);
int *  bt_get_error_counts (int *counts);
ushort bt_error_status (int *saved_counts);

/* macros.c */
void bt_add_macro_value (AST *assignment, ushort options);
void bt_add_macro_text (char * macro, char * text, char * filename, int line);
void bt_delete_macro (char * macro);
void bt_delete_all_macros (void);
int bt_macro_length (char *macro);
char * bt_macro_text (char * macro, char * filename, int line);

/* traversal.c */
AST *bt_next_entry (AST *entry_list, AST *prev_entry);
bt_metatype bt_entry_metatype (AST *entry);
char *bt_entry_type (AST *entry);
char *bt_entry_key (AST *entry);
AST *bt_next_field (AST *entry, AST *prev, char **name);
AST *bt_next_macro (AST *entry, AST *prev, char **name);
AST *bt_next_value (AST *head, 
                    AST *prev,
                    bt_nodetype *nodetype,
                    char **text);
char *bt_get_text (AST *node);

/* modify.c */
void bt_set_text (AST * node, char * new_text);
void bt_entry_set_key (AST * entry, char * new_key);

/* names.c */
bt_stringlist * bt_split_list (char *   string,
                               char *   delim,
                               char *   filename,
                               int      line,
                               char *   description);
void bt_free_list (bt_stringlist *list);
bt_name * bt_split_name (char *  name,
                         char *  filename, 
                         int     line,
                         int     name_num);
void bt_free_name (bt_name * name);

/* tex_tree.c */
bt_tex_tree * bt_build_tex_tree (char * string);
void          bt_free_tex_tree (bt_tex_tree **top);
void          bt_dump_tex_tree (bt_tex_tree *node, int depth, FILE *stream);
char *        bt_flatten_tex_tree (bt_tex_tree *top);

/* string_util.c */
void bt_purify_string (char * string, ushort options);
void bt_change_case (char transform, char * string, ushort options);

/* format_name.c */
bt_name_format * bt_create_name_format (char * parts, boolean abbrev_first);
void bt_free_name_format (bt_name_format * format);
void bt_set_format_text (bt_name_format * format, 
                         bt_namepart part,
                         char * pre_part,
                         char * post_part,
                         char * pre_token,
                         char * post_token);
void bt_set_format_options (bt_name_format * format, 
                            bt_namepart part,
                            boolean abbrev,
                            bt_joinmethod join_tokens,
                            bt_joinmethod join_part);
char * bt_format_name (bt_name * name, bt_name_format * format);

#if defined(__cplusplus__) || defined(__cplusplus) || defined(c_plusplus)
}
#endif

#endif /* BTPARSE_H */
