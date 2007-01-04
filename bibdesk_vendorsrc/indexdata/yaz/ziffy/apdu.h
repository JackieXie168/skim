/*
 * -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
 * apdu.h - 
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


extern unsigned long z3950_apduno;

extern int aflag;

extern int ethflag;
extern int ipflag;
extern int tcpflag;
extern int z3950flag;


extern struct timeval first_apdu;
extern struct timeval last_apdu;


/*
 * The structure containing information about all the apdus
 */
typedef struct
{
  int tag;                   /* unique apdu tag identifier */
  char * name;               /* user printable name of the apdu */
  int minlen;                /* min length of bytes off wire (all optional fields absent) */
  const struct timeval * t;  /* the time the apdu was captured */
  char * calling;            /* source ip address */
  int   srcport;             /* source port */
  char * called;             /* destination ip address */
  int   dstport;             /* source port */
} z3950apdu;


z3950apdu * parseable (unsigned char * apdu, int len);

char * srchost (void);
int    srcport (void);
char * dsthost (void);
int    dstport (void);


/*
 * time stamp presentation formats
 */
#define DELTA_FMT      1   /* the time since receiving the previous apdu */
#define ABS_FMT        2   /* the current time */
#define RELATIVE_FMT   3   /* the time relative to the first apdu received */


char * timestamp (const struct timeval * t, int fmt);
