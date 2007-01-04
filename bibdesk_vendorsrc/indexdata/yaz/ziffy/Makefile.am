## -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
## auto makefile for ziffy - a promiscuous Z39.50 APDU sniffer for Ethernet
## (this file is processed with 'automake' to produce Makefile.in)
##
## Copyright (c) 1998-2001 R. Carbone <rocco@ntop.org>

ziffy_LDADD = ../src/libyaz.la $(PCAP_LIBS)

AM_CPPFLAGS = -I$(top_srcdir)/include $(PCAP_CFLAGS) \
	$(XML2_CFLAGS) $(SSL_CFLAGS) -DHAVE_YAZ=1

bin_PROGRAMS = $(ZIFFY_PROG)
EXTRA_PROGRAMS = ziffy

man_MANS = ziffy.1

EXTRA_DIST = ANNOUNCEMENT-1 AUTHORS COPYING ChangeLog \
              FAQ FILES HACKING NEWS README TODO $(man_MANS)

ziffy_SOURCES = ziffy.c yaz.c fmemdmp.c hooks.c apdu.c apdu.h

