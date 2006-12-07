//========================================================================
//
// CMap.cc
//
// Copyright 2001-2002 Glyph & Cog, LLC
//
//========================================================================

#include <aconf.h>

#ifdef USE_GCC_PRAGMAS
#pragma implementation
#endif

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include "gmem.h"
#include "gfile.h"
#include "GString.h"
#include "Error.h"
#include "GlobalParams.h"
#include "PSTokenizer.h"
#include "CMap.h"

//------------------------------------------------------------------------

struct CMapVectorEntry {
  GBool isVector;
  union {
    CMapVectorEntry *vector;
    CID cid;
  };
};

//------------------------------------------------------------------------

static int getCharFromFile(void *data) {
  return fgetc((FILE *)data);
}

//------------------------------------------------------------------------

CMap *CMap::parse(CMapCache *cache, GString *collectionA,
		  GString *cMapNameA) {
  FILE *f;
  CMap *cmap;
  PSTokenizer *pst;
  char tok1[256], tok2[256], tok3[256];
  int n1, n2, n3;
  Guint start, end;

  if (!(f = globalParams->findCMapFile(collectionA, cMapNameA))) {

    // Check for an identity CMap.
    if (!cMapNameA->cmp("Identity") || !cMapNameA->cmp("Identity-H")) {
      return new CMap(collectionA->copy(), cMapNameA->copy(), 0);
    }
    if (!cMapNameA->cmp("Identity-V")) {
      return new CMap(collectionA->copy(), cMapNameA->copy(), 1);
    }

    error(-1, "Couldn't find '%s' CMap file for '%s' collection",
	  cMapNameA->getCString(), collectionA->getCString());
    return NULL;
  }

  cmap = new CMap(collectionA->copy(), cMapNameA->copy());

  pst = new PSTokenizer(&getCharFromFile, f);
  pst->getToken(tok1, sizeof(tok1), &n1);
  while (pst->getToken(tok2, sizeof(tok2), &n2)) {
    if (!strcmp(tok2, "usecmap")) {
      if (tok1[0] == '/') {
	cmap->useCMap(cache, tok1 + 1);
      }
      pst->getToken(tok1, sizeof(tok1), &n1);
    } else if (!strcmp(tok1, "/WMode")) {
      cmap->wMode = atoi(tok2);
      pst->getToken(tok1, sizeof(tok1), &n1);
    } else if (!strcmp(tok2, "begincodespacerange")) {
      while (pst->getToken(tok1, sizeof(tok1), &n1)) {
	if (!strcmp(tok1, "endcodespacerange")) {
	  break;
	}
	if (!pst->getToken(tok2, sizeof(tok2), &n2) ||
	    !strcmp(tok2, "endcodespacerange")) {
	  error(-1, "Illegal entry in codespacerange block in CMap");
	  break;
	}
	if (tok1[0] == '<' && tok2[0] == '<' &&
	    n1 == n2 && n1 >= 4 && (n1 & 1) == 0) {
	  tok1[n1 - 1] = tok2[n1 - 1] = '\0';
	  sscanf(tok1 + 1, "%x", &start);
	  sscanf(tok2 + 1, "%x", &end);
	  n1 = (n1 - 2) / 2;
	  cmap->addCodeSpace(cmap->vector, start, end, n1);
	}
      }
      pst->getToken(tok1, sizeof(tok1), &n1);
    } else if (!strcmp(tok2, "begincidrange")) {
      while (pst->getToken(tok1, sizeof(tok1), &n1)) {
	if (!strcmp(tok1, "endcidrange")) {
	  break;
	}
	if (!pst->getToken(tok2, sizeof(tok2), &n2) ||
	    !strcmp(tok2, "endcidrange") ||
	    !pst->getToken(tok3, sizeof(tok3), &n3) ||
	    !strcmp(tok3, "endcidrange")) {
	  error(-1, "Illegal entry in cidrange block in CMap");
	  break;
	}
	if (tok1[0] == '<' && tok2[0] == '<' &&
	    n1 == n2 && n1 >= 4 && (n1 & 1) == 0) {
	  tok1[n1 - 1] = tok2[n1 - 1] = '\0';
	  sscanf(tok1 + 1, "%x", &start);
	  sscanf(tok2 + 1, "%x", &end);
	  n1 = (n1 - 2) / 2;
	  cmap->addCIDs(start, end, n1, (CID)atoi(tok3));
	}
      }
      pst->getToken(tok1, sizeof(tok1), &n1);
    } else {
      strcpy(tok1, tok2);
    }
  }
  delete pst;

  fclose(f);

  return cmap;
}

CMap::CMap(GString *collectionA, GString *cMapNameA) {
  int i;

  collection = collectionA;
  cMapName = cMapNameA;
  wMode = 0;
  vector = (CMapVectorEntry *)gmalloc(256 * sizeof(CMapVectorEntry));
  for (i = 0; i < 256; ++i) {
    vector[i].isVector = gFalse;
    vector[i].cid = 0;
  }
  refCnt = 1;
}

CMap::CMap(GString *collectionA, GString *cMapNameA, int wModeA) {
  collection = collectionA;
  cMapName = cMapNameA;
  wMode = wModeA;
  vector = NULL;
  refCnt = 1;
}

void CMap::useCMap(CMapCache *cache, char *useName) {
  GString *useNameStr;
  CMap *subCMap;

  useNameStr = new GString(useName);
  subCMap = cache->getCMap(collection, useNameStr);
  delete useNameStr;
  if (!subCMap) {
    return;
  }
  copyVector(vector, subCMap->vector);
  subCMap->decRefCnt();
}

void CMap::copyVector(CMapVectorEntry *dest, CMapVectorEntry *src) {
  int i, j;

  for (i = 0; i < 256; ++i) {
    if (src[i].isVector) {
      if (!dest[i].isVector) {
	dest[i].isVector = gTrue;
	dest[i].vector =
	  (CMapVectorEntry *)gmalloc(256 * sizeof(CMapVectorEntry));
	for (j = 0; j < 256; ++j) {
	  dest[i].vector[j].isVector = gFalse;
	  dest[i].vector[j].cid = 0;
	}
      }
      copyVector(dest[i].vector, src[i].vector);
    } else {
      if (dest[i].isVector) {
	error(-1, "Collision in usecmap");
      } else {
	dest[i].cid = src[i].cid;
      }
    }
  }
}

void CMap::addCodeSpace(CMapVectorEntry *vec, Guint start, Guint end,
			Guint nBytes) {
  Guint start2, end2;
  int startByte, endByte, i, j;

  if (nBytes > 1) {
    startByte = (start >> (8 * (nBytes - 1))) & 0xff;
    endByte = (end >> (8 * (nBytes - 1))) & 0xff;
    start2 = start & ((1 << (8 * (nBytes - 1))) - 1);
    end2 = end & ((1 << (8 * (nBytes - 1))) - 1);
    for (i = startByte; i <= endByte; ++i) {
      if (!vec[i].isVector) {
	vec[i].isVector = gTrue;
	vec[i].vector =
	  (CMapVectorEntry *)gmalloc(256 * sizeof(CMapVectorEntry));
	for (j = 0; j < 256; ++j) {
	  vec[i].vector[j].isVector = gFalse;
	  vec[i].vector[j].cid = 0;
	}
      }
      addCodeSpace(vec[i].vector, start2, end2, nBytes - 1);
    }
  }
}

void CMap::addCIDs(Guint start, Guint end, Guint nBytes, CID firstCID) {
  CMapVectorEntry *vec;
  CID cid;
  int byte;
  Guint i;

  vec = vector;
  for (i = nBytes - 1; i >= 1; --i) {
    byte = (start >> (8 * i)) & 0xff;
    if (!vec[byte].isVector) {
      error(-1, "Invalid CID (%*x - %*x) in CMap",
	    2*nBytes, start, 2*nBytes, end);
      return;
    }
    vec = vec[byte].vector;
  }
  cid = firstCID;
  for (byte = (int)(start & 0xff); byte <= (int)(end & 0xff); ++byte) {
    if (vec[byte].isVector) {
      error(-1, "Invalid CID (%*x - %*x) in CMap",
	    2*nBytes, start, 2*nBytes, end);
    } else {
      vec[byte].cid = cid;
    }
    ++cid;
  }
}

CMap::~CMap() {
  delete collection;
  delete cMapName;
  if (vector) {
    freeCMapVector(vector);
  }
}

void CMap::freeCMapVector(CMapVectorEntry *vec) {
  int i;

  for (i = 0; i < 256; ++i) {
    if (vec[i].isVector) {
      freeCMapVector(vec[i].vector);
    }
  }
  gfree(vec);
}

void CMap::incRefCnt() {
  ++refCnt;
}

void CMap::decRefCnt() {
  if (--refCnt == 0) {
    delete this;
  }
}

GBool CMap::match(GString *collectionA, GString *cMapNameA) {
  return !collection->cmp(collectionA) && !cMapName->cmp(cMapNameA);
}

CID CMap::getCID(char *s, int len, int *nUsed) {
  CMapVectorEntry *vec;
  int n, i;

  if (!(vec = vector)) {
    // identity CMap
    *nUsed = 2;
    if (len < 2) {
      return 0;
    }
    return ((s[0] & 0xff) << 8) + (s[1] & 0xff);
  }
  n = 0;
  while (1) {
    if (n >= len) {
      *nUsed = n;
      return 0;
    }
    i = s[n++] & 0xff;
    if (!vec[i].isVector) {
      *nUsed = n;
      return vec[i].cid;
    }
    vec = vec[i].vector;
  }
}

//------------------------------------------------------------------------

CMapCache::CMapCache() {
  int i;

  for (i = 0; i < cMapCacheSize; ++i) {
    cache[i] = NULL;
  }
}

CMapCache::~CMapCache() {
  int i;

  for (i = 0; i < cMapCacheSize; ++i) {
    if (cache[i]) {
      cache[i]->decRefCnt();
    }
  }
}

CMap *CMapCache::getCMap(GString *collection, GString *cMapName) {
  CMap *cmap;
  int i, j;

  if (cache[0] && cache[0]->match(collection, cMapName)) {
    cache[0]->incRefCnt();
    return cache[0];
  }
  for (i = 1; i < cMapCacheSize; ++i) {
    if (cache[i] && cache[i]->match(collection, cMapName)) {
      cmap = cache[i];
      for (j = i; j >= 1; --j) {
	cache[j] = cache[j - 1];
      }
      cache[0] = cmap;
      cmap->incRefCnt();
      return cmap;
    }
  }
  if ((cmap = CMap::parse(this, collection, cMapName))) {
    if (cache[cMapCacheSize - 1]) {
      cache[cMapCacheSize - 1]->decRefCnt();
    }
    for (j = cMapCacheSize - 1; j >= 1; --j) {
      cache[j] = cache[j - 1];
    }
    cache[0] = cmap;
    cmap->incRefCnt();
    return cmap;
  }
  return NULL;
}
