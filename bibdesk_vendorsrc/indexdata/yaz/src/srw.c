/*
 * Copyright (C) 1995-2006, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: srw.c,v 1.53 2006/12/07 19:06:11 adam Exp $
 */
/**
 * \file srw.c
 * \brief Implements SRW/SRU package encoding and decoding
 */

#include "srw.h"
#if YAZ_HAVE_XML2
#include <libxml/parser.h>
#include <libxml/tree.h>
#include <assert.h>

static void add_XML_n(xmlNodePtr ptr, const char *elem, char *val, int len,
                      xmlNsPtr ns_ptr)
{
    if (val)
    {
        xmlDocPtr doc = xmlParseMemory(val,len);
        if (doc)
        {
            xmlNodePtr c = xmlNewChild(ptr, ns_ptr, BAD_CAST elem, 0);
            xmlNodePtr t = xmlDocGetRootElement(doc);
            xmlAddChild(c, xmlCopyNode(t,1));
            xmlFreeDoc(doc);
        }
    }
}

xmlNodePtr add_xsd_string_n(xmlNodePtr ptr, const char *elem, const char *val,
                            int len)
{
    if (val)
    {
        xmlNodePtr c = xmlNewChild(ptr, 0, BAD_CAST elem, 0);
        xmlNodePtr t = xmlNewTextLen(BAD_CAST val, len);
        xmlAddChild(c, t);
        return t;
    }
    return 0;
}

xmlNodePtr add_xsd_string_ns(xmlNodePtr ptr, const char *elem, const char *val,
                             xmlNsPtr ns_ptr)
{
    if (val)
    {
        xmlNodePtr c = xmlNewChild(ptr, ns_ptr, BAD_CAST elem, 0);
        xmlNodePtr t = xmlNewText(BAD_CAST val);
        xmlAddChild(c, t);
        return t;
    }
    return 0;
}

xmlNodePtr add_xsd_string(xmlNodePtr ptr, const char *elem, const char *val)
{
    return add_xsd_string_ns(ptr, elem, val, 0);
}

static void add_xsd_integer(xmlNodePtr ptr, const char *elem, const int *val)
{
    if (val)
    {
        char str[30];
        sprintf(str, "%d", *val);
        xmlNewTextChild(ptr, 0, BAD_CAST elem, BAD_CAST str);
    }
}

static int match_element(xmlNodePtr ptr, const char *elem)
{
    if (ptr->type == XML_ELEMENT_NODE && !xmlStrcmp(ptr->name, BAD_CAST elem))
    {
        return 1;
    }
    return 0;
}

#define CHECK_TYPE 0

static int match_xsd_string_n(xmlNodePtr ptr, const char *elem, ODR o,
                              char **val, int *len)
{
#if CHECK_TYPE
    struct _xmlAttr *attr;
#endif
    if (!match_element(ptr, elem))
        return 0;
#if CHECK_TYPE
    for (attr = ptr->properties; attr; attr = attr->next)
        if (!strcmp(attr->name, "type") &&
            attr->children && attr->children->type == XML_TEXT_NODE)
        {
            const char *t = strchr(attr->children->content, ':');
            if (t)
                t = t + 1;
            else
                t = attr->children->content;
            if (!strcmp(t, "string"))
                break;
        }
    if (!attr)
        return 0;
#endif
    ptr = ptr->children;
    if (!ptr || ptr->type != XML_TEXT_NODE)
    {
        *val = "";
        return 1;
    }
    *val = odr_strdup(o, (const char *) ptr->content);
    if (len)
        *len = xmlStrlen(ptr->content);
    return 1;
}


static int match_xsd_string(xmlNodePtr ptr, const char *elem, ODR o,
                            char **val)
{
    return match_xsd_string_n(ptr, elem, o, val, 0);
}

static int match_xsd_XML_n(xmlNodePtr ptr, const char *elem, ODR o,
                           char **val, int *len)
{
    xmlBufferPtr buf;
    xmlNode *tmp;

    if (!match_element(ptr, elem))
        return 0;

    ptr = ptr->children;
    while (ptr && (ptr->type == XML_TEXT_NODE || ptr->type == XML_COMMENT_NODE))
        ptr = ptr->next;
    if (!ptr)
        return 0;
    
    /* copy node to get NS right (bug #740). */
    tmp = xmlCopyNode(ptr, 1);
    
    buf = xmlBufferCreate();
    
    xmlNodeDump(buf, tmp->doc, tmp, 0, 0);
    
    xmlFreeNode(tmp);
    
    *val = odr_malloc(o, buf->use+1);
    memcpy (*val, buf->content, buf->use);
    (*val)[buf->use] = '\0';

    if (len)
        *len = buf->use;

    xmlBufferFree(buf);

    return 1;
}
                     
static int match_xsd_integer(xmlNodePtr ptr, const char *elem, ODR o, int **val)
{
#if CHECK_TYPE
    struct _xmlAttr *attr;
#endif
    if (!match_element(ptr, elem))
        return 0;
#if CHECK_TYPE
    for (attr = ptr->properties; attr; attr = attr->next)
        if (!strcmp(attr->name, "type") &&
            attr->children && attr->children->type == XML_TEXT_NODE)
        {
            const char *t = strchr(attr->children->content, ':');
            if (t)
                t = t + 1;
            else
                t = attr->children->content;
            if (!strcmp(t, "integer"))
                break;
        }
    if (!attr)
        return 0;
#endif
    ptr = ptr->children;
    if (!ptr || ptr->type != XML_TEXT_NODE)
        return 0;
    *val = odr_intdup(o, atoi((const char *) ptr->content));
    return 1;
}

static int yaz_srw_record(ODR o, xmlNodePtr pptr, Z_SRW_record *rec,
                          Z_SRW_extra_record **extra,
                          void *client_data, const char *ns)
{
    if (o->direction == ODR_DECODE)
    {
        Z_SRW_extra_record ex;

        char *spack = 0;
        int pack = Z_SRW_recordPacking_string;
        xmlNodePtr ptr;
        xmlNodePtr data_ptr = 0;
        rec->recordSchema = 0;
        rec->recordData_buf = 0;
        rec->recordData_len = 0;
        rec->recordPosition = 0;
        *extra = 0;

        ex.extraRecordData_buf = 0;
        ex.extraRecordData_len = 0;
        ex.recordIdentifier = 0;

        for (ptr = pptr->children; ptr; ptr = ptr->next)
        {
            
            if (match_xsd_string(ptr, "recordSchema", o, 
                                 &rec->recordSchema))
                ;
            else if (match_xsd_string(ptr, "recordPacking", o, &spack))
            {
                if (spack && !strcmp(spack, "xml"))
                    pack = Z_SRW_recordPacking_XML;
                if (spack && !strcmp(spack, "url"))
                    pack = Z_SRW_recordPacking_URL;
                if (spack && !strcmp(spack, "string"))
                    pack = Z_SRW_recordPacking_string;
            }
            else if (match_xsd_integer(ptr, "recordPosition", o, 
                                       &rec->recordPosition))
                ;
            else if (match_element(ptr, "recordData"))
            {
                /* save position of Data until after the loop
                   then we will know the packing (hopefully), and
                   unpacking is done once
                */
                data_ptr = ptr;
            }
            else if (match_xsd_XML_n(ptr, "extraRecordData", o, 
                                     &ex.extraRecordData_buf,
                                     &ex.extraRecordData_len) )
                ;
            else if (match_xsd_string(ptr, "recordIdentifier", o, 
                                      &ex.recordIdentifier))
                ;

        }
        if (data_ptr)
        {
            switch(pack)
            {
            case Z_SRW_recordPacking_XML:
                match_xsd_XML_n(data_ptr, "recordData", o, 
                                &rec->recordData_buf, &rec->recordData_len);
                break;
            case Z_SRW_recordPacking_URL:
                /* just store it as a string.
                   leave it to the backend to collect the document */
                match_xsd_string_n(data_ptr, "recordData", o, 
                                   &rec->recordData_buf, &rec->recordData_len);
                break;
            case Z_SRW_recordPacking_string:
                match_xsd_string_n(data_ptr, "recordData", o, 
                                   &rec->recordData_buf, &rec->recordData_len);
                break;
            }
        }
        rec->recordPacking = pack;
        if (ex.extraRecordData_buf || ex.recordIdentifier)
        {
            *extra = (Z_SRW_extra_record *)
                odr_malloc(o, sizeof(Z_SRW_extra_record));
            memcpy(*extra, &ex, sizeof(Z_SRW_extra_record));
        }
    }
    else if (o->direction == ODR_ENCODE)
    {
        xmlNodePtr ptr = pptr;
        int pack = rec->recordPacking;
        add_xsd_string(ptr, "recordSchema", rec->recordSchema);

        switch(pack)
        {
        case Z_SRW_recordPacking_string:
            add_xsd_string(ptr, "recordPacking", "string");
            add_xsd_string_n(ptr, "recordData", rec->recordData_buf,
                             rec->recordData_len);
            break;
        case Z_SRW_recordPacking_XML:
            add_xsd_string(ptr, "recordPacking", "xml");
            add_XML_n(ptr, "recordData", rec->recordData_buf,
                      rec->recordData_len, 0);
            break;
        case Z_SRW_recordPacking_URL:
            add_xsd_string(ptr, "recordPacking", "url");
            add_xsd_string_n(ptr, "recordData", rec->recordData_buf,
                             rec->recordData_len);
            break;
        }
        if (rec->recordPosition)
            add_xsd_integer(ptr, "recordPosition", rec->recordPosition );
        if (extra && *extra)
        {
            if ((*extra)->recordIdentifier)
                add_xsd_string(ptr, "recordIdentifier",
                               (*extra)->recordIdentifier);
            if ((*extra)->extraRecordData_buf)
                add_XML_n(ptr, "extraRecordData",
                          (*extra)->extraRecordData_buf,
                          (*extra)->extraRecordData_len, 0);
        }
    }
    return 0;
}

static int yaz_srw_records(ODR o, xmlNodePtr pptr, Z_SRW_record **recs,
                           Z_SRW_extra_record ***extra,
                           int *num, void *client_data, const char *ns)
{
    if (o->direction == ODR_DECODE)
    {
        int i;
        xmlNodePtr ptr;
        *num = 0;
        for (ptr = pptr->children; ptr; ptr = ptr->next)
        {
            if (ptr->type == XML_ELEMENT_NODE &&
                !xmlStrcmp(ptr->name, BAD_CAST "record"))
                (*num)++;
        }
        if (!*num)
            return 1;
        *recs = (Z_SRW_record *) odr_malloc(o, *num * sizeof(**recs));
        *extra = (Z_SRW_extra_record **) odr_malloc(o, *num * sizeof(**extra));
        for (i = 0, ptr = pptr->children; ptr; ptr = ptr->next)
        {
            if (ptr->type == XML_ELEMENT_NODE &&
                !xmlStrcmp(ptr->name, BAD_CAST "record"))
            {
                yaz_srw_record(o, ptr, *recs + i, *extra + i, client_data, ns);
                i++;
            }
        }
    }
    else if (o->direction == ODR_ENCODE)
    {
        int i;
        for (i = 0; i < *num; i++)
        {
            xmlNodePtr rptr = xmlNewChild(pptr, 0, BAD_CAST "record",
                                          0);
            yaz_srw_record(o, rptr, (*recs)+i, (*extra ? *extra + i : 0),
                           client_data, ns);
        }
    }
    return 0;
}

static int yaz_srw_version(ODR o, xmlNodePtr pptr, Z_SRW_recordVersion *rec,
                           void *client_data, const char *ns)
{
    if (o->direction == ODR_DECODE)
    {
        xmlNodePtr ptr;
        rec->versionType = 0;
        rec->versionValue = 0;
        for (ptr = pptr->children; ptr; ptr = ptr->next)
        {
            
            if (match_xsd_string(ptr, "versionType", o, 
                                 &rec->versionType))
                ;
            else if (match_xsd_string(ptr, "versionValue", o, 
                                      &rec->versionValue))
                ;
        }
    }
    else if (o->direction == ODR_ENCODE)
        {
        xmlNodePtr ptr = pptr;
        add_xsd_string(ptr, "versionType", rec->versionType);
        add_xsd_string(ptr, "versionValue", rec->versionValue);
    }
    return 0;
}

static int yaz_srw_versions(ODR o, xmlNodePtr pptr, 
                            Z_SRW_recordVersion **vers,
                            int *num, void *client_data, const char *ns)
{
    if (o->direction == ODR_DECODE)
    {
        int i;
        xmlNodePtr ptr;
        *num = 0;
        for (ptr = pptr->children; ptr; ptr = ptr->next)
        {
            if (ptr->type == XML_ELEMENT_NODE &&
                !xmlStrcmp(ptr->name, BAD_CAST "recordVersion"))
                (*num)++;
        }
        if (!*num)
            return 1;
        *vers = (Z_SRW_recordVersion *) odr_malloc(o, *num * sizeof(**vers));
        for (i = 0, ptr = pptr->children; ptr; ptr = ptr->next)
        {
            if (ptr->type == XML_ELEMENT_NODE &&
                !xmlStrcmp(ptr->name, BAD_CAST "recordVersion"))
            {
                yaz_srw_version(o, ptr, *vers + i, client_data, ns);
                i++;
            }
        }
    }
    else if (o->direction == ODR_ENCODE)
    {
        int i;
        for (i = 0; i < *num; i++)
            {
            xmlNodePtr rptr = xmlNewChild(pptr, 0, BAD_CAST "version",
                                          0);
            yaz_srw_version(o, rptr, (*vers)+i, client_data, ns);
        }
    }
    return 0;
}

static int yaz_srw_diagnostics(ODR o, xmlNodePtr pptr, Z_SRW_diagnostic **recs,
                               int *num, void *client_data, const char *ns)
{
    if (o->direction == ODR_DECODE)
    {
        int i;
        xmlNodePtr ptr;
        *num = 0;
        for (ptr = pptr->children; ptr; ptr = ptr->next)
        {
            if (ptr->type == XML_ELEMENT_NODE &&
                !xmlStrcmp(ptr->name, BAD_CAST "diagnostic"))
                (*num)++;
        }
        if (!*num)
            return 1;
        *recs = (Z_SRW_diagnostic *) odr_malloc(o, *num * sizeof(**recs));
        for (i = 0; i < *num; i++)
        {
            (*recs)[i].uri = 0;
            (*recs)[i].details = 0;
            (*recs)[i].message = 0;
        } 
        for (i = 0, ptr = pptr->children; ptr; ptr = ptr->next)
        {
            if (ptr->type == XML_ELEMENT_NODE &&
                !xmlStrcmp(ptr->name, BAD_CAST "diagnostic"))
            {
                xmlNodePtr rptr;
                (*recs)[i].uri = 0;
                (*recs)[i].details = 0;
                (*recs)[i].message = 0;
                for (rptr = ptr->children; rptr; rptr = rptr->next)
                {
                    if (match_xsd_string(rptr, "uri", o, 
                                         &(*recs)[i].uri))
                        ;
                    else if (match_xsd_string(rptr, "details", o, 
                                              &(*recs)[i].details))
                        ;
                    else if (match_xsd_string(rptr, "message", o, 
                                              &(*recs)[i].message))
                        ;
                }
                i++;
            }
        }
    }
    else if (o->direction == ODR_ENCODE)
    {
        int i;
        xmlNsPtr ns_diag =
            xmlNewNs(pptr, BAD_CAST YAZ_XMLNS_DIAG_v1_1, BAD_CAST "diag" );
        for (i = 0; i < *num; i++)
        {
            const char *std_diag = "info:srw/diagnostic/1/";
            const char *ucp_diag = "info:srw/diagnostic/12/";
            xmlNodePtr rptr = xmlNewChild(pptr, ns_diag,
                                          BAD_CAST "diagnostic", 0);
            add_xsd_string(rptr, "uri", (*recs)[i].uri);
            if ((*recs)[i].message)
                add_xsd_string(rptr, "message", (*recs)[i].message);
            else if ((*recs)[i].uri )
            {
                if (!strncmp((*recs)[i].uri, std_diag, strlen(std_diag)))
                {
                    int no = atoi((*recs)[i].uri + strlen(std_diag));
                    const char *message = yaz_diag_srw_str(no);
                    if (message)
                        add_xsd_string(rptr, "message", message);
                }
                else if (!strncmp((*recs)[i].uri, ucp_diag, strlen(ucp_diag)))
                {
                    int no = atoi((*recs)[i].uri + strlen(ucp_diag));
                    const char *message = yaz_diag_sru_update_str(no);
                    if (message)
                        add_xsd_string(rptr, "message", message);
                }
            }
            add_xsd_string(rptr, "details", (*recs)[i].details);
        }
    }
    return 0;
}

static int yaz_srw_term(ODR o, xmlNodePtr pptr, Z_SRW_scanTerm *term,
                        void *client_data, const char *ns)
{
    if (o->direction == ODR_DECODE)
    {
        xmlNodePtr ptr;
        term->value = 0;
        term->numberOfRecords = 0;
        term->displayTerm = 0;
        term->whereInList = 0;
        for (ptr = pptr->children; ptr; ptr = ptr->next)
        {
            if (match_xsd_string(ptr, "value", o,  &term->value))
                ;
            else if (match_xsd_integer(ptr, "numberOfRecords", o, 
                                   &term->numberOfRecords))
                ;
            else if (match_xsd_string(ptr, "displayTerm", o, 
                                      &term->displayTerm))
                ;
            else if (match_xsd_string(ptr, "whereInList", o, 
                                      &term->whereInList))
                ;
        }
    }
    else if (o->direction == ODR_ENCODE)
    {
        xmlNodePtr ptr = pptr;
        add_xsd_string(ptr, "value", term->value);
        add_xsd_integer(ptr, "numberOfRecords", term->numberOfRecords);
        add_xsd_string(ptr, "displayTerm", term->displayTerm);
        add_xsd_string(ptr, "whereInList", term->whereInList);
    }
    return 0;
}

static int yaz_srw_terms(ODR o, xmlNodePtr pptr, Z_SRW_scanTerm **terms,
                         int *num, void *client_data, const char *ns)
{
    if (o->direction == ODR_DECODE)
    {
        int i;
        xmlNodePtr ptr;
        *num = 0;
        for (ptr = pptr->children; ptr; ptr = ptr->next)
        {
            if (ptr->type == XML_ELEMENT_NODE &&
                !xmlStrcmp(ptr->name, BAD_CAST "term"))
                (*num)++;
        }
        if (!*num)
            return 1;
        *terms = (Z_SRW_scanTerm *) odr_malloc(o, *num * sizeof(**terms));
        for (i = 0, ptr = pptr->children; ptr; ptr = ptr->next, i++)
        {
            if (ptr->type == XML_ELEMENT_NODE &&
                !xmlStrcmp(ptr->name, BAD_CAST "term"))
                yaz_srw_term(o, ptr, (*terms)+i, client_data, ns);
        }
    }
    else if (o->direction == ODR_ENCODE)
    {
        int i;
        for (i = 0; i < *num; i++)
        {
            xmlNodePtr rptr = xmlNewChild(pptr, 0, BAD_CAST "term", 0);
            yaz_srw_term(o, rptr, (*terms)+i, client_data, ns);
        }
    }
    return 0;
}

int yaz_srw_codec(ODR o, void * vptr, Z_SRW_PDU **handler_data,
                  void *client_data, const char *ns)
{
    xmlNodePtr pptr = (xmlNodePtr) vptr;
    if (o->direction == ODR_DECODE)
    {
        Z_SRW_PDU **p = handler_data;
        xmlNodePtr method = pptr->children;

        while (method && method->type == XML_TEXT_NODE)
            method = method->next;
        
        if (!method)
            return -1;
        if (method->type != XML_ELEMENT_NODE)
            return -1;

        *p = yaz_srw_get_core_v_1_1(o);
        
        if (!xmlStrcmp(method->name, BAD_CAST "searchRetrieveRequest"))
        {
            xmlNodePtr ptr = method->children;
            Z_SRW_searchRetrieveRequest *req;

            (*p)->which = Z_SRW_searchRetrieve_request;
            req = (*p)->u.request = (Z_SRW_searchRetrieveRequest *)
                odr_malloc(o, sizeof(*req));
            req->query_type = Z_SRW_query_type_cql;
            req->query.cql = 0;
            req->sort_type = Z_SRW_sort_type_none;
            req->sort.none = 0;
            req->startRecord = 0;
            req->maximumRecords = 0;
            req->recordSchema = 0;
            req->recordPacking = 0;
            req->recordXPath = 0;
            req->resultSetTTL = 0;
            req->stylesheet = 0;
            req->database = 0;

            for (; ptr; ptr = ptr->next)
            {
                if (match_xsd_string(ptr, "version", o,
                                     &(*p)->srw_version))
                    ;
                else if (match_xsd_string(ptr, "query", o, 
                                     &req->query.cql))
                    req->query_type = Z_SRW_query_type_cql;
                else if (match_xsd_string(ptr, "pQuery", o, 
                                     &req->query.pqf))
                    req->query_type = Z_SRW_query_type_pqf;
                else if (match_xsd_string(ptr, "xQuery", o, 
                                     &req->query.xcql))
                    req->query_type = Z_SRW_query_type_xcql;
                else if (match_xsd_integer(ptr, "startRecord", o,
                                           &req->startRecord))
                    ;
                else if (match_xsd_integer(ptr, "maximumRecords", o,
                                           &req->maximumRecords))
                    ;
                else if (match_xsd_string(ptr, "recordPacking", o,
                                          &req->recordPacking))
                    ;
                else if (match_xsd_string(ptr, "recordSchema", o, 
                                          &req->recordSchema))
                    ;
                else if (match_xsd_string(ptr, "recordXPath", o,
                                          &req->recordXPath))
                    ;
                else if (match_xsd_integer(ptr, "resultSetTTL", o,
                                           &req->resultSetTTL))
                    ;
                else if (match_xsd_string(ptr, "sortKeys", o, 
                                          &req->sort.sortKeys))
                    req->sort_type = Z_SRW_sort_type_sort;
                else if (match_xsd_string(ptr, "stylesheet", o,
                                           &req->stylesheet))
                    ;
                else if (match_xsd_string(ptr, "database", o,
                                           &req->database))
                    ;
            }
            if (!req->query.cql && !req->query.pqf && !req->query.xcql)
            {
                /* should put proper diagnostic here */
                return -1;
            }
        }
        else if (!xmlStrcmp(method->name, BAD_CAST "searchRetrieveResponse"))
        {
            xmlNodePtr ptr = method->children;
            Z_SRW_searchRetrieveResponse *res;

            (*p)->which = Z_SRW_searchRetrieve_response;
            res = (*p)->u.response = (Z_SRW_searchRetrieveResponse *)
                odr_malloc(o, sizeof(*res));

            res->numberOfRecords = 0;
            res->resultSetId = 0;
            res->resultSetIdleTime = 0;
            res->records = 0;
            res->num_records = 0;
            res->diagnostics = 0;
            res->num_diagnostics = 0;
            res->nextRecordPosition = 0;

            for (; ptr; ptr = ptr->next)
            {
                if (match_xsd_string(ptr, "version", o,
                                     &(*p)->srw_version))
                    ;
                else if (match_xsd_integer(ptr, "numberOfRecords", o, 
                                      &res->numberOfRecords))
                    ;
                else if (match_xsd_string(ptr, "resultSetId", o, 
                                          &res->resultSetId))
                    ;
                else if (match_xsd_integer(ptr, "resultSetIdleTime", o, 
                                           &res->resultSetIdleTime))
                    ;
                else if (match_element(ptr, "records"))
                    yaz_srw_records(o, ptr, &res->records,
                                    &res->extra_records,
                                    &res->num_records, client_data, ns);
                else if (match_xsd_integer(ptr, "nextRecordPosition", o,
                                           &res->nextRecordPosition))
                    ;
                else if (match_element(ptr, "diagnostics"))
                    yaz_srw_diagnostics(o, ptr, &res->diagnostics,
                                        &res->num_diagnostics,
                                        client_data, ns);
            }
        }
        else if (!xmlStrcmp(method->name, BAD_CAST "explainRequest"))
        {
            Z_SRW_explainRequest *req;
            xmlNodePtr ptr = method->children;
            
            (*p)->which = Z_SRW_explain_request;
            req = (*p)->u.explain_request = (Z_SRW_explainRequest *)
                odr_malloc(o, sizeof(*req));
            req->recordPacking = 0;
            req->database = 0;
            req->stylesheet = 0;
            for (; ptr; ptr = ptr->next)
            {
                if (match_xsd_string(ptr, "version", o,
                                           &(*p)->srw_version))
                    ;
                else if (match_xsd_string(ptr, "stylesheet", o,
                                          &req->stylesheet))
                    ;
                else if (match_xsd_string(ptr, "recordPacking", o,
                                     &req->recordPacking))
                    ;
                else if (match_xsd_string(ptr, "database", o,
                                     &req->database))
                    ;
            }
        }
        else if (!xmlStrcmp(method->name, BAD_CAST "explainResponse"))
        {
            Z_SRW_explainResponse *res;
            xmlNodePtr ptr = method->children;

            (*p)->which = Z_SRW_explain_response;
            res = (*p)->u.explain_response = (Z_SRW_explainResponse*)
                odr_malloc(o, sizeof(*res));
            res->diagnostics = 0;
            res->num_diagnostics = 0;
            res->record.recordSchema = 0;
            res->record.recordData_buf = 0;
            res->record.recordData_len = 0;
            res->record.recordPosition = 0;

            for (; ptr; ptr = ptr->next)
            {
                if (match_xsd_string(ptr, "version", o,
                                           &(*p)->srw_version))
                    ;
                else if (match_element(ptr, "record"))
                    yaz_srw_record(o, ptr, &res->record, &res->extra_record,
                                   client_data, ns);
                else if (match_element(ptr, "diagnostics"))
                    yaz_srw_diagnostics(o, ptr, &res->diagnostics,
                                        &res->num_diagnostics,
                                        client_data, ns);
                ;
            }
        }
        else if (!xmlStrcmp(method->name, BAD_CAST "scanRequest"))
        {
            Z_SRW_scanRequest *req;
            xmlNodePtr ptr = method->children;

            (*p)->which = Z_SRW_scan_request;
            req = (*p)->u.scan_request = (Z_SRW_scanRequest *)
                odr_malloc(o, sizeof(*req));
            req->query_type = Z_SRW_query_type_cql;
            req->scanClause.cql = 0;
            req->responsePosition = 0;
            req->maximumTerms = 0;
            req->stylesheet = 0;
            req->database = 0;
            
            for (; ptr; ptr = ptr->next)
            {
                if (match_xsd_string(ptr, "version", o,
                                     &(*p)->srw_version))
                    ;
                else if (match_xsd_string(ptr, "scanClause", o,
                                     &req->scanClause.cql))
                    ;
                else if (match_xsd_string(ptr, "pScanClause", o,
                                          &req->scanClause.pqf))
                {
                    req->query_type = Z_SRW_query_type_pqf;
                }
                else if (match_xsd_integer(ptr, "responsePosition", o,
                                           &req->responsePosition))
                    ;
                else if (match_xsd_integer(ptr, "maximumTerms", o,
                                           &req->maximumTerms))
                    ;
                else if (match_xsd_string(ptr, "stylesheet", o,
                                          &req->stylesheet))
                    ;
                else if (match_xsd_string(ptr, "database", o,
                                          &req->database))
                    ;
            }
        }
        else if (!xmlStrcmp(method->name, BAD_CAST "scanResponse"))
        {
            Z_SRW_scanResponse *res;
            xmlNodePtr ptr = method->children;

            (*p)->which = Z_SRW_scan_response;
            res = (*p)->u.scan_response = (Z_SRW_scanResponse *)
                odr_malloc(o, sizeof(*res));
            res->terms = 0;
            res->num_terms = 0;
            res->diagnostics = 0;
            res->num_diagnostics = 0;
            
            for (; ptr; ptr = ptr->next)
            {
                if (match_xsd_string(ptr, "version", o,
                                     &(*p)->srw_version))
                    ;
                else if (match_element(ptr, "terms"))
                    yaz_srw_terms(o, ptr, &res->terms,
                                  &res->num_terms, client_data,
                                  ns);
                else if (match_element(ptr, "diagnostics"))
                    yaz_srw_diagnostics(o, ptr, &res->diagnostics,
                                        &res->num_diagnostics,
                                        client_data, ns);
            }
        }
        else
        {
            *p = 0;
            return -1;
        }
    }
    else if (o->direction == ODR_ENCODE)
    {
        Z_SRW_PDU **p = handler_data;
        xmlNsPtr ns_srw;
        
        if ((*p)->which == Z_SRW_searchRetrieve_request)
        {
            Z_SRW_searchRetrieveRequest *req = (*p)->u.request;
            xmlNodePtr ptr = xmlNewChild(pptr, 0,
                                         BAD_CAST "searchRetrieveRequest", 0);
            ns_srw = xmlNewNs(ptr, BAD_CAST ns, BAD_CAST "zs");
            xmlSetNs(ptr, ns_srw);

            if ((*p)->srw_version)
                add_xsd_string(ptr, "version", (*p)->srw_version);
            switch(req->query_type)
            {
            case Z_SRW_query_type_cql:
                add_xsd_string(ptr, "query", req->query.cql);
                break;
            case Z_SRW_query_type_xcql:
                add_xsd_string(ptr, "xQuery", req->query.xcql);
                break;
            case Z_SRW_query_type_pqf:
                add_xsd_string(ptr, "pQuery", req->query.pqf);
                break;
            }
            add_xsd_integer(ptr, "startRecord", req->startRecord);
            add_xsd_integer(ptr, "maximumRecords", req->maximumRecords);
            add_xsd_string(ptr, "recordPacking", req->recordPacking);
            add_xsd_string(ptr, "recordSchema", req->recordSchema);
            add_xsd_string(ptr, "recordXPath", req->recordXPath);
            add_xsd_integer(ptr, "resultSetTTL", req->resultSetTTL);
            switch(req->sort_type)
            {
            case Z_SRW_sort_type_none:
                break;
            case Z_SRW_sort_type_sort:
                add_xsd_string(ptr, "sortKeys", req->sort.sortKeys);
                break;
            case Z_SRW_sort_type_xSort:
                add_xsd_string(ptr, "xSortKeys", req->sort.xSortKeys);
                break;
            }
            add_xsd_string(ptr, "stylesheet", req->stylesheet);
            add_xsd_string(ptr, "database", req->database);
        }
        else if ((*p)->which == Z_SRW_searchRetrieve_response)
        {
            Z_SRW_searchRetrieveResponse *res = (*p)->u.response;
            xmlNodePtr ptr = xmlNewChild(pptr, 0,
                                         BAD_CAST "searchRetrieveResponse", 0);
            ns_srw = xmlNewNs(ptr, BAD_CAST ns, BAD_CAST "zs");
            xmlSetNs(ptr, ns_srw);

            if ((*p)->srw_version)
                add_xsd_string(ptr, "version", (*p)->srw_version);
            add_xsd_integer(ptr, "numberOfRecords", res->numberOfRecords);
            add_xsd_string(ptr, "resultSetId", res->resultSetId);
            add_xsd_integer(ptr, "resultSetIdleTime", res->resultSetIdleTime);
            if (res->num_records)
            {
                xmlNodePtr rptr = xmlNewChild(ptr, 0, BAD_CAST "records", 0);
                yaz_srw_records(o, rptr, &res->records, &res->extra_records,
                                &res->num_records,
                                client_data, ns);
            }
            add_xsd_integer(ptr, "nextRecordPosition",
                            res->nextRecordPosition);
            if (res->num_diagnostics)
            {
                xmlNodePtr rptr = xmlNewChild(ptr, 0, BAD_CAST "diagnostics",
                                              0);
                yaz_srw_diagnostics(o, rptr, &res->diagnostics,
                                    &res->num_diagnostics, client_data, ns);
            }
        }
        else if ((*p)->which == Z_SRW_explain_request)
        {
            Z_SRW_explainRequest *req = (*p)->u.explain_request;
            xmlNodePtr ptr = xmlNewChild(pptr, 0, BAD_CAST "explainRequest",
                                         0);
            ns_srw = xmlNewNs(ptr, BAD_CAST ns, BAD_CAST "zs");
            xmlSetNs(ptr, ns_srw);

            add_xsd_string(ptr, "version", (*p)->srw_version);
            add_xsd_string(ptr, "recordPacking", req->recordPacking);
            add_xsd_string(ptr, "stylesheet", req->stylesheet);
            add_xsd_string(ptr, "database", req->database);
        }
        else if ((*p)->which == Z_SRW_explain_response)
        {
            Z_SRW_explainResponse *res = (*p)->u.explain_response;
            xmlNodePtr ptr = xmlNewChild(pptr, 0, BAD_CAST "explainResponse",
                                         0);
            ns_srw = xmlNewNs(ptr, BAD_CAST ns, BAD_CAST "zs");
            xmlSetNs(ptr, ns_srw);

            add_xsd_string(ptr, "version", (*p)->srw_version);
            if (1)
            {
                xmlNodePtr ptr1 = xmlNewChild(ptr, 0, BAD_CAST "record", 0);
                yaz_srw_record(o, ptr1, &res->record, &res->extra_record,
                               client_data, ns);
            }
            if (res->num_diagnostics)
            {
                xmlNodePtr rptr = xmlNewChild(ptr, 0, BAD_CAST "diagnostics",
                                              0);
                yaz_srw_diagnostics(o, rptr, &res->diagnostics,
                                    &res->num_diagnostics, client_data, ns);
            }
        }
        else if ((*p)->which == Z_SRW_scan_request)
        {
            Z_SRW_scanRequest *req = (*p)->u.scan_request;
            xmlNodePtr ptr = xmlNewChild(pptr, 0, BAD_CAST "scanRequest", 0);
            ns_srw = xmlNewNs(ptr, BAD_CAST ns, BAD_CAST "zs");
            xmlSetNs(ptr, ns_srw);

            add_xsd_string(ptr, "version", (*p)->srw_version);
            switch(req->query_type)
            {
            case Z_SRW_query_type_cql:
                add_xsd_string(ptr, "scanClause", req->scanClause.cql);
                break;
            case Z_SRW_query_type_pqf:
                add_xsd_string(ptr, "pScanClause", req->scanClause.pqf);
                break;
            }
            add_xsd_integer(ptr, "responsePosition", req->responsePosition);
            add_xsd_integer(ptr, "maximumTerms", req->maximumTerms);
            add_xsd_string(ptr, "stylesheet", req->stylesheet);
            add_xsd_string(ptr, "database", req->database);
        }
        else if ((*p)->which == Z_SRW_scan_response)
        {
            Z_SRW_scanResponse *res = (*p)->u.scan_response;
            xmlNodePtr ptr = xmlNewChild(pptr, 0, BAD_CAST "scanResponse", 0);
            ns_srw = xmlNewNs(ptr, BAD_CAST ns, BAD_CAST "zs");
            xmlSetNs(ptr, ns_srw);

            add_xsd_string(ptr, "version", (*p)->srw_version);

            if (res->num_terms)
            {
                xmlNodePtr rptr = xmlNewChild(ptr, 0, BAD_CAST "terms", 0);
                yaz_srw_terms(o, rptr, &res->terms, &res->num_terms,
                              client_data, ns);
            }
            if (res->num_diagnostics)
            {
                xmlNodePtr rptr = xmlNewChild(ptr, 0, BAD_CAST "diagnostics",
                                              0);
                yaz_srw_diagnostics(o, rptr, &res->diagnostics,
                                    &res->num_diagnostics, client_data, ns);
            }
        }
        else
            return -1;

    }
    return 0;
}

int yaz_ucp_codec(ODR o, void * vptr, Z_SRW_PDU **handler_data,
                  void *client_data, const char *ns_ucp_str)
{
    xmlNodePtr pptr = (xmlNodePtr) vptr;
    const char *ns_srw_str = YAZ_XMLNS_SRU_v1_1;
    if (o->direction == ODR_DECODE)
    {
        Z_SRW_PDU **p = handler_data;
        xmlNodePtr method = pptr->children;

        while (method && method->type == XML_TEXT_NODE)
            method = method->next;
        
        if (!method)
            return -1;
        if (method->type != XML_ELEMENT_NODE)
            return -1;

        *p = yaz_srw_get_core_v_1_1(o);
        
        if (!xmlStrcmp(method->name, BAD_CAST "updateRequest"))
        {
            xmlNodePtr ptr = method->children;
            Z_SRW_updateRequest *req;
            char *oper = 0;

            (*p)->which = Z_SRW_update_request;
            req = (*p)->u.update_request = (Z_SRW_updateRequest *)
                odr_malloc(o, sizeof(*req));
            req->database = 0;
            req->operation = 0;
            req->recordId = 0;
            req->recordVersions = 0;
            req->num_recordVersions = 0;
            req->record = 0;
            req->extra_record = 0;
            req->extraRequestData_buf = 0;
            req->extraRequestData_len = 0;
            req->stylesheet = 0;

            for (; ptr; ptr = ptr->next)
            {
                if (match_xsd_string(ptr, "version", o,
                                     &(*p)->srw_version))
                    ;
                else if (match_xsd_string(ptr, "action", o, 
                                          &oper)){
                    if ( oper ){
                        if ( !strcmp(oper, "info:srw/action/1/delete"))
                            req->operation = "delete";
                        else if (!strcmp(oper,"info:srw/action/1/replace" ))
                            req->operation = "replace";
                        else if ( !strcmp( oper, "info:srw/action/1/create"))
                            req->operation = "insert";
                    }
                }
                else if (match_xsd_string(ptr, "recordIdentifier", o,
                                          &req->recordId))
                    ;
                else if (match_element(ptr, "recordVersions" ) )
                    yaz_srw_versions( o, ptr, &req->recordVersions,
                                      &req->num_recordVersions, client_data,
                                      ns_ucp_str);
                else if (match_element(ptr, "record"))
                {
                    req->record = yaz_srw_get_record(o);
                    yaz_srw_record(o, ptr, req->record, &req->extra_record,
                                   client_data, ns_ucp_str);
                }
                else if (match_xsd_string(ptr, "stylesheet", o,
                                           &req->stylesheet))
                    ;
                else if (match_xsd_string(ptr, "database", o,
                                           &req->database))
                    ;
            }
        }
        else if (!xmlStrcmp(method->name, BAD_CAST "updateResponse"))
        {
            xmlNodePtr ptr = method->children;
            Z_SRW_updateResponse *res;

            (*p)->which = Z_SRW_update_response;
            res = (*p)->u.update_response = (Z_SRW_updateResponse *)
                odr_malloc(o, sizeof(*res));

            res->operationStatus = 0;
            res->recordId = 0;
            res->recordVersions = 0;
            res->num_recordVersions = 0;
            res->diagnostics = 0;
            res->num_diagnostics = 0;
            res->record = 0;
            res->extra_record = 0;
            res->extraResponseData_buf = 0;
            res->extraResponseData_len = 0;

            for (; ptr; ptr = ptr->next)
            {
                if (match_xsd_string(ptr, "version", o,
                                     &(*p)->srw_version))
                    ;
                else if (match_xsd_string(ptr, "operationStatus", o, 
                                      &res->operationStatus ))
                    ;
                else if (match_xsd_string(ptr, "recordIdentifier", o, 
                                          &res->recordId))
                    ;
                else if (match_element(ptr, "recordVersions" )) 
                    yaz_srw_versions(o, ptr, &res->recordVersions,
                                     &res->num_recordVersions,
                                     client_data, ns_ucp_str);
                else if (match_element(ptr, "record"))
                {
                    res->record = yaz_srw_get_record(o);
                    yaz_srw_record(o, ptr, res->record, &res->extra_record,
                                   client_data, ns_ucp_str);
                }
                else if (match_element(ptr, "diagnostics"))
                    yaz_srw_diagnostics(o, ptr, &res->diagnostics,
                                        &res->num_diagnostics,
                                        client_data, ns_ucp_str);
            }
        }
        else if (!xmlStrcmp(method->name, BAD_CAST "explainUpdateRequest"))
        {
        }
        else if (!xmlStrcmp(method->name, BAD_CAST "explainUpdateResponse"))
        {
        }
        else
        {
            *p = 0;
            return -1;
        }
    }
    else if (o->direction == ODR_ENCODE)
    {
        Z_SRW_PDU **p = handler_data;
        xmlNsPtr ns_ucp, ns_srw;


        if ((*p)->which == Z_SRW_update_request)
        {
            Z_SRW_updateRequest *req = (*p)->u.update_request;
            xmlNodePtr ptr = xmlNewChild(pptr, 0, BAD_CAST "updateRequest", 0);
	    ns_ucp = xmlNewNs(ptr, BAD_CAST ns_ucp_str, BAD_CAST "zu");
	    xmlSetNs(ptr, ns_ucp);
            ns_srw = xmlNewNs(ptr, BAD_CAST ns_srw_str, BAD_CAST "zs");

	    add_xsd_string_ns(ptr, "version", (*p)->srw_version, ns_srw);
	    add_xsd_string(ptr, "action", req->operation);
            add_xsd_string(ptr, "recordIdentifier", req->recordId );
	    if (req->recordVersions)
                yaz_srw_versions( o, ptr, &req->recordVersions,
                                  &req->num_recordVersions,
                                  client_data, ns_ucp_str);
	    if (req->record && req->record->recordData_len)
            {
                xmlNodePtr rptr = xmlNewChild(ptr, 0, BAD_CAST "record", 0);
                xmlSetNs(rptr, ns_srw);
                yaz_srw_record(o, rptr, req->record, &req->extra_record,
                               client_data, ns_ucp_str);
	    }
	    if (req->extraRequestData_len)
            {
                add_XML_n(ptr, "extraRequestData", 
                          req->extraRequestData_buf, 
                          req->extraRequestData_len, ns_srw);
            }
	    add_xsd_string(ptr, "stylesheet", req->stylesheet);
            add_xsd_string(ptr, "database", req->database);
        }
        else if ((*p)->which == Z_SRW_update_response)
        {
            Z_SRW_updateResponse *res = (*p)->u.update_response;
            xmlNodePtr ptr = xmlNewChild(pptr, 0, (xmlChar *) 
                                         "updateResponse", 0);
	    ns_ucp = xmlNewNs(ptr, BAD_CAST ns_ucp_str, BAD_CAST "zu");
	    xmlSetNs(ptr, ns_ucp);
            ns_srw = xmlNewNs(ptr, BAD_CAST ns_srw_str, BAD_CAST "zs");
            
	    add_xsd_string_ns(ptr, "version", (*p)->srw_version, ns_srw);
            add_xsd_string(ptr, "operationStatus", res->operationStatus );
            add_xsd_string(ptr, "recordIdentifier", res->recordId );
	    if (res->recordVersions)
                yaz_srw_versions(o, ptr, &res->recordVersions,
                                 &res->num_recordVersions,
                                 client_data, ns_ucp_str);
	    if (res->record && res->record->recordData_len)
            {
                xmlNodePtr rptr = xmlNewChild(ptr, 0, BAD_CAST "record", 0);
                xmlSetNs(rptr, ns_srw);
                yaz_srw_record(o, rptr, res->record, &res->extra_record,
                               client_data, ns_ucp_str);
	    }
	    if (res->num_diagnostics)
	    {
                xmlNsPtr ns_diag =
                    xmlNewNs(pptr, BAD_CAST YAZ_XMLNS_DIAG_v1_1,
                             BAD_CAST "diag" );
                
		xmlNodePtr rptr = xmlNewChild(ptr, ns_diag, BAD_CAST "diagnostics", 0);
		yaz_srw_diagnostics(o, rptr, &res->diagnostics,
                                    &res->num_diagnostics, client_data,
                                    ns_ucp_str);
            }
	    if (res->extraResponseData_len)
                add_XML_n(ptr, "extraResponseData", 
                          res->extraResponseData_buf, 
                          res->extraResponseData_len, ns_srw);
        }
        else
            return -1;

    }
    return 0;
}

#endif


/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

