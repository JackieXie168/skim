//========================================================================
//
// JBIG2Stream.cc
//
// Copyright 2002 Glyph & Cog, LLC
//
//========================================================================

#include <aconf.h>

#ifdef USE_GCC_PRAGMAS
#pragma implementation
#endif

#include <stdlib.h>
#include "GList.h"
#include "Error.h"
#include "JBIG2Stream.h"

//~ share these tables
#include "Stream-CCITT.h"

//------------------------------------------------------------------------

static int contextSize[4] = { 16, 13, 10, 10 };
static int refContextSize[2] = { 13, 10 };

//------------------------------------------------------------------------
// JBIG2ArithmeticDecoderStats
//------------------------------------------------------------------------

class JBIG2ArithmeticDecoderStats {
public:

  JBIG2ArithmeticDecoderStats(int contextSizeA);
  ~JBIG2ArithmeticDecoderStats();
  JBIG2ArithmeticDecoderStats *copy();
  void reset();
  int getContextSize() { return contextSize; }
  void copyFrom(JBIG2ArithmeticDecoderStats *stats);

private:

  Guchar *cxTab;		// cxTab[cx] = (i[cx] << 1) + mps[cx]
  int contextSize;

  friend class JBIG2ArithmeticDecoder;
};

JBIG2ArithmeticDecoderStats::JBIG2ArithmeticDecoderStats(int contextSizeA) {
  contextSize = contextSizeA;
  cxTab = (Guchar *)gmalloc((1 << contextSize) * sizeof(Guchar));
  reset();
}

JBIG2ArithmeticDecoderStats::~JBIG2ArithmeticDecoderStats() {
  gfree(cxTab);
}

JBIG2ArithmeticDecoderStats *JBIG2ArithmeticDecoderStats::copy() {
  JBIG2ArithmeticDecoderStats *stats;

  stats = new JBIG2ArithmeticDecoderStats(contextSize);
  memcpy(stats->cxTab, cxTab, 1 << contextSize);
  return stats;
}

void JBIG2ArithmeticDecoderStats::reset() {
  memset(cxTab, 0, 1 << contextSize);
}

void JBIG2ArithmeticDecoderStats::copyFrom(
		                      JBIG2ArithmeticDecoderStats *stats) {
  memcpy(cxTab, stats->cxTab, 1 << contextSize);
}

//------------------------------------------------------------------------
// JBIG2ArithmeticDecoder
//------------------------------------------------------------------------

class JBIG2ArithmeticDecoder {
public:

  JBIG2ArithmeticDecoder();
  ~JBIG2ArithmeticDecoder();
  void setStream(Stream *strA) { str = strA; }
  void start();
  int decodeBit(Guint context, JBIG2ArithmeticDecoderStats *stats);
  int decodeByte(Guint context, JBIG2ArithmeticDecoderStats *stats);

  // Returns false for OOB, otherwise sets *<x> and returns true.
  GBool decodeInt(int *x, JBIG2ArithmeticDecoderStats *stats);

  Guint decodeIAID(Guint codeLen,
		   JBIG2ArithmeticDecoderStats *stats);

private:

  int decodeIntBit(JBIG2ArithmeticDecoderStats *stats);
  void byteIn();

  static Guint qeTab[47];
  static int nmpsTab[47];
  static int nlpsTab[47];
  static int switchTab[47];

  Guint buf0, buf1;
  Guint c, a;
  int ct;

  Guint prev;			// for the integer decoder

  Stream *str;
};

Guint JBIG2ArithmeticDecoder::qeTab[47] = {
  0x56010000, 0x34010000, 0x18010000, 0x0AC10000,
  0x05210000, 0x02210000, 0x56010000, 0x54010000,
  0x48010000, 0x38010000, 0x30010000, 0x24010000,
  0x1C010000, 0x16010000, 0x56010000, 0x54010000,
  0x51010000, 0x48010000, 0x38010000, 0x34010000,
  0x30010000, 0x28010000, 0x24010000, 0x22010000,
  0x1C010000, 0x18010000, 0x16010000, 0x14010000,
  0x12010000, 0x11010000, 0x0AC10000, 0x09C10000,
  0x08A10000, 0x05210000, 0x04410000, 0x02A10000,
  0x02210000, 0x01410000, 0x01110000, 0x00850000,
  0x00490000, 0x00250000, 0x00150000, 0x00090000,
  0x00050000, 0x00010000, 0x56010000
};

int JBIG2ArithmeticDecoder::nmpsTab[47] = {
   1,  2,  3,  4,  5, 38,  7,  8,  9, 10, 11, 12, 13, 29, 15, 16,
  17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32,
  33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 45, 46
};

int JBIG2ArithmeticDecoder::nlpsTab[47] = {
   1,  6,  9, 12, 29, 33,  6, 14, 14, 14, 17, 18, 20, 21, 14, 14,
  15, 16, 17, 18, 19, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29,
  30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 46
};

int JBIG2ArithmeticDecoder::switchTab[47] = {
  1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
};

JBIG2ArithmeticDecoder::JBIG2ArithmeticDecoder() {
  str = NULL;
}

JBIG2ArithmeticDecoder::~JBIG2ArithmeticDecoder() {
}

void JBIG2ArithmeticDecoder::start() {
  buf0 = (Guint)str->getChar() & 0xff;
  buf1 = (Guint)str->getChar() & 0xff;

  // INITDEC
  c = (buf0 ^ 0xff) << 16;
  byteIn();
  c <<= 7;
  ct -= 7;
  a = 0x80000000;
}

int JBIG2ArithmeticDecoder::decodeBit(Guint context,
				      JBIG2ArithmeticDecoderStats *stats) {
  int bit;
  Guint qe;
  int iCX, mpsCX;

  iCX = stats->cxTab[context] >> 1;
  mpsCX = stats->cxTab[context] & 1;
  qe = qeTab[iCX];
  a -= qe;
  if (c < a) {
    if (a & 0x80000000) {
      bit = mpsCX;
    } else {
      // MPS_EXCHANGE
      if (a < qe) {
	bit = 1 - mpsCX;
	if (switchTab[iCX]) {
	  stats->cxTab[context] = (nlpsTab[iCX] << 1) | (1 - mpsCX);
	} else {
	  stats->cxTab[context] = (nlpsTab[iCX] << 1) | mpsCX;
	}
      } else {
	bit = mpsCX;
	stats->cxTab[context] = (nmpsTab[iCX] << 1) | mpsCX;
      }
      // RENORMD
      do {
	if (ct == 0) {
	  byteIn();
	}
	a <<= 1;
	c <<= 1;
	--ct;
      } while (!(a & 0x80000000));
    }
  } else {
    c -= a;
    // LPS_EXCHANGE
    if (a < qe) {
      bit = mpsCX;
      stats->cxTab[context] = (nmpsTab[iCX] << 1) | mpsCX;
    } else {
      bit = 1 - mpsCX;
      if (switchTab[iCX]) {
	stats->cxTab[context] = (nlpsTab[iCX] << 1) | (1 - mpsCX);
      } else {
	stats->cxTab[context] = (nlpsTab[iCX] << 1) | mpsCX;
      }
    }
    a = qe;
    // RENORMD
    do {
      if (ct == 0) {
	byteIn();
      }
      a <<= 1;
      c <<= 1;
      --ct;
    } while (!(a & 0x80000000));
  }
  return bit;
}

int JBIG2ArithmeticDecoder::decodeByte(Guint context,
				       JBIG2ArithmeticDecoderStats *stats) {
  int byte;
  int i;

  byte = 0;
  for (i = 0; i < 8; ++i) {
    byte = (byte << 1) | decodeBit(context, stats);
  }
  return byte;
}

GBool JBIG2ArithmeticDecoder::decodeInt(int *x,
					JBIG2ArithmeticDecoderStats *stats) {
  int s;
  Guint v;
  int i;

  prev = 1;
  s = decodeIntBit(stats);
  if (decodeIntBit(stats)) {
    if (decodeIntBit(stats)) {
      if (decodeIntBit(stats)) {
	if (decodeIntBit(stats)) {
	  if (decodeIntBit(stats)) {
	    v = 0;
	    for (i = 0; i < 32; ++i) {
	      v = (v << 1) | decodeIntBit(stats);
	    }
	    v += 4436;
	  } else {
	    v = 0;
	    for (i = 0; i < 12; ++i) {
	      v = (v << 1) | decodeIntBit(stats);
	    }
	    v += 340;
	  }
	} else {
	  v = 0;
	  for (i = 0; i < 8; ++i) {
	    v = (v << 1) | decodeIntBit(stats);
	  }
	  v += 84;
	}
      } else {
	v = 0;
	for (i = 0; i < 6; ++i) {
	  v = (v << 1) | decodeIntBit(stats);
	}
	v += 20;
      }
    } else {
      v = decodeIntBit(stats);
      v = (v << 1) | decodeIntBit(stats);
      v = (v << 1) | decodeIntBit(stats);
      v = (v << 1) | decodeIntBit(stats);
      v += 4;
    }
  } else {
    v = decodeIntBit(stats);
    v = (v << 1) | decodeIntBit(stats);
  }

  if (s) {
    if (v == 0) {
      return gFalse;
    }
    *x = -(int)v;
  } else {
    *x = (int)v;
  }
  return gTrue;
}

int JBIG2ArithmeticDecoder::decodeIntBit(JBIG2ArithmeticDecoderStats *stats) {
  int bit;

  bit = decodeBit(prev, stats);
  if (prev < 0x100) {
    prev = (prev << 1) | bit;
  } else {
    prev = (((prev << 1) | bit) & 0x1ff) | 0x100;
  }
  return bit;
}

Guint JBIG2ArithmeticDecoder::decodeIAID(Guint codeLen,
					 JBIG2ArithmeticDecoderStats *stats) {
  Guint i;
  int bit;

  prev = 1;
  for (i = 0; i < codeLen; ++i) {
    bit = decodeBit(prev, stats);
    prev = (prev << 1) | bit;
  }
  return prev - (1 << codeLen);
}

void JBIG2ArithmeticDecoder::byteIn() {
  if (buf0 == 0xff) {
    if (buf1 > 0x8f) {
      ct = 8;
    } else {
      buf0 = buf1;
      buf1 = (Guint)str->getChar() & 0xff;
      c = c + 0xfe00 - (buf0 << 9);
      ct = 7;
    }
  } else {
    buf0 = buf1;
    buf1 = (Guint)str->getChar() & 0xff;
    c = c + 0xff00 - (buf0 << 8);
    ct = 8;
  }
}

//------------------------------------------------------------------------
// JBIG2HuffmanTable
//------------------------------------------------------------------------

#define jbig2HuffmanLOW 0xfffffffd
#define jbig2HuffmanOOB 0xfffffffe
#define jbig2HuffmanEOT 0xffffffff

struct JBIG2HuffmanTable {
  int val;
  Guint prefixLen;
  Guint rangeLen;		// can also be LOW, OOB, or EOT
  Guint prefix;
};

JBIG2HuffmanTable huffTableA[] = {
  {     0, 1,  4,              0x000 },
  {    16, 2,  8,              0x002 },
  {   272, 3, 16,              0x006 },
  { 65808, 3, 32,              0x007 },
  {     0, 0, jbig2HuffmanEOT, 0     }
};

JBIG2HuffmanTable huffTableB[] = {
  {     0, 1,  0,              0x000 },
  {     1, 2,  0,              0x002 },
  {     2, 3,  0,              0x006 },
  {     3, 4,  3,              0x00e },
  {    11, 5,  6,              0x01e },
  {    75, 6, 32,              0x03e },
  {     0, 6, jbig2HuffmanOOB, 0x03f },
  {     0, 0, jbig2HuffmanEOT, 0     }
};

JBIG2HuffmanTable huffTableC[] = {
  {     0, 1,  0,              0x000 },
  {     1, 2,  0,              0x002 },
  {     2, 3,  0,              0x006 },
  {     3, 4,  3,              0x00e },
  {    11, 5,  6,              0x01e },
  {     0, 6, jbig2HuffmanOOB, 0x03e },
  {    75, 7, 32,              0x0fe },
  {  -256, 8,  8,              0x0fe },
  {  -257, 8, jbig2HuffmanLOW, 0x0ff },
  {     0, 0, jbig2HuffmanEOT, 0     }
};

JBIG2HuffmanTable huffTableD[] = {
  {     1, 1,  0,              0x000 },
  {     2, 2,  0,              0x002 },
  {     3, 3,  0,              0x006 },
  {     4, 4,  3,              0x00e },
  {    12, 5,  6,              0x01e },
  {    76, 5, 32,              0x01f },
  {     0, 0, jbig2HuffmanEOT, 0     }
};

JBIG2HuffmanTable huffTableE[] = {
  {     1, 1,  0,              0x000 },
  {     2, 2,  0,              0x002 },
  {     3, 3,  0,              0x006 },
  {     4, 4,  3,              0x00e },
  {    12, 5,  6,              0x01e },
  {    76, 6, 32,              0x03e },
  {  -255, 7,  8,              0x07e },
  {  -256, 7, jbig2HuffmanLOW, 0x07f },
  {     0, 0, jbig2HuffmanEOT, 0     }
};

JBIG2HuffmanTable huffTableF[] = {
  {     0, 2,  7,              0x000 },
  {   128, 3,  7,              0x002 },
  {   256, 3,  8,              0x003 },
  { -1024, 4,  9,              0x008 },
  {  -512, 4,  8,              0x009 },
  {  -256, 4,  7,              0x00a },
  {   -32, 4,  5,              0x00b },
  {   512, 4,  9,              0x00c },
  {  1024, 4, 10,              0x00d },
  { -2048, 5, 10,              0x01c },
  {  -128, 5,  6,              0x01d },
  {   -64, 5,  5,              0x01e },
  { -2049, 6, jbig2HuffmanLOW, 0x03e },
  {  2048, 6, 32,              0x03f },
  {     0, 0, jbig2HuffmanEOT, 0     }
};

JBIG2HuffmanTable huffTableG[] = {
  {  -512, 3,  8,              0x000 },
  {   256, 3,  8,              0x001 },
  {   512, 3,  9,              0x002 },
  {  1024, 3, 10,              0x003 },
  { -1024, 4,  9,              0x008 },
  {  -256, 4,  7,              0x009 },
  {   -32, 4,  5,              0x00a },
  {     0, 4,  5,              0x00b },
  {   128, 4,  7,              0x00c },
  {  -128, 5,  6,              0x01a },
  {   -64, 5,  5,              0x01b },
  {    32, 5,  5,              0x01c },
  {    64, 5,  6,              0x01d },
  { -1025, 5, jbig2HuffmanLOW, 0x01e },
  {  2048, 5, 32,              0x01f },
  {     0, 0, jbig2HuffmanEOT, 0     }
};

JBIG2HuffmanTable huffTableH[] = {
  {     0, 2,  1,              0x000 },
  {     0, 2, jbig2HuffmanOOB, 0x001 },
  {     4, 3,  4,              0x004 },
  {    -1, 4,  0,              0x00a },
  {    22, 4,  4,              0x00b },
  {    38, 4,  5,              0x00c },
  {     2, 5,  0,              0x01a },
  {    70, 5,  6,              0x01b },
  {   134, 5,  7,              0x01c },
  {     3, 6,  0,              0x03a },
  {    20, 6,  1,              0x03b },
  {   262, 6,  7,              0x03c },
  {   646, 6, 10,              0x03d },
  {    -2, 7,  0,              0x07c },
  {   390, 7,  8,              0x07d },
  {   -15, 8,  3,              0x0fc },
  {    -5, 8,  1,              0x0fd },
  {    -7, 9,  1,              0x1fc },
  {    -3, 9,  0,              0x1fd },
  {   -16, 9, jbig2HuffmanLOW, 0x1fe },
  {  1670, 9, 32,              0x1ff },
  {     0, 0, jbig2HuffmanEOT, 0     }
};

JBIG2HuffmanTable huffTableI[] = {
  {     0, 2, jbig2HuffmanOOB, 0x000 },
  {    -1, 3,  1,              0x002 },
  {     1, 3,  1,              0x003 },
  {     7, 3,  5,              0x004 },
  {    -3, 4,  1,              0x00a },
  {    43, 4,  5,              0x00b },
  {    75, 4,  6,              0x00c },
  {     3, 5,  1,              0x01a },
  {   139, 5,  7,              0x01b },
  {   267, 5,  8,              0x01c },
  {     5, 6,  1,              0x03a },
  {    39, 6,  2,              0x03b },
  {   523, 6,  8,              0x03c },
  {  1291, 6, 11,              0x03d },
  {    -5, 7,  1,              0x07c },
  {   779, 7,  9,              0x07d },
  {   -31, 8,  4,              0x0fc },
  {   -11, 8,  2,              0x0fd },
  {   -15, 9,  2,              0x1fc },
  {    -7, 9,  1,              0x1fd },
  {   -32, 9, jbig2HuffmanLOW, 0x1fe },
  {  3339, 9, 32,              0x1ff },
  {     0, 0, jbig2HuffmanEOT, 0     }
};

JBIG2HuffmanTable huffTableJ[] = {
  {    -2, 2,  2,              0x000 },
  {     6, 2,  6,              0x001 },
  {     0, 2, jbig2HuffmanOOB, 0x002 },
  {    -3, 5,  0,              0x018 },
  {     2, 5,  0,              0x019 },
  {    70, 5,  5,              0x01a },
  {     3, 6,  0,              0x036 },
  {   102, 6,  5,              0x037 },
  {   134, 6,  6,              0x038 },
  {   198, 6,  7,              0x039 },
  {   326, 6,  8,              0x03a },
  {   582, 6,  9,              0x03b },
  {  1094, 6, 10,              0x03c },
  {   -21, 7,  4,              0x07a },
  {    -4, 7,  0,              0x07b },
  {     4, 7,  0,              0x07c },
  {  2118, 7, 11,              0x07d },
  {    -5, 8,  0,              0x0fc },
  {     5, 8,  0,              0x0fd },
  {   -22, 8, jbig2HuffmanLOW, 0x0fe },
  {  4166, 8, 32,              0x0ff },
  {     0, 0, jbig2HuffmanEOT, 0     }
};

JBIG2HuffmanTable huffTableK[] = {
  {     1, 1,  0,              0x000 },
  {     2, 2,  1,              0x002 },
  {     4, 4,  0,              0x00c },
  {     5, 4,  1,              0x00d },
  {     7, 5,  1,              0x01c },
  {     9, 5,  2,              0x01d },
  {    13, 6,  2,              0x03c },
  {    17, 7,  2,              0x07a },
  {    21, 7,  3,              0x07b },
  {    29, 7,  4,              0x07c },
  {    45, 7,  5,              0x07d },
  {    77, 7,  6,              0x07e },
  {   141, 7, 32,              0x07f },
  {     0, 0, jbig2HuffmanEOT, 0     }
};

JBIG2HuffmanTable huffTableL[] = {
  {     1, 1,  0,              0x000 },
  {     2, 2,  0,              0x002 },
  {     3, 3,  1,              0x006 },
  {     5, 5,  0,              0x01c },
  {     6, 5,  1,              0x01d },
  {     8, 6,  1,              0x03c },
  {    10, 7,  0,              0x07a },
  {    11, 7,  1,              0x07b },
  {    13, 7,  2,              0x07c },
  {    17, 7,  3,              0x07d },
  {    25, 7,  4,              0x07e },
  {    41, 8,  5,              0x0fe },
  {    73, 8, 32,              0x0ff },
  {     0, 0, jbig2HuffmanEOT, 0     }
};

JBIG2HuffmanTable huffTableM[] = {
  {     1, 1,  0,              0x000 },
  {     2, 3,  0,              0x004 },
  {     7, 3,  3,              0x005 },
  {     3, 4,  0,              0x00c },
  {     5, 4,  1,              0x00d },
  {     4, 5,  0,              0x01c },
  {    15, 6,  1,              0x03a },
  {    17, 6,  2,              0x03b },
  {    21, 6,  3,              0x03c },
  {    29, 6,  4,              0x03d },
  {    45, 6,  5,              0x03e },
  {    77, 7,  6,              0x07e },
  {   141, 7, 32,              0x07f },
  {     0, 0, jbig2HuffmanEOT, 0     }
};

JBIG2HuffmanTable huffTableN[] = {
  {     0, 1,  0,              0x000 },
  {    -2, 3,  0,              0x004 },
  {    -1, 3,  0,              0x005 },
  {     1, 3,  0,              0x006 },
  {     2, 3,  0,              0x007 },
  {     0, 0, jbig2HuffmanEOT, 0     }
};

JBIG2HuffmanTable huffTableO[] = {
  {     0, 1,  0,              0x000 },
  {    -1, 3,  0,              0x004 },
  {     1, 3,  0,              0x005 },
  {    -2, 4,  0,              0x00c },
  {     2, 4,  0,              0x00d },
  {    -4, 5,  1,              0x01c },
  {     3, 5,  1,              0x01d },
  {    -8, 6,  2,              0x03c },
  {     5, 6,  2,              0x03d },
  {   -24, 7,  4,              0x07c },
  {     9, 7,  4,              0x07d },
  {   -25, 7, jbig2HuffmanLOW, 0x07e },
  {    25, 7, 32,              0x07f },
  {     0, 0, jbig2HuffmanEOT, 0     }
};

//------------------------------------------------------------------------
// JBIG2HuffmanDecoder
//------------------------------------------------------------------------

class JBIG2HuffmanDecoder {
public:

  JBIG2HuffmanDecoder();
  ~JBIG2HuffmanDecoder();
  void setStream(Stream *strA) { str = strA; }

  void reset();

  // Returns false for OOB, otherwise sets *<x> and returns true.
  GBool decodeInt(int *x, JBIG2HuffmanTable *table);

  Guint readBits(Guint n);
  Guint readBit();

  // Sort the table by prefix length and assign prefix values.
  void buildTable(JBIG2HuffmanTable *table, Guint len);

private:

  Stream *str;
  Guint buf;
  Guint bufLen;
};

JBIG2HuffmanDecoder::JBIG2HuffmanDecoder() {
  str = NULL;
  reset();
}

JBIG2HuffmanDecoder::~JBIG2HuffmanDecoder() {
}

void JBIG2HuffmanDecoder::reset() {
  buf = 0;
  bufLen = 0;
}

//~ optimize this
GBool JBIG2HuffmanDecoder::decodeInt(int *x, JBIG2HuffmanTable *table) {
  Guint i, len, prefix;

  i = 0;
  len = 0;
  prefix = 0;
  while (table[i].rangeLen != jbig2HuffmanEOT) {
    //~ if buildTable removes the entries with prefixLen=0, this is unneeded
    if (table[i].prefixLen > 0) {
      while (len < table[i].prefixLen) {
	prefix = (prefix << 1) | readBit();
	++len;
      }
      if (prefix == table[i].prefix) {
	if (table[i].rangeLen == jbig2HuffmanOOB) {
	  return gFalse;
	}
	if (table[i].rangeLen == jbig2HuffmanLOW) {
	  *x = table[i].val - readBits(32);
	} else if (table[i].rangeLen > 0) {
	  *x = table[i].val + readBits(table[i].rangeLen);
	} else {
	  *x = table[i].val;
	}
	return gTrue;
      }
    }
    ++i;
  }
  return gFalse;
}

Guint JBIG2HuffmanDecoder::readBits(Guint n) {
  Guint x, mask, nLeft;

  mask = (n == 32) ? 0xffffffff : ((1 << n) - 1);
  if (bufLen >= n) {
    x = (buf >> (bufLen - n)) & mask;
    bufLen -= n;
  } else {
    x = buf & ((1 << bufLen) - 1);
    nLeft = n - bufLen;
    bufLen = 0;
    while (nLeft >= 8) {
      x = (x << 8) | (str->getChar() & 0xff);
      nLeft -= 8;
    }
    if (nLeft > 0) {
      buf = str->getChar();
      bufLen = 8 - nLeft;
      x = (x << nLeft) | ((buf >> bufLen) & ((1 << nLeft) - 1));
    }
  }
  return x;
}

Guint JBIG2HuffmanDecoder::readBit() {
  if (bufLen == 0) {
    buf = str->getChar();
    bufLen = 8;
  }
  --bufLen;
  return (buf >> bufLen) & 1;
}

static int cmpHuffmanTabEntries(const void *p1, const void *p2) {
  return ((JBIG2HuffmanTable *)p1)->prefixLen
         - ((JBIG2HuffmanTable *)p2)->prefixLen;
}

//~ should remove entries with prefixLen = 0
void JBIG2HuffmanDecoder::buildTable(JBIG2HuffmanTable *table, Guint len) {
  Guint i, prefix;

  qsort(table, len, sizeof(JBIG2HuffmanTable), &cmpHuffmanTabEntries);
  for (i = 0; i < len && table[i].prefixLen == 0; ++i) {
    table[i].prefix = 0;
  }
  prefix = 0;
  table[i++].prefix = prefix++;
  for (; i < len; ++i) {
    prefix <<= table[i].prefixLen - table[i-1].prefixLen;
    table[i].prefix = prefix++;
  }
}

//------------------------------------------------------------------------
// JBIG2MMRDecoder
//------------------------------------------------------------------------

class JBIG2MMRDecoder {
public:

  JBIG2MMRDecoder();
  ~JBIG2MMRDecoder();
  void setStream(Stream *strA) { str = strA; }
  void reset();
  int get2DCode();
  int getBlackCode();
  int getWhiteCode();
  Guint get24Bits();
  void skipTo(Guint length);

private:

  Stream *str;
  Guint buf;
  Guint bufLen;
  Guint nBytesRead;
};

JBIG2MMRDecoder::JBIG2MMRDecoder() {
  str = NULL;
  reset();
}

JBIG2MMRDecoder::~JBIG2MMRDecoder() {
}

void JBIG2MMRDecoder::reset() {
  buf = 0;
  bufLen = 0;
  nBytesRead = 0;
}

int JBIG2MMRDecoder::get2DCode() {
  CCITTCode *p;

  if (bufLen == 0) {
    buf = str->getChar() & 0xff;
    bufLen = 8;
    ++nBytesRead;
    p = &twoDimTab1[(buf >> 1) & 0x7f];
  } else if (bufLen == 8) {
    p = &twoDimTab1[(buf >> 1) & 0x7f];
  } else {
    p = &twoDimTab1[(buf << (7 - bufLen)) & 0x7f];
    if (p->bits < 0 || p->bits > (int)bufLen) {
      buf = (buf << 8) | (str->getChar() & 0xff);
      bufLen += 8;
      ++nBytesRead;
      p = &twoDimTab1[(buf >> (bufLen - 7)) & 0x7f];
    }
  }
  if (p->bits < 0) {
    error(str->getPos(), "Bad two dim code in JBIG2 MMR stream");
    return 0;
  }
  bufLen -= p->bits;
  return p->n;
}

int JBIG2MMRDecoder::getWhiteCode() {
  CCITTCode *p;
  Guint code;

  if (bufLen == 0) {
    buf = str->getChar() & 0xff;
    bufLen = 8;
    ++nBytesRead;
  }
  while (1) {
    if (bufLen > 7 && ((buf >> (bufLen - 7)) & 0x7f) == 0) {
      if (bufLen <= 12) {
	code = buf << (12 - bufLen);
      } else {
	code = buf >> (bufLen - 12);
      }
      p = &whiteTab1[code & 0x1f];
    } else {
      if (bufLen <= 9) {
	code = buf << (9 - bufLen);
      } else {
	code = buf >> (bufLen - 9);
      }
      p = &whiteTab2[code & 0x1ff];
    }
    if (p->bits > 0 && p->bits < (int)bufLen) {
      bufLen -= p->bits;
      return p->n;
    }
    if (bufLen >= 12) {
      break;
    }
    buf = (buf << 8) | (str->getChar() & 0xff);
    bufLen += 8;
    ++nBytesRead;
  }
  error(str->getPos(), "Bad white code in JBIG2 MMR stream");
  // eat a bit and return a positive number so that the caller doesn't
  // go into an infinite loop
  --bufLen;
  return 1;
}

int JBIG2MMRDecoder::getBlackCode() {
  CCITTCode *p;
  Guint code;

  if (bufLen == 0) {
    buf = str->getChar() & 0xff;
    bufLen = 8;
    ++nBytesRead;
  }
  while (1) {
    if (bufLen > 6 && ((buf >> (bufLen - 6)) & 0x3f) == 0) {
      if (bufLen <= 13) {
	code = buf << (13 - bufLen);
      } else {
	code = buf >> (bufLen - 13);
      }
      p = &blackTab1[code & 0x7f];
    } else if (bufLen > 4 && ((buf >> (bufLen - 4)) & 0x0f) == 0) {
      if (bufLen <= 12) {
	code = buf << (12 - bufLen);
      } else {
	code = buf >> (bufLen - 12);
      }
      p = &blackTab2[(code & 0xff) - 64];
    } else {
      if (bufLen <= 6) {
	code = buf << (6 - bufLen);
      } else {
	code = buf >> (bufLen - 6);
      }
      p = &blackTab3[code & 0x3f];
    }
    if (p->bits > 0 && p->bits < (int)bufLen) {
      bufLen -= p->bits;
      return p->n;
    }
    if (bufLen >= 13) {
      break;
    }
    buf = (buf << 8) | (str->getChar() & 0xff);
    bufLen += 8;
    ++nBytesRead;
  }
  error(str->getPos(), "Bad black code in JBIG2 MMR stream");
  // eat a bit and return a positive number so that the caller doesn't
  // go into an infinite loop
  --bufLen;
  return 1;
}

Guint JBIG2MMRDecoder::get24Bits() {
  while (bufLen < 24) {
    buf = (buf << 8) | (str->getChar() & 0xff);
    bufLen += 8;
    ++nBytesRead;
  }
  return (buf >> (bufLen - 24)) & 0xffffff;
}

void JBIG2MMRDecoder::skipTo(Guint length) {
  while (nBytesRead < length) {
    str->getChar();
    ++nBytesRead;
  }
}

//------------------------------------------------------------------------
// JBIG2Segment
//------------------------------------------------------------------------

enum JBIG2SegmentType {
  jbig2SegBitmap,
  jbig2SegSymbolDict,
  jbig2SegPatternDict,
  jbig2SegCodeTable
};

class JBIG2Segment {
public:

  JBIG2Segment(Guint segNumA) { segNum = segNumA; }
  virtual ~JBIG2Segment() {}
  void setSegNum(Guint segNumA) { segNum = segNumA; }
  Guint getSegNum() { return segNum; }
  virtual JBIG2SegmentType getType() = 0;

private:

  Guint segNum;
};

//------------------------------------------------------------------------
// JBIG2Bitmap
//------------------------------------------------------------------------

class JBIG2Bitmap: public JBIG2Segment {
public:

  JBIG2Bitmap(Guint segNumA, int wA, int hA);
  virtual ~JBIG2Bitmap();
  virtual JBIG2SegmentType getType() { return jbig2SegBitmap; }
  JBIG2Bitmap *copy() { return new JBIG2Bitmap(0, this); }
  JBIG2Bitmap *getSlice(Guint x, Guint y, Guint wA, Guint hA);
  void expand(int newH, Guint pixel);
  void clearToZero();
  void clearToOne();
  int getWidth() { return w; }
  int getHeight() { return h; }
  int getPixel(int x, int y)
    { return (x < 0 || x >= w || y < 0 || y >= h) ? 0 :
             (data[y * line + (x >> 3)] >> (7 - (x & 7))) & 1; }
  void setPixel(int x, int y)
    { data[y * line + (x >> 3)] |= 1 << (7 - (x & 7)); }
  void clearPixel(int x, int y)
    { data[y * line + (x >> 3)] &= 0x7f7f >> (x & 7); }
  void duplicateRow(int yDest, int ySrc);
  void combine(JBIG2Bitmap *bitmap, int x, int y, Guint combOp);
  Guchar *getDataPtr() { return data; }
  int getDataSize() { return h * line; }

private:

  JBIG2Bitmap(Guint segNumA, JBIG2Bitmap *bitmap);

  int w, h, line;
  Guchar *data;
};

JBIG2Bitmap::JBIG2Bitmap(Guint segNumA, int wA, int hA):
  JBIG2Segment(segNumA)
{
  w = wA;
  h = hA;
  line = (wA + 7) >> 3;
  data = (Guchar *)gmalloc(h * line);
}

JBIG2Bitmap::JBIG2Bitmap(Guint segNumA, JBIG2Bitmap *bitmap):
  JBIG2Segment(segNumA)
{
  w = bitmap->w;
  h = bitmap->h;
  line = bitmap->line;
  data = (Guchar *)gmalloc(h * line);
  memcpy(data, bitmap->data, h * line);
}

JBIG2Bitmap::~JBIG2Bitmap() {
  gfree(data);
}

//~ optimize this
JBIG2Bitmap *JBIG2Bitmap::getSlice(Guint x, Guint y, Guint wA, Guint hA) {
  JBIG2Bitmap *slice;
  Guint xx, yy;

  slice = new JBIG2Bitmap(0, wA, hA);
  slice->clearToZero();
  for (yy = 0; yy < hA; ++yy) {
    for (xx = 0; xx < wA; ++xx) {
      if (getPixel(x + xx, y + yy)) {
	slice->setPixel(xx, yy);
      }
    }
  }
  return slice;
}

void JBIG2Bitmap::expand(int newH, Guint pixel) {
  if (newH <= h) {
    return;
  }
  data = (Guchar *)grealloc(data, newH * line);
  if (pixel) {
    memset(data + h * line, 0xff, (newH - h) * line);
  } else {
    memset(data + h * line, 0x00, (newH - h) * line);
  }
  h = newH;
}

void JBIG2Bitmap::clearToZero() {
  memset(data, 0, h * line);
}

void JBIG2Bitmap::clearToOne() {
  memset(data, 0xff, h * line);
}

void JBIG2Bitmap::duplicateRow(int yDest, int ySrc) {
  memcpy(data + yDest * line, data + ySrc * line, line);
}

void JBIG2Bitmap::combine(JBIG2Bitmap *bitmap, int x, int y,
			  Guint combOp) {
  int x0, x1, y0, y1, xx, yy;
  Guchar *srcPtr, *destPtr;
  Guint src0, src1, src, dest, s1, s2, m1, m2, m3;
  GBool oneByte;

  if (y < 0) {
    y0 = -y;
  } else {
    y0 = 0;
  }
  if (y + bitmap->h > h) {
    y1 = h - y;
  } else {
    y1 = bitmap->h;
  }
  if (y0 >= y1) {
    return;
  }

  if (x >= 0) {
    x0 = x & ~7;
  } else {
    x0 = 0;
  }
  x1 = x + bitmap->w;
  if (x1 > w) {
    x1 = w;
  }
  if (x0 >= x1) {
    return;
  }

  s1 = x & 7;
  s2 = 8 - s1;
  m1 = 0xff >> (x1 & 7);
  m2 = 0xff << (((x1 & 7) == 0) ? 0 : 8 - (x1 & 7));
  m3 = (0xff >> s1) & m2;

  oneByte = x0 == ((x1 - 1) & ~7);

  for (yy = y0; yy < y1; ++yy) {

    // one byte per line -- need to mask both left and right side
    if (oneByte) {
      if (x >= 0) {
	destPtr = data + (y + yy) * line + (x >> 3);
	srcPtr = bitmap->data + yy * bitmap->line;
	dest = *destPtr;
	src1 = *srcPtr;
	switch (combOp) {
	case 0: // or
	  dest |= (src1 >> s1) & m2;
	  break;
	case 1: // and
	  dest &= ((0xff00 | src1) >> s1) | m1;
	  break;
	case 2: // xor
	  dest ^= (src1 >> s1) & m2;
	  break;
	case 3: // xnor
	  dest ^= ((src1 ^ 0xff) >> s1) & m2;
	  break;
	case 4: // replace
	  dest = (dest & ~m3) | ((src1 >> s1) & m3);
	  break;
	}
	*destPtr = dest;
      } else {
	destPtr = data + (y + yy) * line;
	srcPtr = bitmap->data + yy * bitmap->line + (-x >> 3);
	dest = *destPtr;
	src1 = *srcPtr;
	switch (combOp) {
	case 0: // or
	  dest |= src1 & m2;
	  break;
	case 1: // and
	  dest &= src1 | m1;
	  break;
	case 2: // xor
	  dest ^= src1 & m2;
	  break;
	case 3: // xnor
	  dest ^= (src1 ^ 0xff) & m2;
	  break;
	case 4: // replace
	  dest = (src1 & m2) | (dest & m1);
	  break;
	}
	*destPtr = dest;
      }

    // multiple bytes per line -- need to mask left side of left-most
    // byte and right side of right-most byte
    } else {

      // left-most byte
      if (x >= 0) {
	destPtr = data + (y + yy) * line + (x >> 3);
	srcPtr = bitmap->data + yy * bitmap->line;
	src1 = *srcPtr++;
	dest = *destPtr;
	switch (combOp) {
	case 0: // or
	  dest |= src1 >> s1;
	  break;
	case 1: // and
	  dest &= (0xff00 | src1) >> s1;
	  break;
	case 2: // xor
	  dest ^= src1 >> s1;
	  break;
	case 3: // xnor
	  dest ^= (src1 ^ 0xff) >> s1;
	  break;
	case 4: // replace
	  dest = (dest & (0xff << s2)) | (src1 >> s1);
	  break;
	}
	*destPtr++ = dest;
	xx = x0 + 8;
      } else {
	destPtr = data + (y + yy) * line;
	srcPtr = bitmap->data + yy * bitmap->line + (-x >> 3);
	src1 = *srcPtr++;
	xx = x0;
      }

      // middle bytes
      for (; xx < x1 - 8; xx += 8) {
	dest = *destPtr;
	src0 = src1;
	src1 = *srcPtr++;
	src = (((src0 << 8) | src1) >> s1) & 0xff;
	switch (combOp) {
	case 0: // or
	  dest |= src;
	  break;
	case 1: // and
	  dest &= src;
	  break;
	case 2: // xor
	  dest ^= src;
	  break;
	case 3: // xnor
	  dest ^= src ^ 0xff;
	  break;
	case 4: // replace
	  dest = src;
	  break;
	}
	*destPtr++ = dest;
      }

      // right-most byte
      dest = *destPtr;
      src0 = src1;
      src1 = *srcPtr++;
      src = (((src0 << 8) | src1) >> s1) & 0xff;
      switch (combOp) {
      case 0: // or
	dest |= src & m2;
	break;
      case 1: // and
	dest &= src | m1;
	break;
      case 2: // xor
	dest ^= src & m2;
	break;
      case 3: // xnor
	dest ^= (src ^ 0xff) & m2;
	break;
      case 4: // replace
	dest = (src & m2) | (dest & m1);
	break;
      }
      *destPtr = dest;
    }
  }
}

//------------------------------------------------------------------------
// JBIG2SymbolDict
//------------------------------------------------------------------------

class JBIG2SymbolDict: public JBIG2Segment {
public:

  JBIG2SymbolDict(Guint segNumA, Guint sizeA);
  virtual ~JBIG2SymbolDict();
  virtual JBIG2SegmentType getType() { return jbig2SegSymbolDict; }
  Guint getSize() { return size; }
  void setBitmap(Guint idx, JBIG2Bitmap *bitmap) { bitmaps[idx] = bitmap; }
  JBIG2Bitmap *getBitmap(Guint idx) { return bitmaps[idx]; }
  void setGenericRegionStats(JBIG2ArithmeticDecoderStats *stats)
    { genericRegionStats = stats; }
  void setRefinementRegionStats(JBIG2ArithmeticDecoderStats *stats)
    { refinementRegionStats = stats; }
  JBIG2ArithmeticDecoderStats *getGenericRegionStats()
    { return genericRegionStats; }
  JBIG2ArithmeticDecoderStats *getRefinementRegionStats()
    { return refinementRegionStats; }

private:

  Guint size;
  JBIG2Bitmap **bitmaps;
  JBIG2ArithmeticDecoderStats *genericRegionStats;
  JBIG2ArithmeticDecoderStats *refinementRegionStats;
};

JBIG2SymbolDict::JBIG2SymbolDict(Guint segNumA, Guint sizeA):
  JBIG2Segment(segNumA)
{
  size = sizeA;
  bitmaps = (JBIG2Bitmap **)gmalloc(size * sizeof(JBIG2Bitmap *));
  genericRegionStats = NULL;
  refinementRegionStats = NULL;
}

JBIG2SymbolDict::~JBIG2SymbolDict() {
  Guint i;

  for (i = 0; i < size; ++i) {
    delete bitmaps[i];
  }
  gfree(bitmaps);
  if (genericRegionStats) {
    delete genericRegionStats;
  }
  if (refinementRegionStats) {
    delete refinementRegionStats;
  }
}

//------------------------------------------------------------------------
// JBIG2PatternDict
//------------------------------------------------------------------------

class JBIG2PatternDict: public JBIG2Segment {
public:

  JBIG2PatternDict(Guint segNumA, Guint sizeA);
  virtual ~JBIG2PatternDict();
  virtual JBIG2SegmentType getType() { return jbig2SegPatternDict; }
  Guint getSize() { return size; }
  void setBitmap(Guint idx, JBIG2Bitmap *bitmap) { bitmaps[idx] = bitmap; }
  JBIG2Bitmap *getBitmap(Guint idx) { return bitmaps[idx]; }

private:

  Guint size;
  JBIG2Bitmap **bitmaps;
};

JBIG2PatternDict::JBIG2PatternDict(Guint segNumA, Guint sizeA):
  JBIG2Segment(segNumA)
{
  size = sizeA;
  bitmaps = (JBIG2Bitmap **)gmalloc(size * sizeof(JBIG2Bitmap *));
}

JBIG2PatternDict::~JBIG2PatternDict() {
  Guint i;

  for (i = 0; i < size; ++i) {
    delete bitmaps[i];
  }
  gfree(bitmaps);
}

//------------------------------------------------------------------------
// JBIG2CodeTable
//------------------------------------------------------------------------

class JBIG2CodeTable: public JBIG2Segment {
public:

  JBIG2CodeTable(Guint segNumA, JBIG2HuffmanTable *tableA);
  virtual ~JBIG2CodeTable();
  virtual JBIG2SegmentType getType() { return jbig2SegCodeTable; }
  JBIG2HuffmanTable *getHuffTable() { return table; }

private:

  JBIG2HuffmanTable *table;
};

JBIG2CodeTable::JBIG2CodeTable(Guint segNumA, JBIG2HuffmanTable *tableA):
  JBIG2Segment(segNumA)
{
  table = tableA;
}

JBIG2CodeTable::~JBIG2CodeTable() {
  gfree(table);
}

//------------------------------------------------------------------------
// JBIG2Stream
//------------------------------------------------------------------------

JBIG2Stream::JBIG2Stream(Stream *strA, Object *globalsStream):
  FilterStream(strA)
{
  pageBitmap = NULL;

  arithDecoder = new JBIG2ArithmeticDecoder();
  genericRegionStats = new JBIG2ArithmeticDecoderStats(1);
  refinementRegionStats = new JBIG2ArithmeticDecoderStats(1);
  iadhStats = new JBIG2ArithmeticDecoderStats(9);
  iadwStats = new JBIG2ArithmeticDecoderStats(9);
  iaexStats = new JBIG2ArithmeticDecoderStats(9);
  iaaiStats = new JBIG2ArithmeticDecoderStats(9);
  iadtStats = new JBIG2ArithmeticDecoderStats(9);
  iaitStats = new JBIG2ArithmeticDecoderStats(9);
  iafsStats = new JBIG2ArithmeticDecoderStats(9);
  iadsStats = new JBIG2ArithmeticDecoderStats(9);
  iardxStats = new JBIG2ArithmeticDecoderStats(9);
  iardyStats = new JBIG2ArithmeticDecoderStats(9);
  iardwStats = new JBIG2ArithmeticDecoderStats(9);
  iardhStats = new JBIG2ArithmeticDecoderStats(9);
  iariStats = new JBIG2ArithmeticDecoderStats(9);
  iaidStats = new JBIG2ArithmeticDecoderStats(1);
  huffDecoder = new JBIG2HuffmanDecoder();
  mmrDecoder = new JBIG2MMRDecoder();

  segments = new GList();
  if (globalsStream->isStream()) {
    curStr = globalsStream->getStream();
    curStr->reset();
    arithDecoder->setStream(curStr);
    huffDecoder->setStream(curStr);
    mmrDecoder->setStream(curStr);
    readSegments();
  }
  globalSegments = segments;

  segments = NULL;
  curStr = NULL;
  dataPtr = dataEnd = NULL;
}

JBIG2Stream::~JBIG2Stream() {
  delete arithDecoder;
  delete genericRegionStats;
  delete refinementRegionStats;
  delete iadhStats;
  delete iadwStats;
  delete iaexStats;
  delete iaaiStats;
  delete iadtStats;
  delete iaitStats;
  delete iafsStats;
  delete iadsStats;
  delete iardxStats;
  delete iardyStats;
  delete iardwStats;
  delete iardhStats;
  delete iariStats;
  delete iaidStats;
  delete huffDecoder;
  delete mmrDecoder;
  if (pageBitmap) {
    delete pageBitmap;
  }
  if (segments) {
    deleteGList(segments, JBIG2Segment);
  }
  if (globalSegments) {
    deleteGList(globalSegments, JBIG2Segment);
  }
  delete str;
}

void JBIG2Stream::reset() {
  if (pageBitmap) {
    delete pageBitmap;
    pageBitmap = NULL;
  }
  if (segments) {
    deleteGList(segments, JBIG2Segment);
  }
  segments = new GList();

  curStr = str;
  curStr->reset();
  arithDecoder->setStream(curStr);
  huffDecoder->setStream(curStr);
  mmrDecoder->setStream(curStr);
  readSegments();

  if (pageBitmap) {
    dataPtr = pageBitmap->getDataPtr();
    dataEnd = dataPtr + pageBitmap->getDataSize();
  } else {
    dataPtr = NULL;
  }
}

int JBIG2Stream::getChar() {
  if (dataPtr && dataPtr < dataEnd) {
    return (*dataPtr++ ^ 0xff) & 0xff;
  }
  return EOF;
}

int JBIG2Stream::lookChar() {
  if (dataPtr && dataPtr < dataEnd) {
    return (*dataPtr ^ 0xff) & 0xff;
  }
  return EOF;
}

GString *JBIG2Stream::getPSFilter(char *indent) {
  return NULL;
}

GBool JBIG2Stream::isBinary(GBool last) {
  return str->isBinary(gTrue);
}

void JBIG2Stream::readSegments() {
  Guint segNum, segFlags, segType, page, segLength;
  Guint refFlags, nRefSegs;
  Guint *refSegs;
  int c1, c2, c3;
  Guint i;

  while (readULong(&segNum)) {

    // segment header flags
    if (!readUByte(&segFlags)) {
      goto eofError1;
    }
    segType = segFlags & 0x3f;

    // referred-to segment count and retention flags
    if (!readUByte(&refFlags)) {
      goto eofError1;
    }
    nRefSegs = refFlags >> 5;
    if (nRefSegs == 7) {
      if ((c1 = curStr->getChar()) == EOF ||
	  (c2 = curStr->getChar()) == EOF ||
	  (c3 = curStr->getChar()) == EOF) {
	goto eofError1;
      }
      refFlags = (refFlags << 24) | (c1 << 16) | (c2 << 8) | c3;
      nRefSegs = refFlags & 0x1fffffff;
      for (i = 0; i < (nRefSegs + 9) >> 3; ++i) {
	c1 = curStr->getChar();
      }
    }

    // referred-to segment numbers
    refSegs = (Guint *)gmalloc(nRefSegs * sizeof(Guint));
    if (segNum <= 256) {
      for (i = 0; i < nRefSegs; ++i) {
	if (!readUByte(&refSegs[i])) {
	  goto eofError2;
	}
      }
    } else if (segNum <= 65536) {
      for (i = 0; i < nRefSegs; ++i) {
	if (!readUWord(&refSegs[i])) {
	  goto eofError2;
	}
      }
    } else {
      for (i = 0; i < nRefSegs; ++i) {
	if (!readULong(&refSegs[i])) {
	  goto eofError2;
	}
      }
    }

    // segment page association
    if (segFlags & 0x40) {
      if (!readULong(&page)) {
	goto eofError2;
      }
    } else {
      if (!readUByte(&page)) {
	goto eofError2;
      }
    }

    // segment data length
    if (!readULong(&segLength)) {
      goto eofError2;
    }

    // read the segment data
    switch (segType) {
    case 0:
      readSymbolDictSeg(segNum, segLength, refSegs, nRefSegs);
      break;
    case 4:
      readTextRegionSeg(segNum, gFalse, gFalse, segLength, refSegs, nRefSegs);
      break;
    case 6:
      readTextRegionSeg(segNum, gTrue, gFalse, segLength, refSegs, nRefSegs);
      break;
    case 7:
      readTextRegionSeg(segNum, gTrue, gTrue, segLength, refSegs, nRefSegs);
      break;
    case 16:
      readPatternDictSeg(segNum, segLength);
      break;
    case 20:
      readHalftoneRegionSeg(segNum, gFalse, gFalse, segLength,
			    refSegs, nRefSegs);
      break;
    case 22:
      readHalftoneRegionSeg(segNum, gTrue, gFalse, segLength,
			    refSegs, nRefSegs);
      break;
    case 23:
      readHalftoneRegionSeg(segNum, gTrue, gTrue, segLength,
			    refSegs, nRefSegs);
      break;
    case 36:
      readGenericRegionSeg(segNum, gFalse, gFalse, segLength);
      break;
    case 38:
      readGenericRegionSeg(segNum, gTrue, gFalse, segLength);
      break;
    case 39:
      readGenericRegionSeg(segNum, gTrue, gTrue, segLength);
      break;
    case 40:
      readGenericRefinementRegionSeg(segNum, gFalse, gFalse, segLength,
				     refSegs, nRefSegs);
      break;
    case 42:
      readGenericRefinementRegionSeg(segNum, gTrue, gFalse, segLength,
				     refSegs, nRefSegs);
      break;
    case 43:
      readGenericRefinementRegionSeg(segNum, gTrue, gTrue, segLength,
				     refSegs, nRefSegs);
      break;
    case 48:
      readPageInfoSeg(segLength);
      break;
    case 50:
      readEndOfStripeSeg(segLength);
      break;
    case 52:
      readProfilesSeg(segLength);
      break;
    case 53:
      readCodeTableSeg(segNum, segLength);
      break;
    case 62:
      readExtensionSeg(segLength);
      break;
    default:
      error(getPos(), "Unknown segment type in JBIG2 stream");
      for (i = 0; i < segLength; ++i) {
	if ((c1 = curStr->getChar()) == EOF) {
	  goto eofError2;
	}
      }
      break;
    }

    gfree(refSegs);
  }

  return;

 eofError2:
  gfree(refSegs);
 eofError1:
  error(getPos(), "Unexpected EOF in JBIG2 stream");
}

void JBIG2Stream::readSymbolDictSeg(Guint segNum, Guint length,
				    Guint *refSegs, Guint nRefSegs) {
  JBIG2SymbolDict *symbolDict;
  JBIG2HuffmanTable *huffDHTable, *huffDWTable;
  JBIG2HuffmanTable *huffBMSizeTable, *huffAggInstTable;
  JBIG2Segment *seg;
  GList *codeTables;
  JBIG2SymbolDict *inputSymbolDict;
  Guint flags, sdTemplate, sdrTemplate, huff, refAgg;
  Guint huffDH, huffDW, huffBMSize, huffAggInst;
  Guint contextUsed, contextRetained;
  int sdATX[4], sdATY[4], sdrATX[2], sdrATY[2];
  Guint numExSyms, numNewSyms, numInputSyms, symCodeLen;
  JBIG2Bitmap **bitmaps;
  JBIG2Bitmap *collBitmap, *refBitmap;
  Guint *symWidths;
  Guint symHeight, symWidth, totalWidth, x, symID;
  int dh, dw, refAggNum, refDX, refDY, bmSize;
  GBool ex;
  int run, cnt;
  Guint i, j, k;
  Guchar *p;

  // symbol dictionary flags
  if (!readUWord(&flags)) {
    goto eofError;
  }
  sdTemplate = (flags >> 10) & 3;
  sdrTemplate = (flags >> 12) & 1;
  huff = flags & 1;
  refAgg = (flags >> 1) & 1;
  huffDH = (flags >> 2) & 3;
  huffDW = (flags >> 4) & 3;
  huffBMSize = (flags >> 6) & 1;
  huffAggInst = (flags >> 7) & 1;
  contextUsed = (flags >> 8) & 1;
  contextRetained = (flags >> 9) & 1;

  // symbol dictionary AT flags
  if (!huff) {
    if (sdTemplate == 0) {
      if (!readByte(&sdATX[0]) ||
	  !readByte(&sdATY[0]) ||
	  !readByte(&sdATX[1]) ||
	  !readByte(&sdATY[1]) ||
	  !readByte(&sdATX[2]) ||
	  !readByte(&sdATY[2]) ||
	  !readByte(&sdATX[3]) ||
	  !readByte(&sdATY[3])) {
	goto eofError;
      }
    } else {
      if (!readByte(&sdATX[0]) ||
	  !readByte(&sdATY[0])) {
	goto eofError;
      }
    }
  }

  // symbol dictionary refinement AT flags
  if (refAgg && !sdrTemplate) {
    if (!readByte(&sdrATX[0]) ||
	!readByte(&sdrATY[0]) ||
	!readByte(&sdrATX[1]) ||
	!readByte(&sdrATY[1])) {
      goto eofError;
    }
  }

  // SDNUMEXSYMS and SDNUMNEWSYMS
  if (!readULong(&numExSyms) || !readULong(&numNewSyms)) {
    goto eofError;
  }

  // get referenced segments: input symbol dictionaries and code tables
  codeTables = new GList();
  numInputSyms = 0;
  for (i = 0; i < nRefSegs; ++i) {
    seg = findSegment(refSegs[i]);
    if (seg->getType() == jbig2SegSymbolDict) {
      numInputSyms += ((JBIG2SymbolDict *)seg)->getSize();
    } else if (seg->getType() == jbig2SegCodeTable) {
      codeTables->append(seg);
    }
  }

  // compute symbol code length
  symCodeLen = 0;
  i = 1;
  while (i < numInputSyms + numNewSyms) {
    ++symCodeLen;
    i <<= 1;
  }

  // get the input symbol bitmaps
  bitmaps = (JBIG2Bitmap **)gmalloc((numInputSyms + numNewSyms) *
				    sizeof(JBIG2Bitmap *));
  k = 0;
  inputSymbolDict = NULL;
  for (i = 0; i < nRefSegs; ++i) {
    seg = findSegment(refSegs[i]);
    if (seg->getType() == jbig2SegSymbolDict) {
      inputSymbolDict = (JBIG2SymbolDict *)seg;
      for (j = 0; j < inputSymbolDict->getSize(); ++j) {
	bitmaps[k++] = inputSymbolDict->getBitmap(j);
      }
    }
  }

  // get the Huffman tables
  huffDHTable = huffDWTable = NULL; // make gcc happy
  huffBMSizeTable = huffAggInstTable = NULL; // make gcc happy
  i = 0;
  if (huff) {
    if (huffDH == 0) {
      huffDHTable = huffTableD;
    } else if (huffDH == 1) {
      huffDHTable = huffTableE;
    } else {
      huffDHTable = ((JBIG2CodeTable *)codeTables->get(i++))->getHuffTable();
    }
    if (huffDW == 0) {
      huffDWTable = huffTableB;
    } else if (huffDW == 1) {
      huffDWTable = huffTableC;
    } else {
      huffDWTable = ((JBIG2CodeTable *)codeTables->get(i++))->getHuffTable();
    }
    if (huffBMSize == 0) {
      huffBMSizeTable = huffTableA;
    } else {
      huffBMSizeTable =
	  ((JBIG2CodeTable *)codeTables->get(i++))->getHuffTable();
    }
    if (huffAggInst == 0) {
      huffAggInstTable = huffTableA;
    } else {
      huffAggInstTable =
	  ((JBIG2CodeTable *)codeTables->get(i++))->getHuffTable();
    }
  }
  delete codeTables;

  // set up the Huffman decoder
  if (huff) {
    huffDecoder->reset();

  // set up the arithmetic decoder
  } else {
    if (contextUsed && inputSymbolDict) {
      resetGenericStats(sdTemplate, inputSymbolDict->getGenericRegionStats());
      if (refAgg) {
	resetRefinementStats(sdrTemplate,
			     inputSymbolDict->getRefinementRegionStats());
      }
    } else {
      resetGenericStats(sdTemplate, NULL);
      if (refAgg) {
	resetRefinementStats(sdrTemplate, NULL);
      }
    }
    resetIntStats(symCodeLen);
    arithDecoder->start();
  }

  // allocate symbol widths storage
  symWidths = NULL;
  if (huff && !refAgg) {
    symWidths = (Guint *)gmalloc(numNewSyms * sizeof(Guint));
  }

  symHeight = 0;
  i = 0;
  while (i < numNewSyms) {

    // read the height class delta height
    if (huff) {
      huffDecoder->decodeInt(&dh, huffDHTable);
    } else {
      arithDecoder->decodeInt(&dh, iadhStats);
    }
    symHeight += dh;
    symWidth = 0;
    totalWidth = 0;
    j = i;

    // read the symbols in this height class
    while (1) {

      // read the delta width
      if (huff) {
	if (!huffDecoder->decodeInt(&dw, huffDWTable)) {
	  break;
	}
      } else {
	if (!arithDecoder->decodeInt(&dw, iadwStats)) {
	  break;
	}
      }
      symWidth += dw;

      // using a collective bitmap, so don't read a bitmap here
      if (huff && !refAgg) {
	symWidths[i] = symWidth;
	totalWidth += symWidth;

      // refinement/aggregate coding
      } else if (refAgg) {
	if (huff) {
	  if (!huffDecoder->decodeInt(&refAggNum, huffAggInstTable)) {
	    break;
	  }
	} else {
	  if (!arithDecoder->decodeInt(&refAggNum, iaaiStats)) {
	    break;
	  }
	}
	if (refAggNum == 1) {
	  if (huff) {
	    symID = huffDecoder->readBits(symCodeLen);
	    huffDecoder->decodeInt(&refDX, huffTableO);
	    huffDecoder->decodeInt(&refDY, huffTableO);
	    huffDecoder->decodeInt(&bmSize, huffTableA);
	    huffDecoder->reset();
	    arithDecoder->start();
	  } else {
	    symID = arithDecoder->decodeIAID(symCodeLen, iaidStats);
	    arithDecoder->decodeInt(&refDX, iardxStats);
	    arithDecoder->decodeInt(&refDY, iardyStats);
	  }
	  refBitmap = bitmaps[symID];
	  bitmaps[numInputSyms + i] =
	      readGenericRefinementRegion(symWidth, symHeight,
					  sdrTemplate, gFalse,
					  refBitmap, refDX, refDY,
					  sdrATX, sdrATY);
	  //~ do we need to use the bmSize value here (in Huffman mode)?
	} else {
	  bitmaps[numInputSyms + i] =
	      readTextRegion(huff, gTrue, symWidth, symHeight,
			     refAggNum, 0, numInputSyms + i, NULL,
			     symCodeLen, bitmaps, 0, 0, 0, 1, 0,
			     huffTableF, huffTableH, huffTableK, huffTableO,
			     huffTableO, huffTableO, huffTableO, huffTableA,
			     sdrTemplate, sdrATX, sdrATY);
	}

      // non-ref/agg coding
      } else {
	bitmaps[numInputSyms + i] =
	    readGenericBitmap(gFalse, symWidth, symHeight,
			      sdTemplate, gFalse, gFalse, NULL,
			      sdATX, sdATY, 0);
      }

      ++i;
    }

    // read the collective bitmap
    if (huff && !refAgg) {
      huffDecoder->decodeInt(&bmSize, huffBMSizeTable);
      if (huff) {
	huffDecoder->reset();
      }
      if (bmSize == 0) {
	collBitmap = new JBIG2Bitmap(0, totalWidth, symHeight);
	bmSize = symHeight * ((totalWidth + 7) >> 3);
	p = collBitmap->getDataPtr();
	for (k = 0; k < (Guint)bmSize; ++k) {
	  *p++ = str->getChar();
	}
      } else {
	collBitmap = readGenericBitmap(gTrue, totalWidth, symHeight,
				       0, gFalse, gFalse, NULL, NULL, NULL,
				       bmSize);
      }
      x = 0;
      for (; j < i; ++j) {
	bitmaps[numInputSyms + j] =
	    collBitmap->getSlice(x, 0, symWidths[j], symHeight);
	x += symWidths[j];
      }
      delete collBitmap;
    }
  }

  // create the symbol dict object
  symbolDict = new JBIG2SymbolDict(segNum, numExSyms);

  // exported symbol list
  i = j = 0;
  ex = gFalse;
  while (i < numInputSyms + numNewSyms) {
    if (huff) {
      huffDecoder->decodeInt(&run, huffTableA);
    } else {
      arithDecoder->decodeInt(&run, iaexStats);
    }
    if (ex) {
      for (cnt = 0; cnt < run; ++cnt) {
	symbolDict->setBitmap(j++, bitmaps[i++]->copy());
      }
    } else {
      i += run;
    }
    ex = !ex;
  }
  
  for (i = 0; i < numNewSyms; ++i) {
    delete bitmaps[numInputSyms + i];
  }
  gfree(bitmaps);
  if (symWidths) {
    gfree(symWidths);
  }

  // save the arithmetic decoder stats
  if (!huff && contextRetained) {
    symbolDict->setGenericRegionStats(genericRegionStats->copy());
    if (refAgg) {
      symbolDict->setRefinementRegionStats(refinementRegionStats->copy());
    }
  }

  // store the new symbol dict
  segments->append(symbolDict);

  return;

 eofError:
  error(getPos(), "Unexpected EOF in JBIG2 stream");
}

void JBIG2Stream::readTextRegionSeg(Guint segNum, GBool imm,
				    GBool lossless, Guint length,
				    Guint *refSegs, Guint nRefSegs) {
  JBIG2Bitmap *bitmap;
  JBIG2HuffmanTable runLengthTab[36];
  JBIG2HuffmanTable *symCodeTab;
  JBIG2HuffmanTable *huffFSTable, *huffDSTable, *huffDTTable;
  JBIG2HuffmanTable *huffRDWTable, *huffRDHTable;
  JBIG2HuffmanTable *huffRDXTable, *huffRDYTable, *huffRSizeTable;
  JBIG2Segment *seg;
  GList *codeTables;
  JBIG2SymbolDict *symbolDict;
  JBIG2Bitmap **syms;
  Guint w, h, x, y, segInfoFlags, extCombOp;
  Guint flags, huff, refine, logStrips, refCorner, transposed;
  Guint combOp, defPixel, sOffset, templ;
  Guint huffFlags, huffFS, huffDS, huffDT;
  Guint huffRDW, huffRDH, huffRDX, huffRDY, huffRSize;
  Guint numInstances, numSyms, symCodeLen;
  int atx[2], aty[2];
  Guint i, k, kk;
  int j;

  // region segment info field
  if (!readULong(&w) || !readULong(&h) ||
      !readULong(&x) || !readULong(&y) ||
      !readUByte(&segInfoFlags)) {
    goto eofError;
  }
  extCombOp = segInfoFlags & 7;

  // rest of the text region header
  if (!readUWord(&flags)) {
    goto eofError;
  }
  huff = flags & 1;
  refine = (flags >> 1) & 1;
  logStrips = (flags >> 2) & 3;
  refCorner = (flags >> 4) & 3;
  transposed = (flags >> 6) & 1;
  combOp = (flags >> 7) & 3;
  defPixel = (flags >> 9) & 1;
  sOffset = (flags >> 10) & 0x1f;
  templ = (flags >> 15) & 1;
  huffFS = huffDS = huffDT = 0; // make gcc happy
  huffRDW = huffRDH = huffRDX = huffRDY = huffRSize = 0; // make gcc happy
  if (huff) {
    if (!readUWord(&huffFlags)) {
      goto eofError;
    }
    huffFS = huffFlags & 3;
    huffDS = (huffFlags >> 2) & 3;
    huffDT = (huffFlags >> 4) & 3;
    huffRDW = (huffFlags >> 6) & 3;
    huffRDH = (huffFlags >> 8) & 3;
    huffRDX = (huffFlags >> 10) & 3;
    huffRDY = (huffFlags >> 12) & 3;
    huffRSize = (huffFlags >> 14) & 1;
  }
  if (refine && templ == 0) {
    if (!readByte(&atx[0]) || !readByte(&aty[0]) ||
	!readByte(&atx[1]) || !readByte(&aty[1])) {
      goto eofError;
    }
  }
  if (!readULong(&numInstances)) {
    goto eofError;
  }

  // get symbol dictionaries and tables
  codeTables = new GList();
  numSyms = 0;
  for (i = 0; i < nRefSegs; ++i) {
    seg = findSegment(refSegs[i]);
    if (seg->getType() == jbig2SegSymbolDict) {
      numSyms += ((JBIG2SymbolDict *)seg)->getSize();
    } else if (seg->getType() == jbig2SegCodeTable) {
      codeTables->append(seg);
    }
  }
  symCodeLen = 0;
  i = 1;
  while (i < numSyms) {
    ++symCodeLen;
    i <<= 1;
  }

  // get the symbol bitmaps
  syms = (JBIG2Bitmap **)gmalloc(numSyms * sizeof(JBIG2Bitmap *));
  kk = 0;
  for (i = 0; i < nRefSegs; ++i) {
    seg = findSegment(refSegs[i]);
    if (seg->getType() == jbig2SegSymbolDict) {
      symbolDict = (JBIG2SymbolDict *)seg;
      for (k = 0; k < symbolDict->getSize(); ++k) {
	syms[kk++] = symbolDict->getBitmap(k);
      }
    }
  }

  // get the Huffman tables
  huffFSTable = huffDSTable = huffDTTable = NULL; // make gcc happy
  huffRDWTable = huffRDHTable = NULL; // make gcc happy
  huffRDXTable = huffRDYTable = huffRSizeTable = NULL; // make gcc happy
  i = 0;
  if (huff) {
    if (huffFS == 0) {
      huffFSTable = huffTableF;
    } else if (huffFS == 1) {
      huffFSTable = huffTableG;
    } else {
      huffFSTable = ((JBIG2CodeTable *)codeTables->get(i++))->getHuffTable();
    }
    if (huffDS == 0) {
      huffDSTable = huffTableH;
    } else if (huffDS == 1) {
      huffDSTable = huffTableI;
    } else if (huffDS == 2) {
      huffDSTable = huffTableJ;
    } else {
      huffDSTable = ((JBIG2CodeTable *)codeTables->get(i++))->getHuffTable();
    }
    if (huffDT == 0) {
      huffDTTable = huffTableK;
    } else if (huffDT == 1) {
      huffDTTable = huffTableL;
    } else if (huffDT == 2) {
      huffDTTable = huffTableM;
    } else {
      huffDTTable = ((JBIG2CodeTable *)codeTables->get(i++))->getHuffTable();
    }
    if (huffRDW == 0) {
      huffRDWTable = huffTableN;
    } else if (huffRDW == 1) {
      huffRDWTable = huffTableO;
    } else {
      huffRDWTable = ((JBIG2CodeTable *)codeTables->get(i++))->getHuffTable();
    }
    if (huffRDH == 0) {
      huffRDHTable = huffTableN;
    } else if (huffRDH == 1) {
      huffRDHTable = huffTableO;
    } else {
      huffRDHTable = ((JBIG2CodeTable *)codeTables->get(i++))->getHuffTable();
    }
    if (huffRDX == 0) {
      huffRDXTable = huffTableN;
    } else if (huffRDX == 1) {
      huffRDXTable = huffTableO;
    } else {
      huffRDXTable = ((JBIG2CodeTable *)codeTables->get(i++))->getHuffTable();
    }
    if (huffRDY == 0) {
      huffRDYTable = huffTableN;
    } else if (huffRDY == 1) {
      huffRDYTable = huffTableO;
    } else {
      huffRDYTable = ((JBIG2CodeTable *)codeTables->get(i++))->getHuffTable();
    }
    if (huffRSize == 0) {
      huffRSizeTable = huffTableA;
    } else {
      huffRSizeTable =
	  ((JBIG2CodeTable *)codeTables->get(i++))->getHuffTable();
    }
  }
  delete codeTables;

  // symbol ID Huffman decoding table
  if (huff) {
    huffDecoder->reset();
    for (i = 0; i < 32; ++i) {
      runLengthTab[i].val = i;
      runLengthTab[i].prefixLen = huffDecoder->readBits(4);
      runLengthTab[i].rangeLen = 0;
    }
    runLengthTab[32].val = 0x103;
    runLengthTab[32].prefixLen = huffDecoder->readBits(4);
    runLengthTab[32].rangeLen = 2;
    runLengthTab[33].val = 0x203;
    runLengthTab[33].prefixLen = huffDecoder->readBits(4);
    runLengthTab[33].rangeLen = 3;
    runLengthTab[34].val = 0x20b;
    runLengthTab[34].prefixLen = huffDecoder->readBits(4);
    runLengthTab[34].rangeLen = 7;
    runLengthTab[35].rangeLen = jbig2HuffmanEOT;
    huffDecoder->buildTable(runLengthTab, 35);
    symCodeTab = (JBIG2HuffmanTable *)gmalloc((numSyms + 1) *
					      sizeof(JBIG2HuffmanTable));
    for (i = 0; i < numSyms; ++i) {
      symCodeTab[i].val = i;
      symCodeTab[i].rangeLen = 0;
    }
    i = 0;
    while (i < numSyms) {
      huffDecoder->decodeInt(&j, runLengthTab);
      if (j > 0x200) {
	for (j -= 0x200; j && i < numSyms; --j) {
	  symCodeTab[i++].prefixLen = 0;
	}
      } else if (j > 0x100) {
	for (j -= 0x100; j && i < numSyms; --j) {
	  symCodeTab[i].prefixLen = symCodeTab[i-1].prefixLen;
	  ++i;
	}
      } else {
	symCodeTab[i++].prefixLen = j;
      }

    }
    symCodeTab[numSyms].rangeLen = jbig2HuffmanEOT;
    huffDecoder->buildTable(symCodeTab, numSyms);
    huffDecoder->reset();

  // set up the arithmetic decoder
  } else {
    symCodeTab = NULL;
    resetIntStats(symCodeLen);
    if (refine) {
      resetRefinementStats(templ, NULL);
    }
    arithDecoder->start();
  }

  bitmap = readTextRegion(huff, refine, w, h, numInstances,
			  logStrips, numSyms, symCodeTab, symCodeLen, syms,
			  defPixel, combOp, transposed, refCorner, sOffset,
			  huffFSTable, huffDSTable, huffDTTable,
			  huffRDWTable, huffRDHTable,
			  huffRDXTable, huffRDYTable, huffRSizeTable,
			  templ, atx, aty);

  gfree(syms);

  // combine the region bitmap into the page bitmap
  if (imm) {
    if (pageH == 0xffffffff && y + h > curPageH) {
      pageBitmap->expand(y + h, pageDefPixel);
    }
    pageBitmap->combine(bitmap, x, y, extCombOp);
    delete bitmap;

  // store the region bitmap
  } else {
    bitmap->setSegNum(segNum);
    segments->append(bitmap);
  }

  // clean up the Huffman decoder
  if (huff) {
    gfree(symCodeTab);
  }

  return;

 eofError:
  error(getPos(), "Unexpected EOF in JBIG2 stream");
}

JBIG2Bitmap *JBIG2Stream::readTextRegion(GBool huff, GBool refine,
					 int w, int h,
					 Guint numInstances,
					 Guint logStrips,
					 int numSyms,
					 JBIG2HuffmanTable *symCodeTab,
					 Guint symCodeLen,
					 JBIG2Bitmap **syms,
					 Guint defPixel, Guint combOp,
					 Guint transposed, Guint refCorner,
					 Guint sOffset,
					 JBIG2HuffmanTable *huffFSTable,
					 JBIG2HuffmanTable *huffDSTable,
					 JBIG2HuffmanTable *huffDTTable,
					 JBIG2HuffmanTable *huffRDWTable,
					 JBIG2HuffmanTable *huffRDHTable,
					 JBIG2HuffmanTable *huffRDXTable,
					 JBIG2HuffmanTable *huffRDYTable,
					 JBIG2HuffmanTable *huffRSizeTable,
					 Guint templ,
					 int *atx, int *aty) {
  JBIG2Bitmap *bitmap;
  JBIG2Bitmap *symbolBitmap;
  Guint strips;
  int t, dt, tt, s, ds, sFirst, j;
  int rdw, rdh, rdx, rdy, ri, refDX, refDY, bmSize;
  Guint symID, inst, bw, bh;

  strips = 1 << logStrips;

  // allocate the bitmap
  bitmap = new JBIG2Bitmap(0, w, h);
  if (defPixel) {
    bitmap->clearToOne();
  } else {
    bitmap->clearToZero();
  }

  // decode initial T value
  if (huff) {
    huffDecoder->decodeInt(&t, huffDTTable);
  } else {
    arithDecoder->decodeInt(&t, iadtStats);
  }
  t *= -strips;

  inst = 0;
  sFirst = 0;
  while (inst < numInstances) {

    // decode delta-T
    if (huff) {
      huffDecoder->decodeInt(&dt, huffDTTable);
    } else {
      arithDecoder->decodeInt(&dt, iadtStats);
    }
    t += dt * strips;

    // first S value
    if (huff) {
      huffDecoder->decodeInt(&ds, huffFSTable);
    } else {
      arithDecoder->decodeInt(&ds, iafsStats);
    }
    sFirst += ds;
    s = sFirst;

    // read the instances
    while (1) {

      // T value
      if (strips == 1) {
	dt = 0;
      } else if (huff) {
	dt = huffDecoder->readBits(logStrips);
      } else {
	arithDecoder->decodeInt(&dt, iaitStats);
      }
      tt = t + dt;

      // symbol ID
      if (huff) {
	if (symCodeTab) {
	  huffDecoder->decodeInt(&j, symCodeTab);
	  symID = (Guint)j;
	} else {
	  symID = huffDecoder->readBits(symCodeLen);
	}
      } else {
	symID = arithDecoder->decodeIAID(symCodeLen, iaidStats);
      }

      // get the symbol bitmap
      symbolBitmap = NULL;
      if (refine) {
	if (huff) {
	  ri = (int)huffDecoder->readBit();
	} else {
	  arithDecoder->decodeInt(&ri, iariStats);
	}
      } else {
	ri = 0;
      }
      if (ri) {
	if (huff) {
	  huffDecoder->decodeInt(&rdw, huffRDWTable);
	  huffDecoder->decodeInt(&rdh, huffRDHTable);
	  huffDecoder->decodeInt(&rdx, huffRDXTable);
	  huffDecoder->decodeInt(&rdy, huffRDYTable);
	  huffDecoder->decodeInt(&bmSize, huffRSizeTable);
	  huffDecoder->reset();
	  arithDecoder->start();
	} else {
	  arithDecoder->decodeInt(&rdw, iardwStats);
	  arithDecoder->decodeInt(&rdh, iardhStats);
	  arithDecoder->decodeInt(&rdx, iardxStats);
	  arithDecoder->decodeInt(&rdy, iardyStats);
	}
	refDX = ((rdw >= 0) ? rdw : rdw - 1) / 2 + rdx;
	refDY = ((rdh >= 0) ? rdh : rdh - 1) / 2 + rdy;

	symbolBitmap =
	  readGenericRefinementRegion(rdw + syms[symID]->getWidth(),
				      rdh + syms[symID]->getHeight(),
				      templ, gFalse, syms[symID],
				      refDX, refDY, atx, aty);
	//~ do we need to use the bmSize value here (in Huffman mode)?
      } else {
	symbolBitmap = syms[symID];
      }

      // combine the symbol bitmap into the region bitmap
      //~ something is wrong here - refCorner shouldn't degenerate into
      //~   two cases
      bw = symbolBitmap->getWidth() - 1;
      bh = symbolBitmap->getHeight() - 1;
      if (transposed) {
	switch (refCorner) {
	case 0: // bottom left
	  bitmap->combine(symbolBitmap, tt, s, combOp);
	  break;
	case 1: // top left
	  bitmap->combine(symbolBitmap, tt, s, combOp);
	  break;
	case 2: // bottom right
	  bitmap->combine(symbolBitmap, tt - bw, s, combOp);
	  break;
	case 3: // top right
	  bitmap->combine(symbolBitmap, tt - bw, s, combOp);
	  break;
	}
	s += bh;
      } else {
	switch (refCorner) {
	case 0: // bottom left
	  bitmap->combine(symbolBitmap, s, tt - bh, combOp);
	  break;
	case 1: // top left
	  bitmap->combine(symbolBitmap, s, tt, combOp);
	  break;
	case 2: // bottom right
	  bitmap->combine(symbolBitmap, s, tt - bh, combOp);
	  break;
	case 3: // top right
	  bitmap->combine(symbolBitmap, s, tt, combOp);
	  break;
	}
	s += bw;
      }
      if (ri) {
	delete symbolBitmap;
      }

      // next instance
      ++inst;

      // next S value
      if (huff) {
	if (!huffDecoder->decodeInt(&ds, huffDSTable)) {
	  break;
	}
      } else {
	if (!arithDecoder->decodeInt(&ds, iadsStats)) {
	  break;
	}
      }
      s += sOffset + ds;
    }
  }

  return bitmap;
}

void JBIG2Stream::readPatternDictSeg(Guint segNum, Guint length) {
  JBIG2PatternDict *patternDict;
  JBIG2Bitmap *bitmap;
  Guint flags, patternW, patternH, grayMax, templ, mmr;
  int atx[4], aty[4];
  Guint i, x;

  // halftone dictionary flags, pattern width and height, max gray value
  if (!readUByte(&flags) ||
      !readUByte(&patternW) ||
      !readUByte(&patternH) ||
      !readULong(&grayMax)) {
    goto eofError;
  }
  templ = (flags >> 1) & 3;
  mmr = flags & 1;

  // set up the arithmetic decoder
  if (!mmr) {
    resetGenericStats(templ, NULL);
    arithDecoder->start();
  }

  // read the bitmap
  atx[0] = -patternW; aty[0] =  0;
  atx[1] = -3;        aty[1] = -1;
  atx[2] =  2;        aty[2] = -2;
  atx[3] = -2;        aty[3] = -2;
  bitmap = readGenericBitmap(mmr, (grayMax + 1) * patternW, patternH,
			     templ, gFalse, gFalse, NULL,
			     atx, aty, length - 7);

  // create the pattern dict object
  patternDict = new JBIG2PatternDict(segNum, grayMax + 1);

  // split up the bitmap
  x = 0;
  for (i = 0; i <= grayMax; ++i) {
    patternDict->setBitmap(i, bitmap->getSlice(x, 0, patternW, patternH));
    x += patternW;
  }

  // free memory
  delete bitmap;

  // store the new pattern dict
  segments->append(patternDict);

  return;

 eofError:
  error(getPos(), "Unexpected EOF in JBIG2 stream");
}

void JBIG2Stream::readHalftoneRegionSeg(Guint segNum, GBool imm,
					GBool lossless, Guint length,
					Guint *refSegs, Guint nRefSegs) {
  JBIG2Bitmap *bitmap;
  JBIG2Segment *seg;
  JBIG2PatternDict *patternDict;
  JBIG2Bitmap *skipBitmap;
  Guint *grayImg;
  JBIG2Bitmap *grayBitmap;
  JBIG2Bitmap *patternBitmap;
  Guint w, h, x, y, segInfoFlags, extCombOp;
  Guint flags, mmr, templ, enableSkip, combOp;
  Guint gridW, gridH, stepX, stepY, patW, patH;
  int atx[4], aty[4];
  int gridX, gridY, xx, yy, bit, j;
  Guint bpp, m, n, i;

  // region segment info field
  if (!readULong(&w) || !readULong(&h) ||
      !readULong(&x) || !readULong(&y) ||
      !readUByte(&segInfoFlags)) {
    goto eofError;
  }
  extCombOp = segInfoFlags & 7;

  // rest of the halftone region header
  if (!readUByte(&flags)) {
    goto eofError;
  }
  mmr = flags & 1;
  templ = (flags >> 1) & 3;
  enableSkip = (flags >> 3) & 1;
  combOp = (flags >> 4) & 7;
  if (!readULong(&gridW) || !readULong(&gridH) ||
      !readLong(&gridX) || !readLong(&gridY) ||
      !readUWord(&stepX) || !readUWord(&stepY)) {
    goto eofError;
  }

  // get pattern dictionary
  if (nRefSegs != 1) {
    error(getPos(), "Bad symbol dictionary reference in JBIG2 halftone segment");
    return;
  }
  seg = findSegment(refSegs[0]);
  if (seg->getType() != jbig2SegPatternDict) {
    error(getPos(), "Bad symbol dictionary reference in JBIG2 halftone segment");
    return;
  }
  patternDict = (JBIG2PatternDict *)seg;
  bpp = 0;
  i = 1;
  while (i < patternDict->getSize()) {
    ++bpp;
    i <<= 1;
  }
  patW = patternDict->getBitmap(0)->getWidth();
  patH = patternDict->getBitmap(0)->getHeight();

  // set up the arithmetic decoder
  if (!mmr) {
    resetGenericStats(templ, NULL);
    arithDecoder->start();
  }

  // allocate the bitmap
  bitmap = new JBIG2Bitmap(segNum, w, h);
  if (flags & 0x80) { // HDEFPIXEL
    bitmap->clearToOne();
  } else {
    bitmap->clearToZero();
  }

  // compute the skip bitmap
  skipBitmap = NULL;
  if (enableSkip) {
    skipBitmap = new JBIG2Bitmap(0, gridW, gridH);
    skipBitmap->clearToZero();
    for (m = 0; m < gridH; ++m) {
      xx = gridX + m * stepY;
      yy = gridY + m * stepX;
      for (n = 0; n < gridW; ++n) {
	if (((xx + (int)patW) >> 8) <= 0 || (xx >> 8) >= (int)w ||
	    ((yy + (int)patH) >> 8) <= 0 || (yy >> 8) >= (int)h) {
	  skipBitmap->setPixel(n, m);
	}
      }
    }
  }

  // read the gray-scale image
  grayImg = (Guint *)gmalloc(gridW * gridH * sizeof(Guint));
  memset(grayImg, 0, gridW * gridH * sizeof(Guint));
  atx[0] = templ <= 1 ? 3 : 2;  aty[0] = -1;
  atx[1] = -3;                  aty[1] = -1;
  atx[2] =  2;                  aty[2] = -2;
  atx[3] = -2;                  aty[3] = -2;
  for (j = bpp - 1; j >= 0; --j) {
    grayBitmap = readGenericBitmap(mmr, gridW, gridH, templ, gFalse,
				   enableSkip, skipBitmap, atx, aty, -1);
    i = 0;
    for (m = 0; m < gridH; ++m) {
      for (n = 0; n < gridW; ++n) {
	bit = grayBitmap->getPixel(n, m) ^ (grayImg[i] & 1);
	grayImg[i] = (grayImg[i] << 1) | bit;
	++i;
      }
    }
    delete grayBitmap;
  }

  // decode the image
  i = 0;
  for (m = 0; m < gridH; ++m) {
    xx = gridX + m * stepY;
    yy = gridY + m * stepX;
    for (n = 0; n < gridW; ++n) {
      if (!(enableSkip && skipBitmap->getPixel(n, m))) {
	patternBitmap = patternDict->getBitmap(grayImg[i]);
	bitmap->combine(patternBitmap, xx >> 8, yy >> 8, combOp);
      }
      xx += stepX;
      yy -= stepY;
      ++i;
    }
  }

  gfree(grayImg);

  // combine the region bitmap into the page bitmap
  if (imm) {
    if (pageH == 0xffffffff && y + h > curPageH) {
      pageBitmap->expand(y + h, pageDefPixel);
    }
    pageBitmap->combine(bitmap, x, y, extCombOp);
    delete bitmap;

  // store the region bitmap
  } else {
    segments->append(bitmap);
  }

  return;

 eofError:
  error(getPos(), "Unexpected EOF in JBIG2 stream");
}

void JBIG2Stream::readGenericRegionSeg(Guint segNum, GBool imm,
				       GBool lossless, Guint length) {
  JBIG2Bitmap *bitmap;
  Guint w, h, x, y, segInfoFlags, extCombOp;
  Guint flags, mmr, templ, tpgdOn;
  int atx[4], aty[4];

  // region segment info field
  if (!readULong(&w) || !readULong(&h) ||
      !readULong(&x) || !readULong(&y) ||
      !readUByte(&segInfoFlags)) {
    goto eofError;
  }
  extCombOp = segInfoFlags & 7;

  // rest of the generic region segment header
  if (!readUByte(&flags)) {
    goto eofError;
  }
  mmr = flags & 1;
  templ = (flags >> 1) & 3;
  tpgdOn = (flags >> 3) & 1;

  // AT flags
  if (!mmr) {
    if (templ == 0) {
      if (!readByte(&atx[0]) ||
	  !readByte(&aty[0]) ||
	  !readByte(&atx[1]) ||
	  !readByte(&aty[1]) ||
	  !readByte(&atx[2]) ||
	  !readByte(&aty[2]) ||
	  !readByte(&atx[3]) ||
	  !readByte(&aty[3])) {
	goto eofError;
      }
    } else {
      if (!readByte(&atx[0]) ||
	  !readByte(&aty[0])) {
	goto eofError;
      }
    }
  }

  // set up the arithmetic decoder
  if (!mmr) {
    resetGenericStats(templ, NULL);
    arithDecoder->start();
  }

  // read the bitmap
  bitmap = readGenericBitmap(mmr, w, h, templ, tpgdOn, gFalse,
			     NULL, atx, aty, mmr ? 0 : length - 18);

  // combine the region bitmap into the page bitmap
  if (imm) {
    if (pageH == 0xffffffff && y + h > curPageH) {
      pageBitmap->expand(y + h, pageDefPixel);
    }
    pageBitmap->combine(bitmap, x, y, extCombOp);
    delete bitmap;

  // store the region bitmap
  } else {
    bitmap->setSegNum(segNum);
    segments->append(bitmap);
  }

  return;

 eofError:
  error(getPos(), "Unexpected EOF in JBIG2 stream");
}

JBIG2Bitmap *JBIG2Stream::readGenericBitmap(GBool mmr, int w, int h,
					    int templ, GBool tpgdOn,
					    GBool useSkip, JBIG2Bitmap *skip,
					    int *atx, int *aty,
					    int mmrDataLength) {
  JBIG2Bitmap *bitmap;
  GBool ltp;
  Guint ltpCX, cx, cx0, cx1, cx2;
  int *refLine, *codingLine;
  int code1, code2, code3;
  int x, y, a0, pix, i, refI, codingI;

  bitmap = new JBIG2Bitmap(0, w, h);
  bitmap->clearToZero();

  //----- MMR decode

  if (mmr) {

    mmrDecoder->reset();
    refLine = (int *)gmalloc((w + 2) * sizeof(int));
    codingLine = (int *)gmalloc((w + 2) * sizeof(int));
    codingLine[0] = codingLine[1] = w;

    for (y = 0; y < h; ++y) {

      // copy coding line to ref line
      for (i = 0; codingLine[i] < w; ++i) {
	refLine[i] = codingLine[i];
      }
      refLine[i] = refLine[i + 1] = w;

      // decode a line
      refI = 0;     // b1 = refLine[refI]
      codingI = 0;  // a1 = codingLine[codingI]
      a0 = 0;
      do {
	code1 = mmrDecoder->get2DCode();
	switch (code1) {
	case twoDimPass:
	  if (refLine[refI] < w) {
	    a0 = refLine[refI + 1];
	    refI += 2;
	  }
	  break;
	case twoDimHoriz:
	  if (codingI & 1) {
	    code1 = 0;
	    do {
	      code1 += code3 = mmrDecoder->getBlackCode();
	    } while (code3 >= 64);
	    code2 = 0;
	    do {
	      code2 += code3 = mmrDecoder->getWhiteCode();
	    } while (code3 >= 64);
	  } else {
	    code1 = 0;
	    do {
	      code1 += code3 = mmrDecoder->getWhiteCode();
	    } while (code3 >= 64);
	    code2 = 0;
	    do {
	      code2 += code3 = mmrDecoder->getBlackCode();
	    } while (code3 >= 64);
	  }
	  a0 = codingLine[codingI++] = a0 + code1;
	  a0 = codingLine[codingI++] = a0 + code2;
	  while (refLine[refI] <= a0 && refLine[refI] < w) {
	    refI += 2;
	  }
	  break;
	case twoDimVert0:
	  a0 = codingLine[codingI++] = refLine[refI];
	  if (refLine[refI] < w) {
	    ++refI;
	  }
	  break;
	case twoDimVertR1:
	  a0 = codingLine[codingI++] = refLine[refI] + 1;
	  if (refLine[refI] < w) {
	    ++refI;
	    while (refLine[refI] <= a0 && refLine[refI] < w) {
	      refI += 2;
	    }
	  }
	  break;
	case twoDimVertR2:
	  a0 = codingLine[codingI++] = refLine[refI] + 2;
	  if (refLine[refI] < w) {
	    ++refI;
	    while (refLine[refI] <= a0 && refLine[refI] < w) {
	      refI += 2;
	    }
	  }
	  break;
	case twoDimVertR3:
	  a0 = codingLine[codingI++] = refLine[refI] + 3;
	  if (refLine[refI] < w) {
	    ++refI;
	    while (refLine[refI] <= a0 && refLine[refI] < w) {
	      refI += 2;
	    }
	  }
	  break;
	case twoDimVertL1:
	  a0 = codingLine[codingI++] = refLine[refI] - 1;
	  if (refI > 0) {
	    --refI;
	  } else {
	    ++refI;
	  }
	  while (refLine[refI] <= a0 && refLine[refI] < w) {
	    refI += 2;
	  }
	  break;
	case twoDimVertL2:
	  a0 = codingLine[codingI++] = refLine[refI] - 2;
	  if (refI > 0) {
	    --refI;
	  } else {
	    ++refI;
	  }
	  while (refLine[refI] <= a0 && refLine[refI] < w) {
	    refI += 2;
	  }
	  break;
	case twoDimVertL3:
	  a0 = codingLine[codingI++] = refLine[refI] - 3;
	  if (refI > 0) {
	    --refI;
	  } else {
	    ++refI;
	  }
	  while (refLine[refI] <= a0 && refLine[refI] < w) {
	    refI += 2;
	  }
	  break;
	default:
	  error(getPos(), "Illegal code in JBIG2 MMR bitmap data");
	  break;
	}
      } while (a0 < w);
      codingLine[codingI++] = w;

      // convert the run lengths to a bitmap line
      i = 0;
      while (codingLine[i] < w) {
	for (x = codingLine[i]; x < codingLine[i+1]; ++x) {
	  bitmap->setPixel(x, y);
	}
	i += 2;
      }
    }

    if (mmrDataLength >= 0) {
      mmrDecoder->skipTo(mmrDataLength);
    } else {
      if (mmrDecoder->get24Bits() != 0x001001) {
	error(getPos(), "Missing EOFB in JBIG2 MMR bitmap data");
      }
    }

    gfree(refLine);
    gfree(codingLine);

  //----- arithmetic decode

  } else {
    // set up the typical row context
    ltpCX = 0; // make gcc happy
    if (tpgdOn) {
      switch (templ) {
      case 0:
	ltpCX = 0x3953; // 001 11001 0101 0011
	break;
      case 1:
	ltpCX = 0x079a; // 0011 11001 101 0
	break;
      case 2:
	ltpCX = 0x0e3; // 001 1100 01 1
	break;
      case 3:
	ltpCX = 0x18a; // 01100 0101 1
	break;
      }
    }

    ltp = 0;
    cx = cx0 = cx1 = cx2 = 0; // make gcc happy
    for (y = 0; y < h; ++y) {

      // check for a "typical" (duplicate) row
      if (tpgdOn) {
	if (arithDecoder->decodeBit(ltpCX, genericRegionStats)) {
	  ltp = !ltp;
	}
	if (ltp) {
	  bitmap->duplicateRow(y, y-1);
	  continue;
	}
      }

      // set up the context
      switch (templ) {
      case 0:
	cx0 = (bitmap->getPixel(0, y-2) << 1) |
	      bitmap->getPixel(1, y-2);
	cx1 = (bitmap->getPixel(0, y-1) << 2) |
	      (bitmap->getPixel(1, y-1) << 1) |
	      bitmap->getPixel(2, y-1);
	cx2 = 0;
	break;
      case 1:
	cx0 = (bitmap->getPixel(0, y-2) << 2) |
	      (bitmap->getPixel(1, y-2) << 1) |
	      bitmap->getPixel(2, y-2);
	cx1 = (bitmap->getPixel(0, y-1) << 2) |
	      (bitmap->getPixel(1, y-1) << 1) |
	      bitmap->getPixel(2, y-1);
	cx2 = 0;
	break;
      case 2:
	cx0 = (bitmap->getPixel(0, y-2) << 1) |
	      bitmap->getPixel(1, y-2);
	cx1 = (bitmap->getPixel(0, y-1) << 1) |
	      bitmap->getPixel(1, y-1);
	cx2 = 0;
	break;
      case 3:
	cx1 = (bitmap->getPixel(0, y-1) << 1) |
	      bitmap->getPixel(1, y-1);
	cx2 = 0;
	break;
      }

      // decode the row
      for (x = 0; x < w; ++x) {

	// check for a skipped pixel
	if (useSkip && skip->getPixel(x, y)) {
	  pix = 0;

	} else {

	  // build the context
	  switch (templ) {
	  case 0:
	    cx = (cx0 << 13) | (cx1 << 8) | (cx2 << 4) |
	         (bitmap->getPixel(x + atx[0], y + aty[0]) << 3) |
	         (bitmap->getPixel(x + atx[1], y + aty[1]) << 2) |
	         (bitmap->getPixel(x + atx[2], y + aty[2]) << 1) |
	         bitmap->getPixel(x + atx[3], y + aty[3]);
	    break;
	  case 1:
	    cx = (cx0 << 9) | (cx1 << 4) | (cx2 << 1) |
	         bitmap->getPixel(x + atx[0], y + aty[0]);
	    break;
	  case 2:
	    cx = (cx0 << 7) | (cx1 << 3) | (cx2 << 1) |
	         bitmap->getPixel(x + atx[0], y + aty[0]);
	    break;
	  case 3:
	    cx = (cx1 << 5) | (cx2 << 1) |
	         bitmap->getPixel(x + atx[0], y + aty[0]);
	    break;
	  }

	  // decode the pixel
	  if ((pix = arithDecoder->decodeBit(cx, genericRegionStats))) {
	    bitmap->setPixel(x, y);
	  }
	}

	// update the context
	switch (templ) {
	  case 0:
	    cx0 = ((cx0 << 1) | bitmap->getPixel(x+2, y-2)) & 0x07;
	    cx1 = ((cx1 << 1) | bitmap->getPixel(x+3, y-1)) & 0x1f;
	    cx2 = ((cx2 << 1) | pix) & 0x0f;
	    break;
	  case 1:
	    cx0 = ((cx0 << 1) | bitmap->getPixel(x+3, y-2)) & 0x0f;
	    cx1 = ((cx1 << 1) | bitmap->getPixel(x+3, y-1)) & 0x1f;
	    cx2 = ((cx2 << 1) | pix) & 0x07;
	    break;
	  case 2:
	    cx0 = ((cx0 << 1) | bitmap->getPixel(x+2, y-2)) & 0x07;
	    cx1 = ((cx1 << 1) | bitmap->getPixel(x+2, y-1)) & 0x0f;
	    cx2 = ((cx2 << 1) | pix) & 0x03;
	    break;
	  case 3:
	    cx1 = ((cx1 << 1) | bitmap->getPixel(x+2, y-1)) & 0x1f;
	    cx2 = ((cx2 << 1) | pix) & 0x0f;
	    break;
	}
      }
    }
  }

  return bitmap;
}

void JBIG2Stream::readGenericRefinementRegionSeg(Guint segNum, GBool imm,
						 GBool lossless, Guint length,
						 Guint *refSegs,
						 Guint nRefSegs) {
  JBIG2Bitmap *bitmap, *refBitmap;
  Guint w, h, x, y, segInfoFlags, extCombOp;
  Guint flags, templ, tpgrOn;
  int atx[2], aty[2];
  JBIG2Segment *seg;

  // region segment info field
  if (!readULong(&w) || !readULong(&h) ||
      !readULong(&x) || !readULong(&y) ||
      !readUByte(&segInfoFlags)) {
    goto eofError;
  }
  extCombOp = segInfoFlags & 7;

  // rest of the generic refinement region segment header
  if (!readUByte(&flags)) {
    goto eofError;
  }
  templ = flags & 1;
  tpgrOn = (flags >> 1) & 1;

  // AT flags
  if (!templ) {
    if (!readByte(&atx[0]) || !readByte(&aty[0]) ||
	!readByte(&atx[1]) || !readByte(&aty[1])) {
      goto eofError;
    }
  }

  // resize the page bitmap if needed
  if (nRefSegs == 0 || imm) {
    if (pageH == 0xffffffff && y + h > curPageH) {
      pageBitmap->expand(y + h, pageDefPixel);
    }
  }

  // get referenced bitmap
  if (nRefSegs > 1) {
    error(getPos(), "Bad reference in JBIG2 generic refinement segment");
    return;
  }
  if (nRefSegs == 1) {
    seg = findSegment(refSegs[0]);
    if (seg->getType() != jbig2SegBitmap) {
      error(getPos(), "Bad bitmap reference in JBIG2 generic refinement segment");
      return;
    }
    refBitmap = (JBIG2Bitmap *)seg;
  } else {
    refBitmap = pageBitmap->getSlice(x, y, w, h);
  }

  // set up the arithmetic decoder
  resetRefinementStats(templ, NULL);
  arithDecoder->start();

  // read
  bitmap = readGenericRefinementRegion(w, h, templ, tpgrOn,
				       refBitmap, 0, 0, atx, aty);

  // combine the region bitmap into the page bitmap
  if (imm) {
    pageBitmap->combine(bitmap, x, y, extCombOp);
    delete bitmap;

  // store the region bitmap
  } else {
    bitmap->setSegNum(segNum);
    segments->append(bitmap);
  }

  // delete the referenced bitmap
  if (nRefSegs == 1) {
    discardSegment(refSegs[0]);
  } else {
    delete refBitmap;
  }

  return;

 eofError:
  error(getPos(), "Unexpected EOF in JBIG2 stream");
}

JBIG2Bitmap *JBIG2Stream::readGenericRefinementRegion(int w, int h,
						      int templ, GBool tpgrOn,
						      JBIG2Bitmap *refBitmap,
						      int refDX, int refDY,
						      int *atx, int *aty) {
  JBIG2Bitmap *bitmap;
  GBool ltp;
  Guint ltpCX, cx, cx0, cx2, cx3, cx4, tpgrCX0, tpgrCX1, tpgrCX2;
  int x, y, pix;

  bitmap = new JBIG2Bitmap(0, w, h);
  bitmap->clearToZero();

  // set up the typical row context
  if (templ) {
    ltpCX = 0x008;
  } else {
    ltpCX = 0x0010;
  }

  ltp = 0;
  for (y = 0; y < h; ++y) {

    // set up the context
    if (templ) {
      cx0 = bitmap->getPixel(0, y-1);
      cx2 = 0; // unused
      cx3 = (refBitmap->getPixel(-1-refDX, y-refDY) << 1) |
	    refBitmap->getPixel(-refDX, y-refDY);
      cx4 = refBitmap->getPixel(-refDX, y+1-refDY);
    } else {
      cx0 = bitmap->getPixel(0, y-1);
      cx2 = refBitmap->getPixel(-refDX, y-1-refDY);
      cx3 = (refBitmap->getPixel(-1-refDX, y-refDY) << 1) |
	    refBitmap->getPixel(-refDX, y-refDY);
      cx4 = (refBitmap->getPixel(-1-refDX, y+1-refDY) << 1) |
	    refBitmap->getPixel(-refDX, y+1-refDY);
    }

    // set up the typical prediction context
    tpgrCX0 = tpgrCX1 = tpgrCX2 = 0; // make gcc happy
    if (tpgrOn) {
      tpgrCX0 = (refBitmap->getPixel(-1-refDX, y-1-refDY) << 2) |
	        (refBitmap->getPixel(-refDX, y-1-refDY) << 1) |
	        refBitmap->getPixel(1-refDX, y-1-refDY);
      tpgrCX1 = (refBitmap->getPixel(-1-refDX, y-refDY) << 2) |
	        (refBitmap->getPixel(-refDX, y-refDY) << 1) |
	        refBitmap->getPixel(1-refDX, y-refDY);
      tpgrCX2 = (refBitmap->getPixel(-1-refDX, y+1-refDY) << 2) |
	        (refBitmap->getPixel(-refDX, y+1-refDY) << 1) |
	        refBitmap->getPixel(1-refDX, y+1-refDY);
    }

    for (x = 0; x < w; ++x) {

      // update the context
      if (templ) {
	cx0 = ((cx0 << 1) | bitmap->getPixel(x+1, y-1)) & 7;
	cx3 = ((cx3 << 1) | refBitmap->getPixel(x+1-refDX, y-refDY)) & 7;
	cx4 = ((cx4 << 1) | refBitmap->getPixel(x+1-refDX, y+1-refDY)) & 3;
      } else {
	cx0 = ((cx0 << 1) | bitmap->getPixel(x+1, y-1)) & 3;
	cx2 = ((cx2 << 1) | refBitmap->getPixel(x+1-refDX, y-1-refDY)) & 3;
	cx3 = ((cx3 << 1) | refBitmap->getPixel(x+1-refDX, y-refDY)) & 7;
	cx4 = ((cx4 << 1) | refBitmap->getPixel(x+1-refDX, y+1-refDY)) & 7;
      }

      if (tpgrOn) {
	// update the typical predictor context
	tpgrCX0 = ((tpgrCX0 << 1) |
		   refBitmap->getPixel(x+1-refDX, y-1-refDY)) & 7;
	tpgrCX1 = ((tpgrCX1 << 1) |
		   refBitmap->getPixel(x+1-refDX, y-refDY)) & 7;
	tpgrCX2 = ((tpgrCX2 << 1) |
		   refBitmap->getPixel(x+1-refDX, y+1-refDY)) & 7;

	// check for a "typical" pixel
	if (arithDecoder->decodeBit(ltpCX, refinementRegionStats)) {
	  ltp = !ltp;
	}
	if (tpgrCX0 == 0 && tpgrCX1 == 0 && tpgrCX2 == 0) {
	  bitmap->clearPixel(x, y);
	  continue;
	} else if (tpgrCX0 == 7 && tpgrCX1 == 7 && tpgrCX2 == 7) {
	  bitmap->setPixel(x, y);
	  continue;
	}
      }

      // build the context
      if (templ) {
	cx = (cx0 << 7) | (bitmap->getPixel(x-1, y) << 6) |
	     (refBitmap->getPixel(x-refDX, y-1-refDY) << 5) |
	     (cx3 << 2) | cx4;
      } else {
	cx = (cx0 << 11) | (bitmap->getPixel(x-1, y) << 10) |
	     (cx2 << 8) | (cx3 << 5) | (cx4 << 2) |
	     (bitmap->getPixel(x+atx[0], y+aty[0]) << 1) |
	     refBitmap->getPixel(x+atx[1]-refDX, y+aty[1]-refDY);
      }

      // decode the pixel
      if ((pix = arithDecoder->decodeBit(cx, refinementRegionStats))) {
	bitmap->setPixel(x, y);
      }
    }
  }

  return bitmap;
}

void JBIG2Stream::readPageInfoSeg(Guint length) {
  Guint xRes, yRes, flags, striping;

  if (!readULong(&pageW) || !readULong(&pageH) ||
      !readULong(&xRes) || !readULong(&yRes) ||
      !readUByte(&flags) || !readUWord(&striping)) {
    goto eofError;
  }
  pageDefPixel = (flags >> 2) & 1;
  defCombOp = (flags >> 3) & 3;

  // allocate the page bitmap
  if (pageH == 0xffffffff) {
    curPageH = striping & 0x7fff;
  } else {
    curPageH = pageH;
  }
  pageBitmap = new JBIG2Bitmap(0, pageW, curPageH);

  // default pixel value
  if (pageDefPixel) {
    pageBitmap->clearToOne();
  } else {
    pageBitmap->clearToZero();
  }

  return;

 eofError:
  error(getPos(), "Unexpected EOF in JBIG2 stream");
}

void JBIG2Stream::readEndOfStripeSeg(Guint length) {
  Guint i;

  // skip the segment
  for (i = 0; i < length; ++i) {
    curStr->getChar();
  }
}

void JBIG2Stream::readProfilesSeg(Guint length) {
  Guint i;

  // skip the segment
  for (i = 0; i < length; ++i) {
    curStr->getChar();
  }
}

void JBIG2Stream::readCodeTableSeg(Guint segNum, Guint length) {
  JBIG2HuffmanTable *huffTab;
  Guint flags, oob, prefixBits, rangeBits;
  int lowVal, highVal, val;
  Guint huffTabSize, i;

  if (!readUByte(&flags) || !readLong(&lowVal) || !readLong(&highVal)) {
    goto eofError;
  }
  oob = flags & 1;
  prefixBits = (flags >> 1) & 7;
  rangeBits = (flags >> 4) & 7;

  huffDecoder->reset();
  huffTabSize = 8;
  huffTab = (JBIG2HuffmanTable *)
                gmalloc(huffTabSize * sizeof(JBIG2HuffmanTable));
  i = 0;
  val = lowVal;
  while (val < highVal) {
    if (i == huffTabSize) {
      huffTabSize *= 2;
      huffTab = (JBIG2HuffmanTable *)
	            grealloc(huffTab, huffTabSize * sizeof(JBIG2HuffmanTable));
    }
    huffTab[i].val = val;
    huffTab[i].prefixLen = huffDecoder->readBits(prefixBits);
    huffTab[i].rangeLen = huffDecoder->readBits(rangeBits);
    val += 1 << huffTab[i].rangeLen;
    ++i;
  }
  if (i + oob + 3 > huffTabSize) {
    huffTabSize = i + oob + 3;
    huffTab = (JBIG2HuffmanTable *)
                  grealloc(huffTab, huffTabSize * sizeof(JBIG2HuffmanTable));
  }
  huffTab[i].val = lowVal - 1;
  huffTab[i].prefixLen = huffDecoder->readBits(prefixBits);
  huffTab[i].rangeLen = jbig2HuffmanLOW;
  ++i;
  huffTab[i].val = highVal;
  huffTab[i].prefixLen = huffDecoder->readBits(prefixBits);
  huffTab[i].rangeLen = 32;
  ++i;
  if (oob) {
    huffTab[i].val = 0;
    huffTab[i].prefixLen = huffDecoder->readBits(prefixBits);
    huffTab[i].rangeLen = jbig2HuffmanOOB;
    ++i;
  }
  huffTab[i].val = 0;
  huffTab[i].prefixLen = 0;
  huffTab[i].rangeLen = jbig2HuffmanEOT;
  ++i;
  huffDecoder->buildTable(huffTab, i);

  // create and store the new table segment
  segments->append(new JBIG2CodeTable(segNum, huffTab));

  return;

 eofError:
  error(getPos(), "Unexpected EOF in JBIG2 stream");
}

void JBIG2Stream::readExtensionSeg(Guint length) {
  Guint i;

  // skip the segment
  for (i = 0; i < length; ++i) {
    curStr->getChar();
  }
}

JBIG2Segment *JBIG2Stream::findSegment(Guint segNum) {
  JBIG2Segment *seg;
  int i;

  for (i = 0; i < globalSegments->getLength(); ++i) {
    seg = (JBIG2Segment *)globalSegments->get(i);
    if (seg->getSegNum() == segNum) {
      return seg;
    }
  }
  for (i = 0; i < segments->getLength(); ++i) {
    seg = (JBIG2Segment *)segments->get(i);
    if (seg->getSegNum() == segNum) {
      return seg;
    }
  }
  return NULL;
}

void JBIG2Stream::discardSegment(Guint segNum) {
  JBIG2Segment *seg;
  int i;

  for (i = 0; i < globalSegments->getLength(); ++i) {
    seg = (JBIG2Segment *)globalSegments->get(i);
    if (seg->getSegNum() == segNum) {
      globalSegments->del(i);
      return;
    }
  }
  for (i = 0; i < segments->getLength(); ++i) {
    seg = (JBIG2Segment *)segments->get(i);
    if (seg->getSegNum() == segNum) {
      globalSegments->del(i);
      return;
    }
  }
}

void JBIG2Stream::resetGenericStats(Guint templ,
				    JBIG2ArithmeticDecoderStats *prevStats) {
  int size;

  size = contextSize[templ];
  if (prevStats && prevStats->getContextSize() == size) {
    if (genericRegionStats->getContextSize() == size) {
      genericRegionStats->copyFrom(prevStats);
    } else {
      delete genericRegionStats;
      genericRegionStats = prevStats->copy();
    }
  } else {
    if (genericRegionStats->getContextSize() == size) {
      genericRegionStats->reset();
    } else {
      delete genericRegionStats;
      genericRegionStats = new JBIG2ArithmeticDecoderStats(size);
    }
  }
}

void JBIG2Stream::resetRefinementStats(
		      Guint templ,
		      JBIG2ArithmeticDecoderStats *prevStats) {
  int size;

  size = refContextSize[templ];
  if (prevStats && prevStats->getContextSize() == size) {
    if (refinementRegionStats->getContextSize() == size) {
      refinementRegionStats->copyFrom(prevStats);
    } else {
      delete refinementRegionStats;
      refinementRegionStats = prevStats->copy();
    }
  } else {
    if (refinementRegionStats->getContextSize() == size) {
      refinementRegionStats->reset();
    } else {
      delete refinementRegionStats;
      refinementRegionStats = new JBIG2ArithmeticDecoderStats(size);
    }
  }
}

void JBIG2Stream::resetIntStats(int symCodeLen) {
  iadhStats->reset();
  iadwStats->reset();
  iaexStats->reset();
  iaaiStats->reset();
  iadtStats->reset();
  iaitStats->reset();
  iafsStats->reset();
  iadsStats->reset();
  iardxStats->reset();
  iardyStats->reset();
  iardwStats->reset();
  iardhStats->reset();
  iariStats->reset();
  if (iaidStats->getContextSize() == symCodeLen + 1) {
    iaidStats->reset();
  } else {
    delete iaidStats;
    iaidStats = new JBIG2ArithmeticDecoderStats(symCodeLen + 1);
  }
}

GBool JBIG2Stream::readUByte(Guint *x) {
  int c0;

  if ((c0 = curStr->getChar()) == EOF) {
    return gFalse;
  }
  *x = (Guint)c0;
  return gTrue;
}

GBool JBIG2Stream::readByte(int *x) {
 int c0;

  if ((c0 = curStr->getChar()) == EOF) {
    return gFalse;
  }
  *x = c0;
  if (c0 & 0x80) {
    *x |= -1 - 0xff;
  }
  return gTrue;
}

GBool JBIG2Stream::readUWord(Guint *x) {
  int c0, c1;

  if ((c0 = curStr->getChar()) == EOF ||
      (c1 = curStr->getChar()) == EOF) {
    return gFalse;
  }
  *x = (Guint)((c0 << 8) | c1);
  return gTrue;
}

GBool JBIG2Stream::readULong(Guint *x) {
  int c0, c1, c2, c3;

  if ((c0 = curStr->getChar()) == EOF ||
      (c1 = curStr->getChar()) == EOF ||
      (c2 = curStr->getChar()) == EOF ||
      (c3 = curStr->getChar()) == EOF) {
    return gFalse;
  }
  *x = (Guint)((c0 << 24) | (c1 << 16) | (c2 << 8) | c3);
  return gTrue;
}

GBool JBIG2Stream::readLong(int *x) {
  int c0, c1, c2, c3;

  if ((c0 = curStr->getChar()) == EOF ||
      (c1 = curStr->getChar()) == EOF ||
      (c2 = curStr->getChar()) == EOF ||
      (c3 = curStr->getChar()) == EOF) {
    return gFalse;
  }
  *x = ((c0 << 24) | (c1 << 16) | (c2 << 8) | c3);
  if (c0 & 0x80) {
    *x |= -1 - 0xffffffff;
  }
  return gTrue;
}
