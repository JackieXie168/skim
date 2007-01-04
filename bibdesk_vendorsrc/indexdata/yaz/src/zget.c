/*
 * Copyright (C) 1995-2005, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: zget.c,v 1.11 2005/06/25 15:46:06 adam Exp $
 */
/**
 * \file zget.c
 * \brief Implements Z39.50 package creator utilities
 */

#include <yaz/proto.h>

Z_InitRequest *zget_InitRequest(ODR o)
{
    Z_InitRequest *r = (Z_InitRequest *)odr_malloc(o, sizeof(*r));

    r->referenceId = 0;
    r->options = (Odr_bitmask *)odr_malloc(o, sizeof(*r->options));
    ODR_MASK_ZERO(r->options);
    r->protocolVersion = (Odr_bitmask *)
        odr_malloc(o, sizeof(*r->protocolVersion));

    ODR_MASK_SET(r->options, Z_Options_search);
    ODR_MASK_SET(r->options, Z_Options_present);

    ODR_MASK_ZERO(r->protocolVersion);

    ODR_MASK_SET(r->protocolVersion, Z_ProtocolVersion_1);
    ODR_MASK_SET(r->protocolVersion, Z_ProtocolVersion_2);

    r->preferredMessageSize = odr_intdup(o, 1024*1024);
    r->maximumRecordSize = odr_intdup(o, 1024*1024);
    r->idAuthentication = 0;
    r->implementationId = "81";
    r->implementationName = "YAZ";
    r->implementationVersion = YAZ_VERSION
#ifdef YAZ_DATE_STR
    " (" YAZ_DATE_STR ")"
#endif
#ifdef YAZ_OS
    " " YAZ_OS
#endif
        ;
    r->userInformationField = 0;
    r->otherInfo = 0;
    return r;
}

Z_InitResponse *zget_InitResponse(ODR o)
{
    Z_InitResponse *r = (Z_InitResponse *)odr_malloc(o, sizeof(*r));

    r->referenceId = 0;
    r->options = (Odr_bitmask *)odr_malloc(o, sizeof(*r->options));
    ODR_MASK_ZERO(r->options);
    r->protocolVersion = (Odr_bitmask *)odr_malloc(o, sizeof(*r->protocolVersion));
    ODR_MASK_ZERO(r->protocolVersion);
    r->preferredMessageSize = odr_intdup(o, 30*1024);
    r->maximumRecordSize = odr_intdup(o, 30*1024);
    r->result = odr_intdup(o, 1);
    r->implementationId = "81";
    r->implementationName = "YAZ";
    r->implementationVersion = YAZ_VERSION
#ifdef YAZ_DATE_STR
    " (" YAZ_DATE_STR ")"
#endif
#ifdef YAZ_OS
    " " YAZ_OS
#endif
        ;
    r->userInformationField = 0;
    r->otherInfo = 0;
    return r;
}

Z_SearchRequest *zget_SearchRequest(ODR o)
{
    Z_SearchRequest *r = (Z_SearchRequest *)odr_malloc(o, sizeof(*r));

    r->referenceId = 0;
    r->smallSetUpperBound = odr_intdup(o, 0);
    r->largeSetLowerBound = odr_intdup(o, 1);
    r->mediumSetPresentNumber = odr_intdup(o, 0);
    r->replaceIndicator = odr_intdup(o, 1);
    r->resultSetName = "default";
    r->num_databaseNames = 0;
    r->databaseNames = 0;
    r->smallSetElementSetNames = 0;
    r->mediumSetElementSetNames = 0;
    r->preferredRecordSyntax = 0;
    r->query = 0;
    r->additionalSearchInfo = 0;
    r->otherInfo = 0;
    return r;
}

Z_SearchResponse *zget_SearchResponse(ODR o)
{
    Z_SearchResponse *r = (Z_SearchResponse *)odr_malloc(o, sizeof(*r));

    r->referenceId = 0;
    r->resultCount = odr_intdup(o, 0);
    r->numberOfRecordsReturned = odr_intdup(o, 0);
    r->nextResultSetPosition = odr_intdup(o, 0);
    r->searchStatus = odr_intdup(o, 1);
    r->resultSetStatus = 0;
    r->presentStatus = 0;
    r->records = 0;
    r->additionalSearchInfo = 0;
    r->otherInfo = 0;
    return r;
}

Z_PresentRequest *zget_PresentRequest(ODR o)
{
    Z_PresentRequest *r = (Z_PresentRequest *)odr_malloc(o, sizeof(*r));

    r->referenceId = 0;
    r->resultSetId = "default";
    r->resultSetStartPoint = odr_intdup(o, 1);
    r->numberOfRecordsRequested = odr_intdup(o, 10);
    r->num_ranges = 0;
    r->additionalRanges = 0;
    r->recordComposition = 0;
    r->preferredRecordSyntax = 0;
    r->maxSegmentCount = 0;
    r->maxRecordSize = 0;
    r->maxSegmentSize = 0;
    r->otherInfo = 0;
    return r;
}

Z_PresentResponse *zget_PresentResponse(ODR o)
{
    Z_PresentResponse *r = (Z_PresentResponse *)odr_malloc(o, sizeof(*r));

    r->referenceId = 0;
    r->numberOfRecordsReturned = odr_intdup(o, 0);
    r->nextResultSetPosition = odr_intdup(o, 0);
    r->presentStatus = odr_intdup(o, Z_PresentStatus_success);
    r->records = 0;
    r->otherInfo = 0;
    return r;
}

Z_DeleteResultSetRequest *zget_DeleteResultSetRequest(ODR o)
{
    Z_DeleteResultSetRequest *r = (Z_DeleteResultSetRequest *)
        odr_malloc(o, sizeof(*r));

    r->referenceId = 0;
    r->deleteFunction = odr_intdup(o, Z_DeleteResultSetRequest_list);
    r->num_resultSetList = 0;
    r->resultSetList = 0;
    r->otherInfo = 0;
    return r;
}

Z_DeleteResultSetResponse *zget_DeleteResultSetResponse(ODR o)
{
    Z_DeleteResultSetResponse *r = (Z_DeleteResultSetResponse *)
        odr_malloc(o, sizeof(*r));
    
    r->referenceId = 0;
    r->deleteOperationStatus = odr_intdup(o, Z_DeleteStatus_success);
    r->deleteListStatuses = 0;
    r->numberNotDeleted = 0;
    r->bulkStatuses = 0;
    r->deleteMessage = 0;
    r->otherInfo = 0;
    return r;
}

Z_ScanRequest *zget_ScanRequest(ODR o)
{
    Z_ScanRequest *r = (Z_ScanRequest *)odr_malloc(o, sizeof(*r));
    
    r->referenceId = 0;
    r->num_databaseNames = 0;
    r->databaseNames = 0;
    r->attributeSet = 0;
    r->termListAndStartPoint = 0;
    r->stepSize = 0;
    r->numberOfTermsRequested = odr_intdup(o, 20);
    r->preferredPositionInResponse = 0;
    r->otherInfo = 0;
    return r;
}

Z_ScanResponse *zget_ScanResponse(ODR o)
{
    Z_ScanResponse *r = (Z_ScanResponse *)odr_malloc(o, sizeof(*r));
    
    r->referenceId = 0;
    r->stepSize = 0;
    r->scanStatus = odr_intdup(o, Z_Scan_success);
    r->numberOfEntriesReturned = odr_intdup(o, 0);
    r->positionOfTerm =0;
    r->entries = 0;
    r->attributeSet = 0;
    r->otherInfo = 0;
    return r;
}

Z_TriggerResourceControlRequest *zget_TriggerResourceControlRequest(ODR o)
{
    Z_TriggerResourceControlRequest *r = (Z_TriggerResourceControlRequest *)
        odr_malloc(o, sizeof(*r));
    
    r->referenceId = 0;
    r->requestedAction = odr_intdup(o, Z_TriggerResourceControlRequest_resourceReport);
    r->prefResourceReportFormat = 0;
    r->resultSetWanted = 0;
    r->otherInfo = 0;
    return r;
}

Z_ResourceControlRequest *zget_ResourceControlRequest(ODR o)
{
    Z_ResourceControlRequest *r = (Z_ResourceControlRequest *)
        odr_malloc(o, sizeof(*r));

    r->referenceId = 0;
    r->suspendedFlag = 0;
    r->resourceReport = 0;
    r->partialResultsAvailable = 0;
    r->responseRequired = odr_intdup(o, 0);
    r->triggeredRequestFlag = 0;
    r->otherInfo = 0;
    return r;
}

Z_ResourceControlResponse *zget_ResourceControlResponse(ODR o)
{
    Z_ResourceControlResponse *r = (Z_ResourceControlResponse *)
        odr_malloc(o, sizeof(*r));

    r->referenceId = 0;
    r->continueFlag = odr_intdup(o, 1);
    r->resultSetWanted = 0;
    r->otherInfo = 0;
    return r;
}

Z_AccessControlRequest *zget_AccessControlRequest(ODR o)
{
    Z_AccessControlRequest *r = (Z_AccessControlRequest *)
        odr_malloc(o, sizeof(*r));

    r->referenceId = 0;
    r->which = Z_AccessControlRequest_simpleForm;
    r->u.simpleForm = 0;
    r->otherInfo = 0;
    return r;
}

Z_AccessControlResponse *zget_AccessControlResponse(ODR o)
{
    Z_AccessControlResponse *r = (Z_AccessControlResponse *)
        odr_malloc(o, sizeof(*r));

    r->referenceId = 0;
    r->which = Z_AccessControlResponse_simpleForm;
    r->u.simpleForm = 0;
    r->diagnostic = 0;
    r->otherInfo = 0;
    return r;
}

Z_Segment *zget_Segment(ODR o)
{
    Z_Segment *r = (Z_Segment *)odr_malloc(o, sizeof(*r));

    r->referenceId = 0;
    r->numberOfRecordsReturned = odr_intdup(o, 0);
    r->num_segmentRecords = 0;
    r->segmentRecords = (Z_NamePlusRecord **) odr_nullval();
    r->otherInfo = 0;
    return r;
}

Z_Close *zget_Close(ODR o)
{
    Z_Close *r = (Z_Close *)odr_malloc(o, sizeof(*r));

    r->referenceId = 0;
    r->closeReason = odr_intdup(o, Z_Close_finished);
    r->diagnosticInformation = 0;
    r->resourceReportFormat = 0;
    r->resourceReport = 0;
    r->otherInfo = 0;
    return r;
}

Z_ResourceReportRequest *zget_ResourceReportRequest(ODR o)
{
    Z_ResourceReportRequest *r = (Z_ResourceReportRequest *)
        odr_malloc(o, sizeof(*r));

    r->referenceId = 0;
    r->opId = 0;
    r->prefResourceReportFormat = 0;
    r->otherInfo = 0;
    return r;
}

Z_ResourceReportResponse *zget_ResourceReportResponse(ODR o)
{
    Z_ResourceReportResponse *r = (Z_ResourceReportResponse *)
        odr_malloc(o, sizeof(*r));

    r->referenceId = 0;
    r->resourceReportStatus = odr_intdup(o, Z_ResourceReportResponse_success);
    r->resourceReport = 0;
    r->otherInfo = 0;
    return r;
}

Z_SortRequest *zget_SortRequest(ODR o)
{
    Z_SortRequest *r = (Z_SortRequest *)odr_malloc(o, sizeof(*r));

    r->referenceId = 0;
    r->inputResultSetNames = 0;
    r->sortedResultSetName = 0;
    r->sortSequence = 0;
    r->otherInfo = 0;
    return r;
}

Z_SortResponse *zget_SortResponse(ODR o)
{
    Z_SortResponse *r = (Z_SortResponse *)odr_malloc(o, sizeof(*r));

    r->referenceId = 0;
    r->sortStatus = odr_intdup(o, Z_SortResponse_success);
    r->resultSetStatus = odr_intdup(o, Z_SortResponse_empty);
    r->diagnostics = 0;
    r->resultCount = 0;
    r->otherInfo = 0;
    return r;
}

Z_ExtendedServicesRequest *zget_ExtendedServicesRequest(ODR o)
{
    Z_ExtendedServicesRequest *r = (Z_ExtendedServicesRequest *)
        odr_malloc(o, sizeof(*r));

    r->referenceId = 0;
    r->function = odr_intdup(o, Z_ExtendedServicesRequest_create);
    r->packageType = 0;
    r->packageName = 0;
    r->userId = 0;
    r->retentionTime = 0;
    r->permissions = 0;
    r->description = 0;
    r->taskSpecificParameters = 0;
    r->waitAction = odr_intdup(o, Z_ExtendedServicesRequest_waitIfPossible);
    r->elements = 0;
    r->otherInfo = 0;
    return r;
}

Z_ExtendedServicesResponse *zget_ExtendedServicesResponse(ODR o)
{
    Z_ExtendedServicesResponse *r = (Z_ExtendedServicesResponse *)
        odr_malloc(o, sizeof(*r));

    r->referenceId = 0;
    r->operationStatus = odr_intdup(o, Z_ExtendedServicesResponse_done);
    r->num_diagnostics = 0;
    r->diagnostics = 0;
    r->taskPackage = 0;
    r->otherInfo = 0;
    return r;
}

Z_DuplicateDetectionRequest *zget_DuplicateDetectionRequest(ODR o)
{
    Z_DuplicateDetectionRequest *r = (Z_DuplicateDetectionRequest *)
        odr_malloc(o, sizeof(*r));
    
    r->referenceId = 0;
    r->num_inputResultSetIds = 0;
    r->inputResultSetIds = 0;
    r->outputResultSetName = 0;
    r->applicablePortionOfRecord = 0;
    r->num_duplicateDetectionCriteria = 0;
    r->duplicateDetectionCriteria = 0;
    r->clustering = 0;
    r->num_retentionCriteria = 0;
    r->retentionCriteria = 0;
    r->num_sortCriteria = 0;
    r->sortCriteria = 0;
    r->otherInfo = 0;
    return r;
}

Z_DuplicateDetectionResponse *zget_DuplicateDetectionResponse(ODR o)
{
    Z_DuplicateDetectionResponse *r = (Z_DuplicateDetectionResponse *)
        odr_malloc(o, sizeof(*r));
 
    r->referenceId = 0;
    r->status = odr_intdup(o, Z_DuplicateDetectionResponse_success);
    r->resultSetCount = 0;
    r->num_diagnostics = 0;
    r->diagnostics = 0;
    r->otherInfo = 0;
    return r;
}
 
Z_APDU *zget_APDU(ODR o, int which)
{
    Z_APDU *r = (Z_APDU *)odr_malloc(o, sizeof(*r));
    
    switch (r->which = which)
    {
    case Z_APDU_initRequest:
        r->u.initRequest = zget_InitRequest(o);
        break;
    case Z_APDU_initResponse:
        r->u.initResponse = zget_InitResponse(o);
        break;
    case Z_APDU_searchRequest:
        r->u.searchRequest = zget_SearchRequest(o);
        break;
    case Z_APDU_searchResponse:
        r->u.searchResponse = zget_SearchResponse(o);
        break;
    case Z_APDU_presentRequest:
        r->u.presentRequest = zget_PresentRequest(o);
        break;
    case Z_APDU_presentResponse:
        r->u.presentResponse = zget_PresentResponse(o);
        break;
    case Z_APDU_deleteResultSetRequest:
        r->u.deleteResultSetRequest = zget_DeleteResultSetRequest(o);
        break;
    case Z_APDU_deleteResultSetResponse:
        r->u.deleteResultSetResponse = zget_DeleteResultSetResponse(o);
        break;
    case Z_APDU_scanRequest:
        r->u.scanRequest = zget_ScanRequest(o);
        break;
    case Z_APDU_scanResponse:
        r->u.scanResponse = zget_ScanResponse(o);
        break;
    case Z_APDU_triggerResourceControlRequest:
        r->u.triggerResourceControlRequest =
            zget_TriggerResourceControlRequest(o);
        break;
    case Z_APDU_resourceControlRequest:
        r->u.resourceControlRequest = zget_ResourceControlRequest(o);
        break;
    case Z_APDU_resourceControlResponse:
        r->u.resourceControlResponse = zget_ResourceControlResponse(o);
        break;
    case Z_APDU_segmentRequest:
        r->u.segmentRequest = zget_Segment(o);
        break;
    case Z_APDU_close:
        r->u.close = zget_Close(o);
        break;
    case Z_APDU_accessControlRequest:
        r->u.accessControlRequest = zget_AccessControlRequest(o);
        break;
    case Z_APDU_accessControlResponse:
        r->u.accessControlResponse = zget_AccessControlResponse(o);
        break;
    case Z_APDU_resourceReportRequest:
        r->u.resourceReportRequest = zget_ResourceReportRequest(o);
        break;
    case Z_APDU_resourceReportResponse:
        r->u.resourceReportResponse = zget_ResourceReportResponse(o);
        break;
    case Z_APDU_sortRequest:
        r->u.sortRequest = zget_SortRequest(o);
        break;
    case Z_APDU_sortResponse:
        r->u.sortResponse = zget_SortResponse(o);
        break;
    case Z_APDU_extendedServicesRequest:
        r->u.extendedServicesRequest = zget_ExtendedServicesRequest(o);
        break;
    case Z_APDU_extendedServicesResponse:
        r->u.extendedServicesResponse = zget_ExtendedServicesResponse(o);
        break;
    case Z_APDU_duplicateDetectionRequest:
        r->u.duplicateDetectionRequest = zget_DuplicateDetectionRequest(o);
        break;
    case Z_APDU_duplicateDetectionResponse:
        r->u.duplicateDetectionResponse = zget_DuplicateDetectionResponse(o);
        break;
    default:
        return 0;
    }
    return r;
}

Z_DefaultDiagFormat *zget_DefaultDiagFormat(ODR o, int error,
                                            const char *addinfo)
{
    Z_DefaultDiagFormat *dr = (Z_DefaultDiagFormat *) 
        odr_malloc (o, sizeof(*dr));
    
    dr->diagnosticSetId = yaz_oidval_to_z3950oid (o, CLASS_DIAGSET, VAL_BIB1);
    dr->condition = odr_intdup(o, error);
    dr->which = Z_DefaultDiagFormat_v2Addinfo;
    dr->u.v2Addinfo = odr_strdup (o, addinfo ? addinfo : "");
    return dr;
}

Z_DiagRec *zget_DiagRec(ODR o, int error, const char *addinfo)
{
    Z_DiagRec *dr = (Z_DiagRec*) odr_malloc(o, sizeof(*dr));
    dr->which = Z_DiagRec_defaultFormat;
    dr->u.defaultFormat = zget_DefaultDiagFormat(o, error, addinfo);
    return dr;
}

Z_DiagRecs *zget_DiagRecs(ODR o, int error, const char *addinfo)
{
    Z_DiagRecs *drecs = (Z_DiagRecs*) odr_malloc(o, sizeof(*drecs));
    Z_DiagRec **dr = (Z_DiagRec**) odr_malloc(o, sizeof(**dr));
    drecs->diagRecs = dr;
    dr[0] = zget_DiagRec(o, error, addinfo);
    drecs->num_diagRecs = 1;
    return drecs;
}

Z_NamePlusRecord *zget_surrogateDiagRec(ODR o, const char *dbname,
                                        int error, const char *addinfo)
{
    Z_NamePlusRecord *rec = (Z_NamePlusRecord *) odr_malloc (o, sizeof(*rec));
    Z_DiagRec *drec = (Z_DiagRec *)odr_malloc (o, sizeof(*drec));
    
    if (dbname)
        rec->databaseName = odr_strdup(o, dbname);
    else
        rec->databaseName = 0;
    rec->which = Z_NamePlusRecord_surrogateDiagnostic;
    rec->u.surrogateDiagnostic = drec;
    drec->which = Z_DiagRec_defaultFormat;
    drec->u.defaultFormat = zget_DefaultDiagFormat(o, error, addinfo);
    return rec;
}

Z_External *zget_init_diagnostics(ODR odr, int error, const char *addinfo)
{
    Z_External *x, *x2;
    oident oid;
    Z_OtherInformation *u;
    Z_OtherInformationUnit *l;
    Z_DiagnosticFormat *d;
    Z_DiagnosticFormat_s *e;

    x = (Z_External*) odr_malloc(odr, sizeof *x);
    x->descriptor = 0;
    x->indirect_reference = 0;  
    oid.proto = PROTO_Z3950;
    oid.oclass = CLASS_USERINFO;
    oid.value = VAL_USERINFO1;
    x->direct_reference = odr_oiddup(odr, oid_getoidbyent(&oid));
    x->which = Z_External_userInfo1;

    u = odr_malloc(odr, sizeof *u);
    x->u.userInfo1 = u;
    u->num_elements = 1;
    u->list = (Z_OtherInformationUnit**) odr_malloc(odr, sizeof *u->list);
    u->list[0] = (Z_OtherInformationUnit*) odr_malloc(odr, sizeof *u->list[0]);
    l = u->list[0];
    l->category = 0;
    l->which = Z_OtherInfo_externallyDefinedInfo;

    x2 = (Z_External*) odr_malloc(odr, sizeof *x);
    l->information.externallyDefinedInfo = x2;
    x2->descriptor = 0;
    x2->indirect_reference = 0;
    oid.oclass = CLASS_DIAGSET;
    oid.value = VAL_DIAG1;
    x2->direct_reference = odr_oiddup(odr, oid_getoidbyent(&oid));
    x2->which = Z_External_diag1;

    d = (Z_DiagnosticFormat*) odr_malloc(odr, sizeof *d);
    x2->u.diag1 = d;
    d->num = 1;
    d->elements = (Z_DiagnosticFormat_s**) odr_malloc (odr, sizeof *d->elements);
    d->elements[0] = (Z_DiagnosticFormat_s*) odr_malloc (odr, sizeof *d->elements[0]);
    e = d->elements[0];

    e->which = Z_DiagnosticFormat_s_defaultDiagRec;
    e->u.defaultDiagRec = zget_DefaultDiagFormat(odr, error, addinfo);
    e->message = 0;
    return x;
}

Z_External *zget_init_diagnostics_octet(ODR odr, int error,
                                        const char *addinfo)
{
    Z_External *x, *x2;
    oident oid;
    Z_OtherInformation *u;
    Z_OtherInformationUnit *l;
    Z_DiagnosticFormat *d;
    Z_DiagnosticFormat_s *e;
    char *octet_buf;
    int octet_len;
    ODR encode;

    u = odr_malloc(odr, sizeof *u);
    u->num_elements = 1;
    u->list = (Z_OtherInformationUnit**) odr_malloc(odr, sizeof *u->list);
    u->list[0] = (Z_OtherInformationUnit*) odr_malloc(odr, sizeof *u->list[0]);
    l = u->list[0];
    l->category = 0;
    l->which = Z_OtherInfo_externallyDefinedInfo;

    x2 = (Z_External*) odr_malloc(odr, sizeof *x);
    l->information.externallyDefinedInfo = x2;
    x2->descriptor = 0;
    x2->indirect_reference = 0;
    oid.oclass = CLASS_DIAGSET;
    oid.proto = PROTO_Z3950;
    oid.value = VAL_DIAG1;
    x2->direct_reference = odr_oiddup(odr, oid_getoidbyent(&oid));
    x2->which = Z_External_diag1;

    d = (Z_DiagnosticFormat*) odr_malloc(odr, sizeof *d);
    x2->u.diag1 = d;
    d->num = 1;
    d->elements = (Z_DiagnosticFormat_s**) odr_malloc (odr, sizeof *d->elements);
    d->elements[0] = (Z_DiagnosticFormat_s*) odr_malloc (odr, sizeof *d->elements[0]);
    e = d->elements[0];

    e->which = Z_DiagnosticFormat_s_defaultDiagRec;
    e->u.defaultDiagRec = zget_DefaultDiagFormat(odr, error, addinfo);
    e->message = 0;

    encode = odr_createmem(ODR_ENCODE);

    z_OtherInformation(encode, &u, 0, 0);

    octet_buf = odr_getbuf(encode, &octet_len, 0);

    x = (Z_External*) odr_malloc(odr, sizeof *x);
    x->descriptor = 0;
    x->indirect_reference = 0;  
    oid.proto = PROTO_Z3950;
    oid.oclass = CLASS_USERINFO;
    oid.value = VAL_USERINFO1;
    x->direct_reference = odr_oiddup(odr, oid_getoidbyent(&oid));

    x->which = Z_External_octet;
    x->u.octet_aligned = (Odr_oct *) odr_malloc(odr, sizeof(Odr_oct));
    x->u.octet_aligned->buf = odr_malloc(odr, octet_len);
    memcpy(x->u.octet_aligned->buf, octet_buf, octet_len);
    x->u.octet_aligned->len = octet_len;

    odr_destroy(encode);

    return x;
}

/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

