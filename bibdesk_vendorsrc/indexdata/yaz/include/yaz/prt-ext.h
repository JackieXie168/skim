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
/* $Id: prt-ext.h,v 1.14 2006/10/09 21:02:41 adam Exp $ */

/**
 * \file prt-ext.h
 * \brief Header for utilities that handles Z39.50 EXTERNALs
 */

/*
 * Biased-choice External for Z39.50.
 */

#ifndef PRT_EXT_H
#define PRT_EXT_H

#include "yconfig.h"
#include "oid.h"


YAZ_BEGIN_CDECL

/**
 * Used to keep track of known External definitions (a loose approach
 * to DEFINED_BY).
 */
typedef struct Z_ext_typeent
{
    oid_value dref;    /* the direct-reference OID value. */
    int what;          /* discriminator value for the external CHOICE */
    Odr_fun fun;       /* decoder function */
} Z_ext_typeent;

/** \brief structure for all known EXTERNALs */
struct Z_External
{
    Odr_oid *direct_reference;
    int *indirect_reference;
    char *descriptor;
    int which;
/* Generic types */
#define Z_External_single 0
#define Z_External_octet 1
#define Z_External_arbitrary 2
/* Specific types */
#define Z_External_sutrs 3
#define Z_External_explainRecord 4
#define Z_External_resourceReport1 5
#define Z_External_resourceReport2 6
#define Z_External_promptObject1 7
#define Z_External_grs1 8
#define Z_External_extendedService 9
#define Z_External_itemOrder 10
#define Z_External_diag1 11
#define Z_External_espec1 12
#define Z_External_summary 13
#define Z_External_OPAC 14
#define Z_External_searchResult1 15
#define Z_External_update 16
#define Z_External_dateTime 17
#define Z_External_universeReport 18
#define Z_External_ESAdmin 19
#define Z_External_update0 20
#define Z_External_userInfo1 21
#define Z_External_charSetandLanguageNegotiation 22
#define Z_External_acfPrompt1 23
#define Z_External_acfDes1 24
#define Z_External_acfKrb1 25
#define Z_External_multisrch2 26
#define Z_External_CQL 27
#define Z_External_OCLCUserInfo 28
    union
    {
        /* Generic types */
        Odr_any *single_ASN1_type;
        Odr_oct *octet_aligned;
        Odr_bitmask *arbitrary;

        /* Specific types */
        Z_SUTRS *sutrs;
        Z_ExplainRecord *explainRecord;

        Z_ResourceReport1 *resourceReport1;
        Z_ResourceReport2 *resourceReport2;
        Z_PromptObject1 *promptObject1;
        Z_GenericRecord *grs1;
        Z_TaskPackage *extendedService;

        Z_ItemOrder *itemOrder;
        Z_DiagnosticFormat *diag1;
        Z_Espec1 *espec1;
        Z_BriefBib *summary;
        Z_OPACRecord *opac;

        Z_SearchInfoReport *searchResult1;
        Z_IUUpdate *update;
        Z_DateTime *dateTime;
        Z_UniverseReport *universeReport;
        Z_Admin *adminService;

        Z_IU0Update *update0;
        Z_OtherInformation *userInfo1;
        Z_CharSetandLanguageNegotiation *charNeg3;
        Z_PromptObject1 *acfPrompt1;
        Z_DES_RN_Object *acfDes1;

        Z_KRBObject *acfKrb1;
        Z_MultipleSearchTerms_2 *multipleSearchTerms_2;
        Z_InternationalString *cql;
        Z_OCLC_UserInformation *oclc;
    } u;
};


/** \brief codec for BER EXTERNAL */
YAZ_EXPORT int z_External(ODR o, Z_External **p, int opt, const char *name);
/** \brief returns type information for OID (NULL if not known) */
YAZ_EXPORT Z_ext_typeent *z_ext_getentbyref(oid_value val);
/** \brief encodes EXTERNAL record based on OID (NULL if knot known) */
YAZ_EXPORT Z_External *z_ext_record(ODR o, int format, const char *buf,
                                    int len);

YAZ_END_CDECL

#endif
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

