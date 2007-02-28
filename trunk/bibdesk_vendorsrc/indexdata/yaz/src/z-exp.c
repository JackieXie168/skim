/** \file z-exp.c
    \brief ASN.1 Module RecordSyntax-explain

    Generated automatically by YAZ ASN.1 Compiler 0.4
*/

#include <yaz/z-exp.h>

int z_ExplainRecord (ODR o, Z_ExplainRecord **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 0, Z_Explain_targetInfo,
		(Odr_fun) z_TargetInfo, "targetInfo"},
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_Explain_databaseInfo,
		(Odr_fun) z_DatabaseInfo, "databaseInfo"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_Explain_schemaInfo,
		(Odr_fun) z_SchemaInfo, "schemaInfo"},
		{ODR_IMPLICIT, ODR_CONTEXT, 3, Z_Explain_tagSetInfo,
		(Odr_fun) z_TagSetInfo, "tagSetInfo"},
		{ODR_IMPLICIT, ODR_CONTEXT, 4, Z_Explain_recordSyntaxInfo,
		(Odr_fun) z_RecordSyntaxInfo, "recordSyntaxInfo"},
		{ODR_IMPLICIT, ODR_CONTEXT, 5, Z_Explain_attributeSetInfo,
		(Odr_fun) z_AttributeSetInfo, "attributeSetInfo"},
		{ODR_IMPLICIT, ODR_CONTEXT, 6, Z_Explain_termListInfo,
		(Odr_fun) z_TermListInfo, "termListInfo"},
		{ODR_IMPLICIT, ODR_CONTEXT, 7, Z_Explain_extendedServicesInfo,
		(Odr_fun) z_ExtendedServicesInfo, "extendedServicesInfo"},
		{ODR_IMPLICIT, ODR_CONTEXT, 8, Z_Explain_attributeDetails,
		(Odr_fun) z_AttributeDetails, "attributeDetails"},
		{ODR_IMPLICIT, ODR_CONTEXT, 9, Z_Explain_termListDetails,
		(Odr_fun) z_TermListDetails, "termListDetails"},
		{ODR_IMPLICIT, ODR_CONTEXT, 10, Z_Explain_elementSetDetails,
		(Odr_fun) z_ElementSetDetails, "elementSetDetails"},
		{ODR_IMPLICIT, ODR_CONTEXT, 11, Z_Explain_retrievalRecordDetails,
		(Odr_fun) z_RetrievalRecordDetails, "retrievalRecordDetails"},
		{ODR_IMPLICIT, ODR_CONTEXT, 12, Z_Explain_sortDetails,
		(Odr_fun) z_SortDetails, "sortDetails"},
		{ODR_IMPLICIT, ODR_CONTEXT, 13, Z_Explain_processing,
		(Odr_fun) z_ProcessingInformation, "processing"},
		{ODR_IMPLICIT, ODR_CONTEXT, 14, Z_Explain_variants,
		(Odr_fun) z_VariantSetInfo, "variants"},
		{ODR_IMPLICIT, ODR_CONTEXT, 15, Z_Explain_units,
		(Odr_fun) z_UnitInfo, "units"},
		{ODR_IMPLICIT, ODR_CONTEXT, 100, Z_Explain_categoryList,
		(Odr_fun) z_CategoryList, "categoryList"},
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

int z_TargetInfo (ODR o, Z_TargetInfo **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_CommonInfo,
			&(*p)->commonInfo, ODR_CONTEXT, 0, 1, "commonInfo") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->name, ODR_CONTEXT, 1, 0, "name") &&
		odr_implicit_tag (o, z_HumanString,
			&(*p)->recentNews, ODR_CONTEXT, 2, 1, "recentNews") &&
		odr_implicit_tag (o, z_IconObject,
			&(*p)->icon, ODR_CONTEXT, 3, 1, "icon") &&
		odr_implicit_tag (o, odr_bool,
			&(*p)->namedResultSets, ODR_CONTEXT, 4, 0, "namedResultSets") &&
		odr_implicit_tag (o, odr_bool,
			&(*p)->multipleDBsearch, ODR_CONTEXT, 5, 0, "multipleDBsearch") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->maxResultSets, ODR_CONTEXT, 6, 1, "maxResultSets") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->maxResultSize, ODR_CONTEXT, 7, 1, "maxResultSize") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->maxTerms, ODR_CONTEXT, 8, 1, "maxTerms") &&
		odr_implicit_tag (o, z_IntUnit,
			&(*p)->timeoutInterval, ODR_CONTEXT, 9, 1, "timeoutInterval") &&
		odr_implicit_tag (o, z_HumanString,
			&(*p)->welcomeMessage, ODR_CONTEXT, 10, 1, "welcomeMessage") &&
		odr_implicit_tag (o, z_ContactInfo,
			&(*p)->contactInfo, ODR_CONTEXT, 11, 1, "contactInfo") &&
		odr_implicit_tag (o, z_HumanString,
			&(*p)->description, ODR_CONTEXT, 12, 1, "description") &&
		odr_implicit_settag (o, ODR_CONTEXT, 13) &&
		(odr_sequence_of(o, (Odr_fun) z_InternationalString, &(*p)->nicknames,
		  &(*p)->num_nicknames, "nicknames") || odr_ok(o)) &&
		odr_implicit_tag (o, z_HumanString,
			&(*p)->usageRest, ODR_CONTEXT, 14, 1, "usageRest") &&
		odr_implicit_tag (o, z_HumanString,
			&(*p)->paymentAddr, ODR_CONTEXT, 15, 1, "paymentAddr") &&
		odr_implicit_tag (o, z_HumanString,
			&(*p)->hours, ODR_CONTEXT, 16, 1, "hours") &&
		odr_implicit_settag (o, ODR_CONTEXT, 17) &&
		(odr_sequence_of(o, (Odr_fun) z_DatabaseList, &(*p)->dbCombinations,
		  &(*p)->num_dbCombinations, "dbCombinations") || odr_ok(o)) &&
		odr_implicit_settag (o, ODR_CONTEXT, 18) &&
		(odr_sequence_of(o, (Odr_fun) z_NetworkAddress, &(*p)->addresses,
		  &(*p)->num_addresses, "addresses") || odr_ok(o)) &&
		odr_implicit_settag (o, ODR_CONTEXT, 101) &&
		(odr_sequence_of(o, (Odr_fun) z_InternationalString, &(*p)->languages,
		  &(*p)->num_languages, "languages") || odr_ok(o)) &&
		odr_implicit_tag (o, z_AccessInfo,
			&(*p)->commonAccessInfo, ODR_CONTEXT, 19, 1, "commonAccessInfo") &&
		odr_sequence_end (o);
}

int z_DatabaseInfo (ODR o, Z_DatabaseInfo **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 0, Z_DatabaseInfo_actualNumber,
		(Odr_fun) odr_integer, "actualNumber"},
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_DatabaseInfo_approxNumber,
		(Odr_fun) odr_integer, "approxNumber"},
		{-1, -1, -1, -1, (Odr_fun) 0, 0}
	};
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_CommonInfo,
			&(*p)->commonInfo, ODR_CONTEXT, 0, 1, "commonInfo") &&
		odr_implicit_tag (o, z_DatabaseName,
			&(*p)->name, ODR_CONTEXT, 1, 0, "name") &&
		odr_implicit_tag (o, odr_null,
			&(*p)->explainDatabase, ODR_CONTEXT, 2, 1, "explainDatabase") &&
		odr_implicit_settag (o, ODR_CONTEXT, 3) &&
		(odr_sequence_of(o, (Odr_fun) z_DatabaseName, &(*p)->nicknames,
		  &(*p)->num_nicknames, "nicknames") || odr_ok(o)) &&
		odr_implicit_tag (o, z_IconObject,
			&(*p)->icon, ODR_CONTEXT, 4, 1, "icon") &&
		odr_implicit_tag (o, odr_bool,
			&(*p)->userFee, ODR_CONTEXT, 5, 0, "userFee") &&
		odr_implicit_tag (o, odr_bool,
			&(*p)->available, ODR_CONTEXT, 6, 0, "available") &&
		odr_implicit_tag (o, z_HumanString,
			&(*p)->titleString, ODR_CONTEXT, 7, 1, "titleString") &&
		odr_implicit_settag (o, ODR_CONTEXT, 8) &&
		(odr_sequence_of(o, (Odr_fun) z_HumanString, &(*p)->keywords,
		  &(*p)->num_keywords, "keywords") || odr_ok(o)) &&
		odr_implicit_tag (o, z_HumanString,
			&(*p)->description, ODR_CONTEXT, 9, 1, "description") &&
		odr_implicit_tag (o, z_DatabaseList,
			&(*p)->associatedDbs, ODR_CONTEXT, 10, 1, "associatedDbs") &&
		odr_implicit_tag (o, z_DatabaseList,
			&(*p)->subDbs, ODR_CONTEXT, 11, 1, "subDbs") &&
		odr_implicit_tag (o, z_HumanString,
			&(*p)->disclaimers, ODR_CONTEXT, 12, 1, "disclaimers") &&
		odr_implicit_tag (o, z_HumanString,
			&(*p)->news, ODR_CONTEXT, 13, 1, "news") &&
		((odr_constructed_begin (o, &(*p)->u, ODR_CONTEXT, 14, "recordCount") &&
		odr_choice (o, arm, &(*p)->u, &(*p)->which, 0) &&
		odr_constructed_end (o)) || odr_ok(o)) &&
		odr_implicit_tag (o, z_HumanString,
			&(*p)->defaultOrder, ODR_CONTEXT, 15, 1, "defaultOrder") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->avRecordSize, ODR_CONTEXT, 16, 1, "avRecordSize") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->maxRecordSize, ODR_CONTEXT, 17, 1, "maxRecordSize") &&
		odr_implicit_tag (o, z_HumanString,
			&(*p)->hours, ODR_CONTEXT, 18, 1, "hours") &&
		odr_implicit_tag (o, z_HumanString,
			&(*p)->bestTime, ODR_CONTEXT, 19, 1, "bestTime") &&
		odr_implicit_tag (o, odr_generalizedtime,
			&(*p)->lastUpdate, ODR_CONTEXT, 20, 1, "lastUpdate") &&
		odr_implicit_tag (o, z_IntUnit,
			&(*p)->updateInterval, ODR_CONTEXT, 21, 1, "updateInterval") &&
		odr_implicit_tag (o, z_HumanString,
			&(*p)->coverage, ODR_CONTEXT, 22, 1, "coverage") &&
		odr_implicit_tag (o, odr_bool,
			&(*p)->proprietary, ODR_CONTEXT, 23, 1, "proprietary") &&
		odr_implicit_tag (o, z_HumanString,
			&(*p)->copyrightText, ODR_CONTEXT, 24, 1, "copyrightText") &&
		odr_implicit_tag (o, z_HumanString,
			&(*p)->copyrightNotice, ODR_CONTEXT, 25, 1, "copyrightNotice") &&
		odr_implicit_tag (o, z_ContactInfo,
			&(*p)->producerContactInfo, ODR_CONTEXT, 26, 1, "producerContactInfo") &&
		odr_implicit_tag (o, z_ContactInfo,
			&(*p)->supplierContactInfo, ODR_CONTEXT, 27, 1, "supplierContactInfo") &&
		odr_implicit_tag (o, z_ContactInfo,
			&(*p)->submissionContactInfo, ODR_CONTEXT, 28, 1, "submissionContactInfo") &&
		odr_implicit_tag (o, z_AccessInfo,
			&(*p)->accessInfo, ODR_CONTEXT, 29, 1, "accessInfo") &&
		odr_sequence_end (o);
}

int z_TagTypeMapping (ODR o, Z_TagTypeMapping **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, odr_integer,
			&(*p)->tagType, ODR_CONTEXT, 0, 0, "tagType") &&
		odr_implicit_tag (o, odr_oid,
			&(*p)->tagSet, ODR_CONTEXT, 1, 1, "tagSet") &&
		odr_implicit_tag (o, odr_null,
			&(*p)->defaultTagType, ODR_CONTEXT, 2, 1, "defaultTagType") &&
		odr_sequence_end (o);
}

int z_SchemaInfo (ODR o, Z_SchemaInfo **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_CommonInfo,
			&(*p)->commonInfo, ODR_CONTEXT, 0, 1, "commonInfo") &&
		odr_implicit_tag (o, odr_oid,
			&(*p)->schema, ODR_CONTEXT, 1, 0, "schema") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->name, ODR_CONTEXT, 2, 0, "name") &&
		odr_implicit_tag (o, z_HumanString,
			&(*p)->description, ODR_CONTEXT, 3, 1, "description") &&
		odr_implicit_settag (o, ODR_CONTEXT, 4) &&
		(odr_sequence_of(o, (Odr_fun) z_TagTypeMapping, &(*p)->tagTypeMapping,
		  &(*p)->num_tagTypeMapping, "tagTypeMapping") || odr_ok(o)) &&
		odr_implicit_settag (o, ODR_CONTEXT, 5) &&
		(odr_sequence_of(o, (Odr_fun) z_ElementInfo, &(*p)->recordStructure,
		  &(*p)->num_recordStructure, "recordStructure") || odr_ok(o)) &&
		odr_sequence_end (o);
}

int z_ElementInfo (ODR o, Z_ElementInfo **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->elementName, ODR_CONTEXT, 1, 0, "elementName") &&
		odr_implicit_tag (o, z_Path,
			&(*p)->elementTagPath, ODR_CONTEXT, 2, 0, "elementTagPath") &&
		odr_explicit_tag (o, z_ElementDataType,
			&(*p)->dataType, ODR_CONTEXT, 3, 1, "dataType") &&
		odr_implicit_tag (o, odr_bool,
			&(*p)->required, ODR_CONTEXT, 4, 0, "required") &&
		odr_implicit_tag (o, odr_bool,
			&(*p)->repeatable, ODR_CONTEXT, 5, 0, "repeatable") &&
		odr_implicit_tag (o, z_HumanString,
			&(*p)->description, ODR_CONTEXT, 6, 1, "description") &&
		odr_sequence_end (o);
}

int z_PathUnit (ODR o, Z_PathUnit **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, odr_integer,
			&(*p)->tagType, ODR_CONTEXT, 1, 0, "tagType") &&
		odr_explicit_tag (o, z_StringOrNumeric,
			&(*p)->tagValue, ODR_CONTEXT, 2, 0, "tagValue") &&
		odr_sequence_end (o);
}

int z_Path (ODR o, Z_Path **p, int opt, const char *name)
{
	if (!odr_initmember (o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_sequence_of (o, (Odr_fun) z_PathUnit, &(*p)->elements,
		&(*p)->num, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int z_ElementInfoList (ODR o, Z_ElementInfoList **p, int opt, const char *name)
{
	if (!odr_initmember (o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_sequence_of (o, (Odr_fun) z_ElementInfo, &(*p)->elements,
		&(*p)->num, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int z_ElementDataType (ODR o, Z_ElementDataType **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 0, Z_ElementDataType_primitive,
		(Odr_fun) z_PrimitiveDataType, "primitive"},
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_ElementDataType_structured,
		(Odr_fun) z_ElementInfoList, "structured"},
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

int z_PrimitiveDataType (ODR o, Z_PrimitiveDataType **p, int opt, const char *name)
{
	return odr_integer (o, p, opt, name);
}

int z_TagSetElements (ODR o, Z_TagSetElements **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->elementname, ODR_CONTEXT, 1, 0, "elementname") &&
		odr_implicit_settag (o, ODR_CONTEXT, 2) &&
		(odr_sequence_of(o, (Odr_fun) z_InternationalString, &(*p)->nicknames,
		  &(*p)->num_nicknames, "nicknames") || odr_ok(o)) &&
		odr_explicit_tag (o, z_StringOrNumeric,
			&(*p)->elementTag, ODR_CONTEXT, 3, 0, "elementTag") &&
		odr_implicit_tag (o, z_HumanString,
			&(*p)->description, ODR_CONTEXT, 4, 1, "description") &&
		odr_explicit_tag (o, z_PrimitiveDataType,
			&(*p)->dataType, ODR_CONTEXT, 5, 1, "dataType") &&
		z_OtherInformation(o, &(*p)->otherTagInfo, 1, "otherTagInfo") &&
		odr_sequence_end (o);
}

int z_TagSetInfo (ODR o, Z_TagSetInfo **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_CommonInfo,
			&(*p)->commonInfo, ODR_CONTEXT, 0, 1, "commonInfo") &&
		odr_implicit_tag (o, odr_oid,
			&(*p)->tagSet, ODR_CONTEXT, 1, 0, "tagSet") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->name, ODR_CONTEXT, 2, 0, "name") &&
		odr_implicit_tag (o, z_HumanString,
			&(*p)->description, ODR_CONTEXT, 3, 1, "description") &&
		odr_implicit_settag (o, ODR_CONTEXT, 4) &&
		(odr_sequence_of(o, (Odr_fun) z_TagSetElements, &(*p)->elements,
		  &(*p)->num_elements, "elements") || odr_ok(o)) &&
		odr_sequence_end (o);
}

int z_RecordSyntaxInfo (ODR o, Z_RecordSyntaxInfo **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_CommonInfo,
			&(*p)->commonInfo, ODR_CONTEXT, 0, 1, "commonInfo") &&
		odr_implicit_tag (o, odr_oid,
			&(*p)->recordSyntax, ODR_CONTEXT, 1, 0, "recordSyntax") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->name, ODR_CONTEXT, 2, 0, "name") &&
		odr_implicit_settag (o, ODR_CONTEXT, 3) &&
		(odr_sequence_of(o, (Odr_fun) odr_oid, &(*p)->transferSyntaxes,
		  &(*p)->num_transferSyntaxes, "transferSyntaxes") || odr_ok(o)) &&
		odr_implicit_tag (o, z_HumanString,
			&(*p)->description, ODR_CONTEXT, 4, 1, "description") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->asn1Module, ODR_CONTEXT, 5, 1, "asn1Module") &&
		odr_implicit_settag (o, ODR_CONTEXT, 6) &&
		(odr_sequence_of(o, (Odr_fun) z_ElementInfo, &(*p)->abstractStructure,
		  &(*p)->num_abstractStructure, "abstractStructure") || odr_ok(o)) &&
		odr_sequence_end (o);
}

int z_AttributeSetInfo (ODR o, Z_AttributeSetInfo **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_CommonInfo,
			&(*p)->commonInfo, ODR_CONTEXT, 0, 1, "commonInfo") &&
		odr_implicit_tag (o, z_AttributeSetId,
			&(*p)->attributeSet, ODR_CONTEXT, 1, 0, "attributeSet") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->name, ODR_CONTEXT, 2, 0, "name") &&
		odr_implicit_settag (o, ODR_CONTEXT, 3) &&
		(odr_sequence_of(o, (Odr_fun) z_AttributeType, &(*p)->attributes,
		  &(*p)->num_attributes, "attributes") || odr_ok(o)) &&
		odr_implicit_tag (o, z_HumanString,
			&(*p)->description, ODR_CONTEXT, 4, 1, "description") &&
		odr_sequence_end (o);
}

int z_AttributeType (ODR o, Z_AttributeType **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->name, ODR_CONTEXT, 0, 1, "name") &&
		odr_implicit_tag (o, z_HumanString,
			&(*p)->description, ODR_CONTEXT, 1, 1, "description") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->attributeType, ODR_CONTEXT, 2, 0, "attributeType") &&
		odr_implicit_settag (o, ODR_CONTEXT, 3) &&
		odr_sequence_of(o, (Odr_fun) z_AttributeDescription, &(*p)->attributeValues,
		  &(*p)->num_attributeValues, "attributeValues") &&
		odr_sequence_end (o);
}

int z_AttributeDescription (ODR o, Z_AttributeDescription **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->name, ODR_CONTEXT, 0, 1, "name") &&
		odr_implicit_tag (o, z_HumanString,
			&(*p)->description, ODR_CONTEXT, 1, 1, "description") &&
		odr_explicit_tag (o, z_StringOrNumeric,
			&(*p)->attributeValue, ODR_CONTEXT, 2, 0, "attributeValue") &&
		odr_implicit_settag (o, ODR_CONTEXT, 3) &&
		(odr_sequence_of(o, (Odr_fun) z_StringOrNumeric, &(*p)->equivalentAttributes,
		  &(*p)->num_equivalentAttributes, "equivalentAttributes") || odr_ok(o)) &&
		odr_sequence_end (o);
}

int z_TermListElement (ODR o, Z_TermListElement **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->name, ODR_CONTEXT, 1, 0, "name") &&
		odr_implicit_tag (o, z_HumanString,
			&(*p)->title, ODR_CONTEXT, 2, 1, "title") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->searchCost, ODR_CONTEXT, 3, 1, "searchCost") &&
		odr_implicit_tag (o, odr_bool,
			&(*p)->scanable, ODR_CONTEXT, 4, 0, "scanable") &&
		odr_implicit_settag (o, ODR_CONTEXT, 5) &&
		(odr_sequence_of(o, (Odr_fun) z_InternationalString, &(*p)->broader,
		  &(*p)->num_broader, "broader") || odr_ok(o)) &&
		odr_implicit_settag (o, ODR_CONTEXT, 6) &&
		(odr_sequence_of(o, (Odr_fun) z_InternationalString, &(*p)->narrower,
		  &(*p)->num_narrower, "narrower") || odr_ok(o)) &&
		odr_sequence_end (o);
}

int z_TermListInfo (ODR o, Z_TermListInfo **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_CommonInfo,
			&(*p)->commonInfo, ODR_CONTEXT, 0, 1, "commonInfo") &&
		odr_implicit_tag (o, z_DatabaseName,
			&(*p)->databaseName, ODR_CONTEXT, 1, 0, "databaseName") &&
		odr_implicit_settag (o, ODR_CONTEXT, 2) &&
		odr_sequence_of(o, (Odr_fun) z_TermListElement, &(*p)->termLists,
		  &(*p)->num_termLists, "termLists") &&
		odr_sequence_end (o);
}

int z_ExtendedServicesInfo (ODR o, Z_ExtendedServicesInfo **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_CommonInfo,
			&(*p)->commonInfo, ODR_CONTEXT, 0, 1, "commonInfo") &&
		odr_implicit_tag (o, odr_oid,
			&(*p)->type, ODR_CONTEXT, 1, 0, "type") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->name, ODR_CONTEXT, 2, 1, "name") &&
		odr_implicit_tag (o, odr_bool,
			&(*p)->privateType, ODR_CONTEXT, 3, 0, "privateType") &&
		odr_implicit_tag (o, odr_bool,
			&(*p)->restrictionsApply, ODR_CONTEXT, 5, 0, "restrictionsApply") &&
		odr_implicit_tag (o, odr_bool,
			&(*p)->feeApply, ODR_CONTEXT, 6, 0, "feeApply") &&
		odr_implicit_tag (o, odr_bool,
			&(*p)->available, ODR_CONTEXT, 7, 0, "available") &&
		odr_implicit_tag (o, odr_bool,
			&(*p)->retentionSupported, ODR_CONTEXT, 8, 0, "retentionSupported") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->waitAction, ODR_CONTEXT, 9, 0, "waitAction") &&
		odr_implicit_tag (o, z_HumanString,
			&(*p)->description, ODR_CONTEXT, 10, 1, "description") &&
		odr_implicit_tag (o, z_External,
			&(*p)->specificExplain, ODR_CONTEXT, 11, 1, "specificExplain") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->esASN, ODR_CONTEXT, 12, 1, "esASN") &&
		odr_sequence_end (o);
}

int z_AttributeDetails (ODR o, Z_AttributeDetails **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_CommonInfo,
			&(*p)->commonInfo, ODR_CONTEXT, 0, 1, "commonInfo") &&
		odr_implicit_tag (o, z_DatabaseName,
			&(*p)->databaseName, ODR_CONTEXT, 1, 0, "databaseName") &&
		odr_implicit_settag (o, ODR_CONTEXT, 2) &&
		(odr_sequence_of(o, (Odr_fun) z_AttributeSetDetails, &(*p)->attributesBySet,
		  &(*p)->num_attributesBySet, "attributesBySet") || odr_ok(o)) &&
		odr_implicit_tag (o, z_AttributeCombinations,
			&(*p)->attributeCombinations, ODR_CONTEXT, 3, 1, "attributeCombinations") &&
		odr_sequence_end (o);
}

int z_AttributeSetDetails (ODR o, Z_AttributeSetDetails **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_AttributeSetId,
			&(*p)->attributeSet, ODR_CONTEXT, 0, 0, "attributeSet") &&
		odr_implicit_settag (o, ODR_CONTEXT, 1) &&
		odr_sequence_of(o, (Odr_fun) z_AttributeTypeDetails, &(*p)->attributesByType,
		  &(*p)->num_attributesByType, "attributesByType") &&
		odr_sequence_end (o);
}

int z_AttributeTypeDetails (ODR o, Z_AttributeTypeDetails **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, odr_integer,
			&(*p)->attributeType, ODR_CONTEXT, 0, 0, "attributeType") &&
		odr_implicit_tag (o, z_OmittedAttributeInterpretation,
			&(*p)->defaultIfOmitted, ODR_CONTEXT, 1, 1, "defaultIfOmitted") &&
		odr_implicit_settag (o, ODR_CONTEXT, 2) &&
		(odr_sequence_of(o, (Odr_fun) z_AttributeValue, &(*p)->attributeValues,
		  &(*p)->num_attributeValues, "attributeValues") || odr_ok(o)) &&
		odr_sequence_end (o);
}

int z_OmittedAttributeInterpretation (ODR o, Z_OmittedAttributeInterpretation **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_explicit_tag (o, z_StringOrNumeric,
			&(*p)->defaultValue, ODR_CONTEXT, 0, 1, "defaultValue") &&
		odr_implicit_tag (o, z_HumanString,
			&(*p)->defaultDescription, ODR_CONTEXT, 1, 1, "defaultDescription") &&
		odr_sequence_end (o);
}

int z_AttributeValue (ODR o, Z_AttributeValue **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_explicit_tag (o, z_StringOrNumeric,
			&(*p)->value, ODR_CONTEXT, 0, 0, "value") &&
		odr_implicit_tag (o, z_HumanString,
			&(*p)->description, ODR_CONTEXT, 1, 1, "description") &&
		odr_implicit_settag (o, ODR_CONTEXT, 2) &&
		(odr_sequence_of(o, (Odr_fun) z_StringOrNumeric, &(*p)->subAttributes,
		  &(*p)->num_subAttributes, "subAttributes") || odr_ok(o)) &&
		odr_implicit_settag (o, ODR_CONTEXT, 3) &&
		(odr_sequence_of(o, (Odr_fun) z_StringOrNumeric, &(*p)->superAttributes,
		  &(*p)->num_superAttributes, "superAttributes") || odr_ok(o)) &&
		odr_implicit_tag (o, odr_null,
			&(*p)->partialSupport, ODR_CONTEXT, 4, 1, "partialSupport") &&
		odr_sequence_end (o);
}

int z_EScanInfo (ODR o, Z_EScanInfo **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, odr_integer,
			&(*p)->maxStepSize, ODR_CONTEXT, 0, 1, "maxStepSize") &&
		odr_implicit_tag (o, z_HumanString,
			&(*p)->collatingSequence, ODR_CONTEXT, 1, 1, "collatingSequence") &&
		odr_implicit_tag (o, odr_bool,
			&(*p)->increasing, ODR_CONTEXT, 2, 1, "increasing") &&
		odr_sequence_end (o);
}

int z_TermListDetails (ODR o, Z_TermListDetails **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_CommonInfo,
			&(*p)->commonInfo, ODR_CONTEXT, 0, 1, "commonInfo") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->termListName, ODR_CONTEXT, 1, 0, "termListName") &&
		odr_implicit_tag (o, z_HumanString,
			&(*p)->description, ODR_CONTEXT, 2, 1, "description") &&
		odr_implicit_tag (o, z_AttributeCombinations,
			&(*p)->attributes, ODR_CONTEXT, 3, 1, "attributes") &&
		odr_implicit_tag (o, z_EScanInfo,
			&(*p)->scanInfo, ODR_CONTEXT, 4, 1, "scanInfo") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->estNumberTerms, ODR_CONTEXT, 5, 1, "estNumberTerms") &&
		odr_implicit_settag (o, ODR_CONTEXT, 6) &&
		(odr_sequence_of(o, (Odr_fun) z_Term, &(*p)->sampleTerms,
		  &(*p)->num_sampleTerms, "sampleTerms") || odr_ok(o)) &&
		odr_sequence_end (o);
}

int z_ElementSetDetails (ODR o, Z_ElementSetDetails **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_CommonInfo,
			&(*p)->commonInfo, ODR_CONTEXT, 0, 1, "commonInfo") &&
		odr_implicit_tag (o, z_DatabaseName,
			&(*p)->databaseName, ODR_CONTEXT, 1, 0, "databaseName") &&
		odr_implicit_tag (o, z_ElementSetName,
			&(*p)->elementSetName, ODR_CONTEXT, 2, 0, "elementSetName") &&
		odr_implicit_tag (o, odr_oid,
			&(*p)->recordSyntax, ODR_CONTEXT, 3, 0, "recordSyntax") &&
		odr_implicit_tag (o, odr_oid,
			&(*p)->schema, ODR_CONTEXT, 4, 0, "schema") &&
		odr_implicit_tag (o, z_HumanString,
			&(*p)->description, ODR_CONTEXT, 5, 1, "description") &&
		odr_implicit_settag (o, ODR_CONTEXT, 6) &&
		(odr_sequence_of(o, (Odr_fun) z_PerElementDetails, &(*p)->detailsPerElement,
		  &(*p)->num_detailsPerElement, "detailsPerElement") || odr_ok(o)) &&
		odr_sequence_end (o);
}

int z_RetrievalRecordDetails (ODR o, Z_RetrievalRecordDetails **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_CommonInfo,
			&(*p)->commonInfo, ODR_CONTEXT, 0, 1, "commonInfo") &&
		odr_implicit_tag (o, z_DatabaseName,
			&(*p)->databaseName, ODR_CONTEXT, 1, 0, "databaseName") &&
		odr_implicit_tag (o, odr_oid,
			&(*p)->schema, ODR_CONTEXT, 2, 0, "schema") &&
		odr_implicit_tag (o, odr_oid,
			&(*p)->recordSyntax, ODR_CONTEXT, 3, 0, "recordSyntax") &&
		odr_implicit_tag (o, z_HumanString,
			&(*p)->description, ODR_CONTEXT, 4, 1, "description") &&
		odr_implicit_settag (o, ODR_CONTEXT, 5) &&
		(odr_sequence_of(o, (Odr_fun) z_PerElementDetails, &(*p)->detailsPerElement,
		  &(*p)->num_detailsPerElement, "detailsPerElement") || odr_ok(o)) &&
		odr_sequence_end (o);
}

int z_PerElementDetails (ODR o, Z_PerElementDetails **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->name, ODR_CONTEXT, 0, 1, "name") &&
		odr_implicit_tag (o, z_RecordTag,
			&(*p)->recordTag, ODR_CONTEXT, 1, 1, "recordTag") &&
		odr_implicit_settag (o, ODR_CONTEXT, 2) &&
		(odr_sequence_of(o, (Odr_fun) z_Path, &(*p)->schemaTags,
		  &(*p)->num_schemaTags, "schemaTags") || odr_ok(o)) &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->maxSize, ODR_CONTEXT, 3, 1, "maxSize") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->minSize, ODR_CONTEXT, 4, 1, "minSize") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->avgSize, ODR_CONTEXT, 5, 1, "avgSize") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->fixedSize, ODR_CONTEXT, 6, 1, "fixedSize") &&
		odr_implicit_tag (o, odr_bool,
			&(*p)->repeatable, ODR_CONTEXT, 8, 0, "repeatable") &&
		odr_implicit_tag (o, odr_bool,
			&(*p)->required, ODR_CONTEXT, 9, 0, "required") &&
		odr_implicit_tag (o, z_HumanString,
			&(*p)->description, ODR_CONTEXT, 12, 1, "description") &&
		odr_implicit_tag (o, z_HumanString,
			&(*p)->contents, ODR_CONTEXT, 13, 1, "contents") &&
		odr_implicit_tag (o, z_HumanString,
			&(*p)->billingInfo, ODR_CONTEXT, 14, 1, "billingInfo") &&
		odr_implicit_tag (o, z_HumanString,
			&(*p)->restrictions, ODR_CONTEXT, 15, 1, "restrictions") &&
		odr_implicit_settag (o, ODR_CONTEXT, 16) &&
		(odr_sequence_of(o, (Odr_fun) z_InternationalString, &(*p)->alternateNames,
		  &(*p)->num_alternateNames, "alternateNames") || odr_ok(o)) &&
		odr_implicit_settag (o, ODR_CONTEXT, 17) &&
		(odr_sequence_of(o, (Odr_fun) z_InternationalString, &(*p)->genericNames,
		  &(*p)->num_genericNames, "genericNames") || odr_ok(o)) &&
		odr_implicit_tag (o, z_AttributeCombinations,
			&(*p)->searchAccess, ODR_CONTEXT, 18, 1, "searchAccess") &&
		odr_sequence_end (o);
}

int z_RecordTag (ODR o, Z_RecordTag **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_explicit_tag (o, z_StringOrNumeric,
			&(*p)->qualifier, ODR_CONTEXT, 0, 1, "qualifier") &&
		odr_explicit_tag (o, z_StringOrNumeric,
			&(*p)->tagValue, ODR_CONTEXT, 1, 0, "tagValue") &&
		odr_sequence_end (o);
}

int z_SortDetails (ODR o, Z_SortDetails **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_CommonInfo,
			&(*p)->commonInfo, ODR_CONTEXT, 0, 1, "commonInfo") &&
		odr_implicit_tag (o, z_DatabaseName,
			&(*p)->databaseName, ODR_CONTEXT, 1, 0, "databaseName") &&
		odr_implicit_settag (o, ODR_CONTEXT, 2) &&
		(odr_sequence_of(o, (Odr_fun) z_SortKeyDetails, &(*p)->sortKeys,
		  &(*p)->num_sortKeys, "sortKeys") || odr_ok(o)) &&
		odr_sequence_end (o);
}

int z_SortKeyDetails (ODR o, Z_SortKeyDetails **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 0, Z_SortKeyDetails_character,
		(Odr_fun) odr_null, "character"},
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_SortKeyDetails_numeric,
		(Odr_fun) odr_null, "numeric"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_SortKeyDetails_structured,
		(Odr_fun) z_HumanString, "structured"},
		{-1, -1, -1, -1, (Odr_fun) 0, 0}
	};
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_HumanString,
			&(*p)->description, ODR_CONTEXT, 0, 1, "description") &&
		odr_implicit_settag (o, ODR_CONTEXT, 1) &&
		(odr_sequence_of(o, (Odr_fun) z_Specification, &(*p)->elementSpecifications,
		  &(*p)->num_elementSpecifications, "elementSpecifications") || odr_ok(o)) &&
		odr_implicit_tag (o, z_AttributeCombinations,
			&(*p)->attributeSpecifications, ODR_CONTEXT, 2, 1, "attributeSpecifications") &&
		((odr_constructed_begin (o, &(*p)->u, ODR_CONTEXT, 3, "sortType") &&
		odr_choice (o, arm, &(*p)->u, &(*p)->which, 0) &&
		odr_constructed_end (o)) || odr_ok(o)) &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->caseSensitivity, ODR_CONTEXT, 4, 1, "caseSensitivity") &&
		odr_sequence_end (o);
}

int z_ProcessingInformation (ODR o, Z_ProcessingInformation **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_CommonInfo,
			&(*p)->commonInfo, ODR_CONTEXT, 0, 1, "commonInfo") &&
		odr_implicit_tag (o, z_DatabaseName,
			&(*p)->databaseName, ODR_CONTEXT, 1, 0, "databaseName") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->processingContext, ODR_CONTEXT, 2, 0, "processingContext") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->name, ODR_CONTEXT, 3, 0, "name") &&
		odr_implicit_tag (o, odr_oid,
			&(*p)->oid, ODR_CONTEXT, 4, 0, "oid") &&
		odr_implicit_tag (o, z_HumanString,
			&(*p)->description, ODR_CONTEXT, 5, 1, "description") &&
		odr_implicit_tag (o, z_External,
			&(*p)->instructions, ODR_CONTEXT, 6, 1, "instructions") &&
		odr_sequence_end (o);
}

int z_VariantSetInfo (ODR o, Z_VariantSetInfo **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_CommonInfo,
			&(*p)->commonInfo, ODR_CONTEXT, 0, 1, "commonInfo") &&
		odr_implicit_tag (o, odr_oid,
			&(*p)->variantSet, ODR_CONTEXT, 1, 0, "variantSet") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->name, ODR_CONTEXT, 2, 0, "name") &&
		odr_implicit_settag (o, ODR_CONTEXT, 3) &&
		(odr_sequence_of(o, (Odr_fun) z_VariantClass, &(*p)->variants,
		  &(*p)->num_variants, "variants") || odr_ok(o)) &&
		odr_sequence_end (o);
}

int z_VariantClass (ODR o, Z_VariantClass **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->name, ODR_CONTEXT, 0, 1, "name") &&
		odr_implicit_tag (o, z_HumanString,
			&(*p)->description, ODR_CONTEXT, 1, 1, "description") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->variantClass, ODR_CONTEXT, 2, 0, "variantClass") &&
		odr_implicit_settag (o, ODR_CONTEXT, 3) &&
		odr_sequence_of(o, (Odr_fun) z_VariantType, &(*p)->variantTypes,
		  &(*p)->num_variantTypes, "variantTypes") &&
		odr_sequence_end (o);
}

int z_VariantType (ODR o, Z_VariantType **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->name, ODR_CONTEXT, 0, 1, "name") &&
		odr_implicit_tag (o, z_HumanString,
			&(*p)->description, ODR_CONTEXT, 1, 1, "description") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->variantType, ODR_CONTEXT, 2, 0, "variantType") &&
		odr_implicit_tag (o, z_VariantValue,
			&(*p)->variantValue, ODR_CONTEXT, 3, 1, "variantValue") &&
		odr_sequence_end (o);
}

int z_VariantValue (ODR o, Z_VariantValue **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_explicit_tag (o, z_PrimitiveDataType,
			&(*p)->dataType, ODR_CONTEXT, 0, 0, "dataType") &&
		odr_explicit_tag (o, z_ValueSet,
			&(*p)->values, ODR_CONTEXT, 1, 1, "values") &&
		odr_sequence_end (o);
}

int z_ValueSetEnumerated (ODR o, Z_ValueSetEnumerated **p, int opt, const char *name)
{
	if (!odr_initmember (o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_sequence_of (o, (Odr_fun) z_ValueDescription, &(*p)->elements,
		&(*p)->num, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int z_ValueSet (ODR o, Z_ValueSet **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 0, Z_ValueSet_range,
		(Odr_fun) z_ValueRange, "range"},
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_ValueSet_enumerated,
		(Odr_fun) z_ValueSetEnumerated, "enumerated"},
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

int z_ValueRange (ODR o, Z_ValueRange **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_explicit_tag (o, z_ValueDescription,
			&(*p)->lower, ODR_CONTEXT, 0, 1, "lower") &&
		odr_explicit_tag (o, z_ValueDescription,
			&(*p)->upper, ODR_CONTEXT, 1, 1, "upper") &&
		odr_sequence_end (o);
}

int z_ValueDescription (ODR o, Z_ValueDescription **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{-1, -1, -1, Z_ValueDescription_integer,
		 (Odr_fun) odr_integer, "integer"},
		{-1, -1, -1, Z_ValueDescription_string,
		 (Odr_fun) z_InternationalString, "string"},
		{-1, -1, -1, Z_ValueDescription_octets,
		 (Odr_fun) odr_octetstring, "octets"},
		{-1, -1, -1, Z_ValueDescription_oid,
		 (Odr_fun) odr_oid, "oid"},
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_ValueDescription_unit,
		(Odr_fun) z_Unit, "unit"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_ValueDescription_valueAndUnit,
		(Odr_fun) z_IntUnit, "valueAndUnit"},
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

int z_UnitInfo (ODR o, Z_UnitInfo **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_CommonInfo,
			&(*p)->commonInfo, ODR_CONTEXT, 0, 1, "commonInfo") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->unitSystem, ODR_CONTEXT, 1, 0, "unitSystem") &&
		odr_implicit_tag (o, z_HumanString,
			&(*p)->description, ODR_CONTEXT, 2, 1, "description") &&
		odr_implicit_settag (o, ODR_CONTEXT, 3) &&
		(odr_sequence_of(o, (Odr_fun) z_UnitType, &(*p)->units,
		  &(*p)->num_units, "units") || odr_ok(o)) &&
		odr_sequence_end (o);
}

int z_UnitType (ODR o, Z_UnitType **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->name, ODR_CONTEXT, 0, 1, "name") &&
		odr_implicit_tag (o, z_HumanString,
			&(*p)->description, ODR_CONTEXT, 1, 1, "description") &&
		odr_explicit_tag (o, z_StringOrNumeric,
			&(*p)->unitType, ODR_CONTEXT, 2, 0, "unitType") &&
		odr_implicit_settag (o, ODR_CONTEXT, 3) &&
		odr_sequence_of(o, (Odr_fun) z_Units, &(*p)->units,
		  &(*p)->num_units, "units") &&
		odr_sequence_end (o);
}

int z_Units (ODR o, Z_Units **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->name, ODR_CONTEXT, 0, 1, "name") &&
		odr_implicit_tag (o, z_HumanString,
			&(*p)->description, ODR_CONTEXT, 1, 1, "description") &&
		odr_explicit_tag (o, z_StringOrNumeric,
			&(*p)->unit, ODR_CONTEXT, 2, 0, "unit") &&
		odr_sequence_end (o);
}

int z_CategoryList (ODR o, Z_CategoryList **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_CommonInfo,
			&(*p)->commonInfo, ODR_CONTEXT, 0, 1, "commonInfo") &&
		odr_implicit_settag (o, ODR_CONTEXT, 1) &&
		odr_sequence_of(o, (Odr_fun) z_CategoryInfo, &(*p)->categories,
		  &(*p)->num_categories, "categories") &&
		odr_sequence_end (o);
}

int z_CategoryInfo (ODR o, Z_CategoryInfo **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->category, ODR_CONTEXT, 1, 0, "category") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->originalCategory, ODR_CONTEXT, 2, 1, "originalCategory") &&
		odr_implicit_tag (o, z_HumanString,
			&(*p)->description, ODR_CONTEXT, 3, 1, "description") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->asn1Module, ODR_CONTEXT, 4, 1, "asn1Module") &&
		odr_sequence_end (o);
}

int z_CommonInfo (ODR o, Z_CommonInfo **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, odr_generalizedtime,
			&(*p)->dateAdded, ODR_CONTEXT, 0, 1, "dateAdded") &&
		odr_implicit_tag (o, odr_generalizedtime,
			&(*p)->dateChanged, ODR_CONTEXT, 1, 1, "dateChanged") &&
		odr_implicit_tag (o, odr_generalizedtime,
			&(*p)->expiry, ODR_CONTEXT, 2, 1, "expiry") &&
		odr_implicit_tag (o, z_LanguageCode,
			&(*p)->humanStringLanguage, ODR_CONTEXT, 3, 1, "humanStringLanguage") &&
		z_OtherInformation(o, &(*p)->otherInfo, 1, "otherInfo") &&
		odr_sequence_end (o);
}

int z_HumanStringUnit (ODR o, Z_HumanStringUnit **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_LanguageCode,
			&(*p)->language, ODR_CONTEXT, 0, 1, "language") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->text, ODR_CONTEXT, 1, 0, "text") &&
		odr_sequence_end (o);
}

int z_HumanString (ODR o, Z_HumanString **p, int opt, const char *name)
{
	if (!odr_initmember (o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_sequence_of (o, (Odr_fun) z_HumanStringUnit, &(*p)->strings,
		&(*p)->num_strings, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int z_IconObjectUnit (ODR o, Z_IconObjectUnit **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_IconObjectUnit_ianaType,
		(Odr_fun) z_InternationalString, "ianaType"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_IconObjectUnit_z3950type,
		(Odr_fun) z_InternationalString, "z3950type"},
		{ODR_IMPLICIT, ODR_CONTEXT, 3, Z_IconObjectUnit_otherType,
		(Odr_fun) z_InternationalString, "otherType"},
		{-1, -1, -1, -1, (Odr_fun) 0, 0}
	};
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_constructed_begin (o, &(*p)->u, ODR_CONTEXT, 1, "bodyType") &&
		odr_choice (o, arm, &(*p)->u, &(*p)->which, 0) &&
		odr_constructed_end (o) &&
		odr_implicit_tag (o, odr_octetstring,
			&(*p)->content, ODR_CONTEXT, 2, 0, "content") &&
		odr_sequence_end (o);
}

int z_IconObject (ODR o, Z_IconObject **p, int opt, const char *name)
{
	if (!odr_initmember (o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_sequence_of (o, (Odr_fun) z_IconObjectUnit, &(*p)->elements,
		&(*p)->num, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int z_LanguageCode (ODR o, Z_LanguageCode **p, int opt, const char *name)
{
	return z_InternationalString (o, p, opt, name);
}

int z_ContactInfo (ODR o, Z_ContactInfo **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->name, ODR_CONTEXT, 0, 1, "name") &&
		odr_implicit_tag (o, z_HumanString,
			&(*p)->description, ODR_CONTEXT, 1, 1, "description") &&
		odr_implicit_tag (o, z_HumanString,
			&(*p)->address, ODR_CONTEXT, 2, 1, "address") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->email, ODR_CONTEXT, 3, 1, "email") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->phone, ODR_CONTEXT, 4, 1, "phone") &&
		odr_sequence_end (o);
}

int z_NetworkAddressIA (ODR o, Z_NetworkAddressIA **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->hostAddress, ODR_CONTEXT, 0, 0, "hostAddress") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->port, ODR_CONTEXT, 1, 0, "port") &&
		odr_sequence_end (o);
}

int z_NetworkAddressOPA (ODR o, Z_NetworkAddressOPA **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->pSel, ODR_CONTEXT, 0, 0, "pSel") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->sSel, ODR_CONTEXT, 1, 1, "sSel") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->tSel, ODR_CONTEXT, 2, 1, "tSel") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->nSap, ODR_CONTEXT, 3, 0, "nSap") &&
		odr_sequence_end (o);
}

int z_NetworkAddressOther (ODR o, Z_NetworkAddressOther **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->type, ODR_CONTEXT, 0, 0, "type") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->address, ODR_CONTEXT, 1, 0, "address") &&
		odr_sequence_end (o);
}

int z_NetworkAddress (ODR o, Z_NetworkAddress **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 0, Z_NetworkAddress_iA,
		(Odr_fun) z_NetworkAddressIA, "internetAddress"},
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_NetworkAddress_oPA,
		(Odr_fun) z_NetworkAddressOPA, "osiPresentationAddress"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_NetworkAddress_other,
		(Odr_fun) z_NetworkAddressOther, "other"},
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

int z_AccessInfo (ODR o, Z_AccessInfo **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_settag (o, ODR_CONTEXT, 0) &&
		(odr_sequence_of(o, (Odr_fun) z_QueryTypeDetails, &(*p)->queryTypesSupported,
		  &(*p)->num_queryTypesSupported, "queryTypesSupported") || odr_ok(o)) &&
		odr_implicit_settag (o, ODR_CONTEXT, 1) &&
		(odr_sequence_of(o, (Odr_fun) odr_oid, &(*p)->diagnosticsSets,
		  &(*p)->num_diagnosticsSets, "diagnosticsSets") || odr_ok(o)) &&
		odr_implicit_settag (o, ODR_CONTEXT, 2) &&
		(odr_sequence_of(o, (Odr_fun) z_AttributeSetId, &(*p)->attributeSetIds,
		  &(*p)->num_attributeSetIds, "attributeSetIds") || odr_ok(o)) &&
		odr_implicit_settag (o, ODR_CONTEXT, 3) &&
		(odr_sequence_of(o, (Odr_fun) odr_oid, &(*p)->schemas,
		  &(*p)->num_schemas, "schemas") || odr_ok(o)) &&
		odr_implicit_settag (o, ODR_CONTEXT, 4) &&
		(odr_sequence_of(o, (Odr_fun) odr_oid, &(*p)->recordSyntaxes,
		  &(*p)->num_recordSyntaxes, "recordSyntaxes") || odr_ok(o)) &&
		odr_implicit_settag (o, ODR_CONTEXT, 5) &&
		(odr_sequence_of(o, (Odr_fun) odr_oid, &(*p)->resourceChallenges,
		  &(*p)->num_resourceChallenges, "resourceChallenges") || odr_ok(o)) &&
		odr_implicit_tag (o, z_AccessRestrictions,
			&(*p)->restrictedAccess, ODR_CONTEXT, 6, 1, "restrictedAccess") &&
		odr_implicit_tag (o, z_Costs,
			&(*p)->costInfo, ODR_CONTEXT, 8, 1, "costInfo") &&
		odr_implicit_settag (o, ODR_CONTEXT, 9) &&
		(odr_sequence_of(o, (Odr_fun) odr_oid, &(*p)->variantSets,
		  &(*p)->num_variantSets, "variantSets") || odr_ok(o)) &&
		odr_implicit_settag (o, ODR_CONTEXT, 10) &&
		(odr_sequence_of(o, (Odr_fun) z_ElementSetName, &(*p)->elementSetNames,
		  &(*p)->num_elementSetNames, "elementSetNames") || odr_ok(o)) &&
		odr_implicit_settag (o, ODR_CONTEXT, 11) &&
		odr_sequence_of(o, (Odr_fun) z_InternationalString, &(*p)->unitSystems,
		  &(*p)->num_unitSystems, "unitSystems") &&
		odr_sequence_end (o);
}

int z_QueryTypeDetails (ODR o, Z_QueryTypeDetails **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 0, Z_QueryTypeDetails_private,
		(Odr_fun) z_PrivateCapabilities, "zprivate"},
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_QueryTypeDetails_rpn,
		(Odr_fun) z_RpnCapabilities, "rpn"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_QueryTypeDetails_iso8777,
		(Odr_fun) z_Iso8777Capabilities, "iso8777"},
		{ODR_IMPLICIT, ODR_CONTEXT, 100, Z_QueryTypeDetails_z39_58,
		(Odr_fun) z_HumanString, "z39_58"},
		{ODR_IMPLICIT, ODR_CONTEXT, 101, Z_QueryTypeDetails_erpn,
		(Odr_fun) z_RpnCapabilities, "erpn"},
		{ODR_IMPLICIT, ODR_CONTEXT, 102, Z_QueryTypeDetails_rankedList,
		(Odr_fun) z_HumanString, "rankedList"},
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

int z_PrivateCapOperator (ODR o, Z_PrivateCapOperator **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->roperator, ODR_CONTEXT, 0, 0, "roperator") &&
		odr_implicit_tag (o, z_HumanString,
			&(*p)->description, ODR_CONTEXT, 1, 1, "description") &&
		odr_sequence_end (o);
}

int z_PrivateCapabilities (ODR o, Z_PrivateCapabilities **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_settag (o, ODR_CONTEXT, 0) &&
		(odr_sequence_of(o, (Odr_fun) z_PrivateCapOperator, &(*p)->operators,
		  &(*p)->num_operators, "operators") || odr_ok(o)) &&
		odr_implicit_settag (o, ODR_CONTEXT, 1) &&
		(odr_sequence_of(o, (Odr_fun) z_SearchKey, &(*p)->searchKeys,
		  &(*p)->num_searchKeys, "searchKeys") || odr_ok(o)) &&
		odr_implicit_settag (o, ODR_CONTEXT, 2) &&
		(odr_sequence_of(o, (Odr_fun) z_HumanString, &(*p)->description,
		  &(*p)->num_description, "description") || odr_ok(o)) &&
		odr_sequence_end (o);
}

int z_RpnCapabilities (ODR o, Z_RpnCapabilities **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_settag (o, ODR_CONTEXT, 0) &&
		(odr_sequence_of(o, (Odr_fun) odr_integer, &(*p)->operators,
		  &(*p)->num_operators, "operators") || odr_ok(o)) &&
		odr_implicit_tag (o, odr_bool,
			&(*p)->resultSetAsOperandSupported, ODR_CONTEXT, 1, 0, "resultSetAsOperandSupported") &&
		odr_implicit_tag (o, odr_bool,
			&(*p)->restrictionOperandSupported, ODR_CONTEXT, 2, 0, "restrictionOperandSupported") &&
		odr_implicit_tag (o, z_ProximitySupport,
			&(*p)->proximity, ODR_CONTEXT, 3, 1, "proximity") &&
		odr_sequence_end (o);
}

int z_Iso8777Capabilities (ODR o, Z_Iso8777Capabilities **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_settag (o, ODR_CONTEXT, 0) &&
		odr_sequence_of(o, (Odr_fun) z_SearchKey, &(*p)->searchKeys,
		  &(*p)->num_searchKeys, "searchKeys") &&
		odr_implicit_tag (o, z_HumanString,
			&(*p)->restrictions, ODR_CONTEXT, 1, 1, "restrictions") &&
		odr_sequence_end (o);
}

int z_ProxSupportPrivate (ODR o, Z_ProxSupportPrivate **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, odr_integer,
			&(*p)->unit, ODR_CONTEXT, 0, 0, "unit") &&
		odr_explicit_tag (o, z_HumanString,
			&(*p)->description, ODR_CONTEXT, 1, 1, "description") &&
		odr_sequence_end (o);
}

int z_ProxSupportUnit (ODR o, Z_ProxSupportUnit **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_ProxSupportUnit_known,
		(Odr_fun) odr_integer, "known"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_ProxSupportUnit_private,
		(Odr_fun) z_ProxSupportPrivate, "zprivate"},
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

int z_ProximitySupport (ODR o, Z_ProximitySupport **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, odr_bool,
			&(*p)->anySupport, ODR_CONTEXT, 0, 0, "anySupport") &&
		odr_implicit_settag (o, ODR_CONTEXT, 1) &&
		(odr_sequence_of(o, (Odr_fun) z_ProxSupportUnit, &(*p)->unitsSupported,
		  &(*p)->num_unitsSupported, "unitsSupported") || odr_ok(o)) &&
		odr_sequence_end (o);
}

int z_SearchKey (ODR o, Z_SearchKey **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->searchKey, ODR_CONTEXT, 0, 0, "searchKey") &&
		odr_implicit_tag (o, z_HumanString,
			&(*p)->description, ODR_CONTEXT, 1, 1, "description") &&
		odr_sequence_end (o);
}

int z_AccessRestrictionsUnit (ODR o, Z_AccessRestrictionsUnit **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_explicit_tag (o, odr_integer,
			&(*p)->accessType, ODR_CONTEXT, 0, 0, "accessType") &&
		odr_implicit_tag (o, z_HumanString,
			&(*p)->accessText, ODR_CONTEXT, 1, 1, "accessText") &&
		odr_implicit_settag (o, ODR_CONTEXT, 2) &&
		(odr_sequence_of(o, (Odr_fun) odr_oid, &(*p)->accessChallenges,
		  &(*p)->num_accessChallenges, "accessChallenges") || odr_ok(o)) &&
		odr_sequence_end (o);
}

int z_AccessRestrictions (ODR o, Z_AccessRestrictions **p, int opt, const char *name)
{
	if (!odr_initmember (o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_sequence_of (o, (Odr_fun) z_AccessRestrictionsUnit, &(*p)->elements,
		&(*p)->num, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int z_CostsOtherCharge (ODR o, Z_CostsOtherCharge **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_HumanString,
			&(*p)->forWhat, ODR_CONTEXT, 1, 0, "forWhat") &&
		odr_implicit_tag (o, z_Charge,
			&(*p)->charge, ODR_CONTEXT, 2, 0, "charge") &&
		odr_sequence_end (o);
}

int z_Costs (ODR o, Z_Costs **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_Charge,
			&(*p)->connectCharge, ODR_CONTEXT, 0, 1, "connectCharge") &&
		odr_implicit_tag (o, z_Charge,
			&(*p)->connectTime, ODR_CONTEXT, 1, 1, "connectTime") &&
		odr_implicit_tag (o, z_Charge,
			&(*p)->displayCharge, ODR_CONTEXT, 2, 1, "displayCharge") &&
		odr_implicit_tag (o, z_Charge,
			&(*p)->searchCharge, ODR_CONTEXT, 3, 1, "searchCharge") &&
		odr_implicit_tag (o, z_Charge,
			&(*p)->subscriptCharge, ODR_CONTEXT, 4, 1, "subscriptCharge") &&
		odr_implicit_settag (o, ODR_CONTEXT, 5) &&
		(odr_sequence_of(o, (Odr_fun) z_CostsOtherCharge, &(*p)->otherCharges,
		  &(*p)->num_otherCharges, "otherCharges") || odr_ok(o)) &&
		odr_sequence_end (o);
}

int z_Charge (ODR o, Z_Charge **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_IntUnit,
			&(*p)->cost, ODR_CONTEXT, 1, 0, "cost") &&
		odr_implicit_tag (o, z_Unit,
			&(*p)->perWhat, ODR_CONTEXT, 2, 1, "perWhat") &&
		odr_implicit_tag (o, z_HumanString,
			&(*p)->text, ODR_CONTEXT, 3, 1, "text") &&
		odr_sequence_end (o);
}

int z_DatabaseList (ODR o, Z_DatabaseList **p, int opt, const char *name)
{
	if (!odr_initmember (o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_sequence_of (o, (Odr_fun) z_DatabaseName, &(*p)->databases,
		&(*p)->num_databases, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int z_AttributeCombinations (ODR o, Z_AttributeCombinations **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_AttributeSetId,
			&(*p)->defaultAttributeSet, ODR_CONTEXT, 0, 0, "defaultAttributeSet") &&
		odr_implicit_settag (o, ODR_CONTEXT, 1) &&
		odr_sequence_of(o, (Odr_fun) z_AttributeCombination, &(*p)->legalCombinations,
		  &(*p)->num_legalCombinations, "legalCombinations") &&
		odr_sequence_end (o);
}

int z_AttributeCombination (ODR o, Z_AttributeCombination **p, int opt, const char *name)
{
	if (!odr_initmember (o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_sequence_of (o, (Odr_fun) z_AttributeOccurrence, &(*p)->occurrences,
		&(*p)->num_occurrences, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int z_AttributeValueList (ODR o, Z_AttributeValueList **p, int opt, const char *name)
{
	if (!odr_initmember (o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_sequence_of (o, (Odr_fun) z_StringOrNumeric, &(*p)->attributes,
		&(*p)->num_attributes, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int z_AttributeOccurrence (ODR o, Z_AttributeOccurrence **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 3, Z_AttributeOcc_any_or_none,
		(Odr_fun) odr_null, "any_or_none"},
		{ODR_IMPLICIT, ODR_CONTEXT, 4, Z_AttributeOcc_specific,
		(Odr_fun) z_AttributeValueList, "specific"},
		{-1, -1, -1, -1, (Odr_fun) 0, 0}
	};
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_AttributeSetId,
			&(*p)->attributeSet, ODR_CONTEXT, 0, 1, "attributeSet") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->attributeType, ODR_CONTEXT, 1, 0, "attributeType") &&
		odr_implicit_tag (o, odr_null,
			&(*p)->mustBeSupplied, ODR_CONTEXT, 2, 1, "mustBeSupplied") &&
		odr_choice (o, arm, &(*p)->attributeValues, &(*p)->which, 0) &&
		odr_sequence_end (o);
}
