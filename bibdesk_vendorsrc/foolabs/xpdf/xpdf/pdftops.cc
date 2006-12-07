//========================================================================
//
// pdftops.cc
//
// Copyright 1996-2002 Glyph & Cog, LLC
//
//========================================================================

#include <aconf.h>
#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>
#include <string.h>
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
#include "PSOutputDev.h"
#include "Error.h"
#include "config.h"

static int firstPage = 1;
static int lastPage = 0;
static GBool level1 = gFalse;
static GBool level1Sep = gFalse;
static GBool level2 = gFalse;
static GBool level2Sep = gFalse;
static GBool level3 = gFalse;
static GBool level3Sep = gFalse;
static GBool doEPS = gFalse;
static GBool doForm = gFalse;
#if OPI_SUPPORT
static GBool doOPI = gFalse;
#endif
static GBool noEmbedT1Fonts = gFalse;
static GBool noEmbedTTFonts = gFalse;
static GBool noEmbedCIDPSFonts = gFalse;
static GBool noEmbedCIDTTFonts = gFalse;
static char paperSize[15] = "";
static int paperWidth = 0;
static int paperHeight = 0;
static GBool duplex = gFalse;
static char ownerPassword[33] = "";
static char userPassword[33] = "";
static GBool quiet = gFalse;
static char cfgFileName[256] = "";
static GBool printVersion = gFalse;
static GBool printHelp = gFalse;

static ArgDesc argDesc[] = {
  {"-f",      argInt,      &firstPage,      0,
   "first page to print"},
  {"-l",      argInt,      &lastPage,       0,
   "last page to print"},
  {"-level1", argFlag,     &level1,         0,
   "generate Level 1 PostScript"},
  {"-level1sep", argFlag,  &level1Sep,      0,
   "generate Level 1 separable PostScript"},
  {"-level2", argFlag,     &level2,         0,
   "generate Level 2 PostScript"},
  {"-level2sep", argFlag,  &level2Sep,      0,
   "generate Level 2 separable PostScript"},
  {"-level3", argFlag,     &level3,         0,
   "generate Level 3 PostScript"},
  {"-level3sep", argFlag,  &level3Sep,      0,
   "generate Level 3 separable PostScript"},
  {"-eps",    argFlag,     &doEPS,          0,
   "generate Encapsulated PostScript (EPS)"},
  {"-form",   argFlag,     &doForm,         0,
   "generate a PostScript form"},
#if OPI_SUPPORT
  {"-opi",    argFlag,     &doOPI,          0,
   "generate OPI comments"},
#endif
  {"-noembt1", argFlag,     &noEmbedT1Fonts, 0,
   "don't embed Type 1 fonts"},
  {"-noembtt", argFlag,    &noEmbedTTFonts, 0,
   "don't embed TrueType fonts"},
  {"-noembcidps", argFlag, &noEmbedCIDPSFonts, 0,
   "don't embed CID PostScript fonts"},
  {"-noembcidtt", argFlag, &noEmbedCIDTTFonts, 0,
   "don't embed CID TrueType fonts"},
  {"-paper",  argString,   paperSize,       sizeof(paperSize),
   "paper size (letter, legal, A4, A3)"},
  {"-paperw", argInt,      &paperWidth,     0,
   "paper width, in points"},
  {"-paperh", argInt,      &paperHeight,    0,
   "paper height, in points"},
  {"-duplex", argFlag,     &duplex,         0,
   "enable duplex printing"},
  {"-opw",    argString,   ownerPassword,   sizeof(ownerPassword),
   "owner password (for encrypted files)"},
  {"-upw",    argString,   userPassword,    sizeof(userPassword),
   "user password (for encrypted files)"},
  {"-q",      argFlag,     &quiet,          0,
   "don't print any messages or errors"},
  {"-cfg",        argString,      cfgFileName,    sizeof(cfgFileName),
   "configuration file to use in place of .xpdfrc"},
  {"-v",      argFlag,     &printVersion,   0,
   "print copyright and version info"},
  {"-h",      argFlag,     &printHelp,      0,
   "print usage information"},
  {"-help",   argFlag,     &printHelp,      0,
   "print usage information"},
  {"--help",  argFlag,     &printHelp,      0,
   "print usage information"},
  {"-?",      argFlag,     &printHelp,      0,
   "print usage information"},
  {NULL}
};

int main(int argc, char *argv[]) {
  PDFDoc *doc;
  GString *fileName;
  GString *psFileName;
  PSLevel level;
  PSOutMode mode;
  GString *ownerPW, *userPW;
  PSOutputDev *psOut;
  GBool ok;
  char *p;
  int exitCode;

  exitCode = 99;

  // parse args
  ok = parseArgs(argDesc, &argc, argv);
  if (!ok || argc < 2 || argc > 3 || printVersion || printHelp) {
    fprintf(stderr, "pdftops version %s\n", xpdfVersion);
    fprintf(stderr, "%s\n", xpdfCopyright);
    if (!printVersion) {
      printUsage("pdftops", "<PDF-file> [<PS-file>]", argDesc);
    }
    exit(1);
  }
  if ((level1 ? 1 : 0) +
      (level1Sep ? 1 : 0) +
      (level2 ? 1 : 0) +
      (level2Sep ? 1 : 0) +
      (level3 ? 1 : 0) +
      (level3Sep ? 1 : 0) > 1) {
    fprintf(stderr, "Error: use only one of the 'level' options.\n");
    exit(1);
  }
  if (doEPS && doForm) {
    fprintf(stderr, "Error: use only one of -eps and -form\n");
    exit(1);
  }
  if (level1) {
    level = psLevel1;
  } else if (level1Sep) {
    level = psLevel1Sep;
  } else if (level2Sep) {
    level = psLevel2Sep;
  } else if (level3) {
    level = psLevel3;
  } else if (level3Sep) {
    level = psLevel3Sep;
  } else {
    level = psLevel2;
  }
  if (doForm && level < psLevel2) {
    fprintf(stderr, "Error: forms are only available with Level 2 output.\n");
    exit(1);
  }
  mode = doEPS ? psModeEPS
               : doForm ? psModeForm
                        : psModePS;
  fileName = new GString(argv[1]);

  // read config file
  globalParams = new GlobalParams(cfgFileName);
  if (paperSize[0]) {
    if (!globalParams->setPSPaperSize(paperSize)) {
      fprintf(stderr, "Invalid paper size\n");
      goto err0;
    }
  } else {
    if (paperWidth) {
      globalParams->setPSPaperWidth(paperWidth);
    }
    if (paperHeight) {
      globalParams->setPSPaperHeight(paperHeight);
    }
  }
  if (duplex) {
    globalParams->setPSDuplex(duplex);
  }
  if (level1 || level1Sep || level2 || level2Sep || level3 || level3Sep) {
    globalParams->setPSLevel(level);
  }
  if (noEmbedT1Fonts) {
    globalParams->setPSEmbedType1(!noEmbedT1Fonts);
  }
  if (noEmbedTTFonts) {
    globalParams->setPSEmbedTrueType(!noEmbedTTFonts);
  }
  if (noEmbedCIDPSFonts) {
    globalParams->setPSEmbedCIDPostScript(!noEmbedCIDPSFonts);
  }
  if (noEmbedCIDTTFonts) {
    globalParams->setPSEmbedCIDTrueType(!noEmbedCIDTTFonts);
  }
#if OPI_SUPPORT
  if (doOPI) {
    globalParams->setPSOPI(doOPI);
  }
#endif
  if (quiet) {
    globalParams->setErrQuiet(quiet);
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
    goto err1;
  }

  // check for print permission
  if (!doc->okToPrint()) {
    error(-1, "Printing this document is not allowed.");
    exitCode = 3;
    goto err1;
  }

  // construct PostScript file name
  if (argc == 3) {
    psFileName = new GString(argv[2]);
  } else {
    p = fileName->getCString() + fileName->getLength() - 4;
    if (!strcmp(p, ".pdf") || !strcmp(p, ".PDF")) {
      psFileName = new GString(fileName->getCString(),
			       fileName->getLength() - 4);
    } else {
      psFileName = fileName->copy();
    }
    psFileName->append(doEPS ? ".eps" : ".ps");
  }

  // get page range
  if (firstPage < 1) {
    firstPage = 1;
  }
  if (lastPage < 1 || lastPage > doc->getNumPages()) {
    lastPage = doc->getNumPages();
  }

  // check for multi-page EPS or form
  if ((doEPS || doForm) && firstPage != lastPage) {
    error(-1, "EPS and form files can only contain one page.");
    goto err2;
  }

  // write PostScript file
  psOut = new PSOutputDev(psFileName->getCString(), doc->getXRef(),
			  doc->getCatalog(), firstPage, lastPage, mode);
  if (psOut->isOk()) {
    doc->displayPages(psOut, firstPage, lastPage, 72, 0, gFalse);
  } else {
    delete psOut;
    exitCode = 2;
    goto err2;
  }
  delete psOut;

  exitCode = 0;

  // clean up
 err2:
  delete psFileName;
 err1:
  delete doc;
  delete globalParams;
 err0:

  // check for memory leaks
  Object::memCheck(stderr);
  gMemReport(stderr);

  return exitCode;
}
