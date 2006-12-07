#include <stdlib.h>
#include <stdio.h>
#include "my_dmalloc.h"
#include "btparse.h"

void postprocess (char *);

void postprocess (char * string)
{
   char * buf;

   buf = (char *) malloc (strlen(string) + 1);
   strcpy (buf, string);
   bt_postprocess_string (buf, 0);
   printf ("[%s] -> [%s] (no collapse)\n", string, buf);
   bt_postprocess_string (buf, BTO_COLLAPSE);
   printf ("[%s] -> [%s] (collapse)\n", string, buf);
   free (buf);
}

int main (void)
{
   postprocess ("vanilla string");
   postprocess ("nospace");
   postprocess ("inner    space");
   postprocess (" leading");
   postprocess ("    leading");
   postprocess ("trailing ");   
   postprocess ("trailing   ");   
   postprocess ("");   
   postprocess ("   leading&trailing   ");   
   postprocess ("   leading & trailing   ");   
   postprocess ("   leading   and internal");   
   postprocess ("internal    and trailing   ");   
   postprocess ("    everything   at   once   ");

   return 0;
}
   
