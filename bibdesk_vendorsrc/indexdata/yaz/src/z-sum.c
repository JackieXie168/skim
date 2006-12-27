/** \file z-sum.c
    \brief ASN.1 Module RecordSyntax-summary

    Generated automatically by YAZ ASN.1 Compiler 0.4
*/

#include <yaz/z-sum.h>

int z_BriefBib (ODR o, Z_BriefBib **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->title, ODR_CONTEXT, 1, 0, "title") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->author, ODR_CONTEXT, 2, 1, "author") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->callNumber, ODR_CONTEXT, 3, 1, "callNumber") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->recordType, ODR_CONTEXT, 4, 1, "recordType") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->bibliographicLevel, ODR_CONTEXT, 5, 1, "bibliographicLevel") &&
		odr_implicit_settag (o, ODR_CONTEXT, 6) &&
		(odr_sequence_of(o, (Odr_fun) z_FormatSpec, &(*p)->format,
		  &(*p)->num_format, "format") || odr_ok(o)) &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->publicationPlace, ODR_CONTEXT, 7, 1, "publicationPlace") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->publicationDate, ODR_CONTEXT, 8, 1, "publicationDate") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->targetSystemKey, ODR_CONTEXT, 9, 1, "targetSystemKey") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->satisfyingElement, ODR_CONTEXT, 10, 1, "satisfyingElement") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->rank, ODR_CONTEXT, 11, 1, "rank") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->documentId, ODR_CONTEXT, 12, 1, "documentId") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->abstract, ODR_CONTEXT, 13, 1, "abstract") &&
		z_OtherInformation(o, &(*p)->otherInfo, 1, "otherInfo") &&
		odr_sequence_end (o);
}

int z_FormatSpec (ODR o, Z_FormatSpec **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->type, ODR_CONTEXT, 1, 0, "type") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->size, ODR_CONTEXT, 2, 1, "size") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->bestPosn, ODR_CONTEXT, 3, 1, "bestPosn") &&
		odr_sequence_end (o);
}
