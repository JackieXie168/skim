/*
 * Copyright (C) 1995-2007, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: prt-ext.c,v 1.7 2007/01/03 08:42:15 adam Exp $
 */

/**
 * \file prt-ext.c
 * \brief Implements handling of various Z39.50 Externals
 */

#include <yaz/proto.h>

#define PRT_EXT_DEBUG 0

#if PRT_EXT_DEBUG
#include <yaz/log.h>
#endif

/*
 * The table below should be moved to the ODR structure itself and
 * be an image of the association context: To help
 * map indirect references when they show up. 
 */
static Z_ext_typeent type_table[] =
{
    {VAL_SUTRS, Z_External_sutrs, (Odr_fun) z_SUTRS},
    {VAL_EXPLAIN, Z_External_explainRecord, (Odr_fun)z_ExplainRecord},
    {VAL_RESOURCE1, Z_External_resourceReport1, (Odr_fun)z_ResourceReport1},
    {VAL_RESOURCE2, Z_External_resourceReport2, (Odr_fun)z_ResourceReport2},
    {VAL_PROMPT1, Z_External_promptObject1, (Odr_fun)z_PromptObject1 },
    {VAL_GRS1, Z_External_grs1, (Odr_fun)z_GenericRecord},
    {VAL_EXTENDED, Z_External_extendedService, (Odr_fun)z_TaskPackage},
    {VAL_ITEMORDER, Z_External_itemOrder, (Odr_fun)z_IOItemOrder},
    {VAL_DIAG1, Z_External_diag1, (Odr_fun)z_DiagnosticFormat},
    {VAL_ESPEC1, Z_External_espec1, (Odr_fun)z_Espec1},
    {VAL_SUMMARY, Z_External_summary, (Odr_fun)z_BriefBib},
    {VAL_OPAC, Z_External_OPAC, (Odr_fun)z_OPACRecord},
    {VAL_SEARCHRES1, Z_External_searchResult1, (Odr_fun)z_SearchInfoReport},
    {VAL_DBUPDATE, Z_External_update, (Odr_fun)z_IUUpdate},
    {VAL_DBUPDATE0, Z_External_update0, (Odr_fun)z_IU0Update},
    {VAL_DBUPDATE1, Z_External_update0, (Odr_fun)z_IU0Update},
    {VAL_DATETIME, Z_External_dateTime, (Odr_fun)z_DateTime},
    {VAL_UNIVERSE_REPORT, Z_External_universeReport,(Odr_fun)z_UniverseReport},
    {VAL_ADMINSERVICE, Z_External_ESAdmin, (Odr_fun)z_Admin},
    {VAL_USERINFO1, Z_External_userInfo1, (Odr_fun) z_OtherInformation},
    {VAL_CHARNEG3, Z_External_charSetandLanguageNegotiation, (Odr_fun)
                  z_CharSetandLanguageNegotiation},
    {VAL_PROMPT1, Z_External_acfPrompt1, (Odr_fun) z_PromptObject1},
    {VAL_DES1, Z_External_acfDes1, (Odr_fun) z_DES_RN_Object},
    {VAL_KRB1, Z_External_acfKrb1, (Odr_fun) z_KRBObject},
    {VAL_MULTISRCH2, Z_External_multisrch2, (Odr_fun) z_MultipleSearchTerms_2},
    {VAL_CQL, Z_External_CQL, (Odr_fun) z_InternationalString},
    {VAL_NONE, 0, 0}
};

Z_ext_typeent *z_ext_getentbyref(oid_value val)
{
    Z_ext_typeent *i;

    for (i = type_table; i->dref != VAL_NONE; i++)
        if (i->dref == val)
            return i;
    return 0;
}

/**
  This routine is the BER codec for the EXTERNAL type.
  It handles information in single-ASN1-type and octet-aligned
  for known structures.

  <pre>
    [UNIVERSAL 8] IMPLICIT SEQUENCE {
    direct-reference      OBJECT IDENTIFIER OPTIONAL,
    indirect-reference    INTEGER OPTIONAL,
    data-value-descriptor ObjectDescriptor OPTIONAL,
    encoding              CHOICE {
      single-ASN1-type   [0] ABSTRACT_SYNTAX.&Type,
      octet-aligned      [1] IMPLICIT OCTET STRING,
      arbitrary          [2] IMPLICIT BIT STRING 
      }
    }
  </pre>
  arbitrary BIT STRING not handled yet.
*/
int z_External(ODR o, Z_External **p, int opt, const char *name)
{
    oident *oid;
    Z_ext_typeent *type;

    static Odr_arm arm[] =
    {
        {ODR_EXPLICIT, ODR_CONTEXT, 0, Z_External_single,
         (Odr_fun)odr_any, 0},
        {ODR_IMPLICIT, ODR_CONTEXT, 1, Z_External_octet,
         (Odr_fun)odr_octetstring, 0},
        {ODR_IMPLICIT, ODR_CONTEXT, 2, Z_External_arbitrary,
         (Odr_fun)odr_bitstring, 0},
        {ODR_EXPLICIT, ODR_CONTEXT, 0, Z_External_sutrs,
         (Odr_fun)z_SUTRS, 0},
        {ODR_EXPLICIT, ODR_CONTEXT, 0, Z_External_explainRecord,
         (Odr_fun)z_ExplainRecord, 0},

        {ODR_EXPLICIT, ODR_CONTEXT, 0, Z_External_resourceReport1,
         (Odr_fun)z_ResourceReport1, 0},
        {ODR_EXPLICIT, ODR_CONTEXT, 0, Z_External_resourceReport2,
         (Odr_fun)z_ResourceReport2, 0},
        {ODR_EXPLICIT, ODR_CONTEXT, 0, Z_External_promptObject1,
         (Odr_fun)z_PromptObject1, 0},
        {ODR_EXPLICIT, ODR_CONTEXT, 0, Z_External_grs1,
         (Odr_fun)z_GenericRecord, 0},
        {ODR_EXPLICIT, ODR_CONTEXT, 0, Z_External_extendedService,
         (Odr_fun)z_TaskPackage, 0},

        {ODR_EXPLICIT, ODR_CONTEXT, 0, Z_External_itemOrder,
         (Odr_fun)z_IOItemOrder, 0},
        {ODR_EXPLICIT, ODR_CONTEXT, 0, Z_External_diag1,
         (Odr_fun)z_DiagnosticFormat, 0},
        {ODR_EXPLICIT, ODR_CONTEXT, 0, Z_External_espec1,
         (Odr_fun)z_Espec1, 0},
        {ODR_EXPLICIT, ODR_CONTEXT, 0, Z_External_summary,
         (Odr_fun)z_BriefBib, 0},
        {ODR_EXPLICIT, ODR_CONTEXT, 0, Z_External_OPAC,
         (Odr_fun)z_OPACRecord, 0},

        {ODR_EXPLICIT, ODR_CONTEXT, 0, Z_External_searchResult1,
         (Odr_fun)z_SearchInfoReport, 0},
        {ODR_EXPLICIT, ODR_CONTEXT, 0, Z_External_update,
         (Odr_fun)z_IUUpdate, 0},
        {ODR_EXPLICIT, ODR_CONTEXT, 0, Z_External_dateTime,
         (Odr_fun)z_DateTime, 0},
        {ODR_EXPLICIT, ODR_CONTEXT, 0, Z_External_universeReport,
         (Odr_fun)z_UniverseReport, 0},
        {ODR_EXPLICIT, ODR_CONTEXT, 0, Z_External_ESAdmin,
         (Odr_fun)z_Admin, 0},

        {ODR_EXPLICIT, ODR_CONTEXT, 0, Z_External_update0,
         (Odr_fun)z_IU0Update, 0},
        {ODR_EXPLICIT, ODR_CONTEXT, 0, Z_External_userInfo1,
         (Odr_fun)z_OtherInformation, 0},
        {ODR_EXPLICIT, ODR_CONTEXT, 0, Z_External_charSetandLanguageNegotiation,
         (Odr_fun)z_CharSetandLanguageNegotiation, 0},
        {ODR_EXPLICIT, ODR_CONTEXT, 0, Z_External_acfPrompt1,
         (Odr_fun)z_PromptObject1, 0},
        {ODR_EXPLICIT, ODR_CONTEXT, 0, Z_External_acfDes1,
         (Odr_fun)z_DES_RN_Object, 0},

        {ODR_EXPLICIT, ODR_CONTEXT, 0, Z_External_acfKrb1,
         (Odr_fun)z_KRBObject, 0},
        {ODR_EXPLICIT, ODR_CONTEXT, 0, Z_External_multisrch2,
         (Odr_fun)z_MultipleSearchTerms_2, 0},
        {ODR_EXPLICIT, ODR_CONTEXT, 0, Z_External_CQL,
         (Odr_fun)z_InternationalString, 0},
        {ODR_EXPLICIT, ODR_CONTEXT, 0, Z_External_OCLCUserInfo,
         (Odr_fun)z_OCLC_UserInformation, 0},
        {-1, -1, -1, -1, 0, 0}
    };

    odr_implicit_settag(o, ODR_UNIVERSAL, ODR_EXTERNAL);
    if (!odr_sequence_begin(o, p, sizeof(**p), name))
        return opt && odr_ok(o);
    if (!(odr_oid(o, &(*p)->direct_reference, 1, 0) &&
          odr_integer(o, &(*p)->indirect_reference, 1, 0) &&
          odr_graphicstring(o, &(*p)->descriptor, 1, 0)))
        return 0;
#if PRT_EXT_DEBUG
    /* debugging purposes only */
    if (o->direction == ODR_DECODE)
    {
        yaz_log(YLOG_LOG, "z_external decode");
        if ((*p)->direct_reference)
        {
            yaz_log(YLOG_LOG, "direct reference");
            if ((oid = oid_getentbyoid((*p)->direct_reference)))
            {
                yaz_log(YLOG_LOG, "oid %s", oid->desc);
                if ((type = z_ext_getentbyref(oid->value)))
                    yaz_log(YLOG_LOG, "type");
            }
        }
    }
#endif
    /* Do we know this beast? */
    if (o->direction == ODR_DECODE && (*p)->direct_reference &&
        (oid = oid_getentbyoid((*p)->direct_reference)) &&
        (type = z_ext_getentbyref(oid->value)))
    {
        int zclass, tag, cons;
        /* OID is present and we know it */

        if (!odr_peektag(o, &zclass, &tag, &cons))
            return opt && odr_ok(o);
#if PRT_EXT_DEBUG
        yaz_log(YLOG_LOG, "odr_peektag OK tag=%d cons=%d zclass=%d what=%d",
                tag, cons, zclass, type->what);
#endif
        if (zclass == ODR_CONTEXT && tag == 1 && cons == 0)
        {
            /* we have an OCTET STRING. decode BER contents from it */
            const unsigned char *o_bp;
            unsigned char *o_buf;
            int o_size;
            char *voidp = 0;
            Odr_oct *oct;
            int r;
            if (!odr_implicit_tag(o, odr_octetstring, &oct,
                                 ODR_CONTEXT, 1, 0, "octetaligned"))
                return 0;

            /* Save our decoding ODR members */
            o_bp = o->bp; 
            o_buf = o->buf;
            o_size = o->size;

            /* Set up the OCTET STRING buffer */
            o->bp = o->buf = oct->buf;
            o->size = oct->len;

            /* and decode that */
            r = (*type->fun)(o, &voidp, 0, 0);
            (*p)->which = type->what;
            (*p)->u.single_ASN1_type = (Odr_any*) voidp;
                
            /* Restore our decoding ODR member */
            o->bp = o_bp; 
            o->buf = o_buf;
            o->size = o_size;

            return r && odr_sequence_end(o);
        }
        if (zclass == ODR_CONTEXT && tag == 0 && cons == 1)
        { 
            /* It's single ASN.1 type, bias the CHOICE. */
            odr_choice_bias(o, type->what);
        }
    }
    return
        odr_choice(o, arm, &(*p)->u, &(*p)->which, name) &&
        odr_sequence_end(o);
}

Z_External *z_ext_record(ODR o, int format, const char *buf, int len)
{
    Z_External *thisext;

    thisext = (Z_External *) odr_malloc(o, sizeof(*thisext));
    thisext->descriptor = 0;
    thisext->indirect_reference = 0;

    thisext->direct_reference = 
        yaz_oidval_to_z3950oid (o, CLASS_RECSYN, format);    
    if (!thisext->direct_reference)
        return 0;

    if (len < 0) /* Structured data */
    {
        /*
         * We cheat on the pointers here. Obviously, the record field
         * of the backend-fetch structure should have been a union for
         * correctness, but we're stuck with this for backwards
         * compatibility.
         */
        thisext->u.grs1 = (Z_GenericRecord*) buf;

        switch (format)
        {
        case VAL_SUTRS:
            thisext->which = Z_External_sutrs;
            break;
        case VAL_GRS1:
            thisext->which = Z_External_grs1;
            break;
        case VAL_EXPLAIN:
            thisext->which = Z_External_explainRecord;
            break;
        case VAL_SUMMARY:
            thisext->which = Z_External_summary;
            break;
        case VAL_OPAC:
            thisext->which = Z_External_OPAC;
            break;
        case VAL_EXTENDED:
            thisext->which = Z_External_extendedService;
            break;
        default:
            return 0;
        }
    }
    else if (format == VAL_SUTRS) /* SUTRS is a single-ASN.1-type */
    {
        Odr_oct *sutrs = (Odr_oct *)odr_malloc(o, sizeof(*sutrs));
        
        thisext->which = Z_External_sutrs;
        thisext->u.sutrs = sutrs;
        sutrs->buf = (unsigned char *)odr_malloc(o, len);
        sutrs->len = sutrs->size = len;
        memcpy(sutrs->buf, buf, len);
    }
    else
    {
        thisext->which = Z_External_octet;
        if (!(thisext->u.octet_aligned = (Odr_oct *)
              odr_malloc(o, sizeof(Odr_oct))))
            return 0;
        if (!(thisext->u.octet_aligned->buf = (unsigned char *)
              odr_malloc(o, len)))
            return 0;
        memcpy(thisext->u.octet_aligned->buf, buf, len);
        thisext->u.octet_aligned->len = thisext->u.octet_aligned->size = len;
    }
    return thisext;
}

/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

