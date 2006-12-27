/** \file z-estask.c
    \brief ASN.1 Module RecordSyntax-ESTaskPackage

    Generated automatically by YAZ ASN.1 Compiler 0.4
*/

#include <yaz/z-estask.h>

int z_TaskPackage (ODR o, Z_TaskPackage **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, odr_oid,
			&(*p)->packageType, ODR_CONTEXT, 1, 0, "packageType") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->packageName, ODR_CONTEXT, 2, 1, "packageName") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->userId, ODR_CONTEXT, 3, 1, "userId") &&
		odr_implicit_tag (o, z_IntUnit,
			&(*p)->retentionTime, ODR_CONTEXT, 4, 1, "retentionTime") &&
		odr_implicit_tag (o, z_Permissions,
			&(*p)->permissions, ODR_CONTEXT, 5, 1, "permissions") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->description, ODR_CONTEXT, 6, 1, "description") &&
		odr_implicit_tag (o, odr_octetstring,
			&(*p)->targetReference, ODR_CONTEXT, 7, 1, "targetReference") &&
		odr_implicit_tag (o, odr_generalizedtime,
			&(*p)->creationDateTime, ODR_CONTEXT, 8, 1, "creationDateTime") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->taskStatus, ODR_CONTEXT, 9, 0, "taskStatus") &&
		odr_implicit_settag (o, ODR_CONTEXT, 10) &&
		(odr_sequence_of(o, (Odr_fun) z_DiagRec, &(*p)->packageDiagnostics,
		  &(*p)->num_packageDiagnostics, "packageDiagnostics") || odr_ok(o)) &&
		odr_implicit_tag (o, z_External,
			&(*p)->taskSpecificParameters, ODR_CONTEXT, 11, 0, "taskSpecificParameters") &&
		odr_sequence_end (o);
}
