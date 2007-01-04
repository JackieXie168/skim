## Copyright (C) 1995-2004, Index Data
## All rights reserved.
## $Id: Makefile.am,v 1.27 2006/08/11 12:57:30 adam Exp $


bin_PROGRAMS=yaz-client 
EXTRA_PROGRAMS=bertorture

EXTRA_DIST = default.bib

COMMON=admin.c admin.h tabcomplete.c tabcomplete.h
yaz_client_SOURCES=client.c $(COMMON)

AM_CFLAGS=$(THREAD_CFLAGS)

AM_CPPFLAGS=-I$(top_srcdir)/include $(XML2_CFLAGS) $(SSL_CFLAGS)

yaz_client_LDADD = ../src/libyaz.la $(READLINE_LIBS) 
bertorture_LDADD = ../src/libyaz.la 

bertorture_SOURCES=bertorture.c


