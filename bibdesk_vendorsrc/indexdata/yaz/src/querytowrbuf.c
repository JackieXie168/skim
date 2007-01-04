/*
 * Copyright (C) 1995-2005, Index Data ApS
 * All rights reserved.
 *
 * $Id: querytowrbuf.c,v 1.5 2006/07/07 12:09:05 marc Exp $
 */

/** \file querytowrbuf.c
    \brief Query to WRBUF (to strings)
 */

#include <stdio.h>
#include <assert.h>

#include <yaz/logrpn.h>
#include <yaz/querytowrbuf.h>

static void yaz_term_to_wrbuf(WRBUF b, const char *term, int len)
{
    int i;
    for (i = 0; i < len; i++)
        if (strchr(" \"{", term[i]))
            break;
    if (i == len && i)
        wrbuf_printf(b, "%.*s ", len, term);
    else
    {
        wrbuf_putc(b, '"');
        for (i = 0; i<len; i++)
        {
            if (term[i] == '"')
                wrbuf_putc(b, '\\');
            wrbuf_putc(b, term[i]);
        }
        wrbuf_printf(b, "\" ");
    }
}

static void yaz_attribute_element_to_wrbuf(WRBUF b,
                                           const Z_AttributeElement *element)
{
    int i;
    char *setname="";
    char *sep = ""; /* optional space after attrset name */
    if (element->attributeSet)
    {
        oident *attrset;
        attrset = oid_getentbyoid (element->attributeSet);
        setname = attrset->desc;
        sep = " ";
    }
    switch (element->which) 
    {
    case Z_AttributeValue_numeric:
        wrbuf_printf(b,"@attr %s%s%d=%d ", setname, sep,
                     *element->attributeType, *element->value.numeric);
        break;
    case Z_AttributeValue_complex:
        wrbuf_printf(b,"@attr %s%s\"%d=", setname, sep,
                     *element->attributeType);
        for (i = 0; i<element->value.complex->num_list; i++)
        {
            if (i)
                wrbuf_printf(b,",");
            if (element->value.complex->list[i]->which ==
                Z_StringOrNumeric_string)
                wrbuf_printf (b, "%s",
                              element->value.complex->list[i]->u.string);
            else if (element->value.complex->list[i]->which ==
                     Z_StringOrNumeric_numeric)
                wrbuf_printf (b, "%d", 
                              *element->value.complex->list[i]->u.numeric);
        }
        wrbuf_printf(b, "\" ");
        break;
    default:
        wrbuf_printf (b, "@attr 1=unknown ");
    }
}

static const char *complex_op_name(const Z_Operator *op)
{
    switch (op->which)
    {
    case Z_Operator_and:
        return "and";
    case Z_Operator_or:
        return "or";
    case Z_Operator_and_not:
        return "not";
    case Z_Operator_prox:
        return "prox";
    default:
        return "unknown complex operator";
    }
}

static void yaz_apt_to_wrbuf(WRBUF b, const Z_AttributesPlusTerm *zapt)
{
    int num_attributes = zapt->attributes->num_attributes;
    int i;
    for (i = 0; i<num_attributes; i++)
        yaz_attribute_element_to_wrbuf(b,zapt->attributes->attributes[i]);
    
    switch (zapt->term->which)
    {
    case Z_Term_general:
        yaz_term_to_wrbuf(b, (const char *)zapt->term->u.general->buf,
                          zapt->term->u.general->len);
        break;
    case Z_Term_characterString:
        wrbuf_printf(b, "@term string ");
        yaz_term_to_wrbuf(b, zapt->term->u.characterString,
                          strlen(zapt->term->u.characterString));
        break;
    case Z_Term_numeric:
        wrbuf_printf(b, "@term numeric %d ", *zapt->term->u.numeric);
        break;
    case Z_Term_null:
        wrbuf_printf(b, "@term null x");
        break;
    default:
        wrbuf_printf(b, "@term null unknown%d ", zapt->term->which);
    }
}

static void yaz_rpnstructure_to_wrbuf(WRBUF b, const Z_RPNStructure *zs)
{
    if (zs->which == Z_RPNStructure_complex)
    {
        Z_Operator *op = zs->u.complex->roperator;
        wrbuf_printf(b, "@%s ", complex_op_name(op) );
        if (op->which== Z_Operator_prox)
        {
            if (!op->u.prox->exclusion)
                wrbuf_putc(b, 'n');
            else if (*op->u.prox->exclusion)
                wrbuf_putc(b, '1');
            else
                wrbuf_putc(b, '0');

            wrbuf_printf(b, " %d %d %d ", *op->u.prox->distance,
                         *op->u.prox->ordered,
                         *op->u.prox->relationType);

            switch(op->u.prox->which)
            {
            case Z_ProximityOperator_known:
                wrbuf_putc(b, 'k');
                break;
            case Z_ProximityOperator_private:
                wrbuf_putc(b, 'p');
                break;
            default:
                wrbuf_printf(b, "%d", op->u.prox->which);
            }
            if (op->u.prox->u.known)
                wrbuf_printf(b, " %d ", *op->u.prox->u.known);
            else
                wrbuf_printf(b, " 0 ");
        }
        yaz_rpnstructure_to_wrbuf(b,zs->u.complex->s1);
        yaz_rpnstructure_to_wrbuf(b,zs->u.complex->s2);
    }
    else if (zs->which == Z_RPNStructure_simple)
    {
        if (zs->u.simple->which == Z_Operand_APT)
            yaz_apt_to_wrbuf(b, zs->u.simple->u.attributesPlusTerm);
        else if (zs->u.simple->which == Z_Operand_resultSetId)
        {
            wrbuf_printf(b, "@set ");
            yaz_term_to_wrbuf(b, zs->u.simple->u.resultSetId,
                              strlen(zs->u.simple->u.resultSetId));
        }
        else
            wrbuf_printf (b, "(unknown simple structure)");
    }
    else
        wrbuf_puts(b, "(unknown structure)");
}

void yaz_rpnquery_to_wrbuf(WRBUF b, const Z_RPNQuery *rpn)
{
    oident *attrset;
    enum oid_value ast;
    
    attrset = oid_getentbyoid (rpn->attributeSetId);
    if (attrset)
    {
        ast = attrset->value;
        wrbuf_printf(b, "@attrset %s ", attrset->desc);
    } 
    yaz_rpnstructure_to_wrbuf(b, rpn->RPNStructure);
    wrbuf_chop_right(b);
}

void yaz_query_to_wrbuf(WRBUF b, const Z_Query *q)
{
    assert(q);
    assert(b);
    switch (q->which)
    {
    case Z_Query_type_1: 
    case Z_Query_type_101:
        wrbuf_printf(b,"RPN ");
        yaz_rpnquery_to_wrbuf(b, q->u.type_1);
        break;
    case Z_Query_type_2:
        wrbuf_printf(b, "CCL %.*s", q->u.type_2->len, q->u.type_2->buf);
        break;
    case Z_Query_type_100:
        wrbuf_printf(b, "Z39.58 %.*s", q->u.type_100->len,
                     q->u.type_100->buf);
        break;
    case Z_Query_type_104:
        if (q->u.type_104->which == Z_External_CQL)
            wrbuf_printf(b, "CQL %s", q->u.type_104->u.cql);
        else
            wrbuf_printf(b,"UNKNOWN type 104 query %d", q->u.type_104->which);
    }
}

void yaz_scan_to_wrbuf(WRBUF b, const Z_AttributesPlusTerm *zapt,
                       oid_value ast)
{
    /* should print attr set here */
    wrbuf_printf(b, "RPN ");
    yaz_apt_to_wrbuf(b, zapt);
}

/* obsolete */
void wrbuf_scan_term(WRBUF b, const Z_AttributesPlusTerm *zapt, oid_value ast)
{
    yaz_apt_to_wrbuf(b, zapt);
}

/* obsolete */
void wrbuf_put_zquery(WRBUF b, const Z_Query *q)
{
    yaz_query_to_wrbuf(b, q);
}


/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

