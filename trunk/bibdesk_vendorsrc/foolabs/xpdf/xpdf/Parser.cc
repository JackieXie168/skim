//========================================================================
//
// Parser.cc
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
#include "Parser.h"
#include "XRef.h"
#include "Error.h"
#ifndef NO_DECRYPTION
#include "Decrypt.h"
#endif

Parser::Parser(XRef *xrefA, Lexer *lexerA) {
  xref = xrefA;
  lexer = lexerA;
  inlineImg = 0;
  lexer->getObj(&buf1);
  lexer->getObj(&buf2);
}

Parser::~Parser() {
  buf1.free();
  buf2.free();
  delete lexer;
}

#ifndef NO_DECRYPTION
Object *Parser::getObj(Object *obj,
		       Guchar *fileKey, int keyLength,
		       int objNum, int objGen) {
#else
Object *Parser::getObj(Object *obj) {
#endif
  char *key;
  Stream *str;
  Object obj2;
  int num;
#ifndef NO_DECRYPTION
  Decrypt *decrypt;
  GString *s;
  char *p;
  int i;
#endif

  // refill buffer after inline image data
  if (inlineImg == 2) {
    buf1.free();
    buf2.free();
    lexer->getObj(&buf1);
    lexer->getObj(&buf2);
    inlineImg = 0;
  }

  // array
  if (buf1.isCmd("[")) {
    shift();
    obj->initArray(xref);
    while (!buf1.isCmd("]") && !buf1.isEOF())
#ifndef NO_DECRYPTION
      obj->arrayAdd(getObj(&obj2, fileKey, keyLength, objNum, objGen));
#else
      obj->arrayAdd(getObj(&obj2));
#endif
    if (buf1.isEOF())
      error(getPos(), "End of file inside array");
    shift();

  // dictionary or stream
  } else if (buf1.isCmd("<<")) {
    shift();
    obj->initDict(xref);
    while (!buf1.isCmd(">>") && !buf1.isEOF()) {
      if (!buf1.isName()) {
	error(getPos(), "Dictionary key must be a name object");
	shift();
      } else {
	key = copyString(buf1.getName());
	shift();
	if (buf1.isEOF() || buf1.isError()) {
	  gfree(key);
	  break;
	}
#ifndef NO_DECRYPTION
	obj->dictAdd(key, getObj(&obj2, fileKey, keyLength, objNum, objGen));
#else
	obj->dictAdd(key, getObj(&obj2));
#endif
      }
    }
    if (buf1.isEOF())
      error(getPos(), "End of file inside dictionary");
    if (buf2.isCmd("stream")) {
      if ((str = makeStream(obj))) {
	obj->initStream(str);
#ifndef NO_DECRYPTION
	if (fileKey) {
	  str->getBaseStream()->doDecryption(fileKey, keyLength,
					     objNum, objGen);
	}
#endif
      } else {
	obj->free();
	obj->initError();
      }
    } else {
      shift();
    }

  // indirect reference or integer
  } else if (buf1.isInt()) {
    num = buf1.getInt();
    shift();
    if (buf1.isInt() && buf2.isCmd("R")) {
      obj->initRef(num, buf1.getInt());
      shift();
      shift();
    } else {
      obj->initInt(num);
    }

#ifndef NO_DECRYPTION
  // string
  } else if (buf1.isString() && fileKey) {
    buf1.copy(obj);
    s = obj->getString();
    decrypt = new Decrypt(fileKey, keyLength, objNum, objGen);
    for (i = 0, p = obj->getString()->getCString();
	 i < s->getLength();
	 ++i, ++p) {
      *p = decrypt->decryptByte(*p);
    }
    delete decrypt;
    shift();
#endif

  // simple object
  } else {
    buf1.copy(obj);
    shift();
  }

  return obj;
}

Stream *Parser::makeStream(Object *dict) {
  Object obj;
  Stream *str;
  Guint pos, endPos, length;

  // get stream start position
  lexer->skipToNextLine();
  pos = lexer->getPos();

  // get length
  dict->dictLookup("Length", &obj);
  if (obj.isInt()) {
    length = (Guint)obj.getInt();
    obj.free();
  } else {
    error(getPos(), "Bad 'Length' attribute in stream");
    obj.free();
    return NULL;
  }

  // check for length in damaged file
  if (xref->getStreamEnd(pos, &endPos)) {
    length = endPos - pos;
  }

  // make base stream
  str = lexer->getStream()->getBaseStream()->makeSubStream(pos, gTrue,
							   length, dict);

  // get filters
  str = str->addFilters(dict);

  // skip over stream data
  lexer->setPos(pos + length);

  // refill token buffers and check for 'endstream'
  shift();  // kill '>>'
  shift();  // kill 'stream'
  if (buf1.isCmd("endstream"))
    shift();
  else
    error(getPos(), "Missing 'endstream'");

  return str;
}

void Parser::shift() {
  if (inlineImg > 0) {
    if (inlineImg < 2) {
      ++inlineImg;
    } else {
      // in a damaged content stream, if 'ID' shows up in the middle
      // of a dictionary, we need to reset
      inlineImg = 0;
    }
  } else if (buf2.isCmd("ID")) {
    lexer->skipChar();		// skip char after 'ID' command
    inlineImg = 1;
  }
  buf1.free();
  buf1 = buf2;
  if (inlineImg > 0)		// don't buffer inline image data
    buf2.initNull();
  else
    lexer->getObj(&buf2);
}
