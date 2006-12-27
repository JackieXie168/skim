/** \file z-uifr1.c
    \brief ASN.1 Module UserInfoFormat-searchResult-1

    Generated automatically by YAZ ASN.1 Compiler 0.4
*/

#include <yaz/z-uifr1.h>

int z_SearchInfoReport_s (ODR o, Z_SearchInfoReport_s **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->subqueryId, ODR_CONTEXT, 1, 1, "subqueryId") &&
		odr_implicit_tag (o, odr_bool,
			&(*p)->fullQuery, ODR_CONTEXT, 2, 0, "fullQuery") &&
		odr_explicit_tag (o, z_QueryExpression,
			&(*p)->subqueryExpression, ODR_CONTEXT, 3, 1, "subqueryExpression") &&
		odr_explicit_tag (o, z_QueryExpression,
			&(*p)->subqueryInterpretation, ODR_CONTEXT, 4, 1, "subqueryInterpretation") &&
		odr_explicit_tag (o, z_QueryExpression,
			&(*p)->subqueryRecommendation, ODR_CONTEXT, 5, 1, "subqueryRecommendation") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->subqueryCount, ODR_CONTEXT, 6, 1, "subqueryCount") &&
		odr_implicit_tag (o, z_IntUnit,
			&(*p)->subqueryWeight, ODR_CONTEXT, 7, 1, "subqueryWeight") &&
		odr_implicit_tag (o, z_ResultsByDB,
			&(*p)->resultsByDB, ODR_CONTEXT, 8, 1, "resultsByDB") &&
		odr_sequence_end (o);
}

int z_SearchInfoReport (ODR o, Z_SearchInfoReport **p, int opt, const char *name)
{
	if (!odr_initmember (o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_sequence_of (o, (Odr_fun) z_SearchInfoReport_s, &(*p)->elements,
		&(*p)->num, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int z_ResultsByDB_sList (ODR o, Z_ResultsByDB_sList **p, int opt, const char *name)
{
	if (!odr_initmember (o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_sequence_of (o, (Odr_fun) z_DatabaseName, &(*p)->elements,
		&(*p)->num, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int z_ResultsByDB_s (ODR o, Z_ResultsByDB_s **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_ResultsByDB_s_all,
		(Odr_fun) odr_null, "all"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_ResultsByDB_s_list,
		(Odr_fun) z_ResultsByDB_sList, "list"},
		{-1, -1, -1, -1, (Odr_fun) 0, 0}
	};
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_constructed_begin (o, &(*p)->u, ODR_CONTEXT, 1, "databases") &&
		odr_choice (o, arm, &(*p)->u, &(*p)->which, 0) &&
		odr_constructed_end (o) &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->count, ODR_CONTEXT, 2, 1, "count") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->resultSetName, ODR_CONTEXT, 3, 1, "resultSetName") &&
		odr_sequence_end (o);
}

int z_ResultsByDB (ODR o, Z_ResultsByDB **p, int opt, const char *name)
{
	if (!odr_initmember (o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_sequence_of (o, (Odr_fun) z_ResultsByDB_s, &(*p)->elements,
		&(*p)->num, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int z_QueryExpressionTerm (ODR o, Z_QueryExpressionTerm **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_explicit_tag (o, z_Term,
			&(*p)->queryTerm, ODR_CONTEXT, 1, 0, "queryTerm") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->termComment, ODR_CONTEXT, 2, 1, "termComment") &&
		odr_sequence_end (o);
}

int z_QueryExpression (ODR o, Z_QueryExpression **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_QueryExpression_term,
		(Odr_fun) z_QueryExpressionTerm, "term"},
		{ODR_EXPLICIT, ODR_CONTEXT, 2, Z_QueryExpression_query,
		(Odr_fun) z_Query, "query"},
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
