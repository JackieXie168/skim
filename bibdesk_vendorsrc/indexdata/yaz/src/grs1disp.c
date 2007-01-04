/*
 * Copyright (C) 1995-2005, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: grs1disp.c,v 1.4 2005/06/25 15:46:04 adam Exp $
 */

/**
 * \file grs1disp.c
 * \brief Implements display of GRS-1 records
 */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#include <yaz/proto.h>

static void display_variant(WRBUF w, Z_Variant *v, int level)
{
    int i;

    for (i = 0; i < v->num_triples; i++)
    {
        printf("%*sclass=%d,type=%d", level * 4, "", *v->triples[i]->zclass,
            *v->triples[i]->type);
        if (v->triples[i]->which == Z_Triple_internationalString)
            printf(",value=%s\n", v->triples[i]->value.internationalString);
        else
            printf("\n");
    }
}

static void display_grs1(WRBUF w, Z_GenericRecord *r, int level)
{
    int i;

    if (!r)
    {
        return;
    }
    for (i = 0; i < r->num_elements; i++)
    {
        Z_TaggedElement *t;

        wrbuf_printf(w, "%*s", level * 4, "");
        t = r->elements[i];
        wrbuf_printf(w, "(");
        if (t->tagType)
            wrbuf_printf(w, "%d,", *t->tagType);
        else
            wrbuf_printf(w, "?,");
        if (t->tagValue->which == Z_StringOrNumeric_numeric)
            wrbuf_printf(w, "%d) ", *t->tagValue->u.numeric);
        else
            wrbuf_printf(w, "%s) ", t->tagValue->u.string);
        if (t->content->which == Z_ElementData_subtree)
        {
            if (!t->content->u.subtree)
                printf (" (no subtree)\n");
            else
            {
                wrbuf_printf(w, "\n");
                display_grs1(w, t->content->u.subtree, level+1);
            }
        }
        else if (t->content->which == Z_ElementData_string)
            wrbuf_printf(w, "%s\n", t->content->u.string);
        else if (t->content->which == Z_ElementData_numeric)
            wrbuf_printf(w, "%d\n", *t->content->u.numeric);
        else if (t->content->which == Z_ElementData_oid)
        {
            int *ip = t->content->u.oid;
            oident *oent;
            
            if ((oent = oid_getentbyoid(t->content->u.oid)))
                wrbuf_printf(w, "OID: %s\n", oent->desc);
            else
            {
                wrbuf_printf(w, "{");
                while (ip && *ip >= 0)
                    wrbuf_printf(w, " %d", *(ip++));
                wrbuf_printf(w, " }\n");
            }
        }
        else if (t->content->which == Z_ElementData_noDataRequested)
            wrbuf_printf(w, "[No data requested]\n");
        else if (t->content->which == Z_ElementData_elementEmpty)
            wrbuf_printf(w, "[Element empty]\n");
        else if (t->content->which == Z_ElementData_elementNotThere)
            wrbuf_printf(w, "[Element not there]\n");
        else if (t->content->which == Z_ElementData_date)
            wrbuf_printf(w, "Date: %s\n", t->content->u.date);
        else if (t->content->which == Z_ElementData_ext)
        {
            printf ("External\n");
            /* we cannot print externals here. Srry */
        } 
        else
            wrbuf_printf(w, "? type = %d\n",t->content->which);
        if (t->appliedVariant)
            display_variant(w, t->appliedVariant, level+1);
        if (t->metaData && t->metaData->supportedVariants)
        {
            int c;

            wrbuf_printf(w, "%*s---- variant list\n", (level+1)*4, "");
            for (c = 0; c < t->metaData->num_supportedVariants; c++)
            {
                wrbuf_printf(w, "%*svariant #%d\n", (level+1)*4, "", c);
                display_variant(w, t->metaData->supportedVariants[c], level+2);
            }
        }
    }
}

void yaz_display_grs1(WRBUF wrbuf, Z_GenericRecord *r, int flags)
{
    display_grs1 (wrbuf, r, 0);
}

/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

