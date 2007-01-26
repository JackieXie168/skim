/*
 * Copyright (C) 1995-2007, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: charneg.c,v 1.7 2007/01/03 08:42:15 adam Exp $
 */

/** 
 * \file charneg.c
 * \brief Implements Z39.50 Charset negotiation utilities
 *
 * Helper functions for Character Set and Language Negotiation - 3
 */
#include <stdio.h>
#include <yaz/otherinfo.h>
#include <yaz/z-charneg.h>
#include <yaz/charneg.h>
#include <yaz/yaz-util.h>

static Z_External* z_ext_record2(ODR o, int oid_class, int oid_value,
                                 const char *buf)
{
    Z_External *p;
    oident oid;
    int len = strlen(buf);
    
    if (!(p = (Z_External *)odr_malloc(o, sizeof(*p)))) return 0;
    
    p->descriptor = 0;
    p->indirect_reference = 0;
    
    oid.proto = PROTO_Z3950;
    oid.oclass = (enum oid_class) oid_class;
    oid.value = (enum oid_value) oid_value;
    p->direct_reference = odr_oiddup(o, oid_getoidbyent(&oid));
    
    p->which = Z_External_octet;
    if (!(p->u.octet_aligned = (Odr_oct *)odr_malloc(o, sizeof(Odr_oct)))) {
        return 0;
    }
    if (!(p->u.octet_aligned->buf = (unsigned char *)odr_malloc(o, len))) {
        return 0;
    }
    p->u.octet_aligned->len = p->u.octet_aligned->size = len;
    memcpy(p->u.octet_aligned->buf, buf, len);
        
    return p;
}

static int get_form(const char *charset)
{
    int form = -1;


    if (!yaz_matchstr(charset, "UCS-2"))
        form = 2;
    if (!yaz_matchstr(charset, "UCS-4"))
        form = 4;
    if (!yaz_matchstr(charset, "UTF-16"))
        form = 5;
    if (!yaz_matchstr(charset, "UTF-8"))
        form = 8;

    return form;
}

static char *set_form (Odr_oid *encoding)
{
    static char *charset = 0;
    if ( oid_oidlen(encoding) != 6)
        return 0;
    if (encoding[5] == 2)
        charset = "UCS-2";
    if (encoding[5] == 4)
        charset = "UCS-4";
    if (encoding[5] == 5)
        charset = "UTF-16";
    if (encoding[5] == 8)
        charset = "UTF-8";
    return charset;
}

static Z_OriginProposal_0 *z_get_OriginProposal_0(ODR o, const char *charset)
{
    int form = get_form (charset);
    Z_OriginProposal_0 *p0 =
        (Z_OriginProposal_0*)odr_malloc(o, sizeof(*p0));

    memset(p0, 0, sizeof(*p0));

    if (form > 0)
    {   /* ISO 10646 (UNICODE) */
        char oidname[20];

        Z_Iso10646 *is = (Z_Iso10646 *) odr_malloc (o, sizeof(*is));
        p0->which = Z_OriginProposal_0_iso10646;
        p0->u.iso10646 = is;
        is->collections = 0;
        sprintf (oidname, "1.0.10646.1.0.%d", form);
        is->encodingLevel = odr_getoidbystr (o, oidname);
    }
    else
    {   /* private ones */
        Z_PrivateCharacterSet *pc =
            (Z_PrivateCharacterSet *)odr_malloc(o, sizeof(*pc));

        memset(pc, 0, sizeof(*pc));
        
        p0->which = Z_OriginProposal_0_private;
        p0->u.zprivate = pc;
        
        pc->which = Z_PrivateCharacterSet_externallySpecified;
        pc->u.externallySpecified =
            z_ext_record2(o, CLASS_NEGOT, VAL_ID_CHARSET, charset);
    }
    return p0;
}

static Z_OriginProposal *z_get_OriginProposal(
    ODR o, const char **charsets, int num_charsets,
    const char **langs, int num_langs, int selected)
{       
    int i;
    Z_OriginProposal *p = (Z_OriginProposal *) odr_malloc(o, sizeof(*p));
                
    memset(p, 0, sizeof(*p));

    p->recordsInSelectedCharSets = (bool_t *)odr_malloc(o, sizeof(bool_t));
    *p->recordsInSelectedCharSets = (selected) ? 1:0;

    if (charsets && num_charsets) {             
        
        p->num_proposedCharSets = num_charsets;
        p->proposedCharSets = 
            (Z_OriginProposal_0**)
            odr_malloc(o, num_charsets*sizeof(Z_OriginProposal_0*));

        for (i = 0; i<num_charsets; i++)
            p->proposedCharSets[i] =
                z_get_OriginProposal_0(o, charsets[i]);
    }
    if (langs && num_langs) {
        
        p->num_proposedlanguages = num_langs;

        p->proposedlanguages = 
            (char **) odr_malloc(o, num_langs*sizeof(char *));

        for (i = 0; i<num_langs; i++) {

            p->proposedlanguages[i] = (char *)langs[i];
                        
        }
    }
    return p;
}

static Z_CharSetandLanguageNegotiation *z_get_CharSetandLanguageNegotiation(
    ODR o)
{
    Z_CharSetandLanguageNegotiation *p =
        (Z_CharSetandLanguageNegotiation *) odr_malloc(o, sizeof(*p));
    
    memset(p, 0, sizeof(*p));
        
    return p;
}

/* Create EXTERNAL for negotation proposal. Client side */
Z_External *yaz_set_proposal_charneg(ODR o,
                                     const char **charsets, int num_charsets,
                                     const char **langs, int num_langs,
                                     int selected)
{
    Z_External *p = (Z_External *)odr_malloc(o, sizeof(*p));
    oident oid;
        
    p->descriptor = 0;
    p->indirect_reference = 0;  

    oid.proto = PROTO_Z3950;
    oid.oclass = CLASS_NEGOT;
    oid.value = VAL_CHARNEG3;
    p->direct_reference = odr_oiddup(o, oid_getoidbyent(&oid));

    p->which = Z_External_charSetandLanguageNegotiation;
    p->u.charNeg3 = z_get_CharSetandLanguageNegotiation(o);
    p->u.charNeg3->which = Z_CharSetandLanguageNegotiation_proposal;
    p->u.charNeg3->u.proposal =
        z_get_OriginProposal(o, charsets, num_charsets,
                             langs, num_langs, selected);

    return p;
}

Z_External *yaz_set_proposal_charneg_list(ODR o,
                                          const char *delim,
                                          const char *charset_list,
                                          const char *lang_list,
                                          int selected)
{
    char **charsets_addresses = 0;
    char **langs_addresses = 0;
    int charsets_count = 0;
    int langs_count = 0;
    
    if (charset_list)
        nmem_strsplit(o->mem, delim, charset_list,
                      &charsets_addresses, &charsets_count);
    if (lang_list)
        nmem_strsplit(o->mem, delim, lang_list,
                      &langs_addresses, &langs_count);    
    return yaz_set_proposal_charneg(o,
                                    (const char **) charsets_addresses,
                                    charsets_count,
                                    (const char **) langs_addresses,
                                    langs_count, 
                                    selected);
}


/* used by yaz_set_response_charneg */
static Z_TargetResponse *z_get_TargetResponse(ODR o, const char *charset,
                                              const char *lang, int selected)
{       
    Z_TargetResponse *p = (Z_TargetResponse *) odr_malloc(o, sizeof(*p));
    int form = get_form(charset);

    memset(p, 0, sizeof(*p));

    if (form > 0)
    {
        char oidname[20];

        Z_Iso10646 *is = (Z_Iso10646 *) odr_malloc (o, sizeof(*is));
        p->which = Z_TargetResponse_iso10646;
        p->u.iso10646 = is;
        is->collections = 0;
        sprintf (oidname, "1.0.10646.1.0.%d", form);
        is->encodingLevel = odr_getoidbystr (o, oidname);
    }
    else
    {
        Z_PrivateCharacterSet *pc =
            (Z_PrivateCharacterSet *)odr_malloc(o, sizeof(*pc));
        
        memset(pc, 0, sizeof(*pc));
        
        p->which = Z_TargetResponse_private;
        p->u.zprivate = pc;
        
        pc->which = Z_PrivateCharacterSet_externallySpecified;
        pc->u.externallySpecified =
            z_ext_record2(o, CLASS_NEGOT, VAL_ID_CHARSET, charset);
    }
    p->recordsInSelectedCharSets = (bool_t *)odr_malloc(o, sizeof(bool_t));
    *p->recordsInSelectedCharSets = (selected) ? 1:0;
    
    p->selectedLanguage = lang ? (char *)odr_strdup(o, lang) : 0;
    return p;
}

/* Create charset response. Server side */
Z_External *yaz_set_response_charneg(ODR o, const char *charset,
                                     const char *lang, int selected)
{
    Z_External *p = (Z_External *)odr_malloc(o, sizeof(*p));
    oident oid;
        
    p->descriptor = 0;
    p->indirect_reference = 0;  

    oid.proto = PROTO_Z3950;
    oid.oclass = CLASS_NEGOT;
    oid.value = VAL_CHARNEG3;
    p->direct_reference = odr_oiddup(o, oid_getoidbyent(&oid));

    p->which = Z_External_charSetandLanguageNegotiation;
    p->u.charNeg3 = z_get_CharSetandLanguageNegotiation(o);
    p->u.charNeg3->which = Z_CharSetandLanguageNegotiation_response;
    p->u.charNeg3->u.response = z_get_TargetResponse(o, charset, lang, selected);

    return p;
}

/* Get negotiation from OtherInformation. Client&Server side */
Z_CharSetandLanguageNegotiation *yaz_get_charneg_record(Z_OtherInformation *p)
{
    int i;
        
    if (!p)
        return 0;
        
    for (i = 0; i < p->num_elements; i++) {
        Z_External *pext;
        if ((p->list[i]->which == Z_OtherInfo_externallyDefinedInfo) &&
            (pext = p->list[i]->information.externallyDefinedInfo)) {
            
            oident *ent = oid_getentbyoid(pext->direct_reference);
            
            if (ent && ent->value == VAL_CHARNEG3 
                && ent->oclass == CLASS_NEGOT
                &&  pext->which == Z_External_charSetandLanguageNegotiation)
            {
                return pext->u.charNeg3;
            }
        }
    }
    return 0;
}

/* Delete negotiation from OtherInformation. Client&Server side */
int yaz_del_charneg_record(Z_OtherInformation **p)
{
    int i;
        
    if (!*p)
        return 0;
        
    for (i = 0; i < (*p)->num_elements; i++) {
        Z_External *pext;
        if (((*p)->list[i]->which == Z_OtherInfo_externallyDefinedInfo) &&
            (pext = (*p)->list[i]->information.externallyDefinedInfo)) {
            
            oident *ent = oid_getentbyoid(pext->direct_reference);
            
            if (ent && ent->value == VAL_CHARNEG3 
                && ent->oclass == CLASS_NEGOT
                && pext->which == Z_External_charSetandLanguageNegotiation)
            {
                --((*p)->num_elements);
                if ((*p)->num_elements == 0)
                    *p = 0;
                else
                {
                    for(; i < (*p)->num_elements; i++)
                        (*p)->list[i] = (*p)->list[i+1];
                }
                return 1;
            }
        }
    }
    return 0;
}


/* Get charsets, langs, selected from negotiation.. Server side */
void yaz_get_proposal_charneg(NMEM mem, Z_CharSetandLanguageNegotiation *p,
                              char ***charsets, int *num_charsets,
                              char ***langs, int *num_langs, int *selected)
{
    int i;
    Z_OriginProposal *pro = p->u.proposal;
    
    if (num_charsets && charsets)
    {
        if (pro->num_proposedCharSets)
        {
            *num_charsets = pro->num_proposedCharSets;
            
            (*charsets) = (char **)
                nmem_malloc(mem, pro->num_proposedCharSets * sizeof(char *));
            
            for (i=0; i<pro->num_proposedCharSets; i++) 
            {
                (*charsets)[i] = 0;
                
                if (pro->proposedCharSets[i]->which ==
                    Z_OriginProposal_0_private &&
                    pro->proposedCharSets[i]->u.zprivate->which ==
                    Z_PrivateCharacterSet_externallySpecified) {
                    
                    Z_External *pext =
                        pro->proposedCharSets[i]->u.zprivate->u.externallySpecified;
                    
                    if (pext->which == Z_External_octet) {
                        
                        (*charsets)[i] = (char *)
                            nmem_malloc(mem, (1+pext->u.octet_aligned->len) *
                                        sizeof(char));
                        
                        memcpy ((*charsets)[i], pext->u.octet_aligned->buf,
                                pext->u.octet_aligned->len);
                        (*charsets)[i][pext->u.octet_aligned->len] = 0;
                        
                    }
                }
                else if (pro->proposedCharSets[i]->which ==
                         Z_OriginProposal_0_iso10646)
                    (*charsets)[i] = set_form (
                        pro->proposedCharSets[i]->u.iso10646->encodingLevel);
            }
        }
        else
            *num_charsets = 0;
    }
    
    if (langs && num_langs)
    {
        if (pro->num_proposedlanguages)
        {
            *num_langs = pro->num_proposedlanguages;
            
            (*langs) = (char **)
                nmem_malloc(mem, pro->num_proposedlanguages * sizeof(char *));
            
            for (i=0; i<pro->num_proposedlanguages; i++)
                (*langs)[i] = nmem_strdup(mem, pro->proposedlanguages[i]);
        }
        else
            *num_langs = 0;
    }
    
    if(pro->recordsInSelectedCharSets && selected)
        *selected = *pro->recordsInSelectedCharSets;
}

/* Return charset, lang, selected from negotiation.. Client side */
void yaz_get_response_charneg(NMEM mem, Z_CharSetandLanguageNegotiation *p,
                              char **charset, char **lang, int *selected)
{
    Z_TargetResponse *res = p->u.response;
        
    if (charset && res->which == Z_TargetResponse_private &&
        res->u.zprivate->which == Z_PrivateCharacterSet_externallySpecified) {

        Z_External *pext = res->u.zprivate->u.externallySpecified;
        
        if (pext->which == Z_External_octet) {
            
            *charset = (char *)
                nmem_malloc(mem, (1+pext->u.octet_aligned->len)*sizeof(char));
            memcpy (*charset, pext->u.octet_aligned->buf,
                    pext->u.octet_aligned->len);
            (*charset)[pext->u.octet_aligned->len] = 0;
        }       
    }
    if (charset && res->which == Z_TargetResponse_iso10646)
        *charset = set_form (res->u.iso10646->encodingLevel);
    if (lang && res->selectedLanguage)
        *lang = nmem_strdup (mem, res->selectedLanguage);

    if(selected && res->recordsInSelectedCharSets)
        *selected = *res->recordsInSelectedCharSets;
}
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

