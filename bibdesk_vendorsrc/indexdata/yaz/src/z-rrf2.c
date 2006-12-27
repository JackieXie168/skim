/** \file z-rrf2.c
    \brief ASN.1 Module ResourceReport-Format-Resource-2

    Generated automatically by YAZ ASN.1 Compiler 0.4
*/

#include <yaz/z-rrf2.h>

int z_ResourceReport2 (ODR o, Z_ResourceReport2 **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_settag (o, ODR_CONTEXT, 1) &&
		(odr_sequence_of(o, (Odr_fun) z_Estimate2, &(*p)->estimates,
		  &(*p)->num_estimates, "estimates") || odr_ok(o)) &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->message, ODR_CONTEXT, 2, 1, "message") &&
		odr_sequence_end (o);
}

int z_Estimate2 (ODR o, Z_Estimate2 **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_explicit_tag (o, z_StringOrNumeric,
			&(*p)->type, ODR_CONTEXT, 1, 0, "type") &&
		odr_implicit_tag (o, z_IntUnit,
			&(*p)->value, ODR_CONTEXT, 2, 0, "value") &&
		odr_sequence_end (o);
}
