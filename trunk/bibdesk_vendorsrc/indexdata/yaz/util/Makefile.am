## Copyright (C) 1995-2007, Index Data
## All rights reserved.
## $Id: Makefile.am,v 1.30 2007/01/03 08:42:16 adam Exp $

bin_SCRIPTS = yaz-asncomp yaz-config

EXTRA_DIST = yaz-asncomp 

DISTCLEANFILES = yaz-config

AM_CPPFLAGS=-I$(top_srcdir)/include $(XML2_CFLAGS)

bin_PROGRAMS = yaz-marcdump yaz-iconv
noinst_PROGRAMS = cclsh cql2pqf cql2xcql srwtst yaz-benchmark yaz-xmlquery

# MARC dumper utility
yaz_marcdump_SOURCES = marcdump.c
yaz_marcdump_LDADD = ../src/libyaz.la

# YAZ Iconv utility
yaz_iconv_SOURCES = yaziconv.c
yaz_iconv_LDADD = ../src/libyaz.la

srwtst_SOURCES=srwtst.c
srwtst_LDADD = ../src/libyaz.la

cclsh_SOURCES=cclsh.c
cclsh_LDADD = ../src/libyaz.la $(READLINE_LIBS)

cql2pqf_SOURCES = cql2pqf.c
cql2pqf_LDADD = ../src/libyaz.la

cql2xcql_SOURCES = cql2xcql.c
cql2xcql_LDADD = ../src/libyaz.la

yaz_benchmark_SOURCES = benchmark.c
yaz_benchmark_LDADD = ../src/libyaz.la

yaz_xmlquery_SOURCES = yaz-xmlquery.c
yaz_xmlquery_LDADD = ../src/libyaz.la
