/** \file zes-update.c
    \brief ASN.1 Module ESFormat-Update

    Generated automatically by YAZ ASN.1 Compiler 0.4
*/

#include <yaz/zes-update.h>

int z_IUUpdateEsRequest (ODR o, Z_IUUpdateEsRequest **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_explicit_tag (o, z_IUOriginPartToKeep,
			&(*p)->toKeep, ODR_CONTEXT, 1, 0, "toKeep") &&
		odr_explicit_tag (o, z_IUOriginPartNotToKeep,
			&(*p)->notToKeep, ODR_CONTEXT, 2, 0, "notToKeep") &&
		odr_sequence_end (o);
}

int z_IUUpdateTaskPackage (ODR o, Z_IUUpdateTaskPackage **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_explicit_tag (o, z_IUOriginPartToKeep,
			&(*p)->originPart, ODR_CONTEXT, 1, 0, "originPart") &&
		odr_explicit_tag (o, z_IUTargetPart,
			&(*p)->targetPart, ODR_CONTEXT, 2, 0, "targetPart") &&
		odr_sequence_end (o);
}

int z_IUUpdate (ODR o, Z_IUUpdate **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_IUUpdate_esRequest,
		(Odr_fun) z_IUUpdateEsRequest, "esRequest"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_IUUpdate_taskPackage,
		(Odr_fun) z_IUUpdateTaskPackage, "taskPackage"},
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

int z_IUOriginPartToKeep (ODR o, Z_IUOriginPartToKeep **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, odr_integer,
			&(*p)->action, ODR_CONTEXT, 1, 0, "action") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->databaseName, ODR_CONTEXT, 2, 0, "databaseName") &&
		odr_implicit_tag (o, odr_oid,
			&(*p)->schema, ODR_CONTEXT, 3, 1, "schema") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->elementSetName, ODR_CONTEXT, 4, 1, "elementSetName") &&
		odr_implicit_tag (o, z_External,
			&(*p)->actionQualifier, ODR_CONTEXT, 5, 1, "actionQualifier") &&
		odr_sequence_end (o);
}

int z_IUOriginPartNotToKeep (ODR o, Z_IUOriginPartNotToKeep **p, int opt, const char *name)
{
	return z_IUSuppliedRecords (o, p, opt, name);
}

int z_IUTargetPart (ODR o, Z_IUTargetPart **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, odr_integer,
			&(*p)->updateStatus, ODR_CONTEXT, 1, 0, "updateStatus") &&
		odr_implicit_settag (o, ODR_CONTEXT, 2) &&
		(odr_sequence_of(o, (Odr_fun) z_DiagRec, &(*p)->globalDiagnostics,
		  &(*p)->num_globalDiagnostics, "globalDiagnostics") || odr_ok(o)) &&
		odr_implicit_settag (o, ODR_CONTEXT, 3) &&
		odr_sequence_of(o, (Odr_fun) z_IUTaskPackageRecordStructure, &(*p)->taskPackageRecords,
		  &(*p)->num_taskPackageRecords, "taskPackageRecords") &&
		odr_sequence_end (o);
}

int z_IUSuppliedRecordsId (ODR o, Z_IUSuppliedRecordsId **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_IUSuppliedRecordsId_timeStamp,
		(Odr_fun) odr_generalizedtime, "timeStamp"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_IUSuppliedRecordsId_versionNumber,
		(Odr_fun) z_InternationalString, "versionNumber"},
		{ODR_IMPLICIT, ODR_CONTEXT, 3, Z_IUSuppliedRecordsId_previousVersion,
		(Odr_fun) z_External, "previousVersion"},
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

int z_IUSuppliedRecords_elem (ODR o, Z_IUSuppliedRecords_elem **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_IUSuppliedRecords_elem_number,
		(Odr_fun) odr_integer, "number"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_IUSuppliedRecords_elem_string,
		(Odr_fun) z_InternationalString, "string"},
		{ODR_IMPLICIT, ODR_CONTEXT, 3, Z_IUSuppliedRecords_elem_opaque,
		(Odr_fun) odr_octetstring, "opaque"},
		{-1, -1, -1, -1, (Odr_fun) 0, 0}
	};
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		((odr_constructed_begin (o, &(*p)->u, ODR_CONTEXT, 1, "recordId") &&
		odr_choice (o, arm, &(*p)->u, &(*p)->which, 0) &&
		odr_constructed_end (o)) || odr_ok(o)) &&
		odr_explicit_tag (o, z_IUSuppliedRecordsId,
			&(*p)->supplementalId, ODR_CONTEXT, 2, 1, "supplementalId") &&
		odr_implicit_tag (o, z_IUCorrelationInfo,
			&(*p)->correlationInfo, ODR_CONTEXT, 3, 1, "correlationInfo") &&
		odr_implicit_tag (o, z_External,
			&(*p)->record, ODR_CONTEXT, 4, 0, "record") &&
		odr_sequence_end (o);
}

int z_IUSuppliedRecords (ODR o, Z_IUSuppliedRecords **p, int opt, const char *name)
{
	if (!odr_initmember (o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_sequence_of (o, (Odr_fun) z_IUSuppliedRecords_elem, &(*p)->elements,
		&(*p)->num, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int z_IUCorrelationInfo (ODR o, Z_IUCorrelationInfo **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->note, ODR_CONTEXT, 1, 1, "note") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->id, ODR_CONTEXT, 2, 1, "id") &&
		odr_sequence_end (o);
}

int z_IUTaskPackageRecordStructureSurrogateDiagnostics (ODR o, Z_IUTaskPackageRecordStructureSurrogateDiagnostics **p, int opt, const char *name)
{
	if (!odr_initmember (o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_sequence_of (o, (Odr_fun) z_DiagRec, &(*p)->elements,
		&(*p)->num, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int z_IUTaskPackageRecordStructure (ODR o, Z_IUTaskPackageRecordStructure **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_IUTaskPackageRecordStructure_record,
		(Odr_fun) z_External, "record"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_IUTaskPackageRecordStructure_surrogateDiagnostics,
		(Odr_fun) z_IUTaskPackageRecordStructureSurrogateDiagnostics, "surrogateDiagnostics"},
		{-1, -1, -1, -1, (Odr_fun) 0, 0}
	};
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		((odr_constructed_begin (o, &(*p)->u, ODR_CONTEXT, 1, "recordOrSurDiag") &&
		odr_choice (o, arm, &(*p)->u, &(*p)->which, 0) &&
		odr_constructed_end (o)) || odr_ok(o)) &&
		odr_implicit_tag (o, z_IUCorrelationInfo,
			&(*p)->correlationInfo, ODR_CONTEXT, 2, 1, "correlationInfo") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->recordStatus, ODR_CONTEXT, 3, 0, "recordStatus") &&
		odr_implicit_settag (o, ODR_CONTEXT, 4) &&
		(odr_sequence_of(o, (Odr_fun) z_DiagRec, &(*p)->supplementalDiagnostics,
		  &(*p)->num_supplementalDiagnostics, "supplementalDiagnostics") || odr_ok(o)) &&
		odr_sequence_end (o);
}
