/*
 * read_test.c
 * 
 * finding bugs related to reading from an empty file, reading twice
 * at eof, parsing an empty string, etc.
 */

#include "bt_config.h"               /* for dmalloc() stuff */
#include <stdlib.h>

#include "testlib.h"
#include "my_dmalloc.h"


int main (void)
{
   char    filename[256];
   FILE *  infile;
   AST *   entry;
   boolean entry_ok,
           ok = TRUE;;

   bt_initialize ();

   /* 
    * First test -- try to read an entry from an empty file.  This 
    * triggers an "unexpected eof" syntax error, and puts the file
    * at eof -- but doesn't do the eof processing (that's for the next
    * call).
    */
   infile = open_file ("empty.bib", DATA_DIR, filename);
   CHECK (!feof (infile))
   entry = bt_parse_entry (infile, filename, 0, &entry_ok);
   CHECK (feof (infile))
   CHECK (entry == NULL);               /* because no entry found */
   CHECK (!entry_ok);                   /* and this causes a syntax error */

   /* Now that we're at eof, read again -- this does the normal eof cleanup */
   entry = bt_parse_entry (infile, filename, 0, &entry_ok);
   CHECK (entry == NULL);               /* because at eof */
   CHECK (entry_ok);                    /* ditto */

   /* 
    * And now do an excess read -- this used to crash the library; now it
    * just triggers a "usage warning".
    */
   entry = bt_parse_entry (infile, filename, 0, &entry_ok);
   CHECK (entry == NULL);
   CHECK (entry_ok);

   /* 
    * Try to parse an empty string; should trigger a syntax error (eof
    * when expected an entry), so entry_ok will be false.
    */
   entry = bt_parse_entry_s ("", NULL, 1, 0, &entry_ok);
   CHECK (entry == NULL);
   CHECK (! entry_ok);

   /* 
    * Try to parse a string with just junk (nothing entry-like) in it --
    * should cause syntax error just like the empty string.
    */
   entry = bt_parse_entry_s ("this is junk", NULL, 1, 0, &entry_ok);
   CHECK (entry == NULL);
   CHECK (! entry_ok);

   /* Tell bt_parse_entry_s() to cleanup after itself */
   entry = bt_parse_entry_s (NULL, NULL, 1, 0, NULL); 
   CHECK (entry == NULL);

   bt_cleanup ();
   
   if (! ok)
   {
      printf ("Some tests failed\n");
      exit (1);
   }
   else
   {
      printf ("All tests successful\n");
      exit (0);
   }

} /* main() */
