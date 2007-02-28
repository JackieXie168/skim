/*
 * -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
 * yaz.c - decoding and printing utility based on the YAZ Toolkit
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
#include <sys/time.h>

/*
 * YAZ include files
 */
#include "yaz/odr.h"
#include "yaz/proto.h"

#include "apdu.h"


void please_yaz_help_me (z3950apdu * hook)
{
  extern unsigned char * z3950;
  extern int z3950_size;

  /*
   * Variable to keep the Z39.50 APDUs. The definitions are in the
   * the structures defined by the YAZ Toolkit.
   */
  Z_APDU * apdu = NULL;

  /*
   * Decoding/Printing streams
   */
  ODR printing;
  ODR decode;

  /*
   * The stream used for decoding
   */
#define MAXBERSIZE (2048 * 2048)
  unsigned char berbuffer [MAXBERSIZE];

  /*
   * Allocate a stream for input data
   */
  decode = odr_createmem (ODR_DECODE);
  if (! decode)
    {
      printf ("Not enough memory to create an input stream\n");
      return;
    }

  /*
   * Allocate a stream for printing data
   */
  printing = odr_createmem (ODR_PRINT);
  if (! printing)
    {
      printf ("Not enough memory to create a printing stream\n");
      odr_destroy (decode);
      return;
    }

  /*
   * Initialize the decoding routines
   */
  memcpy (berbuffer, z3950, z3950_size);

  odr_setbuf (decode, (char *) berbuffer, z3950_size, 0);

  /*
   * Perform BER decoding
   */
  if (z_APDU (decode, & apdu, 0, 0))
    {
      ++ z3950_apduno;

      if (z3950flag)
	printf ("Z3950:  ----- Z39.50 APDU -----\n"),
	  printf ("Z3950:  APDU %ld arrived at %s\n", z3950_apduno,
		  timestamp (hook -> t, ABS_FMT)),
	  printf ("Z3950:  Total size  = %d\n", z3950_size),
	  fflush (stdout);

      /*
       * save the time the last apdu was displayed
       */
      if (z3950_apduno == 1)
	gettimeofday (& first_apdu, NULL);

      /*
       * print standard summary information accordingly to the format
       *
       * id   time     source:port ->   destination:port    type
       */
      printf ("Z3950: %5ld %s %s:%d -> %s:%d %s\n",
	      z3950_apduno, timestamp (hook -> t, DELTA_FMT),
	      hook -> calling, hook -> srcport, hook -> called, hook -> dstport,
	      hook -> name),
	fflush (stdout);

      gettimeofday (& last_apdu, NULL);

#if (0)
      fmemdmp (stdout, z3950, z3950_size, "Z39.50 APDU");
#endif

      /*
       * Yup! We have the APDU now. Try to print it
       */
      odr_setbuf (printing, (char *) berbuffer, z3950_size, 0);
      fflush (stdout);

      z_APDU (printing, & apdu, 0, 0);
      fflush (stderr);

      odr_reset (printing);
      printing -> buf = NULL;
    }

  /*
   * release memory previously allocated
   */
  odr_destroy (decode);
  odr_destroy (printing);
}
