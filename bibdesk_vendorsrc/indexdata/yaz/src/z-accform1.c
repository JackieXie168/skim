/** \file z-accform1.c
    \brief ASN.1 Module AccessControlFormat-prompt-1

    Generated automatically by YAZ ASN.1 Compiler 0.4
*/

#include <yaz/z-accform1.h>

int z_PromptObject1 (ODR o, Z_PromptObject1 **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_PromptObject1_challenge,
		(Odr_fun) z_Challenge1, "challenge"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_PromptObject1_response,
		(Odr_fun) z_Response1, "response"},
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

int z_ChallengeUnit1 (ODR o, Z_ChallengeUnit1 **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_ChallengeUnit1_character,
		(Odr_fun) z_InternationalString, "character"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_ChallengeUnit1_encrypted,
		(Odr_fun) z_Encryption, "encrypted"},
		{-1, -1, -1, -1, (Odr_fun) 0, 0}
	};
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_explicit_tag (o, z_PromptId,
			&(*p)->promptId, ODR_CONTEXT, 1, 0, "promptId") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->defaultResponse, ODR_CONTEXT, 2, 1, "defaultResponse") &&
		((odr_constructed_begin (o, &(*p)->u, ODR_CONTEXT, 3, "promptInfo") &&
		odr_choice (o, arm, &(*p)->u, &(*p)->which, 0) &&
		odr_constructed_end (o)) || odr_ok(o)) &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->regExpr, ODR_CONTEXT, 4, 1, "regExpr") &&
		odr_implicit_tag (o, odr_null,
			&(*p)->responseRequired, ODR_CONTEXT, 5, 1, "responseRequired") &&
		odr_implicit_settag (o, ODR_CONTEXT, 6) &&
		(odr_sequence_of(o, (Odr_fun) z_InternationalString, &(*p)->allowedValues,
		  &(*p)->num_allowedValues, "allowedValues") || odr_ok(o)) &&
		odr_implicit_tag (o, odr_null,
			&(*p)->shouldSave, ODR_CONTEXT, 7, 1, "shouldSave") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->dataType, ODR_CONTEXT, 8, 1, "dataType") &&
		odr_implicit_tag (o, z_External,
			&(*p)->diagnostic, ODR_CONTEXT, 9, 1, "diagnostic") &&
		odr_sequence_end (o);
}

int z_Challenge1 (ODR o, Z_Challenge1 **p, int opt, const char *name)
{
	if (!odr_initmember (o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_sequence_of (o, (Odr_fun) z_ChallengeUnit1, &(*p)->elements,
		&(*p)->num, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int z_ResponseUnit1 (ODR o, Z_ResponseUnit1 **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_ResponseUnit1_string,
		(Odr_fun) z_InternationalString, "string"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_ResponseUnit1_accept,
		(Odr_fun) odr_bool, "accept"},
		{ODR_IMPLICIT, ODR_CONTEXT, 3, Z_ResponseUnit1_acknowledge,
		(Odr_fun) odr_null, "acknowledge"},
		{ODR_EXPLICIT, ODR_CONTEXT, 4, Z_ResponseUnit1_diagnostic,
		(Odr_fun) z_DiagRec, "diagnostic"},
		{ODR_IMPLICIT, ODR_CONTEXT, 5, Z_ResponseUnit1_encrypted,
		(Odr_fun) z_Encryption, "encrypted"},
		{-1, -1, -1, -1, (Odr_fun) 0, 0}
	};
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_explicit_tag (o, z_PromptId,
			&(*p)->promptId, ODR_CONTEXT, 1, 0, "promptId") &&
		odr_constructed_begin (o, &(*p)->u, ODR_CONTEXT, 2, "promptResponse") &&
		odr_choice (o, arm, &(*p)->u, &(*p)->which, 0) &&
		odr_constructed_end (o) &&
		odr_sequence_end (o);
}

int z_Response1 (ODR o, Z_Response1 **p, int opt, const char *name)
{
	if (!odr_initmember (o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_sequence_of (o, (Odr_fun) z_ResponseUnit1, &(*p)->elements,
		&(*p)->num, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int z_PromptIdEnumeratedPrompt (ODR o, Z_PromptIdEnumeratedPrompt **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, odr_integer,
			&(*p)->type, ODR_CONTEXT, 1, 0, "type") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->suggestedString, ODR_CONTEXT, 2, 1, "suggestedString") &&
		odr_sequence_end (o);
}

int z_PromptId (ODR o, Z_PromptId **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_PromptId_enumeratedPrompt,
		(Odr_fun) z_PromptIdEnumeratedPrompt, "enumeratedPrompt"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_PromptId_nonEnumeratedPrompt,
		(Odr_fun) z_InternationalString, "nonEnumeratedPrompt"},
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

int z_Encryption (ODR o, Z_Encryption **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, odr_octetstring,
			&(*p)->cryptType, ODR_CONTEXT, 1, 1, "cryptType") &&
		odr_implicit_tag (o, odr_octetstring,
			&(*p)->credential, ODR_CONTEXT, 2, 1, "credential") &&
		odr_implicit_tag (o, odr_octetstring,
			&(*p)->data, ODR_CONTEXT, 3, 0, "data") &&
		odr_sequence_end (o);
}
