
/* parser.dlg -- DLG Description of scanner
 *
 * Generated from: bibtex.g
 *
 * Terence Parr, Will Cohen, and Hank Dietz: 1989-1994
 * Purdue University Electrical Engineering
 * With AHPCRC, University of Minnesota
 * ANTLR Version 1.33
 */

#include <stdio.h>
#define ANTLR_VERSION	133

#define ZZCOL
#define USER_ZZSYN

#include "config.h"
#include "btparse.h"
#include "attrib.h"
#include "lex_auxiliary.h"
#include "error.h"
#include "my_dmalloc.h"

extern char * InputFilename;            /* for zzcr_ast call in pccts/ast.c */
#include "antlr.h"
#include "ast.h"
#include "tokens.h"
#include "dlgdef.h"
LOOKAHEAD
void zzerraction()
{
	(*zzerr)("invalid token");
	zzadvance();
	zzskip();
}
/*
 * D L G tables
 *
 * Generated from: parser.dlg
 *
 * 1989-1994 by  Will Cohen, Terence Parr, and Hank Dietz
 * Purdue University Electrical Engineering
 * DLG Version 1.33
 */

#include "mode.h"



static void act1()
{ 
		NLA = 1;
	}


static void act2()
{ 
		NLA = AT;
		at_sign ();   
	}


static void act3()
{ 
		NLA = 3;
		newline ();   
	}


static void act4()
{ 
		NLA = COMMENT;
		comment ();   
	}


static void act5()
{ 
		NLA = 5;
		zzskip ();   
	}


static void act6()
{ 
		NLA = 6;
		toplevel_junk ();   
	}

static unsigned char shift0[257] = {
  0, 5, 5, 5, 5, 5, 5, 5, 5, 5, 
  4, 2, 5, 5, 4, 5, 5, 5, 5, 5, 
  5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 
  5, 5, 5, 4, 5, 5, 5, 5, 3, 5, 
  5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 
  5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 
  5, 5, 5, 5, 5, 1, 5, 5, 5, 5, 
  5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 
  5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 
  5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 
  5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 
  5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 
  5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 
  5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 
  5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 
  5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 
  5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 
  5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 
  5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 
  5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 
  5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 
  5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 
  5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 
  5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 
  5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 
  5, 5, 5, 5, 5, 5, 5
};


static void act7()
{ 
		NLA = 1;
	}


static void act8()
{ 
		NLA = 7;
		newline ();   
	}


static void act9()
{ 
		NLA = COMMENT;
		comment ();   
	}


static void act10()
{ 
		NLA = 8;
		zzskip ();   
	}


static void act11()
{ 
		NLA = NUMBER;
	}


static void act12()
{ 
		NLA = NAME;
		name ();   
	}


static void act13()
{ 
		NLA = LBRACE;
		lbrace ();   
	}


static void act14()
{ 
		NLA = RBRACE;
		rbrace ();   
	}


static void act15()
{ 
		NLA = ENTRY_OPEN;
		lparen ();   
	}


static void act16()
{ 
		NLA = ENTRY_CLOSE;
		rparen ();   
	}


static void act17()
{ 
		NLA = EQUALS;
	}


static void act18()
{ 
		NLA = HASH;
	}


static void act19()
{ 
		NLA = COMMA;
	}


static void act20()
{ 
		NLA = 18;
		start_string ('"');   
	}

static unsigned char shift1[257] = {
  0, 14, 14, 14, 14, 14, 14, 14, 14, 14, 
  3, 1, 14, 14, 3, 14, 14, 14, 14, 14, 
  14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 
  14, 14, 14, 3, 5, 13, 11, 5, 2, 5, 
  14, 8, 9, 5, 5, 12, 5, 5, 5, 4, 
  4, 4, 4, 4, 4, 4, 4, 4, 4, 5, 
  5, 5, 10, 5, 5, 14, 5, 5, 5, 5, 
  5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 
  5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 
  5, 5, 5, 14, 5, 5, 5, 5, 5, 5, 
  5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 
  5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 
  5, 5, 5, 5, 6, 5, 7, 14, 14, 14, 
  14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 
  14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 
  14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 
  14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 
  14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 
  14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 
  14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 
  14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 
  14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 
  14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 
  14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 
  14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 
  14, 14, 14, 14, 14, 14, 14
};


static void act21()
{ 
		NLA = 1;
	}


static void act22()
{ 
		NLA = 19;
		check_runaway_string ();   
	}


static void act23()
{ 
		NLA = 20;
		zzreplchar (' '); zzmore ();   
	}


static void act24()
{ 
		NLA = 21;
		open_brace ();   
	}


static void act25()
{ 
		NLA = 22;
		close_brace ();   
	}


static void act26()
{ 
		NLA = 23;
		lparen_in_string ();   
	}


static void act27()
{ 
		NLA = 24;
		rparen_in_string ();   
	}


static void act28()
{ 
		NLA = STRING;
		quote_in_string ();   
	}


static void act29()
{ 
		NLA = 26;
		zzmore ();   
	}

static unsigned char shift2[257] = {
  0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 
  2, 1, 3, 3, 2, 3, 3, 3, 3, 3, 
  3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 
  3, 3, 3, 3, 3, 8, 3, 3, 3, 3, 
  3, 6, 7, 3, 3, 3, 3, 3, 3, 3, 
  3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 
  3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 
  3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 
  3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 
  3, 3, 3, 9, 3, 3, 3, 3, 3, 3, 
  3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 
  3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 
  3, 3, 3, 3, 4, 3, 5, 3, 3, 3, 
  3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 
  3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 
  3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 
  3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 
  3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 
  3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 
  3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 
  3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 
  3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 
  3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 
  3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 
  3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 
  3, 3, 3, 3, 3, 3, 3
};

#define DfaStates	38
typedef unsigned char DfaState;

static DfaState st0[7] = {
  1, 2, 3, 4, 5, 6, 38
};

static DfaState st1[7] = {
  38, 38, 38, 38, 38, 38, 38
};

static DfaState st2[7] = {
  38, 38, 38, 38, 38, 38, 38
};

static DfaState st3[7] = {
  38, 38, 38, 38, 38, 38, 38
};

static DfaState st4[7] = {
  38, 7, 8, 9, 7, 9, 38
};

static DfaState st5[7] = {
  38, 38, 38, 38, 5, 38, 38
};

static DfaState st6[7] = {
  38, 38, 38, 6, 38, 6, 38
};

static DfaState st7[7] = {
  38, 7, 8, 7, 7, 7, 38
};

static DfaState st8[7] = {
  38, 38, 38, 38, 38, 38, 38
};

static DfaState st9[7] = {
  38, 7, 8, 9, 7, 9, 38
};

static DfaState st10[16] = {
  11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 
  21, 22, 23, 24, 38, 38
};

static DfaState st11[16] = {
  38, 38, 38, 38, 38, 38, 38, 38, 38, 38, 
  38, 38, 38, 38, 38, 38
};

static DfaState st12[16] = {
  38, 38, 38, 38, 38, 38, 38, 38, 38, 38, 
  38, 38, 38, 38, 38, 38
};

static DfaState st13[16] = {
  38, 25, 26, 26, 26, 26, 26, 26, 26, 26, 
  26, 26, 26, 26, 26, 38
};

static DfaState st14[16] = {
  38, 38, 38, 14, 38, 38, 38, 38, 38, 38, 
  38, 38, 38, 38, 38, 38
};

static DfaState st15[16] = {
  38, 38, 38, 38, 15, 16, 38, 38, 38, 38, 
  38, 38, 38, 38, 38, 38
};

static DfaState st16[16] = {
  38, 38, 38, 38, 16, 16, 38, 38, 38, 38, 
  38, 38, 38, 38, 38, 38
};

static DfaState st17[16] = {
  38, 38, 38, 38, 38, 38, 38, 38, 38, 38, 
  38, 38, 38, 38, 38, 38
};

static DfaState st18[16] = {
  38, 38, 38, 38, 38, 38, 38, 38, 38, 38, 
  38, 38, 38, 38, 38, 38
};

static DfaState st19[16] = {
  38, 38, 38, 38, 38, 38, 38, 38, 38, 38, 
  38, 38, 38, 38, 38, 38
};

static DfaState st20[16] = {
  38, 38, 38, 38, 38, 38, 38, 38, 38, 38, 
  38, 38, 38, 38, 38, 38
};

static DfaState st21[16] = {
  38, 38, 38, 38, 38, 38, 38, 38, 38, 38, 
  38, 38, 38, 38, 38, 38
};

static DfaState st22[16] = {
  38, 38, 38, 38, 38, 38, 38, 38, 38, 38, 
  38, 38, 38, 38, 38, 38
};

static DfaState st23[16] = {
  38, 38, 38, 38, 38, 38, 38, 38, 38, 38, 
  38, 38, 38, 38, 38, 38
};

static DfaState st24[16] = {
  38, 38, 38, 38, 38, 38, 38, 38, 38, 38, 
  38, 38, 38, 38, 38, 38
};

static DfaState st25[16] = {
  38, 38, 38, 38, 38, 38, 38, 38, 38, 38, 
  38, 38, 38, 38, 38, 38
};

static DfaState st26[16] = {
  38, 25, 26, 26, 26, 26, 26, 26, 26, 26, 
  26, 26, 26, 26, 26, 38
};

static DfaState st27[11] = {
  28, 29, 30, 31, 32, 33, 34, 35, 36, 31, 
  38
};

static DfaState st28[11] = {
  38, 38, 38, 38, 38, 38, 38, 38, 38, 38, 
  38
};

static DfaState st29[11] = {
  38, 38, 37, 37, 38, 38, 38, 38, 38, 38, 
  38
};

static DfaState st30[11] = {
  38, 38, 31, 31, 38, 38, 38, 38, 38, 31, 
  38
};

static DfaState st31[11] = {
  38, 38, 31, 31, 38, 38, 38, 38, 38, 31, 
  38
};

static DfaState st32[11] = {
  38, 38, 38, 38, 38, 38, 38, 38, 38, 38, 
  38
};

static DfaState st33[11] = {
  38, 38, 38, 38, 38, 38, 38, 38, 38, 38, 
  38
};

static DfaState st34[11] = {
  38, 38, 38, 38, 38, 38, 38, 38, 38, 38, 
  38
};

static DfaState st35[11] = {
  38, 38, 38, 38, 38, 38, 38, 38, 38, 38, 
  38
};

static DfaState st36[11] = {
  38, 38, 38, 38, 38, 38, 38, 38, 38, 38, 
  38
};

static DfaState st37[11] = {
  38, 38, 37, 37, 38, 38, 38, 38, 38, 38, 
  38
};


DfaState *dfa[38] = {
	st0,
	st1,
	st2,
	st3,
	st4,
	st5,
	st6,
	st7,
	st8,
	st9,
	st10,
	st11,
	st12,
	st13,
	st14,
	st15,
	st16,
	st17,
	st18,
	st19,
	st20,
	st21,
	st22,
	st23,
	st24,
	st25,
	st26,
	st27,
	st28,
	st29,
	st30,
	st31,
	st32,
	st33,
	st34,
	st35,
	st36,
	st37
};


DfaState accepts[39] = {
  0, 1, 2, 3, 6, 5, 6, 0, 4, 6, 
  0, 7, 8, 0, 10, 11, 12, 13, 14, 15, 
  16, 17, 18, 19, 20, 9, 0, 0, 21, 22, 
  23, 29, 24, 25, 26, 27, 28, 22, 0
};

void (*actions[30])() = {
	zzerraction,
	act1,
	act2,
	act3,
	act4,
	act5,
	act6,
	act7,
	act8,
	act9,
	act10,
	act11,
	act12,
	act13,
	act14,
	act15,
	act16,
	act17,
	act18,
	act19,
	act20,
	act21,
	act22,
	act23,
	act24,
	act25,
	act26,
	act27,
	act28,
	act29
};

static DfaState dfa_base[] = {
	0,
	10,
	27
};

static unsigned char *b_class_no[] = {
	shift0,
	shift1,
	shift2
};



#define ZZSHIFT(c) (b_class_no[zzauto][1+c])
#define MAX_MODE 3
#include "dlgauto.h"
