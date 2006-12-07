//========================================================================
//
// ImageOutputDev.cc
//
// Copyright 1998-2002 Glyph & Cog, LLC
//
//========================================================================

#include <aconf.h>

#ifdef USE_GCC_PRAGMAS
#pragma implementation
#endif

#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>
#include <ctype.h>
#include "gmem.h"
#include "config.h"
#include "Error.h"
#include "GfxState.h"
#include "Object.h"
#include "Stream.h"
#include "ImageOutputDev.h"

ImageOutputDev::ImageOutputDev(char *fileRootA, GBool dumpJPEGA) {
  fileRoot = copyString(fileRootA);
  fileName = (char *)gmalloc(strlen(fileRoot) + 20);
  dumpJPEG = dumpJPEGA;
  imgNum = 0;
  ok = gTrue;
}

ImageOutputDev::~ImageOutputDev() {
  gfree(fileName);
  gfree(fileRoot);
}

void ImageOutputDev::drawImageMask(GfxState *state, Object *ref, Stream *str,
				   int width, int height, GBool invert,
				   GBool inlineImg) {
  FILE *f;
  int c;
  int size, i;

  // dump JPEG file
  if (dumpJPEG && str->getKind() == strDCT && !inlineImg) {

    // open the image file
    sprintf(fileName, "%s-%03d.jpg", fileRoot, imgNum);
    ++imgNum;
    if (!(f = fopen(fileName, "wb"))) {
      error(-1, "Couldn't open image file '%s'", fileName);
      return;
    }

    // initialize stream
    str = ((DCTStream *)str)->getRawStream();
    str->reset();

    // copy the stream
    while ((c = str->getChar()) != EOF)
      fputc(c, f);

    str->close();
    fclose(f);

  // dump PBM file
  } else {

    // open the image file and write the PBM header
    sprintf(fileName, "%s-%03d.pbm", fileRoot, imgNum);
    ++imgNum;
    if (!(f = fopen(fileName, "wb"))) {
      error(-1, "Couldn't open image file '%s'", fileName);
      return;
    }
    fprintf(f, "P4\n");
    fprintf(f, "%d %d\n", width, height);

    // initialize stream
    str->reset();

    // copy the stream
    size = height * ((width + 7) / 8);
    for (i = 0; i < size; ++i) {
      fputc(str->getChar(), f);
    }

    str->close();
    fclose(f);
  }
}

void ImageOutputDev::drawImage(GfxState *state, Object *ref, Stream *str,
			       int width, int height,
			       GfxImageColorMap *colorMap,
			       int *maskColors, GBool inlineImg) {
  FILE *f;
  ImageStream *imgStr;
  Guchar *p;
  GfxRGB rgb;
  int x, y;
  int c;
  int size, i;

  // dump JPEG file
  if (dumpJPEG && str->getKind() == strDCT &&
      colorMap->getNumPixelComps() == 3 &&
      !inlineImg) {

    // open the image file
    sprintf(fileName, "%s-%03d.jpg", fileRoot, imgNum);
    ++imgNum;
    if (!(f = fopen(fileName, "wb"))) {
      error(-1, "Couldn't open image file '%s'", fileName);
      return;
    }

    // initialize stream
    str = ((DCTStream *)str)->getRawStream();
    str->reset();

    // copy the stream
    while ((c = str->getChar()) != EOF)
      fputc(c, f);

    str->close();
    fclose(f);

  // dump PBM file
  } else if (colorMap->getNumPixelComps() == 1 &&
	     colorMap->getBits() == 1) {

    // open the image file and write the PBM header
    sprintf(fileName, "%s-%03d.pbm", fileRoot, imgNum);
    ++imgNum;
    if (!(f = fopen(fileName, "wb"))) {
      error(-1, "Couldn't open image file '%s'", fileName);
      return;
    }
    fprintf(f, "P4\n");
    fprintf(f, "%d %d\n", width, height);

    // initialize stream
    str->reset();

    // copy the stream
    size = height * ((width + 7) / 8);
    for (i = 0; i < size; ++i) {
      fputc(str->getChar() ^ 0xff, f);
    }

    str->close();
    fclose(f);

  // dump PPM file
  } else {

    // open the image file and write the PPM header
    sprintf(fileName, "%s-%03d.ppm", fileRoot, imgNum);
    ++imgNum;
    if (!(f = fopen(fileName, "wb"))) {
      error(-1, "Couldn't open image file '%s'", fileName);
      return;
    }
    fprintf(f, "P6\n");
    fprintf(f, "%d %d\n", width, height);
    fprintf(f, "255\n");

    // initialize stream
    imgStr = new ImageStream(str, width, colorMap->getNumPixelComps(),
			     colorMap->getBits());
    imgStr->reset();

    // for each line...
    for (y = 0; y < height; ++y) {

      // write the line
      p = imgStr->getLine();
      for (x = 0; x < width; ++x) {
	colorMap->getRGB(p, &rgb);
	fputc((int)(rgb.r * 255 + 0.5), f);
	fputc((int)(rgb.g * 255 + 0.5), f);
	fputc((int)(rgb.b * 255 + 0.5), f);
	p += colorMap->getNumPixelComps();
      }
    }
    delete imgStr;

    fclose(f);
  }
}
