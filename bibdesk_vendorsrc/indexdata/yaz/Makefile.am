## This file is part of the YAZ toolkit.
## Copyright (C) 1994-2005, Index Data, All rights reserved.
## $Id: Makefile.am,v 1.38 2006/11/29 22:35:17 adam Exp $

AUTOMAKE_OPTIONS = foreign 

ACLOCAL_AMFLAGS = -I m4

SUBDIRS = src include util test client ztest zoom ziffy doc etc

aclocaldir=$(datadir)/aclocal

aclocal_DATA = m4/yaz.m4

SPEC_FILE=$(PACKAGE).spec
EXTRA_DIST=$(SPEC_FILE) README LICENSE NEWS TODO \
	yaz-config.in m4/yaz.m4 m4/yaz_libxml2.m4 buildconf.sh \
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

