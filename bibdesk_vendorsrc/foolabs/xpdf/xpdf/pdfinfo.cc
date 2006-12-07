//========================================================================
//
// pdfinfo.cc
//
// Copyright 1998-2002 Glyph & Cog, LLC
//
//========================================================================

#include <aconf.h>
#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>
#include <string.h>
#include <time.h>
#include <math.h>
#include "parseargs.h"
#include "GString.h"
#include "gmem.h"
#include "GlobalParams.h"
#include "Object.h"
#include "Stream.h"
#include "Array.h"
#include "Dict.h"
#include "XRef.h"
#include "Catalog.h"
#include "Page.h"
#include "PDFDoc.h"
#include "CharTypes.h"
#include "UnicodeMap.h"
#include "Error.h"
#include "config.h"

static void printInfoString(Dict *infoDict, char *key, char *text,
			    UnicodeMap *uMap);
static void printInfoDate(Dict *infoDict, char *key, char *text);

static GBool printMetadata = gFalse;
static char textEncName[128] = "";
static char ownerPassword[33] = "";
static char userPassword[33] = "";
static char cfgFileName[256] = "";
static GBool printVersion = gFalse;
static GBool printHelp = gFalse;

static ArgDesc argDesc[] = {
  {"-meta",   argFlag,     &printMetadata,    0,
   "print the document metadata (XML)"},
  {"-enc",    argString,   textEncName,    sizeof(textEncName),
   "output text encoding name"},
  {"-opw",    argString,   ownerPassword,  sizeof(ownerPassword),
   "owner password (for encrypted files)"},
  {"-upw",    argString,   userPassword,   sizeof(userPassword),
   "user password (for encrypted files)"},
  {"-cfg",        argString,      cfgFileName,    sizeof(cfgFileName),
   "configuration file to use in place of .xpdfrc"},
  {"-v",      argFlag,     &printVersion,  0,
   "print copyright and version info"},
  {"-h",      argFlag,     &printHelp,     0,
   "print usage information"},
  {"-help",   argFlag,     &printHelp,     0,
   "print usage information"},
  {"--help",  argFlag,     &printHelp,     0,
   "print usage information"},
  {"-?",      argFlag,     &printHelp,     0,
   "print usage information"},
  {NULL}
};

int main(int argc, char *argv[]) {
  PDFDoc *doc;
  GString *fileName;
  GString *ownerPW, *userPW;
  UnicodeMap *uMap;
  Object info;
  double w, h;
  FILE *f;
  GString *metadata;
  GBool ok;
  int exitCode;

  exitCode = 99;

  // parse args
  ok = parseArgs(argDesc, &argc, argv);
  if (!ok || argc != 2 || printVersion || printHelp) {
    fprintf(stderr, "pdfinfo version %s\n", xpdfVersion);
    fprintf(stderr, "%s\n", xpdfCopyright);
    if (!printVersion) {
      printUsage("pdfinfo", "<PDF-file>", argDesc);
    }
    goto err0;
  }
  fileName = new GString(argv[1]);

  // read config file
  globalParams = new GlobalParams(cfgFileName);
  if (textEncName[0]) {
    globalParams->setTextEncoding(textEncName);
  }

  // get mapping to output encoding
  if (!(uMap = globalParams->getTextEncoding())) {
    error(-1, "Couldn't get text encoding");
    delete fileName;
    goto err1;
  }

  // open PDF file
  if (ownerPassword[0]) {
    ownerPW = new GString(ownerPassword);
  } else {
    ownerPW = NULL;
  }
  if (userPassword[0]) {
    userPW = new GString(userPassword);
  } else {
    userPW = NULL;
  }
  doc = new PDFDoc(fileName, ownerPW, userPW);
  if (userPW) {
    delete userPW;
  }
  if (ownerPW) {
    delete ownerPW;
  }
  if (!doc->isOk()) {
    exitCode = 1;
    goto err2;
  }

  // print doc info
  doc->getDocInfo(&info);
  if (info.isDict()) {
    printInfoString(info.getDict(), "Title",        "Title:        ", uMap);
    printInfoString(info.getDict(), "Subject",      "Subject:      ", uMap);
    printInfoString(info.getDict(), "Keywords",     "Keywords:     ", uMap);
    printInfoString(info.getDict(), "Author",       "Author:       ", uMap);
    printInfoString(info.getDict(), "Creator",      "Creator:      ", uMap);
    printInfoString(info.getDict(), "Producer",     "Producer:     ", uMap);
    printInfoDate(info.getDict(),   "CreationDate", "CreationDate: ");
    printInfoDate(info.getDict(),   "ModDate",      "ModDate:      ");
  }
  info.free();

  // print tagging info
  printf("Tagged:       %s\n",
	 doc->getStructTreeRoot()->isDict() ? "yes" : "no");

  // print page count
  printf("Pages:        %d\n", doc->getNumPages());

  // print encryption info
  printf("Encrypted:    ");
  if (doc->isEncrypted()) {
    printf("yes (print:%s copy:%s change:%s addNotes:%s)\n",
	   doc->okToPrint(gTrue) ? "yes" : "no",
	   doc->okToCopy(gTrue) ? "yes" : "no",
	   doc->okToChange(gTrue) ? "yes" : "no",
	   doc->okToAddNotes(gTrue) ? "yes" : "no");
  } else {
    printf("no\n");
  }

  // print page size
  if (doc->getNumPages() >= 1) {
    w = doc->getPageWidth(1);
    h = doc->getPageHeight(1);
    printf("Page size:    %g x %g pts", w, h);
    if ((fabs(w - 612) < 0.1 && fabs(h - 792) < 0.1) ||
	(fabs(w - 792) < 0.1 && fabs(h - 612) < 0.1)) {
      printf(" (letter)");
    } else if ((fabs(w - 595) < 0.1 && fabs(h - 842) < 0.1) ||
	       (fabs(w - 842) < 0.1 && fabs(h - 595) < 0.1)) {
      printf(" (A4)");
    }
    printf("\n");
  } 

  // print file size
#ifdef VMS
  f = fopen(fileName->getCString(), "rb", "ctx=stm");
#else
  f = fopen(fileName->getCString(), "rb");
#endif
  if (f) {
#if HAVE_FSEEKO
    fseeko(f, 0, SEEK_END);
    printf("File size:    %u bytes\n", (Guint)ftello(f));
#elif HAVE_FSEEK64
    fseek64(f, 0, SEEK_END);
    printf("File size:    %u bytes\n", (Guint)ftell64(f));
#else
    fseek(f, 0, SEEK_END);
    printf("File size:    %d bytes\n", (int)ftell(f));
#endif
    fclose(f);
  }

  // print linearization info
  printf("Optimized:    %s\n", doc->isLinearized() ? "yes" : "no");

  // print PDF version
  printf("PDF version:  %.1f\n", doc->getPDFVersion());

  // print the metadata
  if (printMetadata && (metadata = doc->readMetadata())) {
    fputs("Metadata:\n", stdout);
    fputs(metadata->getCString(), stdout);
    fputc('\n', stdout);
    delete metadata;
  }

  exitCode = 0;

  // clean up
 err2:
  uMap->decRefCnt();
  delete doc;
 err1:
  delete globalParams;
 err0:

  // check for memory leaks
  Object::memCheck(stderr);
  gMemReport(stderr);

  return exitCode;
}

static void printInfoString(Dict *infoDict, char *key, char *text,
			    UnicodeMap *uMap) {
  Object obj;
  GString *s1;
  GBool isUnicode;
  Unicode u;
  char buf[8];
  int i, n;

  if (infoDict->lookup(key, &obj)->isString()) {
    fputs(text, stdout);
    s1 = obj.getString();
    if ((s1->getChar(0) & 0xff) == 0xfe &&
	(s1->getChar(1) & 0xff) == 0xff) {
      isUnicode = gTrue;
      i = 2;
    } else {
      isUnicode = gFalse;
      i = 0;
    }
    while (i < obj.getString()->getLength()) {
      if (isUnicode) {
	u = ((s1->getChar(i) & 0xff) << 8) |
	    (s1->getChar(i+1) & 0xff);
	i += 2;
      } else {
	u = s1->getChar(i) & 0xff;
	++i;
      }
      n = uMap->mapUnicode(u, buf, sizeof(buf));
      fwrite(buf, 1, n, stdout);
    }
    fputc('\n', stdout);
  }
  obj.free();
}

static void printInfoDate(Dict *infoDict, char *key, char *text) {
  Object obj;
  char *s;
  int year, mon, day, hour, min, sec;
  struct tm tmStruct;
  char buf[256];

  if (infoDict->lookup(key, &obj)->isString()) {
    fputs(text, stdout);
    s = obj.getString()->getCString();
    if (s[0] == 'D' && s[1] == ':') {
      s += 2;
    }
    if (sscanf(s, "%4d%2d%2d%2d%2d%2d",
	       &year, &mon, &day, &hour, &min, &sec) == 6) {
      tmStruct.tm_year = year - 1900;
      tmStruct.tm_mon = mon - 1;
      tmStruct.tm_mday = day;
      tmStruct.tm_hour = hour;
      tmStruct.tm_min = min;
      tmStruct.tm_sec = sec;
      tmStruct.tm_wday = -1;
      tmStruct.tm_yday = -1;
      tmStruct.tm_isdst = -1;
      // compute the tm_wday and tm_yday fields
      if (mktime(&tmStruct) != (time_t)-1 &&
	  strftime(buf, sizeof(buf), "%c", &tmStruct)) {
	fputs(buf, stdout);
      } else {
	fputs(s, stdout);
      }
    } else {
      fputs(s, stdout);
    }
    fputc('\n', stdout);
  }
  obj.free();
}
