/** \file zes-update0.c
    \brief ASN.1 Module ESFormat-Update0

    Generated automatically by YAZ ASN.1 Compiler 0.4
*/

#include <yaz/zes-update0.h>

int z_IU0UpdateEsRequest (ODR o, Z_IU0UpdateEsRequest **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_explicit_tag (o, z_IU0OriginPartToKeep,
			&(*p)->toKeep, ODR_CONTEXT, 1, 0, "toKeep") &&
		odr_explicit_tag (o, z_IU0OriginPartNotToKeep,
			&(*p)->notToKeep, ODR_CONTEXT, 2, 0, "notToKeep") &&
		odr_sequence_end (o);
}

int z_IU0UpdateTaskPackage (ODR o, Z_IU0UpdateTaskPackage **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_explicit_tag (o, z_IU0OriginPartToKeep,
			&(*p)->originPart, ODR_CONTEXT, 1, 0, "originPart") &&
		odr_explicit_tag (o, z_IU0TargetPart,
			&(*p)->targetPart, ODR_CONTEXT, 2, 0, "targetPart") &&
		odr_sequence_end (o);
}

int z_IU0Update (ODR o, Z_IU0Update **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_IU0Update_esRequest,
		(Odr_fun) z_IU0UpdateEsRequest, "esRequest"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_IU0Update_taskPackage,
		(Odr_fun) z_IU0UpdateTaskPackage, "taskPackage"},
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

int z_IU0OriginPartToKeep (ODR o, Z_IU0OriginPartToKeep **p, int opt, const char *name)
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
		odr_sequence_end (o);
}

int z_IU0OriginPartNotToKeep (ODR o, Z_IU0OriginPartNotToKeep **p, int opt, const char *name)
{
	return z_IU0SuppliedRecords (o, p, opt, name);
}

int z_IU0TargetPart (ODR o, Z_IU0TargetPart **p, int opt, const char *name)
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
		odr_sequence_of(o, (Odr_fun) z_IU0TaskPackageRecordStructure, &(*p)->taskPackageRecords,
		  &(*p)->num_taskPackageRecords, "taskPackageRecords") &&
		odr_sequence_end (o);
}

int z_IU0SuppliedRecordsId (ODR o, Z_IU0SuppliedRecordsId **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_IU0SuppliedRecordsId_timeStamp,
		(Odr_fun) odr_generalizedtime, "timeStamp"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_IU0SuppliedRecordsId_versionNumber,
		(Odr_fun) z_InternationalString, "versionNumber"},
		{ODR_IMPLICIT, ODR_CONTEXT, 3, Z_IU0SuppliedRecordsId_previousVersion,
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

int z_IU0SuppliedRecords_elem (ODR o, Z_IU0SuppliedRecords_elem **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_IU0SuppliedRecords_elem_number,
		(Odr_fun) odr_integer, "number"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_IU0SuppliedRecords_elem_string,
		(Odr_fun) z_InternationalString, "string"},
		{ODR_IMPLICIT, ODR_CONTEXT, 3, Z_IU0SuppliedRecords_elem_opaque,
		(Odr_fun) odr_octetstring, "opaque"},
		{-1, -1, -1, -1, (Odr_fun) 0, 0}
	};
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		((odr_constructed_begin (o, &(*p)->u, ODR_CONTEXT, 1, "recordId") &&
		odr_choice (o, arm, &(*p)->u, &(*p)->which, 0) &&
		odr_constructed_end (o)) || odr_ok(o)) &&
		odr_explicit_tag (o, z_IU0SuppliedRecordsId,
			&(*p)->supplementalId, ODR_CONTEXT, 2, 1, "supplementalId") &&
		odr_implicit_tag (o, z_IU0CorrelationInfo,
			&(*p)->correlationInfo, ODR_CONTEXT, 3, 1, "correlationInfo") &&
		odr_implicit_tag (o, z_External,
			&(*p)->record, ODR_CONTEXT, 4, 0, "record") &&
		odr_sequence_end (o);
}

int z_IU0SuppliedRecords (ODR o, Z_IU0SuppliedRecords **p, int opt, const char *name)
{
	if (!odr_initmember (o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_sequence_of (o, (Odr_fun) z_IU0SuppliedRecords_elem, &(*p)->elements,
		&(*p)->num, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int z_IU0CorrelationInfo (ODR o, Z_IU0CorrelationInfo **p, int opt, const char *name)
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

int z_IU0TaskPackageRecordStructure (ODR o, Z_IU0TaskPackageRecordStructure **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_IU0TaskPackageRecordStructure_record,
		(Odr_fun) z_External, "record"},
		{ODR_EXPLICIT, ODR_CONTEXT, 2, Z_IU0TaskPackageRecordStructure_diagnostic,
		(Odr_fun) z_DiagRec, "diagnostic"},
		{-1, -1, -1, -1, (Odr_fun) 0, 0}
	};
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		((odr_constructed_begin (o, &(*p)->u, ODR_CONTEXT, 1, "recordOrSurDiag") &&
		odr_choice (o, arm, &(*p)->u, &(*p)->which, 0) &&
		odr_constructed_end (o)) || odr_ok(o)) &&
		odr_implicit_tag (o, z_IU0CorrelationInfo,
			&(*p)->correlationInfo, ODR_CONTEXT, 2, 1, "correlationInfo") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->recordStatus, ODR_CONTEXT, 3, 0, "recordStatus") &&
		odr_sequence_end (o);
}
