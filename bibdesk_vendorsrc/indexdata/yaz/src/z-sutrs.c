/** \file z-sutrs.c
    \brief ASN.1 Module RecordSyntax-SUTRS

    Generated automatically by YAZ ASN.1 Compiler 0.4
*/

#include <yaz/z-sutrs.h>

int z_SutrsRecord (ODR o, Z_SutrsRecord **p, int opt, const char *name)
{
	return z_InternationalString (o, p, opt, name);
}

int z_SUTRS (ODR o, Odr_oct **p, int opt, const char *name)
{
    return odr_implicit_tag(o, odr_octetstring, p, ODR_UNIVERSAL,
        ODR_GENERALSTRING, opt, name);
}

