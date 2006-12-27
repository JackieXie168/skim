/** \file zes-expi.c
    \brief ASN.1 Module ESFormat-ExportInvocation

    Generated automatically by YAZ ASN.1 Compiler 0.4
*/

#include <yaz/zes-expi.h>

int z_EIExportInvocationEsRequest (ODR o, Z_EIExportInvocationEsRequest **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_explicit_tag (o, z_EIOriginPartToKeep,
			&(*p)->toKeep, ODR_CONTEXT, 1, 0, "toKeep") &&
		odr_explicit_tag (o, z_EIOriginPartNotToKeep,
			&(*p)->notToKeep, ODR_CONTEXT, 2, 0, "notToKeep") &&
		odr_sequence_end (o);
}

int z_EIExportInvocationTaskPackage (ODR o, Z_EIExportInvocationTaskPackage **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_explicit_tag (o, z_EIOriginPartToKeep,
			&(*p)->originPart, ODR_CONTEXT, 1, 0, "originPart") &&
		odr_explicit_tag (o, z_EITargetPart,
			&(*p)->targetPart, ODR_CONTEXT, 2, 1, "targetPart") &&
		odr_sequence_end (o);
}

int z_EIExportInvocation (ODR o, Z_EIExportInvocation **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_EIExportInvocation_esRequest,
		(Odr_fun) z_EIExportInvocationEsRequest, "esRequest"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_EIExportInvocation_taskPackage,
		(Odr_fun) z_EIExportInvocationTaskPackage, "taskPackage"},
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

int z_EIOriginPartToKeep (ODR o, Z_EIOriginPartToKeep **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_EIOriginPartToKeep_packageName,
		(Odr_fun) z_InternationalString, "packageName"},
		{ODR_EXPLICIT, ODR_CONTEXT, 2, Z_EIOriginPartToKeep_packageSpec,
		(Odr_fun) z_ESExportSpecification, "packageSpec"},
		{-1, -1, -1, -1, (Odr_fun) 0, 0}
	};
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_constructed_begin (o, &(*p)->u, ODR_CONTEXT, 1, "exportSpec") &&
		odr_choice (o, arm, &(*p)->u, &(*p)->which, 0) &&
		odr_constructed_end (o) &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->numberOfCopies, ODR_CONTEXT, 2, 0, "numberOfCopies") &&
		odr_sequence_end (o);
}

int z_EIOriginPartNotToKeepRanges_s (ODR o, Z_EIOriginPartNotToKeepRanges_s **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, odr_integer,
			&(*p)->start, ODR_CONTEXT, 1, 0, "start") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->count, ODR_CONTEXT, 2, 1, "count") &&
		odr_sequence_end (o);
}

int z_EIOriginPartNotToKeepRanges (ODR o, Z_EIOriginPartNotToKeepRanges **p, int opt, const char *name)
{
	if (!odr_initmember (o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_sequence_of (o, (Odr_fun) z_EIOriginPartNotToKeepRanges_s, &(*p)->elements,
		&(*p)->num, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int z_EIOriginPartNotToKeep (ODR o, Z_EIOriginPartNotToKeep **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_EIOriginPartNotToKeep_all,
		(Odr_fun) odr_null, "all"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_EIOriginPartNotToKeep_ranges,
		(Odr_fun) z_EIOriginPartNotToKeepRanges, "ranges"},
		{-1, -1, -1, -1, (Odr_fun) 0, 0}
	};
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->resultSetId, ODR_CONTEXT, 1, 0, "resultSetId") &&
		odr_constructed_begin (o, &(*p)->u, ODR_CONTEXT, 2, "records") &&
		odr_choice (o, arm, &(*p)->u, &(*p)->which, 0) &&
		odr_constructed_end (o) &&
		odr_sequence_end (o);
}

int z_EITargetPart (ODR o, Z_EITargetPart **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_IntUnit,
			&(*p)->estimatedQuantity, ODR_CONTEXT, 1, 1, "estimatedQuantity") &&
		odr_implicit_tag (o, z_IntUnit,
			&(*p)->quantitySoFar, ODR_CONTEXT, 2, 1, "quantitySoFar") &&
		odr_implicit_tag (o, z_IntUnit,
			&(*p)->estimatedCost, ODR_CONTEXT, 3, 1, "estimatedCost") &&
		odr_implicit_tag (o, z_IntUnit,
			&(*p)->costSoFar, ODR_CONTEXT, 4, 1, "costSoFar") &&
		odr_sequence_end (o);
}
