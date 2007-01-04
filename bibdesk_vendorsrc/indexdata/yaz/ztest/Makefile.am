## $Id: Makefile.am,v 1.20 2005/09/09 10:34:09 adam Exp $

bin_PROGRAMS=yaz-ztest

yaz_ztest_SOURCES=ztest.c read-grs.c read-marc.c

EXTRA_DIST=dummy-records dummy-words dummy-grs ztest.pem config1.xml

yaz_ztest_LDADD=../src/libyaz.la

AM_CFLAGS=$(THREAD_CFLAGS)

AM_CPPFLAGS=-I$(top_srcdir)/include $(XML2_CFLAGS)
