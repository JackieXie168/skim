/** \file zes-pquery.c
    \brief ASN.1 Module ESFormat-PersistentQuery

    Generated automatically by YAZ ASN.1 Compiler 0.4
*/

#include <yaz/zes-pquery.h>

int z_PQueryPersistentQueryEsRequest (ODR o, Z_PQueryPersistentQueryEsRequest **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_explicit_tag (o, z_PQueryOriginPartToKeep,
			&(*p)->toKeep, ODR_CONTEXT, 1, 1, "toKeep") &&
		odr_explicit_tag (o, z_PQueryOriginPartNotToKeep,
			&(*p)->notToKeep, ODR_CONTEXT, 2, 0, "notToKeep") &&
		odr_sequence_end (o);
}

int z_PQueryPersistentQueryTaskPackage (ODR o, Z_PQueryPersistentQueryTaskPackage **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_explicit_tag (o, z_PQueryOriginPartToKeep,
			&(*p)->originPart, ODR_CONTEXT, 1, 1, "originPart") &&
		odr_explicit_tag (o, z_PQueryTargetPart,
			&(*p)->targetPart, ODR_CONTEXT, 2, 0, "targetPart") &&
		odr_sequence_end (o);
}

int z_PQueryPersistentQuery (ODR o, Z_PQueryPersistentQuery **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_PQueryPersistentQuery_esRequest,
		(Odr_fun) z_PQueryPersistentQueryEsRequest, "esRequest"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_PQueryPersistentQuery_taskPackage,
		(Odr_fun) z_PQueryPersistentQueryTaskPackage, "taskPackage"},
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

int z_PQueryOriginPartToKeep (ODR o, Z_PQueryOriginPartToKeep **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_settag (o, ODR_CONTEXT, 2) &&
		(odr_sequence_of(o, (Odr_fun) z_InternationalString, &(*p)->dbNames,
		  &(*p)->num_dbNames, "dbNames") || odr_ok(o)) &&
		odr_explicit_tag (o, z_OtherInformation,
			&(*p)->additionalSearchInfo, ODR_CONTEXT, 3, 1, "additionalSearchInfo") &&
		odr_sequence_end (o);
}

int z_PQueryOriginPartNotToKeep (ODR o, Z_PQueryOriginPartNotToKeep **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_PQueryOriginPartNotToKeep_package,
		(Odr_fun) z_InternationalString, "package"},
		{ODR_EXPLICIT, ODR_CONTEXT, 2, Z_PQueryOriginPartNotToKeep_query,
		(Odr_fun) z_Query, "query"},
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

int z_PQueryTargetPart (ODR o, Z_PQueryTargetPart **p, int opt, const char *name)
{
	return z_Query (o, p, opt, name);
}
