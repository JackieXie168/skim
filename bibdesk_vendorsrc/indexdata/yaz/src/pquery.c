/*
 * Copyright (C) 1995-2005, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: pquery.c,v 1.8 2006/04/01 11:45:23 adam Exp $
 */
/**
 * \file pquery.c
 * \brief Implements PQF parsing
 */
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#include "proto.h"
#include "oid.h"
#include "pquery.h"

static oid_value p_query_dfset = VAL_NONE;

struct yaz_pqf_parser {
    const char *query_buf;
    const char *query_ptr;
    const char *lex_buf;
    size_t lex_len;
    int query_look;
    char *left_sep;
    char *right_sep;
    int escape_char;
    int term_type;
    int external_type;
    int error;
};

static Z_RPNStructure *rpn_structure (struct yaz_pqf_parser *li, ODR o,
                                      oid_proto, 
                                      int num_attr, int max_attr, 
                                      int *attr_list, char **attr_clist,
                                      oid_value *attr_set);

static enum oid_value query_oid_getvalbyname (struct yaz_pqf_parser *li)
{
    enum oid_value value;
    char buf[32];

    if (li->lex_len > 31)
        return VAL_NONE;
    memcpy (buf, li->lex_buf, li->lex_len);
    buf[li->lex_len] = '\0';
    value = oid_getvalbyname (buf);
    return value;
}

static int compare_term (struct yaz_pqf_parser *li, const char *src,
                         size_t off)
{
    size_t len=strlen(src);
    
    if (li->lex_len == len+off && !memcmp (li->lex_buf+off, src, len-off))
        return 1;
    return 0;
}

static int query_token (struct yaz_pqf_parser *li)
{
    int sep_char = ' ';
    const char *sep_match;
    const char **qptr = &li->query_ptr;

    while (**qptr == ' ')
        (*qptr)++;
    if (**qptr == '\0')
        return 0;
    li->lex_len = 0;
    if ((sep_match = strchr (li->left_sep, **qptr)))
    {
        sep_char = li->right_sep[sep_match - li->left_sep];
        ++(*qptr);
    }
    li->lex_buf = *qptr;
   
    if (**qptr == li->escape_char && isdigit (((const unsigned char *) *qptr)[1]))
    {
        ++(li->lex_len);
        ++(*qptr);
        return 'l';
    }
    while (**qptr && **qptr != sep_char)
    {
        if (**qptr == '\\')
        {
            ++(li->lex_len);
            ++(*qptr);
        }
        ++(li->lex_len);
        ++(*qptr);
    }
    if (**qptr)
        ++(*qptr);
    if (sep_char == ' ' &&
        li->lex_len >= 1 && li->lex_buf[0] == li->escape_char)
    {
        if (compare_term (li, "and", 1))
            return 'a';
        if (compare_term (li, "or", 1))
            return 'o';
        if (compare_term (li, "not", 1))
            return 'n';
        if (compare_term (li, "attr", 1))
            return 'l';
        if (compare_term (li, "set", 1))
            return 's';
        if (compare_term (li, "attrset", 1))
            return 'r';
        if (compare_term (li, "prox", 1))
            return 'p';
        if (compare_term (li, "term", 1))
            return 'y';
    }
    return 't';
}

static int lex (struct yaz_pqf_parser *li)
{
    return li->query_look = query_token (li);
}

static int escape_string(char *out_buf, const char *in, int len)
{

    char *out = out_buf;
    while (--len >= 0)
        if (*in == '\\' && len > 0)
        {
            --len;
            switch (*++in)
            {
            case 't':
                *out++ = '\t';
                break;
            case 'n':
                *out++ = '\n';
                break;
            case 'r':
                *out++ = '\r';
                break;
            case 'f':
                *out++ = '\f';
                break;
            case 'x':
                if (len > 1)
                {
                    char s[4];
                    int n = 0;
                    s[0] = *++in;
                    s[1] = *++in;
                    s[2] = '\0';
                    len = len - 2;
                    sscanf (s, "%x", &n);
                    *out++ = n;
                }
                break;
            case '0':
            case '1':
            case '2':
            case '3':
                if (len > 1)
                {
                    char s[4];
                    int n = 0;
                    s[0] = *in;
                    s[1] = *++in;                   
                    s[2] = *++in;
                    s[3] = '\0';
                    len = len - 2;
                    sscanf (s, "%o", &n);
                    *out++ = n;
                }
                break;
            default:
                *out++ = *in;
                break;
            }
            in++;
        }
        else
            *out++ = *in++;
    return out - out_buf;
}

static int p_query_parse_attr(struct yaz_pqf_parser *li, ODR o,
                              int num_attr, int *attr_list,
                              char **attr_clist, oid_value *attr_set)
{
    const char *cp;

    if (!(cp = strchr (li->lex_buf, '=')) ||
        (size_t) (cp-li->lex_buf) > li->lex_len)
    {
        attr_set[num_attr] = query_oid_getvalbyname (li);
        if (attr_set[num_attr] == VAL_NONE)
        {
            li->error = YAZ_PQF_ERROR_ATTSET;
            return 0;
        }
        if (!lex (li))
        {
            li->error = YAZ_PQF_ERROR_MISSING;
            return 0;
        }
        if (!(cp = strchr (li->lex_buf, '=')))
        {
            li->error = YAZ_PQF_ERROR_BADATTR;
            return 0;
        }
    }
    else 
    {
        if (num_attr > 0)
            attr_set[num_attr] = attr_set[num_attr-1];
        else
            attr_set[num_attr] = VAL_NONE;
    }
    if (*li->lex_buf < '0' || *li->lex_buf > '9')
    {
        li->error = YAZ_PQF_ERROR_BAD_INTEGER;
        return 0;
    }
    attr_list[2*num_attr] = atoi(li->lex_buf);
    cp++;
    if (*cp >= '0' && *cp <= '9')
    {
        attr_list[2*num_attr+1] = atoi (cp);
        attr_clist[num_attr] = 0;
    }
    else
    {
        int len = li->lex_len - (cp - li->lex_buf);
        attr_list[2*num_attr+1] = 0;
        attr_clist[num_attr] = (char *) odr_malloc (o, len+1);
        len = escape_string(attr_clist[num_attr], cp, len);
        attr_clist[num_attr][len] = '\0';
    }
    return 1;
}

static Z_AttributesPlusTerm *rpn_term (struct yaz_pqf_parser *li, ODR o,
                                       oid_proto proto, 
                                       int num_attr, int *attr_list,
                                       char **attr_clist, oid_value *attr_set)
{
    Z_AttributesPlusTerm *zapt;
    Odr_oct *term_octet;
    Z_Term *term;
    Z_AttributeElement **elements;

    zapt = (Z_AttributesPlusTerm *)odr_malloc (o, sizeof(*zapt));
    term_octet = (Odr_oct *)odr_malloc (o, sizeof(*term_octet));
    term = (Z_Term *)odr_malloc (o, sizeof(*term));

    if (!num_attr)
        elements = (Z_AttributeElement**)odr_nullval();
    else
    {
        int i, k = 0;
        int *attr_tmp;

        elements = (Z_AttributeElement**)
            odr_malloc (o, num_attr * sizeof(*elements));

        attr_tmp = (int *)odr_malloc (o, num_attr * 2 * sizeof(int));
        memcpy (attr_tmp, attr_list, num_attr * 2 * sizeof(int));
        for (i = num_attr; --i >= 0; )
        {
            int j;
            for (j = i+1; j<num_attr; j++)
                if (attr_tmp[2*j] == attr_tmp[2*i])
                    break;
            if (j < num_attr)
                continue;
            elements[k] =
                (Z_AttributeElement*)odr_malloc (o,sizeof(**elements));
            elements[k]->attributeType = &attr_tmp[2*i];
            elements[k]->attributeSet =
                yaz_oidval_to_z3950oid(o, CLASS_ATTSET, attr_set[i]);

            if (attr_clist[i])
            {
                elements[k]->which = Z_AttributeValue_complex;
                elements[k]->value.complex = (Z_ComplexAttribute *)
                    odr_malloc (o, sizeof(Z_ComplexAttribute));
                elements[k]->value.complex->num_list = 1;
                elements[k]->value.complex->list =
                    (Z_StringOrNumeric **)
                    odr_malloc (o, 1 * sizeof(Z_StringOrNumeric *));
                elements[k]->value.complex->list[0] =
                    (Z_StringOrNumeric *)
                    odr_malloc (o, sizeof(Z_StringOrNumeric));
                elements[k]->value.complex->list[0]->which =
                    Z_StringOrNumeric_string;
                elements[k]->value.complex->list[0]->u.string =
                    attr_clist[i];
                elements[k]->value.complex->semanticAction = (int **)
                    odr_nullval();
                elements[k]->value.complex->num_semanticAction = 0;
            }
            else
            {
                elements[k]->which = Z_AttributeValue_numeric;
                elements[k]->value.numeric = &attr_tmp[2*i+1];
            }
            k++;
        }
        num_attr = k;
    }
    zapt->attributes = (Z_AttributeList *)
        odr_malloc (o, sizeof(*zapt->attributes));
    zapt->attributes->num_attributes = num_attr;
    zapt->attributes->attributes = elements;

    zapt->term = term;

    term_octet->buf = (unsigned char *)odr_malloc (o, 1 + li->lex_len);
    term_octet->size = term_octet->len =
        escape_string ((char *) (term_octet->buf), li->lex_buf, li->lex_len);
    term_octet->buf[term_octet->size] = 0;  /* null terminate */
    
    switch (li->term_type)
    {
    case Z_Term_general:
        term->which = Z_Term_general;
        term->u.general = term_octet;
        break;
    case Z_Term_characterString:
        term->which = Z_Term_characterString;
        term->u.characterString = (char*) term_octet->buf; 
                                    /* null terminated above */
        break;
    case Z_Term_numeric:
        term->which = Z_Term_numeric;
        term->u.numeric = odr_intdup (o, atoi((char*) (term_octet->buf)));
        break;
    case Z_Term_null:
        term->which = Z_Term_null;
        term->u.null = odr_nullval();
        break;
    case Z_Term_external:
        term->which = Z_Term_external;
        term->u.external = 0;
        break;
    default:
        term->which = Z_Term_null;
        term->u.null = odr_nullval();
        break;
    }
    return zapt;
}

static Z_Operand *rpn_simple (struct yaz_pqf_parser *li, ODR o, oid_proto proto,
                              int num_attr, int *attr_list, char **attr_clist,
                              oid_value *attr_set)
{
    Z_Operand *zo;

    zo = (Z_Operand *)odr_malloc (o, sizeof(*zo));
    switch (li->query_look)
    {
    case 't':
        zo->which = Z_Operand_APT;
        if (!(zo->u.attributesPlusTerm =
              rpn_term (li, o, proto, num_attr, attr_list, attr_clist,
                        attr_set)))
            return 0;
        lex (li);
        break;
    case 's':
        lex (li);
        if (!li->query_look)
        {
            li->error = YAZ_PQF_ERROR_MISSING;
            return 0;
        }
        zo->which = Z_Operand_resultSetId;
        zo->u.resultSetId = (char *)odr_malloc (o, li->lex_len+1);
        memcpy (zo->u.resultSetId, li->lex_buf, li->lex_len);
        zo->u.resultSetId[li->lex_len] = '\0';
        lex (li);
        break;
    default:
        /* we're only called if one of the above types are seens so
           this shouldn't happen */
        li->error = YAZ_PQF_ERROR_INTERNAL;
        return 0;
    }
    return zo;
}

static Z_ProximityOperator *rpn_proximity (struct yaz_pqf_parser *li, ODR o)
{
    Z_ProximityOperator *p = (Z_ProximityOperator *)odr_malloc (o, sizeof(*p));

    if (!lex (li))
    {
        li->error = YAZ_PQF_ERROR_MISSING;
        return NULL;
    }
    if (*li->lex_buf == '1')
        p->exclusion = odr_intdup (o, 1);
    else if (*li->lex_buf == '0')
        p->exclusion = odr_intdup (o, 0);
    else if (*li->lex_buf == 'v' || *li->lex_buf == 'n')
        p->exclusion = NULL;
    else
    {
        li->error = YAZ_PQF_ERROR_PROXIMITY;
        return NULL;
    }

    if (!lex (li))
    {
        li->error = YAZ_PQF_ERROR_MISSING;
        return NULL;
    }
    if (*li->lex_buf >= '0' && *li->lex_buf <= '9')
        p->distance = odr_intdup (o, atoi (li->lex_buf));
    else
    {
        li->error = YAZ_PQF_ERROR_BAD_INTEGER;
        return NULL;
    }

    if (!lex (li))
    {
        li->error = YAZ_PQF_ERROR_MISSING;
        return NULL;
    }
    if (*li->lex_buf == '1')
        p->ordered = odr_intdup (o, 1);
    else if (*li->lex_buf == '0')
        p->ordered = odr_intdup (o, 0);
    else
    {
        li->error = YAZ_PQF_ERROR_PROXIMITY;
        return NULL;
    }
    
    if (!lex (li))
    {
        li->error = YAZ_PQF_ERROR_MISSING;
        return NULL;
    }
    if (*li->lex_buf >= '0' && *li->lex_buf <= '9')
        p->relationType = odr_intdup (o, atoi (li->lex_buf));
    else
    {
        li->error = YAZ_PQF_ERROR_BAD_INTEGER;
        return NULL;
    }

    if (!lex (li))
    {
        li->error = YAZ_PQF_ERROR_MISSING;
        return NULL;
    }
    if (*li->lex_buf == 'k')
        p->which = Z_ProximityOperator_known;
    else if (*li->lex_buf == 'p')
        p->which = Z_ProximityOperator_private;
    else
        p->which = atoi (li->lex_buf);

    if (p->which != Z_ProximityOperator_known
        && p->which != Z_ProximityOperator_private)
    {
        li->error = YAZ_PQF_ERROR_PROXIMITY;
        return NULL;
    }

    if (!lex (li))
    {
        li->error = YAZ_PQF_ERROR_MISSING;
        return NULL;
    }
    if (*li->lex_buf >= '0' && *li->lex_buf <= '9')
        p->u.known = odr_intdup (o, atoi(li->lex_buf));
    else
    {
        li->error = YAZ_PQF_ERROR_BAD_INTEGER;
        return NULL;
    }
    return p;
}

static Z_Complex *rpn_complex (struct yaz_pqf_parser *li, ODR o, oid_proto proto,
                               int num_attr, int max_attr, 
                               int *attr_list, char **attr_clist,
                               oid_value *attr_set)
{
    Z_Complex *zc;
    Z_Operator *zo;

    zc = (Z_Complex *)odr_malloc (o, sizeof(*zc));
    zo = (Z_Operator *)odr_malloc (o, sizeof(*zo));
    zc->roperator = zo;
    switch (li->query_look)
    {
    case 'a':
        zo->which = Z_Operator_and;
        zo->u.op_and = odr_nullval();
        break;
    case 'o':
        zo->which = Z_Operator_or;
        zo->u.op_or = odr_nullval();
        break;
    case 'n':
        zo->which = Z_Operator_and_not;
        zo->u.and_not = odr_nullval();
        break;
    case 'p':
        zo->which = Z_Operator_prox;
        zo->u.prox = rpn_proximity (li, o);
        if (!zo->u.prox)
            return NULL;
        break;
    default:
        /* we're only called if one of the above types are seens so
           this shouldn't happen */
        li->error = YAZ_PQF_ERROR_INTERNAL;
        return NULL;
    }
    lex (li);
    if (!(zc->s1 =
          rpn_structure (li, o, proto, num_attr, max_attr, attr_list,
                         attr_clist, attr_set)))
        return NULL;
    if (!(zc->s2 =
          rpn_structure (li, o, proto, num_attr, max_attr, attr_list,
                         attr_clist, attr_set)))
        return NULL;
    return zc;
}

static void rpn_term_type (struct yaz_pqf_parser *li, ODR o)
{
    if (!li->query_look)
        return ;
    if (compare_term (li, "general", 0))
        li->term_type = Z_Term_general;
    else if (compare_term (li, "numeric", 0))
        li->term_type = Z_Term_numeric;
    else if (compare_term (li, "string", 0))
        li->term_type = Z_Term_characterString;
    else if (compare_term (li, "oid", 0))
        li->term_type = Z_Term_oid;
    else if (compare_term (li, "datetime", 0))
        li->term_type = Z_Term_dateTime;
    else if (compare_term (li, "null", 0))
        li->term_type = Z_Term_null;
    else if (compare_term(li, "range", 0))
    {
        /* prepare for external: range search .. */
        li->term_type = Z_Term_external;
        li->external_type = VAL_MULTISRCH2;
    }
    lex (li);
}
                           
static Z_RPNStructure *rpn_structure (struct yaz_pqf_parser *li, ODR o,
                                      oid_proto proto, 
                                      int num_attr, int max_attr, 
                                      int *attr_list,
                                      char **attr_clist,
                                      oid_value *attr_set)
{
    Z_RPNStructure *sz;

    sz = (Z_RPNStructure *)odr_malloc (o, sizeof(*sz));
    switch (li->query_look)
    {
    case 'a':
    case 'o':
    case 'n':
    case 'p':
        sz->which = Z_RPNStructure_complex;
        if (!(sz->u.complex =
              rpn_complex (li, o, proto, num_attr, max_attr, attr_list,
                           attr_clist, attr_set)))
            return NULL;
        break;
    case 't':
    case 's':
        sz->which = Z_RPNStructure_simple;
        if (!(sz->u.simple =
              rpn_simple (li, o, proto, num_attr, attr_list,
                          attr_clist, attr_set)))
            return NULL;
        break;
    case 'l':
        lex (li);
        if (!li->query_look)
        {
            li->error = YAZ_PQF_ERROR_MISSING;
            return 0;
        }
        if (num_attr >= max_attr)
        {
            li->error = YAZ_PQF_ERROR_TOOMANY;
            return 0;
        }
        if (!p_query_parse_attr(li, o, num_attr, attr_list,
                                attr_clist, attr_set))
            return 0;
        num_attr++;
        lex (li);
        return
            rpn_structure (li, o, proto, num_attr, max_attr, attr_list,
                           attr_clist,  attr_set);
    case 'y':
        lex (li);
        rpn_term_type (li, o);
        return
            rpn_structure (li, o, proto, num_attr, max_attr, attr_list,
                           attr_clist, attr_set);
    case 0:                /* operator/operand expected! */
        li->error = YAZ_PQF_ERROR_MISSING;
        return 0;
    }
    return sz;
}

Z_RPNQuery *p_query_rpn_mk (ODR o, struct yaz_pqf_parser *li, oid_proto proto,
                            const char *qbuf)
{
    Z_RPNQuery *zq;
    int attr_array[1024];
    char *attr_clist[512];
    oid_value attr_set[512];
    oid_value topSet = VAL_NONE;

    zq = (Z_RPNQuery *)odr_malloc (o, sizeof(*zq));
    lex (li);
    if (li->query_look == 'r')
    {
        lex (li);
        topSet = query_oid_getvalbyname (li);
        if (topSet == VAL_NONE)
        {
            li->error = YAZ_PQF_ERROR_ATTSET;
            return NULL;
        }

        lex (li);
    }
    if (topSet == VAL_NONE)
        topSet = p_query_dfset;
    if (topSet == VAL_NONE)
        topSet = VAL_BIB1;

    zq->attributeSetId = yaz_oidval_to_z3950oid(o, CLASS_ATTSET, topSet);

    if (!zq->attributeSetId)
    {
        li->error = YAZ_PQF_ERROR_ATTSET;
        return 0;
    }

    if (!(zq->RPNStructure = rpn_structure (li, o, proto, 0, 512,
                                            attr_array, attr_clist, attr_set)))
        return 0;
    if (li->query_look)
    {
        li->error = YAZ_PQF_ERROR_EXTRA;
        return 0;
    }
    return zq;
}

Z_RPNQuery *p_query_rpn (ODR o, oid_proto proto, const char *qbuf)
{
    struct yaz_pqf_parser li;

    li.error = 0;
    li.left_sep = "{\"";
    li.right_sep = "}\"";
    li.escape_char = '@';
    li.term_type = Z_Term_general;
    li.query_buf = li.query_ptr = qbuf;
    li.lex_buf = 0;
    return p_query_rpn_mk (o, &li, proto, qbuf);
}


Z_AttributesPlusTerm *p_query_scan_mk (struct yaz_pqf_parser *li,
                                       ODR o, oid_proto proto,
                                       Odr_oid **attributeSetP,
                                       const char *qbuf)
{
    int attr_list[1024];
    char *attr_clist[512];
    oid_value attr_set[512];
    int num_attr = 0;
    int max_attr = 512;
    oid_value topSet = VAL_NONE;
    Z_AttributesPlusTerm *apt;

    lex (li);
    if (li->query_look == 'r')
    {
        lex (li);
        topSet = query_oid_getvalbyname (li);

        lex (li);
    }
    if (topSet == VAL_NONE)
        topSet = p_query_dfset;
    if (topSet == VAL_NONE)
        topSet = VAL_BIB1;

    *attributeSetP = yaz_oidval_to_z3950oid (o, CLASS_ATTSET, topSet);

    while (1)
    {
        if (li->query_look == 'l')
        {
            lex (li);
            if (!li->query_look)
            {
                li->error = YAZ_PQF_ERROR_MISSING;
                return 0;
            }
            if (num_attr >= max_attr)
            {
                li->error = YAZ_PQF_ERROR_TOOMANY;
                return 0;
            }
            if (!p_query_parse_attr(li, o, num_attr, attr_list,
                                    attr_clist, attr_set))
                return 0;
            num_attr++;
            lex (li);
        }
        else if (li->query_look == 'y')
        {
            lex (li);
            rpn_term_type (li, o);
        }
        else
            break;
    }
    if (!li->query_look)
    {
        li->error = YAZ_PQF_ERROR_MISSING;
        return 0;
    }
    apt = rpn_term (li, o, proto, num_attr, attr_list, attr_clist, attr_set);

    lex (li);

    if (li->query_look != 0)
    {
        li->error = YAZ_PQF_ERROR_EXTRA;
        return 0;
    }
    return apt;
}

Z_AttributesPlusTerm *p_query_scan (ODR o, oid_proto proto,
                                    Odr_oid **attributeSetP,
                                    const char *qbuf)
{
    struct yaz_pqf_parser li;

    li.error = 0;
    li.left_sep = "{\"";
    li.right_sep = "}\"";
    li.escape_char = '@';
    li.term_type = Z_Term_general;
    li.query_buf = li.query_ptr = qbuf;
    li.lex_buf = 0;

    return p_query_scan_mk (&li, o, proto, attributeSetP, qbuf);
}

int p_query_attset (const char *arg)
{
    p_query_dfset = oid_getvalbyname (arg);
    return (p_query_dfset == VAL_NONE) ? -1 : 0;
}

YAZ_PQF_Parser yaz_pqf_create (void)
{
    YAZ_PQF_Parser p = (YAZ_PQF_Parser) xmalloc (sizeof(*p));

    p->error = 0;
    p->left_sep = "{\"";
    p->right_sep = "}\"";
    p->escape_char = '@';
    p->term_type = Z_Term_general;

    return p;
}

void yaz_pqf_destroy (YAZ_PQF_Parser p)
{
    xfree (p);
}

Z_RPNQuery *yaz_pqf_parse (YAZ_PQF_Parser p, ODR o, const char *qbuf)
{
    if (!p)
        return 0;
    p->query_buf = p->query_ptr = qbuf;
    p->lex_buf = 0;
    return p_query_rpn_mk (o, p, PROTO_Z3950, qbuf);
}

Z_AttributesPlusTerm *yaz_pqf_scan (YAZ_PQF_Parser p, ODR o,
                                    Odr_oid **attributeSetP,
                                    const char *qbuf)
{
    if (!p)
        return 0;
    p->query_buf = p->query_ptr = qbuf;
    p->lex_buf = 0;
    return p_query_scan_mk (p, o, PROTO_Z3950, attributeSetP, qbuf);
}

int yaz_pqf_error (YAZ_PQF_Parser p, const char **msg, size_t *off)
{
    switch (p->error)
    {
    case YAZ_PQF_ERROR_NONE:
        *msg = "no error"; break;
    case YAZ_PQF_ERROR_EXTRA:
        *msg = "extra token"; break;
    case YAZ_PQF_ERROR_MISSING:
        *msg = "missing token"; break;
    case YAZ_PQF_ERROR_ATTSET:
        *msg = "unknown attribute set"; break;
    case YAZ_PQF_ERROR_TOOMANY:
        *msg = "too many attributes"; break;
    case YAZ_PQF_ERROR_BADATTR:
        *msg = "bad attribute specification"; break;
    case YAZ_PQF_ERROR_INTERNAL:
        *msg = "internal error"; break;
    case YAZ_PQF_ERROR_PROXIMITY:
        *msg = "proximity error"; break;
    case YAZ_PQF_ERROR_BAD_INTEGER:
        *msg = "bad integer"; break;
    default:
        *msg = "unknown error"; break;
    }
    *off = p->query_ptr - p->query_buf;
    return p->error;
}
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

