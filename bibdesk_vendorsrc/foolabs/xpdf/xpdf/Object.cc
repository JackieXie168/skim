//========================================================================
//
// Object.cc
//
// Copyright 1996-2002 Glyph & Cog, LLC
//
//========================================================================

#include <aconf.h>

#ifdef USE_GCC_PRAGMAS
#pragma implementation
#endif

#include <stddef.h>
#include "Object.h"
#include "Array.h"
#include "Dict.h"
#include "Error.h"
#include "Stream.h"
#include "XRef.h"

//------------------------------------------------------------------------
// Object
//------------------------------------------------------------------------

char *objTypeNames[numObjTypes] = {
  "boolean",
  "integer",
  "real",
  "string",
  "name",
  "null",
  "array",
  "dictionary",
  "stream",
  "ref",
  "cmd",
  "error",
  "eof",
  "none"
};

#ifdef DEBUG_MEM
int Object::numAlloc[numObjTypes] =
  {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
#endif

Object *Object::initArray(XRef *xref) {
  initObj(objArray);
  array = new Array(xref);
  return this;
}

Object *Object::initDict(XRef *xref) {
  initObj(objDict);
  dict = new Dict(xref);
  return this;
}

Object *Object::initStream(Stream *streamA) {
  initObj(objStream);
  stream = streamA;
  return this;
}

Object *Object::copy(Object *obj) {
  *obj = *this;
  switch (type) {
  case objString:
    obj->string = string->copy();
    break;
  case objName:
    obj->name = copyString(name);
    break;
  case objArray:
    array->incRef();
    break;
  case objDict:
    dict->incRef();
    break;
  case objStream:
    stream->incRef();
    break;
  case objCmd:
    obj->cmd = copyString(cmd);
    break;
  default:
    break;
  }
#ifdef DEBUG_MEM
  ++numAlloc[type];
#endif
  return obj;
}

Object *Object::fetch(XRef *xref, Object *obj) {
  return (type == objRef && xref) ?
         xref->fetch(ref.num, ref.gen, obj) : copy(obj);
}

void Object::free() {
  switch (type) {
  case objString:
    delete string;
    break;
  case objName:
    gfree(name);
    break;
  case objArray:
    if (!array->decRef()) {
      delete array;
    }
    break;
  case objDict:
    if (!dict->decRef()) {
      delete dict;
    }
    break;
  case objStream:
    if (!stream->decRef()) {
      delete stream;
    }
    break;
  case objCmd:
    gfree(cmd);
    break;
  default:
    break;
  }
#ifdef DEBUG_MEM
  --numAlloc[type];
#endif
  type = objNone;
}

char *Object::getTypeName() {
  return objTypeNames[type];
}

void Object::print(FILE *f) {
  Object obj;
  int i;

  switch (type) {
  case objBool:
    fprintf(f, "%s", booln ? "true" : "false");
    break;
  case objInt:
    fprintf(f, "%d", intg);
    break;
  case objReal:
    fprintf(f, "%g", real);
    break;
  case objString:
    fprintf(f, "(");
    fwrite(string->getCString(), 1, string->getLength(), stdout);
    fprintf(f, ")");
    break;
  case objName:
    fprintf(f, "/%s", name);
    break;
  case objNull:
    fprintf(f, "null");
    break;
  case objArray:
    fprintf(f, "[");
    for (i = 0; i < arrayGetLength(); ++i) {
      if (i > 0)
	fprintf(f, " ");
      arrayGetNF(i, &obj);
      obj.print(f);
      obj.free();
    }
    fprintf(f, "]");
    break;
  case objDict:
    fprintf(f, "<<");
    for (i = 0; i < dictGetLength(); ++i) {
      fprintf(f, " /%s ", dictGetKey(i));
      dictGetValNF(i, &obj);
      obj.print(f);
      obj.free();
    }
    fprintf(f, " >>");
    break;
  case objStream:
    fprintf(f, "<stream>");
    break;
  case objRef:
    fprintf(f, "%d %d R", ref.num, ref.gen);
    break;
  case objCmd:
    fprintf(f, "%s", cmd);
    break;
  case objError:
    fprintf(f, "<error>");
    break;
  case objEOF:
    fprintf(f, "<EOF>");
    break;
  case objNone:
    fprintf(f, "<none>");
    break;
  }
}

void Object::memCheck(FILE *f) {
#ifdef DEBUG_MEM
  int i;
  int t;

  t = 0;
  for (i = 0; i < numObjTypes; ++i)
    t += numAlloc[i];
  if (t > 0) {
    fprintf(f, "Allocated objects:\n");
    for (i = 0; i < numObjTypes; ++i) {
      if (numAlloc[i] > 0)
	fprintf(f, "  %-20s: %6d\n", objTypeNames[i], numAlloc[i]);
    }
  }
#endif
}
