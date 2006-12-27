/*
 * Copyright (C) 1995-2006, Index Data ApS
 * All rights reserved.
 *
 * $Id: xmlquery.c,v 1.11 2006/10/27 12:19:15 adam Exp $
 */

/** \file xmlquery.c
    \brief Query / XML conversions
*/

#include <stdio.h>
#include <string.h>
#include <assert.h>

#if YAZ_HAVE_XML2
#include <libxml/parser.h>
#include <libxml/tree.h>

#include "logrpn.h"
#include "xmlquery.h"
#include <yaz/nmem_xml.h>

void yaz_query2xml_attribute_element(const Z_AttributeElement *element,
                                     xmlNodePtr parent)
{
    char formstr[30];
    const char *setname = 0;
    
    if (element->attributeSet)
    {
        oident *attrset;
        attrset = oid_getentbyoid (element->attributeSet);
        setname = attrset->desc;
    }

    if (element->which == Z_AttributeValue_numeric)
    {
        xmlNodePtr node = xmlNewChild(parent, 0, BAD_CAST "attr", 0);

        if (setname)
            xmlNewProp(node, BAD_CAST "set", BAD_CAST setname);

        sprintf(formstr, "%d", *element->attributeType);
        xmlNewProp(node, BAD_CAST "type", BAD_CAST formstr);

        sprintf(formstr, "%d", *element->value.numeric);
        xmlNewProp(node, BAD_CAST "value", BAD_CAST formstr);
    }
    else if (element->which == Z_AttributeValue_complex)
    {
        int i;
        for (i = 0; i<element->value.complex->num_list; i++)
        {
            xmlNodePtr node = xmlNewChild(parent, 0, BAD_CAST "attr", 0);
            
            if (setname)
                xmlNewProp(node, BAD_CAST "set", BAD_CAST setname);
            
            sprintf(formstr, "%d", *element->attributeType);
            xmlNewProp(node, BAD_CAST "type", BAD_CAST formstr);
            
            if (element->value.complex->list[i]->which ==
                Z_StringOrNumeric_string)
            {
                xmlNewProp(node, BAD_CAST "value", BAD_CAST 
                           element->value.complex->list[i]->u.string);
            }
            else if (element->value.complex->list[i]->which ==
                     Z_StringOrNumeric_numeric)
            {
                sprintf(formstr, "%d",
                        *element->value.complex->list[i]->u.numeric);
                xmlNewProp(node, BAD_CAST "value", BAD_CAST formstr);
            }
        }
    }
}


xmlNodePtr yaz_query2xml_term(const Z_Term *term,
			      xmlNodePtr parent)
{
    xmlNodePtr t = 0;
    xmlNodePtr node = xmlNewChild(parent, /* NS */ 0, BAD_CAST "term", 0);
    char formstr[20];
    const char *type = 0;

    switch (term->which)
    {
    case Z_Term_general:
        type = "general";
	t = xmlNewTextLen(BAD_CAST term->u.general->buf, term->u.general->len);
        break;
    case Z_Term_numeric:
        type = "numeric";
	sprintf(formstr, "%d", *term->u.numeric);
	t = xmlNewText(BAD_CAST formstr);	
        break;
    case Z_Term_characterString:
        type = "string";
	t = xmlNewText(BAD_CAST term->u.characterString);
        break;
    case Z_Term_oid:
        type = "oid";
        break;
    case Z_Term_dateTime:
        type = "dateTime";
        break;
    case Z_Term_external:
        type = "external";
        break;
    case Z_Term_integerAndUnit:
        type ="integerAndUnit";
        break;
    case Z_Term_null:
        type = "null";
        break;
    default:
	break;
    }
    if (t) /* got a term node ? */
	xmlAddChild(node, t);
    if (type)
        xmlNewProp(node, BAD_CAST "type", BAD_CAST type);
    return node;
}

xmlNodePtr yaz_query2xml_apt(const Z_AttributesPlusTerm *zapt,
			     xmlNodePtr parent)
{
    xmlNodePtr node = xmlNewChild(parent, /* NS */ 0, BAD_CAST "apt", 0);
    int num_attributes = zapt->attributes->num_attributes;
    int i;
    for (i = 0; i<num_attributes; i++)
        yaz_query2xml_attribute_element(zapt->attributes->attributes[i], node);
    yaz_query2xml_term(zapt->term, node);

    return node;
}


void yaz_query2xml_operator(Z_Operator *op, xmlNodePtr node)
{
    const char *type = 0;
    switch(op->which)
    {
    case Z_Operator_and:
        type = "and";
        break;
    case Z_Operator_or:
        type = "or";
        break;
    case Z_Operator_and_not:
        type = "not";
        break;
    case Z_Operator_prox:
        type = "prox";
        break;
    default:
        return;
    }
    xmlNewProp(node, BAD_CAST "type", BAD_CAST type);
    
    if (op->which == Z_Operator_prox)
    {
        char formstr[30];
        
        if (op->u.prox->exclusion)
        {
            if (*op->u.prox->exclusion)
                xmlNewProp(node, BAD_CAST "exclusion", BAD_CAST "true");
            else
                xmlNewProp(node, BAD_CAST "exclusion", BAD_CAST "false");
        }
        sprintf(formstr, "%d", *op->u.prox->distance);
        xmlNewProp(node, BAD_CAST "distance", BAD_CAST formstr);

        if (*op->u.prox->ordered)
            xmlNewProp(node, BAD_CAST "ordered", BAD_CAST "true");
        else 
            xmlNewProp(node, BAD_CAST "ordered", BAD_CAST "false");
       
        sprintf(formstr, "%d", *op->u.prox->relationType);
        xmlNewProp(node, BAD_CAST "relationType", BAD_CAST formstr);
        
        switch(op->u.prox->which)
        {
        case Z_ProximityOperator_known:
            sprintf(formstr, "%d", *op->u.prox->u.known);
            xmlNewProp(node, BAD_CAST "knownProximityUnit",
                       BAD_CAST formstr);
            break;
        case Z_ProximityOperator_private:
        default:
            xmlNewProp(node, BAD_CAST "privateProximityUnit",
                       BAD_CAST "private");
            break;
        }
    }
}

xmlNodePtr yaz_query2xml_rpnstructure(const Z_RPNStructure *zs,
				      xmlNodePtr parent)
{
    if (zs->which == Z_RPNStructure_complex)
    {
        Z_Complex *zc = zs->u.complex;

        xmlNodePtr node = xmlNewChild(parent, /* NS */ 0, BAD_CAST "operator", 0);
        if (zc->roperator)
            yaz_query2xml_operator(zc->roperator, node);
        yaz_query2xml_rpnstructure(zc->s1, node);
        yaz_query2xml_rpnstructure(zc->s2, node);
        return node;
    }
    else if (zs->which == Z_RPNStructure_simple)
    {
        if (zs->u.simple->which == Z_Operand_APT)
            return yaz_query2xml_apt(zs->u.simple->u.attributesPlusTerm,
				     parent);
        else if (zs->u.simple->which == Z_Operand_resultSetId)
            return xmlNewChild(parent, /* NS */ 0, BAD_CAST "rset", 
                               BAD_CAST zs->u.simple->u.resultSetId);
    }
    return 0;
}

xmlNodePtr yaz_query2xml_rpn(const Z_RPNQuery *rpn, xmlNodePtr parent)
{
    oident *attrset = oid_getentbyoid (rpn->attributeSetId);
    if (attrset && attrset->value)
        xmlNewProp(parent, BAD_CAST "set", BAD_CAST attrset->desc);
    return yaz_query2xml_rpnstructure(rpn->RPNStructure, parent);
}

xmlNodePtr yaz_query2xml_ccl(const Odr_oct *ccl, xmlNodePtr node)
{
    return 0;
}

xmlNodePtr yaz_query2xml_z3958(const Odr_oct *ccl, xmlNodePtr node)
{
    return 0;
}

xmlNodePtr yaz_query2xml_cql(const char *cql, xmlNodePtr node)
{
    return 0;
}

void yaz_rpnquery2xml(const Z_RPNQuery *rpn, xmlDocPtr *docp)
{
    Z_Query query;

    query.which = Z_Query_type_1;
    query.u.type_1 = (Z_RPNQuery *) rpn;
    yaz_query2xml(&query, docp);
}

void yaz_query2xml(const Z_Query *q, xmlDocPtr *docp)
{
    xmlNodePtr top_node, q_node = 0, child_node = 0;

    assert(q);
    assert(docp);

    top_node = xmlNewNode(0, BAD_CAST "query");

    switch (q->which)
    {
    case Z_Query_type_1: 
    case Z_Query_type_101:
        q_node = xmlNewChild(top_node, 0, BAD_CAST "rpn", 0);
	child_node = yaz_query2xml_rpn(q->u.type_1, q_node);
        break;
    case Z_Query_type_2:
        q_node = xmlNewChild(top_node, 0, BAD_CAST "ccl", 0);
	child_node = yaz_query2xml_ccl(q->u.type_2, q_node);
        break;
    case Z_Query_type_100:
        q_node = xmlNewChild(top_node, 0, BAD_CAST "z39.58", 0);
	child_node = yaz_query2xml_z3958(q->u.type_100, q_node);
        break;
    case Z_Query_type_104:
        if (q->u.type_104->which == Z_External_CQL)
	{
            q_node = xmlNewChild(top_node, 0, BAD_CAST "cql", 0);
	    child_node = yaz_query2xml_cql(q->u.type_104->u.cql, q_node);
	}
    }
    if (child_node && q_node)
    {
	*docp = xmlNewDoc(BAD_CAST "1.0");
	xmlDocSetRootElement(*docp, top_node); /* make it top node in doc */
    }
    else
    {
	*docp = 0;
	xmlFreeNode(top_node);
    }
}

bool_t *boolVal(ODR odr, const char *str)
{
    if (*str == '\0' || strchr("0fF", *str))
        return odr_intdup(odr, 0);
    return odr_intdup(odr, 1);
}

int *intVal(ODR odr, const char *str)
{
    return odr_intdup(odr, atoi(str));
}

void yaz_xml2query_operator(const xmlNode *ptr, Z_Operator **op,
                            ODR odr, int *error_code, const char **addinfo)
{
    const char *type = (const char *)
        xmlGetProp((xmlNodePtr) ptr, BAD_CAST "type");
    if (!type)
    {
        *error_code = 1;
        *addinfo = "no operator type";
        return;
    }
    *op = (Z_Operator*) odr_malloc(odr, sizeof(Z_Operator));
    if (!strcmp(type, "and"))
    {
        (*op)->which = Z_Operator_and;
        (*op)->u.op_and = odr_nullval();
    }
    else if (!strcmp(type, "or"))
    {
        (*op)->which = Z_Operator_or;
        (*op)->u.op_or = odr_nullval();
    }
    else if (!strcmp(type, "not"))
    {
        (*op)->which = Z_Operator_and_not;
        (*op)->u.and_not = odr_nullval();
    }
    else if (!strcmp(type, "prox"))
    {
        const char *atval;
        Z_ProximityOperator *pop = (Z_ProximityOperator *) 
            odr_malloc(odr, sizeof(Z_ProximityOperator));

        (*op)->which = Z_Operator_prox;
        (*op)->u.prox = pop;

        atval = (const char *) xmlGetProp((xmlNodePtr) ptr,
                                          BAD_CAST "exclusion");
        if (atval)
            pop->exclusion = boolVal(odr, atval);
        else
            pop->exclusion = 0;

        atval = (const char *) xmlGetProp((xmlNodePtr) ptr,
                                          BAD_CAST "distance");
        if (atval)
            pop->distance = intVal(odr, atval);
        else
            pop->distance = odr_intdup(odr, 1);

        atval = (const char *) xmlGetProp((xmlNodePtr) ptr,
                                          BAD_CAST "ordered");
        if (atval)
            pop->ordered = boolVal(odr, atval);
        else
            pop->ordered = odr_intdup(odr, 1);

        atval = (const char *) xmlGetProp((xmlNodePtr) ptr,
                                          BAD_CAST "relationType");
        if (atval)
            pop->relationType = intVal(odr, atval);
        else
            pop->relationType =
                odr_intdup(odr, Z_ProximityOperator_Prox_lessThanOrEqual);

        atval = (const char *) xmlGetProp((xmlNodePtr) ptr,
                                          BAD_CAST "knownProximityUnit");
        if (atval)
        {
            pop->which = Z_ProximityOperator_known;            
            pop->u.known = intVal(odr, atval);
        }
        else
        {
            pop->which = Z_ProximityOperator_known;
            pop->u.known = odr_intdup(odr, Z_ProxUnit_word);
        }

        atval = (const char *) xmlGetProp((xmlNodePtr) ptr,
                                          BAD_CAST "privateProximityUnit");
        if (atval)
        {
            pop->which = Z_ProximityOperator_private;
            pop->u.zprivate = intVal(odr, atval);
        }
    }
    else
    {
        *error_code = 1;
        *addinfo = "bad operator type";
    }
}

void yaz_xml2query_attribute_element(const xmlNode *ptr, 
                                     Z_AttributeElement **elem, ODR odr,
                                     int *error_code, const char **addinfo)
{
    int i;
    xmlChar *set = 0;
    xmlChar *type = 0;
    xmlChar *value = 0;
    int num_values = 0;
    struct _xmlAttr *attr;
    for (attr = ptr->properties; attr; attr = attr->next)
    {
        if (!xmlStrcmp(attr->name, BAD_CAST "set") &&
            attr->children && attr->children->type == XML_TEXT_NODE)
            set = attr->children->content;
        else if (!xmlStrcmp(attr->name, BAD_CAST "type") &&
            attr->children && attr->children->type == XML_TEXT_NODE)
            type = attr->children->content;
        else if (!xmlStrcmp(attr->name, BAD_CAST "value") &&
            attr->children && attr->children->type == XML_TEXT_NODE)
        {
            value = attr->children->content;
            num_values++;
        }
        else
        {
            *error_code = 1;
            *addinfo = "bad attribute for attr content";
            return;
        }
    }
    if (!type)
    {
        *error_code = 1;
        *addinfo = "missing type attribute for att content";
        return;
    }
    if (!value)
    {
        *error_code = 1;
        *addinfo = "missing value attribute for att content";
        return;
    }
        
    *elem = (Z_AttributeElement *) odr_malloc(odr, sizeof(**elem));
    if (set)
        (*elem)->attributeSet = yaz_str_to_z3950oid(odr, CLASS_ATTSET,
                                                    (const char *)set);
    else
        (*elem)->attributeSet = 0;
    (*elem)->attributeType = intVal(odr, (const char *) type);

    /* looks like a number ? */
    for (i = 0; value[i] && value[i] >= '0' && value[i] <= '9'; i++)
        ;
    if (num_values > 1 || value[i])
    {   /* multiple values or string, so turn to complex attribute */
        (*elem)->which = Z_AttributeValue_complex;
        (*elem)->value.complex =
            (Z_ComplexAttribute*) odr_malloc(odr, sizeof(Z_ComplexAttribute));
        (*elem)->value.complex->num_list = num_values;
        (*elem)->value.complex->list = (Z_StringOrNumeric **)
            odr_malloc(odr, sizeof(Z_StringOrNumeric*) * num_values);

        /* second pass over attr values */
        i = 0;
        for (attr = ptr->properties; attr; attr = attr->next)
        {
            if (!xmlStrcmp(attr->name, BAD_CAST "value") &&
                attr->children && attr->children->type == XML_TEXT_NODE)
            {
                const char *val = (const char *) attr->children->content;
                assert (i < num_values);
                (*elem)->value.complex->list[i] = (Z_StringOrNumeric *)
                    odr_malloc(odr, sizeof(Z_StringOrNumeric));
                (*elem)->value.complex->list[i]->which =
                    Z_StringOrNumeric_string;
                (*elem)->value.complex->list[i]->u.string =
                    odr_strdup(odr, val);
                i++;
            }
        }
        (*elem)->value.complex->num_semanticAction = 0;
        (*elem)->value.complex->semanticAction = 0;        
    }
    else
    {   /* good'ld numeric value */
        (*elem)->which = Z_AttributeValue_numeric;
        (*elem)->value.numeric = intVal(odr, (const char *) value);
    }
}

char *strVal(const xmlNode *ptr_cdata, ODR odr)
{
    return nmem_text_node_cdata(ptr_cdata, odr->mem);
}

void yaz_xml2query_term(const xmlNode *ptr,
                       Z_Term **term, ODR odr,
                       int *error_code, const char **addinfo)
{
    xmlChar *type = 0;
    struct _xmlAttr *attr;
    char *cdata = strVal(ptr->children, odr);

    for (attr = ptr->properties; attr; attr = attr->next)
    {
        if (!xmlStrcmp(attr->name, BAD_CAST "type") &&
            attr->children && attr->children->type == XML_TEXT_NODE)
            type = attr->children->content;
        else
        {
            *error_code = 1;
            *addinfo = "bad attribute for attr content";
            return;
        }
    }
    *term = (Z_Term *) odr_malloc(odr, sizeof(Z_Term));

    if (!type || !xmlStrcmp(type, BAD_CAST "general"))
    {
        (*term)->which = Z_Term_general;
        (*term)->u.general =
            odr_create_Odr_oct(odr, (unsigned char *)cdata, strlen(cdata));
    }
    else if (!xmlStrcmp(type, BAD_CAST "numeric"))
    {
        (*term)->which = Z_Term_numeric;
        (*term)->u.numeric = intVal(odr, cdata);
    }
    else if (!xmlStrcmp(type, BAD_CAST "string"))
    {
        (*term)->which = Z_Term_characterString;
        (*term)->u.characterString = cdata;
    }
    else if (!xmlStrcmp(type, BAD_CAST "oid"))
    {
        *error_code = 1;
        *addinfo = "unhandled term type: oid";
    }
    else if (!xmlStrcmp(type, BAD_CAST "dateTime"))
    {
        *error_code = 1;
        *addinfo = "unhandled term type: dateTime";
    }
    else if (!xmlStrcmp(type, BAD_CAST "integerAndUnit"))
    {
        *error_code = 1;
        *addinfo = "unhandled term type: integerAndUnit";
    }
    else if (!xmlStrcmp(type, BAD_CAST "null"))
    {
        (*term)->which = Z_Term_null;
        (*term)->u.null = odr_nullval();
    }
    else
    {
        *error_code = 1;
        *addinfo = "unhandled term type";
    }
}

void yaz_xml2query_apt(const xmlNode *ptr_apt,
                       Z_AttributesPlusTerm **zapt, ODR odr,
                       int *error_code, const char **addinfo)
{
    const xmlNode *ptr = ptr_apt->children;
    int i, num_attr = 0;

    *zapt = (Z_AttributesPlusTerm *)
        odr_malloc(odr, sizeof(Z_AttributesPlusTerm));

    /* deal with attributes */
    (*zapt)->attributes = (Z_AttributeList*)
        odr_malloc(odr, sizeof(Z_AttributeList));

    /* how many attributes? */
    for (; ptr; ptr = ptr->next)
        if (ptr->type == XML_ELEMENT_NODE)
        {
            if (!xmlStrcmp(ptr->name, BAD_CAST "attr"))
                num_attr++;
            else
                break;
        }

    /* allocate and parse for real */
    (*zapt)->attributes->num_attributes = num_attr;
    (*zapt)->attributes->attributes = (Z_AttributeElement **)
        odr_malloc(odr, sizeof(Z_AttributeElement*) * num_attr);

    i = 0;    
    ptr = ptr_apt->children;
    for (; ptr; ptr = ptr->next)
        if (ptr->type == XML_ELEMENT_NODE)
        {
            if (!xmlStrcmp(ptr->name, BAD_CAST "attr"))
            {
                yaz_xml2query_attribute_element(
                    ptr,  &(*zapt)->attributes->attributes[i], odr,
                    error_code, addinfo);
                i++;
            }
            else
                break;
        }
    if (ptr && ptr->type == XML_ELEMENT_NODE)
    {
        if (!xmlStrcmp(ptr->name, BAD_CAST "term"))
        {        
            /* deal with term */
            yaz_xml2query_term(ptr, &(*zapt)->term, odr, error_code, addinfo);
        }
        else
        {
            *error_code = 1;
            *addinfo = "bad element in apt content";
        }
    }
    else
    {
        *error_code = 1;
        *addinfo = "missing term node in apt content";
    }
}

void yaz_xml2query_rset(const xmlNode *ptr, Z_ResultSetId **rset,
                        ODR odr, int *error_code, const char **addinfo)
{
    if (ptr->children)
    {
        *rset = strVal(ptr->children, odr);
    }
    else
    {
        *error_code = 1;
        *addinfo = "missing rset content";
    }
}

void yaz_xml2query_rpnstructure(const xmlNode *ptr, Z_RPNStructure **zs,
                                ODR odr, int *error_code, const char **addinfo)
{
    while (ptr && ptr->type != XML_ELEMENT_NODE)
        ptr = ptr->next;
    
    if (!ptr || ptr->type != XML_ELEMENT_NODE)
    {
        *error_code = 1;
        *addinfo = "missing rpn operator, rset, apt node";
        return;
    }
    *zs = (Z_RPNStructure *) odr_malloc(odr, sizeof(Z_RPNStructure));
    if (!xmlStrcmp(ptr->name, BAD_CAST "operator"))
    {
        Z_Complex *zc = odr_malloc(odr, sizeof(Z_Complex));
        
        (*zs)->which = Z_RPNStructure_complex;
        (*zs)->u.complex = zc;
        
        yaz_xml2query_operator(ptr, &zc->roperator, odr, error_code, addinfo);

        ptr = ptr->children;
        while (ptr && ptr->type != XML_ELEMENT_NODE)
            ptr = ptr->next;
        yaz_xml2query_rpnstructure(ptr, &zc->s1, odr, error_code, addinfo);
        if (ptr)
            ptr = ptr->next;
        while (ptr && ptr->type != XML_ELEMENT_NODE)
            ptr = ptr->next;
        yaz_xml2query_rpnstructure(ptr, &zc->s2, odr, error_code, addinfo);
    }
    else 
    {
        Z_Operand *s = (Z_Operand *) odr_malloc(odr, sizeof(Z_Operand));
        (*zs)->which = Z_RPNStructure_simple;
        (*zs)->u.simple = s;
        if (!xmlStrcmp(ptr->name, BAD_CAST "apt"))
        {
            s->which = Z_Operand_APT;
            yaz_xml2query_apt(ptr, &s->u.attributesPlusTerm,
                              odr, error_code, addinfo);
        }
        else if (!xmlStrcmp(ptr->name, BAD_CAST "rset"))
        {
            s->which = Z_Operand_resultSetId; 
            yaz_xml2query_rset(ptr, &s->u.resultSetId,
                               odr, error_code, addinfo);
        }
        else
        {
            *error_code = 1;
            *addinfo = "bad element: expected binary, apt or rset";
        }        
    }
}

void yaz_xml2query_rpn(const xmlNode *ptr, Z_RPNQuery **query, ODR odr,
                   int *error_code, const char **addinfo)
{
    const char *set = (const char *)
        xmlGetProp((xmlNodePtr) ptr, BAD_CAST "set");

    *query = (Z_RPNQuery*) odr_malloc(odr, sizeof(Z_RPNQuery));
    if (set)
        (*query)->attributeSetId = yaz_str_to_z3950oid(odr, CLASS_ATTSET, set);
    else
        (*query)->attributeSetId = 0;
    yaz_xml2query_rpnstructure(ptr->children, &(*query)->RPNStructure,
                               odr, error_code, addinfo);
}

static void yaz_xml2query_(const xmlNode *ptr, Z_Query **query, ODR odr,
                           int *error_code, const char **addinfo)
{
    if (ptr && ptr->type == XML_ELEMENT_NODE && 
        !xmlStrcmp(ptr->name, BAD_CAST "query"))
    {
        const char *type;
        ptr = ptr->children;
        while (ptr && ptr->type != XML_ELEMENT_NODE)
            ptr = ptr->next;
        if (!ptr || ptr->type != XML_ELEMENT_NODE)
        {
            *error_code = 1;
            *addinfo = "missing query content";
            return;
        }
        type = (const char *) ptr->name;

        *query = (Z_Query*) odr_malloc(odr, sizeof(Z_Query));
        if (!type || !strcmp(type, "rpn"))
        {
            (*query)->which = Z_Query_type_1;
            yaz_xml2query_rpn(ptr, &(*query)->u.type_1, odr,
                              error_code, addinfo);
        }
        else if (!strcmp(type, "ccl"))
        {
            *error_code = 1;
            *addinfo = "ccl not supported yet";
        }
        else if (!strcmp(type, "z39.58"))
        {
            *error_code = 1;
            *addinfo = "z39.58 not supported yet";
        }
        else if (!strcmp(type, "cql"))
        {
            *error_code = 1;
            *addinfo = "cql not supported yet";
        }
        else
        {
            *error_code = 1;
            *addinfo = "unsupported query type";
        }
    }
    else
    {
        *error_code = 1;
        *addinfo = "missing query element";
    }
}

void yaz_xml2query(const void *xmlnodep, Z_Query **query, ODR odr,
                   int *error_code, const char **addinfo)
{
    yaz_xml2query_(xmlnodep, query, odr, error_code, addinfo);
}

/* YAZ_HAVE_XML2 */
#endif

/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */
