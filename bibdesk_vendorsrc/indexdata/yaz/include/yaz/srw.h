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
/* $Id: srw.h,v 1.32 2006/12/06 21:35:58 adam Exp $ */

/**
 * \file srw.h
 * \brief Header for SRW/SRU
 */

#ifndef YAZ_SRW_H
#define YAZ_SRW_H

#include <yaz/soap.h>
#include <yaz/zgdu.h>
#include <yaz/diagsrw.h>
#include <yaz/diagsru_update.h>

YAZ_BEGIN_CDECL

typedef struct {
    char *extraRecordData_buf;
    int extraRecordData_len;
    char *recordIdentifier;
} Z_SRW_extra_record;

typedef struct {
    char *recordSchema;
    int recordPacking;
#define Z_SRW_recordPacking_string 0
#define Z_SRW_recordPacking_XML 1
#define Z_SRW_recordPacking_URL 2
    char *recordData_buf;
    int recordData_len;
    int *recordPosition;
} Z_SRW_record;

typedef struct {
    char *uri;
    char *details;
    char *message;
} Z_SRW_diagnostic;
    
typedef struct {

#define Z_SRW_query_type_cql  1
#define Z_SRW_query_type_xcql 2
#define Z_SRW_query_type_pqf  3
    int query_type;
    union {
        char *cql;
        char *xcql;
        char *pqf;
    } query;

#define Z_SRW_sort_type_none 1
#define Z_SRW_sort_type_sort 2
#define Z_SRW_sort_type_xSort 3
    int sort_type;
    union {
        char *none;
        char *sortKeys;
        char *xSortKeys;
    } sort;
    int *startRecord;
    int *maximumRecords;
    char *recordSchema;
    char *recordPacking;
    char *recordXPath;
    char *database;
    char *stylesheet;
    int *resultSetTTL;
} Z_SRW_searchRetrieveRequest;

typedef struct {
    int * numberOfRecords;
    char * resultSetId;
    int * resultSetIdleTime;
    
    Z_SRW_record *records;
    int num_records;

    Z_SRW_diagnostic *diagnostics;
    int num_diagnostics;
    int *nextRecordPosition;

    Z_SRW_extra_record **extra_records;  /* of size num_records */
} Z_SRW_searchRetrieveResponse;

typedef struct {
    char *recordPacking;
    char *database;
    char *stylesheet;
} Z_SRW_explainRequest;

typedef struct {
    Z_SRW_record record;
    Z_SRW_diagnostic *diagnostics;
    int num_diagnostics;
    Z_SRW_extra_record *extra_record;
} Z_SRW_explainResponse;
    
typedef struct {
    int query_type;
    union {
        char *cql;
        char *xcql;
        char *pqf;
    } scanClause;
    int *responsePosition;
    int *maximumTerms;
    char *stylesheet;
    char *database;
} Z_SRW_scanRequest;

typedef struct {
    char *value;
    int *numberOfRecords;
    char *displayTerm;
    char *whereInList;
} Z_SRW_scanTerm;

typedef struct {
    Z_SRW_scanTerm *terms;
    int num_terms;
    Z_SRW_diagnostic *diagnostics;
    int num_diagnostics;
} Z_SRW_scanResponse;


typedef struct {
    char *versionType;
    char *versionValue;
} Z_SRW_recordVersion;

typedef struct {
    char *database;
    char *operation;
    char *recordId;
    Z_SRW_recordVersion *recordVersions;
    int num_recordVersions;
    Z_SRW_record *record;
    Z_SRW_extra_record *extra_record;
    char *extraRequestData_buf;
    int extraRequestData_len;
    char *stylesheet;
} Z_SRW_updateRequest;

typedef struct {
    char *operationStatus;
    char *recordId;
    Z_SRW_recordVersion *recordVersions;
    int num_recordVersions;
    Z_SRW_record *record;
    Z_SRW_extra_record *extra_record;
    char *extraResponseData_buf;
    int extraResponseData_len;
    Z_SRW_diagnostic *diagnostics;
    int num_diagnostics;
} Z_SRW_updateResponse;

#define Z_SRW_searchRetrieve_request  1
#define Z_SRW_searchRetrieve_response 2
#define Z_SRW_explain_request 3
#define Z_SRW_explain_response 4
#define Z_SRW_scan_request 5
#define Z_SRW_scan_response 6
#define Z_SRW_update_request 7
#define Z_SRW_update_response 8

typedef struct {
    int which;
    union {
        Z_SRW_searchRetrieveRequest *request;
        Z_SRW_searchRetrieveResponse *response;
        Z_SRW_explainRequest *explain_request;
        Z_SRW_explainResponse *explain_response;
        Z_SRW_scanRequest *scan_request;
        Z_SRW_scanResponse *scan_response;
        Z_SRW_updateRequest *update_request;
        Z_SRW_updateResponse *update_response;
    } u;
    char *srw_version;
    char *username; /* From HTTP header or request */
    char *password; /* From HTTP header or request  */
    char *extra_args; /* For SRU GET/POST only */
} Z_SRW_PDU;

YAZ_EXPORT int yaz_srw_codec(ODR o, void * pptr,
                             Z_SRW_PDU **handler_data,
                             void *client_data, const char *ns);
YAZ_EXPORT int yaz_ucp_codec(ODR o, void * pptr,
                             Z_SRW_PDU **handler_data,
                             void *client_data, const char *ns);
YAZ_EXPORT Z_SRW_PDU *yaz_srw_get_core_v_1_1(ODR o);
YAZ_EXPORT Z_SRW_PDU *yaz_srw_get(ODR o, int which);
YAZ_EXPORT Z_SRW_recordVersion *yaz_srw_get_record_versions(ODR o, int num);
YAZ_EXPORT Z_SRW_extra_record *yaz_srw_get_extra_record(ODR o);
YAZ_EXPORT Z_SRW_record *yaz_srw_get_record(ODR o);
YAZ_EXPORT Z_SRW_record *yaz_srw_get_records(ODR o, int num);

YAZ_EXPORT int yaz_diag_bib1_to_srw (int bib1_code);

YAZ_EXPORT int yaz_diag_srw_to_bib1(int srw_code);

YAZ_EXPORT const char *yaz_srw_pack_to_str(int pack);
YAZ_EXPORT int yaz_srw_str_to_pack(const char *str);

YAZ_EXPORT char *yaz_uri_val(const char *path, const char *name, ODR o);
YAZ_EXPORT void yaz_uri_val_int(const char *path, const char *name,
                                ODR o, int **intp);
YAZ_EXPORT int yaz_srw_decode(Z_HTTP_Request *hreq, Z_SRW_PDU **srw_pdu,
                              Z_SOAP **soap_package, ODR decode, char **charset);
YAZ_EXPORT int yaz_sru_decode(Z_HTTP_Request *hreq, Z_SRW_PDU **srw_pdu,
                              Z_SOAP **soap_package, ODR decode, 
                              char **charset,
                              Z_SRW_diagnostic **, int *num_diagnostic);

YAZ_EXPORT void yaz_add_srw_diagnostic(ODR o, Z_SRW_diagnostic **d,
                                       int *num, int code,
                                       const char *addinfo);
    
YAZ_EXPORT void yaz_add_sru_update_diagnostic(ODR o, Z_SRW_diagnostic **d,
                                              int *num, int code,
                                              const char *addinfo);

YAZ_EXPORT void yaz_mk_std_diagnostic(ODR o, Z_SRW_diagnostic *d, 
                                      int code, const char *details);

YAZ_EXPORT void yaz_add_srw_diagnostic_uri(ODR o, Z_SRW_diagnostic **d,
                                           int *num, const char *uri,
                                           const char *message,
                                           const char *details);

YAZ_EXPORT void yaz_mk_srw_diagnostic(ODR o, Z_SRW_diagnostic *d, 
                                      const char *uri, const char *message,
                                      const char *details);

YAZ_EXPORT int yaz_sru_get_encode(Z_HTTP_Request *hreq, Z_SRW_PDU *srw_pdu,
                                  ODR encode, const char *charset);
YAZ_EXPORT int yaz_sru_post_encode(Z_HTTP_Request *hreq, Z_SRW_PDU *srw_pdu,
                                   ODR encode, const char *charset);
YAZ_EXPORT int yaz_sru_soap_encode(Z_HTTP_Request *hreq, Z_SRW_PDU *srw_pdu,
                                   ODR odr, const char *charset);

#define YAZ_XMLNS_SRU_v1_0 "http://www.loc.gov/zing/srw/v1.0/"
#define YAZ_XMLNS_SRU_v1_1 "http://www.loc.gov/zing/srw/"
#define YAZ_XMLNS_DIAG_v1_1 "http://www.loc.gov/zing/srw/diagnostic/"
#define YAZ_XMLNS_UPDATE_v0_9 "http://www.loc.gov/zing/srw/update/"

YAZ_END_CDECL

#endif
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

