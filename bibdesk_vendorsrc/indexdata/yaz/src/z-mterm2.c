/** \file z-mterm2.c
    \brief ASN.1 Module UserInfoFormat-multipleSearchTerms-2

    Generated automatically by YAZ ASN.1 Compiler 0.4
*/

#include <yaz/z-mterm2.h>

int z_MultipleSearchTerms_2_s (ODR o, Z_MultipleSearchTerms_2_s **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_explicit_tag (o, z_Term,
			&(*p)->term, ODR_CONTEXT, 1, 0, "term") &&
		odr_implicit_tag (o, odr_bool,
			&(*p)->flag, ODR_CONTEXT, 2, 1, "flag") &&
		odr_sequence_end (o);
}

int z_MultipleSearchTerms_2 (ODR o, Z_MultipleSearchTerms_2 **p, int opt, const char *name)
{
	if (!odr_initmember (o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_sequence_of (o, (Odr_fun) z_MultipleSearchTerms_2_s, &(*p)->elements,
		&(*p)->num, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}
