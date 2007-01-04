/*
 * Copyright (C) 1995-2005, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: ztest.c,v 1.83 2006/12/06 21:35:59 adam Exp $
 */

/*
 * Demonstration of simple server
 */

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#if HAVE_UNISTD_H
#include <unistd.h>
#endif

#include <yaz/yaz-util.h>
#include <yaz/backend.h>
#include <yaz/ill.h>

static int log_level=0;
static int log_level_set=0;

Z_GenericRecord *dummy_grs_record (int num, ODR o);
char *dummy_marc_record (int num, ODR odr);
char *dummy_xml_record (int num, ODR odr);

int ztest_search(void *handle, bend_search_rr *rr);
int ztest_sort(void *handle, bend_sort_rr *rr);
int ztest_present(void *handle, bend_present_rr *rr);
int ztest_esrequest(void *handle, bend_esrequest_rr *rr);
int ztest_delete(void *handle, bend_delete_rr *rr);

int ztest_search(void *handle, bend_search_rr *rr)
{
    if (rr->num_bases != 1)
    {
        rr->errcode = 23;
        return 0;
    }
#if NMEM_DEBUG
    /* if database is stop, stop this process.. For debugging only. */
    if (!yaz_matchstr (rr->basenames[0], "stop"))
    {
        nmem_print_list_l(YLOG_LOG);
        exit(0);
    }
#endif
    /* Throw Database unavailable if other than Default or Slow */
    if (!yaz_matchstr (rr->basenames[0], "Default"))
        ;  /* Default is OK in our test */
    else if(!yaz_matchstr (rr->basenames[0], "Slow"))
    {
#if HAVE_UNISTD_H
        /* wait up to 3 seconds and check if connection is still alive */
        int i;
        for (i = 0; i<3; i++)
        {
            if (!bend_assoc_is_alive(rr->association))
            {
                yaz_log(YLOG_LOG, "search aborted");
                break;
            }
            sleep(1);
        }
#endif
        ;
    }
    else
    {
        rr->errcode = 109;
        rr->errstring = rr->basenames[0];
        return 0;
    }
    rr->hits = rand() % 24;
    return 0;
}


/* this huge function handles extended services */
int ztest_esrequest (void *handle, bend_esrequest_rr *rr)
{
    /* user-defined handle - created in bend_init */
    int *counter = (int*) handle;  

    yaz_log(log_level, "ESRequest no %d", *counter);

    (*counter)++;

    if (rr->esr->packageName)
        yaz_log(log_level, "packagename: %s", rr->esr->packageName);
    yaz_log(log_level, "Waitaction: %d", *rr->esr->waitAction);


    yaz_log(log_level, "function: %d", *rr->esr->function);

    if (!rr->esr->taskSpecificParameters)
    {
        yaz_log (log_level, "No task specific parameters");
    }
    else if (rr->esr->taskSpecificParameters->which == Z_External_itemOrder)
    {
        Z_ItemOrder *it = rr->esr->taskSpecificParameters->u.itemOrder;
        yaz_log (log_level, "Received ItemOrder");
        if (it->which == Z_IOItemOrder_esRequest)
        {
            Z_IORequest *ir = it->u.esRequest;
            Z_IOOriginPartToKeep *k = ir->toKeep;
            Z_IOOriginPartNotToKeep *n = ir->notToKeep;
            
            if (k && k->contact)
            {
                if (k->contact->name)
                    yaz_log(log_level, "contact name %s", k->contact->name);
                if (k->contact->phone)
                    yaz_log(log_level, "contact phone %s", k->contact->phone);
                if (k->contact->email)
                    yaz_log(log_level, "contact email %s", k->contact->email);
            }
            if (k->addlBilling)
            {
                yaz_log(log_level, "Billing info (not shown)");
            }
            
            if (n->resultSetItem)
            {
                yaz_log(log_level, "resultsetItem");
                yaz_log(log_level, "setId: %s", n->resultSetItem->resultSetId);
                yaz_log(log_level, "item: %d", *n->resultSetItem->item);
            }
            if (n->itemRequest)
            {
                Z_External *r = (Z_External*) n->itemRequest;
                ILL_ItemRequest *item_req = 0;
                ILL_APDU *ill_apdu = 0;
                if (r->direct_reference)
                {
                    oident *ent = oid_getentbyoid(r->direct_reference);
                    if (ent)
                        yaz_log(log_level, "OID %s", ent->desc);
                    if (ent && ent->value == VAL_TEXT_XML)
                    {
                        yaz_log (log_level, "ILL XML request");
                        if (r->which == Z_External_octet)
                            yaz_log (log_level, "%.*s", r->u.octet_aligned->len,
                                     r->u.octet_aligned->buf); 
                    }
                    if (ent && ent->value == VAL_ISO_ILL_1)
                    {
                        yaz_log (log_level, "Decode ItemRequest begin");
                        if (r->which == ODR_EXTERNAL_single)
                        {
                            odr_setbuf(rr->decode,
                                       (char *) r->u.single_ASN1_type->buf,
                                       r->u.single_ASN1_type->len, 0);
                            
                            if (!ill_ItemRequest (rr->decode, &item_req, 0, 0))
                            {
                                yaz_log (log_level,
                                    "Couldn't decode ItemRequest %s near %ld",
                                       odr_errmsg(odr_geterror(rr->decode)),
                                       (long) odr_offset(rr->decode));
                            }
                            else
                                yaz_log(log_level, "Decode ItemRequest OK");
                            if (rr->print)
                            {
                                ill_ItemRequest (rr->print, &item_req, 0,
                                    "ItemRequest");
                                odr_reset (rr->print);
                            }
                        }
                        if (!item_req && r->which == ODR_EXTERNAL_single)
                        {
                            yaz_log (log_level, "Decode ILL APDU begin");
                            odr_setbuf(rr->decode,
                                       (char*) r->u.single_ASN1_type->buf,
                                       r->u.single_ASN1_type->len, 0);
                            
                            if (!ill_APDU (rr->decode, &ill_apdu, 0, 0))
                            {
                                yaz_log (log_level,
                                    "Couldn't decode ILL APDU %s near %ld",
                                       odr_errmsg(odr_geterror(rr->decode)),
                                       (long) odr_offset(rr->decode));
                                yaz_log(log_level, "PDU dump:");
                                odr_dumpBER(yaz_log_file(),
                                     (char *) r->u.single_ASN1_type->buf,
                                     r->u.single_ASN1_type->len);
                            }
                            else
                                yaz_log(log_level, "Decode ILL APDU OK");
                            if (rr->print)
                            {
                                ill_APDU (rr->print, &ill_apdu, 0,
                                    "ILL APDU");
                                odr_reset (rr->print);
                            }
                        }
                    }
                }
                if (item_req)
                {
                    yaz_log (log_level, "ILL protocol version = %d",
                             *item_req->protocol_version_num);
                }
            }
            if (k)
            {

                Z_External *ext = (Z_External *)
                    odr_malloc (rr->stream, sizeof(*ext));
                Z_IUOriginPartToKeep *keep = (Z_IUOriginPartToKeep *)
                    odr_malloc (rr->stream, sizeof(*keep));
                Z_IOTargetPart *targetPart = (Z_IOTargetPart *)
                    odr_malloc (rr->stream, sizeof(*targetPart));

                rr->taskPackage = (Z_TaskPackage *)
                    odr_malloc (rr->stream, sizeof(*rr->taskPackage));
                rr->taskPackage->packageType =
                    odr_oiddup (rr->stream, rr->esr->packageType);
                rr->taskPackage->packageName = 0;
                rr->taskPackage->userId = 0;
                rr->taskPackage->retentionTime = 0;
                rr->taskPackage->permissions = 0;
                rr->taskPackage->description = 0;
                rr->taskPackage->targetReference = (Odr_oct *)
                    odr_malloc (rr->stream, sizeof(Odr_oct));
                rr->taskPackage->targetReference->buf =
                    (unsigned char *) odr_strdup (rr->stream, "911");
                rr->taskPackage->targetReference->len =
                    rr->taskPackage->targetReference->size =
                    strlen((char *) (rr->taskPackage->targetReference->buf));
                rr->taskPackage->creationDateTime = 0;
                rr->taskPackage->taskStatus = odr_intdup(rr->stream, 0);
                rr->taskPackage->packageDiagnostics = 0;
                rr->taskPackage->taskSpecificParameters = ext;

                ext->direct_reference =
                    odr_oiddup (rr->stream, rr->esr->packageType);
                ext->indirect_reference = 0;
                ext->descriptor = 0;
                ext->which = Z_External_itemOrder;
                ext->u.itemOrder = (Z_ItemOrder *)
                    odr_malloc (rr->stream, sizeof(*ext->u.update));
                ext->u.itemOrder->which = Z_IOItemOrder_taskPackage;
                ext->u.itemOrder->u.taskPackage =  (Z_IOTaskPackage *)
                    odr_malloc (rr->stream, sizeof(Z_IOTaskPackage));
                ext->u.itemOrder->u.taskPackage->originPart = k;
                ext->u.itemOrder->u.taskPackage->targetPart = targetPart;

                targetPart->itemRequest = 0;
                targetPart->statusOrErrorReport = 0;
                targetPart->auxiliaryStatus = 0;
            }
        }
    }
    else if (rr->esr->taskSpecificParameters->which == Z_External_update)
    {
        Z_IUUpdate *up = rr->esr->taskSpecificParameters->u.update;
        yaz_log (log_level, "Received DB Update");
        if (up->which == Z_IUUpdate_esRequest)
        {
            Z_IUUpdateEsRequest *esRequest = up->u.esRequest;
            Z_IUOriginPartToKeep *toKeep = esRequest->toKeep;
            Z_IUSuppliedRecords *notToKeep = esRequest->notToKeep;
            
            yaz_log (log_level, "action");
            if (toKeep->action)
            {
                switch (*toKeep->action)
                {
                case Z_IUOriginPartToKeep_recordInsert:
                    yaz_log (log_level, " recordInsert");
                    break;
                case Z_IUOriginPartToKeep_recordReplace:
                    yaz_log (log_level, " recordReplace");
                    break;
                case Z_IUOriginPartToKeep_recordDelete:
                    yaz_log (log_level, " recordDelete");
                    break;
                case Z_IUOriginPartToKeep_elementUpdate:
                    yaz_log (log_level, " elementUpdate");
                    break;
                case Z_IUOriginPartToKeep_specialUpdate:
                    yaz_log (log_level, " specialUpdate");
                    break;
                default:
                    yaz_log (log_level, " unknown (%d)", *toKeep->action);
                }
            }
            if (toKeep->databaseName)
            {
                yaz_log (log_level, "database: %s", toKeep->databaseName);
                if (!strcmp(toKeep->databaseName, "fault"))
                {
                    rr->errcode = 109;
                    rr->errstring = toKeep->databaseName;
                }
                if (!strcmp(toKeep->databaseName, "accept"))
                    rr->errcode = -1;
            }
            if (toKeep)
            {
                Z_External *ext = (Z_External *)
                    odr_malloc (rr->stream, sizeof(*ext));
                Z_IUOriginPartToKeep *keep = (Z_IUOriginPartToKeep *)
                    odr_malloc (rr->stream, sizeof(*keep));
                Z_IUTargetPart *targetPart = (Z_IUTargetPart *)
                    odr_malloc (rr->stream, sizeof(*targetPart));

                rr->taskPackage = (Z_TaskPackage *)
                    odr_malloc (rr->stream, sizeof(*rr->taskPackage));
                rr->taskPackage->packageType =
                    odr_oiddup (rr->stream, rr->esr->packageType);
                rr->taskPackage->packageName = 0;
                rr->taskPackage->userId = 0;
                rr->taskPackage->retentionTime = 0;
                rr->taskPackage->permissions = 0;
                rr->taskPackage->description = 0;
                rr->taskPackage->targetReference = (Odr_oct *)
                    odr_malloc (rr->stream, sizeof(Odr_oct));
                rr->taskPackage->targetReference->buf =
                    (unsigned char *) odr_strdup (rr->stream, "123");
                rr->taskPackage->targetReference->len =
                    rr->taskPackage->targetReference->size =
                    strlen((char *) (rr->taskPackage->targetReference->buf));
                rr->taskPackage->creationDateTime = 0;
                rr->taskPackage->taskStatus = odr_intdup(rr->stream, 0);
                rr->taskPackage->packageDiagnostics = 0;
                rr->taskPackage->taskSpecificParameters = ext;

                ext->direct_reference =
                    odr_oiddup (rr->stream, rr->esr->packageType);
                ext->indirect_reference = 0;
                ext->descriptor = 0;
                ext->which = Z_External_update;
                ext->u.update = (Z_IUUpdate *)
                    odr_malloc (rr->stream, sizeof(*ext->u.update));
                ext->u.update->which = Z_IUUpdate_taskPackage;
                ext->u.update->u.taskPackage =  (Z_IUUpdateTaskPackage *)
                    odr_malloc (rr->stream, sizeof(Z_IUUpdateTaskPackage));
                ext->u.update->u.taskPackage->originPart = keep;
                ext->u.update->u.taskPackage->targetPart = targetPart;

                keep->action = (int *) odr_malloc (rr->stream, sizeof(int));
                *keep->action = *toKeep->action;
                keep->databaseName =
                    odr_strdup (rr->stream, toKeep->databaseName);
                keep->schema = 0;
                keep->elementSetName = 0;
                keep->actionQualifier = 0;

                targetPart->updateStatus = odr_intdup (rr->stream, 1);
                targetPart->num_globalDiagnostics = 0;
                targetPart->globalDiagnostics = (Z_DiagRec **) odr_nullval();
                targetPart->num_taskPackageRecords = 1;
                targetPart->taskPackageRecords = 
                    (Z_IUTaskPackageRecordStructure **)
                    odr_malloc (rr->stream,
                                sizeof(Z_IUTaskPackageRecordStructure *));
                targetPart->taskPackageRecords[0] =
                    (Z_IUTaskPackageRecordStructure *)
                    odr_malloc (rr->stream,
                                sizeof(Z_IUTaskPackageRecordStructure));
                
                targetPart->taskPackageRecords[0]->which =
                    Z_IUTaskPackageRecordStructure_record;
                targetPart->taskPackageRecords[0]->u.record = 
                    z_ext_record (rr->stream, VAL_SUTRS, "test", 4);
                targetPart->taskPackageRecords[0]->correlationInfo = 0; 
                targetPart->taskPackageRecords[0]->recordStatus =
                    odr_intdup (rr->stream,
                                Z_IUTaskPackageRecordStructure_success);  
                targetPart->taskPackageRecords[0]->num_supplementalDiagnostics
                    = 0;

                targetPart->taskPackageRecords[0]->supplementalDiagnostics = 0;
            }
            if (notToKeep)
            {
                int i;
                for (i = 0; i < notToKeep->num; i++)
                {
                    Z_External *rec = notToKeep->elements[i]->record;

                    if (rec->direct_reference)
                    {
                        struct oident *oident;
                        oident = oid_getentbyoid(rec->direct_reference);
                        if (oident)
                            yaz_log (log_level, "record %d type %s", i,
                                     oident->desc);
                    }
                    switch (rec->which)
                    {
                    case Z_External_sutrs:
                        if (rec->u.octet_aligned->len > 170)
                            yaz_log (log_level, "%d bytes:\n%.168s ...",
                                     rec->u.sutrs->len,
                                     rec->u.sutrs->buf);
                        else
                            yaz_log (log_level, "%d bytes:\n%s",
                                     rec->u.sutrs->len,
                                     rec->u.sutrs->buf);
                        break;
                    case Z_External_octet        :
                        if (rec->u.octet_aligned->len > 170)
                            yaz_log (log_level, "%d bytes:\n%.168s ...",
                                     rec->u.octet_aligned->len,
                                     rec->u.octet_aligned->buf);
                        else
                            yaz_log (log_level, "%d bytes\n%s",
                                     rec->u.octet_aligned->len,
                                     rec->u.octet_aligned->buf);
                    }
                }
            }
        }
    }
    return 0;
}

/* result set delete */
int ztest_delete (void *handle, bend_delete_rr *rr)
{
    if (rr->num_setnames == 1 && !strcmp (rr->setnames[0], "1"))
        rr->delete_status = Z_DeleteStatus_success;
    else
        rr->delete_status = Z_DeleteStatus_resultSetDidNotExist;
    return 0;
}

/* Our sort handler really doesn't sort... */
int ztest_sort (void *handle, bend_sort_rr *rr)
{
    rr->errcode = 0;
    rr->sort_status = Z_SortResponse_success;
    return 0;
}


/* present request handler */
int ztest_present (void *handle, bend_present_rr *rr)
{
    return 0;
}

/* retrieval of a single record (present, and piggy back search) */
int ztest_fetch(void *handle, bend_fetch_rr *r)
{
    char *cp;

    r->last_in_set = 0;
    r->basename = "Default";
    r->output_format = r->request_format;  
    if (r->request_format == VAL_SUTRS)
    {
        /* this section returns a small record */
        char buf[100];
        
        sprintf(buf, "This is dummy SUTRS record number %d\n", r->number);

        r->len = strlen(buf);
        r->record = (char *) odr_malloc (r->stream, r->len+1);
        strcpy(r->record, buf);
    }
    else if (r->request_format == VAL_GRS1)
    {
        r->len = -1;
        r->record = (char*) dummy_grs_record(r->number, r->stream);
        if (!r->record)
        {
            r->errcode = 13;
            return 0;
        }
    }
    else if (r->request_format == VAL_POSTSCRIPT)
    {
        char fname[20];
        FILE *f;
        long size;

        sprintf (fname, "part.%d.ps", r->number);
        f = fopen(fname, "rb");
        if (!f)
        {
            r->errcode = 13;
            return 0;
        }
        fseek (f, 0L, SEEK_END);
        size = ftell (f);
        if (size <= 0 || size >= 5000000)
        {
            r->errcode = 14;
            return 0;
        }
        fseek (f, 0L, SEEK_SET);
        r->record = (char*) odr_malloc (r->stream, size);
        r->len = size;
        r->output_format = VAL_POSTSCRIPT;
        fread (r->record, size, 1, f);
        fclose (f);
    }
    else if (r->request_format == VAL_TEXT_XML)
    {
        if ((cp = dummy_xml_record (r->number, r->stream)))
        {
            r->len = strlen(cp);
            r->record = cp;
            r->output_format = VAL_TEXT_XML;
        }
        else 
        {
            r->errcode = 14;
            r->surrogate_flag = 1;
            return 0;
        }
    }
    else if ((cp = dummy_marc_record(r->number, r->stream)))
    {
        r->len = strlen(cp);
        r->record = cp;
        r->output_format = VAL_USMARC;
    }
    else
    {
        r->errcode = 13;
        return 0;
    }
    r->errcode = 0;
    return 0;
}

/*
 * silly dummy-scan what reads words from a file.
 */
int ztest_scan(void *handle, bend_scan_rr *q)
{
    static FILE *f = 0;
    static struct scan_entry list[200];
    static char entries[200][80];
    int hits[200];
    char term[80], *p;
    int i, pos;
    int term_position_req = q->term_position;
    int num_entries_req = q->num_entries;

    /* Throw Database unavailable if other than Default or Slow */
    if (!yaz_matchstr (q->basenames[0], "Default"))
        ;  /* Default is OK in our test */
    else if(!yaz_matchstr (q->basenames[0], "Slow"))
    {
#if HAVE_UNISTD_H
        sleep(3);
#endif
        ;
    }
    else
    {
        q->errcode = 109;
        q->errstring = q->basenames[0];
        return 0;
    }

    q->errcode = 0;
    q->errstring = 0;
    q->entries = list;
    q->status = BEND_SCAN_SUCCESS;
    if (!f && !(f = fopen("dummy-words", "r")))
    {
        perror("dummy-words");
        exit(1);
    }
    if (q->num_entries > 200)
    {
        q->errcode = 31;
        return 0;
    }
    if (q->term)
    {
        int len;
        if (q->term->term->which != Z_Term_general)
        {
            q->errcode = 229; /* unsupported term type */
            return 0;
        }
        if (*q->step_size != 0)
        {
            q->errcode = 205; /*Only zero step size supported for Scan */
            return 0;
        }
        len = q->term->term->u.general->len;
        if (len >= sizeof(term))
            len = sizeof(term)-1;
        memcpy(term, q->term->term->u.general->buf, len);
        term[len] = '\0';
    }
    else if (q->scanClause)
    {
        strncpy(term, q->scanClause, sizeof(term)-1);
        term[sizeof(term)-1] = '\0';
    }
    else
        strcpy(term, "0");

    for (p = term; *p; p++)
        if (islower(*(unsigned char *) p))
            *p = toupper(*p);

    fseek(f, 0, SEEK_SET);
    q->num_entries = 0;

    for (i = 0, pos = 0; fscanf(f, " %79[^:]:%d", entries[pos], &hits[pos]) == 2;
        i++, pos < 199 ? pos++ : (pos = 0))
    {
        if (!q->num_entries && strcmp(entries[pos], term) >= 0) /* s-point fnd */
        {
            if ((q->term_position = term_position_req) > i + 1)
            {
                q->term_position = i + 1;
                q->status = BEND_SCAN_PARTIAL;
            }
            for (; q->num_entries < q->term_position; q->num_entries++)
            {
                int po;

                po = pos - q->term_position + q->num_entries+1; /* find pos */
                if (po < 0)
                    po += 200;

                if (!strcmp (term, "SD") && q->num_entries == 2)
                {
                    list[q->num_entries].term = entries[pos];
                    list[q->num_entries].occurrences = -1;
                    list[q->num_entries].errcode = 233;
                    list[q->num_entries].errstring = "SD for Scan Term";
                }
                else
                {
                    list[q->num_entries].term = entries[po];
                    list[q->num_entries].occurrences = hits[po];
                }
            }
        }
        else if (q->num_entries)
        {
            list[q->num_entries].term = entries[pos];
            list[q->num_entries].occurrences = hits[pos];
            q->num_entries++;
        }
        if (q->num_entries >= num_entries_req)
            break;
    }
    if (feof(f))
        q->status = BEND_SCAN_PARTIAL;
    return 0;
}

int ztest_explain(void *handle, bend_explain_rr *rr)
{
    if (rr->database && !strcmp(rr->database, "Default"))
    {
        rr->explain_buf = "<explain>\n"
            "\t<serverInfo>\n"
            "\t\t<host>localhost</host>\n"
            "\t\t<port>210</port>\n"
            "\t</serverInfo>\n"
            "</explain>\n";
    }
    return 0;
}

int ztest_update(void *handle, bend_update_rr *rr)
{
    rr->operation_status = "success";
    return 0;
}

bend_initresult *bend_init(bend_initrequest *q)
{
    bend_initresult *r = (bend_initresult *)
        odr_malloc (q->stream, sizeof(*r));
    int *counter = (int *) xmalloc (sizeof(int));

    if (!log_level_set)
    {
        log_level=yaz_log_module_level("ztest");
        log_level_set=1;
    }

    *counter = 0;
    r->errcode = 0;
    r->errstring = 0;
    r->handle = counter;         /* user handle, in this case a simple int */
    q->bend_sort = ztest_sort;              /* register sort handler */
    q->bend_search = ztest_search;          /* register search handler */
    q->bend_present = ztest_present;        /* register present handle */
    q->bend_esrequest = ztest_esrequest;
    q->bend_delete = ztest_delete;
    q->bend_fetch = ztest_fetch;
    q->bend_scan = ztest_scan;
#if 0
    q->bend_explain = ztest_explain;
#endif
    q->bend_srw_scan = ztest_scan;
    q->bend_srw_update = ztest_update;

    return r;
}

void bend_close(void *handle)
{
    xfree (handle);              /* release our user-defined handle */
    return;
}

int main(int argc, char **argv)
{
    return statserv_main(argc, argv, bend_init, bend_close);
}
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

