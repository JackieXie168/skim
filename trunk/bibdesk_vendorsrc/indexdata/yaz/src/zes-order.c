/** \file zes-order.c
    \brief ASN.1 Module ESFormat-ItemOrder

    Generated automatically by YAZ ASN.1 Compiler 0.4
*/

#include <yaz/zes-order.h>

int z_IORequest (ODR o, Z_IORequest **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_explicit_tag (o, z_IOOriginPartToKeep,
			&(*p)->toKeep, ODR_CONTEXT, 1, 1, "toKeep") &&
		odr_explicit_tag (o, z_IOOriginPartNotToKeep,
			&(*p)->notToKeep, ODR_CONTEXT, 2, 0, "notToKeep") &&
		odr_sequence_end (o);
}

int z_IOTaskPackage (ODR o, Z_IOTaskPackage **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_explicit_tag (o, z_IOOriginPartToKeep,
			&(*p)->originPart, ODR_CONTEXT, 1, 1, "originPart") &&
		odr_explicit_tag (o, z_IOTargetPart,
			&(*p)->targetPart, ODR_CONTEXT, 2, 0, "targetPart") &&
		odr_sequence_end (o);
}

int z_IOItemOrder (ODR o, Z_IOItemOrder **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_IOItemOrder_esRequest,
		(Odr_fun) z_IORequest, "esRequest"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_IOItemOrder_taskPackage,
		(Odr_fun) z_IOTaskPackage, "taskPackage"},
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

int z_IOContact (ODR o, Z_IOContact **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->name, ODR_CONTEXT, 1, 1, "name") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->phone, ODR_CONTEXT, 2, 1, "phone") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->email, ODR_CONTEXT, 3, 1, "email") &&
		odr_sequence_end (o);
}

int z_IOBilling (ODR o, Z_IOBilling **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 0, Z_IOBilling_billInvoice,
		(Odr_fun) odr_null, "billInvoice"},
		{ODR_IMPLICIT, ODR_CONTEXT, 1, Z_IOBilling_prepay,
		(Odr_fun) odr_null, "prepay"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, Z_IOBilling_depositAccount,
		(Odr_fun) odr_null, "depositAccount"},
		{ODR_IMPLICIT, ODR_CONTEXT, 3, Z_IOBilling_creditCard,
		(Odr_fun) z_IOCreditCardInfo, "creditCard"},
		{ODR_IMPLICIT, ODR_CONTEXT, 4, Z_IOBilling_cardInfoPreviouslySupplied,
		(Odr_fun) odr_null, "cardInfoPreviouslySupplied"},
		{ODR_IMPLICIT, ODR_CONTEXT, 5, Z_IOBilling_privateKnown,
		(Odr_fun) odr_null, "privateKnown"},
		{ODR_IMPLICIT, ODR_CONTEXT, 6, Z_IOBilling_privateNotKnown,
		(Odr_fun) z_External, "privateNotKnown"},
		{-1, -1, -1, -1, (Odr_fun) 0, 0}
	};
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_constructed_begin (o, &(*p)->u, ODR_CONTEXT, 1, "paymentMethod") &&
		odr_choice (o, arm, &(*p)->u, &(*p)->which, 0) &&
		odr_constructed_end (o) &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->customerReference, ODR_CONTEXT, 2, 1, "customerReference") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->customerPONumber, ODR_CONTEXT, 3, 1, "customerPONumber") &&
		odr_sequence_end (o);
}

int z_IOOriginPartToKeep (ODR o, Z_IOOriginPartToKeep **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_External,
			&(*p)->supplDescription, ODR_CONTEXT, 1, 1, "supplDescription") &&
		odr_implicit_tag (o, z_IOContact,
			&(*p)->contact, ODR_CONTEXT, 2, 1, "contact") &&
		odr_implicit_tag (o, z_IOBilling,
			&(*p)->addlBilling, ODR_CONTEXT, 3, 1, "addlBilling") &&
		odr_sequence_end (o);
}

int z_IOCreditCardInfo (ODR o, Z_IOCreditCardInfo **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->nameOnCard, ODR_CONTEXT, 1, 0, "nameOnCard") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->expirationDate, ODR_CONTEXT, 2, 0, "expirationDate") &&
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->cardNumber, ODR_CONTEXT, 3, 0, "cardNumber") &&
		odr_sequence_end (o);
}

int z_IOResultSetItem (ODR o, Z_IOResultSetItem **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_InternationalString,
			&(*p)->resultSetId, ODR_CONTEXT, 1, 0, "resultSetId") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->item, ODR_CONTEXT, 2, 0, "item") &&
		odr_sequence_end (o);
}

int z_IOOriginPartNotToKeep (ODR o, Z_IOOriginPartNotToKeep **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_IOResultSetItem,
			&(*p)->resultSetItem, ODR_CONTEXT, 1, 1, "resultSetItem") &&
		odr_implicit_tag (o, z_External,
			&(*p)->itemRequest, ODR_CONTEXT, 2, 1, "itemRequest") &&
		odr_sequence_end (o);
}

int z_IOTargetPart (ODR o, Z_IOTargetPart **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, z_External,
			&(*p)->itemRequest, ODR_CONTEXT, 1, 1, "itemRequest") &&
		odr_implicit_tag (o, z_External,
			&(*p)->statusOrErrorReport, ODR_CONTEXT, 2, 1, "statusOrErrorReport") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->auxiliaryStatus, ODR_CONTEXT, 3, 1, "auxiliaryStatus") &&
		odr_sequence_end (o);
}
