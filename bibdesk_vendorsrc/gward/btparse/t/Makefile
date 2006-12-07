include ../Makefile.defs	# for CC, OPT, etc.

LIBDIR  = ..
INCDIR  = ../src
LIB     = btparse
LIBFILE = lib$(LIB).a
CPPFLAGS = -I$(INCDIR)

LDFLAGS = -L$(LIBDIR) -l$(LIB) $(EXTRA_LDFLAGS)

TESTLIB_SRC = testlib.c
TESTLIB_OBJ = testlib.o
TESTLIB_HDR = testlib.h

SIMPLE = simple_test
READ   = read_test
PP = postprocess_test


OBJ    = $(SIMPLE).o $(READ).o $(TESTLIB_OBJ)
EXEC   = $(SIMPLE) $(READ)

all test : simple read pp

read : $(READ)
	./$(READ) 2> /dev/null

simple : $(SIMPLE)
	./$(SIMPLE) 2> /dev/null

pp : $(PP)
	./$(PP)

$(SIMPLE) : $(SIMPLE).o $(TESTLIB_OBJ) lib
	$(CC) $(CFLAGS) -o $@ $(SIMPLE).o $(TESTLIB_OBJ) $(LDFLAGS)

$(READ) : $(READ).o $(TESTLIB_OBJ) lib
	$(CC) $(CFLAGS) -o $@ $(READ).o $(TESTLIB_OBJ) $(LDFLAGS)

$(PP): $(PP).o lib
	$(CC) $(CFLAGS) -o $@ $(PP).o $(LDFLAGS)

lib :
	cd $(LIBDIR) ; $(MAKE) $(LIBFILE)

clean :
	rm -f $(OBJ) $(EXEC) core logfile
