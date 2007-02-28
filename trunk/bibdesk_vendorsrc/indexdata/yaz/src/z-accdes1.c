/** \file z-accdes1.c
    \brief ASN.1 Module AccessControlFormat-des-1

    Generated automatically by YAZ ASN.1 Compiler 0.4
*/

#include <yaz/z-accdes1.h>

int z_DES_RN_Object (ODR o, Z_DES_RN_Object **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_DES_RN_Object_challenge,
		(Odr_fun) z_DRNType, "challenge"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_DES_RN_Object_response,
		(Odr_fun) z_DRNType, "response"},
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

int z_DRNType (ODR o, Z_DRNType **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, odr_octetstring,
			&(*p)->userId, ODR_CONTEXT, 1, 1, "userId") &&
		odr_implicit_tag (o, odr_octetstring,
			&(*p)->salt, ODR_CONTEXT, 2, 1, "salt") &&
		odr_implicit_tag (o, odr_octetstring,
			&(*p)->randomNumber, ODR_CONTEXT, 3, 0, "randomNumber") &&
		odr_sequence_end (o);
}
