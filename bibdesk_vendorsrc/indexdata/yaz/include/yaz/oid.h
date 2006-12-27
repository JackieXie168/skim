/*
 * Copyright (c) 1995-2006, Index Data
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of Index Data nor the names of its contributors
 *       may be used to endorse or promote products derived from this
 *       software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE REGENTS AND CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
/* $Id: oid.h,v 1.29 2006/10/09 21:02:41 adam Exp $ */

/**
 * \file oid.h
 * \brief Header for OID database
 *
 * More or less protocol-transparent OID database.
 * We could (and should?) extend this so that the user app can add new
 * entries to the list at initialization.
 */
#ifndef OID_H
#define OID_H

#include "yconfig.h"

YAZ_BEGIN_CDECL

#define OID_SIZE 20
#define OID_STR_MAX 256
    
typedef enum oid_proto
{
    PROTO_NOP=0,
    PROTO_Z3950,
    PROTO_SR,
    PROTO_GENERAL,
    PROTO_WAIS,
    PROTO_HTTP
} oid_proto;

typedef enum oid_class
{
    CLASS_NOP=0,
    CLASS_APPCTX,
    CLASS_ABSYN,
    CLASS_ATTSET,
    CLASS_TRANSYN,
    CLASS_DIAGSET,
    CLASS_RECSYN,
    CLASS_RESFORM,
    CLASS_ACCFORM,
    CLASS_EXTSERV,
    CLASS_USERINFO,
    CLASS_ELEMSPEC,
    CLASS_VARSET,
    CLASS_SCHEMA,
    CLASS_TAGSET,
    CLASS_GENERAL,
    CLASS_NEGOT
} oid_class;

typedef enum oid_value
{
    VAL_NOP=0,
    VAL_APDU,
    VAL_BER,
    VAL_BASIC_CTX,
    VAL_BIB1,

    VAL_EXP1,
    VAL_EXT1,
    VAL_CCL1,
    VAL_GILS,
    VAL_WAIS, 
/* 10 */
    VAL_STAS,
    VAL_COLLECT1,
    VAL_CIMI1,
    VAL_GEO,
    VAL_DIAG1,

    VAL_ISO2709,
    VAL_UNIMARC,
    VAL_INTERMARC,
    VAL_CCF,
    VAL_USMARC,
/* 20 */
    VAL_UKMARC,
    VAL_NORMARC,
    VAL_LIBRISMARC,
    VAL_DANMARC,
    VAL_FINMARC,

    VAL_MAB,
    VAL_CANMARC,
    VAL_SBN,
    VAL_PICAMARC,
    VAL_AUSMARC,
/* 30 */
    VAL_IBERMARC,
    VAL_CATMARC,
    VAL_MALMARC,
    VAL_EXPLAIN,
    VAL_SUTRS,

    VAL_OPAC,
    VAL_SUMMARY,
    VAL_GRS0,
    VAL_GRS1,
    VAL_EXTENDED,
/* 40 */
    VAL_FRAGMENT,
    VAL_RESOURCE1,
    VAL_RESOURCE2,
    VAL_PROMPT1,
    VAL_DES1,

    VAL_KRB1,
    VAL_PRESSET,
    VAL_PQUERY,
    VAL_PCQUERY,
    VAL_ITEMORDER,

/* 50 */
    VAL_DBUPDATE0,
    VAL_DBUPDATE,
    VAL_EXPORTSPEC,
    VAL_EXPORTINV,
    VAL_NONE,

    VAL_SETM,
    VAL_SETG,
    VAL_VAR1,
    VAL_ESPEC1,
    VAL_SOIF,

/* 60 */
    VAL_SEARCHRES1,
    VAL_THESAURUS,
    VAL_CHARLANG,
    VAL_USERINFO1,
    VAL_MULTISRCH1,

    VAL_MULTISRCH2,
    VAL_DATETIME,
    VAL_SQLRS,
    VAL_PDF,
    VAL_POSTSCRIPT,

/* 70 */
    VAL_HTML,
    VAL_TIFF,
    VAL_GIF,
    VAL_JPEG,
    VAL_PNG,

    VAL_MPEG,
    VAL_SGML,
    VAL_TIFFB,
    VAL_WAV,
    VAL_UPDATEES,

/* 80 */
    VAL_TEXT_XML,
    VAL_APPLICATION_XML,
    VAL_UNIVERSE_REPORT,
    VAL_PROXY,
    VAL_COOKIE,

    VAL_CLIENT_IP,
    VAL_ISO_ILL_1,
    VAL_ZBIG,
    VAL_UTIL,
    VAL_XD1,

/* 90 */
    VAL_ZTHES,
    VAL_FIN1,
    VAL_DAN1,
    VAL_DIAG_ES,
    VAL_DIAG_GENERAL,

    VAL_JPMARC,
    VAL_SWEMARC,
    VAL_SIGLEMARC,
    VAL_ISDSMARC,
    VAL_RUSMARC,

/* 100 */
    VAL_ADMINSERVICE,
    VAL_HOLDINGS,
    VAL_HUNMARC,
    VAL_CHARNEG3,
    VAL_LIB1,

    VAL_VIRT,
    VAL_UCS2,
    VAL_UCS4,
    VAL_UTF16,
    VAL_UTF8,
/* 110 */

    VAL_IDXPATH,
    VAL_BIB2,
    VAL_ZEEREX,
    VAL_CQL,
    VAL_DBUPDATE1,

    VAL_OCLCUI,
    VAL_ID_CHARSET,
    VAL_EXTLITE,
    VAL_NACSISCATP,
    VAL_FINMARC2000,
/* 120 */

    VAL_MARC21FIN,
    VAL_CHARNEG4,
    VAL_XMLES,

/* VAL_DYNAMIC must have highest value */
    VAL_DYNAMIC,
    VAL_MAX = VAL_DYNAMIC+30
} oid_value;

typedef struct oident
{
    oid_proto proto;
    oid_class oclass;
    oid_value value;
    int oidsuffix[OID_SIZE];
    char *desc;
} oident;

YAZ_EXPORT int *oid_getoidbyent(struct oident *ent);
YAZ_EXPORT int *oid_ent_to_oid(struct oident *ent, int *dst);
YAZ_EXPORT struct oident *oid_getentbyoid(int *o);
YAZ_EXPORT void oid_oidcpy(int *t, int *s);
YAZ_EXPORT void oid_oidcat(int *t, int *s);
YAZ_EXPORT int oid_oidcmp(int *o1, int *o2);
YAZ_EXPORT int oid_oidlen(int *o);
YAZ_EXPORT oid_value oid_getvalbyname(const char *name);
YAZ_EXPORT void oid_setprivateoids(oident *list);
YAZ_EXPORT struct oident *oid_addent (int *oid, enum oid_proto proto,
                                      enum oid_class oclass,
                                      const char *desc, int value);

YAZ_EXPORT void oid_trav (void (*func)(struct oident *oidinfo, void *vp),
                          void *vp);

YAZ_EXPORT void oid_init(void);
YAZ_EXPORT void oid_exit(void);
YAZ_EXPORT int *oid_name_to_oid(oid_class oclass, const char *name, int *oid);
YAZ_EXPORT char *oid_to_dotstring(const int *oid, char *oidbuf);
YAZ_EXPORT char *oid_name_to_dotstring(oid_class oclass, const char *name,
                                       char *oidbuf);

YAZ_END_CDECL

#endif
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

