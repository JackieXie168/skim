/** \file z-grs.c
    \brief ASN.1 Module RecordSyntax-generic

    Generated automatically by YAZ ASN.1 Compiler 0.4
*/

#include <yaz/z-grs.h>

int z_GenericRecord (ODR o, Z_GenericRecord **p, int opt, const char *name)
{
	if (!odr_initmember (o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_sequence_of (o, (Odr_fun) z_TaggedElement, &(*p)->elements,
		&(*p)->num_elements, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int z_TaggedElement (ODR o, Z_TaggedElement **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, odr_integer,
			&(*p)->tagType, ODR_CONTEXT, 1, 1, "tagType") &&
		odr_explicit_tag (o, z_StringOrNumeric,
			&(*p)->tagValue, ODR_CONTEXT, 2, 0, "tagValue") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->tagOccurrence, ODR_CONTEXT, 3, 1, "tagOccurrence") &&
		odr_explicit_tag (o, z_ElementData,
			&(*p)->content, ODR_CONTEXT, 4, 0, "content") &&
		odr_implicit_tag (o, z_ElementMetaData,
			&(*p)->metaData, ODR_CONTEXT, 5, 1, "metaData") &&
		odr_implicit_tag (o, z_Variant,
			&(*p)->appliedVariant, ODR_CONTEXT, 6, 1, "appliedVariant") &&
		odr_sequence_end (o);
}

int z_ElementData (ODR o, Z_ElementData **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{-1, -1, -1, Z_ElementData_octets,
		 (Odr_fun) odr_octetstring, "octets"},
		{-1, -1, -1, Z_ElementData_numeric,
		 (Odr_fun) odr_integer, "numeric"},
		{-1, -1, -1, Z_ElementData_date,
		 (Odr_fun) odr_generalizedtime, "date"},
		{-1, -1, -1, Z_ElementData_ext,
		 (Odr_fun) z_External, "ext"},
		{-1, -1, -1, Z_ElementData_string,
		 (Odr_fun) z_InternationalString, "string"},
		{-1, -1, -1, Z_ElementData_trueOrFalse,
		 (Odr_fun) odr_bool, "trueOrFalse"},
		{-1, -1, -1, Z_ElementData_oid,
		 (Odr_fun) odr_oid, "oid"},
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_ElementData_intUnit,
		(Odr_fun) z_IntUnit, "intUnit"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_ElementData_elementNotThere,
		(Odr_fun) odr_null, "elementNotThere"},
		{ODR_IMPLICIT, ODR_CONTEXT, 3, Z_ElementData_elementEmpty,
		(Odr_fun) odr_null, "elementEmpty"},
		{ODR_IMPLICIT, ODR_CONTEXT, 4, Z_ElementData_noDataRequested,
		(Odr_fun) odr_null, "noDataRequested"},
		{ODR_IMPLICIT, ODR_CONTEXT, 5, Z_ElementData_diagnostic,
		(Odr_fun) z_External, "diagnostic"},
		{ODR_EXPLICIT, ODR_CONTEXT, 6, Z_ElementData_subtree,
		(Odr_fun) z_GenericRecord, "subtree"},
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

int z_ElementMetaData (ODR o, Z_ElementMetaData **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_Order,
			&(*p)->seriesOrder, ODR_CONTEXT, 1, 1, "seriesOrder") &&
		odr_implicit_tag (o, z_Usage,
			&(*p)->usageRight, ODR_CONTEXT, 2, 1, "usageRight") &&
		odr_implicit_settag (o, ODR_CONTEXT, 3) &&
		(odr_sequence_of(o, (Odr_fun) z_HitVector, &(*p)->hits,
		  &(*p)->num_hits, "hits") || odr_ok(o)) &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->displayName, ODR_CONTEXT, 4, 1, "displayName") &&
		odr_implicit_settag (o, ODR_CONTEXT, 5) &&
		(odr_sequence_of(o, (Odr_fun) z_Variant, &(*p)->supportedVariants,
		  &(*p)->num_supportedVariants, "supportedVariants") || odr_ok(o)) &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->message, ODR_CONTEXT, 6, 1, "message") &&
		odr_implicit_tag (o, odr_octetstring,
			&(*p)->elementDescriptor, ODR_CONTEXT, 7, 1, "elementDescriptor") &&
		odr_implicit_tag (o, z_TagPath,
			&(*p)->surrogateFor, ODR_CONTEXT, 8, 1, "surrogateFor") &&
		odr_implicit_tag (o, z_TagPath,
			&(*p)->surrogateElement, ODR_CONTEXT, 9, 1, "surrogateElement") &&
		odr_implicit_tag (o, z_External,
			&(*p)->other, ODR_CONTEXT, 99, 1, "other") &&
		odr_sequence_end (o);
}

int z_TagPath_s (ODR o, Z_TagPath_s **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, odr_integer,
			&(*p)->tagType, ODR_CONTEXT, 1, 1, "tagType") &&
		odr_explicit_tag (o, z_StringOrNumeric,
			&(*p)->tagValue, ODR_CONTEXT, 2, 0, "tagValue") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->tagOccurrence, ODR_CONTEXT, 3, 1, "tagOccurrence") &&
		odr_sequence_end (o);
}

int z_TagPath (ODR o, Z_TagPath **p, int opt, const char *name)
{
	if (!odr_initmember (o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_sequence_of (o, (Odr_fun) z_TagPath_s, &(*p)->elements,
		&(*p)->num, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int z_Order (ODR o, Z_Order **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, odr_bool,
			&(*p)->ascending, ODR_CONTEXT, 1, 0, "ascending") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->order, ODR_CONTEXT, 2, 0, "order") &&
		odr_sequence_end (o);
}

int z_Usage (ODR o, Z_Usage **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, odr_integer,
			&(*p)->type, ODR_CONTEXT, 1, 0, "type") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->restriction, ODR_CONTEXT, 2, 1, "restriction") &&
		odr_sequence_end (o);
}

int z_HitVector (ODR o, Z_HitVector **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		z_Term(o, &(*p)->satisfier, 1, "satisfier") &&
		odr_implicit_tag (o, z_IntUnit,
			&(*p)->offsetIntoElement, ODR_CONTEXT, 1, 1, "offsetIntoElement") &&
		odr_implicit_tag (o, z_IntUnit,
			&(*p)->length, ODR_CONTEXT, 2, 1, "length") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->hitRank, ODR_CONTEXT, 3, 1, "hitRank") &&
		odr_implicit_tag (o, odr_octetstring,
			&(*p)->targetToken, ODR_CONTEXT, 4, 1, "targetToken") &&
		odr_sequence_end (o);
}

int z_Triple (ODR o, Z_Triple **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{-1, -1, -1, Z_Triple_integer,
		 (Odr_fun) odr_integer, "integer"},
		{-1, -1, -1, Z_Triple_internationalString,
		 (Odr_fun) z_InternationalString, "internationalString"},
		{-1, -1, -1, Z_Triple_octetString,
		 (Odr_fun) odr_octetstring, "octetString"},
		{-1, -1, -1, Z_Triple_objectIdentifier,
		 (Odr_fun) odr_oid, "objectIdentifier"},
		{-1, -1, -1, Z_Triple_boolean,
		 (Odr_fun) odr_bool, "boolean"},
		{-1, -1, -1, Z_Triple_null,
		 (Odr_fun) odr_null, "null"},
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_Triple_unit,
		(Odr_fun) z_Unit, "unit"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_Triple_valueAndUnit,
		(Odr_fun) z_IntUnit, "valueAndUnit"},
		{-1, -1, -1, -1, (Odr_fun) 0, 0}
	};
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, odr_oid,
			&(*p)->variantSetId, ODR_CONTEXT, 0, 1, "variantSetId") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->zclass, ODR_CONTEXT, 1, 0, "zclass") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->type, ODR_CONTEXT, 2, 0, "type") &&
		odr_constructed_begin (o, &(*p)->value, ODR_CONTEXT, 3, "value") &&
		odr_choice (o, arm, &(*p)->value, &(*p)->which, 0) &&
		odr_constructed_end (o) &&
		odr_sequence_end (o);
}

int z_Variant (ODR o, Z_Variant **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, odr_oid,
			&(*p)->globalVariantSetId, ODR_CONTEXT, 1, 1, "globalVariantSetId") &&
		odr_implicit_settag (o, ODR_CONTEXT, 2) &&
		odr_sequence_of(o, (Odr_fun) z_Triple, &(*p)->triples,
		  &(*p)->num_triples, "triples") &&
		odr_sequence_end (o);
}
