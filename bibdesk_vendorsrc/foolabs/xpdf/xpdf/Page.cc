//========================================================================
//
// Page.cc
//
// Copyright 1996-2002 Glyph & Cog, LLC
//
//========================================================================

#include <aconf.h>

#ifdef USE_GCC_PRAGMAS
#pragma implementation
#endif

#include <stddef.h>
#include "GlobalParams.h"
#include "Object.h"
#include "Array.h"
#include "Dict.h"
#include "XRef.h"
#include "Link.h"
#include "OutputDev.h"
#ifndef PDF_PARSER_ONLY
#include "Gfx.h"
#include "Annot.h"
#endif
#include "Error.h"
#include "Page.h"

//------------------------------------------------------------------------
// PageAttrs
//------------------------------------------------------------------------

PageAttrs::PageAttrs(PageAttrs *attrs, Dict *dict) {
  Object obj1;
  double w, h;

  // get old/default values
  if (attrs) {
    mediaBox = attrs->mediaBox;
    cropBox = attrs->cropBox;
    haveCropBox = attrs->haveCropBox;
    rotate = attrs->rotate;
    attrs->resources.copy(&resources);
  } else {
    // set default MediaBox to 8.5" x 11" -- this shouldn't be necessary
    // but some (non-compliant) PDF files don't specify a MediaBox
    mediaBox.x1 = 0;
    mediaBox.y1 = 0;
    mediaBox.x2 = 612;
    mediaBox.y2 = 792;
    cropBox.x1 = cropBox.y1 = cropBox.x2 = cropBox.y2 = 0;
    haveCropBox = gFalse;
    rotate = 0;
    resources.initNull();
  }

  // media box
  readBox(dict, "MediaBox", &mediaBox);

  // crop box
  cropBox = mediaBox;
  haveCropBox = readBox(dict, "CropBox", &cropBox);

  // if the MediaBox is excessively larger than the CropBox,
  // just use the CropBox
  limitToCropBox = gFalse;
  if (haveCropBox) {
    w = 0.25 * (cropBox.x2 - cropBox.x1);
    h = 0.25 * (cropBox.y2 - cropBox.y1);
    if ((cropBox.x1 - mediaBox.x1) + (mediaBox.x2 - cropBox.x2) > w ||
	(cropBox.y1 - mediaBox.y1) + (mediaBox.y2 - cropBox.y2) > h) {
      limitToCropBox = gTrue;
    }
  }

  // other boxes
  bleedBox = cropBox;
  readBox(dict, "BleedBox", &bleedBox);
  trimBox = cropBox;
  readBox(dict, "TrimBox", &trimBox);
  artBox = cropBox;
  readBox(dict, "ArtBox", &artBox);

  // rotate
  dict->lookup("Rotate", &obj1);
  if (obj1.isInt()) {
    rotate = obj1.getInt();
  }
  obj1.free();
  while (rotate < 0) {
    rotate += 360;
  }
  while (rotate >= 360) {
    rotate -= 360;
  }

  // misc attributes
  dict->lookup("LastModified", &lastModified);
  dict->lookup("BoxColorInfo", &boxColorInfo);
  dict->lookup("Group", &group);
  dict->lookup("Metadata", &metadata);
  dict->lookup("PieceInfo", &pieceInfo);
  dict->lookup("SeparationInfo", &separationInfo);

  // resource dictionary
  dict->lookup("Resources", &obj1);
  if (obj1.isDict()) {
    resources.free();
    obj1.copy(&resources);
  }
  obj1.free();
}

PageAttrs::~PageAttrs() {
  lastModified.free();
  boxColorInfo.free();
  group.free();
  metadata.free();
  pieceInfo.free();
  separationInfo.free();
  resources.free();
}

GBool PageAttrs::readBox(Dict *dict, char *key, PDFRectangle *box) {
  PDFRectangle tmp;
  Object obj1, obj2;
  GBool ok;

  dict->lookup(key, &obj1);
  if (obj1.isArray() && obj1.arrayGetLength() == 4) {
    ok = gTrue;
    obj1.arrayGet(0, &obj2);
    if (obj2.isNum()) {
      tmp.x1 = obj2.getNum();
    } else {
      ok = gFalse;
    }
    obj2.free();
    obj1.arrayGet(1, &obj2);
    if (obj2.isNum()) {
      tmp.y1 = obj2.getNum();
    } else {
      ok = gFalse;
    }
    obj2.free();
    obj1.arrayGet(2, &obj2);
    if (obj2.isNum()) {
      tmp.x2 = obj2.getNum();
    } else {
      ok = gFalse;
    }
    obj2.free();
    obj1.arrayGet(3, &obj2);
    if (obj2.isNum()) {
      tmp.y2 = obj2.getNum();
    } else {
      ok = gFalse;
    }
    obj2.free();
    if (ok) {
      *box = tmp;
    }
  } else {
    ok = gFalse;
  }
  obj1.free();
  return ok;
}

//------------------------------------------------------------------------
// Page
//------------------------------------------------------------------------

Page::Page(XRef *xrefA, int numA, Dict *pageDict, PageAttrs *attrsA) {
  ok = gTrue;
  xref = xrefA;
  num = numA;

  // get attributes
  attrs = attrsA;

  // annotations
  pageDict->lookupNF("Annots", &annots);
  if (!(annots.isRef() || annots.isArray() || annots.isNull())) {
    error(-1, "Page annotations object (page %d) is wrong type (%s)",
	  num, annots.getTypeName());
    annots.free();
    goto err2;
  }

  // contents
  pageDict->lookupNF("Contents", &contents);
  if (!(contents.isRef() || contents.isArray() ||
	contents.isNull())) {
    error(-1, "Page contents object (page %d) is wrong type (%s)",
	  num, contents.getTypeName());
    contents.free();
    goto err1;
  }

  return;

 err2:
  annots.initNull();
 err1:
  contents.initNull();
  ok = gFalse;
}

Page::~Page() {
  delete attrs;
  annots.free();
  contents.free();
}

void Page::display(OutputDev *out, double dpi, int rotate,
		   Links *links, Catalog *catalog,
		   GBool (*abortCheckCbk)(void *data),
		   void *abortCheckCbkData) {
  displaySlice(out, dpi, rotate, -1, -1, -1, -1, links, catalog,
	       abortCheckCbk, abortCheckCbkData);
}

void Page::displaySlice(OutputDev *out, double dpi, int rotate,
			int sliceX, int sliceY, int sliceW, int sliceH,
			Links *links, Catalog *catalog,
			GBool (*abortCheckCbk)(void *data),
			void *abortCheckCbkData) {
#ifndef PDF_PARSER_ONLY
  PDFRectangle *mediaBox, *cropBox;
  PDFRectangle box;
  Gfx *gfx;
  Object obj;
  Link *link;
  Annots *annotList;
  double k;
  int i;

  rotate += getRotate();
  if (rotate >= 360) {
    rotate -= 360;
  } else if (rotate < 0) {
    rotate += 360;
  }

  mediaBox = getBox();
  if (sliceW >= 0 && sliceH >= 0) {
    k = 72.0 / dpi;
    if (rotate == 90) {
      if (out->upsideDown()) {
	box.x1 = mediaBox->x1 + k * sliceY;
	box.x2 = mediaBox->x1 + k * (sliceY + sliceH);
      } else {
	box.x1 = mediaBox->x2 - k * (sliceY + sliceH);
	box.x2 = mediaBox->x2 - k * sliceY;
      }
      box.y1 = mediaBox->y1 + k * sliceX;
      box.y2 = mediaBox->y1 + k * (sliceX + sliceW);
    } else if (rotate == 180) {
      box.x1 = mediaBox->x2 - k * (sliceX + sliceW);
      box.x2 = mediaBox->x2 - k * sliceX;
      if (out->upsideDown()) {
	box.y1 = mediaBox->y1 + k * sliceY;
	box.y2 = mediaBox->y1 + k * (sliceY + sliceH);
      } else {
	box.y1 = mediaBox->y2 - k * (sliceY + sliceH);
	box.y2 = mediaBox->y2 - k * sliceY;
      }
    } else if (rotate == 270) {
      if (out->upsideDown()) {
	box.x1 = mediaBox->x2 - k * (sliceY + sliceH);
	box.x2 = mediaBox->x2 - k * sliceY;
      } else {
	box.x1 = mediaBox->x1 + k * sliceY;
	box.x2 = mediaBox->x1 + k * (sliceY + sliceH);
      }
      box.y1 = mediaBox->y2 - k * (sliceX + sliceW);
      box.y2 = mediaBox->y2 - k * sliceX;
    } else {
      box.x1 = mediaBox->x1 + k * sliceX;
      box.x2 = mediaBox->x1 + k * (sliceX + sliceW);
      if (out->upsideDown()) {
	box.y1 = mediaBox->y2 - k * (sliceY + sliceH);
	box.y2 = mediaBox->y2 - k * sliceY;
      } else {
	box.y1 = mediaBox->y1 + k * sliceY;
	box.y2 = mediaBox->y1 + k * (sliceY + sliceH);
      }
    }
  } else {
    box = *mediaBox;
  }
  cropBox = getCropBox();

  if (globalParams->getPrintCommands()) {
    printf("***** MediaBox = ll:%g,%g ur:%g,%g\n",
	   box.x1, box.y1, box.x2, box.y2);
    if (isCropped()) {
      printf("***** CropBox = ll:%g,%g ur:%g,%g\n",
	     cropBox->x1, cropBox->y1, cropBox->x2, cropBox->y2);
    }
    printf("***** Rotate = %d\n", attrs->getRotate());
  }

  gfx = new Gfx(xref, out, num, attrs->getResourceDict(),
		dpi, &box, isCropped(), cropBox, rotate,
		abortCheckCbk, abortCheckCbkData);
  contents.fetch(xref, &obj);
  if (!obj.isNull()) {
    gfx->display(&obj);
  }
  obj.free();

  // draw links
  if (links) {
    for (i = 0; i < links->getNumLinks(); ++i) {
      link = links->getLink(i);
      out->drawLink(link, catalog);
    }
    out->dump();
  }

  // draw non-link annotations
  //~ need to reset CTM ???
  annotList = new Annots(xref, annots.fetch(xref, &obj));
  obj.free();
  if (annotList->getNumAnnots() > 0) {
    if (globalParams->getPrintCommands()) {
      printf("***** Annotations\n");
    }
    for (i = 0; i < annotList->getNumAnnots(); ++i) {
      annotList->getAnnot(i)->draw(gfx);
    }
    out->dump();
  }
  delete annotList;

  delete gfx;
#endif
}
