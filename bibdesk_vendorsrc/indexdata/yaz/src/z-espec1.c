/** \file z-espec1.c
    \brief ASN.1 Module ElementSpecificationFormat-eSpec-1

    Generated automatically by YAZ ASN.1 Compiler 0.4
*/

#include <yaz/z-espec1.h>

int z_Espec1 (ODR o, Z_Espec1 **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_settag (o, ODR_CONTEXT, 1) &&
		(odr_sequence_of(o, (Odr_fun) z_InternationalString, &(*p)->elementSetNames,
		  &(*p)->num_elementSetNames, "elementSetNames") || odr_ok(o)) &&
		odr_implicit_tag (o, odr_oid,
			&(*p)->defaultVariantSetId, ODR_CONTEXT, 2, 1, "defaultVariantSetId") &&
		odr_implicit_tag (o, z_Variant,
			&(*p)->defaultVariantRequest, ODR_CONTEXT, 3, 1, "defaultVariantRequest") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->defaultTagType, ODR_CONTEXT, 4, 1, "defaultTagType") &&
		odr_implicit_settag (o, ODR_CONTEXT, 5) &&
		(odr_sequence_of(o, (Odr_fun) z_ElementRequest, &(*p)->elements,
		  &(*p)->num_elements, "elements") || odr_ok(o)) &&
		odr_sequence_end (o);
}

int z_ElementRequestCompositeElementPrimitives (ODR o, Z_ElementRequestCompositeElementPrimitives **p, int opt, const char *name)
{
	if (!odr_initmember (o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_sequence_of (o, (Odr_fun) z_InternationalString, &(*p)->elements,
		&(*p)->num, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int z_ElementRequestCompositeElementSpecs (ODR o, Z_ElementRequestCompositeElementSpecs **p, int opt, const char *name)
{
	if (!odr_initmember (o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_sequence_of (o, (Odr_fun) z_SimpleElement, &(*p)->elements,
		&(*p)->num, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int z_ElementRequestCompositeElement (ODR o, Z_ElementRequestCompositeElement **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_ElementRequestCompositeElement_primitives,
		(Odr_fun) z_ElementRequestCompositeElementPrimitives, "primitives"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_ElementRequestCompositeElement_specs,
		(Odr_fun) z_ElementRequestCompositeElementSpecs, "specs"},
		{-1, -1, -1, -1, (Odr_fun) 0, 0}
	};
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_constructed_begin (o, &(*p)->u, ODR_CONTEXT, 1, "elementList") &&
		odr_choice (o, arm, &(*p)->u, &(*p)->which, 0) &&
		odr_constructed_end (o) &&
		odr_implicit_tag (o, z_ETagPath,
			&(*p)->deliveryTag, ODR_CONTEXT, 2, 0, "deliveryTag") &&
		odr_implicit_tag (o, z_Variant,
			&(*p)->variantRequest, ODR_CONTEXT, 3, 1, "variantRequest") &&
		odr_sequence_end (o);
}

int z_ElementRequest (ODR o, Z_ElementRequest **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_ERequest_simpleElement,
		(Odr_fun) z_SimpleElement, "simpleElement"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_ERequest_compositeElement,
		(Odr_fun) z_ElementRequestCompositeElement, "compositeElement"},
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

int z_SimpleElement (ODR o, Z_SimpleElement **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_ETagPath,
			&(*p)->path, ODR_CONTEXT, 1, 0, "path") &&
		odr_implicit_tag (o, z_Variant,
			&(*p)->variantRequest, ODR_CONTEXT, 2, 1, "variantRequest") &&
		odr_sequence_end (o);
}

int z_SpecificTag (ODR o, Z_SpecificTag **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, odr_integer,
			&(*p)->tagType, ODR_CONTEXT, 1, 1, "tagType") &&
		odr_explicit_tag (o, z_StringOrNumeric,
			&(*p)->tagValue, ODR_CONTEXT, 2, 0, "tagValue") &&
		odr_explicit_tag (o, z_Occurrences,
			&(*p)->occurrences, ODR_CONTEXT, 3, 1, "occurrences") &&
		odr_sequence_end (o);
}

int z_ETagUnit (ODR o, Z_ETagUnit **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_ETagUnit_specificTag,
		(Odr_fun) z_SpecificTag, "specificTag"},
		{ODR_EXPLICIT, ODR_CONTEXT, 2, Z_ETagUnit_wildThing,
		(Odr_fun) z_Occurrences, "wildThing"},
		{ODR_IMPLICIT, ODR_CONTEXT, 3, Z_ETagUnit_wildPath,
		(Odr_fun) odr_null, "wildPath"},
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

int z_ETagPath (ODR o, Z_ETagPath **p, int opt, const char *name)
{
	if (!odr_initmember (o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_sequence_of (o, (Odr_fun) z_ETagUnit, &(*p)->tags,
		&(*p)->num_tags, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int z_OccurValues (ODR o, Z_OccurValues **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, odr_integer,
			&(*p)->start, ODR_CONTEXT, 1, 0, "start") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->howMany, ODR_CONTEXT, 2, 1, "howMany") &&
		odr_sequence_end (o);
}

int z_Occurrences (ODR o, Z_Occurrences **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_Occurrences_all,
		(Odr_fun) odr_null, "all"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_Occurrences_last,
		(Odr_fun) odr_null, "last"},
		{ODR_IMPLICIT, ODR_CONTEXT, 3, Z_Occurrences_values,
		(Odr_fun) z_OccurValues, "values"},
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
