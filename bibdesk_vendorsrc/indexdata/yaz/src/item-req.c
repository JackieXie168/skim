/** \file item-req.c
    \brief ASN.1 Module Z39.50-extendedService-ItemOrder-ItemRequest-1

    Generated automatically by YAZ ASN.1 Compiler 0.4
*/

#include <yaz/item-req.h>

int ill_ItemRequest (ODR o, ILL_ItemRequest **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, odr_integer,
			&(*p)->protocol_version_num, ODR_CONTEXT, 0, 0, "protocol_version_num") &&
		odr_implicit_tag (o, ill_Transaction_Id,
			&(*p)->transaction_id, ODR_CONTEXT, 1, 1, "transaction_id") &&
		odr_implicit_tag (o, ill_Service_Date_Time,
			&(*p)->service_date_time, ODR_CONTEXT, 2, 1, "service_date_time") &&
		odr_implicit_tag (o, ill_System_Id,
			&(*p)->requester_id, ODR_CONTEXT, 3, 1, "requester_id") &&
		odr_implicit_tag (o, ill_System_Id,
			&(*p)->responder_id, ODR_CONTEXT, 4, 1, "responder_id") &&
		odr_implicit_tag (o, ill_Transaction_Type,
			&(*p)->transaction_type, ODR_CONTEXT, 5, 0, "transaction_type") &&
		odr_implicit_tag (o, ill_Delivery_Address,
			&(*p)->delivery_address, ODR_CONTEXT, 6, 1, "delivery_address") &&
		ill_Delivery_Service(o, &(*p)->delivery_service, 1, "delivery_service") &&
		odr_implicit_tag (o, ill_Delivery_Address,
			&(*p)->billing_address, ODR_CONTEXT, 8, 1, "billing_address") &&
		odr_implicit_settag (o, ODR_CONTEXT, 9) &&
		(odr_sequence_of(o, (Odr_fun) ill_Service_Type, &(*p)->iLL_service_type,
		  &(*p)->num_iLL_service_type, "iLL_service_type") || odr_ok(o)) &&
		odr_explicit_tag (o, odr_external,
			&(*p)->responder_specific_service, ODR_CONTEXT, 10, 1, "responder_specific_service") &&
		odr_implicit_tag (o, ill_Requester_Optional_Messages_Type,
			&(*p)->requester_optional_messages, ODR_CONTEXT, 11, 1, "requester_optional_messages") &&
		odr_implicit_tag (o, ill_Search_Type,
			&(*p)->search_type, ODR_CONTEXT, 12, 1, "search_type") &&
		odr_implicit_settag (o, ODR_CONTEXT, 13) &&
		(odr_sequence_of(o, (Odr_fun) ill_Supply_Medium_Info_Type, &(*p)->supply_medium_info_type,
		  &(*p)->num_supply_medium_info_type, "supply_medium_info_type") || odr_ok(o)) &&
		odr_implicit_tag (o, ill_Place_On_Hold_Type,
			&(*p)->place_on_hold, ODR_CONTEXT, 14, 0, "place_on_hold") &&
		odr_implicit_tag (o, ill_Client_Id,
			&(*p)->client_id, ODR_CONTEXT, 15, 1, "client_id") &&
		odr_implicit_tag (o, ill_Item_Id,
			&(*p)->item_id, ODR_CONTEXT, 16, 1, "item_id") &&
		odr_implicit_tag (o, ill_Supplemental_Item_Description,
			&(*p)->supplemental_item_description, ODR_CONTEXT, 17, 1, "supplemental_item_description") &&
		odr_implicit_tag (o, ill_Cost_Info_Type,
			&(*p)->cost_info_type, ODR_CONTEXT, 18, 1, "cost_info_type") &&
		odr_explicit_tag (o, ill_String,
			&(*p)->copyright_compliance, ODR_CONTEXT, 19, 1, "copyright_compliance") &&
		odr_implicit_tag (o, ill_Third_Party_Info_Type,
			&(*p)->third_party_info_type, ODR_CONTEXT, 20, 1, "third_party_info_type") &&
		odr_implicit_tag (o, odr_bool,
			&(*p)->retry_flag, ODR_CONTEXT, 21, 0, "retry_flag") &&
		odr_implicit_tag (o, odr_bool,
			&(*p)->forward_flag, ODR_CONTEXT, 22, 0, "forward_flag") &&
		odr_explicit_tag (o, ill_String,
			&(*p)->requester_note, ODR_CONTEXT, 46, 1, "requester_note") &&
		odr_explicit_tag (o, ill_String,
			&(*p)->forward_note, ODR_CONTEXT, 47, 1, "forward_note") &&
		odr_implicit_settag (o, ODR_CONTEXT, 49) &&
		(odr_sequence_of(o, (Odr_fun) ill_Extension, &(*p)->iLL_request_extensions,
		  &(*p)->num_iLL_request_extensions, "iLL_request_extensions") || odr_ok(o)) &&
		odr_sequence_end (o);
}
