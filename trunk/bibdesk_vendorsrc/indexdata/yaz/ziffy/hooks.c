/*
 * -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
 * hooks.c - a TCP/IP protocol filter for ziffy
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


#if defined(linux)
# if !defined(_BSD_SOURCE)
#  define _BSD_SOURCE
# endif
#endif

/*
 * Operating System include files
 */
#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>

#include <netdb.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#include <net/if.h>

#if HAVE_NETINET_IF_ETHER_H
#include <netinet/if_ether.h>
#endif

#if HAVE_NETINET_IN_SYSTM_H
#include <netinet/in_systm.h>
#endif

#include <netinet/ip.h>
#include <netinet/tcp.h>

#include "pcap.h"                   /* Packet Capture Library */

#include "apdu.h"

void fmemdmp (FILE * fd, char * ptr, int size, char * text);


/* external */
extern int dlt;


/*
 * to allow a pretty-print of lower-layers address I save
 * relevant pointers to all the protocol data units in global variables,
 * rather than pass them across function calls.
 * So, for example, if someone is interested in the paired source and
 * destination IP addressed, they can be easily accessed by global 'ip' pointer.
 */


/*
 * hooks to the known protocols in the ethernet packets
 */
static struct ether_header * e = NULL;
static struct ip * ip          = NULL;
static struct tcphdr * tcp     = NULL;
extern u_char * z3950;

/*
 * sizes of the known protocols in the ethernet packets
 */
static int eth_size   = 0;
static int eth_hlen   = 0;
static int ip_size    = 0;
static int ip_hlen    = 0;
static int tcp_size   = 0;
static int tcp_hlen   = 0;
extern int z3950_size;


char * srchost (void)
{
  static char buf [256];  /* should be enough for humans !!! */

  struct hostent * host = NULL;

  if (aflag)
    host = gethostbyaddr ((char *) & ip -> ip_src, sizeof (ip -> ip_src), AF_INET);

  sprintf (buf, "%s", host ? host -> h_name : inet_ntoa (ip -> ip_src));
  return (buf);
}


int srcport (void)
{
  return ((int) ntohs (tcp -> th_sport));
}


char * dsthost (void)
{
  static char buf [256];  /* should be enough for humans !!! */

  struct hostent * host = NULL;

  if (aflag)
    host = gethostbyaddr ((char *) & ip -> ip_dst, sizeof (ip -> ip_dst), AF_INET);

  sprintf (buf, "%s", host ? host -> h_name : inet_ntoa (ip -> ip_dst));
  return (buf);
}


int dstport (void)
{
  return ((int) ntohs (tcp -> th_dport));
}


/*
 * stolen from the addrtoname.c in tcpdump
 */
static char hex [] = "0123456789abcdef";

static char * etheraddr_string (u_char * e)
{
  static char buf [sizeof ("00:00:00:00:00:00")];

  int i;
  int j;
  char * p;

  strcpy (buf, "00:00:00:00:00:00");

  /*
   * hacked to manage DLT_NULL
   */
  if (! e)
    return (buf);

  p = buf;
  if ((j = * e >> 4) != 0)
    * p ++ = hex [j];
  * p ++ = hex [* e ++ & 0xf];
  for (i = 5; -- i >= 0; )
    {
      * p ++ = ':';
      if ((j = * e >> 4) != 0)
	* p ++ = hex [j];
    * p ++ = hex [* e ++ & 0xf];
    }
  * p = '\0';
  return (buf);
}


/*
 * Parse the incoming Ethernet Packet and set hooks to all pertinent data.
 *
 * 'h' is the pointer to the packet header (independent from interfaces)
 * 'p' is the pointer to the packet data
 *
 * Warning: I really want libpcap to give me aligned packets
 */
z3950apdu * pduhook (const struct pcap_pkthdr * h, const u_char * p)
{
  static unsigned long ethno = 0;  /* # of ethernet packets received by the decoder */
  static unsigned long ipno = 0;   /* # of IP packets received by the decoder */
  static unsigned long tcpno = 0;  /* # of TCP packets received by the decoder */

  u_char * q;

  z3950apdu * apdu = NULL;

  /*
   * Ethernet Protocol
   */
  e = (struct ether_header *) p;

  /*
   * Ethernet sizes
   *
   * The header is only 4 bytes long in case of no link-layer encapsulation (DLT_NULL).
   * It contains a network order 32 bit integer that specifies the family, e.g. AF_INET
   */
  eth_size = h -> len;
  eth_hlen = dlt == DLT_NULL ? 4 : sizeof (struct ether_header);

  ++ ethno;

  if (ethflag)
    printf ("ETHER:  ----- Ether Header -----\n"),
      printf ("ETHER:\n"),
      printf ("ETHER:  Packet %ld arrived at %s\n", ethno, timestamp (& h -> ts, ABS_FMT)),
      printf ("ETHER:  Total size  = %d : header = %d : data = %d\n",
	      eth_size, eth_hlen, eth_size - eth_hlen),
      printf ("ETHER:  Source      = %s\n",
	      etheraddr_string (dlt == DLT_NULL ? NULL : (char *) & e -> ether_shost)),
      printf ("ETHER:  Destination = %s\n",
	      etheraddr_string (dlt == DLT_NULL ? NULL : (char *) & e -> ether_dhost)),
      fflush (stdout),
      fmemdmp (stdout, (char *) e, eth_size, "Ethernet Packet");

  /*
   * Process only IP packets (or loopback packets when testing at home sweet home)
   */
  if (dlt == DLT_NULL || ntohs (e -> ether_type) == ETHERTYPE_IP)
    {
      /*
       * IP Protocol
       */
      ip = (struct ip *) (p + eth_hlen);

      /*
       * IP sizes
       *
       * ip->ip_hl*4        = size of the IP (Header Only)
       * ntohs (ip->ip_len) = size of the IP (Full Packet)
       *            ip_size = eth_size - eth_hlen (better IMO)
       */
      ip_size = eth_size - eth_hlen;
      ip_hlen = ip -> ip_hl * 4;

      ++ ipno;

      if (ipflag)
	printf ("IP:     ----- IP Header -----\n"),
	  printf ("IP:\n"),
	  printf ("IP:     Packet %ld arrived at %s\n", ipno, timestamp (& h -> ts, ABS_FMT)),
	  printf ("IP:     Total size  = %d : header = %d : data = %d\n",
		  ip_size, ip_hlen, ip_size - ip_hlen),
	  printf ("IP:     Source      = %s\n", inet_ntoa (ip -> ip_src)),
	  printf ("IP:     Destination = %s\n", inet_ntoa (ip -> ip_dst)),
	  fflush (stdout);

#if (0)
      fmemdmp (stdout, (char *) ip, ip_size, "IP Packet");
#endif

      /*
       * i am looking for Z39.50 APDUs over TCP/IP. so...
       */
      if (ip -> ip_p == IPPROTO_TCP)
	{
	  /*
	   * TCP Protocol
	   */
	  q = (u_char *) ip + ip_hlen;
	  tcp = (struct tcphdr *) q;

	  /*
	   * TCP sizes
	   *
	   * tcp->th_off*4 = size of the TCP (Header Only)
	   */
	  tcp_size = ip_size - ip_hlen;
	  tcp_hlen = tcp -> th_off * 4;

	  ++ tcpno;

	  if (tcpflag)
	    printf ("TCP:    ----- TCP Header -----\n"),
	      printf ("TCP:\n"),
	      printf ("TCP:    Packet %ld arrived at %s\n", tcpno, timestamp (& h -> ts, ABS_FMT)),
	      printf ("TCP:    Total size  = %d : header = %d : data = %d\n",
		      tcp_size, tcp_hlen, tcp_size - tcp_hlen),
	      printf ("TCP:    Source      = %d\n", ntohs (tcp -> th_sport)),
	      printf ("TCP:    Destination = %d\n", ntohs (tcp -> th_dport)),
	      fflush (stdout),
	      fmemdmp (stdout, (char *) tcp, tcp_size, "TCP Packet");

	  /*
	   * Application Protocol
	   * (time to play with Z39.50 APDUs here)
	   */
	  z3950 = (u_char *) e + eth_hlen + ip_hlen + tcp_hlen;

	  /*
	   * Higher Protocol Packet Size
	   */
	  z3950_size = tcp_size - tcp_hlen;

	  apdu = parseable (z3950, z3950_size);

	  if (tcpflag && apdu)
	    printf ("TCP:    ----- TCP Header -----\n"),
	      printf ("TCP:\n"),
	      printf ("TCP:    Packet %ld arrived at %s\n", tcpno, timestamp (& h -> ts, ABS_FMT)),
	      printf ("TCP:    Total size  = %d : header = %d : data = %d\n",
		      tcp_size, tcp_hlen, tcp_size - tcp_hlen),
	      printf ("TCP:    Source      = %d\n", ntohs (tcp -> th_sport)),
	      printf ("TCP:    Destination = %d\n", ntohs (tcp -> th_dport)),
	      fflush (stdout),
	      fmemdmp (stdout, (char *) tcp, tcp_size, "TCP Packet");


	  return (apdu);
	}
    }
  return (NULL);
}
