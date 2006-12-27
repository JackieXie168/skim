/** \file zes-pset.c
    \brief ASN.1 Module ESFormat-PersistentResultSet

    Generated automatically by YAZ ASN.1 Compiler 0.4
*/

#include <yaz/zes-pset.h>

int z_PRPersistentResultSetEsRequest (ODR o, Z_PRPersistentResultSetEsRequest **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, odr_null,
			&(*p)->toKeep, ODR_CONTEXT, 1, 0, "toKeep") &&
		odr_explicit_tag (o, z_PROriginPartNotToKeep,
			&(*p)->notToKeep, ODR_CONTEXT, 2, 1, "notToKeep") &&
		odr_sequence_end (o);
}

int z_PRPersistentResultSetTaskPackage (ODR o, Z_PRPersistentResultSetTaskPackage **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, odr_null,
			&(*p)->originPart, ODR_CONTEXT, 1, 0, "originPart") &&
		odr_explicit_tag (o, z_PRTargetPart,
			&(*p)->targetPart, ODR_CONTEXT, 2, 1, "targetPart") &&
		odr_sequence_end (o);
}

int z_PRPersistentResultSet (ODR o, Z_PRPersistentResultSet **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_PRPersistentResultSet_esRequest,
		(Odr_fun) z_PRPersistentResultSetEsRequest, "esRequest"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_PRPersistentResultSet_taskPackage,
		(Odr_fun) z_PRPersistentResultSetTaskPackage, "taskPackage"},
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

int z_PROriginPartNotToKeep (ODR o, Z_PROriginPartNotToKeep **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->originSuppliedResultSet, ODR_CONTEXT, 1, 1, "originSuppliedResultSet") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->replaceOrAppend, ODR_CONTEXT, 2, 1, "replaceOrAppend") &&
		odr_sequence_end (o);
}

int z_PRTargetPart (ODR o, Z_PRTargetPart **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->targetSuppliedResultSet, ODR_CONTEXT, 1, 1, "targetSuppliedResultSet") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->numberOfRecords, ODR_CONTEXT, 2, 1, "numberOfRecords") &&
		odr_sequence_end (o);
}
