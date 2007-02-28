/** \file zes-admin.c
    \brief ASN.1 Module ESFormat-Admin

    Generated automatically by YAZ ASN.1 Compiler 0.4
*/

#include <yaz/zes-admin.h>

int z_AdminEsRequest (ODR o, Z_AdminEsRequest **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_explicit_tag (o, z_ESAdminOriginPartToKeep,
			&(*p)->toKeep, ODR_CONTEXT, 1, 0, "toKeep") &&
		odr_explicit_tag (o, z_ESAdminOriginPartNotToKeep,
			&(*p)->notToKeep, ODR_CONTEXT, 2, 0, "notToKeep") &&
		odr_sequence_end (o);
}

int z_AdminTaskPackage (ODR o, Z_AdminTaskPackage **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_explicit_tag (o, z_ESAdminOriginPartToKeep,
			&(*p)->originPart, ODR_CONTEXT, 1, 0, "originPart") &&
		odr_explicit_tag (o, z_ESAdminTargetPart,
			&(*p)->targetPart, ODR_CONTEXT, 2, 0, "targetPart") &&
		odr_sequence_end (o);
}

int z_Admin (ODR o, Z_Admin **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_Admin_esRequest,
		(Odr_fun) z_AdminEsRequest, "esRequest"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_Admin_taskPackage,
		(Odr_fun) z_AdminTaskPackage, "taskPackage"},
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

int z_ESAdminOriginPartToKeep (ODR o, Z_ESAdminOriginPartToKeep **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_EXPLICIT, ODR_CONTEXT, 1, Z_ESAdminOriginPartToKeep_reIndex,
		(Odr_fun) odr_null, "reIndex"},
		{ODR_EXPLICIT, ODR_CONTEXT, 2, Z_ESAdminOriginPartToKeep_truncate,
		(Odr_fun) odr_null, "truncate"},
		{ODR_EXPLICIT, ODR_CONTEXT, 3, Z_ESAdminOriginPartToKeep_drop,
		(Odr_fun) odr_null, "drop"},
		{ODR_EXPLICIT, ODR_CONTEXT, 4, Z_ESAdminOriginPartToKeep_create,
		(Odr_fun) odr_null, "create"},
		{ODR_EXPLICIT, ODR_CONTEXT, 5, Z_ESAdminOriginPartToKeep_import,
		(Odr_fun) z_ImportParameters, "import"},
		{ODR_EXPLICIT, ODR_CONTEXT, 6, Z_ESAdminOriginPartToKeep_refresh,
		(Odr_fun) odr_null, "refresh"},
		{ODR_EXPLICIT, ODR_CONTEXT, 7, Z_ESAdminOriginPartToKeep_commit,
		(Odr_fun) odr_null, "commit"},
		{ODR_EXPLICIT, ODR_CONTEXT, 8, Z_ESAdminOriginPartToKeep_shutdown,
		(Odr_fun) odr_null, "shutdown"},
		{ODR_EXPLICIT, ODR_CONTEXT, 9, Z_ESAdminOriginPartToKeep_start,
		(Odr_fun) odr_null, "start"},
		{-1, -1, -1, -1, (Odr_fun) 0, 0}
	};
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_constructed_begin (o, &(*p)->u, ODR_CONTEXT, 1, "action") &&
		odr_choice (o, arm, &(*p)->u, &(*p)->which, 0) &&
		odr_constructed_end (o) &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->databaseName, ODR_CONTEXT, 2, 1, "databaseName") &&
		odr_sequence_end (o);
}

int z_ESAdminOriginPartNotToKeep (ODR o, Z_ESAdminOriginPartNotToKeep **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_EXPLICIT, ODR_CONTEXT, 1, Z_ESAdminOriginPartNotToKeep_records,
		(Odr_fun) z_Segment, "records"},
		{ODR_EXPLICIT, ODR_CONTEXT, 0, Z_ESAdminOriginPartNotToKeep_recordsWillFollow,
		(Odr_fun) odr_null, "recordsWillFollow"},
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

int z_ESAdminTargetPart (ODR o, Z_ESAdminTargetPart **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, odr_integer,
			&(*p)->updateStatus, ODR_CONTEXT, 1, 0, "updateStatus") &&
		odr_implicit_settag (o, ODR_CONTEXT, 2) &&
		(odr_sequence_of(o, (Odr_fun) z_DiagRec, &(*p)->globalDiagnostics,
		  &(*p)->num_globalDiagnostics, "globalDiagnostics") || odr_ok(o)) &&
		odr_sequence_end (o);
}

int z_ImportParameters (ODR o, Z_ImportParameters **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->recordType, ODR_CONTEXT, 1, 0, "recordType") &&
		odr_sequence_end (o);
}
