/*
 * A n t l r  S e t s / E r r o r  F i l e  H e a d e r
 *
 * Generated from: bibtex.g
 *
 * Terence Parr, Russell Quong, Will Cohen, and Hank Dietz: 1989-1995
 * Parr Research Corporation
 * with Purdue University Electrical Engineering
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
#define zzSET_SIZE 4
#include "antlr.h"
#include "ast.h"
#include "tokens.h"
#include "dlgdef.h"
#include "err.h"

ANTLRChar *zztokens[27]={
	/* 00 */	"Invalid",
	/* 01 */	"@",
	/* 02 */	"AT",
	/* 03 */	"\\n",
	/* 04 */	"COMMENT",
	/* 05 */	"[\\ \\r\\t]+",
	/* 06 */	"~[\\@\\n\\ \\r\\t]+",
	/* 07 */	"\\n",
	/* 08 */	"[\\ \\r\\t]+",
	/* 09 */	"NUMBER",
	/* 10 */	"NAME",
	/* 11 */	"LBRACE",
	/* 12 */	"RBRACE",
	/* 13 */	"ENTRY_OPEN",
	/* 14 */	"ENTRY_CLOSE",
	/* 15 */	"EQUALS",
	/* 16 */	"HASH",
	/* 17 */	"COMMA",
	/* 18 */	"\"",
	/* 19 */	"\\n~[\\n\\{\\}\\(\\)\"\\]*",
	/* 20 */	"[\\r\\t]",
	/* 21 */	"\\{",
	/* 22 */	"\\}",
	/* 23 */	"\\(",
	/* 24 */	"\\)",
	/* 25 */	"STRING",
	/* 26 */	"~[\\n\\{\\}\\(\\)\"]+"
};
SetWordType zzerr1[4] = {0x0,0x20,0x0,0x2};
SetWordType zzerr2[4] = {0x0,0x6,0x0,0x0};
SetWordType zzerr3[4] = {0x0,0x46,0x0,0x2};
SetWordType zzerr4[4] = {0x0,0x44,0x0,0x0};
SetWordType setwd1[27] = {0x0,0x7,0x6,0x0,0x0,0x0,0x0,
	0x0,0x0,0x28,0x38,0x0,0x0,0x0,0xd0,
	0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,
	0x0,0x0,0x20,0x0};
SetWordType zzerr5[4] = {0x0,0x6,0x0,0x2};
SetWordType setwd2[27] = {0x0,0x0,0x0,0x0,0x0,0x0,0x0,
	0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x7,
	0x0,0x4,0x7,0x0,0x0,0x0,0x0,0x0,
	0x0,0x0,0x0,0x0};
