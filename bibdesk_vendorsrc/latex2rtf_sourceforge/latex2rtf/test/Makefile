#
# Initial version 28 May 2001 Scott Prahl
#
LATEX= latex
BIBTEX= bibtex
LATEX2RTF= ../latex2rtf
OPTIONS  = -Z3 -P ../cfg/:../scripts/ -T ../tmp/

RTF=accentchars.rtf array.rtf eqns.rtf fonts.rtf fontsize.rtf \
    frac.rtf list.rtf logo.rtf misc1.rtf misc2.rtf oddchars.rtf \
    tabular.rtf percent.rtf essential.rtf misc3.rtf misc4.rtf fancy.rtf \
	align.rtf box.rtf \
	babel_german.rtf babel_russian.rtf babel_czech.rtf babel_french.rtf \
	babel_spanish.rtf babel_frenchb.rtf \
	bib_simple.rtf bib_apalike.rtf bib_apalike2.rtf bib_natbib1.rtf bib_natbib2.rtf \
	bib_natbib3.rtf bib_harvard.rtf \
	enc_applemac.rtf enc_cp437.rtf enc_cp865.rtf    enc_latin2.rtf enc_latin5.rtf \
	enc_cp1250.rtf   enc_cp850.rtf enc_decmulti.rtf enc_latin3.rtf enc_latin9.rtf\
	enc_cp1252.rtf   enc_cp852.rtf enc_latin1.rtf   enc_latin4.rtf enc_next.rtf\
	enc_cp1251.rtf   enc_cp855.rtf enc_cp866.rtf    enc_koi8-r.rtf enc_koi8-u.rtf \
	enc_maccyr.rtf enc_macukr.rtf eqns-koi8.rtf \
	defs.rtf qualisex.rtf ttgfsr7.rtf excalibur.rtf include.rtf ch.rtf\
	spago1.rtf theorem.rtf picture.rtf tabbing.rtf \
	fig_test.rtf fig_test2.rtf fig_size.rtf \
	chem.rtf subsup.rtf linux.rtf color.rtf \
	head_book.rtf head_article.rtf head_report.rtf endnote.rtf report.rtf

RTFX=bib_apacite.rtf bib_apanat.rtf bib_authordate.rtf fig_test3.rtf

all:
	mkdir -p ../tmp
	$(MAKE) rtf

rtf: $(RTF)

%.rtf:	%.tex
	$(LATEX2RTF) $(OPTIONS) $<

bib_simple.rtf: bib_simple.tex bib_simple.bib
	$(LATEX) bib_simple > latex.log
	$(BIBTEX) bib_simple > bibtex.log
	$(LATEX) bib_simple > latex.log
	$(LATEX) bib_simple > latex.log
	$(LATEX2RTF) $(OPTIONS) bib_simple

bib_apalike.rtf: bib_apalike.tex
	$(LATEX) bib_apalike > latex.log
	$(LATEX) bib_apalike > latex.log
	$(LATEX2RTF) $(OPTIONS) bib_apalike

bib_apacite.rtf: bib_apacite.tex
	$(LATEX) bib_apacite > latex.log
	$(LATEX) bib_apacite > latex.log
	$(LATEX2RTF) $(OPTIONS) bib_apacite

bib_apalike2.rtf: bib_apalike2.tex
	$(LATEX) bib_apalike2 > latex.log
	$(LATEX) bib_apalike2 > latex.log
	$(LATEX2RTF) $(OPTIONS) bib_apalike2

bib_natbib1.rtf: bib_natbib1.tex
	$(LATEX) bib_natbib1 > latex.log
	$(LATEX) bib_natbib1 > latex.log
	$(LATEX2RTF) $(OPTIONS) bib_natbib1

bib_natbib2.rtf: bib_natbib2.tex
	$(LATEX) bib_natbib2 > latex.log
	$(LATEX) bib_natbib2 > latex.log
	$(LATEX2RTF) $(OPTIONS) bib_natbib2

bib_natbib3.rtf: bib_natbib3.tex
	$(LATEX) bib_natbib3 > latex.log
	$(LATEX) bib_natbib3 > latex.log
	$(LATEX2RTF) $(OPTIONS) bib_natbib3

bib_apanat.rtf: bib_apanat.tex
	$(LATEX) bib_apanat > latex.log
	$(LATEX) bib_apanat > latex.log
	$(LATEX2RTF) $(OPTIONS) bib_apanat

bib_harvard.rtf: bib_harvard.tex
	$(LATEX) bib_harvard > latex.log
	$(LATEX) bib_harvard > latex.log
	$(LATEX2RTF) $(OPTIONS) bib_harvard

bib_authordate.rtf: bib_authordate.tex
	$(LATEX) bib_authordate > latex.log
	$(LATEX) bib_authordate > latex.log
	$(LATEX2RTF) $(OPTIONS) bib_authordate

misc2.rtf: misc2.tex
	$(LATEX) misc2 > latex.log
	$(LATEX) misc2 > latex.log
	$(LATEX2RTF) $(OPTIONS) misc2

german.rtf: german.tex
	$(LATEX) german > latex.log
	$(LATEX) german > latex.log
	$(LATEX2RTF) $(OPTIONS) german

russian.rtf: russian.tex
	$(LATEX) russian > russian.log
	$(LATEX) russian > russian.log
	$(LATEX2RTF) $(OPTIONS) russian

ttgfsr7.rtf: ttgfsr7.tex
	$(LATEX) ttgfsr7 > latex.log
	$(LATEX) ttgfsr7 > latex.log
	$(LATEX2RTF) $(OPTIONS) ttgfsr7

fig_test.rtf: fig_test.tex fig_test.eps fig_testc.ps
	$(LATEX) fig_test > latex.log
	$(LATEX) fig_test > latex.log
	$(LATEX2RTF) $(OPTIONS) -F fig_test

fig_test2.rtf: fig_test2.tex fig_testb.pdf fig_testc.pdf
	$(LATEX2RTF) $(OPTIONS) -D 300 fig_test2
	mv fig_test2.rtf fig_test2a.rtf
	$(LATEX2RTF) $(OPTIONS) fig_test2

fig_test3.rtf: fig_test3.tex fig_testd.ps fig_testd.pdf
	$(LATEX2RTF) $(OPTIONS) fig_test3

linux.rtf: linux.tex
	$(LATEX) linux > latex.log
	$(LATEX) linux > latex.log
	$(LATEX2RTF) $(OPTIONS) linux

check:
	./bracecheck
	
clean:
	mv fig_testb.pdf fig_testb.tmp
	mv fig_testc.pdf fig_testc.tmp
	mv fig_testd.pdf fig_testd.tmp
	rm -f *.dvi *.rtf *.aux *.blg *.bbl *.log *.pdf *.toc *.lot *.idx *.ilg *.ind
	rm -f l2r*tex frlicense.dat *.fff *.lof
	mv fig_testb.tmp fig_testb.pdf
	mv fig_testc.tmp fig_testc.pdf
	mv fig_testd.tmp fig_testd.pdf
	rm -rf ../tmp

.PHONY: clean all check
