/* ------------------------------------------------------------------------
@NAME       : lex_auxiliary.c
@INPUT      : 
@OUTPUT     : 
@RETURNS    : 
@DESCRIPTION: The code and global variables here have three main purposes:
                - maintain the lexical buffer (zztoktext, which
                  traditionally with PCCTS is a static array; I have
                  changed things so that it's dynamically allocated and
                  resized on overflow)
                - keep track of lexical state that's not handled by PCCTS
                  code (like "where are we in terms of BibTeX entries?" or
                  "what are the delimiters for the current entry/string?")
                - everything called from lexical actions is here, to keep
                  the grammar file itself neat and clean
@GLOBALS    : 
@CALLS      : 
@CALLERS    : 
@CREATED    : Greg Ward, 1996/07/25-28
@MODIFIED   : Jan 1997
              Jun 1997
@VERSION    : $Id: lex_auxiliary.c,v 1.31 1999/11/29 01:13:10 greg Rel $
@COPYRIGHT  : Copyright (c) 1996-99 by Gregory P. Ward.  All rights reserved.

              This file is part of the btparse library.  This library is
              free software; you can redistribute it and/or modify it under
              the terms of the GNU Library General Public License as
              published by the Free Software Foundation; either version 2
              of the License, or (at your option) any later version.
-------------------------------------------------------------------------- */

#include "bt_config.h"
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <stdarg.h>
#include <assert.h>
#include "lex_auxiliary.h"
#include "stdpccts.h"
#include "error.h"
#include "prototypes.h"
#include "my_dmalloc.h"

#define DUPE_TEXT 0

extern char * InputFilename;            /* from input.c */

GEN_PRIVATE_ERRFUNC (lexical_warning, (char * fmt, ...),
                     BTERR_LEXWARN, InputFilename, zzline, NULL, -1, fmt)
GEN_PRIVATE_ERRFUNC (lexical_error, (char * fmt, ...),
                     BTERR_LEXERR, InputFilename, zzline, NULL, -1, fmt)



/* ----------------------------------------------------------------------
 * Global variables
 */

/* First, the lexical buffer.  This is used elsewhere, so can't be static */
char *         zztoktext = NULL;

/* 
 * Now, the lexical state -- first, stuff that arises from scanning 
 * at top-level and the beginnings of entries;
 *   EntryState:
 *     toplevel when we start scanning a file, or when we are in in_entry
 *       mode and see '}' or ')'
 *     after_at when we are in toplevel mode and see an '@'
 *     after_type when we are in after_at mode and see a name (!= 'comment')
 *     in_comment when we are in after_at mode and see a name (== 'comment')
 *     in_entry when we are in after_type mode and see '{' or '('
 *   EntryOpener:
 *     the character ('(' or '{') which opened the entry currently being
 *     scanned (we use this to make sure that the entry opener and closer
 *     match; if not, we issue a warning)
 *   EntryMetatype: (NB. typedef for bt_metatype is in btparse.h)
 *     classifies entries according to the syntax we will use to parse them;
 *     also winds up (after being changed to a bt_nodetype value) in the 
 *     node that roots the entry AST:
 *       comment    - anything between () or {}
 *       preamble   - a single compound value
 *       string     - a list of "name = compound_value" assignments; no key
 *       alias      - a single "name = compound_value" assignment (where
 *                    the compound value in this case is presumably a 
 *                    name, rather than a string -- this is not syntactically
 *                    checked though)
 *       modify,
 *       entry      - a key followed by a list of "name = compound_value" 
 *                    assignments
 *   JunkCount:
 *     the number of non-whitespace, non-'@' characters seen at toplevel
 *     between two entries (used to print out a warning when we hit
 *     the beginning of entry, to help people catch "old style" implicit
 *     comments
 */
static enum { toplevel, after_at, after_type, in_comment, in_entry } 
               EntryState;
static char    EntryOpener;             /* '(' or '{' */
static bt_metatype
               EntryMetatype;
static int     JunkCount;               /* non-whitespace chars at toplevel */

/*
 * String state -- these are maintained and used by the functions called
 * from actions in the string lexer.
 *   BraceDepth:
 *     brace depth within a string; we can only end the current string
 *     when this is zero
 *   ParenDepth:
 *     parenthesis depth within a string; needed for @comment entries
 *     that are paren-delimited (because the comment in that case is
 *     a paren-delimited string)
 *   StringOpener:
 *     similar to EntryOpener, but stronger than merely warning of token
 *     mismatch -- this determines which character ('"' or '}') can 
 *     actually end the string
 *   StringStart:
 *     line on which current string started; if we detect an apparent
 *     runaway, this is used to report where the runaway started
 *   ApparentRunaway:
 *     flags if we have already detected (and warned) that the current
 *     string appears to be a runaway, so that we don't warn again
 *     (and again and again and again)
 *   QuoteWarned:
 *     flags if we have already warned about seeing a '"' in a string,
 *     because they tend to come in pairs and one warning per string 
 *     is enough
 *
 * (See bibtex.g for an explanation of my runaway string detection heuristic.)
 */
static char    StringOpener = '\0';     /* '{' or '"' */
static int     BraceDepth;              /* depth of brace-nesting */
static int     ParenDepth;              /* depth of parenthesis-nesting */
static int     StringStart = -1;        /* start line of current string */
static int     ApparentRunaway;         /* current string looks like runaway */
static int     QuoteWarned;             /* already warned about " in string? */



/* ----------------------------------------------------------------------
 * Miscellaneous functions:
 *   lex_info()      (handy for debugging)
 *   zzcr_attr()     (called from PCCTS-generated code)
 */

void lex_info (void)
{
   printf ("LA(1) = \"%s\" token %d, %s\n", LATEXT(1), LA(1), zztokens[LA(1)]);
#ifdef LL_K
   printf ("LA(2) = \"%s\" token %d, %s\n", LATEXT(2), LA(2), zztokens[LA(2)]);
#endif
}


void zzcr_attr (Attrib *a, int tok, char *txt)
{
   if (tok == STRING)
   {
      int   len = strlen (txt);

       /*assert ((txt[0] == '{' && txt[len-1] == '}')
              || (txt[0] == '"' && txt[len-1] == '"')); */
      txt[len-1] = (char) 0;            /* remove closing quote from string */
      txt++;                            /* so we'll skip the opening quote */
   }

#if DUPE_TEXT
   a->text = strdup (txt);
#else
   a->text = txt;
#endif
   a->token = tok;
   a->line = zzline;
   a->offset = zzbegcol;
#if DEBUG > 1
   dprintf ("zzcr_attr: input txt = %p (%s)\n", txt, txt);
   dprintf ("           dupe txt  = %p (%s)\n", a->text, a->text);
#endif
}


#if DUPE_TEXT
void zzd_attr (Attrib *attr)
{
   free (attr->text);
}
#endif


/* ----------------------------------------------------------------------
 * Lexical buffer functions:
 *   alloc_lex_buffer()
 *   realloc_lex_buffer()
 *   free_lex_buffer()
 *   lexer_overflow()
 *   zzcopy()              (only if ZZCOPY_FUNCTION is defined and true)
 */


/*
 * alloc_lex_buffer()
 * 
 * allocates the lexical buffer with `size' characters.  Clears the buffer,
 * points zzlextext at it, and sets zzbufsize to `size'.
 *
 * Does nothing if the buffer is already allocated.
 *
 * globals: zztoktext, zzlextext, zzbufsize
 * callers: bt_parse_entry() (in input.c)
 */
void alloc_lex_buffer (int size)
{
   if (zztoktext == NULL)
   {
      zztoktext = (char *) malloc (size * sizeof (char));
      memset (zztoktext, 0, size);
      zzlextext = zztoktext;
      zzbufsize = size;
   }
} /* alloc_lex_buffer() */


/*
 * realloc_lex_buffer()
 * 
 * Reallocates the lexical buffer -- size is increased by `size_increment'
 * characters (which could be negative).  Updates all globals that point
 * to or into the buffer (zzlextext, zzbegexpr, zzendexpr), as well as
 * zztoktext (the buffer itself) zzbufsize (the buffer size).
 *
 * This is only meant to be called (ultimately) from zzgettok(), part of
 * the DLG code.  (In fact, zzgettok() invokes the ZZCOPY() macro, which
 * calls lexer_overflow() on buffer overflow, which calls
 * realloc_lex_buffer().  Whatever.)  The `lastpos' and `nextpos' arguments
 * correspond, respectively, to a local variable in zzgettok() and a static
 * global in dlgauto.h (hence really in scan.c).  They both point into
 * the lexical buffer, so have to be passed by reference here so that
 * we can update them to point into the newly-reallocated buffer.
 * 
 * globals: zztottext, zzbufsize, zzlextext, zzbegexpr, zzendexpr
 * callers: lexer_overflow()
 */
static void
realloc_lex_buffer (int     size_increment, 
                    unsigned char ** lastpos, 
                    unsigned char ** nextpos)
{
   int   beg, end, next;

   if (zztoktext == NULL)
      internal_error ("attempt to reallocate unallocated lexical buffer");

   zztoktext = (char *) realloc (zztoktext, zzbufsize+size_increment);
   memset (zztoktext+zzbufsize, 0, size_increment);
   zzbufsize += size_increment;

   beg = zzbegexpr - zzlextext;
   end = zzendexpr - zzlextext;
   next = *nextpos - zzlextext;
   zzlextext = zztoktext;

   if (lastpos != NULL)
      *lastpos = zzlextext+zzbufsize-1;
   zzbegexpr = zzlextext + beg;
   zzendexpr = zzlextext + end;
   *nextpos = zzlextext + next;
   
} /* realloc_lex_buffer() */


/*
 * free_lex_buffer()
 *
 * Frees the lexical buffer allocated by alloc_lex_buffer().
 */
void free_lex_buffer (void)
{
   if (zztoktext == NULL)
      internal_error ("attempt to free unallocated (or already freed) " 
                      "lexical buffer");

   free (zztoktext);
   zztoktext = NULL;
} /* free_lex_buffer() */


/*
 * lexer_overflow()
 *
 * Prints a warning and calls realloc_lex_buffer() to increase the size
 * of the lexical buffer by ZZLEXBUFSIZE (a constant -- hence the buffer
 * size increases linearly, not exponentially).
 *
 * Also prints a couple of lines of useful debugging stuff if DEBUG is true.
 */ 
void lexer_overflow (unsigned char **lastpos, unsigned char **nextpos)
{
#if DEBUG
   char   head[16], tail[16];

   printf ("zzcopy: overflow detected\n");
   printf ("        zzbegcol=%d, zzendcol=%d, zzline=%d\n",
           zzbegcol, zzendcol, zzline);
   strncpy (head, zzlextext, 15); head[15] = 0;
   strncpy (tail, zzlextext+ZZLEXBUFSIZE-15, 15); tail[15] = 0;
   printf ("        zzlextext=>%s...%s< (last char=%d (%c))\n",
           head, tail, 
           zzlextext[ZZLEXBUFSIZE-1], zzlextext[ZZLEXBUFSIZE-1]);
   printf ("        zzchar = %d (%c), zzbegexpr=zzlextext+%d\n",
           zzchar, zzchar, zzbegexpr-zzlextext);
#endif

   notify ("lexical buffer overflowed (reallocating to %d bytes)",
                    zzbufsize+ZZLEXBUFSIZE);
   realloc_lex_buffer (ZZLEXBUFSIZE, lastpos, nextpos);

} /* lexer_overflow () */


#if ZZCOPY_FUNCTION
/*
 * zzcopy()
 * 
 * Does the same as the ZZCOPY macro (in lex_auxiliary.h), but as a
 * function for easier debugging.
 */
void zzcopy (char **nextpos, char **lastpos, int *ovf_flag)
{
   if (*nextpos >= *lastpos)
   {
      lexer_overflow (lastpos, nextpos);
   }

   **nextpos = zzchar;
   (*nextpos)++;
}
#endif



/* ----------------------------------------------------------------------
 * Report/maintain lexical state 
 *   report_state()        (only meaningful if DEBUG)
 *   initialize_lexer_state()
 *
 * Note that the lexical action functions, below, also fiddle with
 * the lexical state variables an awful lot.
 */

#if DEBUG
char *state_names[] =
   { "toplevel", "after_at", "after_type", "in_comment", "in_entry" };
char *metatype_names[] = 
   { "unknown", "comment", "preamble", "string", "alias", "modify", "entry" };

static void
report_state (char *where)
{
   printf ("%s: lextext=%s (line %d, offset %d), token=%d, "
           "EntryState=%s\n",
           where, zzlextext, zzline, zzbegcol, NLA,
           state_names[EntryState]);
}
#else
# define report_state(where)
/*
static void
report_state (char *where) { }
*/
#endif
  
void initialize_lexer_state (void)
{
   zzmode (START);
   EntryState = toplevel;
   EntryOpener = (char) 0;
   EntryMetatype = BTE_UNKNOWN;
   JunkCount = 0;
}


bt_metatype entry_metatype (void)
{
   return EntryMetatype;
}



/* ----------------------------------------------------------------------
 * Lexical actions (START and LEX_ENTRY modes)
 */

/* 
 * newline ()
 * 
 * Does everything needed to handle newline outside of a quoted string:
 * increments line counter and skips the newline.
 */
void newline (void)
{
   zzline++;
   zzskip();
}


void comment (void)
{
   zzline++;
   zzskip();
}
   

void at_sign (void)
{
   if (EntryState == toplevel)
   {
      EntryState = after_at;
      zzmode (LEX_ENTRY);
      if (JunkCount > 0)
      {
         lexical_warning ("%d characters of junk seen at toplevel", JunkCount);
         JunkCount = 0;
      }
   }
   else
   {
   /* internal_error ("lexer recognized \"@\" at other than top-level"); */
      lexical_warning ("\"@\" in strange place -- should get syntax error");
   }
   report_state ("at_sign");
}


void toplevel_junk (void)
{
   JunkCount += strlen (zzlextext);
   zzskip ();
}


void name (void)
{
   report_state ("name (pre)");

   switch (EntryState)
   {
      case toplevel:
      {
         internal_error ("junk at toplevel (\"%s\")", zzlextext); 
         break;
      }
      case after_at: 
      {
         char * etype = zzlextext;
         EntryState = after_type;

         if (strcasecmp (etype, "comment") == 0)
         {
            EntryMetatype = BTE_COMMENT;
            EntryState = in_comment;
         }

         else if (strcasecmp (etype, "preamble") == 0)
            EntryMetatype = BTE_PREAMBLE;

         else if (strcasecmp (etype, "string") == 0)
            EntryMetatype = BTE_MACRODEF;
/*
         else if (strcasecmp (etype, "alias") == 0)
            EntryMetatype = BTE_ALIAS;

         else if (strcasecmp (etype, "modify") == 0)
            EntryMetatype = BTE_MODIFY;
*/
         else
            EntryMetatype = BTE_REGULAR;

         break;
      }
      case after_type:
      case in_comment:
      case in_entry:
         break;                         /* do nothing */
   }

   report_state ("name (post)");

}


void lbrace (void)
{
   /* 
    * Currently takes a restrictive view of "when an lbrace is an entry
    * opener" -- ie. *only* after '@name' (as determined by EntryState),
    * where name is not 'comment'.  This means that lbrace usually
    * determines a string (in particular, when it's seen at toplevel --
    * which will happen under certain error situations), which in turn
    * means that some unexpected things can become strings (like whole
    * entries).
    */

   if (EntryState == in_entry || EntryState == in_comment)
   {
      start_string ('{');
   }
   else if (EntryState == after_type)
   {
      EntryState = in_entry;
      EntryOpener = '{';
      NLA = ENTRY_OPEN;
   }
   else
   {
      lexical_warning ("\"{\" in strange place -- should get a syntax error");
   }

   report_state ("lbrace");
}


void rbrace (void)
{
   if (EntryState == in_entry)
   {
      if (EntryOpener == '(')
         lexical_warning ("entry started with \"(\", but ends with \"}\"");
      NLA = ENTRY_CLOSE;
      initialize_lexer_state ();
   }
   else
   {
      lexical_warning ("\"}\" in strange place -- should get a syntax error");
   }
   report_state ("rbrace");
}


void lparen (void)
{
   if (EntryState == in_comment)
   {
      start_string ('(');
   }
   else if (EntryState == after_type)
   {
      EntryState = in_entry;
      EntryOpener = '(';
   }
   else
   {
      lexical_warning ("\"(\" in strange place -- should get a syntax error");
   }
   report_state ("lparen");
}


void rparen (void)
{
   if (EntryState == in_entry)
   {
      if (EntryOpener == '{')
         lexical_warning ("entry started with \"{\", but ends with \")\"");
      initialize_lexer_state ();
   }
   else
   {
      lexical_warning ("\")\" in strange place -- should get a syntax error");
   }
   report_state ("rparen");
}


/* ----------------------------------------------------------------------
 * Stuff for processing strings.
 */


/*
 * start_string ()
 *
 * Called when we see a '{' or '"' in the field data.  Records which quote
 * character was used, and calls open_brace() to increment the depth
 * counter if it was a '{'.  Switches to LEX_STRING mode, and tells the
 * lexer to continue slurping characters into the same buffer.
 */
void start_string (char start_char)
{
   StringOpener = start_char;
   BraceDepth = 0;
   ParenDepth = 0;
   StringStart = zzline;
   ApparentRunaway = 0;
   QuoteWarned = 0;
   if (start_char == '{')
      open_brace ();
   if (start_char == '(')
      ParenDepth++;
   if (start_char == '"' && EntryState == in_comment)
   {
      lexical_error ("comment entries must be delimited by either braces or parentheses");
      EntryState = toplevel;
      zzmode (START);
      return;
   }

#ifdef USER_ZZMODE_STACK
   if (zzauto != LEX_ENTRY || EntryState != in_entry)
#else
   if (EntryState != in_entry && EntryState != in_comment)
#endif
   {
      lexical_warning ("start of string seen at weird place");
   }

   zzmore ();
   zzmode (LEX_STRING);
}


/*
 * end_string ()
 *
 * Called when we see either a '"' (at depth 0) or '}' (if it brings us
 * down to depth 0) in a quoted string.  Just makes sure that braces are
 * balanced, and then goes back to the LEX_FIELD mode.
 */
void end_string (char end_char)
{
   char   match;

#ifndef ALLOW_WARNINGS
   match = (char) 0;                    /* silence "might be used" */
                                        /* uninitialized" warning */
#endif

   switch (end_char)
   {
      case '}': match = '{'; break;
      case ')': match = '('; break;
      case '"': match = '"'; break;
      default: 
         internal_error ("end_string(): invalid end_char \"%c\"", end_char);
   }

   assert (StringOpener == match);

   /*
    * If we're at non-zero BraceDepth, that probably means mismatched braces
    * somewhere -- complain about it and reset BraceDepth to minimize future
    * confusion.
    */

   if (BraceDepth > 0)
   {
      lexical_error ("unbalanced braces: too many {'s");
      BraceDepth = 0;
   }

   StringOpener = (char) 0;
   StringStart = -1;
   NLA = STRING;

   if (EntryState == in_comment)
   {
      int   len = strlen (zzlextext);

      /* 
       * ARG! no, this is wrong -- what if unbalanced braces in the string 
       * and we try to output put it later? 
       *
       * ARG! again, this is no more wrong than when we strip quotes in
       * post_parse.c, and blithely assume that we can put them back on
       * later for output in BibTeX syntax.  Hmmm.
       *
       * Actually, it looks like this isn't a problem after all: you
       * can't have unbalanced braces in a BibTeX string (at least
       * not as parsed by btparse).
       */

      if (zzlextext[0] == '(')          /* convert to standard quote delims */
      {
         zzlextext[    0] = '{';
         zzlextext[len-1] = '}';
      }

      EntryState = toplevel;
      zzmode (START);
   }
   else
   {
      zzmode (LEX_ENTRY);
   }
      
   report_state ("string");
}


/*
 * open_brace ()
 * 
 * Called when we see a '{', either to start a string (in which case 
 * it's called from start_string()) or inside a string (called directly
 * from the lexer).
 */
void open_brace (void)
{
   BraceDepth++;
   zzmore ();
   report_state ("open_brace");
}


/*
 * close_brace ()
 *
 * Called when we see a '}' inside a string.  Decrements the depth counter
 * and checks to see if we are down to depth 0, in which case the string is
 * ended and the current lookahead token is set to STRING.  Otherwise,
 * just tells the lexer to keep slurping characters into the buffer.
 */
void close_brace (void)
{
   BraceDepth--;
   if (StringOpener == '{' && BraceDepth == 0)
   {
      end_string ('}');
   }

   /* 
    * This could happen if some bonehead puts an unmatched right-brace
    * in a quote-delimited string (eg. "Hello}").  To attempt to recover,
    * we reset the depth to zero and continue slurping into the string.
    */
   else if (BraceDepth < 0)
   {
      lexical_error ("unbalanced braces: too many }'s");
      BraceDepth = 0;
      zzmore ();
   }

   /* Otherwise, it's just any old right brace in a string -- keep eating */
   else
   {
      zzmore ();
   }
   report_state ("close_brace");
}


void lparen_in_string (void)
{
   ParenDepth++;
   zzmore ();
}


void rparen_in_string (void)
{
   ParenDepth--;
   if (StringOpener == '(' && ParenDepth == 0)
   {
      end_string (')');
   }
   else
   {
      zzmore ();
   }
}


/* 
 * quote_in_string ()
 * 
 * Called when we see '"' in a string.  Ends the string if the quote is at
 * depth 0 and the string was started with a quote, otherwise instructs the
 * lexer to continue munching happily along.  (Also prints a warning,
 * assuming that input is destined for processing by TeX and you really
 * want either `` or '' rather than ".)
 */
void quote_in_string (void)
{
   if (StringOpener == '"' && BraceDepth == 0)
   {
      end_string ('"');
   }
   else
   {
      boolean at_top = FALSE;;

      /* 
       * Note -- this warning assumes that strings are destined 
       * to be processed by TeX, so it should be optional.  Hmmm.
       */

      if (StringOpener == '"' || StringOpener == '(')
         at_top = (BraceDepth == 0);
      else if (StringOpener == '{')
         at_top = (BraceDepth == 1);
      else
         internal_error ("Illegal string opener \"%c\"", StringOpener);

      if (!QuoteWarned && at_top)
      {
         lexical_warning ("found \" at brace-depth zero in string "
                          "(TeX accents in BibTeX should be inside braces)");
         QuoteWarned = 1;
      }
      zzmore ();
   }
}


/*
 * check_runaway_string ()
 *
 * Called from the lexer whenever we see a newline in a string.  See 
 * bibtex.g for a detailed explanation; basically, this function
 * looks for an entry start ("@name{") or new field ("name=") immediately
 * after a newline (with possible whitespace).  This is a heuristic 
 * check for runaway strings, under the assumption that text that looks
 * like a new entry or new field won't actually occur inside a string
 * very often.
 */
void check_runaway_string (void)
{
   int      len;
   int      i;

   /* 
    * could these be made significantly more efficient by a 256-element
    * lookup table instead of calling strchr()?
    */
   static char *alpha_chars = "abcdefghijklmnopqrstuvwxyz";
   static char *name_chars = "abcdefghijklmnopqrstuvwxyz0123456789:+/'.-";

   /* 
    * on entry: zzlextext contains the whole string, starting with {
    * and with newlines/tabs converted to space; zzbegexpr points to
    * a chunk of the string starting with newline (newlines and 
    * tabs have not yet been converted)
    */

#if DEBUG > 1
   printf ("check_runaway_string(): zzline=%d\n", zzline);
   printf ("zzlextext=>%s<\nzzbegexpr=>%s<\n", 
           zzlextext, zzbegexpr);
#endif
      

   /* 
    * increment zzline to take the leading newline into account -- but
    * first a sanity check to be sure that newline is there!
    */

   if (zzbegexpr[0] != '\n')
   {
      lexical_warning ("huh? something's wrong (buffer overflow?) near "
                       "offset %d (line %d)", zzendcol, zzline);
   /* internal_error ("zzbegexpr (line %d, offset %d-%d, "
                      "text >%s<, expr >%s<)"
                      "should start with a newline",
                      zzline, zzbegcol, zzendcol, zzlextext, zzbegexpr);
   */
   }
   else
   {
      zzline++;
   }

   /* standardize whitespace (convert all to space) */

   len = strlen (zzbegexpr);
   for (i = 0; i < len; i++)
   {
      if (isspace (zzbegexpr[i]))
         zzbegexpr[i] = ' ';
   }
   

   if (!ApparentRunaway)                /* haven't already warned about it */
   {
      enum { none, entry, field, giveup } guess;

      i = 1;
      guess = none;
      while (i < len && zzbegexpr[i] == ' ') i++;

      if (zzbegexpr[i] == '@')
      {
         i++;
         while (i < len && zzbegexpr[i] == ' ') i++;
         guess = entry;
      }

      if (strchr (alpha_chars, tolower (zzbegexpr[i])) != NULL)
      {
         while (i < len && strchr (name_chars, tolower (zzbegexpr[i])) != NULL)
            i++;
         while (i < len && zzbegexpr[i] == ' ') i++;
         if (i == len)
         {
            guess = giveup;
         }
         else
         {
            if (guess == entry)
            {
               if (zzbegexpr[i] != '{' && zzbegexpr[i] != '(')
                  guess = giveup;
            }
            else                        /* assume it's a field */
            {
               if (zzbegexpr[i] == '=')
                  guess = field;
               else
                  guess = giveup;
            }               
         }
      }
      else                              /* no name seen after WS or @ */
      {
         guess = giveup;
      }

      if (guess == none)
         internal_error ("gee, I should have made a guess by now");

      if (guess != giveup)
      {
         lexical_warning ("possible runaway string started at line %d", 
                          StringStart);
         ApparentRunaway = 1;
      }
   }

   zzmore();
}

