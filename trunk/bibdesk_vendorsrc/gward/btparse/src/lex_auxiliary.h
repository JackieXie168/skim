/* ------------------------------------------------------------------------
@NAME       : lex_auxiliary.h
@DESCRIPTION: Macros and function prototypes needed by the lexical scanner.
              Some of these are called from internal PCCTS code, and some
              are explicitly called from the lexer actions in bibtex.g.
@CREATED    : Summer 1996, Greg Ward
@MODIFIED   : 
@VERSION    : $Id: lex_auxiliary.h,v 1.15 1999/11/29 01:13:10 greg Rel $
@COPYRIGHT  : Copyright (c) 1996-99 by Gregory P. Ward.  All rights reserved.

              This file is part of the btparse library.  This library is
              free software; you can redistribute it and/or modify it under
              the terms of the GNU Library General Public License as
              published by the Free Software Foundation; either version 2
              of the License, or (at your option) any later version.
-------------------------------------------------------------------------- */
#ifndef LEX_AUXILIARY_H
#define LEX_AUXILIARY_H

#include "btparse.h"
#include "attrib.h"

#define ZZCOPY_FUNCTION 0

#if ZZCOPY_FUNCTION
#define ZZCOPY zzcopy (&zznextpos, &lastpos, &zzbufovf)
#else
#define ZZCOPY                                  \
   if (zznextpos >= lastpos)                    \
   {                                            \
      lexer_overflow (&lastpos, &zznextpos);    \
   }                                            \
   *(zznextpos++) = zzchar;
#endif


/* Function prototypes: */

void lex_info (void);
void zzcr_attr (Attrib *a, int tok, char *txt);

void alloc_lex_buffer (int size);
void free_lex_buffer (void);
void lexer_overflow (unsigned char **lastpos, unsigned char **nextpos);
#if ZZCOPY_FUNCTION
void zzcopy (char **nextpos, char **lastpos, int *ovf_flag);
#endif

void initialize_lexer_state (void);
bt_metatype entry_metatype (void);

void newline (void);
void comment (void);
void at_sign (void);
void toplevel_junk (void);
void name (void);
void lbrace (void);
void rbrace (void);
void lparen (void);
void rparen (void);

void start_string (char start_char);
void end_string (char end_char);
void open_brace (void);
void close_brace (void);
void lparen_in_string (void);
void rparen_in_string (void);
void quote_in_string (void);
void check_runaway_string (void);

#endif /* ! defined LEX_AUXILIARY_H */
