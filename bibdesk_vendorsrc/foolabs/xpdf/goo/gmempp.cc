//========================================================================
//
// gmempp.cc
//
// Use gmalloc/gfree for C++ new/delete operators.
//
// Copyright 1996-2002 Glyph & Cog, LLC
//
//========================================================================

#include <aconf.h>
#include "gmem.h"

#ifdef DEBUG_MEM

void *operator new(size_t size) {
  return gmalloc((int)size);
}

void *operator new[](size_t size) {
  return gmalloc((int)size);
}

void operator delete(void *p) {
  gfree(p);
}

void operator delete[](void *p) {
  gfree(p);
}

#endif
