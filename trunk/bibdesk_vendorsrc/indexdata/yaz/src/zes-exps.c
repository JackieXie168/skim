/** \file zes-exps.c
    \brief ASN.1 Module ESFormat-ExportSpecification

    Generated automatically by YAZ ASN.1 Compiler 0.4
*/

#include <yaz/zes-exps.h>

int z_ESExportSpecificationEsRequest (ODR o, Z_ESExportSpecificationEsRequest **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_explicit_tag (o, z_ESOriginPartToKeep,
			&(*p)->toKeep, ODR_CONTEXT, 1, 0, "toKeep") &&
		odr_implicit_tag (o, odr_null,
			&(*p)->notToKeep, ODR_CONTEXT, 2, 0, "notToKeep") &&
		odr_sequence_end (o);
}

int z_ESExportSpecificationTaskPackage (ODR o, Z_ESExportSpecificationTaskPackage **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_explicit_tag (o, z_ESOriginPartToKeep,
			&(*p)->originPart, ODR_CONTEXT, 1, 0, "originPart") &&
		odr_implicit_tag (o, odr_null,
			&(*p)->targetPart, ODR_CONTEXT, 2, 0, "targetPart") &&
		odr_sequence_end (o);
}

int z_ESExportSpecification (ODR o, Z_ESExportSpecification **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_ESExportSpecification_esRequest,
		(Odr_fun) z_ESExportSpecificationEsRequest, "esRequest"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_ESExportSpecification_taskPackage,
		(Odr_fun) z_ESExportSpecificationTaskPackage, "taskPackage"},
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

int z_ESOriginPartToKeep (ODR o, Z_ESOriginPartToKeep **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_CompSpec,
			&(*p)->composition, ODR_CONTEXT, 1, 0, "composition") &&
		odr_explicit_tag (o, z_ESDestination,
			&(*p)->exportDestination, ODR_CONTEXT, 2, 0, "exportDestination") &&
		odr_sequence_end (o);
}

int z_ESDestinationOther (ODR o, Z_ESDestinationOther **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->vehicle, ODR_CONTEXT, 1, 1, "vehicle") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->destination, ODR_CONTEXT, 2, 0, "destination") &&
		odr_sequence_end (o);
}

int z_ESDestination (ODR o, Z_ESDestination **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_ESDestination_phoneNumber,
		(Odr_fun) z_InternationalString, "phoneNumber"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_ESDestination_faxNumber,
		(Odr_fun) z_InternationalString, "faxNumber"},
		{ODR_IMPLICIT, ODR_CONTEXT, 3, Z_ESDestination_x400address,
		(Odr_fun) z_InternationalString, "x400address"},
		{ODR_IMPLICIT, ODR_CONTEXT, 4, Z_ESDestination_emailAddress,
		(Odr_fun) z_InternationalString, "emailAddress"},
		{ODR_IMPLICIT, ODR_CONTEXT, 5, Z_ESDestination_pagerNumber,
		(Odr_fun) z_InternationalString, "pagerNumber"},
		{ODR_IMPLICIT, ODR_CONTEXT, 6, Z_ESDestination_ftpAddress,
		(Odr_fun) z_InternationalString, "ftpAddress"},
		{ODR_IMPLICIT, ODR_CONTEXT, 7, Z_ESDestination_ftamAddress,
		(Odr_fun) z_InternationalString, "ftamAddress"},
		{ODR_IMPLICIT, ODR_CONTEXT, 8, Z_ESDestination_printerAddress,
		(Odr_fun) z_InternationalString, "printerAddress"},
		{ODR_IMPLICIT, ODR_CONTEXT, 100, Z_ESDestination_other,
		(Odr_fun) z_ESDestinationOther, "other"},
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
