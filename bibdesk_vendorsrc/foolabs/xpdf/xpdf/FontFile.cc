//========================================================================
//
// FontFile.cc
//
// Copyright 1999-2002 Glyph & Cog, LLC
//
//========================================================================

#include <aconf.h>

#ifdef USE_GCC_PRAGMAS
#pragma implementation
#endif

#include <math.h>
#include <stdlib.h>
#include <stddef.h>
#include <stdarg.h>
#include <string.h>
#include <ctype.h>
#include "gmem.h"
#include "Error.h"
#include "GlobalParams.h"
#include "CharCodeToUnicode.h"
#include "FontEncodingTables.h"
#include "FontFile.h"

#include "CompactFontTables.h"

//------------------------------------------------------------------------

static inline char *nextLine(char *line, char *end) {
  while (line < end && *line != '\n' && *line != '\r')
    ++line;
  while (line < end && *line == '\n' || *line == '\r')
    ++line;
  return line;
}

static char hexChars[17] = "0123456789ABCDEF";

//------------------------------------------------------------------------
// FontFile
//------------------------------------------------------------------------

FontFile::FontFile() {
}

FontFile::~FontFile() {
}

//------------------------------------------------------------------------
// Type1FontFile
//------------------------------------------------------------------------

Type1FontFile::Type1FontFile(char *file, int len) {
  char *line, *line1, *p, *p2;
  GBool haveEncoding;
  char buf[256];
  char c;
  int n, code, i, j;

  name = NULL;
  encoding = (char **)gmalloc(256 * sizeof(char *));
  for (i = 0; i < 256; ++i) {
    encoding[i] = NULL;
  }
  haveEncoding = gFalse;

  for (i = 1, line = file;
       i <= 100 && line < file + len && !haveEncoding;
       ++i) {

    // get font name
    if (!strncmp(line, "/FontName", 9)) {
      strncpy(buf, line, 255);
      buf[255] = '\0';
      if ((p = strchr(buf+9, '/')) &&
	  (p = strtok(p+1, " \t\n\r"))) {
	name = copyString(p);
      }
      line = nextLine(line, file + len);

    // get encoding
    } else if (!strncmp(line, "/Encoding StandardEncoding def", 30)) {
      for (j = 0; j < 256; ++j) {
	if (standardEncoding[j]) {
	  encoding[j] = copyString(standardEncoding[j]);
	}
      }
      haveEncoding = gTrue;
    } else if (!strncmp(line, "/Encoding 256 array", 19)) {
      for (j = 0; j < 300; ++j) {
	line1 = nextLine(line, file + len);
	if ((n = line1 - line) > 255) {
	  n = 255;
	}
	strncpy(buf, line, n);
	buf[n] = '\0';
	for (p = buf; *p == ' ' || *p == '\t'; ++p) ;
	if (!strncmp(p, "dup", 3)) {
	  for (p += 3; *p == ' ' || *p == '\t'; ++p) ;
	  for (p2 = p; *p2 >= '0' && *p2 <= '9'; ++p2) ;
	  if (*p2) {
	    c = *p2;
	    *p2 = '\0';
	    if ((code = atoi(p)) < 256) {
	      *p2 = c;
	      for (p = p2; *p == ' ' || *p == '\t'; ++p) ;
	      if (*p == '/') {
		++p;
		for (p2 = p; *p2 && *p2 != ' ' && *p2 != '\t'; ++p2) ;
		*p2 = '\0';
		encoding[code] = copyString(p);
	      }
	    }
	  }
	} else {
	  if (strtok(buf, " \t") &&
	      (p = strtok(NULL, " \t\n\r")) && !strcmp(p, "def")) {
	    break;
	  }
	}
	line = line1;
      }
      //~ check for getinterval/putinterval junk
      haveEncoding = gTrue;

    } else {
      line = nextLine(line, file + len);
    }
  }
}

Type1FontFile::~Type1FontFile() {
  int i;

  if (name) {
    gfree(name);
  }
  for (i = 0; i < 256; ++i) {
    gfree(encoding[i]);
  }
  gfree(encoding);
}

//------------------------------------------------------------------------
// Type1CFontFile
//------------------------------------------------------------------------

struct Type1CTopDict {
  int version;
  int notice;
  int copyright;
  int fullName;
  int familyName;
  int weight;
  int isFixedPitch;
  double italicAngle;
  double underlinePosition;
  double underlineThickness;
  int paintType;
  int charstringType;
  double fontMatrix[6];
  int uniqueID;
  double fontBBox[4];
  double strokeWidth;
  int charset;
  int encoding;
  int charStrings;
  int privateSize;
  int privateOffset;

  //----- CIDFont entries
  int registry;
  int ordering;
  int supplement;
  int fdArrayOffset;
  int fdSelectOffset;
};

struct Type1CPrivateDict {
  GString *dictData;
  int subrsOffset;
  double defaultWidthX;
  GBool defaultWidthXFP;
  double nominalWidthX;
  GBool nominalWidthXFP;
};

Type1CFontFile::Type1CFontFile(char *fileA, int lenA) {
  Guchar *nameIdxPtr, *idxPtr0, *idxPtr1;

  file = fileA;
  len = lenA;
  name = NULL;
  encoding = NULL;

  // some tools embed Type 1C fonts with an extra whitespace char at
  // the beginning
  if (file[0] != '\x01') {
    ++file;
  }

  // read header
  topOffSize = file[3] & 0xff;

  // read name index (first font only)
  nameIdxPtr = (Guchar *)file + (file[2] & 0xff);
  idxPtr0 = getIndexValPtr(nameIdxPtr, 0);
  idxPtr1 = getIndexValPtr(nameIdxPtr, 1);
  name = new GString((char *)idxPtr0, idxPtr1 - idxPtr0);

  topDictIdxPtr = getIndexEnd(nameIdxPtr);
  stringIdxPtr = getIndexEnd(topDictIdxPtr);
  gsubrIdxPtr = getIndexEnd(stringIdxPtr);
}

Type1CFontFile::~Type1CFontFile() {
  int i;

  delete name;
  if (encoding) {
    for (i = 0; i < 256; ++i) {
      gfree(encoding[i]);
    }
    gfree(encoding);
  }
}

char *Type1CFontFile::getName() {
  return name->getCString();
}

char **Type1CFontFile::getEncoding() {
  if (!encoding) {
    readNameAndEncoding();
  }
  return encoding;
}

void Type1CFontFile::readNameAndEncoding() {
  char buf[256];
  Guchar *idxPtr0, *idxPtr1, *ptr;
  int nGlyphs;
  int nCodes, nRanges, nLeft, nSups;
  Gushort *glyphNames;
  int charset, enc, charstrings;
  int encFormat;
  int c, sid;
  double x;
  GBool isFP;
  int key;
  int i, j;

  encoding = (char **)gmalloc(256 * sizeof(char *));
  for (i = 0; i < 256; ++i) {
    encoding[i] = NULL;
  }

  // read top dict (first font only)
  idxPtr0 = getIndexValPtr(topDictIdxPtr, 0);
  idxPtr1 = getIndexValPtr(topDictIdxPtr, 1);
  charset = enc = charstrings = 0;
  i = 0;
  ptr = idxPtr0;
  while (ptr < idxPtr1) {
    if (*ptr <= 27 || *ptr == 31) {
      key = *ptr++;
      if (key == 0x0c) {
	key = (key << 8) | *ptr++;
      }
      if (key == 0x0f) { // charset
	charset = (int)op[0];
      } else if (key == 0x10) { // encoding
	enc = (int)op[0];
      } else if (key == 0x11) { // charstrings
	charstrings = (int)op[0];
      }
      i = 0;
    } else {
      x = getNum(&ptr, &isFP);
      if (i < 48) {
	op[i++] = x;
      }
    }
  }

  // get number of glyphs from charstrings index
  nGlyphs = getIndexLen((Guchar *)file + charstrings);

  // read charset (GID -> name mapping)
  glyphNames = readCharset(charset, nGlyphs);

  // read encoding (GID -> code mapping)
  if (enc == 0) {
    for (i = 0; i < 256; ++i) {
      if (standardEncoding[i]) {
	encoding[i] = copyString(standardEncoding[i]);
      }
    }
  } else if (enc == 1) {
    for (i = 0; i < 256; ++i) {
      if (expertEncoding[i]) {
	encoding[i] = copyString(expertEncoding[i]);
      }
    }
  } else {
    ptr = (Guchar *)file + enc;
    encFormat = *ptr++;
    if ((encFormat & 0x7f) == 0) {
      nCodes = 1 + *ptr++;
      if (nCodes > nGlyphs) {
	nCodes = nGlyphs;
      }
      for (i = 1; i < nCodes; ++i) {
	c = *ptr++;
	encoding[c] = copyString(getString(glyphNames[i], buf));
      }
    } else if ((encFormat & 0x7f) == 1) {
      nRanges = *ptr++;
      nCodes = 1;
      for (i = 0; i < nRanges; ++i) {
	c = *ptr++;
	nLeft = *ptr++;
	for (j = 0; j <= nLeft && nCodes < nGlyphs; ++j) {
	  encoding[c] = copyString(getString(glyphNames[nCodes], buf));
	  ++nCodes;
	  ++c;
	}
      }
    }
    if (encFormat & 0x80) {
      nSups = *ptr++;
      for (i = 0; i < nSups; ++i) {
	c = *ptr++;
	sid = getWord(ptr, 2);
	ptr += 2;
	encoding[c] = copyString(getString(sid, buf));
      }
    }
  }

  if (charset > 2) {
    gfree(glyphNames);
  }
}

void Type1CFontFile::convertToType1(FontFileOutputFunc outputFuncA,
				    void *outputStreamA) {
  Type1CTopDict dict;
  Type1CPrivateDict privateDict;
  char buf[512], eBuf[256];
  Guchar *idxPtr0, *idxPtr1, *subrsIdxPtr, *charStringsIdxPtr, *ptr;
  int nGlyphs, nCodes, nRanges, nLeft, nSups;
  Gushort *glyphNames;
  int encFormat, nSubrs, nCharStrings;
  int c, sid;
  int i, j, n;

  outputFunc = outputFuncA;
  outputStream = outputStreamA;

  // read top dict (first font only)
  readTopDict(&dict);

  // get global subrs
  //~ ... global subrs are unimplemented

  // write header and font dictionary, up to encoding
  (*outputFunc)(outputStream, "%!FontType1-1.0: ", 17);
  (*outputFunc)(outputStream, name->getCString(), name->getLength());
  if (dict.version != 0) {
    getString(dict.version, buf);
    (*outputFunc)(outputStream, buf, strlen(buf));
  }
  (*outputFunc)(outputStream, "\n", 1);
  (*outputFunc)(outputStream, "11 dict begin\n", 14);
  (*outputFunc)(outputStream, "/FontInfo 10 dict dup begin\n", 28);
  if (dict.version != 0) {
    (*outputFunc)(outputStream, "/version (", 10);
    (*outputFunc)(outputStream, buf, strlen(buf));
    (*outputFunc)(outputStream, ") readonly def\n", 15);
  }
  if (dict.notice != 0) {
    getString(dict.notice, buf);
    (*outputFunc)(outputStream, "/Notice (", 9);
    (*outputFunc)(outputStream, buf, strlen(buf));
    (*outputFunc)(outputStream, ") readonly def\n", 15);
  }
  if (dict.copyright != 0) {
    getString(dict.copyright, buf);
    (*outputFunc)(outputStream, "/Copyright (", 12);
    (*outputFunc)(outputStream, buf, strlen(buf));
    (*outputFunc)(outputStream, ") readonly def\n", 15);
  }
  if (dict.fullName != 0) {
    getString(dict.fullName, buf);
    (*outputFunc)(outputStream, "/FullName (", 11);
    (*outputFunc)(outputStream, buf, strlen(buf));
    (*outputFunc)(outputStream, ") readonly def\n", 15);
  }
  if (dict.familyName != 0) {
    getString(dict.familyName, buf);
    (*outputFunc)(outputStream, "/FamilyName (", 13);
    (*outputFunc)(outputStream, buf, strlen(buf));
    (*outputFunc)(outputStream, ") readonly def\n", 15);
  }
  if (dict.weight != 0) {
    getString(dict.weight, buf);
    (*outputFunc)(outputStream, "/Weight (", 9);
    (*outputFunc)(outputStream, buf, strlen(buf));
    (*outputFunc)(outputStream, ") readonly def\n", 15);
  }
  if (dict.isFixedPitch) {
    (*outputFunc)(outputStream, "/isFixedPitch true def\n", 23);
  } else {
    (*outputFunc)(outputStream, "/isFixedPitch false def\n", 24);
  }
  sprintf(buf, "/ItalicAngle %g def\n", dict.italicAngle);
  (*outputFunc)(outputStream, buf, strlen(buf));
  sprintf(buf, "/UnderlinePosition %g def\n", dict.underlinePosition);
  (*outputFunc)(outputStream, buf, strlen(buf));
  sprintf(buf, "/UnderlineThickness %g def\n", dict.underlineThickness);
  (*outputFunc)(outputStream, buf, strlen(buf));
  (*outputFunc)(outputStream, "end readonly def\n", 17);
  (*outputFunc)(outputStream, "/FontName /", 11);
  (*outputFunc)(outputStream, name->getCString(), name->getLength());
  (*outputFunc)(outputStream, " def\n", 5);
  sprintf(buf, "/PaintType %d def\n", dict.paintType);
  (*outputFunc)(outputStream, buf, strlen(buf));
  (*outputFunc)(outputStream, "/FontType 1 def\n", 16);
  sprintf(buf, "/FontMatrix [%g %g %g %g %g %g] readonly def\n",
	  dict.fontMatrix[0], dict.fontMatrix[1], dict.fontMatrix[2],
	  dict.fontMatrix[3], dict.fontMatrix[4], dict.fontMatrix[5]);
  (*outputFunc)(outputStream, buf, strlen(buf));
  sprintf(buf, "/FontBBox [%g %g %g %g] readonly def\n",
	  dict.fontBBox[0], dict.fontBBox[1],
	  dict.fontBBox[2], dict.fontBBox[3]);
  (*outputFunc)(outputStream, buf, strlen(buf));
  sprintf(buf, "/StrokeWidth %g def\n", dict.strokeWidth);
  (*outputFunc)(outputStream, buf, strlen(buf));
  if (dict.uniqueID != 0) {
    sprintf(buf, "/UniqueID %d def\n", dict.uniqueID);
    (*outputFunc)(outputStream, buf, strlen(buf));
  }

  // get number of glyphs from charstrings index
  nGlyphs = getIndexLen((Guchar *)file + dict.charStrings);

  // read charset
  glyphNames = readCharset(dict.charset, nGlyphs);

  // read encoding (glyph -> code mapping), write Type 1 encoding
  (*outputFunc)(outputStream, "/Encoding ", 10);
  if (dict.encoding == 0) {
    (*outputFunc)(outputStream, "StandardEncoding def\n", 21);
  } else {
    (*outputFunc)(outputStream, "256 array\n", 10);
    (*outputFunc)(outputStream,
		  "0 1 255 {1 index exch /.notdef put} for\n", 40);
    if (dict.encoding == 1) {
      for (i = 0; i < 256; ++i) {
	if (expertEncoding[i]) {
	  sprintf(buf, "dup %d /%s put\n", i, expertEncoding[i]);
	  (*outputFunc)(outputStream, buf, strlen(buf));
	}
      }
    } else {
      ptr = (Guchar *)file + dict.encoding;
      encFormat = *ptr++;
      if ((encFormat & 0x7f) == 0) {
	nCodes = 1 + *ptr++;
	if (nCodes > nGlyphs) {
	  nCodes = nGlyphs;
	}
	for (i = 1; i < nCodes; ++i) {
	  c = *ptr++;
	  sprintf(buf, "dup %d /", c);
	  (*outputFunc)(outputStream, buf, strlen(buf));
	  getString(glyphNames[i], buf);
	  (*outputFunc)(outputStream, buf, strlen(buf));
	  (*outputFunc)(outputStream, " put\n", 5);
	}
      } else if ((encFormat & 0x7f) == 1) {
	nRanges = *ptr++;
	nCodes = 1;
	for (i = 0; i < nRanges; ++i) {
	  c = *ptr++;
	  nLeft = *ptr++;
	  for (j = 0; j <= nLeft && nCodes < nGlyphs; ++j) {
	    sprintf(buf, "dup %d /", c);
	    (*outputFunc)(outputStream, buf, strlen(buf));
	    getString(glyphNames[nCodes], buf);
	    (*outputFunc)(outputStream, buf, strlen(buf));
	    (*outputFunc)(outputStream, " put\n", 5);
	    ++nCodes;
	    ++c;
	  }
	}
      }
      if (encFormat & 0x80) {
	nSups = *ptr++;
	for (i = 0; i < nSups; ++i) {
	  c = *ptr++;
	  sid = getWord(ptr, 2);
	  ptr += 2;
	  sprintf(buf, "dup %d /", c);
	  (*outputFunc)(outputStream, buf, strlen(buf));
	  getString(sid, buf);
	  (*outputFunc)(outputStream, buf, strlen(buf));
	  (*outputFunc)(outputStream, " put\n", 5);
	}
      }
    }
    (*outputFunc)(outputStream, "readonly def\n", 13);
  }
  (*outputFunc)(outputStream, "currentdict end\n", 16);

  // start the binary section
  (*outputFunc)(outputStream, "currentfile eexec\n", 18);
  r1 = 55665;
  line = 0;

  // get private dictionary
  eexecWrite("\x83\xca\x73\xd5");
  eexecWrite("dup /Private 32 dict dup begin\n");
  eexecWrite("/RD {string currentfile exch readstring pop} executeonly def\n");
  eexecWrite("/ND {noaccess def} executeonly def\n");
  eexecWrite("/NP {noaccess put} executeonly def\n");
  eexecWrite("/MinFeature {16 16} ND\n");
  readPrivateDict(&privateDict, dict.privateOffset, dict.privateSize);
  eexecWrite(privateDict.dictData->getCString());
  defaultWidthX = privateDict.defaultWidthX;
  defaultWidthXFP = privateDict.defaultWidthXFP;
  nominalWidthX = privateDict.nominalWidthX;
  nominalWidthXFP = privateDict.nominalWidthXFP;

  // get subrs
  if (privateDict.subrsOffset != 0) {
    subrsIdxPtr = (Guchar *)file + dict.privateOffset +
                  privateDict.subrsOffset;
    nSubrs = getIndexLen(subrsIdxPtr);
    sprintf(eBuf, "/Subrs %d array\n", nSubrs);
    eexecWrite(eBuf);
    idxPtr1 = getIndexValPtr(subrsIdxPtr, 0);
    for (i = 0; i < nSubrs; ++i) {
      idxPtr0 = idxPtr1;
      idxPtr1 = getIndexValPtr(subrsIdxPtr, i+1);
      n = idxPtr1 - idxPtr0;
#if 1 //~ Type 2 subrs are unimplemented
      error(-1, "Unimplemented Type 2 subrs");
#else
      sprintf(eBuf, "dup %d %d RD ", i, n);
      eexecWrite(eBuf);
      eexecCvtGlyph(idxPtr0, n);
      eexecWrite(" NP\n");
#endif
    }
    eexecWrite("ND\n");
  }

  // get CharStrings
  charStringsIdxPtr = (Guchar *)file + dict.charStrings;
  nCharStrings = getIndexLen(charStringsIdxPtr);
  sprintf(eBuf, "2 index /CharStrings %d dict dup begin\n", nCharStrings);
  eexecWrite(eBuf);
  idxPtr1 = getIndexValPtr(charStringsIdxPtr, 0);
  for (i = 0; i < nCharStrings; ++i) {
    idxPtr0 = idxPtr1;
    idxPtr1 = getIndexValPtr(charStringsIdxPtr, i+1);
    n = idxPtr1 - idxPtr0;
    eexecCvtGlyph(getString(glyphNames[i], buf), idxPtr0, n);
  }
  eexecWrite("end\n");
  eexecWrite("end\n");
  eexecWrite("readonly put\n");
  eexecWrite("noaccess put\n");
  eexecWrite("dup /FontName get exch definefont pop\n");
  eexecWrite("mark currentfile closefile\n");

  // trailer
  if (line > 0) {
    (*outputFunc)(outputStream, "\n", 1);
  }
  for (i = 0; i < 8; ++i) {
    (*outputFunc)(outputStream, "0000000000000000000000000000000000000000000000000000000000000000\n", 65);
  }
  (*outputFunc)(outputStream, "cleartomark\n", 12);

  // clean up
  delete privateDict.dictData;
  if (dict.charset > 2) {
    gfree(glyphNames);
  }
}

void Type1CFontFile::convertToCIDType0(char *psName,
				       FontFileOutputFunc outputFuncA,
				       void *outputStreamA) {
  Type1CTopDict dict;
  Type1CPrivateDict *privateDicts;
  GString *charStrings;
  int *charStringOffsets;
  Gushort *charset;
  int *cidMap;
  Guchar *fdSelect;
  Guchar *charStringsIdxPtr, *fdArrayIdx, *idxPtr0, *idxPtr1, *ptr;
  char buf[512], buf2[16];
  int nGlyphs, nCIDs, gdBytes, nFDs;
  int fdSelectFmt, nRanges, gid0, gid1, fd, offset;
  int key;
  double x;
  GBool isFP;
  int i, j, k, n;

  outputFunc = outputFuncA;
  outputStream = outputStreamA;

  (*outputFunc)(outputStream, "/CIDInit /ProcSet findresource begin\n", 37);

  // read top dict (first font only)
  readTopDict(&dict);

  // read the FDArray dictionaries and Private dictionaries
  if (dict.fdArrayOffset == 0) {
    nFDs = 1;
    privateDicts = (Type1CPrivateDict *)
                     gmalloc(nFDs * sizeof(Type1CPrivateDict));
    privateDicts[0].dictData = new GString();
    privateDicts[0].subrsOffset = 0;
    privateDicts[0].defaultWidthX = 0;
    privateDicts[0].defaultWidthXFP = gFalse;
    privateDicts[0].nominalWidthX = 0;
    privateDicts[0].nominalWidthXFP = gFalse;
  } else {
    fdArrayIdx = (Guchar *)file + dict.fdArrayOffset;
    nFDs = getIndexLen(fdArrayIdx);
    privateDicts = (Type1CPrivateDict *)
                     gmalloc(nFDs * sizeof(Type1CPrivateDict));
    idxPtr1 = getIndexValPtr(fdArrayIdx, 0);
    for (i = 0; i < nFDs; ++i) {
      privateDicts[i].dictData = NULL;
      idxPtr0 = idxPtr1;
      idxPtr1 = getIndexValPtr(fdArrayIdx, i + 1);
      ptr = idxPtr0;
      j = 0;
      while (ptr < idxPtr1) {
	if (*ptr <= 27 || *ptr == 31) {
	  key = *ptr++;
	  if (key == 0x0c) {
	    key = (key << 8) | *ptr++;
	  }
	  if (key == 0x0012) {
	    readPrivateDict(&privateDicts[i], (int)op[1], (int)op[0]);
	  }
	  j = 0;
	} else {
	  x = getNum(&ptr, &isFP);
	  if (j < 48) {
	    op[j] = x;
	    fp[j++] = isFP;
	  }
	}
      }
      if (!privateDicts[i].dictData) {
	privateDicts[i].dictData = new GString();
	privateDicts[i].subrsOffset = 0;
	privateDicts[i].defaultWidthX = 0;
	privateDicts[i].defaultWidthXFP = gFalse;
	privateDicts[i].nominalWidthX = 0;
	privateDicts[i].nominalWidthXFP = gFalse;
      }
    }
  }

  // get the glyph count
  charStringsIdxPtr = (Guchar *)file + dict.charStrings;
  nGlyphs = getIndexLen(charStringsIdxPtr);

  // read the FDSelect table
  fdSelect = (Guchar *)gmalloc(nGlyphs);
  if (dict.fdSelectOffset == 0) {
    for (i = 0; i < nGlyphs; ++i) {
      fdSelect[i] = 0;
    }
  } else {
    ptr = (Guchar *)file + dict.fdSelectOffset;
    fdSelectFmt = *ptr++;
    if (fdSelectFmt == 0) {
      memcpy(fdSelect, ptr, nGlyphs);
    } else if (fdSelectFmt == 3) {
      nRanges = getWord(ptr, 2);
      ptr += 2;
      gid0 = getWord(ptr, 2);
      ptr += 2;
      for (i = 1; i <= nRanges; ++i) {
	fd = *ptr++;
	gid1 = getWord(ptr, 2);
	ptr += 2;
	for (j = gid0; j < gid1; ++j) {
	  fdSelect[j] = fd;
	}
	gid0 = gid1;
      }
    } else {
      error(-1, "Unknown FDSelect table format in CID font");
      for (i = 0; i < nGlyphs; ++i) {
	fdSelect[i] = 0;
      }
    }
  }

  // read the charset, compute the CID-to-GID mapping
  charset = readCharset(dict.charset, nGlyphs);
  nCIDs = 0;
  for (i = 0; i < nGlyphs; ++i) {
    if (charset[i] >= nCIDs) {
      nCIDs = charset[i] + 1;
    }
  }
  cidMap = (int *)gmalloc(nCIDs * sizeof(int));
  for (i = 0; i < nCIDs; ++i) {
    cidMap[i] = -1;
  }
  for (i = 0; i < nGlyphs; ++i) {
    cidMap[charset[i]] = i;
  }

  // build the charstrings
  charStrings = new GString();
  charStringOffsets = (int *)gmalloc((nCIDs + 1) * sizeof(int));
  for (i = 0; i < nCIDs; ++i) {
    charStringOffsets[i] = charStrings->getLength();
    if (cidMap[i] >= 0) {
      idxPtr0 = getIndexValPtr(charStringsIdxPtr, cidMap[i]);
      idxPtr1 = getIndexValPtr(charStringsIdxPtr, cidMap[i]+1);
      n = idxPtr1 - idxPtr0;
      j = fdSelect[cidMap[i]];
      defaultWidthX = privateDicts[j].defaultWidthX;
      defaultWidthXFP = privateDicts[j].defaultWidthXFP;
      nominalWidthX = privateDicts[j].nominalWidthX;
      nominalWidthXFP = privateDicts[j].nominalWidthXFP;
      cvtGlyph(idxPtr0, n);
      charStrings->append(charBuf);
      delete charBuf;
    }
  }
  charStringOffsets[nCIDs] = charStrings->getLength();

  // compute gdBytes = number of bytes needed for charstring offsets
  // (offset size needs to account for the charstring offset table,
  // with a worst case of five bytes per entry, plus the charstrings
  // themselves)
  i = (nCIDs + 1) * 5 + charStrings->getLength();
  if (i < 0x100) {
    gdBytes = 1;
  } else if (i < 0x10000) {
    gdBytes = 2;
  } else if (i < 0x1000000) {
    gdBytes = 3;
  } else {
    gdBytes = 4;
  }

  // begin the font dictionary
  (*outputFunc)(outputStream, "20 dict begin\n", 14);
  (*outputFunc)(outputStream, "/CIDFontName /", 14);
  (*outputFunc)(outputStream, psName, strlen(psName));
  (*outputFunc)(outputStream, " def\n", 5);
  (*outputFunc)(outputStream, "/CIDFontType 0 def\n", 19);
  (*outputFunc)(outputStream, "/CIDSystemInfo 3 dict dup begin\n", 32);
  if (dict.registry > 0 && dict.ordering > 0) {
    getString(dict.registry, buf);
    (*outputFunc)(outputStream, "  /Registry (", 13);
    (*outputFunc)(outputStream, buf, strlen(buf));
    (*outputFunc)(outputStream, ") def\n", 6);
    getString(dict.ordering, buf);
    (*outputFunc)(outputStream, "  /Ordering (", 13);
    (*outputFunc)(outputStream, buf, strlen(buf));
    (*outputFunc)(outputStream, ") def\n", 6);
  } else {
    (*outputFunc)(outputStream, "  /Registry (Adobe) def\n", 24);
    (*outputFunc)(outputStream, "  /Ordering (Identity) def\n", 27);
  }
  sprintf(buf, "  /Supplement %d def\n", dict.supplement);
  (*outputFunc)(outputStream, buf, strlen(buf));
  (*outputFunc)(outputStream, "end def\n", 8);
  sprintf(buf, "/FontMatrix [%g %g %g %g %g %g] def\n",
	  dict.fontMatrix[0], dict.fontMatrix[1], dict.fontMatrix[2],
	  dict.fontMatrix[3], dict.fontMatrix[4], dict.fontMatrix[5]);
  (*outputFunc)(outputStream, buf, strlen(buf));
  sprintf(buf, "/FontBBox [%g %g %g %g] def\n",
	  dict.fontBBox[0], dict.fontBBox[1],
	  dict.fontBBox[2], dict.fontBBox[3]);
  (*outputFunc)(outputStream, buf, strlen(buf));
  (*outputFunc)(outputStream, "/FontInfo 1 dict dup begin\n", 27);
  (*outputFunc)(outputStream, "  /FSType 8 def\n", 16);
  (*outputFunc)(outputStream, "end def\n", 8);

  // CIDFont-specific entries
  sprintf(buf, "/CIDCount %d def\n", nCIDs);
  (*outputFunc)(outputStream, buf, strlen(buf));
  (*outputFunc)(outputStream, "/FDBytes 1 def\n", 15);
  sprintf(buf, "/GDBytes %d def\n", gdBytes);
  (*outputFunc)(outputStream, buf, strlen(buf));
  (*outputFunc)(outputStream, "/CIDMapOffset 0 def\n", 20);
  if (dict.paintType != 0) {
    sprintf(buf, "/PaintType %d def\n", dict.paintType);
    (*outputFunc)(outputStream, buf, strlen(buf));
    sprintf(buf, "/StrokeWidth %g def\n", dict.strokeWidth);
    (*outputFunc)(outputStream, buf, strlen(buf));
  }

  // FDArray entry
  sprintf(buf, "/FDArray %d array\n", nFDs);
  (*outputFunc)(outputStream, buf, strlen(buf));
  for (i = 0; i < nFDs; ++i) {
    sprintf(buf, "dup %d 10 dict begin\n", i);
    (*outputFunc)(outputStream, buf, strlen(buf));
    (*outputFunc)(outputStream, "/FontType 1 def\n", 16);
    (*outputFunc)(outputStream, "/FontMatrix [1 0 0 1 0 0] def\n", 30);
    sprintf(buf, "/PaintType %d def\n", dict.paintType);
    (*outputFunc)(outputStream, buf, strlen(buf));
    (*outputFunc)(outputStream, "/Private 32 dict begin\n", 23);
    (*outputFunc)(outputStream, privateDicts[i].dictData->getCString(),
		  privateDicts[i].dictData->getLength());
    (*outputFunc)(outputStream, "currentdict end def\n", 20);
    (*outputFunc)(outputStream, "currentdict end put\n", 20);
  }
  (*outputFunc)(outputStream, "def\n", 4);

  //~ need to deal with subrs
  
  // start the binary section
  offset = (nCIDs + 1) * (1 + gdBytes);
  sprintf(buf, "(Hex) %d StartData\n",
	  offset + charStrings->getLength());
  (*outputFunc)(outputStream, buf, strlen(buf));

  // write the charstring offset (CIDMap) table
  for (i = 0; i <= nCIDs; i += 6) {
    for (j = 0; j < 6 && i+j <= nCIDs; ++j) {
      if (i+j < nCIDs && cidMap[i+j] >= 0) {
	buf[0] = (char)fdSelect[cidMap[i+j]];
      } else {
	buf[0] = (char)0;
      }
      n = offset + charStringOffsets[i+j];
      for (k = gdBytes; k >= 1; --k) {
	buf[k] = (char)(n & 0xff);
	n >>= 8;
      }
      for (k = 0; k <= gdBytes; ++k) {
	sprintf(buf2, "%02x", buf[k] & 0xff);
	(*outputFunc)(outputStream, buf2, 2);
      }
    }
    (*outputFunc)(outputStream, "\n", 1);
  }

  // write the charstring data
  n = charStrings->getLength();
  for (i = 0; i < n; i += 32) {
    for (j = 0; j < 32 && i+j < n; ++j) {
      sprintf(buf, "%02x", charStrings->getChar(i+j) & 0xff);
      (*outputFunc)(outputStream, buf, strlen(buf));
    }
    if (i + 32 >= n) {
      (*outputFunc)(outputStream, ">", 1);
    }
    (*outputFunc)(outputStream, "\n", 1);
  }

  for (i = 0; i < nFDs; ++i) {
    delete privateDicts[i].dictData;
  }
  gfree(privateDicts);
  gfree(cidMap);
  gfree(charset);
  gfree(charStringOffsets);
  delete charStrings;
  gfree(fdSelect);
}

void Type1CFontFile::convertToType0(char *psName,
				    FontFileOutputFunc outputFuncA,
				    void *outputStreamA) {
  Type1CTopDict dict;
  Type1CPrivateDict *privateDicts;
  Gushort *charset;
  int *cidMap;
  Guchar *fdSelect;
  Guchar *charStringsIdxPtr, *fdArrayIdx, *idxPtr0, *idxPtr1, *ptr;
  char buf[512];
  char eBuf[256];
  int nGlyphs, nCIDs, nFDs;
  int fdSelectFmt, nRanges, gid0, gid1, fd;
  int key;
  double x;
  GBool isFP;
  int i, j, n;

  outputFunc = outputFuncA;
  outputStream = outputStreamA;

  // read top dict (first font only)
  readTopDict(&dict);

  // read the FDArray dictionaries and Private dictionaries
  if (dict.fdArrayOffset == 0) {
    nFDs = 1;
    privateDicts = (Type1CPrivateDict *)
                     gmalloc(nFDs * sizeof(Type1CPrivateDict));
    privateDicts[0].dictData = new GString();
    privateDicts[0].subrsOffset = 0;
    privateDicts[0].defaultWidthX = 0;
    privateDicts[0].defaultWidthXFP = gFalse;
    privateDicts[0].nominalWidthX = 0;
    privateDicts[0].nominalWidthXFP = gFalse;
  } else {
    fdArrayIdx = (Guchar *)file + dict.fdArrayOffset;
    nFDs = getIndexLen(fdArrayIdx);
    privateDicts = (Type1CPrivateDict *)
                     gmalloc(nFDs * sizeof(Type1CPrivateDict));
    idxPtr1 = getIndexValPtr(fdArrayIdx, 0);
    for (i = 0; i < nFDs; ++i) {
      privateDicts[i].dictData = NULL;
      idxPtr0 = idxPtr1;
      idxPtr1 = getIndexValPtr(fdArrayIdx, i + 1);
      ptr = idxPtr0;
      j = 0;
      while (ptr < idxPtr1) {
	if (*ptr <= 27 || *ptr == 31) {
	  key = *ptr++;
	  if (key == 0x0c) {
	    key = (key << 8) | *ptr++;
	  }
	  if (key == 0x0012) {
	    readPrivateDict(&privateDicts[i], (int)op[1], (int)op[0]);
	  }
	  j = 0;
	} else {
	  x = getNum(&ptr, &isFP);
	  if (j < 48) {
	    op[j] = x;
	    fp[j++] = isFP;
	  }
	}
      }
      if (!privateDicts[i].dictData) {
	privateDicts[i].dictData = new GString();
	privateDicts[i].subrsOffset = 0;
	privateDicts[i].defaultWidthX = 0;
	privateDicts[i].defaultWidthXFP = gFalse;
	privateDicts[i].nominalWidthX = 0;
	privateDicts[i].nominalWidthXFP = gFalse;
      }
    }
  }

  // get the glyph count
  charStringsIdxPtr = (Guchar *)file + dict.charStrings;
  nGlyphs = getIndexLen(charStringsIdxPtr);

  // read the FDSelect table
  fdSelect = (Guchar *)gmalloc(nGlyphs);
  if (dict.fdSelectOffset == 0) {
    for (i = 0; i < nGlyphs; ++i) {
      fdSelect[i] = 0;
    }
  } else {
    ptr = (Guchar *)file + dict.fdSelectOffset;
    fdSelectFmt = *ptr++;
    if (fdSelectFmt == 0) {
      memcpy(fdSelect, ptr, nGlyphs);
    } else if (fdSelectFmt == 3) {
      nRanges = getWord(ptr, 2);
      ptr += 2;
      gid0 = getWord(ptr, 2);
      ptr += 2;
      for (i = 1; i <= nRanges; ++i) {
	fd = *ptr++;
	gid1 = getWord(ptr, 2);
	ptr += 2;
	for (j = gid0; j < gid1; ++j) {
	  fdSelect[j] = fd;
	}
	gid0 = gid1;
      }
    } else {
      error(-1, "Unknown FDSelect table format in CID font");
      for (i = 0; i < nGlyphs; ++i) {
	fdSelect[i] = 0;
      }
    }
  }

  // read the charset, compute the CID-to-GID mapping
  charset = readCharset(dict.charset, nGlyphs);
  nCIDs = 0;
  for (i = 0; i < nGlyphs; ++i) {
    if (charset[i] >= nCIDs) {
      nCIDs = charset[i] + 1;
    }
  }
  cidMap = (int *)gmalloc(nCIDs * sizeof(int));
  for (i = 0; i < nCIDs; ++i) {
    cidMap[i] = -1;
  }
  for (i = 0; i < nGlyphs; ++i) {
    cidMap[charset[i]] = i;
  }

  // write the descendant Type 1 fonts
  for (i = 0; i < nCIDs; i += 256) {

    //~ this assumes that all CIDs in this block have the same FD --
    //~ to handle multiple FDs correctly, need to somehow divide the
    //~ font up by FD
    fd = 0;
    for (j = 0; j < 256 && i+j < nCIDs; ++j) {
      if (cidMap[i+j] >= 0) {
	fd = fdSelect[cidMap[i+j]];
	break;
      }
    }

    // font dictionary (unencrypted section)
    (*outputFunc)(outputStream, "16 dict begin\n", 14);
    (*outputFunc)(outputStream, "/FontName /", 11);
    (*outputFunc)(outputStream, psName, strlen(psName));
    sprintf(buf, "_%02x def\n", i >> 8);
    (*outputFunc)(outputStream, buf, strlen(buf));
    (*outputFunc)(outputStream, "/FontType 1 def\n", 16);
    sprintf(buf, "/FontMatrix [%g %g %g %g %g %g] def\n",
	    dict.fontMatrix[0], dict.fontMatrix[1], dict.fontMatrix[2],
	    dict.fontMatrix[3], dict.fontMatrix[4], dict.fontMatrix[5]);
    (*outputFunc)(outputStream, buf, strlen(buf));
    sprintf(buf, "/FontBBox [%g %g %g %g] def\n",
	    dict.fontBBox[0], dict.fontBBox[1],
	    dict.fontBBox[2], dict.fontBBox[3]);
    (*outputFunc)(outputStream, buf, strlen(buf));
    sprintf(buf, "/PaintType %d def\n", dict.paintType);
    (*outputFunc)(outputStream, buf, strlen(buf));
    if (dict.paintType != 0) {
      sprintf(buf, "/StrokeWidth %g def\n", dict.strokeWidth);
      (*outputFunc)(outputStream, buf, strlen(buf));
    }
    (*outputFunc)(outputStream, "/Encoding 256 array\n", 20);
    for (j = 0; j < 256 && i+j < nCIDs; ++j) {
      sprintf(buf, "dup %d /c%02x put\n", j, j);
      (*outputFunc)(outputStream, buf, strlen(buf));
    }
    (*outputFunc)(outputStream, "readonly def\n", 13);
    (*outputFunc)(outputStream, "currentdict end\n", 16);

    // start the binary section
    (*outputFunc)(outputStream, "currentfile eexec\n", 18);
    r1 = 55665;
    line = 0;

    // start the private dictionary
    eexecWrite("\x83\xca\x73\xd5");
    eexecWrite("dup /Private 32 dict dup begin\n");
    eexecWrite("/RD {string currentfile exch readstring pop} executeonly def\n");
    eexecWrite("/ND {noaccess def} executeonly def\n");
    eexecWrite("/NP {noaccess put} executeonly def\n");
    eexecWrite("/MinFeature {16 16} ND\n");
    eexecWrite(privateDicts[fd].dictData->getCString());
    defaultWidthX = privateDicts[fd].defaultWidthX;
    defaultWidthXFP = privateDicts[fd].defaultWidthXFP;
    nominalWidthX = privateDicts[fd].nominalWidthX;
    nominalWidthXFP = privateDicts[fd].nominalWidthXFP;

    // start the CharStrings
    sprintf(eBuf, "2 index /CharStrings 256 dict dup begin\n");
    eexecWrite(eBuf);

    // write the .notdef CharString
    idxPtr0 = getIndexValPtr(charStringsIdxPtr, 0);
    idxPtr1 = getIndexValPtr(charStringsIdxPtr, 1);
    n = idxPtr1 - idxPtr0;
    eexecCvtGlyph(".notdef", idxPtr0, n);

    // write the CharStrings
    for (j = 0; j < 256 && i+j < nCIDs; ++j) {
      if (cidMap[i+j] >= 0) {
	idxPtr0 = getIndexValPtr(charStringsIdxPtr, cidMap[i+j]);
	idxPtr1 = getIndexValPtr(charStringsIdxPtr, cidMap[i+j]+1);
	n = idxPtr1 - idxPtr0;
	sprintf(buf, "c%02x", j);
	eexecCvtGlyph(buf, idxPtr0, n);
      }
    }
    eexecWrite("end\n");
    eexecWrite("end\n");
    eexecWrite("readonly put\n");
    eexecWrite("noaccess put\n");
    eexecWrite("dup /FontName get exch definefont pop\n");
    eexecWrite("mark currentfile closefile\n");

    // trailer
    if (line > 0) {
      (*outputFunc)(outputStream, "\n", 1);
    }
    for (j = 0; j < 8; ++j) {
      (*outputFunc)(outputStream, "0000000000000000000000000000000000000000000000000000000000000000\n", 65);
    }
    (*outputFunc)(outputStream, "cleartomark\n", 12);
  }

  // write the Type 0 parent font
  (*outputFunc)(outputStream, "16 dict begin\n", 14);
  (*outputFunc)(outputStream, "/FontName /", 11);
  (*outputFunc)(outputStream, psName, strlen(psName));
  (*outputFunc)(outputStream, " def\n", 5);
  (*outputFunc)(outputStream, "/FontType 0 def\n", 16);
  (*outputFunc)(outputStream, "/FontMatrix [1 0 0 1 0 0] def\n", 30);
  (*outputFunc)(outputStream, "/FMapType 2 def\n", 16);
  (*outputFunc)(outputStream, "/Encoding [\n", 12);
  for (i = 0; i < nCIDs; i += 256) {
    sprintf(buf, "%d\n", i >> 8);
    (*outputFunc)(outputStream, buf, strlen(buf));
  }
  (*outputFunc)(outputStream, "] def\n", 6);
  (*outputFunc)(outputStream, "/FDepVector [\n", 14);
  for (i = 0; i < nCIDs; i += 256) {
    (*outputFunc)(outputStream, "/", 1);
    (*outputFunc)(outputStream, psName, strlen(psName));
    sprintf(buf, "_%02x findfont\n", i >> 8);
    (*outputFunc)(outputStream, buf, strlen(buf));
  }
  (*outputFunc)(outputStream, "] def\n", 6);
  (*outputFunc)(outputStream, "FontName currentdict end definefont pop\n", 40);

  // clean up
  for (i = 0; i < nFDs; ++i) {
    delete privateDicts[i].dictData;
  }
  gfree(privateDicts);
  gfree(cidMap);
  gfree(charset);
  gfree(fdSelect);
}

void Type1CFontFile::readTopDict(Type1CTopDict *dict) {
  Guchar *idxPtr0, *idxPtr1, *ptr;
  double x;
  GBool isFP;
  int key;
  int i;

  idxPtr0 = getIndexValPtr(topDictIdxPtr, 0);
  idxPtr1 = getIndexValPtr(topDictIdxPtr, 1);
  dict->version = 0;
  dict->notice = 0;
  dict->copyright = 0;
  dict->fullName = 0;
  dict->familyName = 0;
  dict->weight = 0;
  dict->isFixedPitch = 0;
  dict->italicAngle = 0;
  dict->underlinePosition = -100;
  dict->underlineThickness = 50;
  dict->paintType = 0;
  dict->charstringType = 2;
  dict->fontMatrix[0] = 0.001;
  dict->fontMatrix[1] = 0;
  dict->fontMatrix[2] = 0;
  dict->fontMatrix[3] = 0.001;
  dict->fontMatrix[4] = 0;
  dict->fontMatrix[5] = 0;
  dict->uniqueID = 0;
  dict->fontBBox[0] = 0;
  dict->fontBBox[1] = 0;
  dict->fontBBox[2] = 0;
  dict->fontBBox[3] = 0;
  dict->strokeWidth = 0;
  dict->charset = 0;
  dict->encoding = 0;
  dict->charStrings = 0;
  dict->privateSize = 0;
  dict->privateOffset = 0;
  dict->registry = 0;
  dict->ordering = 0;
  dict->supplement = 0;
  dict->fdArrayOffset = 0;
  dict->fdSelectOffset = 0;
  i = 0;
  ptr = idxPtr0;
  while (ptr < idxPtr1) {
    if (*ptr <= 27 || *ptr == 31) {
      key = *ptr++;
      if (key == 0x0c) {
	key = (key << 8) | *ptr++;
      }
      switch (key) {
      case 0x0000: dict->version = (int)op[0]; break;
      case 0x0001: dict->notice = (int)op[0]; break;
      case 0x0c00: dict->copyright = (int)op[0]; break;
      case 0x0002: dict->fullName = (int)op[0]; break;
      case 0x0003: dict->familyName = (int)op[0]; break;
      case 0x0004: dict->weight = (int)op[0]; break;
      case 0x0c01: dict->isFixedPitch = (int)op[0]; break;
      case 0x0c02: dict->italicAngle = op[0]; break;
      case 0x0c03: dict->underlinePosition = op[0]; break;
      case 0x0c04: dict->underlineThickness = op[0]; break;
      case 0x0c05: dict->paintType = (int)op[0]; break;
      case 0x0c06: dict->charstringType = (int)op[0]; break;
      case 0x0c07: dict->fontMatrix[0] = op[0];
	           dict->fontMatrix[1] = op[1];
	           dict->fontMatrix[2] = op[2];
	           dict->fontMatrix[3] = op[3];
	           dict->fontMatrix[4] = op[4];
	           dict->fontMatrix[5] = op[5]; break;
      case 0x000d: dict->uniqueID = (int)op[0]; break;
      case 0x0005: dict->fontBBox[0] = op[0];
	           dict->fontBBox[1] = op[1];
	           dict->fontBBox[2] = op[2];
	           dict->fontBBox[3] = op[3]; break;
      case 0x0c08: dict->strokeWidth = op[0]; break;
      case 0x000f: dict->charset = (int)op[0]; break;
      case 0x0010: dict->encoding = (int)op[0]; break;
      case 0x0011: dict->charStrings = (int)op[0]; break;
      case 0x0012: dict->privateSize = (int)op[0];
	           dict->privateOffset = (int)op[1]; break;
      case 0x0c1e: dict->registry = (int)op[0];
	           dict->ordering = (int)op[1];
		   dict->supplement = (int)op[2]; break;
      case 0x0c24: dict->fdArrayOffset = (int)op[0]; break;
      case 0x0c25: dict->fdSelectOffset = (int)op[0]; break;
      }
      i = 0;
    } else {
      x = getNum(&ptr, &isFP);
      if (i < 48) {
	op[i] = x;
	fp[i++] = isFP;
      }
    }
  }
}

void Type1CFontFile::readPrivateDict(Type1CPrivateDict *privateDict,
				     int offset, int size) {
  Guchar *idxPtr0, *idxPtr1, *ptr;
  char eBuf[256];
  int key;
  double x;
  GBool isFP;
  int i;

  privateDict->dictData = new GString();
  privateDict->subrsOffset = 0;
  privateDict->defaultWidthX = 0;
  privateDict->defaultWidthXFP = gFalse;
  privateDict->nominalWidthX = 0;
  privateDict->nominalWidthXFP = gFalse;
  idxPtr0 = (Guchar *)file + offset;
  idxPtr1 = idxPtr0 + size;
  ptr = idxPtr0;
  i = 0;
  while (ptr < idxPtr1) {
    if (*ptr <= 27 || *ptr == 31) {
      key = *ptr++;
      if (key == 0x0c) {
	key = (key << 8) | *ptr++;
      }
      switch (key) {
      case 0x0006:
	getDeltaInt(eBuf, "BlueValues", op, i);
	privateDict->dictData->append(eBuf);
	break;
      case 0x0007:
	getDeltaInt(eBuf, "OtherBlues", op, i);
	privateDict->dictData->append(eBuf);
	break;
      case 0x0008:
	getDeltaInt(eBuf, "FamilyBlues", op, i);
	privateDict->dictData->append(eBuf);
	break;
      case 0x0009:
	getDeltaInt(eBuf, "FamilyOtherBlues", op, i);
	privateDict->dictData->append(eBuf);
	break;
      case 0x0c09:
	sprintf(eBuf, "/BlueScale %g def\n", op[0]);
	privateDict->dictData->append(eBuf);
	break;
      case 0x0c0a:
	sprintf(eBuf, "/BlueShift %d def\n", (int)op[0]);
	privateDict->dictData->append(eBuf);
	break;
      case 0x0c0b:
	sprintf(eBuf, "/BlueFuzz %d def\n", (int)op[0]);
	privateDict->dictData->append(eBuf);
	break;
      case 0x000a:
	sprintf(eBuf, "/StdHW [%g] def\n", op[0]);
	privateDict->dictData->append(eBuf);
	break;
      case 0x000b:
	sprintf(eBuf, "/StdVW [%g] def\n", op[0]);
	privateDict->dictData->append(eBuf);
	break;
      case 0x0c0c:
	getDeltaReal(eBuf, "StemSnapH", op, i);
	privateDict->dictData->append(eBuf);
	break;
      case 0x0c0d:
	getDeltaReal(eBuf, "StemSnapV", op, i);
	privateDict->dictData->append(eBuf);
	break;
      case 0x0c0e:
	sprintf(eBuf, "/ForceBold %s def\n", op[0] ? "true" : "false");
	privateDict->dictData->append(eBuf);
	break;
      case 0x0c0f:
	sprintf(eBuf, "/ForceBoldThreshold %g def\n", op[0]);
	privateDict->dictData->append(eBuf);
	break;
      case 0x0c11:
	sprintf(eBuf, "/LanguageGroup %d def\n", (int)op[0]);
	privateDict->dictData->append(eBuf);
	break;
      case 0x0c12:
	sprintf(eBuf, "/ExpansionFactor %g def\n", op[0]);
	privateDict->dictData->append(eBuf);
	break;
      case 0x0c13:
	error(-1, "Got Type 1C InitialRandomSeed");
	break;
      case 0x0013:
	privateDict->subrsOffset = (int)op[0];
	break;
      case 0x0014:
	privateDict->defaultWidthX = op[0];
	privateDict->defaultWidthXFP = fp[0];
	break;
      case 0x0015:
	privateDict->nominalWidthX = op[0];
	privateDict->nominalWidthXFP = fp[0];
	break;
      default:
	error(-1, "Unknown Type 1C private dict entry %04x", key);
	break;
      }
      i = 0;
    } else {
      x = getNum(&ptr, &isFP);
      if (i < 48) {
	op[i] = x;
	fp[i++] = isFP;
      }
    }
  }
}

Gushort *Type1CFontFile::readCharset(int charset, int nGlyphs) {
  Gushort *glyphNames;
  Guchar *ptr;
  int charsetFormat, c;
  int nLeft, i, j;

  if (charset == 0) {
    glyphNames = type1CISOAdobeCharset;
  } else if (charset == 1) {
    glyphNames = type1CExpertCharset;
  } else if (charset == 2) {
    glyphNames = type1CExpertSubsetCharset;
  } else {
    glyphNames = (Gushort *)gmalloc(nGlyphs * sizeof(Gushort));
    glyphNames[0] = 0;
    ptr = (Guchar *)file + charset;
    charsetFormat = *ptr++;
    if (charsetFormat == 0) {
      for (i = 1; i < nGlyphs; ++i) {
	glyphNames[i] = getWord(ptr, 2);
	ptr += 2;
      }
    } else if (charsetFormat == 1) {
      i = 1;
      while (i < nGlyphs) {
	c = getWord(ptr, 2);
	ptr += 2;
	nLeft = *ptr++;
	for (j = 0; j <= nLeft && i < nGlyphs; ++j) {
	  glyphNames[i++] = c++;
	}
      }
    } else if (charsetFormat == 2) {
      i = 1;
      while (i < nGlyphs) {
	c = getWord(ptr, 2);
	ptr += 2;
	nLeft = getWord(ptr, 2);
	ptr += 2;
	for (j = 0; j <= nLeft && i < nGlyphs; ++j) {
	  glyphNames[i++] = c++;
	}
      }
    }
  }
  return glyphNames;
}

void Type1CFontFile::eexecWrite(char *s) {
  Guchar *p;
  Guchar x;

  for (p = (Guchar *)s; *p; ++p) {
    x = *p ^ (r1 >> 8);
    r1 = (x + r1) * 52845 + 22719;
    (*outputFunc)(outputStream, &hexChars[x >> 4], 1);
    (*outputFunc)(outputStream, &hexChars[x & 0x0f], 1);
    line += 2;
    if (line == 64) {
      (*outputFunc)(outputStream, "\n", 1);
      line = 0;
    }
  }
}

void Type1CFontFile::eexecCvtGlyph(char *glyphName, Guchar *s, int n) {
  char eBuf[256];

  cvtGlyph(s, n);
  sprintf(eBuf, "/%s %d RD ", glyphName, charBuf->getLength());
  eexecWrite(eBuf);
  eexecWriteCharstring((Guchar *)charBuf->getCString(), charBuf->getLength());
  eexecWrite(" ND\n");
  delete charBuf;
}

void Type1CFontFile::cvtGlyph(Guchar *s, int n) {
  int nHints;
  int x;
  GBool first = gTrue;
  double d, dx, dy;
  GBool dFP;
  Gushort r2;
  Guchar byte;
  int i, k;

  charBuf = new GString();
  charBuf->append((char)73);
  charBuf->append((char)58);
  charBuf->append((char)147);
  charBuf->append((char)134);

  i = 0;
  nOps = 0;
  nHints = 0;
  while (i < n) {
    if (s[i] == 12) {
      switch (s[i+1]) {
      case 0:			// dotsection (should be Type 1 only?)
	// ignored
	break;
      case 34:			// hflex
	if (nOps != 7) {
	  error(-1, "Wrong number of args (%d) to Type 2 hflex", nOps);
	}
	eexecDumpNum(op[0], fp[0]);
	eexecDumpNum(0, gFalse);
	eexecDumpNum(op[1], fp[1]);
	eexecDumpNum(op[2], fp[2]);
	eexecDumpNum(op[3], fp[3]);
	eexecDumpNum(0, gFalse);
	eexecDumpOp1(8);
	eexecDumpNum(op[4], fp[4]);
	eexecDumpNum(0, gFalse);
	eexecDumpNum(op[5], fp[5]);
	eexecDumpNum(-op[2], fp[2]);
	eexecDumpNum(op[6], fp[6]);
	eexecDumpNum(0, gFalse);
	eexecDumpOp1(8);
	break;
      case 35:			// flex
	if (nOps != 13) {
	  error(-1, "Wrong number of args (%d) to Type 2 flex", nOps);
	}
	eexecDumpNum(op[0], fp[0]);
	eexecDumpNum(op[1], fp[1]);
	eexecDumpNum(op[2], fp[2]);
	eexecDumpNum(op[3], fp[3]);
	eexecDumpNum(op[4], fp[4]);
	eexecDumpNum(op[5], fp[5]);
	eexecDumpOp1(8);
	eexecDumpNum(op[6], fp[6]);
	eexecDumpNum(op[7], fp[7]);
	eexecDumpNum(op[8], fp[8]);
	eexecDumpNum(op[9], fp[9]);
	eexecDumpNum(op[10], fp[10]);
	eexecDumpNum(op[11], fp[11]);
	eexecDumpOp1(8);
	break;
      case 36:			// hflex1
	if (nOps != 9) {
	  error(-1, "Wrong number of args (%d) to Type 2 hflex1", nOps);
	}
	eexecDumpNum(op[0], fp[0]);
	eexecDumpNum(op[1], fp[1]);
	eexecDumpNum(op[2], fp[2]);
	eexecDumpNum(op[3], fp[3]);
	eexecDumpNum(op[4], fp[4]);
	eexecDumpNum(0, gFalse);
	eexecDumpOp1(8);
	eexecDumpNum(op[5], fp[5]);
	eexecDumpNum(0, gFalse);
	eexecDumpNum(op[6], fp[6]);
	eexecDumpNum(op[7], fp[7]);
	eexecDumpNum(op[8], fp[8]);
	eexecDumpNum(-(op[1] + op[3] + op[7]), fp[1] | fp[3] | fp[7]);
	eexecDumpOp1(8);
	break;
      case 37:			// flex1
	if (nOps != 11) {
	  error(-1, "Wrong number of args (%d) to Type 2 flex1", nOps);
	}
	eexecDumpNum(op[0], fp[0]);
	eexecDumpNum(op[1], fp[1]);
	eexecDumpNum(op[2], fp[2]);
	eexecDumpNum(op[3], fp[3]);
	eexecDumpNum(op[4], fp[4]);
	eexecDumpNum(op[5], fp[5]);
	eexecDumpOp1(8);
	eexecDumpNum(op[6], fp[6]);
	eexecDumpNum(op[7], fp[7]);
	eexecDumpNum(op[8], fp[8]);
	eexecDumpNum(op[9], fp[9]);
	dx = op[0] + op[2] + op[4] + op[6] + op[8];
	dy = op[1] + op[3] + op[5] + op[7] + op[9];
	if (fabs(dx) > fabs(dy)) {
	  eexecDumpNum(op[10], fp[10]);
	  eexecDumpNum(-dy, fp[1] | fp[3] | fp[5] | fp[7] | fp[9]);
	} else {
	  eexecDumpNum(-dx, fp[0] | fp[2] | fp[4] | fp[6] | fp[8]);
	  eexecDumpNum(op[10], fp[10]);
	}
	eexecDumpOp1(8);
	break;
      case 3:			// and
      case 4:			// or
      case 5:			// not
      case 8:			// store
      case 9:			// abs
      case 10:			// add
      case 11:			// sub
      case 12:			// div
      case 13:			// load
      case 14:			// neg
      case 15:			// eq
      case 18:			// drop
      case 20:			// put
      case 21:			// get
      case 22:			// ifelse
      case 23:			// random
      case 24:			// mul
      case 26:			// sqrt
      case 27:			// dup
      case 28:			// exch
      case 29:			// index
      case 30:			// roll
	error(-1, "Unimplemented Type 2 charstring op: 12.%d", s[i+1]);
	break;
      default:
	error(-1, "Illegal Type 2 charstring op: 12.%d", s[i+1]);
	break;
      }
      i += 2;
      nOps = 0;
    } else if (s[i] == 19) {	// hintmask
      // ignored
      if (first) {
	cvtGlyphWidth(nOps == 1);
	first = gFalse;
      }
      if (nOps > 0) {
	if (nOps & 1) {
	  error(-1, "Wrong number of args (%d) to Type 2 hintmask/vstemhm",
		nOps);
	}
	nHints += nOps / 2;
      }
      i += 1 + ((nHints + 7) >> 3);
      nOps = 0;
    } else if (s[i] == 20) {	// cntrmask
      // ignored
      if (first) {
	cvtGlyphWidth(nOps == 1);
	first = gFalse;
      }
      if (nOps > 0) {
	if (nOps & 1) {
	  error(-1, "Wrong number of args (%d) to Type 2 cntrmask/vstemhm",
		nOps);
	}
	nHints += nOps / 2;
      }
      i += 1 + ((nHints + 7) >> 3);
      nOps = 0;
    } else if (s[i] == 28) {
      x = (s[i+1] << 8) + s[i+2];
      if (x & 0x8000) {
	x |= -1 << 15;
      }
      if (nOps < 48) {
	fp[nOps] = gFalse;
	op[nOps++] = x;
      }
      i += 3;
    } else if (s[i] <= 31) {
      switch (s[i]) {
      case 4:			// vmoveto
	if (first) {
	  cvtGlyphWidth(nOps == 2);
	  first = gFalse;
	}
	if (nOps != 1) {
	  error(-1, "Wrong number of args (%d) to Type 2 vmoveto", nOps);
	}
	eexecDumpNum(op[0], fp[0]);
	eexecDumpOp1(4);
	break;
      case 5:			// rlineto
	if (nOps < 2 || nOps % 2 != 0) {
	  error(-1, "Wrong number of args (%d) to Type 2 rlineto", nOps);
	}
	for (k = 0; k < nOps; k += 2) {
	  eexecDumpNum(op[k], fp[k]);
	  eexecDumpNum(op[k+1], fp[k+1]);
	  eexecDumpOp1(5);
	}
	break;
      case 6:			// hlineto
	if (nOps < 1) {
	  error(-1, "Wrong number of args (%d) to Type 2 hlineto", nOps);
	}
	for (k = 0; k < nOps; ++k) {
	  eexecDumpNum(op[k], fp[k]);
	  eexecDumpOp1((k & 1) ? 7 : 6);
	}
	break;
      case 7:			// vlineto
	if (nOps < 1) {
	  error(-1, "Wrong number of args (%d) to Type 2 vlineto", nOps);
	}
	for (k = 0; k < nOps; ++k) {
	  eexecDumpNum(op[k], fp[k]);
	  eexecDumpOp1((k & 1) ? 6 : 7);
	}
	break;
      case 8:			// rrcurveto
	if (nOps < 6 || nOps % 6 != 0) {
	  error(-1, "Wrong number of args (%d) to Type 2 rrcurveto", nOps);
	}
	for (k = 0; k < nOps; k += 6) {
	  eexecDumpNum(op[k], fp[k]);
	  eexecDumpNum(op[k+1], fp[k+1]);
	  eexecDumpNum(op[k+2], fp[k+2]);
	  eexecDumpNum(op[k+3], fp[k+3]);
	  eexecDumpNum(op[k+4], fp[k+4]);
	  eexecDumpNum(op[k+5], fp[k+5]);
	  eexecDumpOp1(8);
	}
	break;
      case 14:			// endchar / seac
	if (first) {
	  cvtGlyphWidth(nOps == 1 || nOps == 5);
	  first = gFalse;
	}
	if (nOps == 4) {
	  eexecDumpNum(0, 0);
	  eexecDumpNum(op[0], fp[0]);
	  eexecDumpNum(op[1], fp[1]);
	  eexecDumpNum(op[2], fp[2]);
	  eexecDumpNum(op[3], fp[3]);
	  eexecDumpOp2(6);
	} else if (nOps == 0) {
	  eexecDumpOp1(14);
	} else {
	  error(-1, "Wrong number of args (%d) to Type 2 endchar", nOps);
	}
	break;
      case 21:			// rmoveto
	if (first) {
	  cvtGlyphWidth(nOps == 3);
	  first = gFalse;
	}
	if (nOps != 2) {
	  error(-1, "Wrong number of args (%d) to Type 2 rmoveto", nOps);
	}
	eexecDumpNum(op[0], fp[0]);
	eexecDumpNum(op[1], fp[1]);
	eexecDumpOp1(21);
	break;
      case 22:			// hmoveto
	if (first) {
	  cvtGlyphWidth(nOps == 2);
	  first = gFalse;
	}
	if (nOps != 1) {
	  error(-1, "Wrong number of args (%d) to Type 2 hmoveto", nOps);
	}
	eexecDumpNum(op[0], fp[0]);
	eexecDumpOp1(22);
	break;
      case 24:			// rcurveline
	if (nOps < 8 || (nOps - 2) % 6 != 0) {
	  error(-1, "Wrong number of args (%d) to Type 2 rcurveline", nOps);
	}
	for (k = 0; k < nOps - 2; k += 6) {
	  eexecDumpNum(op[k], fp[k]);
	  eexecDumpNum(op[k+1], fp[k+1]);
	  eexecDumpNum(op[k+2], fp[k+2]);
	  eexecDumpNum(op[k+3], fp[k+3]);
	  eexecDumpNum(op[k+4], fp[k+4]);
	  eexecDumpNum(op[k+5], fp[k+5]);
	  eexecDumpOp1(8);
	}
	eexecDumpNum(op[k], fp[k]);
	eexecDumpNum(op[k+1], fp[k]);
	eexecDumpOp1(5);
	break;
      case 25:			// rlinecurve
	if (nOps < 8 || (nOps - 6) % 2 != 0) {
	  error(-1, "Wrong number of args (%d) to Type 2 rlinecurve", nOps);
	}
	for (k = 0; k < nOps - 6; k += 2) {
	  eexecDumpNum(op[k], fp[k]);
	  eexecDumpNum(op[k+1], fp[k]);
	  eexecDumpOp1(5);
	}
	eexecDumpNum(op[k], fp[k]);
	eexecDumpNum(op[k+1], fp[k+1]);
	eexecDumpNum(op[k+2], fp[k+2]);
	eexecDumpNum(op[k+3], fp[k+3]);
	eexecDumpNum(op[k+4], fp[k+4]);
	eexecDumpNum(op[k+5], fp[k+5]);
	eexecDumpOp1(8);
	break;
      case 26:			// vvcurveto
	if (nOps < 4 || !(nOps % 4 == 0 || (nOps-1) % 4 == 0)) {
	  error(-1, "Wrong number of args (%d) to Type 2 vvcurveto", nOps);
	}
	if (nOps % 2 == 1) {
	  eexecDumpNum(op[0], fp[0]);
	  eexecDumpNum(op[1], fp[1]);
	  eexecDumpNum(op[2], fp[2]);
	  eexecDumpNum(op[3], fp[3]);
	  eexecDumpNum(0, gFalse);
	  eexecDumpNum(op[4], fp[4]);
	  eexecDumpOp1(8);
	  k = 5;
	} else {
	  k = 0;
	}
	for (; k < nOps; k += 4) {
	  eexecDumpNum(0, gFalse);
	  eexecDumpNum(op[k], fp[k]);
	  eexecDumpNum(op[k+1], fp[k+1]);
	  eexecDumpNum(op[k+2], fp[k+2]);
	  eexecDumpNum(0, gFalse);
	  eexecDumpNum(op[k+3], fp[k+3]);
	  eexecDumpOp1(8);
	}
	break;
      case 27:			// hhcurveto
	if (nOps < 4 || !(nOps % 4 == 0 || (nOps-1) % 4 == 0)) {
	  error(-1, "Wrong number of args (%d) to Type 2 hhcurveto", nOps);
	}
	if (nOps % 2 == 1) {
	  eexecDumpNum(op[1], fp[1]);
	  eexecDumpNum(op[0], fp[0]);
	  eexecDumpNum(op[2], fp[2]);
	  eexecDumpNum(op[3], fp[3]);
	  eexecDumpNum(op[4], fp[4]);
	  eexecDumpNum(0, gFalse);
	  eexecDumpOp1(8);
	  k = 5;
	} else {
	  k = 0;
	}
	for (; k < nOps; k += 4) {
	  eexecDumpNum(op[k], fp[k]);
	  eexecDumpNum(0, gFalse);
	  eexecDumpNum(op[k+1], fp[k+1]);
	  eexecDumpNum(op[k+2], fp[k+2]);
	  eexecDumpNum(op[k+3], fp[k+3]);
	  eexecDumpNum(0, gFalse);
	  eexecDumpOp1(8);
	}
	break;
      case 30:			// vhcurveto
	if (nOps < 4 || !(nOps % 4 == 0 || (nOps-1) % 4 == 0)) {
	  error(-1, "Wrong number of args (%d) to Type 2 vhcurveto", nOps);
	}
	for (k = 0; k < nOps && k != nOps-5; k += 4) {
	  if (k % 8 == 0) {
	    eexecDumpNum(op[k], fp[k]);
	    eexecDumpNum(op[k+1], fp[k+1]);
	    eexecDumpNum(op[k+2], fp[k+2]);
	    eexecDumpNum(op[k+3], fp[k+3]);
	    eexecDumpOp1(30);
	  } else {
	    eexecDumpNum(op[k], fp[k]);
	    eexecDumpNum(op[k+1], fp[k+1]);
	    eexecDumpNum(op[k+2], fp[k+2]);
	    eexecDumpNum(op[k+3], fp[k+3]);
	    eexecDumpOp1(31);
	  }
	}
	if (k == nOps-5) {
	  if (k % 8 == 0) {
	    eexecDumpNum(0, gFalse);
	    eexecDumpNum(op[k], fp[k]);
	    eexecDumpNum(op[k+1], fp[k+1]);
	    eexecDumpNum(op[k+2], fp[k+2]);
	    eexecDumpNum(op[k+3], fp[k+3]);
	    eexecDumpNum(op[k+4], fp[k+4]);
	  } else {
	    eexecDumpNum(op[k], fp[k]);
	    eexecDumpNum(0, gFalse);
	    eexecDumpNum(op[k+1], fp[k+1]);
	    eexecDumpNum(op[k+2], fp[k+2]);
	    eexecDumpNum(op[k+4], fp[k+4]);
	    eexecDumpNum(op[k+3], fp[k+3]);
	  }
	  eexecDumpOp1(8);
	}
	break;
      case 31:			// hvcurveto
	if (nOps < 4 || !(nOps % 4 == 0 || (nOps-1) % 4 == 0)) {
	  error(-1, "Wrong number of args (%d) to Type 2 hvcurveto", nOps);
	}
	for (k = 0; k < nOps && k != nOps-5; k += 4) {
	  if (k % 8 == 0) {
	    eexecDumpNum(op[k], fp[k]);
	    eexecDumpNum(op[k+1], fp[k+1]);
	    eexecDumpNum(op[k+2], fp[k+2]);
	    eexecDumpNum(op[k+3], fp[k+3]);
	    eexecDumpOp1(31);
	  } else {
	    eexecDumpNum(op[k], fp[k]);
	    eexecDumpNum(op[k+1], fp[k+1]);
	    eexecDumpNum(op[k+2], fp[k+2]);
	    eexecDumpNum(op[k+3], fp[k+3]);
	    eexecDumpOp1(30);
	  }
	}
	if (k == nOps-5) {
	  if (k % 8 == 0) {
	    eexecDumpNum(op[k], fp[k]);
	    eexecDumpNum(0, gFalse);
	    eexecDumpNum(op[k+1], fp[k+1]);
	    eexecDumpNum(op[k+2], fp[k+2]);
	    eexecDumpNum(op[k+4], fp[k+4]);
	    eexecDumpNum(op[k+3], fp[k+3]);
	  } else {
	    eexecDumpNum(0, gFalse);
	    eexecDumpNum(op[k], fp[k]);
	    eexecDumpNum(op[k+1], fp[k+1]);
	    eexecDumpNum(op[k+2], fp[k+2]);
	    eexecDumpNum(op[k+3], fp[k+3]);
	    eexecDumpNum(op[k+4], fp[k+4]);
	  }
	  eexecDumpOp1(8);
	}
	break;
      case 1:			// hstem
	if (first) {
	  cvtGlyphWidth(nOps & 1);
	  first = gFalse;
	}
	if (nOps & 1) {
	  error(-1, "Wrong number of args (%d) to Type 2 hstem", nOps);
	}
	d = 0;
	dFP = gFalse;
	for (k = 0; k < nOps; k += 2) {
	  if (op[k+1] < 0) {
	    d += op[k] + op[k+1];
	    dFP |= fp[k] | fp[k+1];
	    eexecDumpNum(d, dFP);
	    eexecDumpNum(-op[k+1], fp[k+1]);
	  } else {
	    d += op[k];
	    dFP |= fp[k];
	    eexecDumpNum(d, dFP);
	    eexecDumpNum(op[k+1], fp[k+1]);
	    d += op[k+1];
	    dFP |= fp[k+1];
	  }
	  eexecDumpOp1(1);
	}
	nHints += nOps / 2;
	break;
      case 3:			// vstem
	if (first) {
	  cvtGlyphWidth(nOps & 1);
	  first = gFalse;
	}
	if (nOps & 1) {
	  error(-1, "Wrong number of args (%d) to Type 2 vstem", nOps);
	}
	d = 0;
	dFP = gFalse;
	for (k = 0; k < nOps; k += 2) {
	  if (op[k+1] < 0) {
	    d += op[k] + op[k+1];
	    dFP |= fp[k] | fp[k+1];
	    eexecDumpNum(d, dFP);
	    eexecDumpNum(-op[k+1], fp[k+1]);
	  } else {
	    d += op[k];
	    dFP |= fp[k];
	    eexecDumpNum(d, dFP);
	    eexecDumpNum(op[k+1], fp[k+1]);
	    d += op[k+1];
	    dFP |= fp[k+1];
	  }
	  eexecDumpOp1(3);
	}
	nHints += nOps / 2;
	break;
      case 18:			// hstemhm
	// ignored
	if (first) {
	  cvtGlyphWidth(nOps & 1);
	  first = gFalse;
	}
	if (nOps & 1) {
	  error(-1, "Wrong number of args (%d) to Type 2 hstemhm", nOps);
	}
	nHints += nOps / 2;
	break;
      case 23:			// vstemhm
	// ignored
	if (first) {
	  cvtGlyphWidth(nOps & 1);
	  first = gFalse;
	}
	if (nOps & 1) {
	  error(-1, "Wrong number of args (%d) to Type 2 vstemhm", nOps);
	}
	nHints += nOps / 2;
	break;
      case 10:			// callsubr
      case 11:			// return
      case 16:			// blend
      case 29:			// callgsubr
	error(-1, "Unimplemented Type 2 charstring op: %d", s[i]);
	break;
      default:
	error(-1, "Illegal Type 2 charstring op: %d", s[i]);
	break;
      }
      ++i;
      nOps = 0;
    } else if (s[i] <= 246) {
      if (nOps < 48) {
	fp[nOps] = gFalse;
	op[nOps++] = (int)s[i] - 139;
      }
      ++i;
    } else if (s[i] <= 250) {
      if (nOps < 48) {
	fp[nOps] = gFalse;
	op[nOps++] = (((int)s[i] - 247) << 8) + (int)s[i+1] + 108;
      }
      i += 2;
    } else if (s[i] <= 254) {
      if (nOps < 48) {
	fp[nOps] = gFalse;
	op[nOps++] = -(((int)s[i] - 251) << 8) - (int)s[i+1] - 108;
      }
      i += 2;
    } else {
      x = (s[i+1] << 24) | (s[i+2] << 16) | (s[i+3] << 8) | s[i+4];
      if (x & 0x80000000)
	x |= -1 << 31;
      if (nOps < 48) {
	fp[nOps] = gTrue;
	op[nOps++] = (double)x / 65536.0;
      }
      i += 5;
    }
  }

  // charstring encryption
  r2 = 4330;
  for (i = 0; i < charBuf->getLength(); ++i) {
    byte = charBuf->getChar(i) ^ (r2 >> 8);
    charBuf->setChar(i, byte);
    r2 = (byte + r2) * 52845 + 22719;
  }
}

void Type1CFontFile::cvtGlyphWidth(GBool useOp) {
  double w;
  GBool wFP;
  int i;

  if (useOp) {
    w = nominalWidthX + op[0];
    wFP = nominalWidthXFP | fp[0];
    for (i = 1; i < nOps; ++i) {
      op[i-1] = op[i];
      fp[i-1] = fp[i];
    }
    --nOps;
  } else {
    w = defaultWidthX;
    wFP = defaultWidthXFP;
  }
  eexecDumpNum(0, gFalse);
  eexecDumpNum(w, wFP);
  eexecDumpOp1(13);
}

void Type1CFontFile::eexecDumpNum(double x, GBool fpA) {
  Guchar buf[12];
  int y, n;

  n = 0;
  if (fpA) {
    if (x >= -32768 && x < 32768) {
      y = (int)(x * 256.0);
      buf[0] = 255;
      buf[1] = (Guchar)(y >> 24);
      buf[2] = (Guchar)(y >> 16);
      buf[3] = (Guchar)(y >> 8);
      buf[4] = (Guchar)y;
      buf[5] = 255;
      buf[6] = 0;
      buf[7] = 0;
      buf[8] = 1;
      buf[9] = 0;
      buf[10] = 12;
      buf[11] = 12;
      n = 12;
    } else {
      error(-1, "Type 2 fixed point constant out of range");
    }
  } else {
    y = (int)x;
    if (y >= -107 && y <= 107) {
      buf[0] = (Guchar)(y + 139);
      n = 1;
    } else if (y > 107 && y <= 1131) {
      y -= 108;
      buf[0] = (Guchar)((y >> 8) + 247);
      buf[1] = (Guchar)(y & 0xff);
      n = 2;
    } else if (y < -107 && y >= -1131) {
      y = -y - 108;
      buf[0] = (Guchar)((y >> 8) + 251);
      buf[1] = (Guchar)(y & 0xff);
      n = 2;
    } else {
      buf[0] = 255;
      buf[1] = (Guchar)(y >> 24);
      buf[2] = (Guchar)(y >> 16);
      buf[3] = (Guchar)(y >> 8);
      buf[4] = (Guchar)y;
      n = 5;
    }
  }
  charBuf->append((char *)buf, n);
}

void Type1CFontFile::eexecDumpOp1(int opA) {
  charBuf->append((char)opA);
}

void Type1CFontFile::eexecDumpOp2(int opA) {
  charBuf->append((char)12);
  charBuf->append((char)opA);
}

void Type1CFontFile::eexecWriteCharstring(Guchar *s, int n) {
  Guchar x;
  int i;

  // eexec encryption
  for (i = 0; i < n; ++i) {
    x = s[i] ^ (r1 >> 8);
    r1 = (x + r1) * 52845 + 22719;
    (*outputFunc)(outputStream, &hexChars[x >> 4], 1);
    (*outputFunc)(outputStream, &hexChars[x & 0x0f], 1);
    line += 2;
    if (line == 64) {
      (*outputFunc)(outputStream, "\n", 1);
      line = 0;
    }
  }
}

void Type1CFontFile::getDeltaInt(char *buf, char *key, double *opA,
				 int n) {
  int x, i;

  sprintf(buf, "/%s [", key);
  buf += strlen(buf);
  x = 0;
  for (i = 0; i < n; ++i) {
    x += (int)opA[i];
    sprintf(buf, "%s%d", i > 0 ? " " : "", x);
    buf += strlen(buf);
  }
  sprintf(buf, "] def\n");
}

void Type1CFontFile::getDeltaReal(char *buf, char *key, double *opA,
				  int n) {
  double x;
  int i;

  sprintf(buf, "/%s [", key);
  buf += strlen(buf);
  x = 0;
  for (i = 0; i < n; ++i) {
    x += opA[i];
    sprintf(buf, "%s%g", i > 0 ? " " : "", x);
    buf += strlen(buf);
  }
  sprintf(buf, "] def\n");
}

int Type1CFontFile::getIndexLen(Guchar *indexPtr) {
  return (int)getWord(indexPtr, 2);
}

Guchar *Type1CFontFile::getIndexValPtr(Guchar *indexPtr, int i) {
  int n, offSize;
  Guchar *idxStartPtr;

  n = (int)getWord(indexPtr, 2);
  offSize = indexPtr[2];
  idxStartPtr = indexPtr + 3 + (n + 1) * offSize - 1;
  return idxStartPtr + getWord(indexPtr + 3 + i * offSize, offSize);
}

Guchar *Type1CFontFile::getIndexEnd(Guchar *indexPtr) {
  int n, offSize;
  Guchar *idxStartPtr;

  n = (int)getWord(indexPtr, 2);
  offSize = indexPtr[2];
  idxStartPtr = indexPtr + 3 + (n + 1) * offSize - 1;
  return idxStartPtr + getWord(indexPtr + 3 + n * offSize, offSize);
}

Guint Type1CFontFile::getWord(Guchar *ptr, int size) {
  Guint x;
  int i;

  x = 0;
  for (i = 0; i < size; ++i) {
    x = (x << 8) + *ptr++;
  }
  return x;
}

double Type1CFontFile::getNum(Guchar **ptr, GBool *isFP) {
  static char nybChars[16] = "0123456789.ee -";
  int b0, b, nyb0, nyb1;
  double x;
  char buf[65];
  int i;

  x = 0;
  *isFP = gFalse;
  b0 = (*ptr)[0];
  if (b0 < 28) {
    x = 0;
  } else if (b0 == 28) {
    x = ((*ptr)[1] << 8) + (*ptr)[2];
    *ptr += 3;
  } else if (b0 == 29) {
    x = ((*ptr)[1] << 24) + ((*ptr)[2] << 16) + ((*ptr)[3] << 8) + (*ptr)[4];
    *ptr += 5;
  } else if (b0 == 30) {
    *ptr += 1;
    i = 0;
    do {
      b = *(*ptr)++;
      nyb0 = b >> 4;
      nyb1 = b & 0x0f;
      if (nyb0 == 0xf) {
	break;
      }
      buf[i++] = nybChars[nyb0];
      if (i == 64) {
	break;
      }
      if (nyb0 == 0xc) {
	buf[i++] = '-';
      }
      if (i == 64) {
	break;
      }
      if (nyb1 == 0xf) {
	break;
      }
      buf[i++] = nybChars[nyb1];
      if (i == 64) {
	break;
      }
      if (nyb1 == 0xc) {
	buf[i++] = '-';
      }
    } while (i < 64);
    buf[i] = '\0';
    x = atof(buf);
    *isFP = gTrue;
  } else if (b0 == 31) {
    x = 0;
  } else if (b0 < 247) {
    x = b0 - 139;
    *ptr += 1;
  } else if (b0 < 251) {
    x = ((b0 - 247) << 8) + (*ptr)[1] + 108;
    *ptr += 2;
  } else {
    x = -((b0 - 251) << 8) - (*ptr)[1] - 108;
    *ptr += 2;
  }
  return x;
}

char *Type1CFontFile::getString(int sid, char *buf) {
  Guchar *idxPtr0, *idxPtr1;
  int n;

  if (sid < 391) {
    strcpy(buf, type1CStdStrings[sid]);
  } else {
    sid -= 391;
    idxPtr0 = getIndexValPtr(stringIdxPtr, sid);
    idxPtr1 = getIndexValPtr(stringIdxPtr, sid + 1);
    if ((n = idxPtr1 - idxPtr0) > 255) {
      n = 255;
    }
    strncpy(buf, (char *)idxPtr0, n);
    buf[n] = '\0';
  }
  return buf;
}

//------------------------------------------------------------------------
// TrueTypeFontFile
//------------------------------------------------------------------------

//
// Terminology
// -----------
//
// character code = number used as an element of a text string
//
// character name = glyph name = name for a particular glyph within a
//                  font
//
// glyph index = position (within some internal table in the font)
//               where the instructions to draw a particular glyph are
//               stored
//
// Type 1 fonts
// ------------
//
// Type 1 fonts contain:
//
// Encoding: array of glyph names, maps char codes to glyph names
//
//           Encoding[charCode] = charName
//
// CharStrings: dictionary of instructions, keyed by character names,
//              maps character name to glyph data
//
//              CharStrings[charName] = glyphData
//
// TrueType fonts
// --------------
//
// TrueType fonts contain:
//
// 'cmap' table: mapping from character code to glyph index; there may
//               be multiple cmaps in a TrueType font
//
//               cmap[charCode] = glyphIdx
//
// 'post' table: mapping from glyph index to glyph name
//
//               post[glyphIdx] = glyphName
//
// Type 42 fonts
// -------------
//
// Type 42 fonts contain:
//
// Encoding: array of glyph names, maps char codes to glyph names
//
//           Encoding[charCode] = charName
//
// CharStrings: dictionary of glyph indexes, keyed by character names,
//              maps character name to glyph index
//
//              CharStrings[charName] = glyphIdx
//

struct TTFontTableHdr {
  char tag[4];
  Guint checksum;
  Guint offset;
  Guint length;
};

struct T42Table {
  char *tag;			// 4-byte tag
  GBool required;		// required by the TrueType spec?
};

// TrueType tables to be embedded in Type 42 fonts.
// NB: the table names must be in alphabetical order here.
#define nT42Tables 11
static T42Table t42Tables[nT42Tables] = {
  { "cvt ", gTrue  },
  { "fpgm", gTrue  },
  { "glyf", gTrue  },
  { "head", gTrue  },
  { "hhea", gTrue  },
  { "hmtx", gTrue  },
  { "loca", gTrue  },
  { "maxp", gTrue  },
  { "prep", gTrue  },
  { "vhea", gFalse },
  { "vmtx", gFalse }
};
#define t42HeadTable 3
#define t42LocaTable 6
#define t42GlyfTable 2

// Glyph names in some arbitrary standard that Apple uses for their
// TrueType fonts.
static char *macGlyphNames[258] = {
  ".notdef",
  "null",
  "CR",
  "space",
  "exclam",
  "quotedbl",
  "numbersign",
  "dollar",
  "percent",
  "ampersand",
  "quotesingle",
  "parenleft",
  "parenright",
  "asterisk",
  "plus",
  "comma",
  "hyphen",
  "period",
  "slash",
  "zero",
  "one",
  "two",
  "three",
  "four",
  "five",
  "six",
  "seven",
  "eight",
  "nine",
  "colon",
  "semicolon",
  "less",
  "equal",
  "greater",
  "question",
  "at",
  "A",
  "B",
  "C",
  "D",
  "E",
  "F",
  "G",
  "H",
  "I",
  "J",
  "K",
  "L",
  "M",
  "N",
  "O",
  "P",
  "Q",
  "R",
  "S",
  "T",
  "U",
  "V",
  "W",
  "X",
  "Y",
  "Z",
  "bracketleft",
  "backslash",
  "bracketright",
  "asciicircum",
  "underscore",
  "grave",
  "a",
  "b",
  "c",
  "d",
  "e",
  "f",
  "g",
  "h",
  "i",
  "j",
  "k",
  "l",
  "m",
  "n",
  "o",
  "p",
  "q",
  "r",
  "s",
  "t",
  "u",
  "v",
  "w",
  "x",
  "y",
  "z",
  "braceleft",
  "bar",
  "braceright",
  "asciitilde",
  "Adieresis",
  "Aring",
  "Ccedilla",
  "Eacute",
  "Ntilde",
  "Odieresis",
  "Udieresis",
  "aacute",
  "agrave",
  "acircumflex",
  "adieresis",
  "atilde",
  "aring",
  "ccedilla",
  "eacute",
  "egrave",
  "ecircumflex",
  "edieresis",
  "iacute",
  "igrave",
  "icircumflex",
  "idieresis",
  "ntilde",
  "oacute",
  "ograve",
  "ocircumflex",
  "odieresis",
  "otilde",
  "uacute",
  "ugrave",
  "ucircumflex",
  "udieresis",
  "dagger",
  "degree",
  "cent",
  "sterling",
  "section",
  "bullet",
  "paragraph",
  "germandbls",
  "registered",
  "copyright",
  "trademark",
  "acute",
  "dieresis",
  "notequal",
  "AE",
  "Oslash",
  "infinity",
  "plusminus",
  "lessequal",
  "greaterequal",
  "yen",
  "mu1",
  "partialdiff",
  "summation",
  "product",
  "pi",
  "integral",
  "ordfeminine",
  "ordmasculine",
  "Ohm",
  "ae",
  "oslash",
  "questiondown",
  "exclamdown",
  "logicalnot",
  "radical",
  "florin",
  "approxequal",
  "increment",
  "guillemotleft",
  "guillemotright",
  "ellipsis",
  "nbspace",
  "Agrave",
  "Atilde",
  "Otilde",
  "OE",
  "oe",
  "endash",
  "emdash",
  "quotedblleft",
  "quotedblright",
  "quoteleft",
  "quoteright",
  "divide",
  "lozenge",
  "ydieresis",
  "Ydieresis",
  "fraction",
  "currency",
  "guilsinglleft",
  "guilsinglright",
  "fi",
  "fl",
  "daggerdbl",
  "periodcentered",
  "quotesinglbase",
  "quotedblbase",
  "perthousand",
  "Acircumflex",
  "Ecircumflex",
  "Aacute",
  "Edieresis",
  "Egrave",
  "Iacute",
  "Icircumflex",
  "Idieresis",
  "Igrave",
  "Oacute",
  "Ocircumflex",
  "applelogo",
  "Ograve",
  "Uacute",
  "Ucircumflex",
  "Ugrave",
  "dotlessi",
  "circumflex",
  "tilde",
  "overscore",
  "breve",
  "dotaccent",
  "ring",
  "cedilla",
  "hungarumlaut",
  "ogonek",
  "caron",
  "Lslash",
  "lslash",
  "Scaron",
  "scaron",
  "Zcaron",
  "zcaron",
  "brokenbar",
  "Eth",
  "eth",
  "Yacute",
  "yacute",
  "Thorn",
  "thorn",
  "minus",
  "multiply",
  "onesuperior",
  "twosuperior",
  "threesuperior",
  "onehalf",
  "onequarter",
  "threequarters",
  "franc",
  "Gbreve",
  "gbreve",
  "Idot",
  "Scedilla",
  "scedilla",
  "Cacute",
  "cacute",
  "Ccaron",
  "ccaron",
  "dmacron"
};

enum T42FontIndexMode {
  t42FontModeUnicode,
  t42FontModeCharCode,
  t42FontModeCharCodeOffset,
  t42FontModeMacRoman
};

TrueTypeFontFile::TrueTypeFontFile(char *fileA, int lenA) {
  int pos, i, idx, n, length;
  Guint size, startPos, endPos;

  file = fileA;
  len = lenA;

  encoding = NULL;

  // read table directory
  nTables = getUShort(4);
  tableHdrs = (TTFontTableHdr *)gmalloc(nTables * sizeof(TTFontTableHdr));
  pos = 12;
  for (i = 0; i < nTables; ++i) {
    tableHdrs[i].tag[0] = getByte(pos+0);
    tableHdrs[i].tag[1] = getByte(pos+1);
    tableHdrs[i].tag[2] = getByte(pos+2);
    tableHdrs[i].tag[3] = getByte(pos+3);
    tableHdrs[i].checksum = getULong(pos+4);
    tableHdrs[i].offset = getULong(pos+8);
    tableHdrs[i].length = getULong(pos+12);
    pos += 16;
  }

  // check for tables that are required by both the TrueType spec
  // and the Type 42 spec
  if (seekTable("head") < 0 ||
      seekTable("hhea") < 0 ||
      seekTable("loca") < 0 ||
      seekTable("maxp") < 0 ||
      seekTable("glyf") < 0 ||
      seekTable("hmtx") < 0) {
    error(-1, "TrueType font file is missing a required table");
    return;
  }

  // some embedded TrueType fonts have an incorrect (too small) cmap
  // table size
  idx = seekTableIdx("cmap");
  if (idx >= 0) {
    pos = tableHdrs[idx].offset;
    n = getUShort(pos + 2);
    size = (Guint)(4 + 8 * n);
    for (i = 0; i < n; ++i) {
      startPos = getULong(pos + 4 + 8*i + 4);
      length = getUShort(pos + startPos + 2);
      endPos = startPos + length;
      if (endPos > size) {
	size = endPos;
      }
    }
    if ((mungedCmapSize = size > tableHdrs[idx].length)) {
#if 0 // don't bother printing this error message - it's too common
      error(-1, "Bad cmap table size in TrueType font");
#endif
      tableHdrs[idx].length = size;
    }
  } else {
    mungedCmapSize = gFalse;
  }

  // read the 'head' table
  pos = seekTable("head");
  bbox[0] = getShort(pos + 36);
  bbox[1] = getShort(pos + 38);
  bbox[2] = getShort(pos + 40);
  bbox[3] = getShort(pos + 42);
  locaFmt = getShort(pos + 50);

  // read the 'maxp' table
  pos = seekTable("maxp");
  nGlyphs = getUShort(pos + 4);
}

TrueTypeFontFile::~TrueTypeFontFile() {
  int i;

  if (encoding) {
    for (i = 0; i < 256; ++i) {
      gfree(encoding[i]);
    }
    gfree(encoding);
  }
  gfree(tableHdrs);
}

char *TrueTypeFontFile::getName() {
  return NULL;
}

char **TrueTypeFontFile::getEncoding() {
  int cmap[256];
  int nCmaps, cmapPlatform, cmapEncoding, cmapFmt;
  int cmapLen, cmapOffset, cmapFirst;
  int segCnt, segStart, segEnd, segDelta, segOffset;
  int pos, i, j, k;
  Guint fmt;
  GString *s;
  int stringIdx, stringPos, n;

  if (encoding) {
    return encoding;
  }

  //----- construct the (char code) -> (glyph idx) mapping

  // map everything to the missing glyph
  for (i = 0; i < 256; ++i) {
    cmap[i] = 0;
  }

  // look for the 'cmap' table
  if ((pos = seekTable("cmap")) >= 0) {
    nCmaps = getUShort(pos+2);

    // if the font has a Windows-symbol cmap, use it;
    // otherwise, use the first cmap in the table
    for (i = 0; i < nCmaps; ++i) {
      cmapPlatform = getUShort(pos + 4 + 8*i);
      cmapEncoding = getUShort(pos + 4 + 8*i + 2);
      if (cmapPlatform == 3 && cmapEncoding == 0) {
	break;
      }
    }
    if (i >= nCmaps) {
      i = 0;
      cmapPlatform = getUShort(pos + 4);
      cmapEncoding = getUShort(pos + 4 + 2);
    }
    pos += getULong(pos + 4 + 8*i + 4);

    // read the cmap
    cmapFmt = getUShort(pos);
    switch (cmapFmt) {
    case 0: // byte encoding table (Apple standard)
      cmapLen = getUShort(pos + 2);
      for (i = 0; i < cmapLen && i < 256; ++i) {
	cmap[i] = getByte(pos + 6 + i);
      }
      break;
    case 4: // segment mapping to delta values (Microsoft standard)
      if (cmapPlatform == 3 && cmapEncoding == 0) {
	// Windows-symbol uses char codes 0xf000 - 0xf0ff
	cmapOffset = 0xf000;
      } else {
	cmapOffset = 0;
      }
      segCnt = getUShort(pos + 6) / 2;
      for (i = 0; i < segCnt; ++i) {
	segEnd = getUShort(pos + 14 + 2*i);
	segStart = getUShort(pos + 16 + 2*segCnt + 2*i);
	segDelta = getUShort(pos + 16 + 4*segCnt + 2*i);
	segOffset = getUShort(pos + 16 + 6*segCnt + 2*i);
	if (segStart - cmapOffset <= 0xff &&
	    segEnd - cmapOffset >= 0) {
	  for (j = (segStart - cmapOffset >= 0) ? segStart : cmapOffset;
	       j <= segEnd && j - cmapOffset <= 0xff;
	       ++j) {
	    if (segOffset == 0) {
	      k = (j + segDelta) & 0xffff;
	    } else {
	      k = getUShort(pos + 16 + 6*segCnt + 2*i +
			    segOffset + 2 * (j - segStart));
	      if (k != 0) {
		k = (k + segDelta) & 0xffff;
	      }
	    }
	    cmap[j - cmapOffset] = k;
	  }
	}
      }
      break;
    case 6: // trimmed table mapping
      cmapFirst = getUShort(pos + 6);
      cmapLen = getUShort(pos + 8);
      for (i = cmapFirst; i < 256 && i < cmapFirst + cmapLen; ++i) {
	cmap[i] = getUShort(pos + 10 + 2*i);
      }
      break;
    default:
      error(-1, "Unimplemented cmap format (%d) in TrueType font file",
	    cmapFmt);
      break;
    }
  }

  //----- construct the (glyph idx) -> (glyph name) mapping
  //----- and compute the (char code) -> (glyph name) mapping

  encoding = (char **)gmalloc(256 * sizeof(char *));
  for (i = 0; i < 256; ++i) {
    encoding[i] = NULL;
  }

  if ((pos = seekTable("post")) >= 0) {
    fmt = getULong(pos);

    // Apple font
    if (fmt == 0x00010000) {
      for (i = 0; i < 256; ++i) {
	j = (cmap[i] < 258) ? cmap[i] : 0;
	encoding[i] = copyString(macGlyphNames[j]);
      }

    // Microsoft font
    } else if (fmt == 0x00020000) {
      stringIdx = 0;
      stringPos = pos + 34 + 2*nGlyphs;
      for (i = 0; i < 256; ++i) {
	if (cmap[i] < nGlyphs) {
	  j = getUShort(pos + 34 + 2 * cmap[i]);
	  if (j < 258) {
	    encoding[i] = copyString(macGlyphNames[j]);
	  } else {
	    j -= 258;
	    if (j != stringIdx) {
	      for (stringIdx = 0, stringPos = pos + 34 + 2*nGlyphs;
		   stringIdx < j;
		   ++stringIdx, stringPos += 1 + getByte(stringPos)) ;
	    }
	    n = getByte(stringPos);
	    s = new GString(file + stringPos + 1, n);
	    encoding[i] = copyString(s->getCString());
	    delete s;
	    ++stringIdx;
	    stringPos += 1 + n;
	  }
	} else {
	  encoding[i] = copyString(macGlyphNames[0]);
	}
      }

    // Apple subset
    } else if (fmt == 0x000280000) {
      for (i = 0; i < 256; ++i) {
	if (cmap[i] < nGlyphs) {
	  j = i + getChar(pos + 32 + cmap[i]);
	} else {
	  j = 0;
	}
	encoding[i] = copyString(macGlyphNames[j]);
      }

    // Ugh, just assume the Apple glyph set
    } else {
      for (i = 0; i < 256; ++i) {
	j = (cmap[i] < 258) ? cmap[i] : 0;
	encoding[i] = copyString(macGlyphNames[j]);
      }
    }

  // no "post" table: assume the Apple glyph set
  } else {
    for (i = 0; i < 256; ++i) {
      j = (cmap[i] < 258) ? cmap[i] : 0;
      encoding[i] = copyString(macGlyphNames[j]);
    }
  }

  return encoding;
}

void TrueTypeFontFile::convertToType42(char *name, char **encodingA,
				       CharCodeToUnicode *toUnicode,
				       GBool pdfFontHasEncoding,
				       FontFileOutputFunc outputFunc,
				       void *outputStream) {
  char buf[512];

  // write the header
  sprintf(buf, "%%!PS-TrueTypeFont-%g\n", getFixed(0));
  (*outputFunc)(outputStream, buf, strlen(buf));

  // begin the font dictionary
  (*outputFunc)(outputStream, "10 dict begin\n", 14);
  (*outputFunc)(outputStream, "/FontName /", 11);
  (*outputFunc)(outputStream, name, strlen(name));
  (*outputFunc)(outputStream, " def\n", 5);
  (*outputFunc)(outputStream, "/FontType 42 def\n", 17);
  (*outputFunc)(outputStream, "/FontMatrix [1 0 0 1 0 0] def\n", 30);
  sprintf(buf, "/FontBBox [%d %d %d %d] def\n",
	  bbox[0], bbox[1], bbox[2], bbox[3]);
  (*outputFunc)(outputStream, buf, strlen(buf));
  (*outputFunc)(outputStream, "/PaintType 0 def\n", 17);

  // write the guts of the dictionary
  cvtEncoding(encodingA, pdfFontHasEncoding, outputFunc, outputStream);
  cvtCharStrings(encodingA, toUnicode, pdfFontHasEncoding,
		 outputFunc, outputStream);
  cvtSfnts(outputFunc, outputStream, NULL);

  // end the dictionary and define the font
  (*outputFunc)(outputStream, "FontName currentdict end definefont pop\n", 40);
}

void TrueTypeFontFile::convertToCIDType2(char *name, Gushort *cidMap,
					 int nCIDs,
					 FontFileOutputFunc outputFunc,
					 void *outputStream) {
  char buf[512];
  Gushort cid;
  int i, j, k;

  // write the header
  sprintf(buf, "%%!PS-TrueTypeFont-%g\n", getFixed(0));
  (*outputFunc)(outputStream, buf, strlen(buf));

  // begin the font dictionary
  (*outputFunc)(outputStream, "20 dict begin\n", 14);
  (*outputFunc)(outputStream, "/CIDFontName /", 14);
  (*outputFunc)(outputStream, name, strlen(name));
  (*outputFunc)(outputStream, " def\n", 5);
  (*outputFunc)(outputStream, "/CIDFontType 2 def\n", 19);
  (*outputFunc)(outputStream, "/FontType 42 def\n", 17);
  (*outputFunc)(outputStream, "/CIDSystemInfo 3 dict dup begin\n", 32);
  (*outputFunc)(outputStream, "  /Registry (Adobe) def\n", 24);
  (*outputFunc)(outputStream, "  /Ordering (Identity) def\n", 27);
  (*outputFunc)(outputStream, "  /Supplement 0 def\n", 20);
  (*outputFunc)(outputStream, "  end def\n", 10);
  (*outputFunc)(outputStream, "/GDBytes 2 def\n", 15);
  if (cidMap) {
    sprintf(buf, "/CIDCount %d def\n", nCIDs);
    (*outputFunc)(outputStream, buf, strlen(buf));
    if (nCIDs > 32767) {
      (*outputFunc)(outputStream, "/CIDMap [", 9);
      for (i = 0; i < nCIDs; i += 32768 - 16) {
	(*outputFunc)(outputStream, "<\n", 2);
	for (j = 0; j < 32768 - 16 && i+j < nCIDs; j += 16) {
	  (*outputFunc)(outputStream, "  ", 2);
	  for (k = 0; k < 16 && i+j+k < nCIDs; ++k) {
	    cid = cidMap[i+j+k];
	    sprintf(buf, "%02x%02x", (cid >> 8) & 0xff, cid & 0xff);
	    (*outputFunc)(outputStream, buf, strlen(buf));
	  }
	  (*outputFunc)(outputStream, "\n", 1);
	}
	(*outputFunc)(outputStream, "  >", 3);
      }
      (*outputFunc)(outputStream, "\n", 1);
      (*outputFunc)(outputStream, "] def\n", 6);
    } else {
      (*outputFunc)(outputStream, "/CIDMap <\n", 10);
      for (i = 0; i < nCIDs; i += 16) {
	(*outputFunc)(outputStream, "  ", 2);
	for (j = 0; j < 16 && i+j < nCIDs; ++j) {
	  cid = cidMap[i+j];
	  sprintf(buf, "%02x%02x", (cid >> 8) & 0xff, cid & 0xff);
	  (*outputFunc)(outputStream, buf, strlen(buf));
	}
	(*outputFunc)(outputStream, "\n", 1);
      }
      (*outputFunc)(outputStream, "> def\n", 6);
    }
  } else {
    // direct mapping - just fill the string(s) with s[i]=i
    sprintf(buf, "/CIDCount %d def\n", nGlyphs);
    (*outputFunc)(outputStream, buf, strlen(buf));
    if (nGlyphs > 32767) {
      (*outputFunc)(outputStream, "/CIDMap [\n", 10);
      for (i = 0; i < nGlyphs; i += 32767) {
	j = nGlyphs - i < 32767 ? nGlyphs - i : 32767;
	sprintf(buf, "  %d string 0 1 %d {\n", 2 * j, j - 1);
	(*outputFunc)(outputStream, buf, strlen(buf));
	sprintf(buf, "    2 copy dup 2 mul exch %d add -8 bitshift put\n", i);
	(*outputFunc)(outputStream, buf, strlen(buf));
	sprintf(buf, "    1 index exch dup 2 mul 1 add exch %d add"
		" 255 and put\n", i);
	(*outputFunc)(outputStream, buf, strlen(buf));
	(*outputFunc)(outputStream, "  } for\n", 8);
      }
      (*outputFunc)(outputStream, "] def\n", 6);
    } else {
      sprintf(buf, "/CIDMap %d string\n", 2 * nGlyphs);
      (*outputFunc)(outputStream, buf, strlen(buf));
      sprintf(buf, "  0 1 %d {\n", nGlyphs - 1);
      (*outputFunc)(outputStream, buf, strlen(buf));
      (*outputFunc)(outputStream,
		    "    2 copy dup 2 mul exch -8 bitshift put\n", 42);
      (*outputFunc)(outputStream,
		    "    1 index exch dup 2 mul 1 add exch 255 and put\n", 50);
      (*outputFunc)(outputStream, "  } for\n", 8);
      (*outputFunc)(outputStream, "def\n", 4);
    }
  }
  (*outputFunc)(outputStream, "/FontMatrix [1 0 0 1 0 0] def\n", 30);
  sprintf(buf, "/FontBBox [%d %d %d %d] def\n",
	  bbox[0], bbox[1], bbox[2], bbox[3]);
  (*outputFunc)(outputStream, buf, strlen(buf));
  (*outputFunc)(outputStream, "/PaintType 0 def\n", 17);
  (*outputFunc)(outputStream, "/Encoding [] readonly def\n", 26);
  (*outputFunc)(outputStream, "/CharStrings 1 dict dup begin\n", 30);
  (*outputFunc)(outputStream, "  /.notdef 0 def\n", 17);
  (*outputFunc)(outputStream, "  end readonly def\n", 19);

  // write the guts of the dictionary
  cvtSfnts(outputFunc, outputStream, NULL);

  // end the dictionary and define the font
  (*outputFunc)(outputStream,
		"CIDFontName currentdict end /CIDFont defineresource pop\n",
		56);
}

void TrueTypeFontFile::convertToType0(char *name, Gushort *cidMap,
				      int nCIDs,
				      FontFileOutputFunc outputFunc,
				      void *outputStream) {
  char buf[512];
  GString *sfntsName;
  int n, i, j;

  // write the Type 42 sfnts array
  sfntsName = (new GString(name))->append("_sfnts");
  cvtSfnts(outputFunc, outputStream, sfntsName);
  delete sfntsName;

  // write the descendant Type 42 fonts
  n = cidMap ? nCIDs : nGlyphs;
  for (i = 0; i < n; i += 256) {
    (*outputFunc)(outputStream, "10 dict begin\n", 14);
    (*outputFunc)(outputStream, "/FontName /", 11);
    (*outputFunc)(outputStream, name, strlen(name));
    sprintf(buf, "_%02x def\n", i >> 8);
    (*outputFunc)(outputStream, buf, strlen(buf));
    (*outputFunc)(outputStream, "/FontType 42 def\n", 17);
    (*outputFunc)(outputStream, "/FontMatrix [1 0 0 1 0 0] def\n", 30);
    sprintf(buf, "/FontBBox [%d %d %d %d] def\n",
	    bbox[0], bbox[1], bbox[2], bbox[3]);
    (*outputFunc)(outputStream, buf, strlen(buf));
    (*outputFunc)(outputStream, "/PaintType 0 def\n", 17);
    (*outputFunc)(outputStream, "/sfnts ", 7);
    (*outputFunc)(outputStream, name, strlen(name));
    (*outputFunc)(outputStream, "_sfnts def\n", 11);
    (*outputFunc)(outputStream, "/Encoding 256 array\n", 20);
    for (j = 0; j < 256 && i+j < n; ++j) {
      sprintf(buf, "dup %d /c%02x put\n", j, j);
      (*outputFunc)(outputStream, buf, strlen(buf));
    }
    (*outputFunc)(outputStream, "readonly def\n", 13);
    (*outputFunc)(outputStream, "/CharStrings 257 dict dup begin\n", 32);
    (*outputFunc)(outputStream, "/.notdef 0 def\n", 15);
    for (j = 0; j < 256 && i+j < n; ++j) {
      sprintf(buf, "/c%02x %d def\n", j, cidMap ? cidMap[i+j] : i+j);
      (*outputFunc)(outputStream, buf, strlen(buf));
    }
    (*outputFunc)(outputStream, "end readonly def\n", 17);
    (*outputFunc)(outputStream,
		  "FontName currentdict end definefont pop\n", 40);
  }

  // write the Type 0 parent font
  (*outputFunc)(outputStream, "16 dict begin\n", 14);
  (*outputFunc)(outputStream, "/FontName /", 11);
  (*outputFunc)(outputStream, name, strlen(name));
  (*outputFunc)(outputStream, " def\n", 5);
  (*outputFunc)(outputStream, "/FontType 0 def\n", 16);
  (*outputFunc)(outputStream, "/FontMatrix [1 0 0 1 0 0] def\n", 30);
  (*outputFunc)(outputStream, "/FMapType 2 def\n", 16);
  (*outputFunc)(outputStream, "/Encoding [\n", 12);
  for (i = 0; i < n; i += 256) {
    sprintf(buf, "%d\n", i >> 8);
    (*outputFunc)(outputStream, buf, strlen(buf));
  }
  (*outputFunc)(outputStream, "] def\n", 6);
  (*outputFunc)(outputStream, "/FDepVector [\n", 14);
  for (i = 0; i < n; i += 256) {
    (*outputFunc)(outputStream, "/", 1);
    (*outputFunc)(outputStream, name, strlen(name));
    sprintf(buf, "_%02x findfont\n", i >> 8);
    (*outputFunc)(outputStream, buf, strlen(buf));
  }
  (*outputFunc)(outputStream, "] def\n", 6);
  (*outputFunc)(outputStream, "FontName currentdict end definefont pop\n", 40);
}

int TrueTypeFontFile::getByte(int pos) {
  if (pos < 0 || pos >= len) {
    return 0;
  }
  return file[pos] & 0xff;
}

int TrueTypeFontFile::getChar(int pos) {
  int x;

  if (pos < 0 || pos >= len) {
    return 0;
  }
  x = file[pos] & 0xff;
  if (x & 0x80)
    x |= 0xffffff00;
  return x;
}

int TrueTypeFontFile::getUShort(int pos) {
  int x;

  if (pos < 0 || pos+1 >= len) {
    return 0;
  }
  x = file[pos] & 0xff;
  x = (x << 8) + (file[pos+1] & 0xff);
  return x;
}

int TrueTypeFontFile::getShort(int pos) {
  int x;

  if (pos < 0 || pos+1 >= len) {
    return 0;
  }
  x = file[pos] & 0xff;
  x = (x << 8) + (file[pos+1] & 0xff);
  if (x & 0x8000)
    x |= 0xffff0000;
  return x;
}

Guint TrueTypeFontFile::getULong(int pos) {
  int x;

  if (pos < 0 || pos+3 >= len) {
    return 0;
  }
  x = file[pos] & 0xff;
  x = (x << 8) + (file[pos+1] & 0xff);
  x = (x << 8) + (file[pos+2] & 0xff);
  x = (x << 8) + (file[pos+3] & 0xff);
  return x;
}

double TrueTypeFontFile::getFixed(int pos) {
  int x, y;

  x = getShort(pos);
  y = getUShort(pos+2);
  return (double)x + (double)y / 65536;
}

int TrueTypeFontFile::seekTable(char *tag) {
  int i;

  for (i = 0; i < nTables; ++i) {
    if (!strncmp(tableHdrs[i].tag, tag, 4)) {
      return tableHdrs[i].offset;
    }
  }
  return -1;
}

int TrueTypeFontFile::seekTableIdx(char *tag) {
  int i;

  for (i = 0; i < nTables; ++i) {
    if (!strncmp(tableHdrs[i].tag, tag, 4)) {
      return i;
    }
  }
  return -1;
}

void TrueTypeFontFile::cvtEncoding(char **encodingA, GBool pdfFontHasEncoding,
				   FontFileOutputFunc outputFunc,
				   void *outputStream) {
  char *name;
  char buf[64];
  int i;

  (*outputFunc)(outputStream, "/Encoding 256 array\n", 20);
  if (pdfFontHasEncoding) {
    for (i = 0; i < 256; ++i) {
      if (!(name = encodingA[i])) {
	name = ".notdef";
      }
      sprintf(buf, "dup %d /", i);
      (*outputFunc)(outputStream, buf, strlen(buf));
      (*outputFunc)(outputStream, name, strlen(name));
      (*outputFunc)(outputStream, " put\n", 5);
    }
  } else {
    for (i = 0; i < 256; ++i) {
      sprintf(buf, "dup %d /c%02x put\n", i, i);
      (*outputFunc)(outputStream, buf, strlen(buf));
    }
  }
  (*outputFunc)(outputStream, "readonly def\n", 13);
}

void TrueTypeFontFile::cvtCharStrings(char **encodingA,
				      CharCodeToUnicode *toUnicode,
				      GBool pdfFontHasEncoding,
				      FontFileOutputFunc outputFunc,
				      void *outputStream) {
  int unicodeCmap, macRomanCmap, msSymbolCmap;
  int nCmaps, cmapPlatform, cmapEncoding, cmapFmt, cmapOffset;
  T42FontIndexMode mode;
  char *name;
  char buf[64], buf2[16];
  Unicode u;
  int pos, i, j, k;

  // always define '.notdef'
  (*outputFunc)(outputStream, "/CharStrings 256 dict dup begin\n", 32);
  (*outputFunc)(outputStream, "/.notdef 0 def\n", 15);

  // if there's no 'cmap' table, punt
  if ((pos = seekTable("cmap")) < 0) {
    goto err;
  }

  // To match up with the Adobe-defined behaviour, we choose a cmap
  // like this:
  // 1. If the PDF font has an encoding:
  //    1a. If the TrueType font has a Microsoft Unicode cmap, use it,
  //        and use the Unicode indexes, not the char codes.
  //    1b. If the TrueType font has a Macintosh Roman cmap, use it,
  //        and reverse map the char names through MacRomanEncoding to
  //        get char codes.
  // 2. If the PDF font does not have an encoding:
  //    2a. If the TrueType font has a Macintosh Roman cmap, use it,
  //        and use char codes directly.
  //    2b. If the TrueType font has a Microsoft Symbol cmap, use it,
  //        and use (0xf000 + char code).
  // 3. If none of these rules apply, use the first cmap and hope for
  //    the best (this shouldn't happen).
  nCmaps = getUShort(pos+2);
  unicodeCmap = macRomanCmap = msSymbolCmap = -1;
  cmapOffset = 0;
  for (i = 0; i < nCmaps; ++i) {
    cmapPlatform = getUShort(pos + 4 + 8*i);
    cmapEncoding = getUShort(pos + 4 + 8*i + 2);
    if (cmapPlatform == 3 && cmapEncoding == 1) {
      unicodeCmap = i;
    } else if (cmapPlatform == 1 && cmapEncoding == 0) {
      macRomanCmap = i;
    } else if (cmapPlatform == 3 && cmapEncoding == 0) {
      msSymbolCmap = i;
    }
  }
  i = 0;
  mode = t42FontModeCharCode;
  if (pdfFontHasEncoding) {
    if (unicodeCmap >= 0) {
      i = unicodeCmap;
      mode = t42FontModeUnicode;
    } else if (macRomanCmap >= 0) {
      i = macRomanCmap;
      mode = t42FontModeMacRoman;
    }
  } else {
    if (macRomanCmap >= 0) {
      i = macRomanCmap;
      mode = t42FontModeCharCode;
    } else if (msSymbolCmap >= 0) {
      i = msSymbolCmap;
      mode = t42FontModeCharCodeOffset;
      cmapOffset = 0xf000;
    }
  }
  cmapPlatform = getUShort(pos + 4 + 8*i);
  cmapEncoding = getUShort(pos + 4 + 8*i + 2);
  pos += getULong(pos + 4 + 8*i + 4);
  cmapFmt = getUShort(pos);
  if (cmapFmt != 0 && cmapFmt != 4 && cmapFmt != 6) {
    error(-1, "Unimplemented cmap format (%d) in TrueType font file",
	  cmapFmt);
    goto err;
  }

  // map char name to glyph index:
  // 1. use encoding to map name to char code
  // 2. use cmap to map char code to glyph index
  j = 0; // make gcc happy
  for (i = 0; i < 256; ++i) {
    if (pdfFontHasEncoding) {
      name = encodingA[i];
    } else {
      sprintf(buf2, "c%02x", i);
      name = buf2;
    }
    if (name && strcmp(name, ".notdef")) {
      switch (mode) {
      case t42FontModeUnicode:
	toUnicode->mapToUnicode((CharCode)i, &u, 1);
	j = (int)u;
	break;
      case t42FontModeCharCode:
	j = i;
	break;
      case t42FontModeCharCodeOffset:
	j = cmapOffset + i;
	break;
      case t42FontModeMacRoman:
	j = globalParams->getMacRomanCharCode(name);
	break;
      }
      // note: Distiller (maybe Adobe's PS interpreter in general)
      // doesn't like TrueType fonts that have CharStrings entries
      // which point to nonexistent glyphs, hence the (k < nGlyphs)
      // test
      if ((k = getCmapEntry(cmapFmt, pos, j)) > 0 &&
	  k < nGlyphs) {
	(*outputFunc)(outputStream, "/", 1);
	(*outputFunc)(outputStream, name, strlen(name));
	sprintf(buf, " %d def\n", k);
	(*outputFunc)(outputStream, buf, strlen(buf));
      }
    }
  }

 err:
  (*outputFunc)(outputStream, "end readonly def\n", 17);
}

int TrueTypeFontFile::getCmapEntry(int cmapFmt, int pos, int code) {
  int cmapLen, cmapFirst;
  int segCnt, segEnd, segStart, segDelta, segOffset;
  int a, b, m, i;

  switch (cmapFmt) {
  case 0: // byte encoding table (Apple standard)
    cmapLen = getUShort(pos + 2);
    if (code >= cmapLen) {
      return 0;
    }
    return getByte(pos + 6 + code);

  case 4: // segment mapping to delta values (Microsoft standard)
    segCnt = getUShort(pos + 6) / 2;
    a = -1;
    b = segCnt - 1;
    segEnd = getUShort(pos + 14 + 2*b);
    if (code > segEnd) {
      // malformed font -- the TrueType spec requires the last segEnd
      // to be 0xffff
      return 0;
    }
    // invariant: seg[a].end < code <= seg[b].end
    while (b - a > 1) {
      m = (a + b) / 2;
      segEnd = getUShort(pos + 14 + 2*m);
      if (segEnd < code) {
	a = m;
      } else {
	b = m;
      }
    }
    segStart = getUShort(pos + 16 + 2*segCnt + 2*b);
    segDelta = getUShort(pos + 16 + 4*segCnt + 2*b);
    segOffset = getUShort(pos + 16 + 6*segCnt + 2*b);
    if (segOffset == 0) {
      i = (code + segDelta) & 0xffff;
    } else {
      i = getUShort(pos + 16 + 6*segCnt + 2*b +
		    segOffset + 2 * (code - segStart));
      if (i != 0) {
	i = (i + segDelta) & 0xffff;
      }
    }
    return i;

  case 6: // trimmed table mapping
    cmapFirst = getUShort(pos + 6);
    cmapLen = getUShort(pos + 8);
    if (code < cmapFirst || code >= cmapFirst + cmapLen) {
      return 0;
    }
    return getUShort(pos + 10 + 2*(code - cmapFirst));

  default:
    // shouldn't happen - this is checked earlier
    break;
  }
  return 0;
}

void TrueTypeFontFile::cvtSfnts(FontFileOutputFunc outputFunc,
				void *outputStream, GString *name) {
  TTFontTableHdr newTableHdrs[nT42Tables];
  char tableDir[12 + nT42Tables*16];
  char headTable[54];
  int *origLocaTable;
  char *locaTable;
  int nNewTables;
  Guint checksum;
  int pos, glyfPos, length, glyphLength, pad;
  int i, j, k;

  // construct the 'head' table, zero out the font checksum
  memcpy(headTable, file + seekTable("head"), 54);
  headTable[8] = headTable[9] = headTable[10] = headTable[11] = (char)0;

  // read the original 'loca' table and construct the new one
  // (pad each glyph out to a multiple of 4 bytes)
  origLocaTable = (int *)gmalloc((nGlyphs + 1) * sizeof(int));
  pos = seekTable("loca");
  for (i = 0; i <= nGlyphs; ++i) {
    if (locaFmt) {
      origLocaTable[i] = getULong(pos + 4*i);
    } else {
      origLocaTable[i] = 2 * getUShort(pos + 2*i);
    }
  }
  locaTable = (char *)gmalloc((nGlyphs + 1) * (locaFmt ? 4 : 2));
  if (locaFmt) {
    locaTable[0] = locaTable[1] = locaTable[2] = locaTable[3] = 0;
  } else {
    locaTable[0] = locaTable[1] = 0;
  }
  pos = 0;
  for (i = 1; i <= nGlyphs; ++i) {
    length = origLocaTable[i] - origLocaTable[i-1];
    if (length & 3) {
      length += 4 - (length & 3);
    }
    pos += length;
    if (locaFmt) {
      locaTable[4*i  ] = (char)(pos >> 24);
      locaTable[4*i+1] = (char)(pos >> 16);
      locaTable[4*i+2] = (char)(pos >>  8);
      locaTable[4*i+3] = (char) pos;
    } else {
      locaTable[2*i  ] = (char)(pos >> 9);
      locaTable[2*i+1] = (char)(pos >> 1);
    }
  }

  // count the number of tables
  nNewTables = 0;
  for (i = 0; i < nT42Tables; ++i) {
    if (t42Tables[i].required ||
	seekTable(t42Tables[i].tag) >= 0) {
      ++nNewTables;
    }
  }

  // construct the new table headers, including table checksums
  // (pad each table out to a multiple of 4 bytes)
  pos = 12 + nNewTables*16;
  k = 0;
  for (i = 0; i < nT42Tables; ++i) {
    length = -1;
    checksum = 0; // make gcc happy
    if (i == t42HeadTable) {
      length = 54;
      checksum = computeTableChecksum(headTable, 54);
    } else if (i == t42LocaTable) {
      length = (nGlyphs + 1) * (locaFmt ? 4 : 2);
      checksum = computeTableChecksum(locaTable, length);
    } else if (i == t42GlyfTable) {
      length = 0;
      checksum = 0;
      glyfPos = seekTable("glyf");
      for (j = 0; j < nGlyphs; ++j) {
	glyphLength = origLocaTable[j+1] - origLocaTable[j];
	pad = (glyphLength & 3) ? 4 - (glyphLength & 3) : 0;
	length += glyphLength + pad;
	checksum += computeTableChecksum(file + glyfPos + origLocaTable[j],
					 glyphLength);
      }
    } else {
      if ((j = seekTableIdx(t42Tables[i].tag)) >= 0) {
	length = tableHdrs[j].length;
	checksum = computeTableChecksum(file + tableHdrs[j].offset, length);
      } else if (t42Tables[i].required) {
	error(-1, "Embedded TrueType font is missing a required table ('%s')",
	      t42Tables[i].tag);
	length = 0;
	checksum = 0;
      }
    }
    if (length >= 0) {
      strncpy(newTableHdrs[k].tag, t42Tables[i].tag, 4);
      newTableHdrs[k].checksum = checksum;
      newTableHdrs[k].offset = pos;
      newTableHdrs[k].length = length;
      pad = (length & 3) ? 4 - (length & 3) : 0;
      pos += length + pad;
      ++k;
    }
  }

  // construct the table directory
  tableDir[0] = 0x00;		// sfnt version
  tableDir[1] = 0x01;
  tableDir[2] = 0x00;
  tableDir[3] = 0x00;
  tableDir[4] = 0;		// numTables
  tableDir[5] = nNewTables;
  tableDir[6] = 0;		// searchRange
  tableDir[7] = (char)128;
  tableDir[8] = 0;		// entrySelector
  tableDir[9] = 3;
  tableDir[10] = 0;		// rangeShift
  tableDir[11] = (char)(16 * nNewTables - 128);
  pos = 12;
  for (i = 0; i < nNewTables; ++i) {
    tableDir[pos   ] = newTableHdrs[i].tag[0];
    tableDir[pos+ 1] = newTableHdrs[i].tag[1];
    tableDir[pos+ 2] = newTableHdrs[i].tag[2];
    tableDir[pos+ 3] = newTableHdrs[i].tag[3];
    tableDir[pos+ 4] = (char)(newTableHdrs[i].checksum >> 24);
    tableDir[pos+ 5] = (char)(newTableHdrs[i].checksum >> 16);
    tableDir[pos+ 6] = (char)(newTableHdrs[i].checksum >>  8);
    tableDir[pos+ 7] = (char) newTableHdrs[i].checksum;
    tableDir[pos+ 8] = (char)(newTableHdrs[i].offset >> 24);
    tableDir[pos+ 9] = (char)(newTableHdrs[i].offset >> 16);
    tableDir[pos+10] = (char)(newTableHdrs[i].offset >>  8);
    tableDir[pos+11] = (char) newTableHdrs[i].offset;
    tableDir[pos+12] = (char)(newTableHdrs[i].length >> 24);
    tableDir[pos+13] = (char)(newTableHdrs[i].length >> 16);
    tableDir[pos+14] = (char)(newTableHdrs[i].length >>  8);
    tableDir[pos+15] = (char) newTableHdrs[i].length;
    pos += 16;
  }

  // compute the font checksum and store it in the head table
  checksum = computeTableChecksum(tableDir, 12 + nNewTables*16);
  for (i = 0; i < nNewTables; ++i) {
    checksum += newTableHdrs[i].checksum;
  }
  checksum = 0xb1b0afba - checksum; // because the TrueType spec says so
  headTable[ 8] = (char)(checksum >> 24);
  headTable[ 9] = (char)(checksum >> 16);
  headTable[10] = (char)(checksum >>  8);
  headTable[11] = (char) checksum;

  // start the sfnts array
  if (name) {
    (*outputFunc)(outputStream, "/", 1);
    (*outputFunc)(outputStream, name->getCString(), name->getLength());
    (*outputFunc)(outputStream, " [\n", 3);
  } else {
    (*outputFunc)(outputStream, "/sfnts [\n", 9);
  }

  // write the table directory
  dumpString(tableDir, 12 + nNewTables*16, outputFunc, outputStream);

  // write the tables
  for (i = 0; i < nNewTables; ++i) {
    if (i == t42HeadTable) {
      dumpString(headTable, 54, outputFunc, outputStream);
    } else if (i == t42LocaTable) {
      length = (nGlyphs + 1) * (locaFmt ? 4 : 2);
      dumpString(locaTable, length, outputFunc, outputStream);
    } else if (i == t42GlyfTable) {
      glyfPos = seekTable("glyf");
      for (j = 0; j < nGlyphs; ++j) {
	length = origLocaTable[j+1] - origLocaTable[j];
	if (length > 0) {
	  dumpString(file + glyfPos + origLocaTable[j], length,
		     outputFunc, outputStream);
	}
      }
    } else {
      // length == 0 means the table is missing and the error was
      // already reported during the construction of the table
      // headers
      if ((length = newTableHdrs[i].length) > 0) {
	dumpString(file + seekTable(t42Tables[i].tag), length,
		   outputFunc, outputStream);
      }
    }
  }

  // end the sfnts array
  (*outputFunc)(outputStream, "] def\n", 6);

  gfree(origLocaTable);
  gfree(locaTable);
}

void TrueTypeFontFile::dumpString(char *s, int length,
				  FontFileOutputFunc outputFunc,
				  void *outputStream) {
  char buf[64];
  int pad, i, j;

  (*outputFunc)(outputStream, "<", 1);
  for (i = 0; i < length; i += 32) {
    for (j = 0; j < 32 && i+j < length; ++j) {
      sprintf(buf, "%02X", s[i+j] & 0xff);
      (*outputFunc)(outputStream, buf, strlen(buf));
    }
    if (i % (65536 - 32) == 65536 - 64) {
      (*outputFunc)(outputStream, ">\n<", 3);
    } else if (i+32 < length) {
      (*outputFunc)(outputStream, "\n", 1);
    }
  }
  if (length & 3) {
    pad = 4 - (length & 3);
    for (i = 0; i < pad; ++i) {
      (*outputFunc)(outputStream, "00", 2);
    }
  }
  // add an extra zero byte because the Adobe Type 42 spec says so
  (*outputFunc)(outputStream, "00>\n", 4);
}

Guint TrueTypeFontFile::computeTableChecksum(char *data, int length) {
  Guint checksum, word;
  int i;

  checksum = 0;
  for (i = 0; i+3 < length; i += 4) {
    word = ((data[i  ] & 0xff) << 24) +
           ((data[i+1] & 0xff) << 16) +
           ((data[i+2] & 0xff) <<  8) +
            (data[i+3] & 0xff);
    checksum += word;
  }
  if (length & 3) {
    word = 0;
    i = length & ~3;
    switch (length & 3) {
    case 3:
      word |= (data[i+2] & 0xff) <<  8;
    case 2:
      word |= (data[i+1] & 0xff) << 16;
    case 1:
      word |= (data[i  ] & 0xff) << 24;
      break;
    }
    checksum += word;
  }
  return checksum;
}

void TrueTypeFontFile::writeTTF(FILE *out) {
  static char cmapTab[20] = {
    0, 0,			// table version number
    0, 1,			// number of encoding tables
    0, 1,			// platform ID
    0, 0,			// encoding ID
    0, 0, 0, 12,		// offset of subtable
    0, 0,			// subtable format
    0, 1,			// subtable length
    0, 1,			// subtable version
    0,				// map char 0 -> glyph 0
    0				// pad to multiple of four bytes
  };
  static char nameTab[8] = {
    0, 0,			// format
    0, 0,			// number of name records
    0, 6,			// offset to start of string storage
    0, 0			// pad to multiple of four bytes
  };
  static char postTab[32] = {
    0, 1, 0, 0,			// format
    0, 0, 0, 0,			// italic angle
    0, 0,			// underline position
    0, 0,			// underline thickness
    0, 0, 0, 0,			// fixed pitch
    0, 0, 0, 0,			// min Type 42 memory
    0, 0, 0, 0,			// max Type 42 memory
    0, 0, 0, 0,			// min Type 1 memory
    0, 0, 0, 0			// max Type 1 memory
  };
  GBool haveCmap, haveName, havePost;
  GBool dirCmap, dirName, dirPost;
  int nNewTables, nAllTables, pad;
  char *tableDir;
  Guint t, pos;
  int i, j;

  // check for missing tables
  haveCmap = seekTable("cmap") >= 0;
  haveName = seekTable("name") >= 0;
  havePost = seekTable("post") >= 0;
  nNewTables = (haveCmap ? 0 : 1) + (haveName ? 0 : 1) + (havePost ? 0 : 1);
  if (!nNewTables && !mungedCmapSize) {
    // none are missing - write the TTF file as is
    fwrite(file, 1, len, out);
    return;
  }

  // construct the new table directory
  nAllTables = nTables + nNewTables;
  tableDir = (char *)gmalloc(12 + nAllTables * 16);
  memcpy(tableDir, file, 12 + nTables * 16);
  tableDir[4] = (char)((nAllTables >> 8) & 0xff);
  tableDir[5] = (char)(nAllTables & 0xff);
  for (i = -1, t = (Guint)nAllTables; t; ++i, t >>= 1) ;
  t = 1 << (4 + i);
  tableDir[6] = (char)((t >> 8) & 0xff);
  tableDir[7] = (char)(t & 0xff);
  tableDir[8] = (char)((i >> 8) & 0xff);
  tableDir[9] = (char)(i & 0xff);
  t = nAllTables * 16 - t;
  tableDir[10] = (char)((t >> 8) & 0xff);
  tableDir[11] = (char)(t & 0xff);
  dirCmap = haveCmap;
  dirName = haveName;
  dirPost = havePost;
  j = 0;
  pad = (len & 3) ? 4 - (len & 3) : 0;
  pos = len + pad + 16 * nNewTables;
  for (i = 0; i < nTables; ++i) {
    if (!dirCmap && strncmp(tableHdrs[i].tag, "cmap", 4) > 0) {
      tableDir[12 + 16*j     ] = 'c';
      tableDir[12 + 16*j +  1] = 'm';
      tableDir[12 + 16*j +  2] = 'a';
      tableDir[12 + 16*j +  3] = 'p';
      tableDir[12 + 16*j +  4] = (char)0; //~ should compute the checksum
      tableDir[12 + 16*j +  5] = (char)0;
      tableDir[12 + 16*j +  6] = (char)0;
      tableDir[12 + 16*j +  7] = (char)0;
      tableDir[12 + 16*j +  8] = (char)((pos >> 24) & 0xff);
      tableDir[12 + 16*j +  9] = (char)((pos >> 16) & 0xff);
      tableDir[12 + 16*j + 10] = (char)((pos >>  8) & 0xff);
      tableDir[12 + 16*j + 11] = (char)( pos        & 0xff);
      tableDir[12 + 16*j + 12] = (char)((sizeof(cmapTab) >> 24) & 0xff);
      tableDir[12 + 16*j + 13] = (char)((sizeof(cmapTab) >> 16) & 0xff);
      tableDir[12 + 16*j + 14] = (char)((sizeof(cmapTab) >>  8) & 0xff);
      tableDir[12 + 16*j + 15] = (char)( sizeof(cmapTab)        & 0xff);
      pos += sizeof(cmapTab);
      ++j;
      dirCmap = gTrue;
    }
    if (!dirName && strncmp(tableHdrs[i].tag, "name", 4) > 0) {
      tableDir[12 + 16*j     ] = 'n';
      tableDir[12 + 16*j +  1] = 'a';
      tableDir[12 + 16*j +  2] = 'm';
      tableDir[12 + 16*j +  3] = 'e';
      tableDir[12 + 16*j +  4] = (char)0; //~ should compute the checksum
      tableDir[12 + 16*j +  5] = (char)0;
      tableDir[12 + 16*j +  6] = (char)0;
      tableDir[12 + 16*j +  7] = (char)0;
      tableDir[12 + 16*j +  8] = (char)((pos >> 24) & 0xff);
      tableDir[12 + 16*j +  9] = (char)((pos >> 16) & 0xff);
      tableDir[12 + 16*j + 10] = (char)((pos >>  8) & 0xff);
      tableDir[12 + 16*j + 11] = (char)( pos        & 0xff);
      tableDir[12 + 16*j + 12] = (char)((sizeof(nameTab) >> 24) & 0xff);
      tableDir[12 + 16*j + 13] = (char)((sizeof(nameTab) >> 16) & 0xff);
      tableDir[12 + 16*j + 14] = (char)((sizeof(nameTab) >>  8) & 0xff);
      tableDir[12 + 16*j + 15] = (char)( sizeof(nameTab)        & 0xff);
      pos += sizeof(nameTab);
      ++j;
      dirName = gTrue;
    }
    if (!dirName && strncmp(tableHdrs[i].tag, "post", 4) > 0) {
      tableDir[12 + 16*j     ] = 'p';
      tableDir[12 + 16*j +  1] = 'o';
      tableDir[12 + 16*j +  2] = 's';
      tableDir[12 + 16*j +  3] = 't';
      tableDir[12 + 16*j +  4] = (char)0; //~ should compute the checksum
      tableDir[12 + 16*j +  5] = (char)0;
      tableDir[12 + 16*j +  6] = (char)0;
      tableDir[12 + 16*j +  7] = (char)0;
      tableDir[12 + 16*j +  8] = (char)((pos >> 24) & 0xff);
      tableDir[12 + 16*j +  9] = (char)((pos >> 16) & 0xff);
      tableDir[12 + 16*j + 10] = (char)((pos >>  8) & 0xff);
      tableDir[12 + 16*j + 11] = (char)( pos        & 0xff);
      tableDir[12 + 16*j + 12] = (char)((sizeof(postTab) >> 24) & 0xff);
      tableDir[12 + 16*j + 13] = (char)((sizeof(postTab) >> 16) & 0xff);
      tableDir[12 + 16*j + 14] = (char)((sizeof(postTab) >>  8) & 0xff);
      tableDir[12 + 16*j + 15] = (char)( sizeof(postTab)        & 0xff);
      pos += sizeof(postTab);
      ++j;
      dirPost = gTrue;
    }
    tableDir[12 + 16*j     ] = tableHdrs[i].tag[0];
    tableDir[12 + 16*j +  1] = tableHdrs[i].tag[1];
    tableDir[12 + 16*j +  2] = tableHdrs[i].tag[2];
    tableDir[12 + 16*j +  3] = tableHdrs[i].tag[3];
    tableDir[12 + 16*j +  4] = (char)((tableHdrs[i].checksum >> 24) & 0xff);
    tableDir[12 + 16*j +  5] = (char)((tableHdrs[i].checksum >> 16) & 0xff);
    tableDir[12 + 16*j +  6] = (char)((tableHdrs[i].checksum >>  8) & 0xff);
    tableDir[12 + 16*j +  7] = (char)( tableHdrs[i].checksum        & 0xff);
    t = tableHdrs[i].offset + nNewTables * 16;
    tableDir[12 + 16*j +  8] = (char)((t >> 24) & 0xff);
    tableDir[12 + 16*j +  9] = (char)((t >> 16) & 0xff);
    tableDir[12 + 16*j + 10] = (char)((t >>  8) & 0xff);
    tableDir[12 + 16*j + 11] = (char)( t        & 0xff);
    tableDir[12 + 16*j + 12] = (char)((tableHdrs[i].length >> 24) & 0xff);
    tableDir[12 + 16*j + 13] = (char)((tableHdrs[i].length >> 16) & 0xff);
    tableDir[12 + 16*j + 14] = (char)((tableHdrs[i].length >>  8) & 0xff);
    tableDir[12 + 16*j + 15] = (char)( tableHdrs[i].length        & 0xff);
    ++j;
  }
  if (!dirCmap) {
    tableDir[12 + 16*j     ] = 'c';
    tableDir[12 + 16*j +  1] = 'm';
    tableDir[12 + 16*j +  2] = 'a';
    tableDir[12 + 16*j +  3] = 'p';
    tableDir[12 + 16*j +  4] = (char)0; //~ should compute the checksum
    tableDir[12 + 16*j +  5] = (char)0;
    tableDir[12 + 16*j +  6] = (char)0;
    tableDir[12 + 16*j +  7] = (char)0;
    tableDir[12 + 16*j +  8] = (char)((pos >> 24) & 0xff);
    tableDir[12 + 16*j +  9] = (char)((pos >> 16) & 0xff);
    tableDir[12 + 16*j + 10] = (char)((pos >>  8) & 0xff);
    tableDir[12 + 16*j + 11] = (char)( pos        & 0xff);
    tableDir[12 + 16*j + 12] = (char)((sizeof(cmapTab) >> 24) & 0xff);
    tableDir[12 + 16*j + 13] = (char)((sizeof(cmapTab) >> 16) & 0xff);
    tableDir[12 + 16*j + 14] = (char)((sizeof(cmapTab) >>  8) & 0xff);
    tableDir[12 + 16*j + 15] = (char)( sizeof(cmapTab)        & 0xff);
    pos += sizeof(cmapTab);
    ++j;
    dirCmap = gTrue;
  }
  if (!dirName) {
    tableDir[12 + 16*j     ] = 'n';
    tableDir[12 + 16*j +  1] = 'a';
    tableDir[12 + 16*j +  2] = 'm';
    tableDir[12 + 16*j +  3] = 'e';
    tableDir[12 + 16*j +  4] = (char)0; //~ should compute the checksum
    tableDir[12 + 16*j +  5] = (char)0;
    tableDir[12 + 16*j +  6] = (char)0;
    tableDir[12 + 16*j +  7] = (char)0;
    tableDir[12 + 16*j +  8] = (char)((pos >> 24) & 0xff);
    tableDir[12 + 16*j +  9] = (char)((pos >> 16) & 0xff);
    tableDir[12 + 16*j + 10] = (char)((pos >>  8) & 0xff);
    tableDir[12 + 16*j + 11] = (char)( pos        & 0xff);
    tableDir[12 + 16*j + 12] = (char)((sizeof(nameTab) >> 24) & 0xff);
    tableDir[12 + 16*j + 13] = (char)((sizeof(nameTab) >> 16) & 0xff);
    tableDir[12 + 16*j + 14] = (char)((sizeof(nameTab) >>  8) & 0xff);
    tableDir[12 + 16*j + 15] = (char)( sizeof(nameTab)        & 0xff);
    pos += sizeof(nameTab);
    ++j;
    dirName = gTrue;
  }
  if (!dirPost) {
    tableDir[12 + 16*j     ] = 'p';
    tableDir[12 + 16*j +  1] = 'o';
    tableDir[12 + 16*j +  2] = 's';
    tableDir[12 + 16*j +  3] = 't';
    tableDir[12 + 16*j +  4] = (char)0; //~ should compute the checksum
    tableDir[12 + 16*j +  5] = (char)0;
    tableDir[12 + 16*j +  6] = (char)0;
    tableDir[12 + 16*j +  7] = (char)0;
    tableDir[12 + 16*j +  8] = (char)((pos >> 24) & 0xff);
    tableDir[12 + 16*j +  9] = (char)((pos >> 16) & 0xff);
    tableDir[12 + 16*j + 10] = (char)((pos >>  8) & 0xff);
    tableDir[12 + 16*j + 11] = (char)( pos        & 0xff);
    tableDir[12 + 16*j + 12] = (char)((sizeof(postTab) >> 24) & 0xff);
    tableDir[12 + 16*j + 13] = (char)((sizeof(postTab) >> 16) & 0xff);
    tableDir[12 + 16*j + 14] = (char)((sizeof(postTab) >>  8) & 0xff);
    tableDir[12 + 16*j + 15] = (char)( sizeof(postTab)        & 0xff);
    pos += sizeof(postTab);
    ++j;
    dirPost = gTrue;
  }

  // write the table directory
  fwrite(tableDir, 1, 12 + 16 * nAllTables, out);

  // write the original tables
  fwrite(file + 12 + 16*nTables, 1, len - (12 + 16*nTables), out);

  // write the new tables
  for (i = 0; i < pad; ++i) {
    fputc((char)0, out);
  }
  if (!haveCmap) {
    fwrite(cmapTab, 1, sizeof(cmapTab), out);
  }
  if (!haveName) {
    fwrite(nameTab, 1, sizeof(nameTab), out);
  }
  if (!havePost) {
    fwrite(postTab, 1, sizeof(postTab), out);
  }

  gfree(tableDir);
}
