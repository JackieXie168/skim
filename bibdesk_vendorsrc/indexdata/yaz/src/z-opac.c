/** \file z-opac.c
    \brief ASN.1 Module RecordSyntax-opac

    Generated automatically by YAZ ASN.1 Compiler 0.4
*/

#include <yaz/z-opac.h>

int z_OPACRecord (ODR o, Z_OPACRecord **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_External,
			&(*p)->bibliographicRecord, ODR_CONTEXT, 1, 1, "bibliographicRecord") &&
		odr_implicit_settag (o, ODR_CONTEXT, 2) &&
		(odr_sequence_of(o, (Odr_fun) z_HoldingsRecord, &(*p)->holdingsData,
		  &(*p)->num_holdingsData, "holdingsData") || odr_ok(o)) &&
		odr_sequence_end (o);
}

int z_HoldingsRecord (ODR o, Z_HoldingsRecord **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_HoldingsRecord_marcHoldingsRecord,
		(Odr_fun) z_External, "marcHoldingsRecord"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_HoldingsRecord_holdingsAndCirc,
		(Odr_fun) z_HoldingsAndCircData, "holdingsAndCirc"},
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

int z_HoldingsAndCircData (ODR o, Z_HoldingsAndCircData **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->typeOfRecord, ODR_CONTEXT, 1, 1, "typeOfRecord") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->encodingLevel, ODR_CONTEXT, 2, 1, "encodingLevel") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->format, ODR_CONTEXT, 3, 1, "format") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->receiptAcqStatus, ODR_CONTEXT, 4, 1, "receiptAcqStatus") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->generalRetention, ODR_CONTEXT, 5, 1, "generalRetention") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->completeness, ODR_CONTEXT, 6, 1, "completeness") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->dateOfReport, ODR_CONTEXT, 7, 1, "dateOfReport") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->nucCode, ODR_CONTEXT, 8, 1, "nucCode") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->localLocation, ODR_CONTEXT, 9, 1, "localLocation") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->shelvingLocation, ODR_CONTEXT, 10, 1, "shelvingLocation") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->callNumber, ODR_CONTEXT, 11, 1, "callNumber") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->shelvingData, ODR_CONTEXT, 12, 1, "shelvingData") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->copyNumber, ODR_CONTEXT, 13, 1, "copyNumber") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->publicNote, ODR_CONTEXT, 14, 1, "publicNote") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->reproductionNote, ODR_CONTEXT, 15, 1, "reproductionNote") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->termsUseRepro, ODR_CONTEXT, 16, 1, "termsUseRepro") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->enumAndChron, ODR_CONTEXT, 17, 1, "enumAndChron") &&
		odr_implicit_settag (o, ODR_CONTEXT, 18) &&
		(odr_sequence_of(o, (Odr_fun) z_Volume, &(*p)->volumes,
		  &(*p)->num_volumes, "volumes") || odr_ok(o)) &&
		odr_implicit_settag (o, ODR_CONTEXT, 19) &&
		(odr_sequence_of(o, (Odr_fun) z_CircRecord, &(*p)->circulationData,
		  &(*p)->num_circulationData, "circulationData") || odr_ok(o)) &&
		odr_sequence_end (o);
}

int z_Volume (ODR o, Z_Volume **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->enumeration, ODR_CONTEXT, 1, 1, "enumeration") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->chronology, ODR_CONTEXT, 2, 1, "chronology") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->enumAndChron, ODR_CONTEXT, 3, 1, "enumAndChron") &&
		odr_sequence_end (o);
}

int z_CircRecord (ODR o, Z_CircRecord **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, odr_bool,
			&(*p)->availableNow, ODR_CONTEXT, 1, 0, "availableNow") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->availablityDate, ODR_CONTEXT, 2, 1, "availablityDate") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->availableThru, ODR_CONTEXT, 3, 1, "availableThru") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->restrictions, ODR_CONTEXT, 4, 1, "restrictions") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->itemId, ODR_CONTEXT, 5, 1, "itemId") &&
		odr_implicit_tag (o, odr_bool,
			&(*p)->renewable, ODR_CONTEXT, 6, 0, "renewable") &&
		odr_implicit_tag (o, odr_bool,
			&(*p)->onHold, ODR_CONTEXT, 7, 0, "onHold") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->enumAndChron, ODR_CONTEXT, 8, 1, "enumAndChron") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->midspine, ODR_CONTEXT, 9, 1, "midspine") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->temporaryLocation, ODR_CONTEXT, 10, 1, "temporaryLocation") &&
		odr_sequence_end (o);
}
