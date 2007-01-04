/*
 * -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
 * ziffy.c - a promiscuous Z39.50 APDU sniffer for Ethernet
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
#include <string.h>
#include <signal.h>

#include <time.h>
#if HAVE_SYS_TIME_H
#include <sys/time.h>
#endif
#include <sys/utsname.h>

#if 1
#include "getopt.h"
#endif

#include "pcap.h"               /* Packet Capture Library */

#include "apdu.h"


/*
 * external
 */
z3950apdu * pduhook (const struct pcap_pkthdr * h, const u_char * p);


#if defined(HAVE_XASN1)
void please_finsiel_help_me (z3950apdu * hook);
#endif /* HAVE_XASN1 */

#if defined(HAVE_YAZ)
void please_yaz_help_me (z3950apdu * hook);
#endif /* HAVE_YAZ */

#if defined(HAVE_SNACC)
void please_snacc_help_me (z3950apdu * hook);
#endif /* HAVE_SNACC */


/*
 * global variables
 */
time_t now;                           /* current time */
time_t start_time;                    /* time the program was started */
time_t firstapdu_time;                /* time the first APDU was received */
time_t laststapdu_time;               /* time the last APDU was received */

unsigned long int z3950_apduno = 0;   /* # of z3950 apdus so far received */
u_char * z3950   = NULL;              /* pointer to the last apdu received */
int z3950_size   = 0;                 /* and its size */

/*
 * I currently tested the program at home in a null networked environment
 * and on ethernet 10M lan. the following variable keeps the data-link
 * encapsulation type. more info in net/bpf.h
 */
int dlt = -1;

int aflag     = 0; /* attempt to convert numeric network addresses to FQDN */

int ethflag   = 0;
int ipflag    = 0;
int tcpflag   = 0;
int z3950flag = 0;


/*
 * Length of saved portion of packet
 */
#define DEFAULT_SNAPLEN 65536	/* This should be enough... */
static int snaplen = DEFAULT_SNAPLEN;

#define DEFAULT_MAXAPDUS -1	/* that means indefinite */
static int maxapdus = DEFAULT_MAXAPDUS;

/*
 * A handler for pcap, it needs to be global because there is no other way to
 * pass it to the signal handler, the same can be said about the file descriptor
 * for SOCK_PACKET.
 */
pcap_t * ph = NULL;


/*
 * package info
 */
static char __copyright__   [] = "Copyright (c) 1998-2001";
static char __author__      [] = "R. Carbone <rocco@ntop.org>";
static char __version__     [] = "Version 0.0.3";
static char __released__    [] = "June 2001";


#if (0)
struct option options [] =
{
  /* Default args */
  { "help",		no_argument,            NULL,   'h' },
  { "version",	 	no_argument,            NULL,   'v' },

  /* Session Management stuff */
  { "restart-session",	required_argument,      NULL,   'S' },
  { "discard-session",	required_argument,      NULL,   'D' },

  { NULL, 0, NULL, 0 }
};
#endif

char ebuf [PCAP_ERRBUF_SIZE] = {0};
struct pcap_stat pcapstats = {0};

/*
 * signal handler
 */
void on_signal (int signo)
{
  /*
   * time for statistics
   */
  if (pcap_stats (ph, & pcapstats) != 0)
    {
      printf ("Cannot get the statistics due to %s\n", ebuf),
      exit (-1);
    }
  else
    {
      printf ("\n\n");

      printf ("%u packets received by decoder\n", pcapstats . ps_recv);
      printf ("%u packets dropped by kernel\n", pcapstats . ps_drop);
    }

  fflush (stdout);

  /*
   * bye bye !
   */
  pcap_close (ph);

  exit (0);
}



/*
 * You are welcome!
 */
void welcome (char * progname)
{
  time_t now = ((time_t) time ((time_t *) 0));
  char * nowstring = ctime (& now);
  struct utsname machine;

  nowstring [24] = '\0';
  uname (& machine);

  printf ("This is %s %s of %s\n", progname, __version__, __released__);
  printf ("%s %s\n", __copyright__, __author__);
  printf ("Started at %s on %s\n\n", nowstring, machine . nodename);
  printf ("\n");
  fflush (stdout);
  fflush (stderr);
}


/*
 * Wrong. Please try again accordingly to ....
 */
void usage (char * progname)
{
  welcome (progname);

  printf ("Usage: %s [--help] [--version]\n\n", progname);
  printf ("Options:\n");
  printf ("        h, --help             display this help and exit\n");
  printf ("        v, --version          output version information and exit\n");

  printf ("         , --                 print filter code\n");
  printf ("         , --                 print ethernet header\n");
  printf ("         , --                 try to resolve ip addresses\n");
  printf ("         , --                 remove domains from printed host names\n");
  printf ("         , --                 don't translate _foreign_ IP address\n");
  printf ("         , --                 print packet arrival time\n");

  printf ("        s, --snaplen          \n");
  printf ("        N, --non-promiscuous  capture APDUs addressed to the host machine\n");
  printf ("        C, --maxcount         capture maxcount APDUs and then terminate\n");

  printf ("        D, --dropped-packets  display number of packets dropped during capture\n");
  fflush (stdout);
}


/*
 * This is really the `main' function of the sniffer.
 *
 * Parse the incoming APDU, and when possible show all pertinent data.
 *
 * 'h' is the pointer to the packet header (independent from interfaces)
 * 'p' is the pointer to the packet data
 * 'caplen' is the number of bytes actually captured
 * 'length' is the length of the packet off the wire
 */
void parse_pdu (u_char * user_data,
		const struct pcap_pkthdr * h,
		const u_char * p)
{
  z3950apdu * hook;
  int done = 0;

  if (! (hook = pduhook (h, p)))
    return;

  /*
   * update the descriptor of the apdu
   */
  hook -> t = & h -> ts;
  hook -> calling = srchost ();
  hook -> srcport = srcport ();
  hook -> called  = dsthost ();
  hook -> dstport = dstport ();

#if defined(HAVE_XASN1)
  if (! done)
    please_finsiel_help_me (hook);
  done = 1;
#endif /* HAVE_XASN1 */

#if defined(HAVE_YAZ)
  if (! done)
    please_yaz_help_me (hook);
  done = 1;
#endif /* HAVE_YAZ */

#if defined(HAVE_SNACC)
  if (! done)
    please_snacc_help_me (hook);
  done = 1;
#endif /* HAVE_SNACC */
}


/*
 * Oh no! yet another main here
 */
int main (int argc, char * argv [])
{
  int option;
  char * optstr = "hvac:ef:i:lnprs:twxz";

  char * progname;

  char * interface = NULL;
  char * filename = NULL;

  char * filter = NULL;
  struct bpf_program program = {0};
  bpf_u_int32 network = {0};
  bpf_u_int32 netmask = {0};


  /*
   * notice the program name
   */
  progname = strrchr (argv [0], '/');
  if (! progname || ! * progname)
    progname = * argv;
  else
    progname ++;

#if (0)
  /*
   * initialize getopt
   */
  optarg = NULL;
  optind = 0;
  optopt = 0;
  opterr = 0;  /* this prevents getopt() to send error messages to stderr */
#endif

  /*
   * Parse command-line options
   */
  while ((option = getopt (argc, argv, optstr)) != EOF)
    {
      switch (option)
	{
	default:
	  usage (progname);
	  return (-1);

	case '?':
	  printf ("%s: unrecognized option %c\n", progname, optopt);
	  usage (progname);
	  return (-1);

	case ':':
	  printf ("%s: missing parameter %c\n", progname, optopt);
	  usage (progname);
	  return (-1);

	case 'h':
	  usage (progname);
	  return (0);

	case 'a':
	  aflag = 1;
	  break;

	case 'c':
	  maxapdus = atoi (optarg);
	  if (maxapdus <= 0)
	    printf ("malformed max apdus counter %s", optarg), maxapdus = DEFAULT_MAXAPDUS;
	  break;

	case 'e':
	  ethflag = 1;
	  break;

	case 'f':
	  filename = strdup (optarg);
	  break;

	case 'i':
	  interface = strdup (optarg);
	  break;

	case 'l':
	  break;

	case 'n':
	  break;

	case 'p':
	  break;

	case 'r':
	  break;

	case 's':
	  snaplen = atoi (optarg);
	  if (snaplen <= 0)
	    printf ("malformed snaplen %s", optarg), snaplen = DEFAULT_SNAPLEN;
	  break;

	case 't':
	  tcpflag = 1;
	  break;

	case 'w':
	  break;

	case 'x':
	  ipflag = 1;
	  break;

	case 'z':
	  z3950flag = 1;
	  break;
	}
    }

  /*
   * You are welcome
   */
  welcome (progname);


  /*
   * build a string from all remaining arguments
   */
  filter = NULL;
  {
    int roomsize = 0;
    while (optind < argc)
      {
        roomsize += (strlen (argv [optind]) + 1 + 1);
        if (filter)
          {
            strcat (filter, " ");
            filter = realloc (filter, roomsize);
            strcat (filter, argv [optind ++]);
          }
        else
          {
            filter = malloc (roomsize);
            strcpy (filter, argv [optind ++]);
          }
      }
  }


  /*
   * find a suitable interface, if i don't have one
   */
  if (! filename && ! interface && ! (interface = pcap_lookupdev (ebuf)))
    {
      printf ("No suitable interfaces found, please specify one with -i\n");
      exit (-1);
    }


  if ((getuid () && geteuid ()) || setuid (0))
    {
      printf ("Sorry, you must be root in order to run this program.\n");
      exit (-1);
    }

  /*
   * time to initialize the libpcap
   */
  ph = filename ? pcap_open_offline (filename, ebuf) :
    pcap_open_live (interface, snaplen, 1, 1000, ebuf);

  if (! ph)
    printf ("Cannot initialize the libpcap package due to %s\n", ebuf),
      exit (-1);

  /*
   * get the interface network number and its mask
   * (unless we are reading data from a file)
   */
  if (! filename && pcap_lookupnet (interface, & network, & netmask, ebuf) < 0)
    printf ("Cannot lookup for the network due to %s\n", ebuf),
      exit (-1);

  /*
   * determine the type of the underlying network and the data-link encapsulation method
   * (unless we are reading data from a file)
   */
  dlt = pcap_datalink (ph);

  if (! filename && dlt != DLT_NULL && dlt != DLT_IEEE802 && dlt != DLT_EN10MB)
    printf ("Unsupported data-link encapsulation %d\n", dlt),
      exit (-1);

  /*
   * compile an optional filter into a BPF program
   */
  if (filter && pcap_compile (ph, & program, filter, 1, netmask) == -1)
    printf ("Cannot compile the filter %s\n", filter),
      exit (-1);

  /*
   * apply the filter to the handler
   */
  if (filter && pcap_setfilter (ph, & program) == -1)
    printf ("Cannot set the filter %s\n", filter),
      exit (-1);

  /*
   * announce to the world
   */
  printf ("%s %s: listening on %s\n", progname, __version__, interface);
  fflush (stdout);

  /*
   * Setup signal handlers
   */
  signal (SIGTERM, on_signal);
  signal (SIGINT, on_signal);


  /*
   * Go for fun! and handle any packet received
   */
  if (pcap_loop (ph, -1, parse_pdu, NULL) == -1)
    printf ("%s: error while capturing packets due to %s\n", progname, pcap_geterr (ph)),
      exit (-1);

  pcap_close (ph);


  return (0);
}
