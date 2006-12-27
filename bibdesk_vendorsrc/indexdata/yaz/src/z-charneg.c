/** \file z-charneg.c
    \brief ASN.1 Module NegotiationRecordDefinition-charSetandLanguageNegotiation-3

    Generated automatically by YAZ ASN.1 Compiler 0.4
*/

#include <yaz/z-charneg.h>

int z_CharSetandLanguageNegotiation (ODR o, Z_CharSetandLanguageNegotiation **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_CharSetandLanguageNegotiation_proposal,
		(Odr_fun) z_OriginProposal, "proposal"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_CharSetandLanguageNegotiation_response,
		(Odr_fun) z_TargetResponse, "response"},
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

int z_OriginProposal_0 (ODR o, Z_OriginProposal_0 **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_EXPLICIT, ODR_CONTEXT, 1, Z_OriginProposal_0_iso2022,
		(Odr_fun) z_Iso2022, "iso2022"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_OriginProposal_0_iso10646,
		(Odr_fun) z_Iso10646, "iso10646"},
		{ODR_EXPLICIT, ODR_CONTEXT, 3, Z_OriginProposal_0_private,
		(Odr_fun) z_PrivateCharacterSet, "zprivate"},
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

int z_OriginProposal (ODR o, Z_OriginProposal **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_settag (o, ODR_CONTEXT, 1) &&
		(odr_sequence_of(o, (Odr_fun) z_OriginProposal_0, &(*p)->proposedCharSets,
		  &(*p)->num_proposedCharSets, "proposedCharSets") || odr_ok(o)) &&
		odr_implicit_settag (o, ODR_CONTEXT, 2) &&
		(odr_sequence_of(o, (Odr_fun) z_LanguageCode, &(*p)->proposedlanguages,
		  &(*p)->num_proposedlanguages, "proposedlanguages") || odr_ok(o)) &&
		odr_implicit_tag (o, odr_bool,
			&(*p)->recordsInSelectedCharSets, ODR_CONTEXT, 3, 1, "recordsInSelectedCharSets") &&
		odr_sequence_end (o);
}

int z_TargetResponse (ODR o, Z_TargetResponse **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_EXPLICIT, ODR_CONTEXT, 1, Z_TargetResponse_iso2022,
		(Odr_fun) z_Iso2022, "iso2022"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_TargetResponse_iso10646,
		(Odr_fun) z_Iso10646, "iso10646"},
		{ODR_EXPLICIT, ODR_CONTEXT, 3, Z_TargetResponse_private,
		(Odr_fun) z_PrivateCharacterSet, "zprivate"},
		{ODR_IMPLICIT, ODR_CONTEXT, 4, Z_TargetResponse_none,
		(Odr_fun) odr_null, "none"},
		{-1, -1, -1, -1, (Odr_fun) 0, 0}
	};
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		((odr_constructed_begin (o, &(*p)->u, ODR_CONTEXT, 1, "selectedCharSets") &&
		odr_choice (o, arm, &(*p)->u, &(*p)->which, 0) &&
		odr_constructed_end (o)) || odr_ok(o)) &&
		odr_implicit_tag (o, z_LanguageCode,
			&(*p)->selectedLanguage, ODR_CONTEXT, 2, 1, "selectedLanguage") &&
		odr_implicit_tag (o, odr_bool,
			&(*p)->recordsInSelectedCharSets, ODR_CONTEXT, 3, 1, "recordsInSelectedCharSets") &&
		odr_sequence_end (o);
}

int z_PrivateCharacterSetViaOid (ODR o, Z_PrivateCharacterSetViaOid **p, int opt, const char *name)
{
	if (!odr_initmember (o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_sequence_of (o, (Odr_fun) odr_oid, &(*p)->elements,
		&(*p)->num, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int z_PrivateCharacterSet (ODR o, Z_PrivateCharacterSet **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_PrivateCharacterSet_viaOid,
		(Odr_fun) z_PrivateCharacterSetViaOid, "viaOid"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_PrivateCharacterSet_externallySpecified,
		(Odr_fun) z_External, "externallySpecified"},
		{ODR_IMPLICIT, ODR_CONTEXT, 3, Z_PrivateCharacterSet_previouslyAgreedUpon,
		(Odr_fun) odr_null, "previouslyAgreedUpon"},
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

int z_Iso2022OriginProposal (ODR o, Z_Iso2022OriginProposal **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_explicit_tag (o, z_Environment,
			&(*p)->proposedEnvironment, ODR_CONTEXT, 0, 1, "proposedEnvironment") &&
		odr_implicit_settag (o, ODR_CONTEXT, 1) &&
		odr_sequence_of(o, (Odr_fun) odr_integer, &(*p)->proposedSets,
		  &(*p)->num_proposedSets, "proposedSets") &&
		odr_implicit_settag (o, ODR_CONTEXT, 2) &&
		odr_sequence_of(o, (Odr_fun) z_InitialSet, &(*p)->proposedInitialSets,
		  &(*p)->num_proposedInitialSets, "proposedInitialSets") &&
		odr_implicit_tag (o, z_LeftAndRight,
			&(*p)->proposedLeftAndRight, ODR_CONTEXT, 3, 0, "proposedLeftAndRight") &&
		odr_sequence_end (o);
}

int z_Iso2022TargetResponse (ODR o, Z_Iso2022TargetResponse **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_explicit_tag (o, z_Environment,
			&(*p)->selectedEnvironment, ODR_CONTEXT, 0, 0, "selectedEnvironment") &&
		odr_implicit_settag (o, ODR_CONTEXT, 1) &&
		odr_sequence_of(o, (Odr_fun) odr_integer, &(*p)->selectedSets,
		  &(*p)->num_selectedSets, "selectedSets") &&
		odr_implicit_tag (o, z_InitialSet,
			&(*p)->selectedinitialSet, ODR_CONTEXT, 2, 0, "selectedinitialSet") &&
		odr_implicit_tag (o, z_LeftAndRight,
			&(*p)->selectedLeftAndRight, ODR_CONTEXT, 3, 0, "selectedLeftAndRight") &&
		odr_sequence_end (o);
}

int z_Iso2022 (ODR o, Z_Iso2022 **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_Iso2022_originProposal,
		(Odr_fun) z_Iso2022OriginProposal, "originProposal"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_Iso2022_targetResponse,
		(Odr_fun) z_Iso2022TargetResponse, "targetResponse"},
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

int z_Environment (ODR o, Z_Environment **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_Environment_sevenBit,
		(Odr_fun) odr_null, "sevenBit"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_Environment_eightBit,
		(Odr_fun) odr_null, "eightBit"},
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

int z_InitialSet (ODR o, Z_InitialSet **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, odr_integer,
			&(*p)->g0, ODR_CONTEXT, 0, 1, "g0") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->g1, ODR_CONTEXT, 1, 1, "g1") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->g2, ODR_CONTEXT, 2, 1, "g2") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->g3, ODR_CONTEXT, 3, 1, "g3") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->c0, ODR_CONTEXT, 4, 0, "c0") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->c1, ODR_CONTEXT, 5, 1, "c1") &&
		odr_sequence_end (o);
}

int z_LeftAndRight (ODR o, Z_LeftAndRight **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, odr_integer,
			&(*p)->gLeft, ODR_CONTEXT, 3, 0, "gLeft") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->gRight, ODR_CONTEXT, 4, 1, "gRight") &&
		odr_sequence_end (o);
}

int z_Iso10646 (ODR o, Z_Iso10646 **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, odr_oid,
			&(*p)->collections, ODR_CONTEXT, 1, 1, "collections") &&
		odr_implicit_tag (o, odr_oid,
			&(*p)->encodingLevel, ODR_CONTEXT, 2, 0, "encodingLevel") &&
		odr_sequence_end (o);
}
