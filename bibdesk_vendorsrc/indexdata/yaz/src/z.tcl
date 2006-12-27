# YC Sample Config File for Z39.50
# $Id: z.tcl,v 1.1 2003/10/27 12:21:36 adam Exp $
# ----------------------------------------------------------
# Prefix Specifications
#  
#    1: C function prefix
#    2: C type prefix
#    3: C preprocessor prefix

# Default prefix
set default-prefix {z_ Z_ Z_}

# Name clash in extended services (TargetPart, OriginPartToKeep, etc)
# You can possibly think of better names :)
set prefix(ESFormat-PersistentResultSet) {z_PR Z_PR Z_PR}
set prefix(ESFormat-PersistentQuery) {z_PQuery Z_PQuery Z_PQuery}
set prefix(ESFormat-PeriodicQuerySchedule) {z_PQS Z_PQS Z_PQS}
set prefix(ESFormat-ItemOrder) {z_IO Z_IO Z_IO}
set prefix(ESFormat-Update0) {z_IU0 Z_IU0 Z_IU0}
set prefix(ESFormat-Update) {z_IU Z_IU Z_IU}
set prefix(ESFormat-ExportSpecification) {z_ES Z_ES Z_ES}
set prefix(ESFormat-ExportInvocation) {z_EI Z_EI Z_EI}

# ----------------------------------------------------------
# Settings for core of the protocol
set m Z39-50-APDU-1995

# Filename
set filename($m) z-core

# Public header initialization code
set init($m,h) {
typedef struct Z_External Z_External;
YAZ_EXPORT int z_External(ODR o, Z_External **p, int opt, const char *name);
}

set body($m,h) "
#ifdef __cplusplus
extern \"C\" \{
#endif

int z_ANY_type_0 (ODR o, void **p, int opt);

#ifdef __cplusplus
\}
#endif
"
set body($m,c) {

/* the type-0 query ... */
int z_ANY_type_0 (ODR o, void **p, int opt)
{
    return 0;
}

}

# Type Name overrides
set map($m,PDU) APDU
set membermap($m,Operator,and) {Operator_and op_and}
set membermap($m,Operator,or) {Operator_or op_or}
#set membermap($m,Operator,and-not) {Operator_and_not op_and_not}
set map($m,AttributeElement_complex) ComplexAttribute
set map($m,DeleteSetStatus) DeleteStatus
set membermap($m,ProximityOperator,private) {ProximityOperator_private zprivate}
set unionmap($m,AttributeElement,attributeValue) {which value AttributeValue}
set membermap($m,ElementSpec,externalEspec) externalSpec
set membermap($m,RPNStructure,op) simple
set membermap($m,RPNStructure,rpnRpnOp) complex
set map($m,RPNStructure_complex) Complex
set membermap($m,Operand,attrTerm) {Operand_APT attributesPlusTerm}
set membermap($m,Operand,resultSet) {Operand_resultSetId resultSetId}
set membermap($m,Operand,resultAttr) {Operand_resultAttr resultAttr}
set membermap($m,Complex,rpn1) s1
set membermap($m,Complex,rpn2) s2
set membermap($m,Complex,op) roperator
set membermap($m,RPNQuery,attributeSet) attributeSetId
set membermap($m,RPNQuery,rpn) RPNStructure
set map($m,KnownProximityUnit) ProxUnit
set membermap($m,ProximityOperator,lessThan) {Prox_lessThan 1}
set membermap($m,ProximityOperator,lessThanOrEqual) {Prox_lessThanOrEqual 1}
set membermap($m,ProximityOperator,equal) {Prox_equal 1}
set membermap($m,ProximityOperator,greaterThanOrEqual) {Prox_greaterThanOrEqual 1}
set membermap($m,ProximityOperator,greaterThan) {Prox_greaterThan 1}
set membermap($m,ProximityOperator,notEqual) {Prox_notEqual 1}
#
set membermap($m,Records,responseRecords) {Records_DBOSD databaseOrSurDiagnostics}
set membermap($m,Records,nonSurrogateDiagnostic) {Records_NSD nonSurrogateDiagnostic}
set membermap($m,Records,multipleNonSurDiagnostics) {Records_multipleNSD multipleNonSurDiagnostics}
set map($m,Records_DBOSD) NamePlusRecordList
set map($m,Records_NSD) DiagRec
set map($m,Records_multipleNSD) DiagRecs
set membermap($m,NamePlusRecord,name) databaseName
set unionmap($m,DiagRecs) {num_diagRecs diagRecs}
set unionmap($m,NamePlusRecordList) {num_records records}
#
set membermap($m,ElementSetNames,genericElementSetName) generic
set map($m,ElementSetNames_databaseSpecific) DatabaseSpecific
#
set map($m,OccurrenceByAttributes_s) OccurrenceByAttributesElem
set map($m,OccurrenceByAttributesElem_byDatabase) byDatabaseList
#
set membermap($m,SortElement,datbaseSpecific) databaseSpecific
set map($m,SortElement_databaseSpecific) SortDbSpecificList
#
set map($m,SortKey_sortAttributes) SortAttributes
set unionmap($m,PresentRequest,recordComposition) {}
set map($m,PresentRequest_0) RecordComposition
set unionmap($m,PresentRequest,additionalRanges) {num_ranges additionalRanges}
set unionmap($m,SortRequest,sortSequence) {}
set map($m,SortRequest_0) SortKeySpecList
set unionmap($m,SortKeySpecList) {num_specs specs}
set map($m,InitializeRequest) InitRequest
set map($m,InitializeResponse) InitResponse
set unionmap($m,CloseReason) Close
set membermap($m,ProtocolVersion,version-1) 1
set membermap($m,ProtocolVersion,version-2) 2
set membermap($m,ProtocolVersion,version-3) 3
set membermap($m,InitRequest,exceptionalRecordSize) maximumRecordSize
set membermap($m,InitResponse,exceptionalRecordSize) maximumRecordSize
set map($m,RecordsMultipleNonSurDiagnostics) DiagRecs
set map($m,RecordsDatabaseOrSurDiagnostics) NamePlusRecordList
set membermap($m,NamePlusRecord,retrievalRecord) databaseRecord
set unionmap($m,RecordComposition) {which u RecordComp}
set unionmap($m,ScanResponse,scanStatus) Scan
set unionmap($m,AttributeList) {num_attributes attributes}
set membermap($m,SortKey,sortfield) sortField
set map($m,CompSpec_0) DbSpecific
set map($m,DatabaseSpecific_s) DatabaseSpecificUnit
set map($m,ListStatuses_s) ListStatus
set map($m,IdAuthenticationIdPass) IdPass
set map($m,OtherInformation_s) OtherInformationUnit
set unionmap($m,OtherInformationUnit,information) {which information OtherInfo}
set unionmap($m,OtherInformation) {num_elements list}
set unionmap($m,Specification,elementSpec) {}
set map($m,Specification_0) ElementSpec
set unionmap($m,Specification,schema) {which schema Schema}

# ----
set m DiagnosticFormatDiag1
set filename($m) z-diag1
set map($m,DiagFormat_tooMany) TooMany
set map($m,DiagFormat_badSpec) BadSpec
set map($m,DiagFormat_dbUnavail) DbUnavail
set map($m,DiagFormat_attribute) Attribute
set map($m,DiagFormat_attCombo) AttCombo
set map($m,DiagFormat_term) DiagTerm
set map($m,DiagFormat_proximity) Proximity
set map($m,DiagFormat_scan) Scan
set map($m,DiagFormat_sort) Sort
set unionmap($m,Sort) {which u SortD}
set map($m,DiagFormat_segmentation) Segmentation
set map($m,DiagFormat_extServices) ExtServices
set map($m,DiagFormat_accessCtrl) AccessCtrl
set map($m,DiagFormat_recordSyntax) RecordSyntax
#
set map($m,Scan_termList2) AttrListList
set map($m,Sort_inputTooLarge) StringList
#
set map($m,AccessCtrl_oid) OidList
set map($m,AccessCtrl_alternative) AltOidList
# ----
set m RecordSyntax-explain
set filename($m) z-exp
set map($m,Explain-Record) ExplainRecord
set map($m,ElementDataType_structured) ElementInfoList
set map($m,HumanString_s) HumanStringUnit
set unionmap($m,HumanString) {num_strings strings}
set membermap($m,CommonInfo,humanString-Language) humanStringLanguage
set unionmap($m,AttributeOccurrence,attributeValues) {which attributeValues AttributeOcc}
set unionmap($m,AttributeCombination) {num_occurrences occurrences}
#
set membermap($m,NetworkAddress,internetAddress) {NetworkAddress_iA internetAddress}
set map($m,NetworkAddress_iA) NetworkAddressIA
set membermap($m,NetworkAddress,osiPresentationAddress) {NetworkAddress_oPA osiPresentationAddress}
set map($m,NetworkAddress_oPA) NetworkAddressOPA
set map($m,NetworkAddress_other) NetworkAddressOther
set unionmap($m,DatabaseList) {num_databases databases}
set membermap($m,TargetInfo,recent-news) recentNews
set membermap($m,TargetInfo,usage-restrictions) usageRest
set membermap($m,DatabaseInfo,user-fee) userFee
#
set map($m,ProximitySupport_0) ProxSupportUnit
set map($m,ProxSupportUnitZprivate) ProxSupportPrivate
set membermap($m,ProxSupportUnit,private) {ProxSupportUnit_private zprivate}
#
set map($m,AttributeOccurrence_specific) AttributeValueList
set unionmap($m,AttributeValueList) {num_attributes attributes}

set unionmap($m,ExplainRecord) {which u Explain}
set map($m,SchemaInfo_0) TagTypeMapping
set map($m,TagSetInfo_0) TagSetElements
set map($m,TermListInfo_0) TermListElement
set map($m,TermListDetails_0) EScanInfo
set map($m,PrivateCapabilities_0) PrivateCapOperator
set map($m,Costs_0) CostsOtherCharge
set map($m,Path_s) PathUnit
set map($m,IconObject_s) IconObjectUnit
set map($m,NetworkAddressInternetAddress) NetworkAddressIA
set map($m,NetworkAddressOsiPresentationAddress) NetworkAddressOPA
set membermap($m,QueryTypeDetails,private) {QueryTypeDetails_private zprivate}
set membermap($m,PrivateCapOperator,operator) roperator
set map($m,AccessRestrictions_s) AccessRestrictionsUnit
# ----
set m RecordSyntax-SUTRS
set filename($m) z-sutrs
#set map($m,SutrsRecord) SUTRS
set body($m,c) {
int z_SUTRS (ODR o, Odr_oct **p, int opt, const char *name)
{
    return odr_implicit_tag(o, odr_octetstring, p, ODR_UNIVERSAL,
        ODR_GENERALSTRING, opt, name);
}
}

set init($m,h) {
typedef Odr_oct Z_SUTRS;
YAZ_EXPORT int z_SUTRS (ODR o, Odr_oct **p, int opt, const char *name);
}
# ----
set m RecordSyntax-opac
set filename($m) z-opac
# ----
set m RecordSyntax-summary
set filename($m) z-sum
# ----
set m RecordSyntax-generic
set filename($m) z-grs
set map($m,ElementData_subtree) GenericRecord
set map($m,Variant_0) Triple
set membermap($m,Triple,class) zclass
set unionmap($m,Triple,value) {which value Triple}
set unionmap($m,GenericRecord) {num_elements elements}
# ----
set m RecordSyntax-ESTaskPackage
set filename($m) z-estask
# ----
set m ResourceReport-Format-Resource-1
set filename($m) z-rrf1
set map($m,ResourceReport) ResourceReport1
set map($m,Estimate) Estimate1
# ----
set m ResourceReport-Format-Resource-2
set filename($m) z-rrf2
set map($m,ResourceReport) ResourceReport2
set map($m,Estimate) Estimate2
# ----
set m AccessControlFormat-prompt-1
set filename($m) z-accform1
set membermap($m,PromptId,enummeratedPrompt) enumeratedPrompt 
set map($m,PromptObject) PromptObject1
set map($m,Challenge) Challenge1
set map($m,Challenge1_s) ChallengeUnit1
set map($m,Response) Response1
set map($m,Response1_s) ResponseUnit1
set map($m,PromptObject) PromptObject1
# ----
set m AccessControlFormat-des-1
set filename($m) z-accdes1
# ----
set m AccessControlFormat-krb-1
set filename($m) z-acckrb1
# ----
set m ESFormat-PersistentResultSet
set filename($m) zes-pset
# ----
set m ESFormat-PersistentQuery
set filename($m) zes-pquery
# ----
set m ESFormat-PeriodicQuerySchedule 
set filename($m) zes-psched
# ----
set m ESFormat-ItemOrder
set filename($m) zes-order
set map($m,ItemOrderEsRequest) Request
set map($m,ItemOrderTaskPackage) TaskPackage
set map($m,OriginPartToKeep_0) Contact
set map($m,OriginPartToKeep_1) Billing
set map($m,OriginPartNotToKeep_0) ResultSetItem
#
# ---- (old version)
set m ESFormat-Update0
set filename($m) zes-update0
set map($m,SuppliedRecords_s) SuppliedRecords_elem
set map($m,SuppliedRecords_elem_0) SuppliedRecordsId
#
# ---- (new, current version)
set m ESFormat-Update
set filename($m) zes-update
set map($m,SuppliedRecords_s) SuppliedRecords_elem
set map($m,SuppliedRecords_elem_0) SuppliedRecordsId
# ----
set m ESFormat-ExportSpecification
set filename($m) zes-exps
# ----
set m ESFormat-ExportInvocation
set filename($m) zes-expi
# ----
set m UserInfoFormat-searchResult-1
set filename($m) z-uifr1
# ----
set m ElementSpecificationFormat-eSpec-1
set filename($m) z-espec1
set map($m,Espec-1) Espec1
set map($m,TagPath) ETagPath
set map($m,ETagPath_s) ETagUnit
set map($m,ETagUnitSpecificTag) SpecificTag
set membermap($m,SpecificTag,occurrence) occurrences
set unionmap($m,ElementRequest) {which u ERequest}
set unionmap($m,ETagPath) {num_tags tags}
set map($m,OccurrencesValues) OccurValues
# ----
set m UserInfoFormat-dateTime
set filename($m) z-date
set map($m,Z3950Date) Date
set map($m,Z3950Time) Time
set unionmap($m,Z3950Date,era) {}
set map($m,DateFlags_0) Era
set map($m,Z3950DateMonthAndDay) MonthAndDay
set map($m,Z3950DateQuarter) DateQuater
set map($m,Z3950DateSeason) DateSeason
set map($m,Date_0) DateFlags
set unionmap($m,DateFlags,era) {}
# ----
set m UserInfoFormat-multipleSearchTerms-2
set filename($m) z-mterm2
# ----
set m ResourceReport-Format-Universe-1 
set filename($m) z-univ
# ----
set m UserInfoFormat-oclcUserInformation
set filename($m) z-oclcui
# ----
set m ESFormat-Admin
set filename($m) zes-admin
set map($m,EsRequest) ESAdminRequest
set map($m,TaskPackage) ESAdminTaskPackage
set map($m,OriginPartToKeep) ESAdminOriginPartToKeep
set map($m,OriginPartNotToKeep) ESAdminOriginPartNotToKeep
set map($m,TargetPart) ESAdminTargetPart
# ----
set m NegotiationRecordDefinition-charSetandLanguageNegotiation-3
set filename($m) z-charneg
set membermap($m,OriginProposal_0,private) {OriginProposal_0_private zprivate}
set membermap($m,TargetResponse,private) {TargetResponse_private zprivate}
# ----------------------------------------------------------
# "Constructed" types defined by means of C-types are declared here.
# Each function returns the C-handler and the C-type.
proc asnBasicEXTERNAL {} {
    return {z_External Z_External}
}
