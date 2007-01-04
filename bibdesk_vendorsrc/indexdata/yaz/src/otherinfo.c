/*
 * Copyright (C) 1995-2005, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: otherinfo.c,v 1.5 2006/01/16 15:53:28 adam Exp $
 */
/**
 * \file otherinfo.c
 * \brief Implements Z39.50 OtherInfo utilities
 */
#include <stdio.h>
#include <string.h>

#include <yaz/otherinfo.h>

void yaz_oi_APDU(Z_APDU *apdu, Z_OtherInformation ***oip)
{
    switch (apdu->which)
    {
    case Z_APDU_initRequest:
        *oip = &apdu->u.initRequest->otherInfo;
        break;
    case Z_APDU_searchRequest:
        *oip = &apdu->u.searchRequest->otherInfo;
        break;
    case Z_APDU_presentRequest:
        *oip = &apdu->u.presentRequest->otherInfo;
        break;
    case Z_APDU_sortRequest:
        *oip = &apdu->u.sortRequest->otherInfo;
        break;
    case Z_APDU_scanRequest:
        *oip = &apdu->u.scanRequest->otherInfo;
        break;
    case Z_APDU_extendedServicesRequest:
        *oip = &apdu->u.extendedServicesRequest->otherInfo;
        break;
    case Z_APDU_deleteResultSetRequest:
        *oip = &apdu->u.deleteResultSetRequest->otherInfo;
        break;
    case Z_APDU_initResponse:
        *oip = &apdu->u.initResponse->otherInfo;
        break;
    case Z_APDU_searchResponse:
        *oip = &apdu->u.searchResponse->otherInfo;
        break;
    case Z_APDU_presentResponse:
        *oip = &apdu->u.presentResponse->otherInfo;
        break;
    case Z_APDU_sortResponse:
        *oip = &apdu->u.sortResponse->otherInfo;
        break;
    case Z_APDU_scanResponse:
        *oip = &apdu->u.scanResponse->otherInfo;
        break;
    case Z_APDU_extendedServicesResponse:
        *oip = &apdu->u.extendedServicesResponse->otherInfo;
        break;
    case Z_APDU_deleteResultSetResponse:
        *oip = &apdu->u.deleteResultSetResponse->otherInfo;
        break;
    case Z_APDU_duplicateDetectionRequest:
        *oip = &apdu->u.duplicateDetectionRequest->otherInfo;
        break;
    case Z_APDU_duplicateDetectionResponse:
        *oip = &apdu->u.duplicateDetectionResponse->otherInfo;
        break;
    default:
        *oip = 0;
        break;
    }
}

Z_OtherInformationUnit *yaz_oi_update (
    Z_OtherInformation **otherInformationP, ODR odr,
    int *oid, int categoryValue, int delete_flag)
{
    int i;
    Z_OtherInformation *otherInformation;

    if (!otherInformationP)
        return 0;
    otherInformation = *otherInformationP;
    if (!otherInformation)
    {
        if (!odr)
            return 0;
        otherInformation = *otherInformationP = (Z_OtherInformation *)
            odr_malloc (odr, sizeof(*otherInformation));
        otherInformation->num_elements = 0;
        otherInformation->list = 0;
    }
    for (i = 0; i<otherInformation->num_elements; i++)
    {
        if (!oid)
        {
            if (!otherInformation->list[i]->category)
                return otherInformation->list[i];
        }
        else
        {
            if (otherInformation->list[i]->category &&
                categoryValue ==
                *otherInformation->list[i]->category->categoryValue &&
                !oid_oidcmp (oid, otherInformation->list[i]->category->
                             categoryTypeId))
            {
                Z_OtherInformationUnit *this_list = otherInformation->list[i];

                if (delete_flag)
                {
                    (otherInformation->num_elements)--;
                    while (i < otherInformation->num_elements)
                    {
                        otherInformation->list[i] =
                            otherInformation->list[i+1];
                        i++;
                    }
                }
                return this_list;
            }
        }
    }
    if (!odr)
        return 0;
    else
    {
        Z_OtherInformationUnit **newlist = (Z_OtherInformationUnit**)
            odr_malloc(odr, (otherInformation->num_elements+1) *
                       sizeof(*newlist));
        for (i = 0; i<otherInformation->num_elements; i++)
            newlist[i] = otherInformation->list[i];
        otherInformation->list = newlist;
        
        otherInformation->list[i] = (Z_OtherInformationUnit*)
            odr_malloc (odr, sizeof(Z_OtherInformationUnit));
        if (oid)
        {
            otherInformation->list[i]->category = (Z_InfoCategory*)
                odr_malloc (odr, sizeof(Z_InfoCategory));
            otherInformation->list[i]->category->categoryTypeId = (int*)
                odr_oiddup (odr, oid);
            otherInformation->list[i]->category->categoryValue = (int*)
                odr_malloc (odr, sizeof(int));
            *otherInformation->list[i]->category->categoryValue =
                categoryValue;
        }
        else
            otherInformation->list[i]->category = 0;
        otherInformation->list[i]->which = Z_OtherInfo_characterInfo;
        otherInformation->list[i]->information.characterInfo = 0;
        
        otherInformation->num_elements = i+1;
        return otherInformation->list[i];
    }
}

void yaz_oi_set_string_oid (
    Z_OtherInformation **otherInformation, ODR odr,
    int *oid, int categoryValue,
    const char *str)
{
    Z_OtherInformationUnit *oi =
        yaz_oi_update(otherInformation, odr, oid, categoryValue, 0);
    if (!oi)
        return;
    oi->which = Z_OtherInfo_characterInfo;
    oi->information.characterInfo = odr_strdup (odr, str);
}

void yaz_oi_set_string_oidval (
    Z_OtherInformation **otherInformation, ODR odr,
    int oidval, int categoryValue,
    const char *str)
{
    int oid[OID_SIZE];
    struct oident ent;
    ent.proto = PROTO_Z3950;
    ent.oclass = CLASS_USERINFO;
    ent.value = (oid_value) oidval;
    if (!oid_ent_to_oid (&ent, oid))
        return ;
    yaz_oi_set_string_oid(otherInformation,
                          odr, oid, categoryValue, str);
}

char *yaz_oi_get_string_oid (
    Z_OtherInformation **otherInformation,
    int *oid, int categoryValue, int delete_flag)
{
    Z_OtherInformationUnit *oi;
    
    if ((oi = yaz_oi_update(otherInformation, 0, oid, categoryValue,
                            delete_flag)) &&
        oi->which == Z_OtherInfo_characterInfo)
        return oi->information.characterInfo;
    return 0;
}

char *yaz_oi_get_string_oidval(Z_OtherInformation **otherInformation,
                               int oidval, int categoryValue, int delete_flag)
{
    int oid[OID_SIZE];
    struct oident ent;
    ent.proto = PROTO_Z3950;
    ent.oclass = CLASS_USERINFO;
    ent.value = (oid_value) oidval;

    if (!oid_ent_to_oid (&ent, oid))
        return 0;
    return yaz_oi_get_string_oid (otherInformation, oid, categoryValue,
                                  delete_flag);
}

/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

