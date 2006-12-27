/*
 * Copyright (C) 1995-2005, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: ill-get.c,v 1.5 2005/06/25 15:46:04 adam Exp $
 */

/**
 * \file ill-get.c
 * \brief Implements ILL package creator utilities
 */

#include <stdlib.h>
#include "ill.h"

bool_t *ill_get_bool (struct ill_get_ctl *gc, const char *name,
                      const char *sub, int val)
{
    ODR o = gc->odr;
    char element[128];
    const char *v;
    bool_t *r = (bool_t *) odr_malloc (o, sizeof(*r));
    
    strcpy(element, name);
    if (sub)
    {
        strcat (element, ",");
        strcat (element, sub);
    }    

    v = (gc->f)(gc->clientData, element);
    if (v)
        val = atoi(v);
    else if (val < 0)
        return 0;
    *r = val;
    return r;
}

int *ill_get_int (struct ill_get_ctl *gc, const char *name,
                  const char *sub, int val)
{
    ODR o = gc->odr;
    char element[128];
    const char *v;
    
    strcpy(element, name);
    if (sub)
    {
        strcat (element, ",");
        strcat (element, sub);
    }    
    v = (gc->f)(gc->clientData, element);
    if (v)
        val = atoi(v);
    return odr_intdup(o, val);
}

int *ill_get_enumerated (struct ill_get_ctl *gc, const char *name,
                         const char *sub, int val)
{
    return ill_get_int(gc, name, sub, val);
}

ILL_String *ill_get_ILL_String_x (struct ill_get_ctl *gc, const char *name,
                                  const char *sub, const char *vdefault)
{
    ILL_String *r = (ILL_String *) odr_malloc (gc->odr, sizeof(*r));
    char element[128];
    const char *v;

    strcpy(element, name);
    if (sub)
    {
        strcat (element, ",");
        strcat (element, sub);
    }
    v = (gc->f)(gc->clientData, element);
    if (!v)
        v = vdefault;
    if (!v)
        return 0;
    r->which = ILL_String_GeneralString;
    r->u.GeneralString = odr_strdup (gc->odr, v);
    return r;
}

ILL_String *ill_get_ILL_String(struct ill_get_ctl *gc, const char *name,
                               const char *sub)
{
    return ill_get_ILL_String_x (gc, name, sub, 0);
}

ILL_ISO_Date *ill_get_ILL_ISO_Date (struct ill_get_ctl *gc, const char *name,
                                    const char *sub, const char *val)
{
    char element[128];
    const char *v;

    strcpy(element, name);
    if (sub)
    {
        strcat (element, ",");
        strcat (element, sub);
    }
    v = (gc->f)(gc->clientData, element);
    if (!v)
        v = val;
    if (!v)
        return 0;
    return odr_strdup (gc->odr, v);
}

ILL_ISO_Time *ill_get_ILL_ISO_Time (struct ill_get_ctl *gc, const char *name,
                                    const char *sub, const char *val)
{
    char element[128];
    const char *v;

    strcpy(element, name);
    if (sub)
    {
        strcat (element, ",");
        strcat (element, sub);
    }
    v = (gc->f)(gc->clientData, element);
    if (!v)
        v = val;
    if (!v)
        return 0;
    return odr_strdup (gc->odr, v);
}

ILL_Person_Or_Institution_Symbol *ill_get_Person_Or_Insitution_Symbol (
    struct ill_get_ctl *gc, const char *name, const char *sub)
{
    char element[128];
    ODR o = gc->odr;
    ILL_Person_Or_Institution_Symbol *p =
        (ILL_Person_Or_Institution_Symbol *) odr_malloc (o, sizeof(*p));
    
    strcpy(element, name);
    if (sub)
    {
        strcat (element, ",");
        strcat (element, sub);
    }
    p->which = ILL_Person_Or_Institution_Symbol_person_symbol;
    if ((p->u.person_symbol = ill_get_ILL_String (gc, element, "person")))
        return p;

    p->which = ILL_Person_Or_Institution_Symbol_institution_symbol;
    if ((p->u.institution_symbol =
         ill_get_ILL_String (gc, element, "institution")))
        return p;
    return 0;
}

static ILL_Name_Of_Person_Or_Institution *ill_get_Name_Of_Person_Or_Institution(
    struct ill_get_ctl *gc, const char *name, const char *sub)
{
    char element[128];
    ODR o = gc->odr;
    ILL_Name_Of_Person_Or_Institution *p =
        (ILL_Name_Of_Person_Or_Institution *) odr_malloc (o, sizeof(*p));
    
    strcpy(element, name);
    if (sub)
    {
        strcat (element, ",");
        strcat (element, sub);
    }
    p->which = ILL_Name_Of_Person_Or_Institution_name_of_person;
    if ((p->u.name_of_person =
         ill_get_ILL_String (gc, element, "name-of-person")))
        return p;

    p->which = ILL_Name_Of_Person_Or_Institution_name_of_institution;
    if ((p->u.name_of_institution =
         ill_get_ILL_String (gc, element, "name-of-institution")))
        return p;
    return 0;
}
    
ILL_System_Id *ill_get_System_Id(struct ill_get_ctl *gc,
                                 const char *name, const char *sub)
{
    ODR o = gc->odr;
    char element[128];
    ILL_System_Id *p;
    
    strcpy(element, name);
    if (sub)
    {
        strcat (element, ",");
        strcat (element, sub);
    }
    p = (ILL_System_Id *) odr_malloc (o, sizeof(*p));
    p->person_or_institution_symbol = ill_get_Person_Or_Insitution_Symbol (
        gc, element, "person-or-institution-symbol");
    p->name_of_person_or_institution = ill_get_Name_Of_Person_Or_Institution (
        gc, element, "name-of-person-or-institution");
    return p;
}

ILL_Transaction_Id *ill_get_Transaction_Id (struct ill_get_ctl *gc,
                                            const char *name, const char *sub)
{
    ODR o = gc->odr;
    ILL_Transaction_Id *r = (ILL_Transaction_Id *) odr_malloc (o, sizeof(*r));
    char element[128];
    
    strcpy(element, name);
    if (sub)
    {
        strcat (element, ",");
        strcat (element, sub);
    }    
    r->initial_requester_id =
        ill_get_System_Id (gc, element, "initial-requester-id");
    r->transaction_group_qualifier =
        ill_get_ILL_String_x (gc, element, "transaction-group-qualifier", "");
    r->transaction_qualifier =
        ill_get_ILL_String_x (gc, element, "transaction-qualifier", "");
    r->sub_transaction_qualifier =
        ill_get_ILL_String (gc, element, "sub-transaction-qualifier");
    return r;
}


ILL_Service_Date_this *ill_get_Service_Date_this (
    struct ill_get_ctl *gc, const char *name, const char *sub)
{
    ODR o = gc->odr;
    ILL_Service_Date_this *r =
        (ILL_Service_Date_this *) odr_malloc (o, sizeof(*r));
    char element[128];
    
    strcpy(element, name);
    if (sub)
    {
        strcat (element, ",");
        strcat (element, sub);
    }
    r->date = ill_get_ILL_ISO_Date (gc, element, "date", "20000101");
    r->time = ill_get_ILL_ISO_Time (gc, element, "time", 0);
    return r;
}

ILL_Service_Date_original *ill_get_Service_Date_original (
    struct ill_get_ctl *gc, const char *name, const char *sub)
{
    ODR o = gc->odr;
    ILL_Service_Date_original *r =
        (ILL_Service_Date_original *) odr_malloc (o, sizeof(*r));
    char element[128];
    
    strcpy(element, name);
    if (sub)
    {
        strcat (element, ",");
        strcat (element, sub);
    }
    r->date = ill_get_ILL_ISO_Date (gc, element, "date", 0);
    r->time = ill_get_ILL_ISO_Time (gc, element, "time", 0);
    if (!r->date && !r->time)
        return 0;
    return r;
}

ILL_Service_Date_Time *ill_get_Service_Date_Time (
    struct ill_get_ctl *gc, const char *name, const char *sub)
{
    ODR o = gc->odr;
    ILL_Service_Date_Time *r =
        (ILL_Service_Date_Time *) odr_malloc (o, sizeof(*r));
    char element[128];
    
    strcpy(element, name);
    if (sub)
    {
        strcat (element, ",");
        strcat (element, sub);
    }    
    r->date_time_of_this_service = ill_get_Service_Date_this (
        gc, element, "this");
    r->date_time_of_original_service = ill_get_Service_Date_original (
        gc, element, "original");
    return r;
}

ILL_Requester_Optional_Messages_Type *ill_get_Requester_Optional_Messages_Type (
    struct ill_get_ctl *gc, const char *name, const char *sub)
{
    ODR o = gc->odr;
    ILL_Requester_Optional_Messages_Type *r =
        (ILL_Requester_Optional_Messages_Type *) odr_malloc (o, sizeof(*r));
    char element[128];
    
    strcpy(element, name);
    if (sub)
    {
        strcat (element, ",");
        strcat (element, sub);
    }
    r->can_send_RECEIVED = ill_get_bool (gc, element, "can-send-RECEIVED", 0);
    r->can_send_RETURNED = ill_get_bool (gc, element, "can-send-RETURNED", 0);
    r->requester_SHIPPED =
        ill_get_enumerated (gc, element, "requester-SHIPPED", 1);
    r->requester_CHECKED_IN =
        ill_get_enumerated (gc, element, "requester-CHECKED-IN", 1);
    return r;
}

ILL_Item_Id *ill_get_Item_Id (
    struct ill_get_ctl *gc, const char *name, const char *sub)   
{
    ODR o = gc->odr;
    ILL_Item_Id *r = (ILL_Item_Id *) odr_malloc (o, sizeof(*r));
    char element[128];
    
    strcpy(element, name);
    if (sub)
    {
        strcat (element, ",");
        strcat (element, sub);
    }
    r->item_type = ill_get_enumerated (gc, element, "item-type",
                                       ILL_Item_Id_monograph);
    r->held_medium_type = 0;
    r->call_number = ill_get_ILL_String(gc, element, "call-number");
    r->author = ill_get_ILL_String(gc, element, "author");
    r->title = ill_get_ILL_String(gc, element, "title");
    r->sub_title = ill_get_ILL_String(gc, element, "sub-title");
    r->sponsoring_body = ill_get_ILL_String(gc, element, "sponsoring-body");
    r->place_of_publication =
        ill_get_ILL_String(gc, element, "place-of-publication");
    r->publisher = ill_get_ILL_String(gc, element, "publisher");
    r->series_title_number =
        ill_get_ILL_String(gc, element, "series-title-number");
    r->volume_issue = ill_get_ILL_String(gc, element, "volume-issue");
    r->edition = ill_get_ILL_String(gc, element, "edition");
    r->publication_date = ill_get_ILL_String(gc, element, "publication-date");
    r->publication_date_of_component =
        ill_get_ILL_String(gc, element, "publication-date-of-component");
    r->author_of_article = ill_get_ILL_String(gc, element,
                                              "author-of-article");
    r->title_of_article = ill_get_ILL_String(gc, element, "title-of-article");
    r->pagination = ill_get_ILL_String(gc, element, "pagination");
    r->national_bibliography_no = 0;
    r->iSBN = ill_get_ILL_String(gc, element, "ISBN");
    r->iSSN = ill_get_ILL_String(gc, element, "ISSN");
    r->system_no = 0;
    r->additional_no_letters =
        ill_get_ILL_String(gc, element, "additional-no-letters");
    r->verification_reference_source = 
        ill_get_ILL_String(gc, element, "verification-reference-source");
    return r;
}


ILL_Client_Id *ill_get_Client_Id (
    struct ill_get_ctl *gc, const char *name, const char *sub)
{
    char element[128];
    ODR o = gc->odr;
    ILL_Client_Id *r = (ILL_Client_Id *) odr_malloc(o, sizeof(*r));

    strcpy(element, name);
    if (sub)
    {
        strcat (element, ",");
        strcat (element, sub);
    }
    r->client_name = ill_get_ILL_String (gc, element, "client-name");
    r->client_status = ill_get_ILL_String (gc, element, "client-status");
    r->client_identifier = ill_get_ILL_String (gc, element,
                                               "client-identifier");
    return r;
}

ILL_Postal_Address *ill_get_Postal_Address (
    struct ill_get_ctl *gc, const char *name, const char *sub)
{
    ODR o = gc->odr;
    ILL_Postal_Address *r =
        (ILL_Postal_Address *) odr_malloc(o, sizeof(*r));
    char element[128];

    strcpy(element, name);
    if (sub)
    {
        strcat (element, ",");
        strcat (element, sub);
    }
    r->name_of_person_or_institution = 
        ill_get_Name_Of_Person_Or_Institution (
            gc, element, "name-of-person-or-institution");
    r->extended_postal_delivery_address =
        ill_get_ILL_String (
            gc, element, "extended-postal-delivery-address");
    r->street_and_number =
        ill_get_ILL_String (gc, element, "street-and-number");
    r->post_office_box =
        ill_get_ILL_String (gc, element, "post-office-box");
    r->city = ill_get_ILL_String (gc, element, "city");
    r->region = ill_get_ILL_String (gc, element, "region");
    r->country = ill_get_ILL_String (gc, element, "country");
    r->postal_code = ill_get_ILL_String (gc, element, "postal-code");
    return r;
}

ILL_System_Address *ill_get_System_Address (
    struct ill_get_ctl *gc, const char *name, const char *sub)
{
    ODR o = gc->odr;
    ILL_System_Address *r =
        (ILL_System_Address *) odr_malloc(o, sizeof(*r));
    char element[128];
    
    strcpy(element, name);
    if (sub)
    {
        strcat (element, ",");
        strcat (element, sub);
    }
    r->telecom_service_identifier =
        ill_get_ILL_String (gc, element, "telecom-service-identifier");
    r->telecom_service_address =
        ill_get_ILL_String (gc, element, "telecom-service-addreess");
    return r;
}

ILL_Delivery_Address *ill_get_Delivery_Address (
    struct ill_get_ctl *gc, const char *name, const char *sub)
{
    ODR o = gc->odr;
    ILL_Delivery_Address *r =
        (ILL_Delivery_Address *) odr_malloc(o, sizeof(*r));
    char element[128];
    
    strcpy(element, name);
    if (sub)
    {
        strcat (element, ",");
        strcat (element, sub);
    }
    r->postal_address =
        ill_get_Postal_Address (gc, element, "postal-address");
    r->electronic_address =
        ill_get_System_Address (gc, element, "electronic-address");
    return r;
}

ILL_Search_Type *ill_get_Search_Type (
    struct ill_get_ctl *gc, const char *name, const char *sub)
{
    ODR o = gc->odr;
    ILL_Search_Type *r = (ILL_Search_Type *) odr_malloc(o, sizeof(*r));
    char element[128];
    
    strcpy(element, name);
    if (sub)
    {
        strcat (element, ",");
        strcat (element, sub);
    }
    r->level_of_service = ill_get_ILL_String (gc, element, "level-of-service");
    r->need_before_date = ill_get_ILL_ISO_Date (gc, element,
                                                "need-before-date", 0);
    r->expiry_date = ill_get_ILL_ISO_Date (gc, element, "expiry-date", 0);
    r->expiry_flag = ill_get_enumerated (gc, element, "expiry-flag", 3);
                                         
    return r;
}

ILL_Request *ill_get_ILLRequest (
    struct ill_get_ctl *gc, const char *name, const char *sub)
{
    ODR o = gc->odr;
    ILL_Request *r = (ILL_Request *) odr_malloc(o, sizeof(*r));
    char element[128];
    
    strcpy(element, name);
    if (sub)
    {
        strcat (element, ",");
        strcat (element, sub);
    }
    r->protocol_version_num =
        ill_get_enumerated (gc, element, "protocol-version-num", 
                            ILL_Request_version_2);
    
    r->transaction_id = ill_get_Transaction_Id (gc, element, "transaction-id");
    r->service_date_time =
        ill_get_Service_Date_Time (gc, element, "service-date-time");
    r->requester_id = ill_get_System_Id (gc, element, "requester-id");
    r->responder_id = ill_get_System_Id (gc, element, "responder-id");
    r->transaction_type =
        ill_get_enumerated(gc, element, "transaction-type", 1);

    r->delivery_address =
        ill_get_Delivery_Address (gc, element, "delivery-address");
    r->delivery_service = 0; /* TODO */
    /* ill_get_Delivery_Service (gc, element, "delivery-service"); */
    r->billing_address =
        ill_get_Delivery_Address (gc, element, "billing-address");

    r->num_iLL_service_type = 1;
    r->iLL_service_type = (ILL_Service_Type **)
        odr_malloc (o, sizeof(*r->iLL_service_type));
    *r->iLL_service_type =
        ill_get_enumerated (gc, element, "ill-service-type",
                            ILL_Service_Type_copy_non_returnable);

    r->responder_specific_service = 0;
    r->requester_optional_messages =
        ill_get_Requester_Optional_Messages_Type (
            gc, element,"requester-optional-messages");
    r->search_type = ill_get_Search_Type(gc, element, "search-type");
    r->num_supply_medium_info_type = 0;
    r->supply_medium_info_type = 0;

    r->place_on_hold = ill_get_enumerated (
        gc, element, "place-on-hold", 
        ILL_Place_On_Hold_Type_according_to_responder_policy);
    r->client_id = ill_get_Client_Id (gc, element, "client-id");
                           
    r->item_id = ill_get_Item_Id (gc, element, "item-id");
    r->supplemental_item_description = 0;
    r->cost_info_type = 0;
    r->copyright_compliance =
        ill_get_ILL_String(gc, element, "copyright-complicance");
    r->third_party_info_type = 0;
    r->retry_flag = ill_get_bool (gc, element, "retry-flag", 0);
    r->forward_flag = ill_get_bool (gc, element, "forward-flag", 0);
    r->requester_note = ill_get_ILL_String(gc, element, "requester-note");
    r->forward_note = ill_get_ILL_String(gc, element, "forward-note");
    r->num_iLL_request_extensions = 0;
    r->iLL_request_extensions = 0;
    return r;
}

ILL_ItemRequest *ill_get_ItemRequest (
    struct ill_get_ctl *gc, const char *name, const char *sub)
{
    ODR o = gc->odr;
    ILL_ItemRequest *r = (ILL_ItemRequest *)odr_malloc(o, sizeof(*r));
    char element[128];
    
    strcpy(element, name);
    if (sub)
    {
        strcat (element, ",");
        strcat (element, sub);
    }
    r->protocol_version_num =
        ill_get_enumerated (gc, element, "protocol-version-num", 
                            ILL_Request_version_2);
    
    r->transaction_id = ill_get_Transaction_Id (gc, element, "transaction-id");
    r->service_date_time =
        ill_get_Service_Date_Time (gc, element, "service-date-time");
    r->requester_id = ill_get_System_Id (gc, element, "requester-id");
    r->responder_id = ill_get_System_Id (gc, element, "responder-id");
    r->transaction_type =
        ill_get_enumerated(gc, element, "transaction-type", 1);

    r->delivery_address =
        ill_get_Delivery_Address (gc, element, "delivery-address");
    r->delivery_service = 0; /* TODO */
    /* ill_get_Delivery_Service (gc, element, "delivery-service"); */
    r->billing_address =
        ill_get_Delivery_Address (gc, element, "billing-address");

    r->num_iLL_service_type = 1;
    r->iLL_service_type = (ILL_Service_Type **)
        odr_malloc (o, sizeof(*r->iLL_service_type));
    *r->iLL_service_type =
        ill_get_enumerated (gc, element, "ill-service-type",
                            ILL_Service_Type_copy_non_returnable);

    r->responder_specific_service = 0;
    r->requester_optional_messages =
        ill_get_Requester_Optional_Messages_Type (
            gc, element,"requester-optional-messages");
    r->search_type = ill_get_Search_Type(gc, element, "search-type");
    r->num_supply_medium_info_type = 0;
    r->supply_medium_info_type = 0;

    r->place_on_hold = ill_get_enumerated (
        gc, element, "place-on-hold", 
        ILL_Place_On_Hold_Type_according_to_responder_policy);
    r->client_id = ill_get_Client_Id (gc, element, "client-id");
                           
    r->item_id = ill_get_Item_Id (gc, element, "item-id");
    r->supplemental_item_description = 0;
    r->cost_info_type = 0;
    r->copyright_compliance =
        ill_get_ILL_String(gc, element, "copyright-complicance");
    r->third_party_info_type = 0;
    r->retry_flag = ill_get_bool (gc, element, "retry-flag", 0);
    r->forward_flag = ill_get_bool (gc, element, "forward-flag", 0);
    r->requester_note = ill_get_ILL_String(gc, element, "requester-note");
    r->forward_note = ill_get_ILL_String(gc, element, "forward-note");
    r->num_iLL_request_extensions = 0;
    r->iLL_request_extensions = 0;
    return r;
}

ILL_Cancel *ill_get_Cancel (
    struct ill_get_ctl *gc, const char *name, const char *sub)
{
    ODR o = gc->odr;
    ILL_Cancel *r = (ILL_Cancel *)odr_malloc(o, sizeof(*r));
    char element[128];
    
    strcpy(element, name);
    if (sub)
    {
        strcat (element, ",");
        strcat (element, sub);
    }
    r->protocol_version_num =
        ill_get_enumerated (gc, element, "protocol-version-num", 
                            ILL_Request_version_2);
    
    r->transaction_id = ill_get_Transaction_Id (gc, element, "transaction-id");
    r->service_date_time =
        ill_get_Service_Date_Time (gc, element, "service-date-time");
    r->requester_id = ill_get_System_Id (gc, element, "requester-id");
    r->responder_id = ill_get_System_Id (gc, element, "responder-id");
    r->requester_note = ill_get_ILL_String(gc, element, "requester-note");

    r->num_cancel_extensions = 0;
    r->cancel_extensions = 0;
    return r;
}

ILL_APDU *ill_get_APDU (
    struct ill_get_ctl *gc, const char *name, const char *sub)
{
    ODR o = gc->odr;
    ILL_APDU *r = (ILL_APDU *)odr_malloc(o, sizeof(*r));
    char element[128];
    const char *v;

    strcpy (element, name);
    strcat (element, ",which");

    v = (gc->f)(gc->clientData, element);
    if (!v)
        v = "request";
    if (!strcmp (v, "request"))
    {
        r->which = ILL_APDU_ILL_Request;
        r->u.illRequest = ill_get_ILLRequest(gc, name, sub);
    }
    else if (!strcmp (v, "cancel"))
    {
        r->which = ILL_APDU_Cancel;
        r->u.Cancel = ill_get_Cancel(gc, name, sub);
    }
    else
        return 0;
    return r;
}
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

