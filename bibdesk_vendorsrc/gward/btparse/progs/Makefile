# Generated automatically from Makefile.in by configure.
#
# Makefile for the 'progs' subdirectory in the btparse distribution;
# builds the example/utility programs bibparse, biblex, and dumpnames.
#
# $Id$
#

include ../Makefile.defs	# for CC, CFLAGS, etc.

# We put ../pccts in the include list because biblex is evil, naughty,
# and badly-behaved -- it evades the library and goes poking right
# into the guts of the lexical scanner in order to ferret out the
# token stream.  Thus, it needs access to the PCCTS header files in
# order to compile.
LIBDIR = ..
CPPFLAGS = -I$(LIBDIR) -I$(LIBDIR)/pccts

LIBDIRS = -L$(LIBDIR) $(OTHERLIBDIRS)
LIBS    = -lbtparse $(OTHERLIBS)
LDFLAGS = $(LIBDIRS) $(LIBS)


BPSRC   = bibparse.c args.c getopt.c getopt1.c
BPOBJ   = $(BPSRC:.c=.o)

BLSRC   = biblex.c
BLOBJ   = $(BLSRC:.c=.o)

DNSRC   = dumpnames.c
DNOBJ   = $(DNSRC:.c=.o)

all : bibparse biblex dumpnames

bibparse : $(BPOBJ) lib
	$(CC) -o $@ $(CFLAGS) $(BPOBJ) $(LDFLAGS)

biblex : $(BLOBJ) lib
	$(CC) -o $@ $(CFLAGS) $(BLOBJ) $(LDFLAGS)

dumpnames : $(DNOBJ) lib
	$(CC) -o $@ $(CFLAGS) $(DNOBJ) $(LDFLAGS)

lib:
	cd $(LIBDIR) ; make lib

clean:
	rm -f $(BPOBJ) $(BLOBJ) $(DNOBJ) core logfile

scrub: clean
	rm -f bibparse biblex dumpnames
	cat < /dev/null > .depend

dep .depend:
	$(CC) $(CFLAGS) -M $(BPSRC) $(BLSRC) > .depend

include .depend
