/*
 * Copyright (C) 1995-2005, Index Data ApS
 * All rights reserved.
 *
 * $Id: logrpn.c,v 1.14 2006/01/20 10:34:51 adam Exp $
 */

/**
 * \file logrpn.c
 * \brief Implements Z39.50 Query Printing
 */

#include <stdio.h>
#include <assert.h>

#include <yaz/log.h>
#include <yaz/logrpn.h>

static const char *relToStr(int v)
{
    const char *str = 0;
    switch (v)
    {
    case 1: str = "Less than"; break;
    case 2: str = "Less than or equal"; break;
    case 3: str = "Equal"; break;
    case 4: str = "Greater or equal"; break;
    case 5: str = "Greater than"; break;
    case 6: str = "Not equal"; break;
    case 100: str = "Phonetic"; break;
    case 101: str = "Stem"; break;
    case 102: str = "Relevance"; break;
    case 103: str = "AlwaysMatches"; break;
    }
    return str;
}

static void attrStr (int type, int value, enum oid_value ast, char *str)
{
    const char *rstr;
    *str = '\0';
    switch (ast)
    {
    case VAL_BIB1:
    case VAL_EXP1:
    case VAL_GILS:
        switch (type)
        {
        case 1:
            sprintf (str, "use");
            break;
        case 2:
            rstr = relToStr(value);
            if (rstr)
                sprintf(str, "relation=%s", rstr);
            else
                sprintf(str, "relation=%d", value);
            break;
        case 3:
            switch (value)
            {
            case 1:
                sprintf(str, "position=First in field");
                break;
            case 2:
                sprintf(str, "position=First in any subfield");
                break;
            case 3:
                sprintf(str, "position=Any position in field");
                break;
            default:
                sprintf(str, "position");
            }
            break;
        case 4:
            switch (value)
            {
            case 1:
                sprintf(str, "structure=Phrase");
                break;
            case 2:
                sprintf(str, "structure=Word");
                break;
            case 3:
                sprintf(str, "structure=Key");
                break;
            case 4:
                sprintf(str, "structure=Year");
                break;
            case 5:
                sprintf(str, "structure=Date");
                break;
            case 6:
                sprintf(str, "structure=Word list");
                break;
            case 100:
                sprintf(str, "structure=Date (un)");
                break;
            case 101:
                sprintf(str, "structure=Name (norm)");
                break;
            case 102:
                sprintf(str, "structure=Name (un)");
                break;
            case 103:
                sprintf(str, "structure=Structure");
                break;
            case 104:
                sprintf(str, "structure=urx");
                break;
            case 105:
                sprintf(str, "structure=free-form-text");
                break;
            case 106:
                sprintf(str, "structure=document-text");
                break;
            case 107:
                sprintf(str, "structure=local-number");
                break;
            case 108:
                sprintf(str, "structure=string");
                break;
            case 109:
                sprintf(str, "structure=numeric string");
                break;
            default:
                sprintf(str, "structure");
            }
            break;
        case 5:
            switch (value)
            {
            case 1:
                sprintf(str, "truncation=Right");
                break;
            case 2:
                sprintf(str, "truncation=Left");
                break;
            case 3:
                sprintf(str, "truncation=Left&right");
                break;
            case 100:
                sprintf(str, "truncation=Do not truncate");
                break;
            case 101:
                sprintf(str, "truncation=Process #");
                break;
            case 102:
                sprintf(str, "truncation=re-1");
                break;
            case 103:
                sprintf(str, "truncation=re-2");
                break;
            case 104:
                sprintf(str, "truncation=CCL");
                break;
            default:
                sprintf(str, "truncation");
            }
            break;
        case 6:
            switch(value)
            {
            case 1:
                sprintf(str, "completeness=Incomplete subfield");
                break;
            case 2:
                sprintf(str, "completeness=Complete subfield");
                break;
            case 3:
                sprintf(str, "completeness=Complete field");
                break;
            default:
                sprintf(str, "completeness");
            }
            break;
        }
        break;
    default:
        break;
    }
    if (*str)
        sprintf(str + strlen(str), " (%d=%d)", type, value);
    else
        sprintf(str, "%d=%d", type, value);
}

/*
 * zlog_attributes: print attributes of term
 */
static void zlog_attributes (Z_AttributesPlusTerm *t, int depth,
                             enum oid_value ast, int loglevel)
{
    int of, i;
    char str[80];
    int num_attributes = t->attributes->num_attributes;
    
    for (of = 0; of < num_attributes; of++)
    {
        const char *attset_name = "";
        Z_AttributeElement *element;
        element = t->attributes->attributes[of];
        if (element->attributeSet)
        {
            oident *attrset;
            attrset = oid_getentbyoid (element->attributeSet);
            attset_name = attrset->desc;
        }
        switch (element->which) 
        {
        case Z_AttributeValue_numeric:
            attrStr (*element->attributeType,
                     *element->value.numeric, ast, str);
            yaz_log (loglevel, "%*.0s%s %s", depth, "", attset_name, str);
            break;
        case Z_AttributeValue_complex:
            yaz_log (loglevel, "%*.0s%s attributeType=%d complex",
                  depth, "", attset_name, *element->attributeType);
            for (i = 0; i<element->value.complex->num_list; i++)
            {
                if (element->value.complex->list[i]->which ==
                    Z_StringOrNumeric_string)
                    yaz_log (loglevel, "%*.0s  string: '%s'", depth, "",
                             element->value.complex->list[i]->u.string);
                else if (element->value.complex->list[i]->which ==
                         Z_StringOrNumeric_numeric)
                    yaz_log (loglevel, "%*.0s  numeric: '%d'", depth, "",
                             *element->value.complex->list[i]->u.numeric);
            }
            break;
        default:
            yaz_log (loglevel, "%.*s%s attribute unknown",
                     depth, "", attset_name);
        }
    }
}

static char *complex_op_name(Z_Operator *op)
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

static char *prox_unit_name(Z_ProximityOperator *op)
{
    if (op->which!=Z_ProximityOperator_known)
         return "private";
    switch(*op->u.known)
    {
        case Z_ProxUnit_character: return "character";
        case Z_ProxUnit_word: return "word";
        case Z_ProxUnit_sentence: return "sentence";
        case Z_ProxUnit_paragraph: return "paragraph";
        case Z_ProxUnit_section: return "section";
        case Z_ProxUnit_chapter: return "chapter";
        case Z_ProxUnit_document: return "document";
        case Z_ProxUnit_element: return "element";
        case Z_ProxUnit_subelement: return "subelement";
        case Z_ProxUnit_elementType: return "elementType";
        case Z_ProxUnit_byte: return "byte";
        default: return "unknown";
    }
}

static void zlog_structure (Z_RPNStructure *zs, int depth, 
        enum oid_value ast, int loglevel)
{
    if (zs->which == Z_RPNStructure_complex)
    {
        Z_Operator *op = zs->u.complex->roperator;
        switch (op->which)
        {
        case Z_Operator_and:
        case Z_Operator_or:
        case Z_Operator_and_not:
            yaz_log (loglevel, "%*.0s %s", depth, "", complex_op_name(op) );
            break;
        case Z_Operator_prox:
            yaz_log (loglevel, "%*.0s prox excl=%s dist=%d order=%s "
                     "rel=%s unit=%s",
                     depth, "", op->u.prox->exclusion ?
                     (*op->u.prox->exclusion ? "T" : "F") : "N", 
                     *op->u.prox->distance,
                     *op->u.prox->ordered ? "T" : "F",
                     relToStr(*op->u.prox->relationType),
                     prox_unit_name(op->u.prox) );
            break;
        default:
            yaz_log (loglevel, "%*.0s unknown complex", depth, "");
            return;
        }
        zlog_structure (zs->u.complex->s1, depth+2, ast, loglevel);
        zlog_structure (zs->u.complex->s2, depth+2, ast, loglevel);
    } 
    else if (zs->which == Z_RPNStructure_simple)
    {
        if (zs->u.simple->which == Z_Operand_APT)
        {
            Z_AttributesPlusTerm *zapt = zs->u.simple->u.attributesPlusTerm;

            switch (zapt->term->which)
            {
            case Z_Term_general:
                yaz_log (loglevel, "%*.0s term '%.*s' (general)", depth, "",
                         zapt->term->u.general->len,
                         zapt->term->u.general->buf);
                break;
            case Z_Term_characterString:
                yaz_log (loglevel, "%*.0s term '%s' (string)", depth, "",
                         zapt->term->u.characterString);
                break;
            case Z_Term_numeric:
                yaz_log (loglevel, "%*.0s term '%d' (numeric)", depth, "",
                         *zapt->term->u.numeric);
                break;
            case Z_Term_null:
                yaz_log (loglevel, "%*.0s term (null)", depth, "");
                break;
            default:
                yaz_log (loglevel, "%*.0s term (not general)", depth, "");
            }
            zlog_attributes (zapt, depth+2, ast, loglevel);
        }
        else if (zs->u.simple->which == Z_Operand_resultSetId)
        {
            yaz_log (loglevel, "%*.0s set '%s'", depth, "",
                     zs->u.simple->u.resultSetId);
        }
        else
            yaz_log (loglevel, "%*.0s unknown simple structure", depth, "");
    }
    else
        yaz_log (loglevel, "%*.0s unknown structure", depth, "");
}

void log_rpn_query_level (int loglevel, Z_RPNQuery *rpn)
{
    oident *attrset;
    enum oid_value ast;
    
    attrset = oid_getentbyoid (rpn->attributeSetId);
    if (attrset)
    {
        ast = attrset->value;
        yaz_log (loglevel, "RPN query. Type: %s", attrset->desc);
    } 
    else
    {
        ast = VAL_NONE;
        yaz_log (loglevel, "RPN query. Unknown type");
    }
    zlog_structure (rpn->RPNStructure, 0, ast, loglevel);
}

void log_rpn_query(Z_RPNQuery *rpn)
{
    log_rpn_query_level(YLOG_LOG, rpn);
}

void log_scan_term_level(int loglevel, 
                         Z_AttributesPlusTerm *zapt, oid_value ast)
{
    int depth = 0;
    if (!loglevel)
        return;
    if (zapt->term->which == Z_Term_general) 
    {
        yaz_log (loglevel, "%*.0s term '%.*s' (general)", depth, "",
                 zapt->term->u.general->len, zapt->term->u.general->buf);
    }
    else
        yaz_log (loglevel, "%*.0s term (not general)", depth, "");
    zlog_attributes (zapt, depth+2, ast, loglevel);
}

void log_scan_term(Z_AttributesPlusTerm *zapt, oid_value ast)
{
    log_scan_term_level (YLOG_LOG, zapt, ast);
}

void yaz_log_zquery_level (int loglevel, Z_Query *q)
{
    if (!loglevel)
        return; 
    switch (q->which)
    {
    case Z_Query_type_1: case Z_Query_type_101:
        log_rpn_query_level (loglevel, q->u.type_1);
        break;
    case Z_Query_type_2:
        yaz_log(loglevel, "CCL: %.*s", q->u.type_2->len, q->u.type_2->buf);
        break;
    case Z_Query_type_100:
        yaz_log(loglevel, "Z39.58: %.*s", q->u.type_100->len,
                q->u.type_100->buf);
        break;
    case Z_Query_type_104:
        if (q->u.type_104->which == Z_External_CQL)
            yaz_log (loglevel, "CQL: %s", q->u.type_104->u.cql);
    }
}

void yaz_log_zquery (Z_Query *q)
{
    yaz_log_zquery_level(YLOG_LOG, q);
}

void wrbuf_diags(WRBUF b, int num_diagnostics,Z_DiagRec **diags)
{
    /* we only dump the first diag - that keeps the log cleaner. */
    wrbuf_printf(b," ERROR ");
    if (diags[0]->which != Z_DiagRec_defaultFormat)
        wrbuf_printf(b,"(diag not in default format?)");
    else
    {
        Z_DefaultDiagFormat *e=diags[0]->u.defaultFormat;
        if (e->condition)
            wrbuf_printf(b, "%d ",*e->condition);
        else
            wrbuf_printf(b, "?? ");
        if ((e->which==Z_DefaultDiagFormat_v2Addinfo) && (e->u.v2Addinfo))
            wrbuf_printf(b,"%s ",e->u.v2Addinfo);
        else if ((e->which==Z_DefaultDiagFormat_v3Addinfo) && (e->u.v3Addinfo))
            wrbuf_printf(b,"%s ",e->u.v3Addinfo);
    }
}
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

