/* ------------------------------------------------------------------------
@NAME       : string_util.c
@DESCRIPTION: Various string-processing utility functions:
                bt_purify_string()
                bt_change_case()

              and their helpers:
                foreign_letter()
                purify_special_char()
@GLOBALS    : 
@CALLS      : 
@CALLERS    : 
@CREATED    : 1997/10/19, Greg Ward
@MODIFIED   : 1997/11/25, GPW: renamed to from purify.c to string_util.c
                               added bt_change_case() and friends
@VERSION    : $Id: string_util.c,v 1.10 1999/10/28 22:50:28 greg Rel $
-------------------------------------------------------------------------- */

#include <stdlib.h>
#include <ctype.h>
#include <string.h>
#include <assert.h>
#include "error.h"
#include "btparse.h"
#include "bt_debug.h"


/* 
 * These definitions should be fixed to be consistent with HTML 
 * entities, just for fun.  And perhaps I should add entries for
 * accented letters (at least those supported by TeX and HTML).
 */
typedef enum
{
   L_OTHER,                             /* not a "foreign" letter */
   L_OSLASH_L,                          /* Eastern European {\o} */
   L_OSLASH_U,
   L_LSLASH_L,                          /* {\l} */
   L_LSLASH_U,
   L_OELIG_L,                           /* Latin {\oe} ligature */
   L_OELIG_U,
   L_AELIG_L,                           /* {\ae} ligature */
   L_AELIG_U,
   L_SSHARP_L,                          /* German "sharp s" {\ss} */
   L_SSHARP_U,
   L_ACIRCLE_L,                         /* Nordic {\aa} */
   L_ACIRCLE_U,
   L_INODOT_L,                          /* undotted i: {\i} */
   L_JNODOT_L                           /* {\j} */
} bt_letter;


static char * uc_version[] = 
{
   NULL,                                /* L_OTHER */
   "\\O",                               /* L_OSLASH_L */
   "\\O",                               /* L_OSLASH_U */
   "\\L",                               /* L_LSLASH_L */
   "\\L",                               /* L_LSLASH_U */
   "\\OE",                              /* L_OELIG_L */
   "\\OE",                              /* L_OELIG_U */
   "\\AE",                              /* L_AELIG_L */
   "\\AE",                              /* L_AELIG_U */
   "SS",                                /* L_SSHARP_L -- for LaTeX 2.09 */
   "\\SS",                              /* L_SSHARP_U */
   "\\AA",                              /* L_ACIRCLE_L */
   "\\AA",                              /* L_ACIRCLE_U */
   "I",                                 /* L_INODOT_L */
   "J"                                  /* L_JNODOT_L */
};

static char * lc_version[] = 
{
   NULL,                                /* L_OTHER */
   "\\o",                               /* L_OSLASH_L */
   "\\o",                               /* L_OSLASH_U */
   "\\l",                               /* L_LSLASH_L */
   "\\l",                               /* L_LSLASH_U */
   "\\oe",                              /* L_OELIG_L */
   "\\oe",                              /* L_OELIG_U */
   "\\ae",                              /* L_AELIG_L */
   "\\ae",                              /* L_AELIG_U */
   "\\ss",                              /* L_SSHARP_L */
   "\\ss",                              /* L_SSHARP_U */
   "\\aa",                              /* L_ACIRCLE_L */
   "\\aa",                              /* L_ACIRCLE_U */
   "\\i",                               /* L_INODOT_L */
   "\\j"                                /* L_JNODOT_L */
};      



/* ------------------------------------------------------------------------
@NAME       : foreign_letter()
@INPUT      : str
              start
              stop
@OUTPUT     : letter
@RETURNS    : TRUE if the string delimited by start and stop is a foreign
              letter control sequence
@DESCRIPTION: Determines if a character sequence is one of (La)TeX's
              "foreign letter" control sequences (l, o, ae, oe, aa, ss, plus
              uppercase versions).  If `letter' is non-NULL, returns which
              letter was found in it (as a bt_letter value).
@CALLS      : 
@CALLERS    : purify_special_char()
@CREATED    : 1997/10/19, GPW
@MODIFIED   : 
-------------------------------------------------------------------------- */
static boolean
foreign_letter (char *str, int start, int stop, bt_letter * letter)
{
   char      c1, c2;
   bt_letter dummy;


   /* 
    * This is written for speed, not flexibility -- adding new foreign
    * letters would be trying and vexatious.
    * 
    * N.B. my gold standard list of foreign letters is Kopka and Daly's
    * *A Guide to LaTeX 2e*, section 2.5.6.
    */

   if (letter == NULL)                  /* so we can assign to *letter */
      letter = &dummy;                  /* without compunctions */
   *letter = L_OTHER;                   /* assume not a "foreign" letter */

   c1 = str[start+0];                   /* only two characters that we're */
   c2 = str[start+1];                   /* interested in */

   switch (stop - start)
   {
      case 1:                           /* one-character control sequences */
         switch (c1)                    /* (\o and \l) */
         {
            case 'o':
               *letter = L_OSLASH_L; return TRUE;
            case 'O':
               *letter = L_OSLASH_U; return TRUE;
            case 'l':
               *letter = L_LSLASH_L; return TRUE;
            case 'L': 
               *letter = L_LSLASH_L; return TRUE;
            case 'i':
               *letter = L_INODOT_L; return TRUE;
            case 'j':
               *letter = L_JNODOT_L; return TRUE;
            default:
               return FALSE;
         }
         break;
      case 2:                           /* two character control sequences */
         switch (c1)                    /* (\oe, \ae, \aa, and \ss) */
         {
            case 'o':
               if (c2 == 'e') { *letter = L_OELIG_L; return TRUE; }
            case 'O':
               if (c2 == 'E') { *letter = L_OELIG_U; return TRUE; }

            /* BibTeX 0.99 does not handle \aa and \AA -- but I do!*/
            case 'a':
               if (c2 == 'e')
                  { *letter = L_AELIG_L; return TRUE; }
               else if (c2 == 'a')
                  { *letter = L_ACIRCLE_L; return TRUE; }
               else
                  return FALSE;
            case 'A':
               if (c2 == 'E')
                  { *letter = L_AELIG_U; return TRUE; }
               else if (c2 == 'A')
                  { *letter = L_ACIRCLE_U; return TRUE; }
               else
                  return FALSE;

            /* uppercase sharp-s -- new with LaTeX 2e (so far all I do
             * is recognize it as a "foreign" letter)
             */
            case 's':
               if (c2 == 's')
                  { *letter = L_SSHARP_L; return TRUE; }
               else 
                  return FALSE;
            case 'S':
               if (c2 == 'S')
                  { *letter = L_SSHARP_U; return TRUE; }
               else 
                  return FALSE;
         }
         break;
      default:
         return FALSE;
   } /* switch on length of control sequence */

   internal_error ("foreign_letter(): should never reach end of function");
   return FALSE;                        /* to keep gcc -Wall happy */

} /* foreign_letter */


/* ------------------------------------------------------------------------
@NAME       : purify_special_char()
@INPUT      : *src, *dst - pointers into the input and output strings
@OUTPUT     : *src       - updated to point to the closing brace of the 
                           special char
              *dst       - updated to point to the next available spot
                           for copying text to
@RETURNS    : 
@DESCRIPTION: "Purifies" a BibTeX special character.  On input, *src should
              point to the opening brace of a special character (ie. the
              brace must be at depth 0 of the whole string, and the
              character immediately following it must be a backslash).
              *dst should point to the next spot to copy into the output
              (purified) string.  purify_special_char() will skip over the
              opening brace and backslash; if the control sequence is one
              of LaTeX's foreign letter sequences (as determined by
              foreign_letter()), then it is simply copied to *dst.
              Otherwise the control sequence is skipped.  In either case,
              text after the control sequence is either copied (alphabetic
              characters) or skipped (anything else, including hyphens,
              ties, and digits).
@CALLS      : foreign_letter()
@CALLERS    : bt_purify_string()
@CREATED    : 1997/10/19, GPW
@MODIFIED   : 
-------------------------------------------------------------------------- */
static void
purify_special_char (char *str, int * src, int * dst)
{
   int    depth;
   int    peek;

   assert (str[*src] == '{' && str[*src + 1] == '\\');
   depth = 1;

   *src += 2;                           /* jump to start of control sequence */
   peek = *src;                         /* scan to end of control sequence */
   while (isalpha (str[peek]))
      peek++;
   if (peek == *src)                    /* in case of single-char, non-alpha */
      peek++;                           /* control sequence (eg. {\'e}) */

   if (foreign_letter (str, *src, peek, NULL))
   {
      assert (peek - *src == 1 || peek - *src == 2);
      str[(*dst)++] = str[(*src)++];    /* copy first char */
      if (*src < peek)                  /* copy second char, downcasing */
         str[(*dst)++] = tolower (str[(*src)++]);
   }
   else                                 /* not a foreign letter -- skip */
   {                                    /* the control sequence entirely */
      *src = peek;
   }

   while (str[*src])
   {
      switch (str[*src])
      {
         case '{':
            depth++;
            (*src)++;
            break;
         case '}':
            depth--;
            if (depth == 0) return;     /* done with special char */
            (*src)++;
            break;
         default:
            if (isalpha (str[*src]))    /* copy alphabetic chars */
               str[(*dst)++] = str[(*src)++];
            else                        /* skip everything else */
               (*src)++;
      }
   }

   /* 
    * If we get here, we have unbalanced braces -- the '}' case should
    * always hit a depth == 0 point if braces are balanced.  No warning,
    * though, because a) BibTeX doesn't warn about purifying unbalanced
    * strings, and b) we (should have) already warned about it in the
    * lexer.
    */

} /* purify_special_char() */


/* ------------------------------------------------------------------------
@NAME       : bt_purify_string()
@INOUT      : instr
@INPUT      : options
@OUTPUT     : 
@RETURNS    : instr   - same as input string, but modified in place
@DESCRIPTION: "Purifies" a BibTeX string.  This consists of copying
              alphanumeric characters, converting hyphens and ties to
              space, copying spaces, and skipping everything else.  (Well,
              almost -- special characters are handled specially, of
              course.  Basically, accented letters have the control
              sequence skipped, while foreign letters have the control
              sequence preserved in a reasonable manner.  See
              purify_special_char() for details.)
@CALLS      : purify_special_char()
@CALLERS    : 
@CREATED    : 1997/10/19, GPW
@MODIFIED   : 
-------------------------------------------------------------------------- */
void
bt_purify_string (char * string, ushort options)
{
   int    src,                          /* both indeces into string */
          dst;
   int    depth;                        /* brace depth in string */
   unsigned orig_len;

   /* 
    * Since purification always copies or deletes chars, outstr will
    * be no longer than string -- so nothing fancy is required to put
    * an upper bound on its eventual size.
    */

   depth = 0;
   src = 0;
   dst = 0;
   orig_len = strlen (string);

   DBG_ACTION (1, printf ("bt_purify_string(): input = %p (%s)\n", 
                          string, string));

   while (string[src] != (char) 0)
   {
      DBG_ACTION (2, printf ("  next: >%c<: ", string[src]));
      switch (string[src])
      {
         case '~':                      /* "separator" characters -- */
         case '-':                      /* replaced with space */
         case ' ':                      /* and copy an actual space */
            string[dst++] = ' ';
            src++;
            DBG_ACTION (2, printf ("replacing with space"));
            break;
         case '{':
            if (depth == 0 && string[src+1] == '\\')
            {
               DBG_ACTION (2, printf ("special char found"));
               purify_special_char (string, &src, &dst);
            }
            else
            {
               DBG_ACTION (2, printf ("ordinary open brace"));
               src++;
            }
            depth++;
            break;
         case '}':
            DBG_ACTION (2, printf ("close brace"));
            depth--;
            src++;
            break;
         default:
            if (isalnum (string[src]))         /* any alphanumeric char -- */
            {
               DBG_ACTION (2, printf ("alphanumeric -- copying"));
               string[dst++] = string[src++]; /* copy it */
            }
            else                        /* anything else -- skip it */
            {
               DBG_ACTION (2, printf ("non-separator, non-brace, non-alpha"));
               src++;
            }
      } /* switch string[src] */

      DBG_ACTION (2, printf ("\n"));

   } /* while string[src] */

   DBG_ACTION (1, printf ("bt_purify_string(): depth on exit: %d\n", depth));

   string[dst] = (char) 0;
   assert (strlen (string) <= orig_len);
} /* bt_purify_string() */


/* ======================================================================
 * Case-transformation stuff
 */


/* ------------------------------------------------------------------------
@NAME       : convert_special_char()
@INPUT      : transform
@INOUT      : string
              src
              dst
              start_sentence
              after_colon
@RETURNS    : 
@DESCRIPTION: Does case conversion on a special character.
@GLOBALS    : 
@CALLS      : 
@CALLERS    : 
@CREATED    : 1997/11/25, GPW
@MODIFIED   : 
-------------------------------------------------------------------------- */
static void
convert_special_char (char transform, 
                      char * string,
                      int * src,
                      int * dst, 
                      boolean * start_sentence,
                      boolean * after_colon)
{
   int       depth;
   boolean   done_special;
   int       cs_end;
   int       cs_len;                    /* counting the backslash */
   bt_letter letter;
   char *    repl;
   int       repl_len;

#ifndef ALLOW_WARNINGS
   repl = NULL;                         /* silence "might be used" */
                                        /* uninitialized" warning */
#endif

   /* First, copy just the opening brace */
   string[(*dst)++] = string[(*src)++];

   /* 
    * Now loop over characters inside the braces -- stop when we reach
    * the matching close brace, or when the string ends.
    */
   depth = 1;                           /* because we're in a special char */
   done_special = FALSE;

   while (string[*src] != 0 && !done_special)
   {
      switch (string[*src])
      {
         case '\\':                     /* a control sequence */
         {
            cs_end = *src+1;            /* scan over chars of c.s. */
            while (isalpha (string[cs_end])) 
               cs_end++;

            /* 
             * OK, now *src points to the backslash (so src+*1 points to
             * first char. of control sequence), and cs_end points to
             * character immediately following end of control sequence.
             * Thus we analyze [*src+1..cs_end] to determine if the control
             * sequence is a foreign letter, and use (cs_end - (*src+1) + 1)
             * = (cs_end - *src) as the length of the control sequence.
             */

            cs_len = cs_end - *src;     /* length of cs, counting backslash */

            if (foreign_letter (string, *src+1, cs_end, &letter))
            {
               if (letter == L_OTHER)
                  internal_error ("impossible foreign letter");

               switch (transform)
               {
                  case 'u':
                     repl = uc_version[(int) letter];
                     break;
                  case 'l':
                     repl = lc_version[(int) letter];
                     break;
                  case 't':
                     if (*start_sentence || *after_colon)
                     {
                        repl = uc_version[(int) letter];
                        *start_sentence = *after_colon = FALSE;
                     }
                     else
                     {
                        repl = lc_version[(int) letter];
                     }
                     break;
                  default:
                     internal_error ("impossible case transform \"%c\"",
                                     transform);
               }

               repl_len = strlen (repl);
               if (repl_len > cs_len)
                  internal_error
                     ("replacement text longer than original cs");

               strncpy (string + *dst, repl, repl_len);
               *src = cs_end;
               *dst += repl_len;
            } /* control sequence is a foreign letter */
            else
            {
               /* not a foreign letter -- just copy the control seq. as is */


               strncpy (string + *dst, string + *src, cs_end - *src);
               *src += cs_len;
               assert (*src == cs_end);
               *dst += cs_len;
            } /* control sequence not a foreign letter */

            break;
         } /* case: '\\' */

         case '{':
         {
            string[(*dst)++] = string[(*src)++];
            depth++;
            break;
         }

         case '}':
         {
            string[(*dst)++] = string[(*src)++];
            depth--;
            if (depth == 0)
               done_special = TRUE;
            break;
         }

         default:                       /* any other character */
         {
            switch (transform)
            {
               /* 
                * Inside special chars, lowercase and title caps are same.
                * (At least, that's bibtex's convention.  I might change this
                * at some point to be a bit smarter.)
                */
               case 'l':
               case 't':
                  string[(*dst)++] = tolower (string[(*src)++]);
                  break;
               case 'u':
                  string[(*dst)++] = toupper (string[(*src)++]);
                  break;
               default:
                  internal_error ("impossible case transform \"%c\"",
                                  transform);
            }
         } /* default char */

      } /* switch: current char */

   } /* while: string or special char not done */

} /* convert_special_char() */


/* ------------------------------------------------------------------------
@NAME       : bt_change_case()
@INPUT      : 
@OUTPUT     : 
@RETURNS    : 
@DESCRIPTION: Converts a string (in-place) to either uppercase, lowercase,
              or "title capitalization">
@GLOBALS    : 
@CALLS      : 
@CALLERS    : 
@CREATED    : 1997/11/25, GPW
@MODIFIED   : 
-------------------------------------------------------------------------- */
void
bt_change_case (char   transform,
                char * string,
                ushort options)
{
   int    len;
   int    depth;
   int    src, dst;                     /* indeces into string */
   boolean start_sentence;
   boolean after_colon;

   src = dst = 0;
   len = strlen (string);
   depth = 0;

   start_sentence = TRUE;
   after_colon = FALSE;

   while (string[src] != 0)
   {
      switch (string[src])
      {
         case '{': 

            /* 
             * At start of special character?  The entire special char.
             * will be handled here, as follows:
             *   - text at any brace-depth within the s.c. is case-mangled;
             *     punctuation (sentence endings, colons) are ignored
             *   - control sequences are left alone, unless they are
             *     one of the "foreign letter" control sequences, in
             *     which case they're converted to the appropriate string
             *     according to the uc_version or lc_version tables.
             */
            if (depth == 0 && string[src+1] == '\\')
            {
               convert_special_char (transform, string, &src, &dst, 
                                     &start_sentence, &after_colon);
            }

            /*
             * Otherwise, it's just something in braces.  This is probably
             * a proper noun or something encased in braces to protect it
             * from case-mangling, so we do not case-mangle it.  However,
             * we *do* switch out of start_sentence or after_colon mode if
             * we happen to be there (otherwise we'll do the wrong thing
             * once we're out of the braces).
             */
            else
            {
               string[dst++] = string[src++];
               start_sentence = after_colon = FALSE;
               depth++;
            }
            break;

         case '}':
            string[dst++] = string[src++];
            depth--;
            break;

         /*
          * Sentence-ending punctuation and colons are handled separately
          * to allow for exact mimicing of BibTeX's behaviour.  I happen
          * to think that this behaviour (capitalize first word of sentences
          * in a title) is better than BibTeX's, but I want to keep my
          * options open for a future goal of perfect compatability.
          */
         case '.':
         case '?':
         case '!':
            start_sentence = TRUE;
            string[dst++] = string[src++];
            break;

         case ':':
            after_colon = TRUE;
            string[dst++] = string[src++];
            break;

         default:
            if (isspace (string[src]))
            {
               string[dst++] = string[src++];
            }
            else
            {
               if (depth == 0)
               {
                  switch (transform)
                  {
                     case 'u':
                        string[dst++] = toupper (string[src++]);
                        break;
                     case 'l':
                        string[dst++] = tolower (string[src++]);
                        break;
                     case 't':
                        if (start_sentence || after_colon)
                        {
                           /* 
                            * XXX BibTeX only preserves case of character
                            * immediately after a colon; I do two things
                            * differently: first, I pay attention to sentence
                            * punctuation, and second I force uppercase
                            * at start of sentence or after a colon.
                            */
                           string[dst++] = toupper (string[src++]);
                           start_sentence = after_colon = FALSE;
                        }
                        else
                        {
                           string[dst++] = tolower (string[src++]);
                        }
                        break;
                     default:
                        internal_error ("impossible case transform \"%c\"",
                                        transform);
                  }
               } /* depth == 0 */
               else
               {
                  string[dst++] = string[src++];
               }
            } /* not blank */
      } /* switch on current character */
                                  
   } /* while not at end of string */

} /* bt_change_case */
