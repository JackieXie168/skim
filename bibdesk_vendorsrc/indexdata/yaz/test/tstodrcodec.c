/** \file tstodrcodec.c
    \brief ASN.1 Module tstodrcodec

    Generated automatically by YAZ ASN.1 Compiler 0.4
*/

#include <tstodrcodec.h>

int yc_MySequence (ODR o, Yc_MySequence **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, odr_integer,
			&(*p)->first, ODR_CONTEXT, 1, 0, "first") &&
		odr_implicit_tag (o, odr_octetstring,
			&(*p)->second, ODR_CONTEXT, 2, 0, "second") &&
		odr_implicit_tag (o, odr_bool,
			&(*p)->third, ODR_CONTEXT, 3, 0, "third") &&
		odr_implicit_tag (o, odr_null,
			&(*p)->fourth, ODR_CONTEXT, 4, 0, "fourth") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->fifth, ODR_CONTEXT, 5, 0, "fifth") &&
		odr_implicit_tag (o, odr_oid,
			&(*p)->myoid, ODR_CONTEXT, 6, 0, "myoid") &&
		odr_sequence_end (o);
}
