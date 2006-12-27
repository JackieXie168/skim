/** \file z-rrf1.c
    \brief ASN.1 Module ResourceReport-Format-Resource-1

    Generated automatically by YAZ ASN.1 Compiler 0.4
*/

#include <yaz/z-rrf1.h>

int z_ResourceReport1 (ODR o, Z_ResourceReport1 **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_settag (o, ODR_CONTEXT, 1) &&
		odr_sequence_of(o, (Odr_fun) z_Estimate1, &(*p)->estimates,
		  &(*p)->num_estimates, "estimates") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->message, ODR_CONTEXT, 2, 0, "message") &&
		odr_sequence_end (o);
}

int z_Estimate1 (ODR o, Z_Estimate1 **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_EstimateType,
			&(*p)->type, ODR_CONTEXT, 1, 0, "type") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->value, ODR_CONTEXT, 2, 0, "value") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->currency_code, ODR_CONTEXT, 3, 1, "currency_code") &&
		odr_sequence_end (o);
}

int z_EstimateType (ODR o, Z_EstimateType **p, int opt, const char *name)
{
	return odr_integer (o, p, opt, name);
}
