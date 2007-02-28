# Copyright (C) 1995-2007, Index Data ApS
# All rights reserved.
# $Id: makefile,v 1.128 2007/01/24 11:50:19 adam Exp $
#
# Programmed by
#  Heikki Levanto & Adam Dickmeiss

# Parameters 

DEBUG=0   # 0 for release, 1 for debug

# TCL
TCL="C:\Tcl\bin\tclsh84.exe"
#TCL="C:\Program Files\Tcl\bin\tclsh83.exe"
HAVE_TCL=1

# iconv charcter conversion utility
HAVE_ICONV=1
ICONV_DIR = c:\iconv-1.9.2.win32

# libxslt
HAVE_LIBXSLT=1
LIBXSLT_DIR=c:\libxslt-1.1.17.win32

# libxml2
HAVE_LIBXML2=1
LIBXML2_DIR=c:\libxml2-2.6.26.win32

# zlib compression (used by libxml2)
ZLIB_DIR = c:\zlib-1.2.3.win32

# get WIN32 binaries libxml2 & iconv & zlib from here:
#  http://www.zlatkovic.com/libxml.en.html

# bison
HAVE_BISON=1
BISON=bison

default: all

all: dirs generate dll client ztest zoomsh utilprog testprog iconv libxml2 libxslt

NSIS="c:\program files\nsis\makensis.exe"
HHC="c:\program files\html help workshop\hhc.exe"

dist: 
	nmake DEBUG=1 clean
	nmake DEBUG=0 clean
	nmake DEBUG=0
	$(NSIS) yaz.nsi

nsis:
	$(NSIS) yaz.nsi

nsishelp:
	$(NSIS)

generate: generated_files

# Directories
# The current directory is supposed to be something like
# ..../yaz/win, everything is relative to that
ROOTDIR=..   # The home of yaz

INCLDIR=$(ROOTDIR)\include  # our includes
LIBDIR=$(ROOTDIR)\lib       # We produce .lib, .exp etc there
BINDIR=$(ROOTDIR)\bin       # We produce exes and dlls there
WINDIR=$(ROOTDIR)\win       # all these Win make things
SRCDIR=$(ROOTDIR)\src       # for the case we move them under src
DOCDIR=$(ROOTDIR)\doc       # where the doc is

# where we store intermediate files
!if $(DEBUG)
OBJDIR=$(WINDIR)\dobj
!else
OBJDIR=$(WINDIR)\obj
!endif

CLIENTDIR=$(ROOTDIR)\CLIENT
ZTESTDIR=$(ROOTDIR)\ZTEST
ZOOMDIR=$(ROOTDIR)\ZOOM
UTILDIR=$(ROOTDIR)\UTIL
TESTDIR=$(ROOTDIR)\TEST

TMPDIR=$(ROOTDIR)\win\tmp
TMP=$(TMPDIR)

# Targets - what to make

!if $(DEBUG)
DLL=$(BINDIR)\yazd.dll
YAZ_IMPLIB=$(LIBDIR)\yazd.lib
!else
DLL=$(BINDIR)\yaz.dll
YAZ_IMPLIB=$(LIBDIR)\yaz.lib
!endif

CLIENT=$(BINDIR)\yaz-client.exe
ZOOMSH=$(BINDIR)\zoomsh.exe
ZTEST=$(BINDIR)\yaz-ztest.exe

ZOOMTST1=$(BINDIR)\zoomtst1.exe
ZOOMTST2=$(BINDIR)\zoomtst2.exe
ZOOMTST3=$(BINDIR)\zoomtst3.exe
ZOOMTST4=$(BINDIR)\zoomtst4.exe
ZOOMTST5=$(BINDIR)\zoomtst5.exe
ZOOMTST6=$(BINDIR)\zoomtst6.exe
ZOOMTST7=$(BINDIR)\zoomtst7.exe
ZOOMTST8=$(BINDIR)\zoomtst8.exe
ZOOMTST9=$(BINDIR)\zoomtst9.exe
ZOOMTST10=$(BINDIR)\zoomtst10.exe

CQL2PQF=$(BINDIR)\cql2pqf.exe
CQL2XCQL=$(BINDIR)\cql2xcql.exe
YAZ_MARCDUMP=$(BINDIR)\yaz-marcdump.exe

TSTLOG=$(BINDIR)\tstlog.exe
TST_TIMING=$(BINDIR)\tst_timing.exe

# shortcut names defined here
dll: dirs generate $(DLL) 
client: dirs generate $(CLIENT)
ztest: dirs generate $(ZTEST)

zoomsh: $(ZOOMSH) $(ZOOMTST1) $(ZOOMTST2) $(ZOOMTST3) \
 $(ZOOMTST4) $(ZOOMTST5) $(ZOOMTST6) $(ZOOMTST7) $(ZOOMTST8) $(ZOOMTST9) \
 $(ZOOMTST10)

utilprog: $(CQL2PQF) $(CQL2XCQL) $(YAZ_MARCDUMP)

testprog: $(TSTLOG) $(TST_TIMING)

htmlhelp: $(DOCDIR)\htmlhelp.chm

# Modules and conditional flags, etc

!if $(HAVE_ICONV)
ICONV_DEF= \
  /D HAVE_ICONV_H=1 \
  /I"$(ICONV_DIR)\include"
ICONV_LIB= \
  "$(ICONV_DIR)\lib\iconv.lib"
iconv: $(BINDIR)\iconv.dll

$(BINDIR)\iconv.dll:
  copy "$(ICONV_DIR)\bin\iconv.dll" $(BINDIR)
!else
ICONV_DEF= \
  /D HAVE_ICONV_H=0
ICONV_LIB=
iconv:

!endif

!if $(HAVE_LIBXML2)
LIBXML2_LIB="$(LIBXML2_DIR)\lib\libxml2.lib"
LIBXML2_DEF=/D YAZ_HAVE_XML2=1 /I"$(LIBXML2_DIR)\include"
libxml2: $(BINDIR)\libxml2.dll $(BINDIR)\zlib1.dll

$(BINDIR)\libxml2.dll:
  copy "$(LIBXML2_DIR)\bin\libxml2.dll" $(BINDIR)

$(BINDIR)\zlib1.dll:
  copy "$(ZLIB_DIR)\bin\zlib1.dll" $(BINDIR)

!else
LIBXML2_LIB=
LIBXML2_DEF=/D YAZ_HAVE_XML2=0
libxml2: 

!endif

!if $(HAVE_LIBXSLT)
LIBXSLT_LIB="$(LIBXSLT_DIR)\lib\libxslt.lib"
LIBXSLT_DEF= \
	/D HAVE_XSLTSAVERESULTTOSTRING=1 \
	/D YAZ_HAVE_XSLT=1 \
	/I"$(LIBXSLT_DIR)\include"
libxslt: $(BINDIR)\libxslt.dll

$(BINDIR)\libxslt.dll:
  copy "$(LIBXSLT_DIR)\bin\libxslt.dll" $(BINDIR)

!else
LIBXSLT_LIB=
LIBXSLT_DEF=/D YAZ_HAVE_XSLT=0
libxslt: 
!endif


### C and CPP compiler  (the same thing)
# Note: $(CPP) has already been defined in the environment
# (if you set things up right!)

COMMON_C_OPTIONS=          \
  /nologo /W3 /EHsc /FD /c   \
  $(ICONV_DEF)             \
  $(LIBXML2_DEF)           \
  $(LIBXSLT_DEF)           \
  /D "_CRT_SECURE_NO_DEPRECATE" \
  /D "_CRT_NONSTDC_NO_DEPRECATE" \
  /D "_WINDOWS"            \
  /D "WIN32"               \
  /FR"$(OBJDIR)\\"         \
  /Fo"$(OBJDIR)\\"         \
  /Fd"$(OBJDIR)\\" 

COMMON_C_INCLUDES= \
  /I"$(ROOTDIR)\include"

DEBUG_C_OPTIONS=  \
  /D "_DEBUG"      \
  /MDd  /Od /Zi /Gm

RELEASE_C_OPTIONS=  \
  /D "NDEBUG"        \
  /MD /O2

# /W3  = warning level
# /GX  = Enable exception handling
# /FD  = Generate file dependencies (what ever they are)
# /c   = compile without linking
# /FR  = Generate browse info (.sbr file that gets combined into .bsc)
# /Fo  = object file name (or at least path)
# /Fd  = debug database name (or path)
# /MD  = Runtime library: Multithread DLL
# /MDd = Runtime library: Multithread DLL (debug)
# /Od  = Disable optimising (debug)
# /O2  = Optimize for speed
# /Gm  = Minimal rebuild (some cpp class stuff)
# /Zi  = Program database for debuggers
# /ZI  = Pgm database with special "edit&continue" stuff - not available in C5


### Linker options
LINK=link.exe

LINK_LIBS= kernel32.lib user32.lib   gdi32.lib   \
           advapi32.lib uuid.lib wsock32.lib  advapi32.lib \
           $(ICONV_LIB) $(LIBXML2_LIB) $(LIBXSLT_LIB)

COMMON_LNK_OPTIONS= /nologo /subsystem:windows /machine:i386 /incremental:no

DEBUG_LNK_OPTIONS= /debug 

RELEASE_LNK_OPTIONS=

DLL_LINK_OPTIONS= /dll  
CLIENT_LINK_OPTIONS = /subsystem:console  

COMMON_TCL_OPTIONS= ..\util\yaz-asncomp -I$(INCLDIR) -i yaz

# Final opt variables
!if $(DEBUG)
COPT=   $(COMMON_C_OPTIONS)   $(DEBUG_C_OPTIONS)     $(COMMON_C_INCLUDES)
MTLOPT= $(COMMON_MTL_OPTIONS) $(DEBUG_MTL_OPTIONS)
RCOPT=  $(COMMON_RC_OPTIONS)  $(DEBUG_RC_OPTIONS)
LNKOPT= $(COMMON_LNK_OPTIONS) $(DEBUG_LNK_OPTIONS)   $(LNK_LIBS)
TCLOPT= $(COMMON_TCL_OPTIONS)

!else
COPT=   $(COMMON_C_OPTIONS)   $(RELEASE_C_OPTIONS)   $(COMMON_C_INCLUDES) 
MTLOPT= $(COMMON_MTL_OPTIONS) $(RELEASE_MTL_OPTIONS)
RCOPT=  $(COMMON_RC_OPTIONS)  $(RELEASE_RC_OPTIONS)
LNKOPT= $(COMMON_LNK_OPTIONS) $(RELEASE_LNK_OPTIONS) $(LNK_LIBS)
TCLOPT= $(COMMON_TCL_OPTIONS)
!endif

LINK_PROGRAM = $(LINK) $(LNKOPT) \
		$(CLIENT_LINK_OPTIONS) $(LINK_LIBS) $(YAZ_IMPLIB)

LINK_DLL = $(LINK) $(LNKOPT) \
		$(LINK_LIBS) $(DLL_LINK_OPTIONS)

# Source and object modules

# Note: Ordinary source files are not specified here at 
# all, make finds them in suitable dirs. The object modules
# need to be specified, though

YAZ_CLIENT_OBJS= \
   $(OBJDIR)\client.obj \
   $(OBJDIR)\tabcomplete.obj \
   $(OBJDIR)\admin.obj \
   $(OBJDIR)\fhistory.obj

ZTEST_OBJS= \
    $(OBJDIR)\read-marc.obj \
    $(OBJDIR)\read-grs.obj \
    $(OBJDIR)\ztest.obj 

YAZ_ZOOMSH_OBJS = \
   $(OBJDIR)\zoomsh.obj

YAZ_ZOOMTST1_OBJS = \
   $(OBJDIR)\zoomtst1.obj
YAZ_ZOOMTST2_OBJS = \
   $(OBJDIR)\zoomtst2.obj
YAZ_ZOOMTST3_OBJS = \
   $(OBJDIR)\zoomtst3.obj
YAZ_ZOOMTST4_OBJS = \
   $(OBJDIR)\zoomtst4.obj
YAZ_ZOOMTST5_OBJS = \
   $(OBJDIR)\zoomtst5.obj
YAZ_ZOOMTST6_OBJS = \
   $(OBJDIR)\zoomtst6.obj
YAZ_ZOOMTST7_OBJS = \
   $(OBJDIR)\zoomtst7.obj
YAZ_ZOOMTST8_OBJS = \
   $(OBJDIR)\zoomtst8.obj
YAZ_ZOOMTST9_OBJS = \
   $(OBJDIR)\zoomtst9.obj
YAZ_ZOOMTST10_OBJS = \
   $(OBJDIR)\zoomtst10.obj

YAZ_CQL2PQF_OBJS = \
   $(OBJDIR)\cql2pqf.obj
YAZ_CQL2XCQL_OBJS = \
   $(OBJDIR)\cql2xcql.obj
YAZ_MARCDUMP_OBJS = \
   $(OBJDIR)\marcdump.obj

TSTLOG_OBJS = \
   $(OBJDIR)\tstlog.obj

TST_TIMING_OBJS = \
   $(OBJDIR)\tst_timing.obj

MISC_OBJS= \
   $(OBJDIR)\version.obj \
   $(OBJDIR)\eventl.obj \
   $(OBJDIR)\requestq.obj \
   $(OBJDIR)\service.obj \
   $(OBJDIR)\seshigh.obj \
   $(OBJDIR)\statserv.obj \
   $(OBJDIR)\tcpdchk.obj \
   $(OBJDIR)\cclerrms.obj \
   $(OBJDIR)\cclfind.obj \
   $(OBJDIR)\cclptree.obj \
   $(OBJDIR)\cclqfile.obj \
   $(OBJDIR)\cclqual.obj \
   $(OBJDIR)\cclstr.obj \
   $(OBJDIR)\ccltoken.obj \
   $(OBJDIR)\comstack.obj \
   $(OBJDIR)\tcpip.obj \
   $(OBJDIR)\waislen.obj \
   $(OBJDIR)\ber_any.obj \
   $(OBJDIR)\ber_bit.obj \
   $(OBJDIR)\ber_bool.obj \
   $(OBJDIR)\ber_int.obj \
   $(OBJDIR)\ber_len.obj \
   $(OBJDIR)\ber_null.obj \
   $(OBJDIR)\ber_oct.obj \
   $(OBJDIR)\ber_oid.obj \
   $(OBJDIR)\ber_tag.obj \
   $(OBJDIR)\dumpber.obj \
   $(OBJDIR)\odr.obj \
   $(OBJDIR)\odr_any.obj \
   $(OBJDIR)\odr_bit.obj \
   $(OBJDIR)\odr_bool.obj \
   $(OBJDIR)\odr_choice.obj \
   $(OBJDIR)\odr_cons.obj \
   $(OBJDIR)\odr_enum.obj \
   $(OBJDIR)\odr_int.obj \
   $(OBJDIR)\odr_mem.obj \
   $(OBJDIR)\odr_null.obj \
   $(OBJDIR)\odr_oct.obj \
   $(OBJDIR)\odr_oid.obj \
   $(OBJDIR)\odr_seq.obj \
   $(OBJDIR)\odr_tag.obj \
   $(OBJDIR)\odr_use.obj \
   $(OBJDIR)\odr_util.obj \
   $(OBJDIR)\atoin.obj \
   $(OBJDIR)\log.obj \
   $(OBJDIR)\marcdisp.obj \
   $(OBJDIR)\marc_read_xml.obj \
   $(OBJDIR)\marc_read_iso2709.obj \
   $(OBJDIR)\marc_read_line.obj \
   $(OBJDIR)\nmem.obj \
   $(OBJDIR)\nmemsdup.obj \
   $(OBJDIR)\oid.obj \
   $(OBJDIR)\options.obj \
   $(OBJDIR)\readconf.obj \
   $(OBJDIR)\tpath.obj \
   $(OBJDIR)\wrbuf.obj \
   $(OBJDIR)\xmalloc.obj \
   $(OBJDIR)\matchstr.obj \
   $(OBJDIR)\siconv.obj \
   $(OBJDIR)\marc8.obj \
   $(OBJDIR)\marc8r.obj \
   $(OBJDIR)\record_conv.obj \
   $(OBJDIR)\retrieval.obj \
   $(OBJDIR)\libxml2_error.obj \
   $(OBJDIR)\test.obj \
   $(OBJDIR)\diagbib1.obj \
   $(OBJDIR)\diagsru_update.obj \
   $(OBJDIR)\diagsrw.obj \
   $(OBJDIR)\diag-entry.obj \
   $(OBJDIR)\zget.obj \
   $(OBJDIR)\logrpn.obj \
   $(OBJDIR)\querytowrbuf.obj \
   $(OBJDIR)\pquery.obj \
   $(OBJDIR)\yaz-ccl.obj \
   $(OBJDIR)\otherinfo.obj \
   $(OBJDIR)\sortspec.obj \
   $(OBJDIR)\z3950oid.obj \
   $(OBJDIR)\charneg.obj \
   $(OBJDIR)\grs1disp.obj \
   $(OBJDIR)\opacdisp.obj \
   $(OBJDIR)\zgdu.obj \
   $(OBJDIR)\soap.obj \
   $(OBJDIR)\srw.obj \
   $(OBJDIR)\srwutil.obj \
   $(OBJDIR)\zoom-c.obj \
   $(OBJDIR)\zoom-opt.obj \
   $(OBJDIR)\zoom-socket.obj \
   $(OBJDIR)\initopt.obj \
   $(OBJDIR)\xmlquery.obj \
   $(OBJDIR)\mime.obj \
   $(OBJDIR)\cql.obj \
   $(OBJDIR)\cqlstdio.obj \
   $(OBJDIR)\cqlstring.obj \
   $(OBJDIR)\cqltransform.obj \
   $(OBJDIR)\cqlutil.obj \
   $(OBJDIR)\cqlstrer.obj \
   $(OBJDIR)\xcqlutil.obj \
   $(OBJDIR)\elementset.obj \
   $(OBJDIR)\timing.obj \
   $(OBJDIR)\http.obj

Z3950_OBJS= \
   $(OBJDIR)\z-date.obj\
   $(OBJDIR)\z-univ.obj\
   $(OBJDIR)\zes-update.obj\
   $(OBJDIR)\zes-admin.obj \
   $(OBJDIR)\z-accdes1.obj \
   $(OBJDIR)\z-accform1.obj \
   $(OBJDIR)\z-acckrb1.obj \
   $(OBJDIR)\z-core.obj \
   $(OBJDIR)\z-diag1.obj \
   $(OBJDIR)\z-espec1.obj \
   $(OBJDIR)\z-estask.obj \
   $(OBJDIR)\z-exp.obj \
   $(OBJDIR)\z-grs.obj \
   $(OBJDIR)\z-opac.obj \
   $(OBJDIR)\z-uifr1.obj \
   $(OBJDIR)\z-rrf1.obj \
   $(OBJDIR)\z-rrf2.obj \
   $(OBJDIR)\z-sum.obj \
   $(OBJDIR)\z-sutrs.obj \
   $(OBJDIR)\zes-expi.obj \
   $(OBJDIR)\zes-exps.obj \
   $(OBJDIR)\zes-order.obj \
   $(OBJDIR)\zes-pquery.obj \
   $(OBJDIR)\zes-psched.obj \
   $(OBJDIR)\zes-pset.obj \
   $(OBJDIR)\zes-update0.obj \
   $(OBJDIR)\prt-ext.obj \
   $(OBJDIR)\z-charneg.obj \
   $(OBJDIR)\z-mterm2.obj \
   $(OBJDIR)\z-oclcui.obj

ILL_OBJS= \
   $(OBJDIR)\ill-get.obj\
   $(OBJDIR)\ill-core.obj\
   $(OBJDIR)\item-req.obj

DLL_OBJS =\
   $(MISC_OBJS) \
   $(Z3950_OBJS) \
   $(ILL_OBJS) \

# Generated C and H files

Z3950_C_DIR=$(SRCDIR)   
ILL_C_DIR=$(SRCDIR)
#!!! Should be moved to OBJ, but that requires too much trickery

# Files generated from datetime.asn
DATETIME_H_FILES = $(INCLDIR)\yaz\z-date.h
DATETIME_C_FILES = $(Z3950_C_DIR)\z-date.c

# Files generated from univres.asn
UNIVRES_H_FILES = $(INCLDIR)\yaz\z-univ.h
UNIVRES_C_FILES = $(Z3950_C_DIR)\z-univ.c

# Files generated from esupdate.asn
ESUPDATE_H_FILES = $(INCLDIR)\yaz\zes-update.h
ESUPDATE_C_FILES = $(Z3950_C_DIR)\zes-update.c

# Files generated from esadmin.asn
ESADMIN_H_FILES = $(INCLDIR)\yaz\zes-admin.h
ESADMIN_C_FILES = $(Z3950_C_DIR)\zes-admin.c

# Files generated from esadmin.asn
CHARNEG_H_FILES = $(INCLDIR)\yaz\z-charneg.h
CHARNEG_C_FILES = $(Z3950_C_DIR)\z-charneg.c

# Files generated from mterm2.asn
MTERM2_H_FILES = $(INCLDIR)\yaz\z-mterm2.h
MTERM2_C_FILES = $(Z3950_C_DIR)\z-mterm2.c

# Files generated from mterm2.asn
OCLCUI_H_FILES = $(INCLDIR)\yaz\z-oclcui.h
OCLCUI_C_FILES = $(Z3950_C_DIR)\z-oclcui.c

# Files created from z3950v3.asn
Z3950V3_H_FILES= \
   $(INCLDIR)\yaz\z-accdes1.h \
   $(INCLDIR)\yaz\z-core.h

Z3950V3_C_FILES= \
   $(Z3950_C_DIR)\z-accdes1.c \
   $(Z3950_C_DIR)\z-accform1.c \
   $(Z3950_C_DIR)\z-acckrb1.c \
   $(Z3950_C_DIR)\z-core.c \
   $(Z3950_C_DIR)\z-diag1.c \
   $(Z3950_C_DIR)\z-espec1.c \
   $(Z3950_C_DIR)\z-estask.c \
   $(Z3950_C_DIR)\z-exp.c \
   $(Z3950_C_DIR)\z-grs.c \
   $(Z3950_C_DIR)\z-opac.c \
   $(Z3950_C_DIR)\z-uifr1.c \
   $(Z3950_C_DIR)\z-rrf1.c \
   $(Z3950_C_DIR)\z-rrf2.c \
   $(Z3950_C_DIR)\z-sum.c \
   $(Z3950_C_DIR)\z-sutrs.c \
   $(Z3950_C_DIR)\zes-expi.c \
   $(Z3950_C_DIR)\zes-exps.c \
   $(Z3950_C_DIR)\zes-order.c \
   $(Z3950_C_DIR)\zes-pquery.c \
   $(Z3950_C_DIR)\zes-psched.c \
   $(Z3950_C_DIR)\zes-pset.c \
   $(Z3950_C_DIR)\zes-update0.c

# Files generated from ill9702.asn
ILL_CORE_H_FILES= \
   $(INCLDIR)\yaz\ill-core.h

ILL_CORE_C_FILES= \
   $(ILL_C_DIR)\ill-core.c

# Files generated from itemreq.asn
ITEM_REQ_H_FILES= \
   $(INCLDIR)\yaz\item-req.h

ITEM_REQ_C_FILES= \
   $(ILL_C_DIR)\item-req.c

# Combined..
DATETIME_FILES = $(DATETIME_H_FILES) $(DATETIME_C_FILES)
UNIVRES_FILES = $(UNIVRES_H_FILES) $(UNIVRES_C_FILES)
ESUPDATE_FILES = $(ESUPDATE_H_FILES) $(ESUPDATE_C_FILES)
ESADMIN_FILES = $(ESADMIN_H_FILES) $(ESADMIN_C_FILES)
Z3950V3_FILES= $(Z3950V3_C_FILES) $(Z3950V3_H_FILES)
ILL_CORE_FILES= $(ILL_CORE_C_FILES) $(ILL_CORE_H_FILES)
ITEM_REQ_FILES= $(ITEM_REQ_C_FILES) $(ITEM_REQ_H_FILES)
CHARNEG_FILES = $(CHARNEG_C_FILES) $(CHARNEG_H_FILES)
MTERM2_FILES = $(MTERM2_C_FILES) $(MTERM2_H_FILES)
OCLCUI_FILES = $(OCLCUI_C_FILES) $(OCLCUI_H_FILES)

GENERATED_C_FILES= \
   $(Z3950V3_C_FILES)  \
   $(ESUPDATE_C_FILES) \
   $(UNIVRES_C_FILES)  \
   $(DATETIME_C_FILES) \
   $(ESADMIN_C_FILES) \
   $(CHARNEG_C_FILES) \
   $(MTERM2_C_FILES) \
   $(OCLCUI_C_FILES) \
   $(ILL_CORE_C_FILES) \
   $(ITEM_REQ_C_FILES)

GENERATED_H_FILES= \
   $(Z3950V3_H_FILES)  \
   $(ESUPDATE_H_FILES) \
   $(UNIVRES_H_FILES)  \
   $(DATETIME_H_FILES) \
   $(ESADMIN_H_FILES) \
   $(CHARNEG_H_FILES) \
   $(MTERM2_H_FILES) \
   $(OCLCUI_H_FILES) \
   $(ILL_CORE_H_FILES) \
   $(ITEM_REQ_H_FILES)

generated_files: \
	$(GENERATED_H_FILES) \
	$(GENERATED_C_FILES) \
	$(SRCDIR)\diagsrw.c \
	$(SRCDIR)\diagbib1.c \
	$(SRCDIR)\diagsru_update.c 

# Compiling 

# Note: This defines where to look for the necessary
# source files. Funny way of doing it, but it works.

# yaz client
{$(CLIENTDIR)}.c{$(OBJDIR)}.obj:
	$(CPP) $(COPT) $< /D"_CONSOLE"

# Ztest
{$(ZTESTDIR)}.c{$(OBJDIR)}.obj:
	$(CPP) $(COPT) $< /D"_CONSOLE"

# Server
{$(SERVERDIR)}.c{$(OBJDIR)}.obj:
	$(CPP) $(COPT) $< 

# Various YAZ source directories
{$(SRCDIR)}.c{$(OBJDIR)}.obj:
	$(CPP) $(COPT) $< 

{$(ZOOMDIR)}.c{$(OBJDIR)}.obj:
	$(CPP) $(COPT) $< 

{$(UTILDIR)}.c{$(OBJDIR)}.obj:
	$(CPP) $(COPT) $< 

{$(TESTDIR)}.c{$(OBJDIR)}.obj:
	$(CPP) $(COPT) $< 

# ASN-generated files

!if $(HAVE_TCL)

$(Z3950V3_FILES): $(SRCDIR)\z3950v3.asn
	@cd $(SRCDIR)
	$(TCL) $(TCLOPT) -d z.tcl z3950v3.asn
	@cd $(WINDIR)

$(DATETIME_FILES): $(SRCDIR)\datetime.asn
	@cd $(SRCDIR)
	$(TCL) $(TCLOPT) -d z.tcl datetime.asn
	@cd $(WINDIR)

$(UNIVRES_FILES): $(SRCDIR)\univres.asn
	@cd $(SRCDIR)
	$(TCL) $(TCLOPT) -d z.tcl univres.asn
	@cd $(WINDIR)

$(ESUPDATE_FILES): $(SRCDIR)\esupdate.asn
	@cd $(SRCDIR)
	$(TCL) $(TCLOPT) -d z.tcl esupdate.asn
	@cd $(WINDIR)

$(ESADMIN_FILES): $(SRCDIR)\esadmin.asn
	@cd $(SRCDIR)
	$(TCL) $(TCLOPT) -d z.tcl esadmin.asn
	@cd $(WINDIR)

$(CHARNEG_FILES): $(SRCDIR)\charneg-3.asn
	@cd $(SRCDIR)
	$(TCL) $(TCLOPT) -d z.tcl charneg-3.asn
	@cd $(WINDIR)

$(MTERM2_FILES): $(SRCDIR)\mterm2.asn
	@cd $(SRCDIR)
	$(TCL) $(TCLOPT) -d z.tcl mterm2.asn
	@cd $(WINDIR)

$(OCLCUI_FILES): $(SRCDIR)\oclcui.asn
	@cd $(SRCDIR)
	$(TCL) $(TCLOPT) -d z.tcl oclcui.asn
	@cd $(WINDIR)

$(ILL_CORE_FILES): $(SRCDIR)\ill9702.asn
	@cd $(SRCDIR)
	$(TCL) $(TCLOPT) -d ill.tcl ill9702.asn
	@cd $(WINDIR)

$(ITEM_REQ_FILES): $(SRCDIR)\item-req.asn
	@cd $(SRCDIR)
	$(TCL) $(TCLOPT) -d ill.tcl item-req.asn
	@cd $(WINDIR)

$(SRCDIR)\marc8.c: $(SRCDIR)\codetables.xml $(SRCDIR)\charconv.tcl
	@cd $(SRCDIR)
	$(TCL) charconv.tcl -p marc8 codetables.xml -o marc8.c

$(SRCDIR)\marc8r.c: $(SRCDIR)\codetables.xml $(SRCDIR)\charconv.tcl
	@cd $(SRCDIR)
	$(TCL) charconv.tcl -r -p marc8r codetables.xml -o marc8r.c

$(SRCDIR)\diagbib1.c: $(SRCDIR)\bib1.csv
	@cd $(SRCDIR)
	$(TCL) csvtobib1.tcl $(SRCDIR)

$(SRCDIR)\diagsrw.c: $(SRCDIR)\srw.csv
	@cd $(SRCDIR)
	$(TCL) csvtosrw.tcl $(SRCDIR)

$(SRCDIR)\diagsru_update.c: $(SRCDIR)\sru_update.csv
	@cd $(SRCDIR)
	$(TCL) csvtosru_update.tcl $(SRCDIR)

!endif

!if $(HAVE_BISON)
$(SRCDIR)\cql.c: $(SRCDIR)\cql.y
	@cd $(SRCDIR)
	$(BISON) -y -p cql_ -o cql.c cql.y

!endif

# Resources
# The RC compiler (resource files)
RSC=rc.exe
COMMON_RC_OPTIONS= /l 0x406 /i"$(ROOTDIR)" 
DEBUG_RC_OPTIONS=/d "_DEBUG"
RELEASE_RC_OPTIONS=/d "NDEBUG"

YAZ_RES=$(OBJDIR)\yaz.res
YAZ_RC=$(WINDIR)\yaz.rc

!if $(DEBUG)
RSOPT=/d_DEBUG
!else
RSOPT=/d_NDEBUG
!endif

$(YAZ_RES): $(YAZ_RC)
	$(RSC) $(RSOPT) /fo"$(YAZ_RES)" $(YAZ_RC) 

# Linking

$(DLL) $(YAZ_IMPLIB): "$(BINDIR)" $(DLL_OBJS) $(YAZ_RES)
	$(LINK_DLL) \
		$(DLL_OBJS) \
		$(YAZ_RES) \
		/out:$(DLL) \
		/implib:"$(YAZ_IMPLIB)" 

$(CLIENT) : "$(BINDIR)" $(YAZ_CLIENT_OBJS) $(DLL)
	$(LINK_PROGRAM) $(YAZ_CLIENT_OBJS) /out:$(CLIENT)

$(ZOOMSH) : "$(BINDIR)" $(YAZ_ZOOMSH_OBJS) $(DLL)
	$(LINK_PROGRAM) $(YAZ_ZOOMSH_OBJS) /out:$(ZOOMSH)

$(ZOOMTST1) : "$(BINDIR)" $(YAZ_ZOOMTST1_OBJS) $(DLL)
	$(LINK_PROGRAM) $(YAZ_ZOOMTST1_OBJS) /out:$(ZOOMTST1)

$(ZOOMTST2) : "$(BINDIR)" $(YAZ_ZOOMTST2_OBJS) $(DLL)
	$(LINK_PROGRAM) $(YAZ_ZOOMTST2_OBJS) /out:$(ZOOMTST2)

$(ZOOMTST3) : "$(BINDIR)" $(YAZ_ZOOMTST3_OBJS) $(DLL)
	$(LINK_PROGRAM) $(YAZ_ZOOMTST3_OBJS) /out:$(ZOOMTST3)

$(ZOOMTST4) : "$(BINDIR)" $(YAZ_ZOOMTST4_OBJS) $(DLL)
	$(LINK_PROGRAM) $(YAZ_ZOOMTST4_OBJS) /out:$(ZOOMTST4)

$(ZOOMTST5) : "$(BINDIR)" $(YAZ_ZOOMTST5_OBJS) $(DLL)
	$(LINK_PROGRAM) $(YAZ_ZOOMTST5_OBJS) /out:$(ZOOMTST5)

$(ZOOMTST6) : "$(BINDIR)" $(YAZ_ZOOMTST6_OBJS) $(DLL)
	$(LINK_PROGRAM) $(YAZ_ZOOMTST6_OBJS) /out:$(ZOOMTST6)

$(ZOOMTST7) : "$(BINDIR)" $(YAZ_ZOOMTST7_OBJS) $(DLL)
	$(LINK_PROGRAM) $(YAZ_ZOOMTST7_OBJS) /out:$(ZOOMTST7)

$(ZOOMTST8) : "$(BINDIR)" $(YAZ_ZOOMTST8_OBJS) $(DLL)
	$(LINK_PROGRAM) $(YAZ_ZOOMTST8_OBJS) /out:$(ZOOMTST8)

$(ZOOMTST9) : "$(BINDIR)" $(YAZ_ZOOMTST9_OBJS) $(DLL)
	$(LINK_PROGRAM) $(YAZ_ZOOMTST9_OBJS) /out:$(ZOOMTST9)

$(ZOOMTST10) : "$(BINDIR)" $(YAZ_ZOOMTST10_OBJS) $(DLL)
	$(LINK_PROGRAM) $(YAZ_ZOOMTST10_OBJS) /out:$(ZOOMTST10)

$(CQL2PQF) : "$(BINDIR)" $(YAZ_CQL2PQF_OBJS) $(DLL)
	$(LINK_PROGRAM) $(YAZ_CQL2PQF_OBJS) /out:$(CQL2PQF)

$(CQL2XCQL) : "$(BINDIR)" $(YAZ_CQL2XCQL_OBJS) $(DLL)
	$(LINK_PROGRAM) $(YAZ_CQL2XCQL_OBJS) /out:$(CQL2XCQL)

$(ZTEST) : "$(BINDIR)" $(ZTEST_OBJS) $(DLL)
	$(LINK_PROGRAM)	$(ZTEST_OBJS) /out:$(ZTEST) 

$(YAZ_MARCDUMP) : "$(BINDIR)" $(YAZ_MARCDUMP_OBJS) $(DLL)
	$(LINK_PROGRAM) $(YAZ_MARCDUMP_OBJS) /out:$(YAZ_MARCDUMP) 

$(TSTLOG) : "$(BINDIR)" $(TSTLOG_OBJS) $(DLL)
	$(LINK_PROGRAM) $(TSTLOG_OBJS) /out:$(TSTLOG)

$(TST_TIMING) : "$(BINDIR)" $(TST_TIMING_OBJS) $(DLL)
	$(LINK_PROGRAM) $(TST_TIMING_OBJS) /out:$(TST_TIMING)

# Other rules

$(DOCDIR)\htmlhelp.chm: $(DOCDIR)\htmlhelp.hhp
	@cd $(DOCDIR)
	-$(HHC) htmlhelp.hhp
	@cd $(WINDIR)

clean:
	-del $(BINDIR)\*.exe
	-del $(BINDIR)\*.dll
	-del $(BINDIR)\*.pdb
	-del $(TMPDIR)\*.
	-del $(LIBDIR)\*.LIB
	-del $(OBJDIR)\*.OBJ

realclean: clean
	-del $(SRCDIR)\marc8.c
	-del $(SRCDIR)\cql.c
	-del $(SRCDIR)\z-*.c
	-del $(SRCDIR)\ill-core.c
	-del $(SRCDIR)\item-req.c
	-del $(INCLDIR)\yaz\ill-core.h
	-del $(INCLDIR)\yaz\item-req.h
	-del $(INCLDIR)\yaz\z-accdes1.h
	-del $(INCLDIR)\yaz\z-core.h
	-del $(DATETIME_H_FILES)
	-del $(UNIVRES_H_FILES)
	-del $(ESUPDATE_H_FILES)

# Because DOS del will only accept one file name to delete,
# the _H_ files work only on sets that have just one file.
# Z3950_H_FILES had to be spelled out. One more point for MS!

# check directories and create if needed
dirs: $(OBJDIR) $(WINDIR) $(LIBDIR) $(BINDIR) $(TMPDIR)

$(OBJDIR) $(WINDIR) $(LIBDIR) $(BINDIR) $(TMPDIR):
	if not exist "$@/$(NUL)" mkdir "$@"


# Explicit dependencies

# force recompilation of everything, if makefile changed

$(Z3950_OBJS): $(GENERATED_C_FILES) $(GENERATED_H_FILES)

$(ILL_OBJS): $(ILL_CORE_FILES) $(ITEM_REQ_FILES)

# makes sure we generate before compiling anything, as the
# new proto.h refers to the generated files, and is included
# in various places

