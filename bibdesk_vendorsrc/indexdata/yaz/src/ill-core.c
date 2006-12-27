/** \file ill-core.c
    \brief ASN.1 Module ISO-10161-ILL-1

    Generated automatically by YAZ ASN.1 Compiler 0.4
*/

#include <yaz/ill-core.h>

int ill_APDU (ODR o, ILL_APDU **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{-1, -1, -1, ILL_APDU_ILL_Request,
		 (Odr_fun) ill_Request, "illRequest"},
		{-1, -1, -1, ILL_APDU_Forward_Notification,
		 (Odr_fun) ill_Forward_Notification, "Forward_Notification"},
		{-1, -1, -1, ILL_APDU_Shipped,
		 (Odr_fun) ill_Shipped, "Shipped"},
		{-1, -1, -1, ILL_APDU_ILL_Answer,
		 (Odr_fun) ill_Answer, "illAnswer"},
		{-1, -1, -1, ILL_APDU_Conditional_Reply,
		 (Odr_fun) ill_Conditional_Reply, "Conditional_Reply"},
		{-1, -1, -1, ILL_APDU_Cancel,
		 (Odr_fun) ill_Cancel, "Cancel"},
		{-1, -1, -1, ILL_APDU_Cancel_Reply,
		 (Odr_fun) ill_Cancel_Reply, "Cancel_Reply"},
		{-1, -1, -1, ILL_APDU_Received,
		 (Odr_fun) ill_Received, "Received"},
		{-1, -1, -1, ILL_APDU_Recall,
		 (Odr_fun) ill_Recall, "Recall"},
		{-1, -1, -1, ILL_APDU_Returned,
		 (Odr_fun) ill_Returned, "Returned"},
		{-1, -1, -1, ILL_APDU_Checked_In,
		 (Odr_fun) ill_Checked_In, "Checked_In"},
		{-1, -1, -1, ILL_APDU_Overdue,
		 (Odr_fun) ill_Overdue, "Overdue"},
		{-1, -1, -1, ILL_APDU_Renew,
		 (Odr_fun) ill_Renew, "Renew"},
		{-1, -1, -1, ILL_APDU_Renew_Answer,
		 (Odr_fun) ill_Renew_Answer, "Renew_Answer"},
		{-1, -1, -1, ILL_APDU_Lost,
		 (Odr_fun) ill_Lost, "Lost"},
		{-1, -1, -1, ILL_APDU_Damaged,
		 (Odr_fun) ill_Damaged, "Damaged"},
		{-1, -1, -1, ILL_APDU_Message,
		 (Odr_fun) ill_Message, "Message"},
		{-1, -1, -1, ILL_APDU_Status_Query,
		 (Odr_fun) ill_Status_Query, "Status_Query"},
		{-1, -1, -1, ILL_APDU_Status_Or_Error_Report,
		 (Odr_fun) ill_Status_Or_Error_Report, "Status_Or_Error_Report"},
		{-1, -1, -1, ILL_APDU_Expired,
		 (Odr_fun) ill_Expired, "Expired"},
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

int ill_Request (ODR o, ILL_Request **p, int opt, const char *name)
{
	if (!odr_constructed_begin (o, p, ODR_APPLICATION, 1, name))
		return odr_missing(o, opt, name);
	if (o->direction == ODR_DECODE)
		*p = (ILL_Request *) odr_malloc (o, sizeof(**p));
	if (!odr_sequence_begin (o, p, sizeof(**p), 0))
	{
		if(o->direction == ODR_DECODE)
			*p = 0;
		return 0;
	}
	return
		odr_implicit_tag (o, odr_integer,
			&(*p)->protocol_version_num, ODR_CONTEXT, 0, 0, "protocol_version_num") &&
		odr_implicit_tag (o, ill_Transaction_Id,
			&(*p)->transaction_id, ODR_CONTEXT, 1, 0, "transaction_id") &&
		odr_implicit_tag (o, ill_Service_Date_Time,
			&(*p)->service_date_time, ODR_CONTEXT, 2, 0, "service_date_time") &&
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
		odr_sequence_of(o, (Odr_fun) ill_Service_Type, &(*p)->iLL_service_type,
		  &(*p)->num_iLL_service_type, "iLL_service_type") &&
		odr_explicit_tag (o, odr_external,
			&(*p)->responder_specific_service, ODR_CONTEXT, 10, 1, "responder_specific_service") &&
		odr_implicit_tag (o, ill_Requester_Optional_Messages_Type,
			&(*p)->requester_optional_messages, ODR_CONTEXT, 11, 0, "requester_optional_messages") &&
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
			&(*p)->item_id, ODR_CONTEXT, 16, 0, "item_id") &&
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
		odr_sequence_end (o) &&
		odr_constructed_end (o);
}

int ill_Forward_Notification (ODR o, ILL_Forward_Notification **p, int opt, const char *name)
{
	if (!odr_constructed_begin (o, p, ODR_APPLICATION, 2, name))
		return odr_missing(o, opt, name);
	if (o->direction == ODR_DECODE)
		*p = (ILL_Forward_Notification *) odr_malloc (o, sizeof(**p));
	if (!odr_sequence_begin (o, p, sizeof(**p), 0))
	{
		if(o->direction == ODR_DECODE)
			*p = 0;
		return 0;
	}
	return
		odr_implicit_tag (o, odr_integer,
			&(*p)->protocol_version_num, ODR_CONTEXT, 0, 0, "protocol_version_num") &&
		odr_implicit_tag (o, ill_Transaction_Id,
			&(*p)->transaction_id, ODR_CONTEXT, 1, 0, "transaction_id") &&
		odr_implicit_tag (o, ill_Service_Date_Time,
			&(*p)->service_date_time, ODR_CONTEXT, 2, 0, "service_date_time") &&
		odr_implicit_tag (o, ill_System_Id,
			&(*p)->requester_id, ODR_CONTEXT, 3, 1, "requester_id") &&
		odr_implicit_tag (o, ill_System_Id,
			&(*p)->responder_id, ODR_CONTEXT, 4, 0, "responder_id") &&
		odr_implicit_tag (o, ill_System_Address,
			&(*p)->responder_address, ODR_CONTEXT, 24, 1, "responder_address") &&
		odr_implicit_tag (o, ill_System_Id,
			&(*p)->intermediary_id, ODR_CONTEXT, 25, 0, "intermediary_id") &&
		odr_explicit_tag (o, ill_String,
			&(*p)->notification_note, ODR_CONTEXT, 48, 1, "notification_note") &&
		odr_implicit_settag (o, ODR_CONTEXT, 49) &&
		(odr_sequence_of(o, (Odr_fun) ill_Extension, &(*p)->forward_notification_extensions,
		  &(*p)->num_forward_notification_extensions, "forward_notification_extensions") || odr_ok(o)) &&
		odr_sequence_end (o) &&
		odr_constructed_end (o);
}

int ill_Shipped (ODR o, ILL_Shipped **p, int opt, const char *name)
{
	if (!odr_constructed_begin (o, p, ODR_APPLICATION, 3, name))
		return odr_missing(o, opt, name);
	if (o->direction == ODR_DECODE)
		*p = (ILL_Shipped *) odr_malloc (o, sizeof(**p));
	if (!odr_sequence_begin (o, p, sizeof(**p), 0))
	{
		if(o->direction == ODR_DECODE)
			*p = 0;
		return 0;
	}
	return
		odr_implicit_tag (o, odr_integer,
			&(*p)->protocol_version_num, ODR_CONTEXT, 0, 0, "protocol_version_num") &&
		odr_implicit_tag (o, ill_Transaction_Id,
			&(*p)->transaction_id, ODR_CONTEXT, 1, 0, "transaction_id") &&
		odr_implicit_tag (o, ill_Service_Date_Time,
			&(*p)->service_date_time, ODR_CONTEXT, 2, 0, "service_date_time") &&
		odr_implicit_tag (o, ill_System_Id,
			&(*p)->requester_id, ODR_CONTEXT, 3, 1, "requester_id") &&
		odr_implicit_tag (o, ill_System_Id,
			&(*p)->responder_id, ODR_CONTEXT, 4, 1, "responder_id") &&
		odr_implicit_tag (o, ill_System_Address,
			&(*p)->responder_address, ODR_CONTEXT, 24, 1, "responder_address") &&
		odr_implicit_tag (o, ill_System_Id,
			&(*p)->intermediary_id, ODR_CONTEXT, 25, 1, "intermediary_id") &&
		odr_implicit_tag (o, ill_System_Id,
			&(*p)->supplier_id, ODR_CONTEXT, 26, 1, "supplier_id") &&
		odr_implicit_tag (o, ill_Client_Id,
			&(*p)->client_id, ODR_CONTEXT, 15, 1, "client_id") &&
		odr_implicit_tag (o, ill_Transaction_Type,
			&(*p)->transaction_type, ODR_CONTEXT, 5, 0, "transaction_type") &&
		odr_implicit_tag (o, ill_Supplemental_Item_Description,
			&(*p)->supplemental_item_description, ODR_CONTEXT, 17, 1, "supplemental_item_description") &&
		odr_implicit_tag (o, ill_Shipped_Service_Type,
			&(*p)->shipped_service_type, ODR_CONTEXT, 27, 0, "shipped_service_type") &&
		odr_implicit_tag (o, ill_Responder_Optional_Messages_Type,
			&(*p)->responder_optional_messages, ODR_CONTEXT, 28, 1, "responder_optional_messages") &&
		odr_implicit_tag (o, ill_Supply_Details,
			&(*p)->supply_details, ODR_CONTEXT, 29, 0, "supply_details") &&
		odr_implicit_tag (o, ill_Postal_Address,
			&(*p)->return_to_address, ODR_CONTEXT, 30, 1, "return_to_address") &&
		odr_explicit_tag (o, ill_String,
			&(*p)->responder_note, ODR_CONTEXT, 46, 1, "responder_note") &&
		odr_implicit_settag (o, ODR_CONTEXT, 49) &&
		(odr_sequence_of(o, (Odr_fun) ill_Extension, &(*p)->shipped_extensions,
		  &(*p)->num_shipped_extensions, "shipped_extensions") || odr_ok(o)) &&
		odr_sequence_end (o) &&
		odr_constructed_end (o);
}

int ill_Answer (ODR o, ILL_Answer **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_EXPLICIT, ODR_CONTEXT, 1, ILL_Answer_conditional_results,
		(Odr_fun) ill_Conditional_Results, "conditional_results"},
		{ODR_EXPLICIT, ODR_CONTEXT, 2, ILL_Answer_retry_results,
		(Odr_fun) ill_Retry_Results, "retry_results"},
		{ODR_EXPLICIT, ODR_CONTEXT, 3, ILL_Answer_unfilled_results,
		(Odr_fun) ill_Unfilled_Results, "unfilled_results"},
		{ODR_EXPLICIT, ODR_CONTEXT, 4, ILL_Answer_locations_results,
		(Odr_fun) ill_Locations_Results, "locations_results"},
		{ODR_EXPLICIT, ODR_CONTEXT, 5, ILL_Answer_will_supply_results,
		(Odr_fun) ill_Will_Supply_Results, "will_supply_results"},
		{ODR_EXPLICIT, ODR_CONTEXT, 6, ILL_Answer_hold_placed_results,
		(Odr_fun) ill_Hold_Placed_Results, "hold_placed_results"},
		{ODR_EXPLICIT, ODR_CONTEXT, 7, ILL_Answer_estimate_results,
		(Odr_fun) ill_Estimate_Results, "estimate_results"},
		{-1, -1, -1, -1, (Odr_fun) 0, 0}
	};
	if (!odr_constructed_begin (o, p, ODR_APPLICATION, 4, name))
		return odr_missing(o, opt, name);
	if (o->direction == ODR_DECODE)
		*p = (ILL_Answer *) odr_malloc (o, sizeof(**p));
	if (!odr_sequence_begin (o, p, sizeof(**p), 0))
	{
		if(o->direction == ODR_DECODE)
			*p = 0;
		return 0;
	}
	return
		odr_implicit_tag (o, odr_integer,
			&(*p)->protocol_version_num, ODR_CONTEXT, 0, 0, "protocol_version_num") &&
		odr_implicit_tag (o, ill_Transaction_Id,
			&(*p)->transaction_id, ODR_CONTEXT, 1, 0, "transaction_id") &&
		odr_implicit_tag (o, ill_Service_Date_Time,
			&(*p)->service_date_time, ODR_CONTEXT, 2, 0, "service_date_time") &&
		odr_implicit_tag (o, ill_System_Id,
			&(*p)->requester_id, ODR_CONTEXT, 3, 1, "requester_id") &&
		odr_implicit_tag (o, ill_System_Id,
			&(*p)->responder_id, ODR_CONTEXT, 4, 1, "responder_id") &&
		odr_implicit_tag (o, ill_Transaction_Results,
			&(*p)->transaction_results, ODR_CONTEXT, 31, 0, "transaction_results") &&
		((odr_constructed_begin (o, &(*p)->u, ODR_CONTEXT, 32, "results_explanation") &&
		odr_choice (o, arm, &(*p)->u, &(*p)->which, 0) &&
		odr_constructed_end (o)) || odr_ok(o)) &&
		odr_explicit_tag (o, odr_external,
			&(*p)->responder_specific_results, ODR_CONTEXT, 33, 1, "responder_specific_results") &&
		odr_implicit_tag (o, ill_Supplemental_Item_Description,
			&(*p)->supplemental_item_description, ODR_CONTEXT, 17, 1, "supplemental_item_description") &&
		odr_implicit_tag (o, ill_Send_To_List_Type,
			&(*p)->send_to_list, ODR_CONTEXT, 23, 1, "send_to_list") &&
		odr_implicit_tag (o, ill_Already_Tried_List_Type,
			&(*p)->already_tried_list, ODR_CONTEXT, 34, 1, "already_tried_list") &&
		odr_implicit_tag (o, ill_Responder_Optional_Messages_Type,
			&(*p)->responder_optional_messages, ODR_CONTEXT, 28, 1, "responder_optional_messages") &&
		odr_explicit_tag (o, ill_String,
			&(*p)->responder_note, ODR_CONTEXT, 46, 1, "responder_note") &&
		odr_implicit_settag (o, ODR_CONTEXT, 49) &&
		(odr_sequence_of(o, (Odr_fun) ill_Extension, &(*p)->ill_answer_extensions,
		  &(*p)->num_ill_answer_extensions, "ill_answer_extensions") || odr_ok(o)) &&
		odr_sequence_end (o) &&
		odr_constructed_end (o);
}

int ill_Conditional_Reply (ODR o, ILL_Conditional_Reply **p, int opt, const char *name)
{
	if (!odr_constructed_begin (o, p, ODR_APPLICATION, 5, name))
		return odr_missing(o, opt, name);
	if (o->direction == ODR_DECODE)
		*p = (ILL_Conditional_Reply *) odr_malloc (o, sizeof(**p));
	if (!odr_sequence_begin (o, p, sizeof(**p), 0))
	{
		if(o->direction == ODR_DECODE)
			*p = 0;
		return 0;
	}
	return
		odr_implicit_tag (o, odr_integer,
			&(*p)->protocol_version_num, ODR_CONTEXT, 0, 0, "protocol_version_num") &&
		odr_implicit_tag (o, ill_Transaction_Id,
			&(*p)->transaction_id, ODR_CONTEXT, 1, 0, "transaction_id") &&
		odr_implicit_tag (o, ill_Service_Date_Time,
			&(*p)->service_date_time, ODR_CONTEXT, 2, 0, "service_date_time") &&
		odr_implicit_tag (o, ill_System_Id,
			&(*p)->requester_id, ODR_CONTEXT, 3, 1, "requester_id") &&
		odr_implicit_tag (o, ill_System_Id,
			&(*p)->responder_id, ODR_CONTEXT, 4, 1, "responder_id") &&
		odr_implicit_tag (o, odr_bool,
			&(*p)->answer, ODR_CONTEXT, 35, 0, "answer") &&
		odr_explicit_tag (o, ill_String,
			&(*p)->requester_note, ODR_CONTEXT, 46, 1, "requester_note") &&
		odr_implicit_settag (o, ODR_CONTEXT, 49) &&
		(odr_sequence_of(o, (Odr_fun) ill_Extension, &(*p)->conditional_reply_extensions,
		  &(*p)->num_conditional_reply_extensions, "conditional_reply_extensions") || odr_ok(o)) &&
		odr_sequence_end (o) &&
		odr_constructed_end (o);
}

int ill_Cancel (ODR o, ILL_Cancel **p, int opt, const char *name)
{
	if (!odr_constructed_begin (o, p, ODR_APPLICATION, 6, name))
		return odr_missing(o, opt, name);
	if (o->direction == ODR_DECODE)
		*p = (ILL_Cancel *) odr_malloc (o, sizeof(**p));
	if (!odr_sequence_begin (o, p, sizeof(**p), 0))
	{
		if(o->direction == ODR_DECODE)
			*p = 0;
		return 0;
	}
	return
		odr_implicit_tag (o, odr_integer,
			&(*p)->protocol_version_num, ODR_CONTEXT, 0, 0, "protocol_version_num") &&
		odr_implicit_tag (o, ill_Transaction_Id,
			&(*p)->transaction_id, ODR_CONTEXT, 1, 0, "transaction_id") &&
		odr_implicit_tag (o, ill_Service_Date_Time,
			&(*p)->service_date_time, ODR_CONTEXT, 2, 0, "service_date_time") &&
		odr_implicit_tag (o, ill_System_Id,
			&(*p)->requester_id, ODR_CONTEXT, 3, 1, "requester_id") &&
		odr_implicit_tag (o, ill_System_Id,
			&(*p)->responder_id, ODR_CONTEXT, 4, 1, "responder_id") &&
		odr_explicit_tag (o, ill_String,
			&(*p)->requester_note, ODR_CONTEXT, 46, 1, "requester_note") &&
		odr_implicit_settag (o, ODR_CONTEXT, 49) &&
		(odr_sequence_of(o, (Odr_fun) ill_Extension, &(*p)->cancel_extensions,
		  &(*p)->num_cancel_extensions, "cancel_extensions") || odr_ok(o)) &&
		odr_sequence_end (o) &&
		odr_constructed_end (o);
}

int ill_Cancel_Reply (ODR o, ILL_Cancel_Reply **p, int opt, const char *name)
{
	if (!odr_constructed_begin (o, p, ODR_APPLICATION, 7, name))
		return odr_missing(o, opt, name);
	if (o->direction == ODR_DECODE)
		*p = (ILL_Cancel_Reply *) odr_malloc (o, sizeof(**p));
	if (!odr_sequence_begin (o, p, sizeof(**p), 0))
	{
		if(o->direction == ODR_DECODE)
			*p = 0;
		return 0;
	}
	return
		odr_implicit_tag (o, odr_integer,
			&(*p)->protocol_version_num, ODR_CONTEXT, 0, 0, "protocol_version_num") &&
		odr_implicit_tag (o, ill_Transaction_Id,
			&(*p)->transaction_id, ODR_CONTEXT, 1, 0, "transaction_id") &&
		odr_implicit_tag (o, ill_Service_Date_Time,
			&(*p)->service_date_time, ODR_CONTEXT, 2, 0, "service_date_time") &&
		odr_implicit_tag (o, ill_System_Id,
			&(*p)->requester_id, ODR_CONTEXT, 3, 1, "requester_id") &&
		odr_implicit_tag (o, ill_System_Id,
			&(*p)->responder_id, ODR_CONTEXT, 4, 1, "responder_id") &&
		odr_implicit_tag (o, odr_bool,
			&(*p)->answer, ODR_CONTEXT, 35, 0, "answer") &&
		odr_explicit_tag (o, ill_String,
			&(*p)->responder_note, ODR_CONTEXT, 46, 1, "responder_note") &&
		odr_implicit_settag (o, ODR_CONTEXT, 49) &&
		(odr_sequence_of(o, (Odr_fun) ill_Extension, &(*p)->cancel_reply_extensions,
		  &(*p)->num_cancel_reply_extensions, "cancel_reply_extensions") || odr_ok(o)) &&
		odr_sequence_end (o) &&
		odr_constructed_end (o);
}

int ill_Received (ODR o, ILL_Received **p, int opt, const char *name)
{
	if (!odr_constructed_begin (o, p, ODR_APPLICATION, 8, name))
		return odr_missing(o, opt, name);
	if (o->direction == ODR_DECODE)
		*p = (ILL_Received *) odr_malloc (o, sizeof(**p));
	if (!odr_sequence_begin (o, p, sizeof(**p), 0))
	{
		if(o->direction == ODR_DECODE)
			*p = 0;
		return 0;
	}
	return
		odr_implicit_tag (o, odr_integer,
			&(*p)->protocol_version_num, ODR_CONTEXT, 0, 0, "protocol_version_num") &&
		odr_implicit_tag (o, ill_Transaction_Id,
			&(*p)->transaction_id, ODR_CONTEXT, 1, 0, "transaction_id") &&
		odr_implicit_tag (o, ill_Service_Date_Time,
			&(*p)->service_date_time, ODR_CONTEXT, 2, 0, "service_date_time") &&
		odr_implicit_tag (o, ill_System_Id,
			&(*p)->requester_id, ODR_CONTEXT, 3, 1, "requester_id") &&
		odr_implicit_tag (o, ill_System_Id,
			&(*p)->responder_id, ODR_CONTEXT, 4, 1, "responder_id") &&
		odr_implicit_tag (o, ill_System_Id,
			&(*p)->supplier_id, ODR_CONTEXT, 26, 1, "supplier_id") &&
		odr_implicit_tag (o, ill_Supplemental_Item_Description,
			&(*p)->supplemental_item_description, ODR_CONTEXT, 17, 1, "supplemental_item_description") &&
		odr_implicit_tag (o, ill_ISO_Date,
			&(*p)->date_received, ODR_CONTEXT, 36, 0, "date_received") &&
		odr_implicit_tag (o, ill_Shipped_Service_Type,
			&(*p)->shipped_service_type, ODR_CONTEXT, 27, 0, "shipped_service_type") &&
		odr_explicit_tag (o, ill_String,
			&(*p)->requester_note, ODR_CONTEXT, 46, 1, "requester_note") &&
		odr_implicit_settag (o, ODR_CONTEXT, 49) &&
		(odr_sequence_of(o, (Odr_fun) ill_Extension, &(*p)->received_extensions,
		  &(*p)->num_received_extensions, "received_extensions") || odr_ok(o)) &&
		odr_sequence_end (o) &&
		odr_constructed_end (o);
}

int ill_Recall (ODR o, ILL_Recall **p, int opt, const char *name)
{
	if (!odr_constructed_begin (o, p, ODR_APPLICATION, 9, name))
		return odr_missing(o, opt, name);
	if (o->direction == ODR_DECODE)
		*p = (ILL_Recall *) odr_malloc (o, sizeof(**p));
	if (!odr_sequence_begin (o, p, sizeof(**p), 0))
	{
		if(o->direction == ODR_DECODE)
			*p = 0;
		return 0;
	}
	return
		odr_implicit_tag (o, odr_integer,
			&(*p)->protocol_version_num, ODR_CONTEXT, 0, 0, "protocol_version_num") &&
		odr_implicit_tag (o, ill_Transaction_Id,
			&(*p)->transaction_id, ODR_CONTEXT, 1, 0, "transaction_id") &&
		odr_implicit_tag (o, ill_Service_Date_Time,
			&(*p)->service_date_time, ODR_CONTEXT, 2, 0, "service_date_time") &&
		odr_implicit_tag (o, ill_System_Id,
			&(*p)->requester_id, ODR_CONTEXT, 3, 1, "requester_id") &&
		odr_implicit_tag (o, ill_System_Id,
			&(*p)->responder_id, ODR_CONTEXT, 4, 1, "responder_id") &&
		odr_explicit_tag (o, ill_String,
			&(*p)->responder_note, ODR_CONTEXT, 46, 1, "responder_note") &&
		odr_implicit_settag (o, ODR_CONTEXT, 49) &&
		(odr_sequence_of(o, (Odr_fun) ill_Extension, &(*p)->recall_extensions,
		  &(*p)->num_recall_extensions, "recall_extensions") || odr_ok(o)) &&
		odr_sequence_end (o) &&
		odr_constructed_end (o);
}

int ill_Returned (ODR o, ILL_Returned **p, int opt, const char *name)
{
	if (!odr_constructed_begin (o, p, ODR_APPLICATION, 10, name))
		return odr_missing(o, opt, name);
	if (o->direction == ODR_DECODE)
		*p = (ILL_Returned *) odr_malloc (o, sizeof(**p));
	if (!odr_sequence_begin (o, p, sizeof(**p), 0))
	{
		if(o->direction == ODR_DECODE)
			*p = 0;
		return 0;
	}
	return
		odr_implicit_tag (o, odr_integer,
			&(*p)->protocol_version_num, ODR_CONTEXT, 0, 0, "protocol_version_num") &&
		odr_implicit_tag (o, ill_Transaction_Id,
			&(*p)->transaction_id, ODR_CONTEXT, 1, 0, "transaction_id") &&
		odr_implicit_tag (o, ill_Service_Date_Time,
			&(*p)->service_date_time, ODR_CONTEXT, 2, 0, "service_date_time") &&
		odr_implicit_tag (o, ill_System_Id,
			&(*p)->requester_id, ODR_CONTEXT, 3, 1, "requester_id") &&
		odr_implicit_tag (o, ill_System_Id,
			&(*p)->responder_id, ODR_CONTEXT, 4, 1, "responder_id") &&
		odr_implicit_tag (o, ill_Supplemental_Item_Description,
			&(*p)->supplemental_item_description, ODR_CONTEXT, 17, 1, "supplemental_item_description") &&
		odr_implicit_tag (o, ill_ISO_Date,
			&(*p)->date_returned, ODR_CONTEXT, 37, 0, "date_returned") &&
		odr_explicit_tag (o, ill_Transportation_Mode,
			&(*p)->returned_via, ODR_CONTEXT, 38, 1, "returned_via") &&
		odr_implicit_tag (o, ill_Amount,
			&(*p)->insured_for, ODR_CONTEXT, 39, 1, "insured_for") &&
		odr_explicit_tag (o, ill_String,
			&(*p)->requester_note, ODR_CONTEXT, 46, 1, "requester_note") &&
		odr_implicit_settag (o, ODR_CONTEXT, 49) &&
		(odr_sequence_of(o, (Odr_fun) ill_Extension, &(*p)->returned_extensions,
		  &(*p)->num_returned_extensions, "returned_extensions") || odr_ok(o)) &&
		odr_sequence_end (o) &&
		odr_constructed_end (o);
}

int ill_Checked_In (ODR o, ILL_Checked_In **p, int opt, const char *name)
{
	if (!odr_constructed_begin (o, p, ODR_APPLICATION, 11, name))
		return odr_missing(o, opt, name);
	if (o->direction == ODR_DECODE)
		*p = (ILL_Checked_In *) odr_malloc (o, sizeof(**p));
	if (!odr_sequence_begin (o, p, sizeof(**p), 0))
	{
		if(o->direction == ODR_DECODE)
			*p = 0;
		return 0;
	}
	return
		odr_implicit_tag (o, odr_integer,
			&(*p)->protocol_version_num, ODR_CONTEXT, 0, 0, "protocol_version_num") &&
		odr_implicit_tag (o, ill_Transaction_Id,
			&(*p)->transaction_id, ODR_CONTEXT, 1, 0, "transaction_id") &&
		odr_implicit_tag (o, ill_Service_Date_Time,
			&(*p)->service_date_time, ODR_CONTEXT, 2, 0, "service_date_time") &&
		odr_implicit_tag (o, ill_System_Id,
			&(*p)->requester_id, ODR_CONTEXT, 3, 1, "requester_id") &&
		odr_implicit_tag (o, ill_System_Id,
			&(*p)->responder_id, ODR_CONTEXT, 4, 1, "responder_id") &&
		odr_implicit_tag (o, ill_ISO_Date,
			&(*p)->date_checked_in, ODR_CONTEXT, 40, 0, "date_checked_in") &&
		odr_explicit_tag (o, ill_String,
			&(*p)->responder_note, ODR_CONTEXT, 46, 1, "responder_note") &&
		odr_implicit_settag (o, ODR_CONTEXT, 49) &&
		(odr_sequence_of(o, (Odr_fun) ill_Extension, &(*p)->checked_in_extensions,
		  &(*p)->num_checked_in_extensions, "checked_in_extensions") || odr_ok(o)) &&
		odr_sequence_end (o) &&
		odr_constructed_end (o);
}

int ill_Overdue_ExtensionS (ODR o, ILL_Overdue_ExtensionS **p, int opt, const char *name)
{
	if (!odr_initmember (o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_sequence_of (o, (Odr_fun) ill_Extension, &(*p)->elements,
		&(*p)->num, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int ill_Overdue (ODR o, ILL_Overdue **p, int opt, const char *name)
{
	if (!odr_constructed_begin (o, p, ODR_APPLICATION, 12, name))
		return odr_missing(o, opt, name);
	if (o->direction == ODR_DECODE)
		*p = (ILL_Overdue *) odr_malloc (o, sizeof(**p));
	if (!odr_sequence_begin (o, p, sizeof(**p), 0))
	{
		if(o->direction == ODR_DECODE)
			*p = 0;
		return 0;
	}
	return
		odr_implicit_tag (o, odr_integer,
			&(*p)->protocol_version_num, ODR_CONTEXT, 0, 0, "protocol_version_num") &&
		odr_implicit_tag (o, ill_Transaction_Id,
			&(*p)->transaction_id, ODR_CONTEXT, 1, 0, "transaction_id") &&
		odr_implicit_tag (o, ill_Service_Date_Time,
			&(*p)->service_date_time, ODR_CONTEXT, 2, 0, "service_date_time") &&
		odr_implicit_tag (o, ill_System_Id,
			&(*p)->requester_id, ODR_CONTEXT, 3, 1, "requester_id") &&
		odr_implicit_tag (o, ill_System_Id,
			&(*p)->responder_id, ODR_CONTEXT, 4, 1, "responder_id") &&
		odr_implicit_tag (o, ill_Date_Due,
			&(*p)->date_due, ODR_CONTEXT, 41, 0, "date_due") &&
		odr_explicit_tag (o, ill_String,
			&(*p)->responder_note, ODR_CONTEXT, 46, 1, "responder_note") &&
		odr_explicit_tag (o, ill_Overdue_ExtensionS,
			&(*p)->overdue_extensions, ODR_CONTEXT, 49, 1, "overdue_extensions") &&
		odr_sequence_end (o) &&
		odr_constructed_end (o);
}

int ill_Renew (ODR o, ILL_Renew **p, int opt, const char *name)
{
	if (!odr_constructed_begin (o, p, ODR_APPLICATION, 13, name))
		return odr_missing(o, opt, name);
	if (o->direction == ODR_DECODE)
		*p = (ILL_Renew *) odr_malloc (o, sizeof(**p));
	if (!odr_sequence_begin (o, p, sizeof(**p), 0))
	{
		if(o->direction == ODR_DECODE)
			*p = 0;
		return 0;
	}
	return
		odr_implicit_tag (o, odr_integer,
			&(*p)->protocol_version_num, ODR_CONTEXT, 0, 0, "protocol_version_num") &&
		odr_implicit_tag (o, ill_Transaction_Id,
			&(*p)->transaction_id, ODR_CONTEXT, 1, 0, "transaction_id") &&
		odr_implicit_tag (o, ill_Service_Date_Time,
			&(*p)->service_date_time, ODR_CONTEXT, 2, 0, "service_date_time") &&
		odr_implicit_tag (o, ill_System_Id,
			&(*p)->requester_id, ODR_CONTEXT, 3, 1, "requester_id") &&
		odr_implicit_tag (o, ill_System_Id,
			&(*p)->responder_id, ODR_CONTEXT, 4, 1, "responder_id") &&
		odr_implicit_tag (o, ill_ISO_Date,
			&(*p)->desired_due_date, ODR_CONTEXT, 42, 1, "desired_due_date") &&
		odr_explicit_tag (o, ill_String,
			&(*p)->requester_note, ODR_CONTEXT, 46, 1, "requester_note") &&
		odr_implicit_settag (o, ODR_CONTEXT, 49) &&
		(odr_sequence_of(o, (Odr_fun) ill_Extension, &(*p)->renew_extensions,
		  &(*p)->num_renew_extensions, "renew_extensions") || odr_ok(o)) &&
		odr_sequence_end (o) &&
		odr_constructed_end (o);
}

int ill_Renew_Answer (ODR o, ILL_Renew_Answer **p, int opt, const char *name)
{
	if (!odr_constructed_begin (o, p, ODR_APPLICATION, 14, name))
		return odr_missing(o, opt, name);
	if (o->direction == ODR_DECODE)
		*p = (ILL_Renew_Answer *) odr_malloc (o, sizeof(**p));
	if (!odr_sequence_begin (o, p, sizeof(**p), 0))
	{
		if(o->direction == ODR_DECODE)
			*p = 0;
		return 0;
	}
	return
		odr_implicit_tag (o, odr_integer,
			&(*p)->protocol_version_num, ODR_CONTEXT, 0, 0, "protocol_version_num") &&
		odr_implicit_tag (o, ill_Transaction_Id,
			&(*p)->transaction_id, ODR_CONTEXT, 1, 0, "transaction_id") &&
		odr_implicit_tag (o, ill_Service_Date_Time,
			&(*p)->service_date_time, ODR_CONTEXT, 2, 0, "service_date_time") &&
		odr_implicit_tag (o, ill_System_Id,
			&(*p)->requester_id, ODR_CONTEXT, 3, 1, "requester_id") &&
		odr_implicit_tag (o, ill_System_Id,
			&(*p)->responder_id, ODR_CONTEXT, 4, 1, "responder_id") &&
		odr_implicit_tag (o, odr_bool,
			&(*p)->answer, ODR_CONTEXT, 35, 0, "answer") &&
		odr_implicit_tag (o, ill_Date_Due,
			&(*p)->date_due, ODR_CONTEXT, 41, 1, "date_due") &&
		odr_explicit_tag (o, ill_String,
			&(*p)->responder_note, ODR_CONTEXT, 46, 1, "responder_note") &&
		odr_implicit_settag (o, ODR_CONTEXT, 49) &&
		(odr_sequence_of(o, (Odr_fun) ill_Extension, &(*p)->renew_answer_extensions,
		  &(*p)->num_renew_answer_extensions, "renew_answer_extensions") || odr_ok(o)) &&
		odr_sequence_end (o) &&
		odr_constructed_end (o);
}

int ill_Lost (ODR o, ILL_Lost **p, int opt, const char *name)
{
	if (!odr_constructed_begin (o, p, ODR_APPLICATION, 15, name))
		return odr_missing(o, opt, name);
	if (o->direction == ODR_DECODE)
		*p = (ILL_Lost *) odr_malloc (o, sizeof(**p));
	if (!odr_sequence_begin (o, p, sizeof(**p), 0))
	{
		if(o->direction == ODR_DECODE)
			*p = 0;
		return 0;
	}
	return
		odr_implicit_tag (o, odr_integer,
			&(*p)->protocol_version_num, ODR_CONTEXT, 0, 0, "protocol_version_num") &&
		odr_implicit_tag (o, ill_Transaction_Id,
			&(*p)->transaction_id, ODR_CONTEXT, 1, 0, "transaction_id") &&
		odr_implicit_tag (o, ill_Service_Date_Time,
			&(*p)->service_date_time, ODR_CONTEXT, 2, 0, "service_date_time") &&
		odr_implicit_tag (o, ill_System_Id,
			&(*p)->requester_id, ODR_CONTEXT, 3, 1, "requester_id") &&
		odr_implicit_tag (o, ill_System_Id,
			&(*p)->responder_id, ODR_CONTEXT, 4, 1, "responder_id") &&
		odr_explicit_tag (o, ill_String,
			&(*p)->note, ODR_CONTEXT, 46, 1, "note") &&
		odr_implicit_settag (o, ODR_CONTEXT, 49) &&
		(odr_sequence_of(o, (Odr_fun) ill_Extension, &(*p)->lost_extensions,
		  &(*p)->num_lost_extensions, "lost_extensions") || odr_ok(o)) &&
		odr_sequence_end (o) &&
		odr_constructed_end (o);
}

int ill_Damaged (ODR o, ILL_Damaged **p, int opt, const char *name)
{
	if (!odr_constructed_begin (o, p, ODR_APPLICATION, 16, name))
		return odr_missing(o, opt, name);
	if (o->direction == ODR_DECODE)
		*p = (ILL_Damaged *) odr_malloc (o, sizeof(**p));
	if (!odr_sequence_begin (o, p, sizeof(**p), 0))
	{
		if(o->direction == ODR_DECODE)
			*p = 0;
		return 0;
	}
	return
		odr_implicit_tag (o, odr_integer,
			&(*p)->protocol_version_num, ODR_CONTEXT, 0, 0, "protocol_version_num") &&
		odr_implicit_tag (o, ill_Transaction_Id,
			&(*p)->transaction_id, ODR_CONTEXT, 1, 0, "transaction_id") &&
		odr_implicit_tag (o, ill_Service_Date_Time,
			&(*p)->service_date_time, ODR_CONTEXT, 2, 0, "service_date_time") &&
		odr_implicit_tag (o, ill_System_Id,
			&(*p)->requester_id, ODR_CONTEXT, 3, 1, "requester_id") &&
		odr_implicit_tag (o, ill_System_Id,
			&(*p)->responder_id, ODR_CONTEXT, 4, 1, "responder_id") &&
		odr_implicit_tag (o, ill_Damaged_Details,
			&(*p)->damaged_details, ODR_CONTEXT, 5, 1, "damaged_details") &&
		odr_explicit_tag (o, ill_String,
			&(*p)->note, ODR_CONTEXT, 46, 1, "note") &&
		odr_implicit_settag (o, ODR_CONTEXT, 49) &&
		(odr_sequence_of(o, (Odr_fun) ill_Extension, &(*p)->damaged_extensions,
		  &(*p)->num_damaged_extensions, "damaged_extensions") || odr_ok(o)) &&
		odr_sequence_end (o) &&
		odr_constructed_end (o);
}

int ill_Message (ODR o, ILL_Message **p, int opt, const char *name)
{
	if (!odr_constructed_begin (o, p, ODR_APPLICATION, 17, name))
		return odr_missing(o, opt, name);
	if (o->direction == ODR_DECODE)
		*p = (ILL_Message *) odr_malloc (o, sizeof(**p));
	if (!odr_sequence_begin (o, p, sizeof(**p), 0))
	{
		if(o->direction == ODR_DECODE)
			*p = 0;
		return 0;
	}
	return
		odr_implicit_tag (o, odr_integer,
			&(*p)->protocol_version_num, ODR_CONTEXT, 0, 0, "protocol_version_num") &&
		odr_implicit_tag (o, ill_Transaction_Id,
			&(*p)->transaction_id, ODR_CONTEXT, 1, 0, "transaction_id") &&
		odr_implicit_tag (o, ill_Service_Date_Time,
			&(*p)->service_date_time, ODR_CONTEXT, 2, 0, "service_date_time") &&
		odr_implicit_tag (o, ill_System_Id,
			&(*p)->requester_id, ODR_CONTEXT, 3, 1, "requester_id") &&
		odr_implicit_tag (o, ill_System_Id,
			&(*p)->responder_id, ODR_CONTEXT, 4, 1, "responder_id") &&
		odr_explicit_tag (o, ill_String,
			&(*p)->note, ODR_CONTEXT, 46, 0, "note") &&
		odr_implicit_settag (o, ODR_CONTEXT, 49) &&
		(odr_sequence_of(o, (Odr_fun) ill_Extension, &(*p)->message_extensions,
		  &(*p)->num_message_extensions, "message_extensions") || odr_ok(o)) &&
		odr_sequence_end (o) &&
		odr_constructed_end (o);
}

int ill_Status_Query (ODR o, ILL_Status_Query **p, int opt, const char *name)
{
	if (!odr_constructed_begin (o, p, ODR_APPLICATION, 18, name))
		return odr_missing(o, opt, name);
	if (o->direction == ODR_DECODE)
		*p = (ILL_Status_Query *) odr_malloc (o, sizeof(**p));
	if (!odr_sequence_begin (o, p, sizeof(**p), 0))
	{
		if(o->direction == ODR_DECODE)
			*p = 0;
		return 0;
	}
	return
		odr_implicit_tag (o, odr_integer,
			&(*p)->protocol_version_num, ODR_CONTEXT, 0, 0, "protocol_version_num") &&
		odr_implicit_tag (o, ill_Transaction_Id,
			&(*p)->transaction_id, ODR_CONTEXT, 1, 0, "transaction_id") &&
		odr_implicit_tag (o, ill_Service_Date_Time,
			&(*p)->service_date_time, ODR_CONTEXT, 2, 0, "service_date_time") &&
		odr_implicit_tag (o, ill_System_Id,
			&(*p)->requester_id, ODR_CONTEXT, 3, 1, "requester_id") &&
		odr_implicit_tag (o, ill_System_Id,
			&(*p)->responder_id, ODR_CONTEXT, 4, 1, "responder_id") &&
		odr_explicit_tag (o, ill_String,
			&(*p)->note, ODR_CONTEXT, 46, 1, "note") &&
		odr_implicit_settag (o, ODR_CONTEXT, 49) &&
		(odr_sequence_of(o, (Odr_fun) ill_Extension, &(*p)->status_query_extensions,
		  &(*p)->num_status_query_extensions, "status_query_extensions") || odr_ok(o)) &&
		odr_sequence_end (o) &&
		odr_constructed_end (o);
}

int ill_Status_Or_Error_Report (ODR o, ILL_Status_Or_Error_Report **p, int opt, const char *name)
{
	if (!odr_constructed_begin (o, p, ODR_APPLICATION, 19, name))
		return odr_missing(o, opt, name);
	if (o->direction == ODR_DECODE)
		*p = (ILL_Status_Or_Error_Report *) odr_malloc (o, sizeof(**p));
	if (!odr_sequence_begin (o, p, sizeof(**p), 0))
	{
		if(o->direction == ODR_DECODE)
			*p = 0;
		return 0;
	}
	return
		odr_implicit_tag (o, odr_integer,
			&(*p)->protocol_version_num, ODR_CONTEXT, 0, 0, "protocol_version_num") &&
		odr_implicit_tag (o, ill_Transaction_Id,
			&(*p)->transaction_id, ODR_CONTEXT, 1, 0, "transaction_id") &&
		odr_implicit_tag (o, ill_Service_Date_Time,
			&(*p)->service_date_time, ODR_CONTEXT, 2, 0, "service_date_time") &&
		odr_implicit_tag (o, ill_System_Id,
			&(*p)->requester_id, ODR_CONTEXT, 3, 1, "requester_id") &&
		odr_implicit_tag (o, ill_System_Id,
			&(*p)->responder_id, ODR_CONTEXT, 4, 1, "responder_id") &&
		odr_implicit_tag (o, ill_Reason_No_Report,
			&(*p)->reason_no_report, ODR_CONTEXT, 43, 1, "reason_no_report") &&
		odr_implicit_tag (o, ill_Status_Report,
			&(*p)->status_report, ODR_CONTEXT, 44, 1, "status_report") &&
		odr_implicit_tag (o, ill_Error_Report,
			&(*p)->error_report, ODR_CONTEXT, 45, 1, "error_report") &&
		odr_explicit_tag (o, ill_String,
			&(*p)->note, ODR_CONTEXT, 46, 1, "note") &&
		odr_implicit_settag (o, ODR_CONTEXT, 49) &&
		(odr_sequence_of(o, (Odr_fun) ill_Extension, &(*p)->status_or_error_report_extensions,
		  &(*p)->num_status_or_error_report_extensions, "status_or_error_report_extensions") || odr_ok(o)) &&
		odr_sequence_end (o) &&
		odr_constructed_end (o);
}

int ill_Expired (ODR o, ILL_Expired **p, int opt, const char *name)
{
	if (!odr_constructed_begin (o, p, ODR_APPLICATION, 20, name))
		return odr_missing(o, opt, name);
	if (o->direction == ODR_DECODE)
		*p = (ILL_Expired *) odr_malloc (o, sizeof(**p));
	if (!odr_sequence_begin (o, p, sizeof(**p), 0))
	{
		if(o->direction == ODR_DECODE)
			*p = 0;
		return 0;
	}
	return
		odr_implicit_tag (o, odr_integer,
			&(*p)->protocol_version_num, ODR_CONTEXT, 0, 0, "protocol_version_num") &&
		odr_implicit_tag (o, ill_Transaction_Id,
			&(*p)->transaction_id, ODR_CONTEXT, 1, 0, "transaction_id") &&
		odr_implicit_tag (o, ill_Service_Date_Time,
			&(*p)->service_date_time, ODR_CONTEXT, 2, 0, "service_date_time") &&
		odr_implicit_tag (o, ill_System_Id,
			&(*p)->requester_id, ODR_CONTEXT, 3, 1, "requester_id") &&
		odr_implicit_tag (o, ill_System_Id,
			&(*p)->responder_id, ODR_CONTEXT, 4, 1, "responder_id") &&
		odr_implicit_settag (o, ODR_CONTEXT, 49) &&
		(odr_sequence_of(o, (Odr_fun) ill_Extension, &(*p)->expired_extensions,
		  &(*p)->num_expired_extensions, "expired_extensions") || odr_ok(o)) &&
		odr_sequence_end (o) &&
		odr_constructed_end (o);
}

int ill_Account_Number (ODR o, ILL_Account_Number **p, int opt, const char *name)
{
	return ill_String (o, p, opt, name);
}

int ill_Already_Forwarded (ODR o, ILL_Already_Forwarded **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, ill_System_Id,
			&(*p)->responder_id, ODR_CONTEXT, 0, 0, "responder_id") &&
		odr_implicit_tag (o, ill_System_Address,
			&(*p)->responder_address, ODR_CONTEXT, 1, 1, "responder_address") &&
		odr_sequence_end (o);
}

int ill_Already_Tried_List_Type (ODR o, ILL_Already_Tried_List_Type **p, int opt, const char *name)
{
	if (!odr_initmember (o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_sequence_of (o, (Odr_fun) ill_System_Id, &(*p)->elements,
		&(*p)->num, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int ill_Amount (ODR o, ILL_Amount **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, odr_visiblestring,
			&(*p)->currency_code, ODR_CONTEXT, 0, 1, "currency_code") &&
		odr_implicit_tag (o, ill_AmountString,
			&(*p)->monetary_value, ODR_CONTEXT, 1, 0, "monetary_value") &&
		odr_sequence_end (o);
}

int ill_AmountString (ODR o, ILL_AmountString **p, int opt, const char *name)
{
	return odr_visiblestring (o, p, opt, name);
}

int ill_Client_Id (ODR o, ILL_Client_Id **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_explicit_tag (o, ill_String,
			&(*p)->client_name, ODR_CONTEXT, 0, 1, "client_name") &&
		odr_explicit_tag (o, ill_String,
			&(*p)->client_status, ODR_CONTEXT, 1, 1, "client_status") &&
		odr_explicit_tag (o, ill_String,
			&(*p)->client_identifier, ODR_CONTEXT, 2, 1, "client_identifier") &&
		odr_sequence_end (o);
}

int ill_Conditional_Results (ODR o, ILL_Conditional_Results **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, odr_enum,
			&(*p)->conditions, ODR_CONTEXT, 0, 0, "conditions") &&
		odr_implicit_tag (o, ill_ISO_Date,
			&(*p)->date_for_reply, ODR_CONTEXT, 1, 1, "date_for_reply") &&
		odr_implicit_settag (o, ODR_CONTEXT, 2) &&
		(odr_sequence_of(o, (Odr_fun) ill_Location_Info, &(*p)->locations,
		  &(*p)->num_locations, "locations") || odr_ok(o)) &&
		ill_Delivery_Service(o, &(*p)->proposed_delivery_service, 1, "proposed_delivery_service") &&
		odr_sequence_end (o);
}

int ill_Cost_Info_Type (ODR o, ILL_Cost_Info_Type **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_explicit_tag (o, ill_Account_Number,
			&(*p)->account_number, ODR_CONTEXT, 0, 1, "account_number") &&
		odr_implicit_tag (o, ill_Amount,
			&(*p)->maximum_cost, ODR_CONTEXT, 1, 1, "maximum_cost") &&
		odr_implicit_tag (o, odr_bool,
			&(*p)->reciprocal_agreement, ODR_CONTEXT, 2, 0, "reciprocal_agreement") &&
		odr_implicit_tag (o, odr_bool,
			&(*p)->will_pay_fee, ODR_CONTEXT, 3, 0, "will_pay_fee") &&
		odr_implicit_tag (o, odr_bool,
			&(*p)->payment_provided, ODR_CONTEXT, 4, 0, "payment_provided") &&
		odr_sequence_end (o);
}

int ill_Current_State (ODR o, ILL_Current_State **p, int opt, const char *name)
{
	return odr_enum (o, p, opt, name);
}

int ill_Damaged_DetailsSpecific_units (ODR o, ILL_Damaged_DetailsSpecific_units **p, int opt, const char *name)
{
	if (!odr_initmember (o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_sequence_of (o, (Odr_fun) odr_integer, &(*p)->elements,
		&(*p)->num, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int ill_Damaged_Details (ODR o, ILL_Damaged_Details **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 1, ILL_Damaged_Details_complete_document,
		(Odr_fun) odr_null, "complete_document"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, ILL_Damaged_Details_specific_units,
		(Odr_fun) ill_Damaged_DetailsSpecific_units, "specific_units"},
		{-1, -1, -1, -1, (Odr_fun) 0, 0}
	};
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, odr_oid,
			&(*p)->document_type_id, ODR_CONTEXT, 0, 1, "document_type_id") &&
		odr_choice (o, arm, &(*p)->u, &(*p)->which, 0) &&
		odr_sequence_end (o);
}

int ill_Date_Due (ODR o, ILL_Date_Due **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, ill_ISO_Date,
			&(*p)->date_due_field, ODR_CONTEXT, 0, 0, "date_due_field") &&
		odr_implicit_tag (o, odr_bool,
			&(*p)->renewable, ODR_CONTEXT, 1, 0, "renewable") &&
		odr_sequence_end (o);
}

int ill_Delivery_Address (ODR o, ILL_Delivery_Address **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, ill_Postal_Address,
			&(*p)->postal_address, ODR_CONTEXT, 0, 1, "postal_address") &&
		odr_implicit_tag (o, ill_System_Address,
			&(*p)->electronic_address, ODR_CONTEXT, 1, 1, "electronic_address") &&
		odr_sequence_end (o);
}

int ill_Delivery_ServiceElectronic_delivery (ODR o, ILL_Delivery_ServiceElectronic_delivery **p, int opt, const char *name)
{
	if (!odr_initmember (o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_sequence_of (o, (Odr_fun) ill_Electronic_Delivery_Service, &(*p)->elements,
		&(*p)->num, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int ill_Delivery_Service (ODR o, ILL_Delivery_Service **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_EXPLICIT, ODR_CONTEXT, 7, ILL_Delivery_Service_physical_delivery,
		(Odr_fun) ill_Transportation_Mode, "physical_delivery"},
		{ODR_IMPLICIT, ODR_CONTEXT, 50, ILL_Delivery_Service_electronic_delivery,
		(Odr_fun) ill_Delivery_ServiceElectronic_delivery, "electronic_delivery"},
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

int ill_Electronic_Delivery_Service_0 (ODR o, ILL_Electronic_Delivery_Service_0 **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, odr_oid,
			&(*p)->e_delivery_mode, ODR_CONTEXT, 0, 0, "e_delivery_mode") &&
		odr_explicit_tag (o, odr_any,
			&(*p)->e_delivery_parameters, ODR_CONTEXT, 1, 0, "e_delivery_parameters") &&
		odr_sequence_end (o);
}

int ill_Electronic_Delivery_Service_1 (ODR o, ILL_Electronic_Delivery_Service_1 **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, odr_oid,
			&(*p)->document_type_id, ODR_CONTEXT, 2, 0, "document_type_id") &&
		odr_explicit_tag (o, odr_any,
			&(*p)->document_type_parameters, ODR_CONTEXT, 3, 0, "document_type_parameters") &&
		odr_sequence_end (o);
}

int ill_Electronic_Delivery_Service (ODR o, ILL_Electronic_Delivery_Service **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 0, ILL_Electronic_Delivery_Service_e_delivery_address,
		(Odr_fun) ill_System_Address, "e_delivery_address"},
		{ODR_IMPLICIT, ODR_CONTEXT, 1, ILL_Electronic_Delivery_Service_e_delivery_id,
		(Odr_fun) ill_System_Id, "e_delivery_id"},
		{-1, -1, -1, -1, (Odr_fun) 0, 0}
	};
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, ill_Electronic_Delivery_Service_0,
			&(*p)->e_delivery_service, ODR_CONTEXT, 0, 1, "e_delivery_service") &&
		odr_implicit_tag (o, ill_Electronic_Delivery_Service_1,
			&(*p)->document_type, ODR_CONTEXT, 1, 1, "document_type") &&
		odr_explicit_tag (o, ill_String,
			&(*p)->e_delivery_description, ODR_CONTEXT, 4, 1, "e_delivery_description") &&
		odr_constructed_begin (o, &(*p)->u, ODR_CONTEXT, 5, "e_delivery_details") &&
		odr_choice (o, arm, &(*p)->u, &(*p)->which, 0) &&
		odr_constructed_end (o) &&
		odr_explicit_tag (o, ill_String,
			&(*p)->name_or_code, ODR_CONTEXT, 6, 1, "name_or_code") &&
		odr_implicit_tag (o, ill_ISO_Time,
			&(*p)->delivery_time, ODR_CONTEXT, 7, 1, "delivery_time") &&
		odr_sequence_end (o);
}

int ill_Error_Report (ODR o, ILL_Error_Report **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_explicit_tag (o, ill_String,
			&(*p)->correlation_information, ODR_CONTEXT, 0, 0, "correlation_information") &&
		odr_implicit_tag (o, ill_Report_Source,
			&(*p)->report_source, ODR_CONTEXT, 1, 0, "report_source") &&
		odr_explicit_tag (o, ill_User_Error_Report,
			&(*p)->user_error_report, ODR_CONTEXT, 2, 1, "user_error_report") &&
		odr_explicit_tag (o, ill_Provider_Error_Report,
			&(*p)->provider_error_report, ODR_CONTEXT, 3, 1, "provider_error_report") &&
		odr_sequence_end (o);
}

int ill_Estimate_Results (ODR o, ILL_Estimate_Results **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_explicit_tag (o, ill_String,
			&(*p)->cost_estimate, ODR_CONTEXT, 0, 0, "cost_estimate") &&
		odr_implicit_settag (o, ODR_CONTEXT, 1) &&
		(odr_sequence_of(o, (Odr_fun) ill_Location_Info, &(*p)->locations,
		  &(*p)->num_locations, "locations") || odr_ok(o)) &&
		odr_sequence_end (o);
}

int ill_Extension (ODR o, ILL_Extension **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, odr_integer,
			&(*p)->identifier, ODR_CONTEXT, 0, 0, "identifier") &&
		odr_implicit_tag (o, odr_bool,
			&(*p)->critical, ODR_CONTEXT, 1, 0, "critical") &&
		odr_explicit_tag (o, odr_any,
			&(*p)->item, ODR_CONTEXT, 2, 0, "item") &&
		odr_sequence_end (o);
}

int ill_General_Problem (ODR o, ILL_General_Problem **p, int opt, const char *name)
{
	return odr_enum (o, p, opt, name);
}

int ill_History_Report (ODR o, ILL_History_Report **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, ill_ISO_Date,
			&(*p)->date_requested, ODR_CONTEXT, 0, 1, "date_requested") &&
		odr_explicit_tag (o, ill_String,
			&(*p)->author, ODR_CONTEXT, 1, 1, "author") &&
		odr_explicit_tag (o, ill_String,
			&(*p)->title, ODR_CONTEXT, 2, 1, "title") &&
		odr_explicit_tag (o, ill_String,
			&(*p)->author_of_article, ODR_CONTEXT, 3, 1, "author_of_article") &&
		odr_explicit_tag (o, ill_String,
			&(*p)->title_of_article, ODR_CONTEXT, 4, 1, "title_of_article") &&
		odr_implicit_tag (o, ill_ISO_Date,
			&(*p)->date_of_last_transition, ODR_CONTEXT, 5, 0, "date_of_last_transition") &&
		odr_implicit_tag (o, odr_enum,
			&(*p)->most_recent_service, ODR_CONTEXT, 6, 0, "most_recent_service") &&
		odr_implicit_tag (o, ill_ISO_Date,
			&(*p)->date_of_most_recent_service, ODR_CONTEXT, 7, 0, "date_of_most_recent_service") &&
		odr_implicit_tag (o, ill_System_Id,
			&(*p)->initiator_of_most_recent_service, ODR_CONTEXT, 8, 0, "initiator_of_most_recent_service") &&
		odr_implicit_tag (o, ill_Shipped_Service_Type,
			&(*p)->shipped_service_type, ODR_CONTEXT, 9, 1, "shipped_service_type") &&
		odr_implicit_tag (o, ill_Transaction_Results,
			&(*p)->transaction_results, ODR_CONTEXT, 10, 1, "transaction_results") &&
		odr_explicit_tag (o, ill_String,
			&(*p)->most_recent_service_note, ODR_CONTEXT, 11, 1, "most_recent_service_note") &&
		odr_sequence_end (o);
}

int ill_Hold_Placed_Results (ODR o, ILL_Hold_Placed_Results **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, ill_ISO_Date,
			&(*p)->estimated_date_available, ODR_CONTEXT, 0, 0, "estimated_date_available") &&
		odr_implicit_tag (o, ill_Medium_Type,
			&(*p)->hold_placed_medium_type, ODR_CONTEXT, 1, 1, "hold_placed_medium_type") &&
		odr_implicit_settag (o, ODR_CONTEXT, 2) &&
		(odr_sequence_of(o, (Odr_fun) ill_Location_Info, &(*p)->locations,
		  &(*p)->num_locations, "locations") || odr_ok(o)) &&
		odr_sequence_end (o);
}

int ill_APDU_Type (ODR o, ILL_APDU_Type **p, int opt, const char *name)
{
	return odr_enum (o, p, opt, name);
}

int ill_Service_Type (ODR o, ILL_Service_Type **p, int opt, const char *name)
{
	return odr_enum (o, p, opt, name);
}

int ill_String (ODR o, ILL_String **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{-1, -1, -1, ILL_String_GeneralString,
		 (Odr_fun) odr_generalstring, "GeneralString"},
		{-1, -1, -1, ILL_String_EDIFACTString,
		 (Odr_fun) ill_EDIFACTString, "EDIFACTString"},
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

int ill_Intermediary_Problem (ODR o, ILL_Intermediary_Problem **p, int opt, const char *name)
{
	return odr_enum (o, p, opt, name);
}

int ill_ISO_Date (ODR o, ILL_ISO_Date **p, int opt, const char *name)
{
	return odr_visiblestring (o, p, opt, name);
}

int ill_ISO_Time (ODR o, ILL_ISO_Time **p, int opt, const char *name)
{
	return odr_visiblestring (o, p, opt, name);
}

int ill_Item_Id (ODR o, ILL_Item_Id **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, odr_enum,
			&(*p)->item_type, ODR_CONTEXT, 0, 1, "item_type") &&
		odr_implicit_tag (o, ill_Medium_Type,
			&(*p)->held_medium_type, ODR_CONTEXT, 1, 1, "held_medium_type") &&
		odr_explicit_tag (o, ill_String,
			&(*p)->call_number, ODR_CONTEXT, 2, 1, "call_number") &&
		odr_explicit_tag (o, ill_String,
			&(*p)->author, ODR_CONTEXT, 3, 1, "author") &&
		odr_explicit_tag (o, ill_String,
			&(*p)->title, ODR_CONTEXT, 4, 1, "title") &&
		odr_explicit_tag (o, ill_String,
			&(*p)->sub_title, ODR_CONTEXT, 5, 1, "sub_title") &&
		odr_explicit_tag (o, ill_String,
			&(*p)->sponsoring_body, ODR_CONTEXT, 6, 1, "sponsoring_body") &&
		odr_explicit_tag (o, ill_String,
			&(*p)->place_of_publication, ODR_CONTEXT, 7, 1, "place_of_publication") &&
		odr_explicit_tag (o, ill_String,
			&(*p)->publisher, ODR_CONTEXT, 8, 1, "publisher") &&
		odr_explicit_tag (o, ill_String,
			&(*p)->series_title_number, ODR_CONTEXT, 9, 1, "series_title_number") &&
		odr_explicit_tag (o, ill_String,
			&(*p)->volume_issue, ODR_CONTEXT, 10, 1, "volume_issue") &&
		odr_explicit_tag (o, ill_String,
			&(*p)->edition, ODR_CONTEXT, 11, 1, "edition") &&
		odr_explicit_tag (o, ill_String,
			&(*p)->publication_date, ODR_CONTEXT, 12, 1, "publication_date") &&
		odr_explicit_tag (o, ill_String,
			&(*p)->publication_date_of_component, ODR_CONTEXT, 13, 1, "publication_date_of_component") &&
		odr_explicit_tag (o, ill_String,
			&(*p)->author_of_article, ODR_CONTEXT, 14, 1, "author_of_article") &&
		odr_explicit_tag (o, ill_String,
			&(*p)->title_of_article, ODR_CONTEXT, 15, 1, "title_of_article") &&
		odr_explicit_tag (o, ill_String,
			&(*p)->pagination, ODR_CONTEXT, 16, 1, "pagination") &&
		odr_explicit_tag (o, odr_external,
			&(*p)->national_bibliography_no, ODR_CONTEXT, 17, 1, "national_bibliography_no") &&
		odr_explicit_tag (o, ill_String,
			&(*p)->iSBN, ODR_CONTEXT, 18, 1, "iSBN") &&
		odr_explicit_tag (o, ill_String,
			&(*p)->iSSN, ODR_CONTEXT, 19, 1, "iSSN") &&
		odr_explicit_tag (o, odr_external,
			&(*p)->system_no, ODR_CONTEXT, 20, 1, "system_no") &&
		odr_explicit_tag (o, ill_String,
			&(*p)->additional_no_letters, ODR_CONTEXT, 21, 1, "additional_no_letters") &&
		odr_explicit_tag (o, ill_String,
			&(*p)->verification_reference_source, ODR_CONTEXT, 22, 1, "verification_reference_source") &&
		odr_sequence_end (o);
}

int ill_Location_Info (ODR o, ILL_Location_Info **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, ill_System_Id,
			&(*p)->location_id, ODR_CONTEXT, 0, 0, "location_id") &&
		odr_implicit_tag (o, ill_System_Address,
			&(*p)->location_address, ODR_CONTEXT, 1, 1, "location_address") &&
		odr_explicit_tag (o, ill_String,
			&(*p)->location_note, ODR_CONTEXT, 2, 1, "location_note") &&
		odr_sequence_end (o);
}

int ill_Locations_Results (ODR o, ILL_Locations_Results **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, ill_Reason_Locs_Provided,
			&(*p)->reason_locs_provided, ODR_CONTEXT, 0, 1, "reason_locs_provided") &&
		odr_implicit_settag (o, ODR_CONTEXT, 1) &&
		odr_sequence_of(o, (Odr_fun) ill_Location_Info, &(*p)->locations,
		  &(*p)->num_locations, "locations") &&
		odr_sequence_end (o);
}

int ill_Medium_Type (ODR o, ILL_Medium_Type **p, int opt, const char *name)
{
	return odr_enum (o, p, opt, name);
}

int ill_Name_Of_Person_Or_Institution (ODR o, ILL_Name_Of_Person_Or_Institution **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_EXPLICIT, ODR_CONTEXT, 0, ILL_Name_Of_Person_Or_Institution_name_of_person,
		(Odr_fun) ill_String, "name_of_person"},
		{ODR_EXPLICIT, ODR_CONTEXT, 1, ILL_Name_Of_Person_Or_Institution_name_of_institution,
		(Odr_fun) ill_String, "name_of_institution"},
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

int ill_Person_Or_Institution_Symbol (ODR o, ILL_Person_Or_Institution_Symbol **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_EXPLICIT, ODR_CONTEXT, 0, ILL_Person_Or_Institution_Symbol_person_symbol,
		(Odr_fun) ill_String, "person_symbol"},
		{ODR_EXPLICIT, ODR_CONTEXT, 1, ILL_Person_Or_Institution_Symbol_institution_symbol,
		(Odr_fun) ill_String, "institution_symbol"},
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

int ill_Place_On_Hold_Type (ODR o, ILL_Place_On_Hold_Type **p, int opt, const char *name)
{
	return odr_enum (o, p, opt, name);
}

int ill_Postal_Address (ODR o, ILL_Postal_Address **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_explicit_tag (o, ill_Name_Of_Person_Or_Institution,
			&(*p)->name_of_person_or_institution, ODR_CONTEXT, 0, 1, "name_of_person_or_institution") &&
		odr_explicit_tag (o, ill_String,
			&(*p)->extended_postal_delivery_address, ODR_CONTEXT, 1, 1, "extended_postal_delivery_address") &&
		odr_explicit_tag (o, ill_String,
			&(*p)->street_and_number, ODR_CONTEXT, 2, 1, "street_and_number") &&
		odr_explicit_tag (o, ill_String,
			&(*p)->post_office_box, ODR_CONTEXT, 3, 1, "post_office_box") &&
		odr_explicit_tag (o, ill_String,
			&(*p)->city, ODR_CONTEXT, 4, 1, "city") &&
		odr_explicit_tag (o, ill_String,
			&(*p)->region, ODR_CONTEXT, 5, 1, "region") &&
		odr_explicit_tag (o, ill_String,
			&(*p)->country, ODR_CONTEXT, 6, 1, "country") &&
		odr_explicit_tag (o, ill_String,
			&(*p)->postal_code, ODR_CONTEXT, 7, 1, "postal_code") &&
		odr_sequence_end (o);
}

int ill_Provider_Error_Report (ODR o, ILL_Provider_Error_Report **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 0, ILL_Provider_Error_Report_general_problem,
		(Odr_fun) ill_General_Problem, "general_problem"},
		{ODR_IMPLICIT, ODR_CONTEXT, 1, ILL_Provider_Error_Report_transaction_id_problem,
		(Odr_fun) ill_Transaction_Id_Problem, "transaction_id_problem"},
		{ODR_IMPLICIT, ODR_CONTEXT, 2, ILL_Provider_Error_Report_state_transition_prohibited,
		(Odr_fun) ill_State_Transition_Prohibited, "state_transition_prohibited"},
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

int ill_Reason_Locs_Provided (ODR o, ILL_Reason_Locs_Provided **p, int opt, const char *name)
{
	return odr_enum (o, p, opt, name);
}

int ill_Reason_No_Report (ODR o, ILL_Reason_No_Report **p, int opt, const char *name)
{
	return odr_enum (o, p, opt, name);
}

int ill_Reason_Unfilled (ODR o, ILL_Reason_Unfilled **p, int opt, const char *name)
{
	return odr_enum (o, p, opt, name);
}

int ill_Report_Source (ODR o, ILL_Report_Source **p, int opt, const char *name)
{
	return odr_enum (o, p, opt, name);
}

int ill_Requester_Optional_Messages_Type (ODR o, ILL_Requester_Optional_Messages_Type **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, odr_bool,
			&(*p)->can_send_RECEIVED, ODR_CONTEXT, 0, 0, "can_send_RECEIVED") &&
		odr_implicit_tag (o, odr_bool,
			&(*p)->can_send_RETURNED, ODR_CONTEXT, 1, 0, "can_send_RETURNED") &&
		odr_implicit_tag (o, odr_enum,
			&(*p)->requester_SHIPPED, ODR_CONTEXT, 2, 0, "requester_SHIPPED") &&
		odr_implicit_tag (o, odr_enum,
			&(*p)->requester_CHECKED_IN, ODR_CONTEXT, 3, 0, "requester_CHECKED_IN") &&
		odr_sequence_end (o);
}

int ill_Responder_Optional_Messages_Type (ODR o, ILL_Responder_Optional_Messages_Type **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, odr_bool,
			&(*p)->can_send_SHIPPED, ODR_CONTEXT, 0, 0, "can_send_SHIPPED") &&
		odr_implicit_tag (o, odr_bool,
			&(*p)->can_send_CHECKED_IN, ODR_CONTEXT, 1, 0, "can_send_CHECKED_IN") &&
		odr_implicit_tag (o, odr_enum,
			&(*p)->responder_RECEIVED, ODR_CONTEXT, 2, 0, "responder_RECEIVED") &&
		odr_implicit_tag (o, odr_enum,
			&(*p)->responder_RETURNED, ODR_CONTEXT, 3, 0, "responder_RETURNED") &&
		odr_sequence_end (o);
}

int ill_Retry_Results (ODR o, ILL_Retry_Results **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, odr_enum,
			&(*p)->reason_not_available, ODR_CONTEXT, 0, 1, "reason_not_available") &&
		odr_implicit_tag (o, ill_ISO_Date,
			&(*p)->retry_date, ODR_CONTEXT, 1, 1, "retry_date") &&
		odr_implicit_settag (o, ODR_CONTEXT, 2) &&
		(odr_sequence_of(o, (Odr_fun) ill_Location_Info, &(*p)->locations,
		  &(*p)->num_locations, "locations") || odr_ok(o)) &&
		odr_sequence_end (o);
}

int ill_Search_Type (ODR o, ILL_Search_Type **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_explicit_tag (o, ill_String,
			&(*p)->level_of_service, ODR_CONTEXT, 0, 1, "level_of_service") &&
		odr_implicit_tag (o, ill_ISO_Date,
			&(*p)->need_before_date, ODR_CONTEXT, 1, 1, "need_before_date") &&
		odr_implicit_tag (o, odr_enum,
			&(*p)->expiry_flag, ODR_CONTEXT, 2, 0, "expiry_flag") &&
		odr_implicit_tag (o, ill_ISO_Date,
			&(*p)->expiry_date, ODR_CONTEXT, 3, 1, "expiry_date") &&
		odr_sequence_end (o);
}

int ill_Security_Problem (ODR o, ILL_Security_Problem **p, int opt, const char *name)
{
	return ill_String (o, p, opt, name);
}

int ill_Send_To_List_Type_s (ODR o, ILL_Send_To_List_Type_s **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, ill_System_Id,
			&(*p)->system_id, ODR_CONTEXT, 0, 0, "system_id") &&
		odr_explicit_tag (o, ill_Account_Number,
			&(*p)->account_number, ODR_CONTEXT, 1, 1, "account_number") &&
		odr_implicit_tag (o, ill_System_Address,
			&(*p)->system_address, ODR_CONTEXT, 2, 1, "system_address") &&
		odr_sequence_end (o);
}

int ill_Send_To_List_Type (ODR o, ILL_Send_To_List_Type **p, int opt, const char *name)
{
	if (!odr_initmember (o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_sequence_of (o, (Odr_fun) ill_Send_To_List_Type_s, &(*p)->elements,
		&(*p)->num, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int ill_Service_Date_this (ODR o, ILL_Service_Date_this **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, ill_ISO_Date,
			&(*p)->date, ODR_CONTEXT, 0, 0, "date") &&
		odr_implicit_tag (o, ill_ISO_Time,
			&(*p)->time, ODR_CONTEXT, 1, 1, "time") &&
		odr_sequence_end (o);
}

int ill_Service_Date_original (ODR o, ILL_Service_Date_original **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, ill_ISO_Date,
			&(*p)->date, ODR_CONTEXT, 0, 0, "date") &&
		odr_implicit_tag (o, ill_ISO_Time,
			&(*p)->time, ODR_CONTEXT, 1, 1, "time") &&
		odr_sequence_end (o);
}

int ill_Service_Date_Time (ODR o, ILL_Service_Date_Time **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, ill_Service_Date_this,
			&(*p)->date_time_of_this_service, ODR_CONTEXT, 0, 0, "date_time_of_this_service") &&
		odr_implicit_tag (o, ill_Service_Date_original,
			&(*p)->date_time_of_original_service, ODR_CONTEXT, 1, 1, "date_time_of_original_service") &&
		odr_sequence_end (o);
}

int ill_Shipped_Service_Type (ODR o, ILL_Shipped_Service_Type **p, int opt, const char *name)
{
	return ill_Service_Type (o, p, opt, name);
}

int ill_State_Transition_Prohibited (ODR o, ILL_State_Transition_Prohibited **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, ill_APDU_Type,
			&(*p)->aPDU_type, ODR_CONTEXT, 0, 0, "aPDU_type") &&
		odr_implicit_tag (o, ill_Current_State,
			&(*p)->current_state, ODR_CONTEXT, 1, 0, "current_state") &&
		odr_sequence_end (o);
}

int ill_Status_Report (ODR o, ILL_Status_Report **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, ill_History_Report,
			&(*p)->user_status_report, ODR_CONTEXT, 0, 0, "user_status_report") &&
		odr_implicit_tag (o, ill_Current_State,
			&(*p)->provider_status_report, ODR_CONTEXT, 1, 0, "provider_status_report") &&
		odr_sequence_end (o);
}

int ill_Supplemental_Item_Description (ODR o, ILL_Supplemental_Item_Description **p, int opt, const char *name)
{
	if (!odr_initmember (o, p, sizeof(**p)))
		return odr_missing(o, opt, name);
	if (odr_sequence_of (o, (Odr_fun) odr_external, &(*p)->elements,
		&(*p)->num, name))
		return 1;
	if(o->direction == ODR_DECODE)
		*p = 0;
	return odr_missing(o, opt, name);
}

int ill_Supply_Details (ODR o, ILL_Supply_Details **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_EXPLICIT, ODR_CONTEXT, 5, ILL_Supply_Details_physical_delivery,
		(Odr_fun) ill_Transportation_Mode, "physical_delivery"},
		{ODR_IMPLICIT, ODR_CONTEXT, 50, ILL_Supply_Details_electronic_delivery,
		(Odr_fun) ill_Electronic_Delivery_Service, "electronic_delivery"},
		{-1, -1, -1, -1, (Odr_fun) 0, 0}
	};
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, ill_ISO_Date,
			&(*p)->date_shipped, ODR_CONTEXT, 0, 1, "date_shipped") &&
		odr_implicit_tag (o, ill_Date_Due,
			&(*p)->date_due, ODR_CONTEXT, 1, 1, "date_due") &&
		odr_implicit_tag (o, odr_integer,
			&(*p)->chargeable_units, ODR_CONTEXT, 2, 1, "chargeable_units") &&
		odr_implicit_tag (o, ill_Amount,
			&(*p)->cost, ODR_CONTEXT, 3, 1, "cost") &&
		odr_implicit_tag (o, odr_enum,
			&(*p)->shipped_conditions, ODR_CONTEXT, 4, 1, "shipped_conditions") &&
		(odr_choice (o, arm, &(*p)->u, &(*p)->which, 0) || odr_ok(o)) &&
		odr_implicit_tag (o, ill_Amount,
			&(*p)->insured_for, ODR_CONTEXT, 6, 1, "insured_for") &&
		odr_implicit_tag (o, ill_Amount,
			&(*p)->return_insurance_require, ODR_CONTEXT, 7, 1, "return_insurance_require") &&
		odr_implicit_settag (o, ODR_CONTEXT, 8) &&
		(odr_sequence_of(o, (Odr_fun) ill_Units_Per_Medium_Type, &(*p)->no_of_units_per_medium,
		  &(*p)->num_no_of_units_per_medium, "no_of_units_per_medium") || odr_ok(o)) &&
		odr_sequence_end (o);
}

int ill_Supply_Medium_Info_Type (ODR o, ILL_Supply_Medium_Info_Type **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, ill_Supply_Medium_Type,
			&(*p)->supply_medium_type, ODR_CONTEXT, 0, 0, "supply_medium_type") &&
		odr_explicit_tag (o, ill_String,
			&(*p)->medium_characteristics, ODR_CONTEXT, 1, 1, "medium_characteristics") &&
		odr_sequence_end (o);
}

int ill_Supply_Medium_Type (ODR o, ILL_Supply_Medium_Type **p, int opt, const char *name)
{
	return odr_enum (o, p, opt, name);
}

int ill_System_Address (ODR o, ILL_System_Address **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_explicit_tag (o, ill_String,
			&(*p)->telecom_service_identifier, ODR_CONTEXT, 0, 1, "telecom_service_identifier") &&
		odr_explicit_tag (o, ill_String,
			&(*p)->telecom_service_address, ODR_CONTEXT, 1, 1, "telecom_service_address") &&
		odr_sequence_end (o);
}

int ill_System_Id (ODR o, ILL_System_Id **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_explicit_tag (o, ill_Person_Or_Institution_Symbol,
			&(*p)->person_or_institution_symbol, ODR_CONTEXT, 0, 1, "person_or_institution_symbol") &&
		odr_explicit_tag (o, ill_Name_Of_Person_Or_Institution,
			&(*p)->name_of_person_or_institution, ODR_CONTEXT, 1, 1, "name_of_person_or_institution") &&
		odr_sequence_end (o);
}

int ill_Third_Party_Info_Type (ODR o, ILL_Third_Party_Info_Type **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, odr_bool,
			&(*p)->permission_to_forward, ODR_CONTEXT, 0, 0, "permission_to_forward") &&
		odr_implicit_tag (o, odr_bool,
			&(*p)->permission_to_chain, ODR_CONTEXT, 1, 0, "permission_to_chain") &&
		odr_implicit_tag (o, odr_bool,
			&(*p)->permission_to_partition, ODR_CONTEXT, 2, 0, "permission_to_partition") &&
		odr_implicit_tag (o, odr_bool,
			&(*p)->permission_to_change_send_to_list, ODR_CONTEXT, 3, 0, "permission_to_change_send_to_list") &&
		odr_implicit_tag (o, ill_System_Address,
			&(*p)->initial_requester_address, ODR_CONTEXT, 4, 1, "initial_requester_address") &&
		odr_implicit_tag (o, odr_enum,
			&(*p)->preference, ODR_CONTEXT, 5, 0, "preference") &&
		odr_implicit_tag (o, ill_Send_To_List_Type,
			&(*p)->send_to_list, ODR_CONTEXT, 6, 1, "send_to_list") &&
		odr_implicit_tag (o, ill_Already_Tried_List_Type,
			&(*p)->already_tried_list, ODR_CONTEXT, 7, 1, "already_tried_list") &&
		odr_sequence_end (o);
}

int ill_Transaction_Id (ODR o, ILL_Transaction_Id **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, ill_System_Id,
			&(*p)->initial_requester_id, ODR_CONTEXT, 0, 1, "initial_requester_id") &&
		odr_explicit_tag (o, ill_String,
			&(*p)->transaction_group_qualifier, ODR_CONTEXT, 1, 0, "transaction_group_qualifier") &&
		odr_explicit_tag (o, ill_String,
			&(*p)->transaction_qualifier, ODR_CONTEXT, 2, 0, "transaction_qualifier") &&
		odr_explicit_tag (o, ill_String,
			&(*p)->sub_transaction_qualifier, ODR_CONTEXT, 3, 1, "sub_transaction_qualifier") &&
		odr_sequence_end (o);
}

int ill_Transaction_Id_Problem (ODR o, ILL_Transaction_Id_Problem **p, int opt, const char *name)
{
	return odr_enum (o, p, opt, name);
}

int ill_Transaction_Results (ODR o, ILL_Transaction_Results **p, int opt, const char *name)
{
	return odr_enum (o, p, opt, name);
}

int ill_Transaction_Type (ODR o, ILL_Transaction_Type **p, int opt, const char *name)
{
	return odr_enum (o, p, opt, name);
}

int ill_Transportation_Mode (ODR o, ILL_Transportation_Mode **p, int opt, const char *name)
{
	return ill_String (o, p, opt, name);
}

int ill_Unable_To_Perform (ODR o, ILL_Unable_To_Perform **p, int opt, const char *name)
{
	return odr_enum (o, p, opt, name);
}

int ill_Unfilled_Results (ODR o, ILL_Unfilled_Results **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_implicit_tag (o, ill_Reason_Unfilled,
			&(*p)->reason_unfilled, ODR_CONTEXT, 0, 0, "reason_unfilled") &&
		odr_implicit_settag (o, ODR_CONTEXT, 1) &&
		(odr_sequence_of(o, (Odr_fun) ill_Location_Info, &(*p)->locations,
		  &(*p)->num_locations, "locations") || odr_ok(o)) &&
		odr_sequence_end (o);
}

int ill_Units_Per_Medium_Type (ODR o, ILL_Units_Per_Medium_Type **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_explicit_tag (o, ill_Supply_Medium_Type,
			&(*p)->medium, ODR_CONTEXT, 0, 0, "medium") &&
		odr_explicit_tag (o, odr_integer,
			&(*p)->no_of_units, ODR_CONTEXT, 1, 0, "no_of_units") &&
		odr_sequence_end (o);
}

int ill_User_Error_Report (ODR o, ILL_User_Error_Report **p, int opt, const char *name)
{
	static Odr_arm arm[] = {
		{ODR_IMPLICIT, ODR_CONTEXT, 0, ILL_User_Error_Report_already_forwarded,
		(Odr_fun) ill_Already_Forwarded, "already_forwarded"},
		{ODR_IMPLICIT, ODR_CONTEXT, 1, ILL_User_Error_Report_intermediary_problem,
		(Odr_fun) ill_Intermediary_Problem, "intermediary_problem"},
		{ODR_EXPLICIT, ODR_CONTEXT, 2, ILL_User_Error_Report_security_problem,
		(Odr_fun) ill_Security_Problem, "security_problem"},
		{ODR_IMPLICIT, ODR_CONTEXT, 3, ILL_User_Error_Report_unable_to_perform,
		(Odr_fun) ill_Unable_To_Perform, "unable_to_perform"},
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

int ill_Will_Supply_Results (ODR o, ILL_Will_Supply_Results **p, int opt, const char *name)
{
	if (!odr_sequence_begin (o, p, sizeof(**p), name))
		return odr_missing(o, opt, name) && odr_ok (o);
	return
		odr_explicit_tag (o, odr_enum,
			&(*p)->reason_will_supply, ODR_CONTEXT, 0, 0, "reason_will_supply") &&
		odr_explicit_tag (o, ill_ISO_Date,
			&(*p)->supply_date, ODR_CONTEXT, 1, 1, "supply_date") &&
		odr_explicit_tag (o, ill_Postal_Address,
			&(*p)->return_to_address, ODR_CONTEXT, 2, 1, "return_to_address") &&
		odr_implicit_settag (o, ODR_CONTEXT, 3) &&
		(odr_sequence_of(o, (Odr_fun) ill_Location_Info, &(*p)->locations,
		  &(*p)->num_locations, "locations") || odr_ok(o)) &&
		odr_explicit_tag (o, ill_Electronic_Delivery_Service,
			&(*p)->electronic_delivery_service, ODR_CONTEXT, 4, 1, "electronic_delivery_service") &&
		odr_sequence_end (o);
}

int ill_EDIFACTString (ODR o, ILL_EDIFACTString **p, int opt, const char *name)
{
	return odr_visiblestring (o, p, opt, name);
}


