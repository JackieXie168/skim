/*
 * Copyright (C) 1995-2006, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: z3950oid.c,v 1.5 2006/04/20 20:50:51 adam Exp $
 */

/** \file z3950oid.c
    \brief Z3950 OID conversion utilities
*/

#if HAVE_CONFIG_H
#include <config.h>
#endif

#include "proto.h"

Odr_oid *yaz_oidval_to_z3950oid (ODR o, int oid_class, int oid_value)
{
    oident ident;
    int oid[OID_SIZE];

    ident.proto = PROTO_Z3950;
    ident.oclass = (enum oid_class) oid_class;
    ident.value = (enum oid_value) oid_value;

    if (ident.value == VAL_NONE)
        return 0;

    return odr_oiddup(o, oid_ent_to_oid(&ident, oid));
}

Odr_oid *yaz_str_to_z3950oid (ODR o, int oid_class, const char *str)
{
    struct oident ident;
    int oid[OID_SIZE];

    ident.proto = PROTO_Z3950;
    ident.oclass = (enum oid_class) oid_class;
    ident.value = oid_getvalbyname(str);

    if (ident.value == VAL_NONE)
        return 0;

    return odr_oiddup(o, oid_ent_to_oid(&ident, oid));
}

const char *yaz_z3950oid_to_str (Odr_oid *oid, int *oid_class)
{
    struct oident *ident = oid_getentbyoid(oid);

    if (!ident || ident->value == VAL_NONE)
        return 0;
    *oid_class = ident->oclass;
    return ident->desc;
}


const char* yaz_z3950_oid_value_to_str(oid_value ov, oid_class oc)
{
    struct oident tmpentry;
    int tmp_oid[OID_SIZE];
     
    tmpentry.proto = PROTO_Z3950;
    tmpentry.oclass = oc;
    tmpentry.value = ov; 
    
    if( oid_ent_to_oid(&tmpentry,tmp_oid) ) 
    {
        return tmpentry.desc;
    } 
    else 
    {
        return "";
    }
}
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

