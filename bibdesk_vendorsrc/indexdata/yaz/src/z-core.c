/** \file z-core.c
    \brief ASN.1 Module Z39-50-APDU-1995

    Generated automatically by YAZ ASN.1 Compiler 0.4
*/

#include <yaz/z-core.h>

int z_APDU (ODR o, Z_APDU **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 20, Z_APDU_initRequest,
		(Odr_fun) z_InitRequest, "initRequest"},
		{ODR_IMPLICIT, ODR_CONTEXT, 21, Z_APDU_initResponse,
		(Odr_fun) z_InitResponse, "initResponse"},
		{ODR_IMPLICIT, ODR_CONTEXT, 22, Z_APDU_searchRequest,
		(Odr_fun) z_SearchRequest, "searchRequest"},
		{ODR_IMPLICIT, ODR_CONTEXT, 23, Z_APDU_searchResponse,
		(Odr_fun) z_SearchResponse, "searchResponse"},
		{ODR_IMPLICIT, ODR_CONTEXT, 24, Z_APDU_presentRequest,
		(Odr_fun) z_PresentRequest, "presentRequest"},
		{ODR_IMPLICIT, ODR_CONTEXT, 25, Z_APDU_presentResponse,
		(Odr_fun) z_PresentResponse, "presentResponse"},
		{ODR_IMPLICIT, ODR_CONTEXT, 26, Z_APDU_deleteResultSetRequest,
		(Odr_fun) z_DeleteResultSetRequest, "deleteResultSetRequest"},
		{ODR_IMPLICIT, ODR_CONTEXT, 27, Z_APDU_deleteResultSetResponse,
		(Odr_fun) z_DeleteResultSetResponse, "deleteResultSetResponse"},
		{ODR_IMPLICIT, ODR_CONTEXT, 28, Z_APDU_accessControlRequest,
		(Odr_fun) z_AccessControlRequest, "accessControlRequest"},
		{ODR_IMPLICIT, ODR_CONTEXT, 29, Z_APDU_accessControlResponse,
		(Odr_fun) z_AccessControlResponse, "accessControlResponse"},
		{ODR_IMPLICIT, ODR_CONTEXT, 30, Z_APDU_resourceControlRequest,
		(Odr_fun) z_ResourceControlRequest, "resourceControlRequest"},
		{ODR_IMPLICIT, ODR_CONTEXT, 31, Z_APDU_resourceControlResponse,
		(Odr_fun) z_ResourceControlResponse, "resourceControlResponse"},
		{ODR_IMPLICIT, ODR_CONTEXT, 32, Z_APDU_triggerResourceControlRequest,
		(Odr_fun) z_TriggerResourceControlRequest, "triggerResourceControlRequest"},
		{ODR_IMPLICIT, ODR_CONTEXT, 33, Z_APDU_resourceReportRequest,
		(Odr_fun) z_ResourceReportRequest, "resourceReportRequest"},
		{ODR_IMPLICIT, ODR_CONTEXT, 34, Z_APDU_resourceReportResponse,
		(Odr_fun) z_ResourceReportResponse, "resourceReportResponse"},
		{ODR_IMPLICIT, ODR_CONTEXT, 35, Z_APDU_scanRequest,
		(Odr_fun) z_ScanRequest, "scanRequest"},
		{ODR_IMPLICIT, ODR_CONTEXT, 36, Z_APDU_scanResponse,
		(Odr_fun) z_ScanResponse, "scanResponse"},
		{ODR_IMPLICIT, ODR_CONTEXT, 43, Z_APDU_sortRequest,
		(Odr_fun) z_SortRequest, "sortRequest"},
		{ODR_IMPLICIT, ODR_CONTEXT, 44, Z_APDU_sortResponse,
		(Odr_fun) z_SortResponse, "sortResponse"},
		{ODR_IMPLICIT, ODR_CONTEXT, 45, Z_APDU_segmentRequest,
		(Odr_fun) z_Segment, "segmentRequest"},
		{ODR_IMPLICIT, ODR_CONTEXT, 46, Z_APDU_extendedServicesRequest,
		(Odr_fun) z_ExtendedServicesRequest, "extendedServicesRequest"},
		{ODR_IMPLICIT, ODR_CONTEXT, 47, Z_APDU_extendedServicesResponse,
		(Odr_fun) z_ExtendedServicesResponse, "extendedServicesResponse"},
		{ODR_IMPLICIT, ODR_CONTEXT, 48, Z_APDU_close,
		(Odr_fun) z_Close, "close"},
		{ODR_IMPLICIT, ODR_CONTEXT, 49, Z_APDU_duplicateDetectionRequest,
		(Odr_fun) z_DuplicateDetectionRequest, "duplicateDetectionRequest"},
		{ODR_IMPLICIT, ODR_CONTEXT, 50, Z_APDU_duplicateDetectionResponse,
		(Odr_fun) z_DuplicateDetectionResponse, "duplicateDetectionResponse"},
		{-1, -1, -1, -1, (Odr_fun) 0, 0}
	};
	if (!odr_initmember(o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_choice(o, arm, &(*p)->u, &(*p)->which, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int z_InitRequest (ODR o, Z_InitRequest **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		z_ReferenceId(o, &(*p)->referenceId, 1, "referenceId") &&
		z_ProtocolVersion(o, &(*p)->protocolVersion, 0, "protocolVersion") &&
		z_Options(o, &(*p)->options, 0, "options") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->preferredMessageSize, ODR_CONTEXT, 5, 0, "preferredMessageSize") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->maximumRecordSize, ODR_CONTEXT, 6, 0, "maximumRecordSize") &&
		odr_explicit_tag (o, z_IdAuthentication,
			&(*p)->idAuthentication, ODR_CONTEXT, 7, 1, "idAuthentication") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->implementationId, ODR_CONTEXT, 110, 1, "implementationId") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->implementationName, ODR_CONTEXT, 111, 1, "implementationName") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->implementationVersion, ODR_CONTEXT, 112, 1, "implementationVersion") &&
		odr_explicit_tag (o, z_External,
			&(*p)->userInformationField, ODR_CONTEXT, 11, 1, "userInformationField") &&
		z_OtherInformation(o, &(*p)->otherInfo, 1, "otherInfo") &&
		odr_sequence_end (o);
}

int z_IdPass (ODR o, Z_IdPass **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->groupId, ODR_CONTEXT, 0, 1, "groupId") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->userId, ODR_CONTEXT, 1, 1, "userId") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->password, ODR_CONTEXT, 2, 1, "password") &&
		odr_sequence_end (o);
}

int z_IdAuthentication (ODR o, Z_IdAuthentication **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{-1, -1, -1, Z_IdAuthentication_open,
		 (Odr_fun) odr_visiblestring, "open"},
		{-1, -1, -1, Z_IdAuthentication_idPass,
		 (Odr_fun) z_IdPass, "idPass"},
		{-1, -1, -1, Z_IdAuthentication_anonymous,
		 (Odr_fun) odr_null, "anonymous"},
		{-1, -1, -1, Z_IdAuthentication_other,
		 (Odr_fun) z_External, "other"},
		{-1, -1, -1, -1, (Odr_fun) 0, 0}
	};
	if (!odr_initmember(o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_choice(o, arm, &(*p)->u, &(*p)->which, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int z_InitResponse (ODR o, Z_InitResponse **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		z_ReferenceId(o, &(*p)->referenceId, 1, "referenceId") &&
		z_ProtocolVersion(o, &(*p)->protocolVersion, 0, "protocolVersion") &&
		z_Options(o, &(*p)->options, 0, "options") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->preferredMessageSize, ODR_CONTEXT, 5, 0, "preferredMessageSize") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->maximumRecordSize, ODR_CONTEXT, 6, 0, "maximumRecordSize") &&
		odr_implicit_tag (o, odr_bool,
			&(*p)->result, ODR_CONTEXT, 12, 0, "result") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->implementationId, ODR_CONTEXT, 110, 1, "implementationId") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->implementationName, ODR_CONTEXT, 111, 1, "implementationName") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->implementationVersion, ODR_CONTEXT, 112, 1, "implementationVersion") &&
		odr_explicit_tag (o, z_External,
			&(*p)->userInformationField, ODR_CONTEXT, 11, 1, "userInformationField") &&
		z_OtherInformation(o, &(*p)->otherInfo, 1, "otherInfo") &&
		odr_sequence_end (o);
}

int z_ProtocolVersion (ODR o, Z_ProtocolVersion **p, int opt, const char *name)
{
	return odr_implicit_tag (o, odr_bitstring, p, ODR_CONTEXT, 3, opt, name);
}

int z_Options (ODR o, Z_Options **p, int opt, const char *name)
{
	return odr_implicit_tag (o, odr_bitstring, p, ODR_CONTEXT, 4, opt, name);
}

int z_SearchRequest (ODR o, Z_SearchRequest **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		z_ReferenceId(o, &(*p)->referenceId, 1, "referenceId") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->smallSetUpperBound, ODR_CONTEXT, 13, 0, "smallSetUpperBound") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->largeSetLowerBound, ODR_CONTEXT, 14, 0, "largeSetLowerBound") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->mediumSetPresentNumber, ODR_CONTEXT, 15, 0, "mediumSetPresentNumber") &&
		odr_implicit_tag (o, odr_bool,
			&(*p)->replaceIndicator, ODR_CONTEXT, 16, 0, "replaceIndicator") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->resultSetName, ODR_CONTEXT, 17, 0, "resultSetName") &&
		odr_implicit_settag (o, ODR_CONTEXT, 18) &&
		odr_sequence_of(o, (Odr_fun) z_DatabaseName, &(*p)->databaseNames,
		  &(*p)->num_databaseNames, "databaseNames") &&
		odr_explicit_tag (o, z_ElementSetNames,
			&(*p)->smallSetElementSetNames, ODR_CONTEXT, 100, 1, "smallSetElementSetNames") &&
		odr_explicit_tag (o, z_ElementSetNames,
			&(*p)->mediumSetElementSetNames, ODR_CONTEXT, 101, 1, "mediumSetElementSetNames") &&
		odr_implicit_tag (o, odr_oid,
			&(*p)->preferredRecordSyntax, ODR_CONTEXT, 104, 1, "preferredRecordSyntax") &&
		odr_explicit_tag (o, z_Query,
			&(*p)->query, ODR_CONTEXT, 21, 0, "query") &&
		odr_implicit_tag (o, z_OtherInformation,
			&(*p)->additionalSearchInfo, ODR_CONTEXT, 203, 1, "additionalSearchInfo") &&
		z_OtherInformation(o, &(*p)->otherInfo, 1, "otherInfo") &&
		odr_sequence_end (o);
}

int z_Query (ODR o, Z_Query **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_EXPLICIT, ODR_CONTEXT, 0, Z_Query_type_0,
		(Odr_fun) z_ANY_type_0, "type_0"},
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_Query_type_1,
		(Odr_fun) z_RPNQuery, "type_1"},
		{ODR_EXPLICIT, ODR_CONTEXT, 2, Z_Query_type_2,
		(Odr_fun) odr_octetstring, "type_2"},
		{ODR_EXPLICIT, ODR_CONTEXT, 100, Z_Query_type_100,
		(Odr_fun) odr_octetstring, "type_100"},
		{ODR_IMPLICIT, ODR_CONTEXT, 101, Z_Query_type_101,
		(Odr_fun) z_RPNQuery, "type_101"},
		{ODR_EXPLICIT, ODR_CONTEXT, 102, Z_Query_type_102,
		(Odr_fun) odr_octetstring, "type_102"},
		{ODR_IMPLICIT, ODR_CONTEXT, 104, Z_Query_type_104,
		(Odr_fun) z_External, "type_104"},
		{-1, -1, -1, -1, (Odr_fun) 0, 0}
	};
	if (!odr_initmember(o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_choice(o, arm, &(*p)->u, &(*p)->which, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int z_RPNQuery (ODR o, Z_RPNQuery **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		z_AttributeSetId(o, &(*p)->attributeSetId, 0, "attributeSetId") &&
		z_RPNStructure(o, &(*p)->RPNStructure, 0, "RPNStructure") &&
		odr_sequence_end (o);
}

int z_Complex (ODR o, Z_Complex **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		z_RPNStructure(o, &(*p)->s1, 0, "s1") &&
		z_RPNStructure(o, &(*p)->s2, 0, "s2") &&
		z_Operator(o, &(*p)->roperator, 0, "roperator") &&
		odr_sequence_end (o);
}

int z_RPNStructure (ODR o, Z_RPNStructure **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_EXPLICIT, ODR_CONTEXT, 0, Z_RPNStructure_simple,
		(Odr_fun) z_Operand, "simple"},
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_RPNStructure_complex,
		(Odr_fun) z_Complex, "complex"},
		{-1, -1, -1, -1, (Odr_fun) 0, 0}
	};
	if (!odr_initmember(o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_choice(o, arm, &(*p)->u, &(*p)->which, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int z_Operand (ODR o, Z_Operand **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{-1, -1, -1, Z_Operand_APT,
		 (Odr_fun) z_AttributesPlusTerm, "attributesPlusTerm"},
		{-1, -1, -1, Z_Operand_resultSetId,
		 (Odr_fun) z_ResultSetId, "resultSetId"},
		{-1, -1, -1, Z_Operand_resultAttr,
		 (Odr_fun) z_ResultSetPlusAttributes, "resultAttr"},
		{-1, -1, -1, -1, (Odr_fun) 0, 0}
	};
	if (!odr_initmember(o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_choice(o, arm, &(*p)->u, &(*p)->which, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int z_AttributesPlusTerm (ODR o, Z_AttributesPlusTerm **p, int opt, const char *name)
{
	if (!odr_implicit_settag (o, ODR_CONTEXT, 102) ||
		!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name);
	return
		z_AttributeList(o, &(*p)->attributes, 0, "attributes") &&
		z_Term(o, &(*p)->term, 0, "term") &&
		odr_sequence_end (o);
}

int z_ResultSetPlusAttributes (ODR o, Z_ResultSetPlusAttributes **p, int opt, const char *name)
{
	if (!odr_implicit_settag (o, ODR_CONTEXT, 214) ||
		!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name);
	return
		z_ResultSetId(o, &(*p)->resultSet, 0, "resultSet") &&
		z_AttributeList(o, &(*p)->attributes, 0, "attributes") &&
		odr_sequence_end (o);
}

int z_AttributeList (ODR o, Z_AttributeList **p, int opt, const char *name)
{
	if (!odr_initmember (o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	odr_implicit_settag (o, ODR_CONTEXT, 44);
	if (odr_sequence_of (o, (Odr_fun) z_AttributeElement, &(*p)->attributes,
		&(*p)->num_attributes, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int z_Term (ODR o, Z_Term **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 45, Z_Term_general,
		(Odr_fun) odr_octetstring, "general"},
		{ODR_IMPLICIT, ODR_CONTEXT, 215, Z_Term_numeric,
		(Odr_fun) odr_integer, "numeric"},
		{ODR_IMPLICIT, ODR_CONTEXT, 216, Z_Term_characterString,
		(Odr_fun) z_InternationalString, "characterString"},
		{ODR_IMPLICIT, ODR_CONTEXT, 217, Z_Term_oid,
		(Odr_fun) odr_oid, "oid"},
		{ODR_IMPLICIT, ODR_CONTEXT, 218, Z_Term_dateTime,
		(Odr_fun) odr_generalizedtime, "dateTime"},
		{ODR_IMPLICIT, ODR_CONTEXT, 219, Z_Term_external,
		(Odr_fun) z_External, "external"},
		{ODR_IMPLICIT, ODR_CONTEXT, 220, Z_Term_integerAndUnit,
		(Odr_fun) z_IntUnit, "integerAndUnit"},
		{ODR_IMPLICIT, ODR_CONTEXT, 221, Z_Term_null,
		(Odr_fun) odr_null, "null"},
		{-1, -1, -1, -1, (Odr_fun) 0, 0}
	};
	if (!odr_initmember(o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_choice(o, arm, &(*p)->u, &(*p)->which, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int z_Operator (ODR o, Z_Operator **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 0, Z_Operator_and,
		(Odr_fun) odr_null, "op_and"},
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_Operator_or,
		(Odr_fun) odr_null, "op_or"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_Operator_and_not,
		(Odr_fun) odr_null, "and_not"},
		{ODR_IMPLICIT, ODR_CONTEXT, 3, Z_Operator_prox,
		(Odr_fun) z_ProximityOperator, "prox"},
		{-1, -1, -1, -1, (Odr_fun) 0, 0}
	};
	if (!odr_constructed_begin(o, p, ODR_CONTEXT, 46, 0))
		return odr_missing(o, opt, name);
	if (!odr_initmember(o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_choice(o, arm, &(*p)->u, &(*p)->which, name) &&
		odr_constructed_end(o))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int z_ComplexAttribute (ODR o, Z_ComplexAttribute **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_settag (o, ODR_CONTEXT, 1) &&
		odr_sequence_of(o, (Odr_fun) z_StringOrNumeric, &(*p)->list,
		  &(*p)->num_list, "list") &&
		odr_implicit_settag (o, ODR_CONTEXT, 2) &&
		(odr_sequence_of(o, (Odr_fun) odr_integer, &(*p)->semanticAction,
		  &(*p)->num_semanticAction, "semanticAction") || odr_ok(o)) &&
		odr_sequence_end (o);
}

int z_AttributeElement (ODR o, Z_AttributeElement **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 121, Z_AttributeValue_numeric,
		(Odr_fun) odr_integer, "numeric"},
		{ODR_IMPLICIT, ODR_CONTEXT, 224, Z_AttributeValue_complex,
		(Odr_fun) z_ComplexAttribute, "complex"},
		{-1, -1, -1, -1, (Odr_fun) 0, 0}
	};
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_AttributeSetId,
			&(*p)->attributeSet, ODR_CONTEXT, 1, 1, "attributeSet") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->attributeType, ODR_CONTEXT, 120, 0, "attributeType") &&
		odr_choice (o, arm, &(*p)->value, &(*p)->which, 0) &&
		odr_sequence_end (o);
}

int z_ProximityOperator (ODR o, Z_ProximityOperator **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_ProximityOperator_known,
		(Odr_fun) z_ProxUnit, "known"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_ProximityOperator_private,
		(Odr_fun) odr_integer, "zprivate"},
		{-1, -1, -1, -1, (Odr_fun) 0, 0}
	};
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, odr_bool,
			&(*p)->exclusion, ODR_CONTEXT, 1, 1, "exclusion") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->distance, ODR_CONTEXT, 2, 0, "distance") &&
		odr_implicit_tag (o, odr_bool,
			&(*p)->ordered, ODR_CONTEXT, 3, 0, "ordered") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->relationType, ODR_CONTEXT, 4, 0, "relationType") &&
		odr_constructed_begin (o, &(*p)->u, ODR_CONTEXT, 5, "proximityUnitCode") &&
		odr_choice (o, arm, &(*p)->u, &(*p)->which, 0) &&
		odr_constructed_end (o) &&
		odr_sequence_end (o);
}

int z_ProxUnit (ODR o, Z_ProxUnit **p, int opt, const char *name)
{
	return odr_integer (o, p, opt, name);
}

int z_SearchResponse (ODR o, Z_SearchResponse **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		z_ReferenceId(o, &(*p)->referenceId, 1, "referenceId") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->resultCount, ODR_CONTEXT, 23, 0, "resultCount") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->numberOfRecordsReturned, ODR_CONTEXT, 24, 0, "numberOfRecordsReturned") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->nextResultSetPosition, ODR_CONTEXT, 25, 0, "nextResultSetPosition") &&
		odr_implicit_tag (o, odr_bool,
			&(*p)->searchStatus, ODR_CONTEXT, 22, 0, "searchStatus") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->resultSetStatus, ODR_CONTEXT, 26, 1, "resultSetStatus") &&
		z_PresentStatus(o, &(*p)->presentStatus, 1, "presentStatus") &&
		z_Records(o, &(*p)->records, 1, "records") &&
		odr_implicit_tag (o, z_OtherInformation,
			&(*p)->additionalSearchInfo, ODR_CONTEXT, 203, 1, "additionalSearchInfo") &&
		z_OtherInformation(o, &(*p)->otherInfo, 1, "otherInfo") &&
		odr_sequence_end (o);
}

int z_RecordComposition (ODR o, Z_RecordComposition **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_EXPLICIT, ODR_CONTEXT, 19, Z_RecordComp_simple,
		(Odr_fun) z_ElementSetNames, "simple"},
		{ODR_IMPLICIT, ODR_CONTEXT, 209, Z_RecordComp_complex,
		(Odr_fun) z_CompSpec, "complex"},
		{-1, -1, -1, -1, (Odr_fun) 0, 0}
	};
	if (!odr_initmember(o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_choice(o, arm, &(*p)->u, &(*p)->which, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int z_PresentRequest (ODR o, Z_PresentRequest **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		z_ReferenceId(o, &(*p)->referenceId, 1, "referenceId") &&
		z_ResultSetId(o, &(*p)->resultSetId, 0, "resultSetId") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->resultSetStartPoint, ODR_CONTEXT, 30, 0, "resultSetStartPoint") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->numberOfRecordsRequested, ODR_CONTEXT, 29, 0, "numberOfRecordsRequested") &&
		odr_implicit_settag (o, ODR_CONTEXT, 212) &&
		(odr_sequence_of(o, (Odr_fun) z_Range, &(*p)->additionalRanges,
		  &(*p)->num_ranges, "additionalRanges") || odr_ok(o)) &&
		z_RecordComposition (o, &(*p)->recordComposition, 1, "recordComposition") &&
		odr_implicit_tag (o, odr_oid,
			&(*p)->preferredRecordSyntax, ODR_CONTEXT, 104, 1, "preferredRecordSyntax") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->maxSegmentCount, ODR_CONTEXT, 204, 1, "maxSegmentCount") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->maxRecordSize, ODR_CONTEXT, 206, 1, "maxRecordSize") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->maxSegmentSize, ODR_CONTEXT, 207, 1, "maxSegmentSize") &&
		z_OtherInformation(o, &(*p)->otherInfo, 1, "otherInfo") &&
		odr_sequence_end (o);
}

int z_Segment (ODR o, Z_Segment **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		z_ReferenceId(o, &(*p)->referenceId, 1, "referenceId") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->numberOfRecordsReturned, ODR_CONTEXT, 24, 0, "numberOfRecordsReturned") &&
		odr_implicit_settag (o, ODR_CONTEXT, 0) &&
		odr_sequence_of(o, (Odr_fun) z_NamePlusRecord, &(*p)->segmentRecords,
		  &(*p)->num_segmentRecords, "segmentRecords") &&
		z_OtherInformation(o, &(*p)->otherInfo, 1, "otherInfo") &&
		odr_sequence_end (o);
}

int z_PresentResponse (ODR o, Z_PresentResponse **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		z_ReferenceId(o, &(*p)->referenceId, 1, "referenceId") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->numberOfRecordsReturned, ODR_CONTEXT, 24, 0, "numberOfRecordsReturned") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->nextResultSetPosition, ODR_CONTEXT, 25, 0, "nextResultSetPosition") &&
		z_PresentStatus(o, &(*p)->presentStatus, 0, "presentStatus") &&
		z_Records(o, &(*p)->records, 1, "records") &&
		z_OtherInformation(o, &(*p)->otherInfo, 1, "otherInfo") &&
		odr_sequence_end (o);
}

int z_NamePlusRecordList (ODR o, Z_NamePlusRecordList **p, int opt, const char *name)
{
	if (!odr_initmember (o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_sequence_of (o, (Odr_fun) z_NamePlusRecord, &(*p)->records,
		&(*p)->num_records, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int z_DiagRecs (ODR o, Z_DiagRecs **p, int opt, const char *name)
{
	if (!odr_initmember (o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_sequence_of (o, (Odr_fun) z_DiagRec, &(*p)->diagRecs,
		&(*p)->num_diagRecs, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int z_Records (ODR o, Z_Records **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 28, Z_Records_DBOSD,
		(Odr_fun) z_NamePlusRecordList, "databaseOrSurDiagnostics"},
		{ODR_IMPLICIT, ODR_CONTEXT, 130, Z_Records_NSD,
		(Odr_fun) z_DefaultDiagFormat, "nonSurrogateDiagnostic"},
		{ODR_IMPLICIT, ODR_CONTEXT, 205, Z_Records_multipleNSD,
		(Odr_fun) z_DiagRecs, "multipleNonSurDiagnostics"},
		{-1, -1, -1, -1, (Odr_fun) 0, 0}
	};
	if (!odr_initmember(o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_choice(o, arm, &(*p)->u, &(*p)->which, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int z_NamePlusRecord (ODR o, Z_NamePlusRecord **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_EXPLICIT, ODR_CONTEXT, 1, Z_NamePlusRecord_databaseRecord,
		(Odr_fun) z_External, "databaseRecord"},
		{ODR_EXPLICIT, ODR_CONTEXT, 2, Z_NamePlusRecord_surrogateDiagnostic,
		(Odr_fun) z_DiagRec, "surrogateDiagnostic"},
		{ODR_EXPLICIT, ODR_CONTEXT, 3, Z_NamePlusRecord_startingFragment,
		(Odr_fun) z_FragmentSyntax, "startingFragment"},
		{ODR_EXPLICIT, ODR_CONTEXT, 4, Z_NamePlusRecord_intermediateFragment,
		(Odr_fun) z_FragmentSyntax, "intermediateFragment"},
		{ODR_EXPLICIT, ODR_CONTEXT, 5, Z_NamePlusRecord_finalFragment,
		(Odr_fun) z_FragmentSyntax, "finalFragment"},
		{-1, -1, -1, -1, (Odr_fun) 0, 0}
	};
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_DatabaseName,
			&(*p)->databaseName, ODR_CONTEXT, 0, 1, "databaseName") &&
		odr_constructed_begin (o, &(*p)->u, ODR_CONTEXT, 1, "record") &&
		odr_choice (o, arm, &(*p)->u, &(*p)->which, 0) &&
		odr_constructed_end (o) &&
		odr_sequence_end (o);
}

int z_FragmentSyntax (ODR o, Z_FragmentSyntax **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{-1, -1, -1, Z_FragmentSyntax_externallyTagged,
		 (Odr_fun) z_External, "externallyTagged"},
		{-1, -1, -1, Z_FragmentSyntax_notExternallyTagged,
		 (Odr_fun) odr_octetstring, "notExternallyTagged"},
		{-1, -1, -1, -1, (Odr_fun) 0, 0}
	};
	if (!odr_initmember(o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_choice(o, arm, &(*p)->u, &(*p)->which, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int z_DiagRec (ODR o, Z_DiagRec **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{-1, -1, -1, Z_DiagRec_defaultFormat,
		 (Odr_fun) z_DefaultDiagFormat, "defaultFormat"},
		{-1, -1, -1, Z_DiagRec_externallyDefined,
		 (Odr_fun) z_External, "externallyDefined"},
		{-1, -1, -1, -1, (Odr_fun) 0, 0}
	};
	if (!odr_initmember(o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_choice(o, arm, &(*p)->u, &(*p)->which, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int z_DefaultDiagFormat (ODR o, Z_DefaultDiagFormat **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{-1, -1, -1, Z_DefaultDiagFormat_v2Addinfo,
		 (Odr_fun) odr_visiblestring, "v2Addinfo"},
		{-1, -1, -1, Z_DefaultDiagFormat_v3Addinfo,
		 (Odr_fun) z_InternationalString, "v3Addinfo"},
		{-1, -1, -1, -1, (Odr_fun) 0, 0}
	};
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_oid(o, &(*p)->diagnosticSetId, 0, "diagnosticSetId") &&
		odr_integer(o, &(*p)->condition, 0, "condition") &&
		odr_choice (o, arm, &(*p)->u, &(*p)->which, 0) &&
		odr_sequence_end (o);
}

int z_Range (ODR o, Z_Range **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, odr_integer,
			&(*p)->startingPosition, ODR_CONTEXT, 1, 0, "startingPosition") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->numberOfRecords, ODR_CONTEXT, 2, 0, "numberOfRecords") &&
		odr_sequence_end (o);
}

int z_DatabaseSpecificUnit (ODR o, Z_DatabaseSpecificUnit **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		z_DatabaseName(o, &(*p)->dbName, 0, "dbName") &&
		z_ElementSetName(o, &(*p)->esn, 0, "esn") &&
		odr_sequence_end (o);
}

int z_DatabaseSpecific (ODR o, Z_DatabaseSpecific **p, int opt, const char *name)
{
	if (!odr_initmember (o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_sequence_of (o, (Odr_fun) z_DatabaseSpecificUnit, &(*p)->elements,
		&(*p)->num, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int z_ElementSetNames (ODR o, Z_ElementSetNames **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 0, Z_ElementSetNames_generic,
		(Odr_fun) z_InternationalString, "generic"},
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_ElementSetNames_databaseSpecific,
		(Odr_fun) z_DatabaseSpecific, "databaseSpecific"},
		{-1, -1, -1, -1, (Odr_fun) 0, 0}
	};
	if (!odr_initmember(o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_choice(o, arm, &(*p)->u, &(*p)->which, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int z_PresentStatus (ODR o, Z_PresentStatus **p, int opt, const char *name)
{
	return odr_implicit_tag (o, odr_integer, p, ODR_CONTEXT, 27, opt, name);
}

int z_DbSpecific (ODR o, Z_DbSpecific **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_explicit_tag (o, z_DatabaseName,
			&(*p)->db, ODR_CONTEXT, 1, 0, "db") &&
		odr_implicit_tag (o, z_Specification,
			&(*p)->spec, ODR_CONTEXT, 2, 0, "spec") &&
		odr_sequence_end (o);
}

int z_CompSpec (ODR o, Z_CompSpec **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, odr_bool,
			&(*p)->selectAlternativeSyntax, ODR_CONTEXT, 1, 0, "selectAlternativeSyntax") &&
		odr_implicit_tag (o, z_Specification,
			&(*p)->generic, ODR_CONTEXT, 2, 1, "generic") &&
		odr_implicit_settag (o, ODR_CONTEXT, 3) &&
		(odr_sequence_of(o, (Odr_fun) z_DbSpecific, &(*p)->dbSpecific,
		  &(*p)->num_dbSpecific, "dbSpecific") || odr_ok(o)) &&
		odr_implicit_settag (o, ODR_CONTEXT, 4) &&
		(odr_sequence_of(o, (Odr_fun) odr_oid, &(*p)->recordSyntax,
		  &(*p)->num_recordSyntax, "recordSyntax") || odr_ok(o)) &&
		odr_sequence_end (o);
}

int z_ElementSpec (ODR o, Z_ElementSpec **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_ElementSpec_elementSetName,
		(Odr_fun) z_InternationalString, "elementSetName"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_ElementSpec_externalSpec,
		(Odr_fun) z_External, "externalSpec"},
		{-1, -1, -1, -1, (Odr_fun) 0, 0}
	};
	if (!odr_initmember(o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_choice(o, arm, &(*p)->u, &(*p)->which, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int z_Specification (ODR o, Z_Specification **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_Schema_oid,
		(Odr_fun) odr_oid, "oid"},
		{ODR_IMPLICIT, ODR_CONTEXT, 300, Z_Schema_uri,
		(Odr_fun) z_InternationalString, "uri"},
		{-1, -1, -1, -1, (Odr_fun) 0, 0}
	};
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		(odr_choice (o, arm, &(*p)->schema, &(*p)->which, 0) || odr_ok(o)) &&
		odr_explicit_tag (o, z_ElementSpec,
			&(*p)->elementSpec, ODR_CONTEXT, 2, 1, "elementSpec") &&
		odr_sequence_end (o);
}

int z_DeleteResultSetRequest (ODR o, Z_DeleteResultSetRequest **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		z_ReferenceId(o, &(*p)->referenceId, 1, "referenceId") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->deleteFunction, ODR_CONTEXT, 32, 0, "deleteFunction") &&
		(odr_sequence_of(o, (Odr_fun) z_ResultSetId, &(*p)->resultSetList,
		  &(*p)->num_resultSetList, "resultSetList") || odr_ok(o)) &&
		z_OtherInformation(o, &(*p)->otherInfo, 1, "otherInfo") &&
		odr_sequence_end (o);
}

int z_DeleteResultSetResponse (ODR o, Z_DeleteResultSetResponse **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		z_ReferenceId(o, &(*p)->referenceId, 1, "referenceId") &&
		odr_implicit_tag (o, z_DeleteStatus,
			&(*p)->deleteOperationStatus, ODR_CONTEXT, 0, 0, "deleteOperationStatus") &&
		odr_implicit_tag (o, z_ListStatuses,
			&(*p)->deleteListStatuses, ODR_CONTEXT, 1, 1, "deleteListStatuses") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->numberNotDeleted, ODR_CONTEXT, 34, 1, "numberNotDeleted") &&
		odr_implicit_tag (o, z_ListStatuses,
			&(*p)->bulkStatuses, ODR_CONTEXT, 35, 1, "bulkStatuses") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->deleteMessage, ODR_CONTEXT, 36, 1, "deleteMessage") &&
		z_OtherInformation(o, &(*p)->otherInfo, 1, "otherInfo") &&
		odr_sequence_end (o);
}

int z_ListStatus (ODR o, Z_ListStatus **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		z_ResultSetId(o, &(*p)->id, 0, "id") &&
		z_DeleteStatus(o, &(*p)->status, 0, "status") &&
		odr_sequence_end (o);
}

int z_ListStatuses (ODR o, Z_ListStatuses **p, int opt, const char *name)
{
	if (!odr_initmember (o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_sequence_of (o, (Odr_fun) z_ListStatus, &(*p)->elements,
		&(*p)->num, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int z_DeleteStatus (ODR o, Z_DeleteStatus **p, int opt, const char *name)
{
	return odr_implicit_tag (o, odr_integer, p, ODR_CONTEXT, 33, opt, name);
}

int z_AccessControlRequest (ODR o, Z_AccessControlRequest **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 37, Z_AccessControlRequest_simpleForm,
		(Odr_fun) odr_octetstring, "simpleForm"},
		{ODR_EXPLICIT, ODR_CONTEXT, 0, Z_AccessControlRequest_externallyDefined,
		(Odr_fun) z_External, "externallyDefined"},
		{-1, -1, -1, -1, (Odr_fun) 0, 0}
	};
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		z_ReferenceId(o, &(*p)->referenceId, 1, "referenceId") &&
		odr_choice (o, arm, &(*p)->u, &(*p)->which, 0) &&
		z_OtherInformation(o, &(*p)->otherInfo, 1, "otherInfo") &&
		odr_sequence_end (o);
}

int z_AccessControlResponse (ODR o, Z_AccessControlResponse **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 38, Z_AccessControlResponse_simpleForm,
		(Odr_fun) odr_octetstring, "simpleForm"},
		{ODR_EXPLICIT, ODR_CONTEXT, 0, Z_AccessControlResponse_externallyDefined,
		(Odr_fun) z_External, "externallyDefined"},
		{-1, -1, -1, -1, (Odr_fun) 0, 0}
	};
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		z_ReferenceId(o, &(*p)->referenceId, 1, "referenceId") &&
		(odr_choice (o, arm, &(*p)->u, &(*p)->which, 0) || odr_ok(o)) &&
		odr_explicit_tag (o, z_DiagRec,
			&(*p)->diagnostic, ODR_CONTEXT, 223, 1, "diagnostic") &&
		z_OtherInformation(o, &(*p)->otherInfo, 1, "otherInfo") &&
		odr_sequence_end (o);
}

int z_ResourceControlRequest (ODR o, Z_ResourceControlRequest **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		z_ReferenceId(o, &(*p)->referenceId, 1, "referenceId") &&
		odr_implicit_tag (o, odr_bool,
			&(*p)->suspendedFlag, ODR_CONTEXT, 39, 1, "suspendedFlag") &&
		odr_explicit_tag (o, z_ResourceReport,
			&(*p)->resourceReport, ODR_CONTEXT, 40, 1, "resourceReport") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->partialResultsAvailable, ODR_CONTEXT, 41, 1, "partialResultsAvailable") &&
		odr_implicit_tag (o, odr_bool,
			&(*p)->responseRequired, ODR_CONTEXT, 42, 0, "responseRequired") &&
		odr_implicit_tag (o, odr_bool,
			&(*p)->triggeredRequestFlag, ODR_CONTEXT, 43, 1, "triggeredRequestFlag") &&
		z_OtherInformation(o, &(*p)->otherInfo, 1, "otherInfo") &&
		odr_sequence_end (o);
}

int z_ResourceControlResponse (ODR o, Z_ResourceControlResponse **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		z_ReferenceId(o, &(*p)->referenceId, 1, "referenceId") &&
		odr_implicit_tag (o, odr_bool,
			&(*p)->continueFlag, ODR_CONTEXT, 44, 0, "continueFlag") &&
		odr_implicit_tag (o, odr_bool,
			&(*p)->resultSetWanted, ODR_CONTEXT, 45, 1, "resultSetWanted") &&
		z_OtherInformation(o, &(*p)->otherInfo, 1, "otherInfo") &&
		odr_sequence_end (o);
}

int z_TriggerResourceControlRequest (ODR o, Z_TriggerResourceControlRequest **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		z_ReferenceId(o, &(*p)->referenceId, 1, "referenceId") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->requestedAction, ODR_CONTEXT, 46, 0, "requestedAction") &&
		odr_implicit_tag (o, z_ResourceReportId,
			&(*p)->prefResourceReportFormat, ODR_CONTEXT, 47, 1, "prefResourceReportFormat") &&
		odr_implicit_tag (o, odr_bool,
			&(*p)->resultSetWanted, ODR_CONTEXT, 48, 1, "resultSetWanted") &&
		z_OtherInformation(o, &(*p)->otherInfo, 1, "otherInfo") &&
		odr_sequence_end (o);
}

int z_ResourceReportRequest (ODR o, Z_ResourceReportRequest **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		z_ReferenceId(o, &(*p)->referenceId, 1, "referenceId") &&
		odr_implicit_tag (o, z_ReferenceId,
			&(*p)->opId, ODR_CONTEXT, 210, 1, "opId") &&
		odr_implicit_tag (o, z_ResourceReportId,
			&(*p)->prefResourceReportFormat, ODR_CONTEXT, 49, 1, "prefResourceReportFormat") &&
		z_OtherInformation(o, &(*p)->otherInfo, 1, "otherInfo") &&
		odr_sequence_end (o);
}

int z_ResourceReportResponse (ODR o, Z_ResourceReportResponse **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		z_ReferenceId(o, &(*p)->referenceId, 1, "referenceId") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->resourceReportStatus, ODR_CONTEXT, 50, 0, "resourceReportStatus") &&
		odr_explicit_tag (o, z_ResourceReport,
			&(*p)->resourceReport, ODR_CONTEXT, 51, 1, "resourceReport") &&
		z_OtherInformation(o, &(*p)->otherInfo, 1, "otherInfo") &&
		odr_sequence_end (o);
}

int z_ResourceReport (ODR o, Z_ResourceReport **p, int opt, const char *name)
{
	return z_External (o, p, opt, name);
}

int z_ResourceReportId (ODR o, Z_ResourceReportId **p, int opt, const char *name)
{
	return odr_oid (o, p, opt, name);
}

int z_ScanRequest (ODR o, Z_ScanRequest **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		z_ReferenceId(o, &(*p)->referenceId, 1, "referenceId") &&
		odr_implicit_settag (o, ODR_CONTEXT, 3) &&
		odr_sequence_of(o, (Odr_fun) z_DatabaseName, &(*p)->databaseNames,
		  &(*p)->num_databaseNames, "databaseNames") &&
		z_AttributeSetId(o, &(*p)->attributeSet, 1, "attributeSet") &&
		z_AttributesPlusTerm(o, &(*p)->termListAndStartPoint, 0, "termListAndStartPoint") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->stepSize, ODR_CONTEXT, 5, 1, "stepSize") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->numberOfTermsRequested, ODR_CONTEXT, 6, 0, "numberOfTermsRequested") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->preferredPositionInResponse, ODR_CONTEXT, 7, 1, "preferredPositionInResponse") &&
		z_OtherInformation(o, &(*p)->otherInfo, 1, "otherInfo") &&
		odr_sequence_end (o);
}

int z_ScanResponse (ODR o, Z_ScanResponse **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		z_ReferenceId(o, &(*p)->referenceId, 1, "referenceId") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->stepSize, ODR_CONTEXT, 3, 1, "stepSize") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->scanStatus, ODR_CONTEXT, 4, 0, "scanStatus") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->numberOfEntriesReturned, ODR_CONTEXT, 5, 0, "numberOfEntriesReturned") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->positionOfTerm, ODR_CONTEXT, 6, 1, "positionOfTerm") &&
		odr_implicit_tag (o, z_ListEntries,
			&(*p)->entries, ODR_CONTEXT, 7, 1, "entries") &&
		odr_implicit_tag (o, z_AttributeSetId,
			&(*p)->attributeSet, ODR_CONTEXT, 8, 1, "attributeSet") &&
		z_OtherInformation(o, &(*p)->otherInfo, 1, "otherInfo") &&
		odr_sequence_end (o);
}

int z_ListEntries (ODR o, Z_ListEntries **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_settag (o, ODR_CONTEXT, 1) &&
		(odr_sequence_of(o, (Odr_fun) z_Entry, &(*p)->entries,
		  &(*p)->num_entries, "entries") || odr_ok(o)) &&
		odr_implicit_settag (o, ODR_CONTEXT, 2) &&
		(odr_sequence_of(o, (Odr_fun) z_DiagRec, &(*p)->nonsurrogateDiagnostics,
		  &(*p)->num_nonsurrogateDiagnostics, "nonsurrogateDiagnostics") || odr_ok(o)) &&
		odr_sequence_end (o);
}

int z_Entry (ODR o, Z_Entry **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_Entry_termInfo,
		(Odr_fun) z_TermInfo, "termInfo"},
		{ODR_EXPLICIT, ODR_CONTEXT, 2, Z_Entry_surrogateDiagnostic,
		(Odr_fun) z_DiagRec, "surrogateDiagnostic"},
		{-1, -1, -1, -1, (Odr_fun) 0, 0}
	};
	if (!odr_initmember(o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_choice(o, arm, &(*p)->u, &(*p)->which, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int z_TermInfo (ODR o, Z_TermInfo **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		z_Term(o, &(*p)->term, 0, "term") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->displayTerm, ODR_CONTEXT, 0, 1, "displayTerm") &&
		z_AttributeList(o, &(*p)->suggestedAttributes, 1, "suggestedAttributes") &&
		odr_implicit_settag (o, ODR_CONTEXT, 4) &&
		(odr_sequence_of(o, (Odr_fun) z_AttributesPlusTerm, &(*p)->alternativeTerm,
		  &(*p)->num_alternativeTerm, "alternativeTerm") || odr_ok(o)) &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->globalOccurrences, ODR_CONTEXT, 2, 1, "globalOccurrences") &&
		odr_implicit_tag (o, z_OccurrenceByAttributes,
			&(*p)->byAttributes, ODR_CONTEXT, 3, 1, "byAttributes") &&
		z_OtherInformation(o, &(*p)->otherTermInfo, 1, "otherTermInfo") &&
		odr_sequence_end (o);
}

int z_byDatabaseList_s (ODR o, Z_byDatabaseList_s **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		z_DatabaseName(o, &(*p)->db, 0, "db") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->num, ODR_CONTEXT, 1, 1, "num") &&
		z_OtherInformation(o, &(*p)->otherDbInfo, 1, "otherDbInfo") &&
		odr_sequence_end (o);
}

int z_byDatabaseList (ODR o, Z_byDatabaseList **p, int opt, const char *name)
{
	if (!odr_initmember (o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_sequence_of (o, (Odr_fun) z_byDatabaseList_s, &(*p)->elements,
		&(*p)->num, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int z_OccurrenceByAttributesElem (ODR o, Z_OccurrenceByAttributesElem **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_EXPLICIT, ODR_CONTEXT, 2, Z_OccurrenceByAttributesElem_global,
		(Odr_fun) odr_integer, "global"},
		{ODR_IMPLICIT, ODR_CONTEXT, 3, Z_OccurrenceByAttributesElem_byDatabase,
		(Odr_fun) z_byDatabaseList, "byDatabase"},
		{-1, -1, -1, -1, (Odr_fun) 0, 0}
	};
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_explicit_tag (o, z_AttributeList,
			&(*p)->attributes, ODR_CONTEXT, 1, 0, "attributes") &&
		(odr_choice (o, arm, &(*p)->u, &(*p)->which, 0) || odr_ok(o)) &&
		z_OtherInformation(o, &(*p)->otherOccurInfo, 1, "otherOccurInfo") &&
		odr_sequence_end (o);
}

int z_OccurrenceByAttributes (ODR o, Z_OccurrenceByAttributes **p, int opt, const char *name)
{
	if (!odr_initmember (o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_sequence_of (o, (Odr_fun) z_OccurrenceByAttributesElem, &(*p)->elements,
		&(*p)->num, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int z_SortKeySpecList (ODR o, Z_SortKeySpecList **p, int opt, const char *name)
{
	if (!odr_initmember (o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_sequence_of (o, (Odr_fun) z_SortKeySpec, &(*p)->specs,
		&(*p)->num_specs, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int z_SortRequest (ODR o, Z_SortRequest **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		z_ReferenceId(o, &(*p)->referenceId, 1, "referenceId") &&
		odr_implicit_settag (o, ODR_CONTEXT, 3) &&
		odr_sequence_of(o, (Odr_fun) z_InternationalString, &(*p)->inputResultSetNames,
		  &(*p)->num_inputResultSetNames, "inputResultSetNames") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->sortedResultSetName, ODR_CONTEXT, 4, 0, "sortedResultSetName") &&
		odr_implicit_tag (o, z_SortKeySpecList,
			&(*p)->sortSequence, ODR_CONTEXT, 5, 0, "sortSequence") &&
		z_OtherInformation(o, &(*p)->otherInfo, 1, "otherInfo") &&
		odr_sequence_end (o);
}

int z_SortResponse (ODR o, Z_SortResponse **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		z_ReferenceId(o, &(*p)->referenceId, 1, "referenceId") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->sortStatus, ODR_CONTEXT, 3, 0, "sortStatus") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->resultSetStatus, ODR_CONTEXT, 4, 1, "resultSetStatus") &&
		odr_implicit_settag (o, ODR_CONTEXT, 5) &&
		(odr_sequence_of(o, (Odr_fun) z_DiagRec, &(*p)->diagnostics,
		  &(*p)->num_diagnostics, "diagnostics") || odr_ok(o)) &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->resultCount, ODR_CONTEXT, 6, 1, "resultCount") &&
		z_OtherInformation(o, &(*p)->otherInfo, 1, "otherInfo") &&
		odr_sequence_end (o);
}

int z_SortKeySpec (ODR o, Z_SortKeySpec **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_SortKeySpec_abort,
		(Odr_fun) odr_null, "abort"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_SortKeySpec_null,
		(Odr_fun) odr_null, "null"},
		{ODR_IMPLICIT, ODR_CONTEXT, 3, Z_SortKeySpec_missingValueData,
		(Odr_fun) odr_octetstring, "missingValueData"},
		{-1, -1, -1, -1, (Odr_fun) 0, 0}
	};
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		z_SortElement(o, &(*p)->sortElement, 0, "sortElement") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->sortRelation, ODR_CONTEXT, 1, 0, "sortRelation") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->caseSensitivity, ODR_CONTEXT, 2, 0, "caseSensitivity") &&
		((odr_constructed_begin (o, &(*p)->u, ODR_CONTEXT, 3, "missingValueAction") &&
		odr_choice (o, arm, &(*p)->u, &(*p)->which, 0) &&
		odr_constructed_end (o)) || odr_ok(o)) &&
		odr_sequence_end (o);
}

int z_SortDbSpecificList_s (ODR o, Z_SortDbSpecificList_s **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		z_DatabaseName(o, &(*p)->databaseName, 0, "databaseName") &&
		z_SortKey(o, &(*p)->dbSort, 0, "dbSort") &&
		odr_sequence_end (o);
}

int z_SortDbSpecificList (ODR o, Z_SortDbSpecificList **p, int opt, const char *name)
{
	if (!odr_initmember (o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_sequence_of (o, (Odr_fun) z_SortDbSpecificList_s, &(*p)->elements,
		&(*p)->num, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int z_SortElement (ODR o, Z_SortElement **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_EXPLICIT, ODR_CONTEXT, 1, Z_SortElement_generic,
		(Odr_fun) z_SortKey, "generic"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_SortElement_databaseSpecific,
		(Odr_fun) z_SortDbSpecificList, "databaseSpecific"},
		{-1, -1, -1, -1, (Odr_fun) 0, 0}
	};
	if (!odr_initmember(o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_choice(o, arm, &(*p)->u, &(*p)->which, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int z_SortAttributes (ODR o, Z_SortAttributes **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		z_AttributeSetId(o, &(*p)->id, 0, "id") &&
		z_AttributeList(o, &(*p)->list, 0, "list") &&
		odr_sequence_end (o);
}

int z_SortKey (ODR o, Z_SortKey **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 0, Z_SortKey_sortField,
		(Odr_fun) z_InternationalString, "sortField"},
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_SortKey_elementSpec,
		(Odr_fun) z_Specification, "elementSpec"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_SortKey_sortAttributes,
		(Odr_fun) z_SortAttributes, "sortAttributes"},
		{-1, -1, -1, -1, (Odr_fun) 0, 0}
	};
	if (!odr_initmember(o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_choice(o, arm, &(*p)->u, &(*p)->which, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int z_ExtendedServicesRequest (ODR o, Z_ExtendedServicesRequest **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		z_ReferenceId(o, &(*p)->referenceId, 1, "referenceId") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->function, ODR_CONTEXT, 3, 0, "function") &&
		odr_implicit_tag (o, odr_oid,
			&(*p)->packageType, ODR_CONTEXT, 4, 0, "packageType") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->packageName, ODR_CONTEXT, 5, 1, "packageName") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->userId, ODR_CONTEXT, 6, 1, "userId") &&
		odr_implicit_tag (o, z_IntUnit,
			&(*p)->retentionTime, ODR_CONTEXT, 7, 1, "retentionTime") &&
		odr_implicit_tag (o, z_Permissions,
			&(*p)->permissions, ODR_CONTEXT, 8, 1, "permissions") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->description, ODR_CONTEXT, 9, 1, "description") &&
		odr_implicit_tag (o, z_External,
			&(*p)->taskSpecificParameters, ODR_CONTEXT, 10, 1, "taskSpecificParameters") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->waitAction, ODR_CONTEXT, 11, 0, "waitAction") &&
		z_ElementSetName(o, &(*p)->elements, 1, "elements") &&
		z_OtherInformation(o, &(*p)->otherInfo, 1, "otherInfo") &&
		odr_sequence_end (o);
}

int z_ExtendedServicesResponse (ODR o, Z_ExtendedServicesResponse **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		z_ReferenceId(o, &(*p)->referenceId, 1, "referenceId") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->operationStatus, ODR_CONTEXT, 3, 0, "operationStatus") &&
		odr_implicit_settag (o, ODR_CONTEXT, 4) &&
		(odr_sequence_of(o, (Odr_fun) z_DiagRec, &(*p)->diagnostics,
		  &(*p)->num_diagnostics, "diagnostics") || odr_ok(o)) &&
		odr_implicit_tag (o, z_External,
			&(*p)->taskPackage, ODR_CONTEXT, 5, 1, "taskPackage") &&
		z_OtherInformation(o, &(*p)->otherInfo, 1, "otherInfo") &&
		odr_sequence_end (o);
}

int z_Permissions_s (ODR o, Z_Permissions_s **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->userId, ODR_CONTEXT, 1, 0, "userId") &&
		odr_implicit_settag (o, ODR_CONTEXT, 2) &&
		odr_sequence_of(o, (Odr_fun) odr_integer, &(*p)->allowableFunctions,
		  &(*p)->num_allowableFunctions, "allowableFunctions") &&
		odr_sequence_end (o);
}

int z_Permissions (ODR o, Z_Permissions **p, int opt, const char *name)
{
	if (!odr_initmember (o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_sequence_of (o, (Odr_fun) z_Permissions_s, &(*p)->elements,
		&(*p)->num, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int z_Close (ODR o, Z_Close **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		z_ReferenceId(o, &(*p)->referenceId, 1, "referenceId") &&
		z_CloseReason(o, &(*p)->closeReason, 0, "closeReason") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->diagnosticInformation, ODR_CONTEXT, 3, 1, "diagnosticInformation") &&
		odr_implicit_tag (o, z_ResourceReportId,
			&(*p)->resourceReportFormat, ODR_CONTEXT, 4, 1, "resourceReportFormat") &&
		odr_explicit_tag (o, z_ResourceReport,
			&(*p)->resourceReport, ODR_CONTEXT, 5, 1, "resourceReport") &&
		z_OtherInformation(o, &(*p)->otherInfo, 1, "otherInfo") &&
		odr_sequence_end (o);
}

int z_CloseReason (ODR o, Z_CloseReason **p, int opt, const char *name)
{
	return odr_implicit_tag (o, odr_integer, p, ODR_CONTEXT, 211, opt, name);
}

int z_DuplicateDetectionRequest (ODR o, Z_DuplicateDetectionRequest **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		z_ReferenceId(o, &(*p)->referenceId, 1, "referenceId") &&
		odr_implicit_settag (o, ODR_CONTEXT, 3) &&
		odr_sequence_of(o, (Odr_fun) z_InternationalString, &(*p)->inputResultSetIds,
		  &(*p)->num_inputResultSetIds, "inputResultSetIds") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->outputResultSetName, ODR_CONTEXT, 4, 0, "outputResultSetName") &&
		odr_implicit_tag (o, z_External,
			&(*p)->applicablePortionOfRecord, ODR_CONTEXT, 5, 1, "applicablePortionOfRecord") &&
		odr_implicit_settag (o, ODR_CONTEXT, 6) &&
		(odr_sequence_of(o, (Odr_fun) z_DuplicateDetectionCriterion, &(*p)->duplicateDetectionCriteria,
		  &(*p)->num_duplicateDetectionCriteria, "duplicateDetectionCriteria") || odr_ok(o)) &&
		odr_implicit_tag (o, odr_bool,
			&(*p)->clustering, ODR_CONTEXT, 7, 1, "clustering") &&
		odr_implicit_settag (o, ODR_CONTEXT, 8) &&
		odr_sequence_of(o, (Odr_fun) z_RetentionCriterion, &(*p)->retentionCriteria,
		  &(*p)->num_retentionCriteria, "retentionCriteria") &&
		odr_implicit_settag (o, ODR_CONTEXT, 9) &&
		(odr_sequence_of(o, (Odr_fun) z_SortCriterion, &(*p)->sortCriteria,
		  &(*p)->num_sortCriteria, "sortCriteria") || odr_ok(o)) &&
		z_OtherInformation(o, &(*p)->otherInfo, 1, "otherInfo") &&
		odr_sequence_end (o);
}

int z_DuplicateDetectionCriterion (ODR o, Z_DuplicateDetectionCriterion **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_DuplicateDetectionCriterion_levelOfMatch,
		(Odr_fun) odr_integer, "levelOfMatch"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_DuplicateDetectionCriterion_caseSensitive,
		(Odr_fun) odr_null, "caseSensitive"},
		{ODR_IMPLICIT, ODR_CONTEXT, 3, Z_DuplicateDetectionCriterion_punctuationSensitive,
		(Odr_fun) odr_null, "punctuationSensitive"},
		{ODR_IMPLICIT, ODR_CONTEXT, 4, Z_DuplicateDetectionCriterion_regularExpression,
		(Odr_fun) z_External, "regularExpression"},
		{ODR_IMPLICIT, ODR_CONTEXT, 5, Z_DuplicateDetectionCriterion_rsDuplicates,
		(Odr_fun) odr_null, "rsDuplicates"},
		{-1, -1, -1, -1, (Odr_fun) 0, 0}
	};
	if (!odr_initmember(o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_choice(o, arm, &(*p)->u, &(*p)->which, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int z_RetentionCriterion (ODR o, Z_RetentionCriterion **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_RetentionCriterion_numberOfEntries,
		(Odr_fun) odr_integer, "numberOfEntries"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_RetentionCriterion_percentOfEntries,
		(Odr_fun) odr_integer, "percentOfEntries"},
		{ODR_IMPLICIT, ODR_CONTEXT, 3, Z_RetentionCriterion_duplicatesOnly,
		(Odr_fun) odr_null, "duplicatesOnly"},
		{ODR_IMPLICIT, ODR_CONTEXT, 4, Z_RetentionCriterion_discardRsDuplicates,
		(Odr_fun) odr_null, "discardRsDuplicates"},
		{-1, -1, -1, -1, (Odr_fun) 0, 0}
	};
	if (!odr_initmember(o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_choice(o, arm, &(*p)->u, &(*p)->which, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int z_SortCriterionPreferredDatabases (ODR o, Z_SortCriterionPreferredDatabases **p, int opt, const char *name)
{
	if (!odr_initmember (o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_sequence_of (o, (Odr_fun) z_InternationalString, &(*p)->elements,
		&(*p)->num, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int z_SortCriterion (ODR o, Z_SortCriterion **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_SortCriterion_mostComprehensive,
		(Odr_fun) odr_null, "mostComprehensive"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_SortCriterion_leastConmprehensive,
		(Odr_fun) odr_null, "leastConmprehensive"},
		{ODR_IMPLICIT, ODR_CONTEXT, 3, Z_SortCriterion_mostRecent,
		(Odr_fun) odr_null, "mostRecent"},
		{ODR_IMPLICIT, ODR_CONTEXT, 4, Z_SortCriterion_oldest,
		(Odr_fun) odr_null, "oldest"},
		{ODR_IMPLICIT, ODR_CONTEXT, 5, Z_SortCriterion_leastCost,
		(Odr_fun) odr_null, "leastCost"},
		{ODR_IMPLICIT, ODR_CONTEXT, 6, Z_SortCriterion_preferredDatabases,
		(Odr_fun) z_SortCriterionPreferredDatabases, "preferredDatabases"},
		{-1, -1, -1, -1, (Odr_fun) 0, 0}
	};
	if (!odr_initmember(o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_choice(o, arm, &(*p)->u, &(*p)->which, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int z_DuplicateDetectionResponse (ODR o, Z_DuplicateDetectionResponse **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		z_ReferenceId(o, &(*p)->referenceId, 1, "referenceId") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->status, ODR_CONTEXT, 3, 0, "status") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->resultSetCount, ODR_CONTEXT, 4, 1, "resultSetCount") &&
		odr_implicit_settag (o, ODR_CONTEXT, 5) &&
		(odr_sequence_of(o, (Odr_fun) z_DiagRec, &(*p)->diagnostics,
		  &(*p)->num_diagnostics, "diagnostics") || odr_ok(o)) &&
		z_OtherInformation(o, &(*p)->otherInfo, 1, "otherInfo") &&
		odr_sequence_end (o);
}

int z_ReferenceId (ODR o, Z_ReferenceId **p, int opt, const char *name)
{
	return odr_implicit_tag (o, odr_octetstring, p, ODR_CONTEXT, 2, opt, name);
}

int z_ResultSetId (ODR o, Z_ResultSetId **p, int opt, const char *name)
{
	return odr_implicit_tag (o, z_InternationalString, p, ODR_CONTEXT, 31, opt, name);
}

int z_ElementSetName (ODR o, Z_ElementSetName **p, int opt, const char *name)
{
	return odr_implicit_tag (o, z_InternationalString, p, ODR_CONTEXT, 103, opt, name);
}

int z_DatabaseName (ODR o, Z_DatabaseName **p, int opt, const char *name)
{
	return odr_implicit_tag (o, z_InternationalString, p, ODR_CONTEXT, 105, opt, name);
}

int z_AttributeSetId (ODR o, Z_AttributeSetId **p, int opt, const char *name)
{
	return odr_oid (o, p, opt, name);
}

int z_OtherInformationUnit (ODR o, Z_OtherInformationUnit **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_OtherInfo_characterInfo,
		(Odr_fun) z_InternationalString, "characterInfo"},
		{ODR_IMPLICIT, ODR_CONTEXT, 3, Z_OtherInfo_binaryInfo,
		(Odr_fun) odr_octetstring, "binaryInfo"},
		{ODR_IMPLICIT, ODR_CONTEXT, 4, Z_OtherInfo_externallyDefinedInfo,
		(Odr_fun) z_External, "externallyDefinedInfo"},
		{ODR_IMPLICIT, ODR_CONTEXT, 5, Z_OtherInfo_oid,
		(Odr_fun) odr_oid, "oid"},
		{-1, -1, -1, -1, (Odr_fun) 0, 0}
	};
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_InfoCategory,
			&(*p)->category, ODR_CONTEXT, 1, 1, "category") &&
		odr_choice (o, arm, &(*p)->information, &(*p)->which, 0) &&
		odr_sequence_end (o);
}

int z_OtherInformation (ODR o, Z_OtherInformation **p, int opt, const char *name)
{
	if (!odr_initmember (o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	odr_implicit_settag (o, ODR_CONTEXT, 201);
	if (odr_sequence_of (o, (Odr_fun) z_OtherInformationUnit, &(*p)->list,
		&(*p)->num_elements, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int z_InfoCategory (ODR o, Z_InfoCategory **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, odr_oid,
			&(*p)->categoryTypeId, ODR_CONTEXT, 1, 1, "categoryTypeId") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->categoryValue, ODR_CONTEXT, 2, 0, "categoryValue") &&
		odr_sequence_end (o);
}

int z_IntUnit (ODR o, Z_IntUnit **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, odr_integer,
			&(*p)->value, ODR_CONTEXT, 1, 0, "value") &&
		odr_implicit_tag (o, z_Unit,
			&(*p)->unitUsed, ODR_CONTEXT, 2, 0, "unitUsed") &&
		odr_sequence_end (o);
}

int z_Unit (ODR o, Z_Unit **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_explicit_tag (o, z_InternationalString,
			&(*p)->unitSystem, ODR_CONTEXT, 1, 1, "unitSystem") &&
		odr_explicit_tag (o, z_StringOrNumeric,
			&(*p)->unitType, ODR_CONTEXT, 2, 1, "unitType") &&
		odr_explicit_tag (o, z_StringOrNumeric,
			&(*p)->unit, ODR_CONTEXT, 3, 1, "unit") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->scaleFactor, ODR_CONTEXT, 4, 1, "scaleFactor") &&
		odr_sequence_end (o);
}

int z_InternationalString (ODR o, Z_InternationalString **p, int opt, const char *name)
{
	return odr_generalstring (o, p, opt, name);
}

int z_StringOrNumeric (ODR o, Z_StringOrNumeric **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_StringOrNumeric_string,
		(Odr_fun) z_InternationalString, "string"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_StringOrNumeric_numeric,
		(Odr_fun) odr_integer, "numeric"},
		{-1, -1, -1, -1, (Odr_fun) 0, 0}
	};
	if (!odr_initmember(o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_choice(o, arm, &(*p)->u, &(*p)->which, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}


/* the type-0 query ... */
int z_ANY_type_0 (ODR o, void **p, int opt)
{
    return 0;
}


