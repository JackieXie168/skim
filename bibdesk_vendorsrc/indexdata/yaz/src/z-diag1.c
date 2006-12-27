/** \file z-diag1.c
    \brief ASN.1 Module DiagnosticFormatDiag1

    Generated automatically by YAZ ASN.1 Compiler 0.4
*/

#include <yaz/z-diag1.h>

int z_DiagnosticFormat_s (ODR o, Z_DiagnosticFormat_s **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_DiagnosticFormat_s_defaultDiagRec,
		(Odr_fun) z_DefaultDiagFormat, "defaultDiagRec"},
		{ODR_EXPLICIT, ODR_CONTEXT, 2, Z_DiagnosticFormat_s_explicitDiagnostic,
		(Odr_fun) z_DiagFormat, "explicitDiagnostic"},
		{-1, -1, -1, -1, (Odr_fun) 0, 0}
	};
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		((odr_constructed_begin (o, &(*p)->u, ODR_CONTEXT, 1, "diagnostic") &&
		odr_choice (o, arm, &(*p)->u, &(*p)->which, 0) &&
		odr_constructed_end (o)) || odr_ok(o)) &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->message, ODR_CONTEXT, 2, 1, "message") &&
		odr_sequence_end (o);
}

int z_DiagnosticFormat (ODR o, Z_DiagnosticFormat **p, int opt, const char *name)
{
	if (!odr_initmember (o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_sequence_of (o, (Odr_fun) z_DiagnosticFormat_s, &(*p)->elements,
		&(*p)->num, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int z_TooMany (ODR o, Z_TooMany **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, odr_integer,
			&(*p)->tooManyWhat, ODR_CONTEXT, 1, 0, "tooManyWhat") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->max, ODR_CONTEXT, 2, 1, "max") &&
		odr_sequence_end (o);
}

int z_BadSpec (ODR o, Z_BadSpec **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_Specification,
			&(*p)->spec, ODR_CONTEXT, 1, 0, "spec") &&
		odr_implicit_tag (o, z_DatabaseName,
			&(*p)->db, ODR_CONTEXT, 2, 1, "db") &&
		odr_implicit_settag (o, ODR_CONTEXT, 3) &&
		(odr_sequence_of(o, (Odr_fun) z_Specification, &(*p)->goodOnes,
		  &(*p)->num_goodOnes, "goodOnes") || odr_ok(o)) &&
		odr_sequence_end (o);
}

int z_DbUnavail_0 (ODR o, Z_DbUnavail_0 **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, odr_integer,
			&(*p)->reasonCode, ODR_CONTEXT, 1, 1, "reasonCode") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->message, ODR_CONTEXT, 2, 1, "message") &&
		odr_sequence_end (o);
}

int z_DbUnavail (ODR o, Z_DbUnavail **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_DatabaseName,
			&(*p)->db, ODR_CONTEXT, 1, 0, "db") &&
		odr_implicit_tag (o, z_DbUnavail_0,
			&(*p)->why, ODR_CONTEXT, 2, 0, "why") &&
		odr_sequence_end (o);
}

int z_Attribute (ODR o, Z_Attribute **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, odr_oid,
			&(*p)->id, ODR_CONTEXT, 1, 0, "id") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->type, ODR_CONTEXT, 2, 1, "type") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->value, ODR_CONTEXT, 3, 1, "value") &&
		odr_explicit_tag (o, z_Term,
			&(*p)->term, ODR_CONTEXT, 4, 1, "term") &&
		odr_sequence_end (o);
}

int z_AttCombo (ODR o, Z_AttCombo **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_AttributeList,
			&(*p)->unsupportedCombination, ODR_CONTEXT, 1, 0, "unsupportedCombination") &&
		odr_implicit_settag (o, ODR_CONTEXT, 2) &&
		(odr_sequence_of(o, (Odr_fun) z_AttributeList, &(*p)->recommendedAlternatives,
		  &(*p)->num_recommendedAlternatives, "recommendedAlternatives") || odr_ok(o)) &&
		odr_sequence_end (o);
}

int z_DiagTerm (ODR o, Z_DiagTerm **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, odr_integer,
			&(*p)->problem, ODR_CONTEXT, 1, 1, "problem") &&
		odr_explicit_tag (o, z_Term,
			&(*p)->term, ODR_CONTEXT, 2, 0, "term") &&
		odr_sequence_end (o);
}

int z_Proximity (ODR o, Z_Proximity **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_Proximity_resultSets,
		(Odr_fun) odr_null, "resultSets"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_Proximity_badSet,
		(Odr_fun) z_InternationalString, "badSet"},
		{ODR_IMPLICIT, ODR_CONTEXT, 3, Z_Proximity_relation,
		(Odr_fun) odr_integer, "relation"},
		{ODR_IMPLICIT, ODR_CONTEXT, 4, Z_Proximity_unit,
		(Odr_fun) odr_integer, "unit"},
		{ODR_IMPLICIT, ODR_CONTEXT, 5, Z_Proximity_distance,
		(Odr_fun) odr_integer, "distance"},
		{ODR_EXPLICIT, ODR_CONTEXT, 6, Z_Proximity_attributes,
		(Odr_fun) z_AttributeList, "attributes"},
		{ODR_IMPLICIT, ODR_CONTEXT, 7, Z_Proximity_ordered,
		(Odr_fun) odr_null, "ordered"},
		{ODR_IMPLICIT, ODR_CONTEXT, 8, Z_Proximity_exclusion,
		(Odr_fun) odr_null, "exclusion"},
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

int z_AttrListList (ODR o, Z_AttrListList **p, int opt, const char *name)
{
	if (!odr_initmember (o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_sequence_of (o, (Odr_fun) z_AttributeList, &(*p)->elements,
		&(*p)->num, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int z_Scan (ODR o, Z_Scan **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 0, Z_Scan_nonZeroStepSize,
		(Odr_fun) odr_null, "nonZeroStepSize"},
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_Scan_specifiedStepSize,
		(Odr_fun) odr_null, "specifiedStepSize"},
		{ODR_IMPLICIT, ODR_CONTEXT, 3, Z_Scan_termList1,
		(Odr_fun) odr_null, "termList1"},
		{ODR_IMPLICIT, ODR_CONTEXT, 4, Z_Scan_termList2,
		(Odr_fun) z_AttrListList, "termList2"},
		{ODR_IMPLICIT, ODR_CONTEXT, 5, Z_Scan_posInResponse,
		(Odr_fun) odr_integer, "posInResponse"},
		{ODR_IMPLICIT, ODR_CONTEXT, 6, Z_Scan_resources,
		(Odr_fun) odr_null, "resources"},
		{ODR_IMPLICIT, ODR_CONTEXT, 7, Z_Scan_endOfList,
		(Odr_fun) odr_null, "endOfList"},
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

int z_StringList (ODR o, Z_StringList **p, int opt, const char *name)
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

int z_Sort (ODR o, Z_Sort **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 0, Z_SortD_sequence,
		(Odr_fun) odr_null, "sequence"},
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_SortD_noRsName,
		(Odr_fun) odr_null, "noRsName"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_SortD_tooMany,
		(Odr_fun) odr_integer, "tooMany"},
		{ODR_IMPLICIT, ODR_CONTEXT, 3, Z_SortD_incompatible,
		(Odr_fun) odr_null, "incompatible"},
		{ODR_IMPLICIT, ODR_CONTEXT, 4, Z_SortD_generic,
		(Odr_fun) odr_null, "generic"},
		{ODR_IMPLICIT, ODR_CONTEXT, 5, Z_SortD_dbSpecific,
		(Odr_fun) odr_null, "dbSpecific"},
		{ODR_EXPLICIT, ODR_CONTEXT, 6, Z_SortD_sortElement,
		(Odr_fun) z_SortElement, "sortElement"},
		{ODR_IMPLICIT, ODR_CONTEXT, 7, Z_SortD_key,
		(Odr_fun) odr_integer, "key"},
		{ODR_IMPLICIT, ODR_CONTEXT, 8, Z_SortD_action,
		(Odr_fun) odr_null, "action"},
		{ODR_IMPLICIT, ODR_CONTEXT, 9, Z_SortD_illegal,
		(Odr_fun) odr_integer, "illegal"},
		{ODR_IMPLICIT, ODR_CONTEXT, 10, Z_SortD_inputTooLarge,
		(Odr_fun) z_StringList, "inputTooLarge"},
		{ODR_IMPLICIT, ODR_CONTEXT, 11, Z_SortD_aggregateTooLarge,
		(Odr_fun) odr_null, "aggregateTooLarge"},
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

int z_Segmentation (ODR o, Z_Segmentation **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 0, Z_Segmentation_segmentCount,
		(Odr_fun) odr_null, "segmentCount"},
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_Segmentation_segmentSize,
		(Odr_fun) odr_integer, "segmentSize"},
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

int z_ExtServices (ODR o, Z_ExtServices **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_ExtServices_req,
		(Odr_fun) odr_integer, "req"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_ExtServices_permission,
		(Odr_fun) odr_integer, "permission"},
		{ODR_IMPLICIT, ODR_CONTEXT, 3, Z_ExtServices_immediate,
		(Odr_fun) odr_integer, "immediate"},
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

int z_OidList (ODR o, Z_OidList **p, int opt, const char *name)
{
	if (!odr_initmember (o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_sequence_of (o, (Odr_fun) odr_oid, &(*p)->elements,
		&(*p)->num, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int z_AltOidList (ODR o, Z_AltOidList **p, int opt, const char *name)
{
	if (!odr_initmember (o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_sequence_of (o, (Odr_fun) odr_oid, &(*p)->elements,
		&(*p)->num, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int z_AccessCtrl (ODR o, Z_AccessCtrl **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_AccessCtrl_noUser,
		(Odr_fun) odr_null, "noUser"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_AccessCtrl_refused,
		(Odr_fun) odr_null, "refused"},
		{ODR_IMPLICIT, ODR_CONTEXT, 3, Z_AccessCtrl_simple,
		(Odr_fun) odr_null, "simple"},
		{ODR_IMPLICIT, ODR_CONTEXT, 4, Z_AccessCtrl_oid,
		(Odr_fun) z_OidList, "oid"},
		{ODR_IMPLICIT, ODR_CONTEXT, 5, Z_AccessCtrl_alternative,
		(Odr_fun) z_AltOidList, "alternative"},
		{ODR_IMPLICIT, ODR_CONTEXT, 6, Z_AccessCtrl_pwdInv,
		(Odr_fun) odr_null, "pwdInv"},
		{ODR_IMPLICIT, ODR_CONTEXT, 7, Z_AccessCtrl_pwdExp,
		(Odr_fun) odr_null, "pwdExp"},
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

int z_RecordSyntax (ODR o, Z_RecordSyntax **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, odr_oid,
			&(*p)->unsupportedSyntax, ODR_CONTEXT, 1, 0, "unsupportedSyntax") &&
		odr_implicit_settag (o, ODR_CONTEXT, 2) &&
		(odr_sequence_of(o, (Odr_fun) odr_oid, &(*p)->suggestedAlternatives,
		  &(*p)->num_suggestedAlternatives, "suggestedAlternatives") || odr_ok(o)) &&
		odr_sequence_end (o);
}

int z_DiagFormat (ODR o, Z_DiagFormat **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 1000, Z_DiagFormat_tooMany,
		(Odr_fun) z_TooMany, "tooMany"},
		{ODR_IMPLICIT, ODR_CONTEXT, 1001, Z_DiagFormat_badSpec,
		(Odr_fun) z_BadSpec, "badSpec"},
		{ODR_IMPLICIT, ODR_CONTEXT, 1002, Z_DiagFormat_dbUnavail,
		(Odr_fun) z_DbUnavail, "dbUnavail"},
		{ODR_IMPLICIT, ODR_CONTEXT, 1003, Z_DiagFormat_unSupOp,
		(Odr_fun) odr_integer, "unSupOp"},
		{ODR_IMPLICIT, ODR_CONTEXT, 1004, Z_DiagFormat_attribute,
		(Odr_fun) z_Attribute, "attribute"},
		{ODR_IMPLICIT, ODR_CONTEXT, 1005, Z_DiagFormat_attCombo,
		(Odr_fun) z_AttCombo, "attCombo"},
		{ODR_IMPLICIT, ODR_CONTEXT, 1006, Z_DiagFormat_term,
		(Odr_fun) z_DiagTerm, "term"},
		{ODR_EXPLICIT, ODR_CONTEXT, 1007, Z_DiagFormat_proximity,
		(Odr_fun) z_Proximity, "proximity"},
		{ODR_EXPLICIT, ODR_CONTEXT, 1008, Z_DiagFormat_scan,
		(Odr_fun) z_Scan, "scan"},
		{ODR_EXPLICIT, ODR_CONTEXT, 1009, Z_DiagFormat_sort,
		(Odr_fun) z_Sort, "sort"},
		{ODR_EXPLICIT, ODR_CONTEXT, 1010, Z_DiagFormat_segmentation,
		(Odr_fun) z_Segmentation, "segmentation"},
		{ODR_EXPLICIT, ODR_CONTEXT, 1011, Z_DiagFormat_extServices,
		(Odr_fun) z_ExtServices, "extServices"},
		{ODR_EXPLICIT, ODR_CONTEXT, 1012, Z_DiagFormat_accessCtrl,
		(Odr_fun) z_AccessCtrl, "accessCtrl"},
		{ODR_IMPLICIT, ODR_CONTEXT, 1013, Z_DiagFormat_recordSyntax,
		(Odr_fun) z_RecordSyntax, "recordSyntax"},
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
