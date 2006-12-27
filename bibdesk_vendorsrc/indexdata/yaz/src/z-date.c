/** \file z-date.c
    \brief ASN.1 Module UserInfoFormat-dateTime

    Generated automatically by YAZ ASN.1 Compiler 0.4
*/

#include <yaz/z-date.h>

int z_DateTime (ODR o, Z_DateTime **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_explicit_tag (o, z_Date,
			&(*p)->date, ODR_CONTEXT, 1, 1, "date") &&
		odr_explicit_tag (o, z_Time,
			&(*p)->time, ODR_CONTEXT, 2, 1, "time") &&
		odr_sequence_end (o);
}

int z_DateMonthAndDay (ODR o, Z_DateMonthAndDay **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, odr_integer,
			&(*p)->month, ODR_CONTEXT, 2, 0, "month") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->day, ODR_CONTEXT, 3, 1, "day") &&
		odr_sequence_end (o);
}

int z_DateQuarter (ODR o, Z_DateQuarter **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_DateQuarter_first,
		(Odr_fun) odr_null, "first"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_DateQuarter_second,
		(Odr_fun) odr_null, "second"},
		{ODR_IMPLICIT, ODR_CONTEXT, 3, Z_DateQuarter_third,
		(Odr_fun) odr_null, "third"},
		{ODR_IMPLICIT, ODR_CONTEXT, 4, Z_DateQuarter_fourth,
		(Odr_fun) odr_null, "fourth"},
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

int z_DateSeason (ODR o, Z_DateSeason **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_DateSeason_winter,
		(Odr_fun) odr_null, "winter"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_DateSeason_spring,
		(Odr_fun) odr_null, "spring"},
		{ODR_IMPLICIT, ODR_CONTEXT, 3, Z_DateSeason_summer,
		(Odr_fun) odr_null, "summer"},
		{ODR_IMPLICIT, ODR_CONTEXT, 4, Z_DateSeason_autumn,
		(Odr_fun) odr_null, "autumn"},
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

int z_Era (ODR o, Z_Era **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_Era_decade,
		(Odr_fun) odr_null, "decade"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_Era_century,
		(Odr_fun) odr_null, "century"},
		{ODR_IMPLICIT, ODR_CONTEXT, 3, Z_Era_millennium,
		(Odr_fun) odr_null, "millennium"},
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

int z_DateFlags (ODR o, Z_DateFlags **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, odr_null,
			&(*p)->circa, ODR_CONTEXT, 1, 1, "circa") &&
		odr_explicit_tag (o, z_Era,
			&(*p)->era, ODR_CONTEXT, 2, 1, "era") &&
		odr_sequence_end (o);
}

int z_Date (ODR o, Z_Date **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_Date_monthAndDay,
		(Odr_fun) z_DateMonthAndDay, "monthAndDay"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_Date_julianDay,
		(Odr_fun) odr_integer, "julianDay"},
		{ODR_IMPLICIT, ODR_CONTEXT, 3, Z_Date_weekNumber,
		(Odr_fun) odr_integer, "weekNumber"},
		{ODR_EXPLICIT, ODR_CONTEXT, 4, Z_Date_quarter,
		(Odr_fun) z_DateQuarter, "quarter"},
		{ODR_EXPLICIT, ODR_CONTEXT, 5, Z_Date_season,
		(Odr_fun) z_DateSeason, "season"},
		{-1, -1, -1, -1, (Odr_fun) 0, 0}
	};
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, odr_integer,
			&(*p)->year, ODR_CONTEXT, 1, 0, "year") &&
		((odr_constructed_begin (o, &(*p)->u, ODR_CONTEXT, 2, "partOfYear") &&
		odr_choice (o, arm, &(*p)->u, &(*p)->which, 0) &&
		odr_constructed_end (o)) || odr_ok(o)) &&
		odr_implicit_tag (o, z_DateFlags,
			&(*p)->flags, ODR_CONTEXT, 3, 1, "flags") &&
		odr_sequence_end (o);
}

int z_Time (ODR o, Z_Time **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_Time_local,
		(Odr_fun) odr_null, "local"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_Time_utc,
		(Odr_fun) odr_null, "utc"},
		{ODR_IMPLICIT, ODR_CONTEXT, 3, Z_Time_utcOffset,
		(Odr_fun) odr_integer, "utcOffset"},
		{-1, -1, -1, -1, (Odr_fun) 0, 0}
	};
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, odr_integer,
			&(*p)->hour, ODR_CONTEXT, 1, 0, "hour") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->minute, ODR_CONTEXT, 2, 1, "minute") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->second, ODR_CONTEXT, 3, 1, "second") &&
		odr_implicit_tag (o, z_IntUnit,
			&(*p)->partOfSecond, ODR_CONTEXT, 4, 1, "partOfSecond") &&
		odr_constructed_begin (o, &(*p)->u, ODR_CONTEXT, 5, "zone") &&
		odr_choice (o, arm, &(*p)->u, &(*p)->which, 0) &&
		odr_constructed_end (o) &&
		odr_sequence_end (o);
}
