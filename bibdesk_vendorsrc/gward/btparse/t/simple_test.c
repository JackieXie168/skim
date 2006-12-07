/* ------------------------------------------------------------------------
@NAME       : simple_test.c
@INPUT      : 
@OUTPUT     : 
@RETURNS    : 
@DESCRIPTION: Run some basic tests on some simple data.  The .bib files
              processed here are all free of errors, and use just the basic
              BibTeX syntax.  This is just to make sure the parser and
              library are working in the crudest sense; more elaborate
              tests will someday performed elsewhere (I hope).
@GLOBALS    : 
@CALLS      : 
@CALLERS    : 
@CREATED    : 1997/07/29, Greg Ward
@MODIFIED   : 
@VERSION    : $Id: simple_test.c,v 1.13 2000/03/23 03:39:48 greg Exp $
@COPYRIGHT  : Copyright (c) 1996-97 by Gregory P. Ward.  All rights reserved.

              This file is part of the btparse distribution (but not part
              of the library itself).  This is free software; you can
              redistribute it and/or modify it under the terms of the GNU
              General Public License as published by the Free Software
              Foundation; either version 2 of the License, or (at your
              option) any later version.
-------------------------------------------------------------------------- */

#include "bt_config.h"
#include <stdlib.h>
#include <string.h>
#include "btparse.h"
#include "testlib.h"
#include "my_dmalloc.h"

int test_num = 0;


typedef enum { single, multiple, wholefile } test_mode;

typedef struct
{
   int    num_fields;
   char **fields;
   int    num_values;
   char **values;
   bt_nodetype * ntypes;
} test_data;

typedef boolean (*tester) (AST *, test_data *);

typedef struct
{
   char *      desc;
   char *      filename;
   ushort      options;
   tester      test_func;
   test_data * data;
} test;

/* prototypes needed for defining the tests[] array */
boolean eviltest_regular (AST *entry, test_data *data);
boolean eviltest_macro (AST *entry, test_data *data);
boolean eviltest_comment (AST *entry, test_data *data);
boolean eviltest_preamble (AST *entry, test_data *data);
boolean goodtest_regular (AST *entry, test_data *data);
boolean goodtest_macro (AST *entry, test_data *data);
boolean goodtest_comment (AST *entry, test_data *data);
boolean goodtest_preamble (AST *entry, test_data *data);

/* and prototypes to keep "gcc -Wall" from whining */
boolean test_multiple (FILE *, char *, ushort, ushort, int, test *);
boolean test_wholefile (char *, ushort, ushort, int, test *);


/* a priori knowledge about the entry in "regular.bib" (used for both tests) */
char * regular_fields[] = { "title", "editor", "publisher", "year" };
char * regular_values[] = 
  { "A ", "Book", "  John Q.  Random", "junk", "Foo Bar \\& Sons", "1922" };
char * regular_values_proc[] = 
  { "A Book", "John Q. Random", "Foo Bar \\& Sons", "1922" };
bt_nodetype regular_ntypes[] = 
  { BTAST_STRING, BTAST_STRING, BTAST_STRING, BTAST_MACRO, BTAST_STRING, BTAST_NUMBER };
bt_nodetype regular_ntypes_proc[] = 
  { BTAST_STRING, BTAST_STRING, BTAST_STRING, BTAST_STRING };

/* likewise for "macro.bib" */
char * macro_macros[] = { "macro", "foo" };
char * macro_values[] = 
  { "macro  text ", "blah blah  ", " ding dong " };
char * macro_values_proc[] = 
  { "macro text", "blah blah ding dong" };
bt_nodetype macro_ntypes[] = { BTAST_STRING, BTAST_STRING, BTAST_STRING };

/* and for "comment.bib" */
char * comment_value = "this is a comment entry, anything at all can go in it (as long          as parentheses are balanced), even {braces}";
char * comment_value_proc = "this is a comment entry, anything at all can go in it (as long as parentheses are balanced), even {braces}";

/* and for "preamble.bib" */
char * preamble_values[] = 
   { " This is   a preamble",
     "---the concatenation of several strings" };
char * preamble_value_proc = 
   "This is a preamble---the concatenation of several strings";

test_data regular_unproc_data =
   { 4, regular_fields, 6, regular_values, regular_ntypes };
test_data regular_proc_data =
   { 4, regular_fields, 4, regular_values_proc, regular_ntypes_proc };
test_data macro_unproc_data =
   { 2, macro_macros, 3, macro_values, macro_ntypes };
test_data macro_proc_data =
   { 2, macro_macros, 2, macro_values_proc, macro_ntypes };
test_data comment_unproc_data = 
   { 0, NULL, 1, &comment_value, NULL };
test_data comment_proc_data = 
   { 0, NULL, 1, &comment_value_proc, NULL };
test_data preamble_unproc_data = 
   { 0, NULL, 2, preamble_values, NULL };
test_data preamble_proc_data = 
   { 0, NULL, 1, &preamble_value_proc, NULL };


test tests[] = 
{
   { "regular entry (unprocessed, low-level scan)",
     "regular.bib", BTO_MINIMAL,
     eviltest_regular, &regular_unproc_data
   },
   { "macro entry (unprocessed, low-level scan)",
     "macro.bib", BTO_MINIMAL,
     eviltest_macro, &macro_unproc_data
   },
   { "comment entry (unprocessed, low-level scan)",
     "comment.bib", BTO_MINIMAL,
     eviltest_comment, &comment_unproc_data
   },
   { "preamble entry (unprocessed, low-level scan)",
     "preamble.bib", BTO_MINIMAL,
     eviltest_preamble, &preamble_unproc_data
   },
   { "regular entry (unprocessed, high-level scan)",
     "regular.bib", BTO_MINIMAL,
     goodtest_regular, &regular_unproc_data
   },
   { "macro entry (unprocessed, high-level scan)",
     "macro.bib", BTO_MINIMAL,
     goodtest_macro, &macro_unproc_data
   },
   { "comment entry (unprocessed, high-level scan)",
     "comment.bib", BTO_MINIMAL,
     goodtest_comment, &comment_unproc_data
   },
   { "preamble entry (unprocessed, high-level scan)",
     "preamble.bib", BTO_MINIMAL,
     goodtest_preamble, &preamble_unproc_data
   },
   { "regular entry (processed, low-level scan)",
     "regular.bib", BTO_FULL,
     eviltest_regular, &regular_proc_data
   },
   { "macro entry (processed, low-level scan)",
     "macro.bib", BTO_FULL,
     eviltest_macro, &macro_proc_data
   },
   { "comment entry (processed, low-level scan)",
     "comment.bib", BTO_FULL,
     eviltest_comment, &comment_proc_data
   },
   { "preamble entry (processed, low-level scan)",
     "preamble.bib", BTO_FULL,
     eviltest_preamble, &preamble_proc_data
   },
   { "regular entry (processed, high-level scan)",
     "regular.bib", BTO_FULL,
     goodtest_regular, &regular_proc_data
   },
   { "macro entry (processed, high-level scan)",
     "macro.bib", BTO_FULL,
     goodtest_macro, &macro_proc_data
   },
   { "comment entry (processed, high-level scan)",
     "comment.bib", BTO_FULL,
     goodtest_comment, &comment_proc_data
   },
   { "preamble entry (processed, high-level scan)",
     "preamble.bib", BTO_FULL,
     goodtest_preamble, &preamble_proc_data
   },
};


#define NUM_TESTS sizeof (tests) / sizeof (tests[0])


boolean eviltest_regular (AST * entry, test_data * data)
{
   boolean ok = TRUE;
   AST *   key;
   AST *   field;
   AST *   value;
   int     field_num;
   int     value_num;

   CHECK_ESCAPE (entry != NULL, return FALSE, "entry")
   CHECK (entry->nodetype == BTAST_ENTRY)
   CHECK (entry->metatype == BTE_REGULAR)
   CHECK (strcmp (entry->text, "book") == 0)

   key = entry->down;
   CHECK_ESCAPE (key != NULL, return FALSE, "entry")
   CHECK (key->nodetype == BTAST_KEY)
   CHECK (key->metatype == BTE_UNKNOWN)
   CHECK (strcmp (key->text, "abook") == 0)
   
   field = key;
   field_num = 0;
   value_num = 0;

   while ((field = field->right))
   {
      CHECK_ESCAPE (field_num < data->num_fields, break, "entry")
      CHECK (field->nodetype == BTAST_FIELD)
      CHECK (field->metatype == BTE_UNKNOWN)
      CHECK (strcmp (field->text, data->fields[field_num++]) == 0)

      value = field->down;
      while (value)
      {
         CHECK_ESCAPE (value_num < data->num_values, break, "field") 
         CHECK (value->nodetype == data->ntypes[value_num])
         CHECK (strcmp (value->text, data->values[value_num]) == 0)
         value = value->right;
         value_num++;
      }
   }
   CHECK (field_num == data->num_fields)
   CHECK (value_num == data->num_values)

   return ok;

} /* eviltest_regular () */


boolean eviltest_macro (AST * entry, test_data * data)
{
   boolean ok = TRUE;
   AST *   macro;
   AST *   value;
   int     macro_num;
   int     value_num;

   CHECK (entry != NULL)
   CHECK (entry->nodetype == BTAST_ENTRY)
   CHECK (entry->metatype == BTE_MACRODEF)
   CHECK (strcmp (entry->text, "string") == 0)

   macro_num = 0;
   value_num = 0;
   macro = entry->down;

   while (macro)
   {
      CHECK_ESCAPE (macro_num < data->num_fields, break, "entry")
      CHECK (macro->nodetype == BTAST_FIELD)
      CHECK (macro->metatype == BTE_UNKNOWN)
      CHECK (strcmp (macro->text, data->fields[macro_num++]) == 0)

      value = macro->down;
      while (value)
      {
         CHECK_ESCAPE (value_num < data->num_values, break, "macro") 
         CHECK (value->nodetype == data->ntypes[value_num])
         CHECK (strcmp (value->text, data->values[value_num]) == 0)
         value = value->right;
         value_num++;
      }
      macro = macro->right;
   }
   CHECK (macro_num == data->num_fields)
   CHECK (value_num == data->num_values)

   return ok;

} /* eviltest_macro () */


boolean eviltest_comment (AST * entry, test_data * data)
{
   boolean ok = TRUE;
   AST *   value;

   CHECK_ESCAPE (entry != NULL, return FALSE, "entry");
   CHECK (strcmp (entry->text, "comment") == 0);

   value = entry->down;
   CHECK_ESCAPE (value != NULL, return FALSE, "entry");
   CHECK (strcmp (value->text, data->values[0]) == 0);
   CHECK (value->right == NULL);
   CHECK (value->down == NULL);

   return ok;
} /* eviltest_comment () */


boolean eviltest_preamble (AST * entry, test_data * data)
{
   boolean ok = TRUE;
   AST *   value;
   int     value_num;

   CHECK_ESCAPE (entry != NULL, return FALSE, "entry");
   CHECK (strcmp (entry->text, "preamble") == 0);

   value_num = 0;
   value = entry->down;
   while (value)
   {
      CHECK_ESCAPE (value_num < data->num_values, break, "entry");
      CHECK (value->nodetype == BTAST_STRING);
      CHECK (strcmp (value->text, data->values[value_num]) == 0);

      value = value->right;
      value_num++;
   }

   CHECK (value_num == data->num_values);
   return ok;

} /* eviltest_preamble () */


boolean goodtest_regular (AST * entry, test_data * data)
{
   boolean ok = TRUE;
   AST *   field;
   AST *   value;
   char *  field_name;
   char *  value_text;
   bt_nodetype
           value_nodetype;
   int     field_num;
   int     value_num;

   CHECK (bt_entry_metatype (entry) == BTE_REGULAR);
   CHECK (strcmp (bt_entry_type (entry), "book") == 0);
   CHECK (strcmp (bt_entry_key (entry), "abook") == 0);

   field = NULL;
   field_num = 0;
   value_num = 0;

   while ((field = bt_next_field (entry, field, &field_name)))
   {
      CHECK_ESCAPE (field_num < data->num_fields, break, "entry");
      CHECK (strcmp (field_name, data->fields[field_num++]) == 0);

      value = NULL;
      while ((value = bt_next_value (field,value,&value_nodetype,&value_text)))
      {
         CHECK_ESCAPE (value_num < data->num_values, break, "field");
         CHECK (value_nodetype == data->ntypes[value_num]);
         CHECK (strcmp (value_text, data->values[value_num++]) == 0);
      }
   }

   CHECK (field_num == data->num_fields);
   CHECK (value_num == data->num_values);

   return ok;

}


boolean goodtest_macro (AST * entry, test_data * data)
{
   boolean ok = TRUE;
   AST *   macro;
   AST *   value;
   char *  macro_name;
   char *  value_text;
   bt_nodetype
           value_nodetype;
   int     macro_num;
   int     value_num;

   CHECK (bt_entry_metatype (entry) == BTE_MACRODEF);
   CHECK (strcmp (bt_entry_type (entry), "string") == 0);
   CHECK (bt_entry_key (entry) == NULL);

   macro = NULL;
   macro_num = 0;
   value_num = 0;

   while ((macro = bt_next_macro (entry, macro, &macro_name)))
   {
      CHECK_ESCAPE (macro_num < data->num_fields, break, "entry");
      CHECK (strcmp (macro_name, data->fields[macro_num++]) == 0);

      value = NULL;
      while ((value = bt_next_value (macro,value,&value_nodetype,&value_text)))
      {
         CHECK_ESCAPE (value_num < data->num_values, break, "macro");
         CHECK (value_nodetype == data->ntypes[value_num]);
         CHECK (strcmp (value_text, data->values[value_num++]) == 0);
      }
   }

   CHECK (macro_num == data->num_fields);
   CHECK (value_num == data->num_values);

   return ok;

}


boolean goodtest_comment (AST * entry, test_data * data)
{
   boolean ok = TRUE;
   AST *   value;
   char *  text;

   CHECK (bt_entry_metatype (entry) == BTE_COMMENT);
   CHECK (strcmp (bt_entry_type (entry), "comment") == 0);

   value = bt_next_value (entry, NULL, NULL, &text);
   CHECK (strcmp (text, data->values[0]) == 0);

   return ok;
}


boolean goodtest_preamble (AST * entry, test_data * data)
{
   boolean ok = TRUE;
   AST *   value;
   char *  value_text;
   bt_nodetype
           value_nodetype;
   int     value_num;

   CHECK (bt_entry_metatype (entry) == BTE_PREAMBLE);
   CHECK (strcmp (bt_entry_type (entry), "preamble") == 0);

   value = NULL;
   value_num = 0;
   while ((value = bt_next_value (entry, value, &value_nodetype, &value_text)))
   {
      CHECK_ESCAPE (value_num < data->num_values, break, "entry");
      CHECK (value_nodetype == BTAST_STRING);
      CHECK (strcmp (value_text, data->values[value_num++]) == 0);
   }

   CHECK (value_num == data->num_values);
   return ok;
}


boolean test_multiple (FILE * file,
                       char * filename,
                       ushort string_opts,
                       ushort other_opts,
                       int    num_entries,
                       test * tests)
{
   boolean entry_ok;
   boolean ok;
   int     entry_num;
   AST *   entry;

   ok = TRUE;
   entry_num = 0;

   printf ("multiple entries in one file, read individually:\n");
   set_all_stringopts (string_opts);

   while (1)
   {
      entry = bt_parse_entry (file, filename, other_opts, &entry_ok);
      if (!entry) break;                /* at eof? */
      
      CHECK_ESCAPE (entry_num < num_entries, break, "file");

      entry_ok &= tests[entry_num].test_func (entry, tests[entry_num].data);
      printf ("  %s: %s\n",
              tests[entry_num].desc,
              entry_ok ? "ok" : "not ok");
      entry_num++;
      bt_free_ast (entry);
      
      ok &= entry_ok;
   }
                       
   CHECK (entry_num == num_entries);
   printf ("...%s\n", ok ? "all ok" : "not all ok");
   return ok;

}


boolean test_wholefile (char * filename,
                        ushort string_opts,
                        ushort other_opts,
                        int    num_entries,
                        test * tests)
{
   boolean entry_ok;
   boolean ok;
   int     entry_num;
   AST *   entries,
       *   entry;

   ok = TRUE;
   entry_num = 0;

   printf ("multiple entries in one file, read together:\n");
   set_all_stringopts (string_opts);
   entries = bt_parse_file (filename, other_opts, &entry_ok);
   CHECK (entry_ok);

   entry = NULL;
   while ((entry = bt_next_entry (entries, entry)))
   {
      CHECK_ESCAPE (entry_num < num_entries, break, "file");

      entry_ok = tests[entry_num].test_func (entry, tests[entry_num].data);
      printf ("  %s: %s\n",
              tests[entry_num].desc,
              entry_ok ? "ok" : "not ok");
      entry_num++;
      
      ok &= entry_ok;
   }
                       
   CHECK (entry_num == num_entries);
   bt_free_ast (entries);
   printf ("...%s\n", ok ? "all ok" : "not all ok");
   return ok;

}


int main (void)
{
   unsigned i;
   char    filename[256];
   FILE *  infile;
   AST *   entry;
   ushort  options = 0;                 /* use default non-string options */
   boolean ok;
   int     num_failures = 0;

   bt_initialize ();

   for (i = 0; i < NUM_TESTS; i++)
   {
      infile = open_file (tests[i].filename, DATA_DIR, filename);

      /* Override string-processing options for all entry metatypes */
      set_all_stringopts (tests[i].options);

      entry = bt_parse_entry (infile, filename, options, &ok);
      ok &= tests[i].test_func (entry, tests[i].data);
      bt_free_ast (entry);
      entry = bt_parse_entry (infile, filename, options, NULL);
      CHECK ((entry == NULL));
      CHECK (feof (infile));
      fclose (infile);

      printf ("%s: %s\n", tests[i].desc, ok ? "ok" : "not ok");
      if (!ok) num_failures++;
   } /* for i */

   infile = open_file ("simple.bib", DATA_DIR, filename);
   if (! test_multiple (infile, filename, BTO_MINIMAL, options, 4, tests+4))
      num_failures++;
   rewind (infile);
   if (! test_multiple (infile, filename, BTO_FULL, options, 4, tests+12))
      num_failures++;

   fclose (infile);

   if (! test_wholefile (DATA_DIR "/" "simple.bib",
                         BTO_MINIMAL, options, 4, tests+4))
      num_failures++;
   if (! test_wholefile (DATA_DIR "/" "simple.bib",
                         BTO_FULL, options, 4, tests+12))
      num_failures++;

   bt_cleanup ();

   if (num_failures == 0)
      printf ("All tests successful\n");
   else
      printf ("%d failed tests\n", num_failures);

   return (num_failures > 0);
}
