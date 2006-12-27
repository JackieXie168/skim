/** \file zes-psched.c
    \brief ASN.1 Module ESFormat-PeriodicQuerySchedule

    Generated automatically by YAZ ASN.1 Compiler 0.4
*/

#include <yaz/zes-psched.h>

int z_PQSPeriodicQueryScheduleEsRequest (ODR o, Z_PQSPeriodicQueryScheduleEsRequest **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_explicit_tag (o, z_PQSOriginPartToKeep,
			&(*p)->toKeep, ODR_CONTEXT, 1, 0, "toKeep") &&
		odr_explicit_tag (o, z_PQSOriginPartNotToKeep,
			&(*p)->notToKeep, ODR_CONTEXT, 2, 0, "notToKeep") &&
		odr_sequence_end (o);
}

int z_PQSPeriodicQueryScheduleTaskPackage (ODR o, Z_PQSPeriodicQueryScheduleTaskPackage **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_explicit_tag (o, z_PQSOriginPartToKeep,
			&(*p)->originPart, ODR_CONTEXT, 1, 0, "originPart") &&
		odr_explicit_tag (o, z_PQSTargetPart,
			&(*p)->targetPart, ODR_CONTEXT, 2, 0, "targetPart") &&
		odr_sequence_end (o);
}

int z_PQSPeriodicQuerySchedule (ODR o, Z_PQSPeriodicQuerySchedule **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_PQSPeriodicQuerySchedule_esRequest,
		(Odr_fun) z_PQSPeriodicQueryScheduleEsRequest, "esRequest"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_PQSPeriodicQuerySchedule_taskPackage,
		(Odr_fun) z_PQSPeriodicQueryScheduleTaskPackage, "taskPackage"},
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

int z_PQSOriginPartToKeep (ODR o, Z_PQSOriginPartToKeep **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_PQSOriginPartToKeep_packageName,
		(Odr_fun) z_InternationalString, "packageName"},
		{ODR_EXPLICIT, ODR_CONTEXT, 2, Z_PQSOriginPartToKeep_exportPackage,
		(Odr_fun) z_ESExportSpecification, "exportPackage"},
		{-1, -1, -1, -1, (Odr_fun) 0, 0}
	};
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, odr_bool,
			&(*p)->activeFlag, ODR_CONTEXT, 1, 0, "activeFlag") &&
		odr_implicit_settag (o, ODR_CONTEXT, 2) &&
		(odr_sequence_of(o, (Odr_fun) z_InternationalString, &(*p)->databaseNames,
		  &(*p)->num_databaseNames, "databaseNames") || odr_ok(o)) &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->resultSetDisposition, ODR_CONTEXT, 3, 1, "resultSetDisposition") &&
		odr_explicit_tag (o, z_ESDestination,
			&(*p)->alertDestination, ODR_CONTEXT, 4, 1, "alertDestination") &&
		((odr_constructed_begin (o, &(*p)->u, ODR_CONTEXT, 5, "exportParameters") &&
		odr_choice (o, arm, &(*p)->u, &(*p)->which, 0) &&
		odr_constructed_end (o)) || odr_ok(o)) &&
		odr_sequence_end (o);
}

int z_PQSOriginPartNotToKeep (ODR o, Z_PQSOriginPartNotToKeep **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_EXPLICIT, ODR_CONTEXT, 1, Z_PQSOriginPartNotToKeep_actualQuery,
		(Odr_fun) z_Query, "actualQuery"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_PQSOriginPartNotToKeep_packageName,
		(Odr_fun) z_InternationalString, "packageName"},
		{-1, -1, -1, -1, (Odr_fun) 0, 0}
	};
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		((odr_constructed_begin (o, &(*p)->u, ODR_CONTEXT, 1, "querySpec") &&
		odr_choice (o, arm, &(*p)->u, &(*p)->which, 0) &&
		odr_constructed_end (o)) || odr_ok(o)) &&
		odr_explicit_tag (o, z_PQSPeriod,
			&(*p)->originSuggestedPeriod, ODR_CONTEXT, 2, 1, "originSuggestedPeriod") &&
		odr_implicit_tag (o, odr_generalizedtime,
			&(*p)->expiration, ODR_CONTEXT, 3, 1, "expiration") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->resultSetPackage, ODR_CONTEXT, 4, 1, "resultSetPackage") &&
		odr_sequence_end (o);
}

int z_PQSTargetPart (ODR o, Z_PQSTargetPart **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_explicit_tag (o, z_Query,
			&(*p)->actualQuery, ODR_CONTEXT, 1, 0, "actualQuery") &&
		odr_explicit_tag (o, z_PQSPeriod,
			&(*p)->targetStatedPeriod, ODR_CONTEXT, 2, 0, "targetStatedPeriod") &&
		odr_implicit_tag (o, odr_generalizedtime,
			&(*p)->expiration, ODR_CONTEXT, 3, 1, "expiration") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->resultSetPackage, ODR_CONTEXT, 4, 1, "resultSetPackage") &&
		odr_implicit_tag (o, odr_generalizedtime,
			&(*p)->lastQueryTime, ODR_CONTEXT, 5, 0, "lastQueryTime") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->lastResultNumber, ODR_CONTEXT, 6, 0, "lastResultNumber") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->numberSinceModify, ODR_CONTEXT, 7, 1, "numberSinceModify") &&
		odr_sequence_end (o);
}

int z_PQSPeriod (ODR o, Z_PQSPeriod **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_PQSPeriod_unit,
		(Odr_fun) z_IntUnit, "unit"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_PQSPeriod_businessDaily,
		(Odr_fun) odr_null, "businessDaily"},
		{ODR_IMPLICIT, ODR_CONTEXT, 3, Z_PQSPeriod_continuous,
		(Odr_fun) odr_null, "continuous"},
		{ODR_IMPLICIT, ODR_CONTEXT, 4, Z_PQSPeriod_other,
		(Odr_fun) z_InternationalString, "other"},
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
