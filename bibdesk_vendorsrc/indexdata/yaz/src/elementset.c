/*
 * Copyright (C) 1995-2006, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: elementset.c,v 1.2 2006/12/13 11:25:17 adam Exp $
 */
/**
 * \file elementset.c
 * \brief Z39.50 element set utilities
 */

#if HAVE_CONFIG_H
#include <config.h>
#endif

#include <yaz/proto.h>

const char *yaz_get_esn(Z_RecordComposition *comp)
{
    if (comp && comp->which == Z_RecordComp_complex)
    {
        if (comp->u.complex->generic
            && comp->u.complex->generic->elementSpec
            && (comp->u.complex->generic->elementSpec->which ==
                Z_ElementSpec_elementSetName))
            return comp->u.complex->generic->elementSpec->u.elementSetName;
    }
    else if (comp && comp->which == Z_RecordComp_simple &&
             comp->u.simple->which == Z_ElementSetNames_generic)
        return comp->u.simple->u.generic;
    return 0;
}

void yaz_set_esn(Z_RecordComposition **comp_p, const char *esn, NMEM nmem)
{
    Z_RecordComposition *comp = nmem_malloc(nmem, sizeof(*comp));
    
    comp->which = Z_RecordComp_simple;
    comp->u.simple = nmem_malloc(nmem, sizeof(*comp->u.simple));
    comp->u.simple->which = Z_ElementSetNames_generic;
    comp->u.simple->u.generic = nmem_strdup(nmem, esn);
    *comp_p = comp;
}



/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

