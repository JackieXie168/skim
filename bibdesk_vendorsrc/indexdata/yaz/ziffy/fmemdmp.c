/*
 * -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
 * fmemdmp.c - tracing utilities
 *
 * Copyright (c) 1998-2001 R. Carbone <rocco@ntop.org>
 * -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */



/*
 * Operating System include files
 */
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdarg.h>
#include <ctype.h>

#include <time.h>
#if HAVE_SYS_TIME_H
# include <sys/time.h>
#endif


/*
 * Pretty print function.
 *
 * This function dumps a buffer in memory in the (pretty !!) format :
 *
 *   off:  printable          hexadecimal notation
 * --------------------------------------------------------------------------
 *
 * Dump of memory area at address 0x10000444 for 51 bytes
 *     0:  abcdefghijklmnop   61 62 63 64 65 66 67 68 69 6a 6b 6c 6d 6e 6f 70
 *    16:  qrstuvzxyw012345   71 72 73 74 75 76 7a 78 79 77 30 31 32 33 34 35
 *    32:  6789~!@#$%^&*()_   36 37 38 39 7e 21 40 23 24 25 5e 26 2a 28 29 5f
 *    48:  -+=                2d 2b 3d
 *
 * Dump of memory area at address 0x7fffbc03 for 16 bytes
 *    0:  rocco@tecsiel.it    72 6f 63 63 6f 40 74 65 63 73 69 65 6c 2e 69 74
 */
void fmemdmp (FILE * fd, char * ptr, int size, char * text)
{
  int offset = 0;
  int i = 0;
  int bytes_in_a_line = 16;
  unsigned int total;

  if (! ptr || size <= 0)
    return;

  if (text && * text)
    fprintf (fd, "\"%s\" at address 0x%08x for %d bytes\n",
	     text, (unsigned int) ptr, size);

  for (total = 0; total < size; total += bytes_in_a_line)
    {
      /*
       * Print the offset
       */
      fprintf (fd, "%6d:  ", offset);
      /*
       * Print the bytes in a line (each byte in ASCII notation)
       */
      for (i = 0; i < bytes_in_a_line; i ++)
	if (total + i < size)
	  fprintf (fd, "%c",
		   isprint (* (ptr + total + i) & 0x000000ff)
		   ? (* (ptr + total + i))
		   : '.');
	else
	  fprintf (fd, " "); /* 1 blank character */
      /*
       * Print the separator
       */
      fprintf (fd, "  ");
      /*
       * Print the bytes in a line (each byte in Hexadecimal notation)
       */
      for (i = 0; i < bytes_in_a_line && i < size; i ++)
	if (total + i < size)
	  fprintf (fd, "%02x ",
		   * (ptr + total + i) & 0x000000ff);
	else
	  fprintf (fd, "   "); /* 3 more blanks characters */

      fprintf (fd, "\n");
      offset += bytes_in_a_line;
    }
  fflush (fd);
}
