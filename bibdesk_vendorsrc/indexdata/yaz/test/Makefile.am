## Copyright (C) 1994-2006, Index Data ApS
## All rights reserved.
## $Id: Makefile.am,v 1.28 2006/12/17 15:34:11 adam Exp $

check_PROGRAMS = tsticonv tstnmem tstmatchstr tstwrbuf tstodr tstccl tstlog \
 tstsoap1 tstsoap2 tstodrstack tstlogthread tstxmlquery tstpquery \
 tst_filepath tst_record_conv tst_retrieval tst_tpath
check_SCRIPTS = tstcql.sh tstmarciso.sh tstmarcxml.sh tstmarccol.sh

TESTS = $(check_PROGRAMS) $(check_SCRIPTS)

EXTRA_DIST = tstodr.asn tstodrcodec.c tstodrcodec.h cqlsample \
 cql2pqf-order.txt \
 $(check_SCRIPTS) \
 marc1.marc marc1.xml marc1.chr marc1.xml.marc \
 marc2.marc marc2.xml marc2.chr marc2.xml.marc \
 marc3.marc marc3.xml marc3.chr marc3.xml.marc \
 marc4.marc marc4.xml marc4.chr marc4.xml.marc \
 marc5.marc marc5.xml marc5.chr marc5.xml.marc \
 marc6.marc marc6.xml marc6.chr marc6.xml.marc \
 marc7.marc marc7.xml marc7.chr marc7.xml.marc \
 marccol1.u8.marc marccol1.u8.1.lst marccol1.u8.2.lst \
 marccol2.u8.marc marccol2.u8.1.lst marccol2.u8.2.lst \
 tst_record_conv.xsl 

YAZCOMP = ../util/yaz-asncomp
YAZCOMPLINE = $(YAZCOMP) -d z.tcl -i yaz -I../include $(YCFLAGS)

AM_CFLAGS=$(THREAD_CFLAGS)

AM_CPPFLAGS=-I$(top_srcdir)/include $(XML2_CFLAGS)

dist-hook:
	mkdir -p $(distdir)/cql
	cp $(srcdir)/cql/*.err $(distdir)/cql
	cp $(srcdir)/cql/*.out $(distdir)/cql

# Rule for generating codecs for our small ASN.1 spec
tstodrcodec.c tstodrcodec.h: tstodr.asn $(YAZCOMP)
	cd $(srcdir); $(YAZCOMP) tstodr.asn

LDADD = ../src/libyaz.la

CONFIG_CLEAN_FILES=*.log

tsticonv_SOURCES = tsticonv.c
tstnmem_SOURCES = tstnmem.c
tstmatchstr_SOURCES = tstmatchstr.c
tstwrbuf_SOURCES = tstwrbuf.c
tstodr_SOURCES = tstodrcodec.c tstodrcodec.h tstodr.c
tstodrstack_SOURCES = tstodrstack.c
tstccl_SOURCES = tstccl.c
tstlog_SOURCES = tstlog.c
tstsoap1_SOURCES = tstsoap1.c
tstsoap2_SOURCES = tstsoap2.c
tstlogthread_SOURCES = tstlogthread.c
tstxmlquery_SOURCES = tstxmlquery.c
tstpquery_SOURCES = tstpquery.c
tst_filepath_SOURCES = tst_filepath.c
tst_record_conv_SOURCES = tst_record_conv.c
tst_retrieval_SOURCES = tst_retrieval.c
tst_tpath_SOURCES = tst_tpath.c
