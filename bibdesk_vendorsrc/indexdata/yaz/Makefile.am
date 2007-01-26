## This file is part of the YAZ toolkit.
## Copyright (C) 1995-2007, Index Data, All rights reserved.
## $Id: Makefile.am,v 1.40 2007/01/24 10:09:31 adam Exp $

AUTOMAKE_OPTIONS = foreign 

ACLOCAL_AMFLAGS = -I m4

SUBDIRS = src include util test client ztest zoom ziffy doc etc

aclocaldir=$(datadir)/aclocal

aclocal_DATA = m4/yaz.m4

pkgconfigdir = $(libdir)/pkgconfig
pkgconfig_DATA = yaz.pc

SPEC_FILE=$(PACKAGE).spec
EXTRA_DIST=$(SPEC_FILE) README LICENSE NEWS TODO \
	yaz-config.in yaz.pc.in m4/yaz.m4 m4/yaz_libxml2.m4 buildconf.sh \
	Doxyfile.in

dist-hook:
	if test -x /usr/bin/cvs2cl -a -d CVS; then cvs2cl ; fi
	mkdir $(distdir)/win
	-cp $(srcdir)/win/* $(distdir)/win
	mkdir $(distdir)/debian
	cp $(srcdir)/debian/control $(distdir)/debian
	cp $(srcdir)/debian/changelog $(distdir)/debian
	cp $(srcdir)/debian/rules $(distdir)/debian
	cp $(srcdir)/debian/*.postinst $(distdir)/debian
	cp $(srcdir)/debian/*.install $(distdir)/debian
	cp $(srcdir)/debian/*.manpages $(distdir)/debian

