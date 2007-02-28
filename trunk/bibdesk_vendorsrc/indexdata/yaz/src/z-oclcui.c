/** \file z-oclcui.c
    \brief ASN.1 Module UserInfoFormat-oclcUserInformation

    Generated automatically by YAZ ASN.1 Compiler 0.4
*/

#include <yaz/z-oclcui.h>

int z_OCLC_UserInformation (ODR o, Z_OCLC_UserInformation **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, odr_visiblestring,
			&(*p)->motd, ODR_CONTEXT, 1, 1, "motd") &&
		(odr_sequence_of(o, (Odr_fun) z_DBName, &(*p)->dblist,
		  &(*p)->num_dblist, "dblist") || odr_ok(o)) &&
		odr_implicit_tag (o, odr_bool,
			&(*p)->failReason, ODR_CONTEXT, 3, 1, "failReason") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->code, ODR_CONTEXT, 1, 1, "code") &&
		odr_implicit_tag (o, odr_visiblestring,
			&(*p)->text, ODR_CONTEXT, 2, 1, "text") &&
		odr_sequence_end (o);
}

int z_DBName (ODR o, Z_DBName **p, int opt, const char *name)
{
	return odr_implicit_tag (o, odr_visiblestring, p, ODR_CONTEXT, 2, opt, name);
}
