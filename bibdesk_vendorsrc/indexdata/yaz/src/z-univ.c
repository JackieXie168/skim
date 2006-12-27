/** \file z-univ.c
    \brief ASN.1 Module ResourceReport-Format-Universe-1

    Generated automatically by YAZ ASN.1 Compiler 0.4
*/

#include <yaz/z-univ.h>

int z_UniverseReportHits (ODR o, Z_UniverseReportHits **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		z_StringOrNumeric(o, &(*p)->database, 0, "database") &&
		z_StringOrNumeric(o, &(*p)->hits, 0, "hits") &&
		odr_sequence_end (o);
}

int z_UniverseReportDuplicate (ODR o, Z_UniverseReportDuplicate **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		z_StringOrNumeric(o, &(*p)->hitno, 0, "hitno") &&
		odr_sequence_end (o);
}

int z_UniverseReport (ODR o, Z_UniverseReport **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 0, Z_UniverseReport_databaseHits,
		(Odr_fun) z_UniverseReportHits, "databaseHits"},
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_UniverseReport_duplicate,
		(Odr_fun) z_UniverseReportDuplicate, "duplicate"},
		{-1, -1, -1, -1, (Odr_fun) 0, 0}
	};
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_integer(o, &(*p)->totalHits, 0, "totalHits") &&
		odr_choice (o, arm, &(*p)->u, &(*p)->which, 0) &&
		odr_sequence_end (o);
}
