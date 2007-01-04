## $Id: Makefile.am,v 1.76 2006/12/13 09:40:32 adam Exp $

docdir=$(datadir)/doc/@PACKAGE@

SUBDIRS = common

XMLFILES=bookinfo.xml introduction.xml installation.xml \
 indexdata.xml \
 asn.xml tools.xml odr.xml comstack.xml frontend.xml license.xml \
 future.xml client.xml ziffy.xml zoom.xml credits.xml gfs-options.xml \
 yaz.xml yaz-client-commands.xml soap.xml gfs-virtual.xml gfs-synopsis.xml

HTMLFILES = index.html

MANFILES=yaz-client.1 yaz-ztest.8 \
	yaz-config.8 yaz.7 zoomsh.1 yaz-asncomp.1 \
	yaz-marcdump.1 yaz-iconv.1 yaz-log.7
REFFILES=yaz-client-man.xml yaz-ztest-man.xml yaz-config-man.xml \
	yaz-man.xml zoomsh-man.xml yaz-asncomp-man.xml \
	yaz-marcdump-man.xml yaz-iconv-man.xml yaz-log-man.xml

SUPPORTFILES=entities.ent apilayer.obj local.ent.in

doc_DATA = $(HTMLFILES) apilayer.png 
man_MANS = $(MANFILES)

EXTRA_DIST = $(XMLFILES) $(SUPPORTFILES) $(man_MANS) $(REFFILES) \
	$(doc_DATA)

yaz-client.1: $(srcdir)/yaz-client-man.xml $(srcdir)/yaz-client-commands.xml
	$(MAN_COMPILE) $(srcdir)/yaz-client-man.xml

yaz-ztest.8: yaz-ztest-man.xml gfs-options.xml gfs-synopsis.xml gfs-virtual.xml
	$(MAN_COMPILE) $(srcdir)/yaz-ztest-man.xml

yaz-config.8: yaz-config-man.xml
	$(MAN_COMPILE) $(srcdir)/yaz-config-man.xml

yaz.7: yaz-man.xml
	$(MAN_COMPILE) $(srcdir)/yaz-man.xml

zoomsh.1: zoomsh-man.xml
	$(MAN_COMPILE) $(srcdir)/zoomsh-man.xml

yaz-asncomp.1: yaz-asncomp-man.xml
	$(MAN_COMPILE) $(srcdir)/yaz-asncomp-man.xml

yaz-marcdump.1: yaz-marcdump-man.xml
	$(MAN_COMPILE) $(srcdir)/yaz-marcdump-man.xml

yaz-iconv.1: yaz-iconv-man.xml
	$(MAN_COMPILE) $(srcdir)/yaz-iconv-man.xml

yaz-log.7: yaz-log-man.xml
	$(MAN_COMPILE) $(srcdir)/yaz-log-man.xml

$(HTMLFILES): $(XMLFILES)
	rm -f *.html
	$(HTML_COMPILE) $(srcdir)/yaz.xml

index.tkl: $(XMLFILES)
	rm -f *.tkl
	$(TKL_COMPILE) $(srcdir)/yaz.xml

yaz.pdf: $(XMLFILES)
	if test ! -f common/id.png ; then cp $(srcdir)/common/id.png common; fi
	if test ! -f apilayer.png ; then cp $(srcdir)/apilayer.png .; fi
	jade -E14 -D $(srcdir) -d common/print.dsl -t tex $(srcdir)/common/xml.dcl $(srcdir)/yaz.xml
	pdfjadetex yaz.tex 
	pdfjadetex yaz.tex >/dev/null
	pdfjadetex yaz.tex >/dev/null

apilayer.png: 
	tgif -print -xbm apilayer.obj
	xbmtopbm <apilayer.xbm|pnmtopng >apilayer.png

dist-hook:
	if test -f index.html; then d=.; else d="$(srcdir)"; fi; \
	for p in $$d/*.html; do \
		cp $$p $(distdir); \
	done

doc-clean:
	rm -f *.html *.[0-9] *.pdf *.tkl

install-data-hook:
	if test -f index.html; then d=.; else d="$(srcdir)"; fi; \
	for p in $$d/*.html; do \
		$(docDATA_INSTALL) $$p $(DESTDIR)/$(docdir); \
	done

uninstall-hook:
	rm -r $(DESTDIR)/$(docdir)
