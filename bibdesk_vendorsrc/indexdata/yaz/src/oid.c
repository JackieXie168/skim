/*
 * Copyright (C) 1995-2007, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: oid.c,v 1.13 2007/01/03 08:42:15 adam Exp $
 */

/**
 * \file oid.c
 * \brief Implements OID database
 *
 * More or less protocol-transparent OID database.
 * We could (and should?) extend this so that the user app can add new
 * entries to the list at initialization.
 */
#if HAVE_CONFIG_H
#include <config.h>
#endif

#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#include <yaz/oid.h>
#include <yaz/yaz-util.h>

static int z3950_prefix[] = { 1, 2, 840, 10003, -1 };
static int sr_prefix[]    = { 1, 0, 10163, -1 };

struct oident_list {
    struct oident oident;
    struct oident_list *next;
};

static struct oident_list *oident_table = NULL;
static int oid_value_dynamic = VAL_DYNAMIC;
static int oid_init_flag = 0;
static NMEM_MUTEX oid_mutex = 0;
static NMEM oid_nmem = 0;

/*
 * OID database
 */
static oident standard_oids[] =
{
    /* General definitions */
    {PROTO_GENERAL, CLASS_TRANSYN, VAL_BER,          {2,1,1,-1},
     "BER" },
    {PROTO_GENERAL, CLASS_TRANSYN, VAL_ISO2709,      {1,0,2709,1,1,-1},
     "ISO2709"},
    {PROTO_GENERAL, CLASS_GENERAL, VAL_ISO_ILL_1,    {1,0,10161,2,1,-1},
     "ISOILL-1"},
    /* Z39.50v3 definitions */
    {PROTO_Z3950,   CLASS_ABSYN,   VAL_APDU,         {2,1,-1},
     "Z-APDU"},    
    {PROTO_Z3950,   CLASS_APPCTX,  VAL_BASIC_CTX,    {1,1,-1},
     "Z-BASIC"},
    {PROTO_Z3950,   CLASS_ATTSET,  VAL_BIB1,         {3,1,-1},
     "Bib-1"},
    {PROTO_Z3950,   CLASS_ATTSET,  VAL_EXP1,         {3,2,-1},
     "Exp-1"},
    {PROTO_Z3950,   CLASS_ATTSET,  VAL_EXT1,         {3,3,-1},
     "Ext-1"},
    {PROTO_Z3950,   CLASS_ATTSET,  VAL_CCL1,         {3,4,-1},
     "CCL-1"},
    {PROTO_Z3950,   CLASS_ATTSET,  VAL_GILS,         {3,5,-1},
     "GILS-attset"},
    {PROTO_Z3950,   CLASS_ATTSET,  VAL_GILS,         {3,5,-1},
     "GILS"},
    {PROTO_Z3950,   CLASS_ATTSET,  VAL_STAS,         {3,6,-1},
     "STAS-attset"},
    {PROTO_Z3950,   CLASS_ATTSET,  VAL_COLLECT1,     {3,7,-1},
     "Collections-attset"},
    {PROTO_Z3950,   CLASS_ATTSET,  VAL_CIMI1,        {3,8,-1},
     "CIMI-attset"},
    {PROTO_Z3950,   CLASS_ATTSET,  VAL_GEO,          {3,9,-1},
     "Geo-attset"},

    {PROTO_Z3950,   CLASS_ATTSET,  VAL_ZBIG,         {3,10,-1},
     "ZBIG"},
    {PROTO_Z3950,   CLASS_ATTSET,  VAL_UTIL,         {3,11,-1},
     "Util"},
    {PROTO_Z3950,   CLASS_ATTSET,  VAL_XD1,          {3,12,-1},
     "XD-1"},
    {PROTO_Z3950,   CLASS_ATTSET,  VAL_ZTHES,        {3,13,-1},
     "Zthes"},
    {PROTO_Z3950,   CLASS_ATTSET,  VAL_FIN1,         {3,14,-1},
     "Fin-1"},
    {PROTO_Z3950,   CLASS_ATTSET,  VAL_DAN1,         {3,15,-1},
     "Dan-1"},
    {PROTO_Z3950,   CLASS_ATTSET,  VAL_HOLDINGS,     {3,16,-1},
     "Holdings"},
    {PROTO_Z3950,   CLASS_ATTSET,  VAL_USMARC,       {3,17,-1},
     "MARC"},
    {PROTO_Z3950,   CLASS_ATTSET,  VAL_BIB2,         {3,18,-1},
     "Bib-2"},
    {PROTO_Z3950,   CLASS_ATTSET,  VAL_ZEEREX,       {3,19,-1},
     "ZeeRex"},
    /* New applications should use Zthes-1 instead of this Satan-spawn */
    {PROTO_Z3950,   CLASS_ATTSET,  VAL_THESAURUS,    {3,1000,81,1,-1},
     "Thesaurus-attset"},
    {PROTO_Z3950,   CLASS_ATTSET,  VAL_IDXPATH,      {3,1000,81,2,-1},
     "IDXPATH"},
    {PROTO_Z3950,   CLASS_ATTSET,  VAL_EXTLITE,      {3,1000,81,3,-1},
     "EXTLITE"},
    {PROTO_Z3950,   CLASS_DIAGSET, VAL_BIB1,         {4,1,-1},
     "Bib-1"},
    {PROTO_Z3950,   CLASS_DIAGSET, VAL_DIAG1,        {4,2,-1},
     "Diag-1"},
    {PROTO_Z3950,   CLASS_DIAGSET, VAL_DIAG_ES,      {4,3,-1},
     "Diag-ES"},
    {PROTO_Z3950,   CLASS_DIAGSET, VAL_DIAG_GENERAL, {4,3,-1},
     "Diag-General"},
    {PROTO_Z3950,   CLASS_RECSYN,  VAL_UNIMARC,      {5,1,-1},
     "Unimarc"},
    {PROTO_Z3950,   CLASS_RECSYN,  VAL_INTERMARC,    {5,2,-1},
     "Intermarc"},
    {PROTO_Z3950,   CLASS_RECSYN,  VAL_CCF,          {5,3,-1},
     "CCF"},
    /* MARC21 is just an alias for the original USmarc */
    {PROTO_Z3950,   CLASS_RECSYN,  VAL_USMARC,       {5,10,-1},
     "MARC21"},
    {PROTO_Z3950,   CLASS_RECSYN,  VAL_USMARC,       {5,10,-1},
     "USmarc"},
    {PROTO_Z3950,   CLASS_RECSYN,  VAL_UKMARC,       {5,11,-1},
     "UKmarc"},
    {PROTO_Z3950,   CLASS_RECSYN,  VAL_NORMARC,      {5,12,-1},
     "Normarc"},
    {PROTO_Z3950,   CLASS_RECSYN,  VAL_LIBRISMARC,   {5,13,-1},
     "Librismarc"},
    {PROTO_Z3950,   CLASS_RECSYN,  VAL_DANMARC,      {5,14,-1},
     "Danmarc"},
    {PROTO_Z3950,   CLASS_RECSYN,  VAL_FINMARC,      {5,15,-1},
     "Finmarc"},
    {PROTO_Z3950,   CLASS_RECSYN,  VAL_MAB,          {5,16,-1},
     "MAB"},
    {PROTO_Z3950,   CLASS_RECSYN,  VAL_CANMARC,      {5,17,-1},
     "Canmarc"},
    {PROTO_Z3950,   CLASS_RECSYN,  VAL_SBN,          {5,18,-1},
     "SBN"},
    {PROTO_Z3950,   CLASS_RECSYN,  VAL_PICAMARC,     {5,19,-1},
     "Picamarc"},
    {PROTO_Z3950,   CLASS_RECSYN,  VAL_AUSMARC,      {5,20,-1},
     "Ausmarc"},
    {PROTO_Z3950,   CLASS_RECSYN,  VAL_IBERMARC,     {5,21,-1},
     "Ibermarc"},
    {PROTO_Z3950,   CLASS_RECSYN,  VAL_CATMARC,      {5,22,-1},
     "Carmarc"},
    {PROTO_Z3950,   CLASS_RECSYN,  VAL_MALMARC,      {5,23,-1},
     "Malmarc"},
    {PROTO_Z3950,   CLASS_RECSYN,  VAL_JPMARC,       {5,24,-1},
     "JPmarc"},
    {PROTO_Z3950,   CLASS_RECSYN,  VAL_SWEMARC,      {5,25,-1},
     "SWEmarc"},
    {PROTO_Z3950,   CLASS_RECSYN,  VAL_SIGLEMARC,    {5,26,-1},
     "SIGLEmarc"},
    {PROTO_Z3950,   CLASS_RECSYN,  VAL_ISDSMARC,     {5,27,-1},
     "ISDSmarc"},
    {PROTO_Z3950,   CLASS_RECSYN,  VAL_RUSMARC,      {5,28,-1},
     "RUSmarc"},
    {PROTO_Z3950,   CLASS_RECSYN,  VAL_HUNMARC,      {5,29,-1},
     "Hunmarc"},
    {PROTO_Z3950,   CLASS_RECSYN,  VAL_NACSISCATP,   {5,30,-1},
     "NACSIS-CATP"},
    {PROTO_Z3950,   CLASS_RECSYN,  VAL_FINMARC2000,  {5,31,-1},
     "FINMARC2000"},
    {PROTO_Z3950,   CLASS_RECSYN,  VAL_MARC21FIN,    {5,32,-1},
     "MARC21-fin"},
    {PROTO_Z3950,   CLASS_RECSYN,  VAL_EXPLAIN,      {5,100,-1},
     "Explain"},
    {PROTO_Z3950,   CLASS_RECSYN,  VAL_SUTRS,        {5,101,-1},
     "SUTRS"},
    {PROTO_Z3950,   CLASS_RECSYN,  VAL_OPAC,         {5,102,-1},
     "OPAC"},
    {PROTO_Z3950,   CLASS_RECSYN,  VAL_SUMMARY,      {5,103,-1},
     "Summary"},
    {PROTO_Z3950,   CLASS_RECSYN,  VAL_GRS0,         {5,104,-1},
     "GRS-0"},
    {PROTO_Z3950,   CLASS_RECSYN,  VAL_GRS1,         {5,105,-1},
     "GRS-1"},
    {PROTO_Z3950,   CLASS_RECSYN,  VAL_EXTENDED,     {5,106,-1},
     "Extended"},
    {PROTO_Z3950,   CLASS_RECSYN,  VAL_FRAGMENT,     {5,107,-1},
     "Fragment"},
    {PROTO_Z3950,   CLASS_RECSYN,  VAL_PDF,          {5,109,1,-1},
     "pdf"},
    {PROTO_Z3950,   CLASS_RECSYN,  VAL_POSTSCRIPT,   {5,109,2,-1},
     "postscript"},
    {PROTO_Z3950,   CLASS_RECSYN,  VAL_HTML,         {5,109,3,-1},
     "html"},
    {PROTO_Z3950,   CLASS_RECSYN,  VAL_TIFF,         {5,109,4,-1},
     "tiff"},
    {PROTO_Z3950,   CLASS_RECSYN,  VAL_GIF,          {5,109,5,-1},
     "gif"},
    {PROTO_Z3950,   CLASS_RECSYN,  VAL_JPEG,         {5,109,6,-1},
     "jpeg"},
    {PROTO_Z3950,   CLASS_RECSYN,  VAL_PNG,          {5,109,7,-1},
     "png"},
    {PROTO_Z3950,   CLASS_RECSYN,  VAL_MPEG,         {5,109,8,-1},
     "mpeg"},
    {PROTO_Z3950,   CLASS_RECSYN,  VAL_SGML,         {5,109,9,-1},
     "sgml"},

    {PROTO_Z3950,   CLASS_RECSYN,  VAL_TIFFB,        {5,110,1,-1},
     "tiff-b"},
    {PROTO_Z3950,   CLASS_RECSYN,  VAL_WAV,          {5,110,2,-1},
     "wav"},

    {PROTO_Z3950,   CLASS_RECSYN,  VAL_SQLRS,        {5,111,-1},
     "SQL-RS"},
    {PROTO_Z3950,   CLASS_RECSYN,  VAL_SOIF,         {5,1000,81,2,-1},
     "SOIF" },
    {PROTO_Z3950,   CLASS_RECSYN,  VAL_TEXT_XML,     {5,109,10,-1},
     "text-XML" },
    {PROTO_Z3950,   CLASS_RECSYN,  VAL_TEXT_XML,     {5,109,10,-1},
     "XML" },
    {PROTO_Z3950,   CLASS_RECSYN,  VAL_APPLICATION_XML, {5,109,11,-1},
     "application-XML" },
    {PROTO_Z3950,   CLASS_RESFORM, VAL_RESOURCE1,    {7,1,-1},
     "Resource-1"},
    {PROTO_Z3950,   CLASS_RESFORM, VAL_RESOURCE2,    {7,2,-1},
     "Resource-2"},
    {PROTO_Z3950,   CLASS_RESFORM, VAL_UNIVERSE_REPORT, {7,1000,81,1,-1},
     "UNIverse-Resource-Report"},

    {PROTO_Z3950,   CLASS_ACCFORM, VAL_PROMPT1,      {8,1,-1},
     "Prompt-1"},
    {PROTO_Z3950,   CLASS_ACCFORM, VAL_DES1,         {8,2,-1},
     "Des-1"},
    {PROTO_Z3950,   CLASS_ACCFORM, VAL_KRB1,         {8,3,-1},
     "Krb-1"},
    {PROTO_Z3950,   CLASS_EXTSERV, VAL_PRESSET,      {9,1,-1},
     "Pers. set"},
    {PROTO_Z3950,   CLASS_EXTSERV, VAL_PQUERY,       {9,2,-1},
     "Pers. query"},
    {PROTO_Z3950,   CLASS_EXTSERV, VAL_PCQUERY,      {9,3,-1},
     "Per'd query"},
    {PROTO_Z3950,   CLASS_EXTSERV, VAL_ITEMORDER,    {9,4,-1},
     "Item order"},
    {PROTO_Z3950,   CLASS_EXTSERV, VAL_DBUPDATE0,    {9,5,-1},
     "DB. Update (first version)"},
    {PROTO_Z3950,   CLASS_EXTSERV, VAL_DBUPDATE1,    {9,5,1,-1},
     "DB. Update (second version)"},
    {PROTO_Z3950,   CLASS_EXTSERV, VAL_DBUPDATE,     {9,5,1,1,-1},
     "DB. Update"},
    {PROTO_Z3950,   CLASS_EXTSERV, VAL_EXPORTSPEC,   {9,6,-1},
     "exp. spec."},
    {PROTO_Z3950,   CLASS_EXTSERV, VAL_EXPORTINV,    {9,7,-1},
     "exp. inv."},
    {PROTO_Z3950,   CLASS_EXTSERV, VAL_ADMINSERVICE, {9,1000,81,1,-1},
     "Admin"},
    {PROTO_Z3950,   CLASS_USERINFO,VAL_SEARCHRES1,   {10,1,-1},
     "searchResult-1"},
    {PROTO_Z3950,   CLASS_USERINFO,VAL_CHARLANG,     {10,2,-1},
     "CharSetandLanguageNegotiation"},
    {PROTO_Z3950,   CLASS_USERINFO,VAL_USERINFO1,    {10,3,-1},
     "UserInfo-1"},
    {PROTO_Z3950,   CLASS_USERINFO,VAL_MULTISRCH1,   {10,4,-1},
     "MultipleSearchTerms-1"},
    {PROTO_Z3950,   CLASS_USERINFO,VAL_MULTISRCH2,   {10,5,-1},
     "MultipleSearchTerms-2"},
    {PROTO_Z3950,   CLASS_USERINFO,VAL_DATETIME,     {10,6,-1},
     "DateTime"},
    {PROTO_Z3950,   CLASS_USERINFO,VAL_PROXY,        {10,1000,81,1,-1},
     "Proxy" },
    {PROTO_Z3950,   CLASS_USERINFO,VAL_COOKIE,       {10,1000,81,2,-1},
     "Cookie" },
    {PROTO_Z3950,   CLASS_USERINFO,VAL_CLIENT_IP,    {10,1000,81,3,-1},
     "Client-IP" },
    {PROTO_Z3950,   CLASS_ELEMSPEC,VAL_ESPEC1,       {11,1,-1},
     "Espec-1"},
    {PROTO_Z3950,   CLASS_VARSET,  VAL_VAR1,         {12,1,-1},
     "Variant-1"},
    {PROTO_Z3950,   CLASS_SCHEMA,  VAL_WAIS,         {13,1,-1},
     "WAIS-schema"},
    {PROTO_Z3950,   CLASS_SCHEMA,  VAL_GILS,         {13,2,-1},
     "GILS-schema"},
    {PROTO_Z3950,   CLASS_SCHEMA,  VAL_COLLECT1,     {13,3,-1},
     "Collections-schema"},
    {PROTO_Z3950,   CLASS_SCHEMA,  VAL_GEO,          {13,4,-1},
     "Geo-schema"},
    {PROTO_Z3950,   CLASS_SCHEMA,  VAL_CIMI1,        {13,5,-1},
     "CIMI-schema"},
    {PROTO_Z3950,   CLASS_SCHEMA,  VAL_UPDATEES,     {13,6,-1},
     "Update ES"},
    {PROTO_Z3950,   CLASS_SCHEMA,  VAL_HOLDINGS,     {13,7,-1},
     "Holdings"},
    {PROTO_Z3950,   CLASS_SCHEMA,  VAL_ZTHES,        {13,8,-1},
     "Zthes"},
    {PROTO_Z3950,   CLASS_SCHEMA,  VAL_THESAURUS,    {13,1000,81,1,-1},
     "thesaurus-schema"},
    {PROTO_Z3950,   CLASS_SCHEMA,  VAL_EXPLAIN,      {13,1000,81,2,-1},
     "Explain-schema"},
    {PROTO_Z3950,   CLASS_TAGSET,  VAL_SETM,         {14,1,-1},
     "TagsetM"},
    {PROTO_Z3950,   CLASS_TAGSET,  VAL_SETG,         {14,2,-1},
     "TagsetG"},
    {PROTO_Z3950,   CLASS_TAGSET,  VAL_STAS,         {14,3,-1},
     "STAS-tagset"},
    {PROTO_Z3950,   CLASS_TAGSET,  VAL_GILS,         {14,4,-1},
     "GILS-tagset"},
    {PROTO_Z3950,   CLASS_TAGSET,  VAL_COLLECT1,     {14,5,-1},
     "Collections-tagset"},
    {PROTO_Z3950,   CLASS_TAGSET,  VAL_CIMI1,        {14,6,-1},
     "CIMI-tagset"},
    {PROTO_Z3950,   CLASS_TAGSET,  VAL_THESAURUS,    {14,1000,81,1,-1},
     "thesaurus-tagset"},       /* What is this Satan-spawn doing here? */
    {PROTO_Z3950,   CLASS_TAGSET,  VAL_EXPLAIN,      {14,1000,81,2,-1},
     "Explain-tagset"},
    {PROTO_Z3950,   CLASS_TAGSET,  VAL_ZTHES,        {14,8,-1},
     "Zthes-tagset"},
    {PROTO_Z3950,   CLASS_NEGOT,   VAL_CHARNEG3,     {15,3,-1},
     "CharSetandLanguageNegotiation-3"},
    {PROTO_Z3950,   CLASS_NEGOT,   VAL_CHARNEG4,     {15,4,-1},
     "CharSetandLanguageNegotiation-4"},
    {PROTO_Z3950,   CLASS_NEGOT,   VAL_ID_CHARSET,   {15,1000,81,1,-1},
     "ID-Charset" },
    {PROTO_Z3950,   CLASS_USERINFO,VAL_CQL,          {16, 2, -1},
     "CQL"},
    {PROTO_GENERAL, CLASS_GENERAL, VAL_UCS2,         {1,0,10646,1,0,2,-1},
     "UCS-2"},
    {PROTO_GENERAL, CLASS_GENERAL, VAL_UCS4,         {1,0,10646,1,0,4,-1},
     "UCS-4"},
    {PROTO_GENERAL, CLASS_GENERAL, VAL_UTF16,        {1,0,10646,1,0,5,-1},
     "UTF-16"},
    {PROTO_GENERAL, CLASS_GENERAL, VAL_UTF8,         {1,0,10646,1,0,8,-1},
     "UTF-8"},
    {PROTO_Z3950,   CLASS_USERINFO,VAL_OCLCUI,       {10, 1000, 17, 1, -1},
     "OCLC-userInfo"},
    {PROTO_Z3950,   CLASS_EXTSERV, VAL_XMLES,        {9,1000,105,4,-1},
     "XML-ES"},
    {PROTO_NOP,     CLASS_NOP,     VAL_NOP,          {-1},      0     }
};

/* OID utilities */

void oid_oidcpy(int *t, int *s)
{
    while ((*(t++) = *(s++)) > -1);
}

void oid_oidcat(int *t, int *s)
{
    while (*t > -1)
        t++;
    while ((*(t++) = *(s++)) > -1);
}

int oid_oidcmp(int *o1, int *o2)
{
    while (*o1 == *o2 && *o1 > -1)
    {
        o1++;
        o2++;
    }
    if (*o1 == *o2)
        return 0;
    else if (*o1 > *o2)
        return 1;
    else
        return -1;
}

int oid_oidlen(int *o)
{
    int len = 0;

    while (*(o++) >= 0)
        len++;
    return len;
}


static int match_prefix(int *look, int *prefix)
{
    int len;

    for (len = 0; *look == *prefix; look++, prefix++, len++);
    if (*prefix < 0) /* did we reach the end of the prefix? */
        return len;
    return 0;
}

void oid_transfer (struct oident *oidentp)
{
    while (*oidentp->oidsuffix >= 0)
    {
        oid_addent (oidentp->oidsuffix, oidentp->proto,
                    oidentp->oclass,
                    oidentp->desc, oidentp->value);
        oidentp++;
    }
}

void oid_init (void)
{
    if (oid_init_flag == 0)
    {
        /* oid_transfer is thread safe, so there's nothing wrong in having
           two threads calling it simultaniously. On the other hand
           no thread may exit oid_init before all OID's bave been
           transferred - which is why checked is set after oid_transfer... 
        */
        nmem_mutex_create (&oid_mutex);
        nmem_mutex_enter (oid_mutex);
        if (!oid_nmem)
            oid_nmem = nmem_create ();
        nmem_mutex_leave (oid_mutex);
        oid_transfer (standard_oids);
        oid_init_flag = 1;
    }
}

void oid_exit (void)
{
    if (oid_init_flag)
    {
        oid_init_flag = 0;
        nmem_mutex_destroy (&oid_mutex);
        nmem_destroy (oid_nmem);
        oid_nmem = 0;
    }
}

static struct oident *oid_getentbyoid_x(int *o)
{
    enum oid_proto proto;
    int prelen;
    struct oident_list *ol;
    
    /* determine protocol type */
    if ((prelen = match_prefix(o, z3950_prefix)) != 0)
        proto = PROTO_Z3950;
    else if ((prelen = match_prefix(o, sr_prefix)) != 0)
        proto = PROTO_SR;
    else
        proto = PROTO_GENERAL;
    for (ol = oident_table; ol; ol = ol->next)
    {
        struct oident *p = &ol->oident;
        if (p->proto == proto && !oid_oidcmp(o + prelen, p->oidsuffix))
            return p;
        if (p->proto == PROTO_GENERAL && !oid_oidcmp (o, p->oidsuffix))
            return p;
    }
    return 0;
}

/*
 * To query, fill out proto, class, and value of the ent parameter.
 */
int *oid_ent_to_oid(struct oident *ent, int *ret)
{
    struct oident_list *ol;
    
    oid_init ();
    for (ol = oident_table; ol; ol = ol->next)
    {
        struct oident *p = &ol->oident;
        if (ent->value == p->value &&
            (p->proto == PROTO_GENERAL || (ent->proto == p->proto &&  
            (ent->oclass == p->oclass || ent->oclass == CLASS_GENERAL))))
        {
            if (p->proto == PROTO_Z3950)
                oid_oidcpy(ret, z3950_prefix);
            else if (p->proto == PROTO_SR)
                oid_oidcpy(ret, sr_prefix);
            else
                ret[0] = -1;
            oid_oidcat(ret, p->oidsuffix);
            ent->desc = p->desc;
            return ret;
        }
    }
    ret[0] = -1;
    return 0;
}

/*
 * To query, fill out proto, class, and value of the ent parameter.
 */
int *oid_getoidbyent(struct oident *ent)
{
    static int ret[OID_SIZE];

    return oid_ent_to_oid (ent, ret);
}

struct oident *oid_addent (int *oid, enum oid_proto proto,
                           enum oid_class oclass,
                           const char *desc, int value)
{
    struct oident *oident = 0;

    nmem_mutex_enter (oid_mutex);
    if (!oident)
    {
        struct oident_list *oident_list;
        oident_list = (struct oident_list *)
            nmem_malloc (oid_nmem, sizeof(*oident_list));
        oident = &oident_list->oident;
        oident->proto = proto;
        oident->oclass = oclass;

        if (!desc)
        {
            char desc_str[OID_STR_MAX];
            int i;

            *desc_str = '\0';
            if (*oid >= 0)
            {
                sprintf (desc_str, "%d", *oid);
                for (i = 1; i < OID_SIZE && oid[i] >= 0; i++)
                    sprintf (desc_str+strlen(desc_str), ".%d", oid[i]);
            }
            oident->desc = nmem_strdup(oid_nmem, desc_str);
        }
        else
            oident->desc = nmem_strdup(oid_nmem, desc);
        if (value == VAL_DYNAMIC)
            oident->value = (enum oid_value) (++oid_value_dynamic);
        else
            oident->value = (enum oid_value) value;
        oid_oidcpy (oident->oidsuffix, oid);
        oident_list->next = oident_table;
        oident_table = oident_list;
    }
    nmem_mutex_leave (oid_mutex);
    return oident;
}

struct oident *oid_getentbyoid(int *oid)
{
    struct oident *oident;

    if (!oid)
        return 0;
    oid_init ();
    oident = oid_getentbyoid_x (oid);
    if (!oident)
        oident = oid_addent (oid, PROTO_GENERAL, CLASS_GENERAL,
                             NULL, VAL_DYNAMIC);
    return oident;
}

static oid_value oid_getval_raw(const char *name)
{
    int val = 0, i = 0, oid[OID_SIZE];
    struct oident *oident;
    
    while (isdigit (*(const unsigned char *) name))
    {
        val = val*10 + (*name - '0');
        name++;
        if (*name == '.')
        {
            if (i < OID_SIZE-1)
                oid[i++] = val;
            val = 0;
            name++;
        }
    }
    oid[i] = val;
    oid[i+1] = -1;
    oident = oid_getentbyoid_x (oid);
    if (!oident)
        oident = oid_addent (oid, PROTO_GENERAL, CLASS_GENERAL, NULL,
                         VAL_DYNAMIC);
    return oident->value;
}

oid_value oid_getvalbyname(const char *name)
{
    struct oident_list *ol;

    oid_init ();
    if (isdigit (*(const unsigned char *) name))
        return oid_getval_raw (name);
    for (ol = oident_table; ol; ol = ol->next)
        if (!yaz_matchstr(ol->oident.desc, name))
        {
            return ol->oident.value;
        }
    return VAL_NONE;
}

void oid_setprivateoids(oident *list)
{
    oid_transfer (list);
}

void oid_trav (void (*func)(struct oident *oidinfo, void *vp), void *vp)
{
    struct oident_list *ol;

    oid_init ();
    for (ol = oident_table; ol; ol = ol->next)
        (*func)(&ol->oident, vp);
}

int *oid_name_to_oid(oid_class oclass, const char *name, int *oid)
{
    struct oident ent;

    /* Translate syntax to oid_val */
    oid_value value = oid_getvalbyname(name);

    /* Build it into an oident */
    ent.proto = PROTO_Z3950;
    ent.oclass = oclass;
    ent.value = value;

    /* Translate to an array of int */
    return oid_ent_to_oid(&ent, oid);
}

char *oid_to_dotstring(const int *oid, char *oidbuf)
{
    char tmpbuf[20];
    int i;

    oidbuf[0] = '\0';
    for (i = 0; oid[i] != -1 && i < OID_SIZE; i++) 
    {
        sprintf(tmpbuf, "%d", oid[i]);
        if (i > 0)
            strcat(oidbuf, ".");
        strcat(oidbuf, tmpbuf);
    }
    return oidbuf;
}

char *oid_name_to_dotstring(oid_class oclass, const char *name, char *oidbuf)
{
    int oid[OID_SIZE];

    (void) oid_name_to_oid(oclass, name, oid);
    return oid_to_dotstring(oid, oidbuf);
}

/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

