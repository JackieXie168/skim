/*
 * -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
 * apdu.c - 
 *
 * Copyright (c) 1998-2001 R. Carbone <rocco@tecsiel.it> - Finsiel S.p.A.
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

#include <time.h>
#if HAVE_SYS_TIME_H
#include <sys/time.h>
#endif

#include <sys/types.h>

#include "apdu.h"

/*
 * The table of z3950 apdus
 */
static z3950apdu apdutable [] =
{
  { 20, "INIT request",      -1, NULL, NULL, 0, NULL, 0 },
  { 21, "INIT response",     -1, NULL, NULL, 0, NULL, 0 },
  { 22, "SEARCH request",    -1, NULL, NULL, 0, NULL, 0 },
  { 23, "SEARCH response",   -1, NULL, NULL, 0, NULL, 0 },
  { 24, "PRESENT request",   -1, NULL, NULL, 0, NULL, 0 },
  { 25, "PRESENT response",  -1, NULL, NULL, 0, NULL, 0 },
  { 26, "DELETE request",    -1, NULL, NULL, 0, NULL, 0 },
  { 27, "DELETE response",   -1, NULL, NULL, 0, NULL, 0 },
  { 28, "ACCESS request",    -1, NULL, NULL, 0, NULL, 0 },
  { 29, "ACCESS response",   -1, NULL, NULL, 0, NULL, 0 },
  { 30, "RESOURCE request",  -1, NULL, NULL, 0, NULL, 0 },
  { 31, "RESOURCE response", -1, NULL, NULL, 0, NULL, 0 },
  { 32, "TRIGGER request",   -1, NULL, NULL, 0, NULL, 0 },
  { 33, "REPORT request",    -1, NULL, NULL, 0, NULL, 0 },
  { 34, "REPORT response",   -1, NULL, NULL, 0, NULL, 0 },
  { 35, "SCAN request",      -1, NULL, NULL, 0, NULL, 0 },
  { 36, "SCAN response",     -1, NULL, NULL, 0, NULL, 0 },

  { 43, "SORT request",      -1, NULL, NULL, 0, NULL, 0 },
  { 44, "SORT response",     -1, NULL, NULL, 0, NULL, 0 },
  { 45, "SEGMENT request",   -1, NULL, NULL, 0, NULL, 0 },
  { 46, "EXTENDED request",  -1, NULL, NULL, 0, NULL, 0 },
  { 47, "EXTENDED response", -1, NULL, NULL, 0, NULL, 0 },
  { 48, "CLOSE request",     -1, NULL, NULL, 0, NULL, 0 },

  { 0 },
};


z3950apdu * lookup (int tag)
{
  z3950apdu * found = apdutable;

  for (found = apdutable; found < apdutable +
	 (sizeof (apdutable) / sizeof (apdutable [0])); found ++)
    if (found -> tag == tag)
	break;

  return (found);
}


static int bertag (u_char * apdu)
{
  u_char * q = apdu;
  int tag = * q & 0x1F;

  if (tag > 30)
    {
      tag = 0;
      q ++;
      do
	{
	  tag <<= 7;
	  tag |= * q & 0X7F;
	}
      while (* q ++ & 0X80);
    }
  return (tag);
}


/*
 * An euristic Z39.50 event check routine that simply
 * looks for the first tag in the APDU
 */
z3950apdu * parseable (u_char * apdu, int len)
{
  if (! len)
    return (0);

  return (lookup (bertag (apdu)));
}



struct timeval current_apdu = {0};
struct timeval first_apdu = {0};
struct timeval last_apdu = {0};

/*
 * The time difference in milliseconds
 */
time_t delta_time_in_milliseconds (const struct timeval * now,
				   const struct timeval * before)
{
  /*
   * compute delta in second, 1/10's and 1/1000's second units
   */
  time_t delta_seconds = now -> tv_sec - before -> tv_sec;
  time_t delta_milliseconds = (now -> tv_usec - before -> tv_usec) / 1000;

  if (delta_milliseconds < 0)
    { /* manually carry a one from the seconds field */
      delta_milliseconds += 1000; 		/* 1e3 */
      -- delta_seconds;
    }
  return ((delta_seconds * 1000) + delta_milliseconds);
}


/*
 * return a well formatted timestamp
 */
char * timestamp (const struct timeval * t, int fmt)
{
  static char buf [16];

  time_t now = time ((time_t *) 0);
  struct tm * tm = localtime (& now);

  gettimeofday (& current_apdu, NULL);

  switch (fmt)
    {
    default:
    case DELTA_FMT:
      /*
       * calculate the difference in milliseconds since the previous apdus was displayed
       */
      sprintf (buf, "%10ld ms", delta_time_in_milliseconds (& current_apdu, & last_apdu));
      break;

    case ABS_FMT:
      sprintf (buf, "%02d:%02d:%02d.%06d",
	       tm -> tm_hour, tm -> tm_min, tm -> tm_sec, (int) t -> tv_usec);
      break;

    case RELATIVE_FMT:
      /*
       * calculate the difference in milliseconds since the previous apdus was displayed
       */
      sprintf (buf, "%10ld ms", delta_time_in_milliseconds (& current_apdu, & first_apdu));
      break;
    }

  return (buf);
}
