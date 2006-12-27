/*
 * Copyright (c) 1995, the EUROPAGATE consortium (see below).
 *
 * The EUROPAGATE consortium members are:
 *
 *    University College Dublin
 *    Danmarks Teknologiske Videnscenter
 *    An Chomhairle Leabharlanna
 *    Consejo Superior de Investigaciones Cientificas
 *
 * Permission to use, copy, modify, distribute, and sell this software and
 * its documentation, in whole or in part, for any purpose, is hereby granted,
 * provided that:
 *
 * 1. This copyright and permission notice appear in all copies of the
 * software and its documentation. Notices of copyright or attribution
 * which appear at the beginning of any file must remain unchanged.
 *
 * 2. The names of EUROPAGATE or the project partners may not be used to
 * endorse or promote products derived from this software without specific
 * prior written permission.
 *
 * 3. Users of this software (implementors and gateway operators) agree to
 * inform the EUROPAGATE consortium of their use of the software. This
 * information will be used to evaluate the EUROPAGATE project and the
 * software, and to plan further developments. The consortium may use
 * the information in later publications.
 * 
 * 4. Users of this software agree to make their best efforts, when
 * documenting their use of the software, to acknowledge the EUROPAGATE
 * consortium, and the role played by the software in their work.
 *
 * THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS, IMPLIED, OR OTHERWISE, INCLUDING WITHOUT LIMITATION, ANY
 * WARRANTY OF MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE.
 * IN NO EVENT SHALL THE EUROPAGATE CONSORTIUM OR ITS MEMBERS BE LIABLE
 * FOR ANY SPECIAL, INCIDENTAL, INDIRECT OR CONSEQUENTIAL DAMAGES OF
 * ANY KIND, OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA
 * OR PROFITS, WHETHER OR NOT ADVISED OF THE POSSIBILITY OF DAMAGE, AND
 * ON ANY THEORY OF LIABILITY, ARISING OUT OF OR IN CONNECTION WITH THE
 * USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 */

/** 
 * \file cclfind.c
 * \brief Implements parsing of a CCL FIND query.
 *
 * This source file implements parsing of a CCL Query (ISO8777).
 * The parser uses predictive parsing, but it does several tokens
 * of lookahead in the handling of relational operations.. So
 * it's not really pure.
 */


/* CCL find (to rpn conversion)
 * Europagate, 1995
 *
 * $Id: cclfind.c,v 1.8 2005/06/25 15:46:03 adam Exp $
 *
 * Old Europagate log:
 *
 * Revision 1.16  1996/01/08  08:41:13  adam
 * Removed unused function.
 *
 * Revision 1.15  1995/07/20  08:14:34  adam
 * Qualifiers were observed too often. Instead tokens are treated as
 * qualifiers only when separated by comma.
 *
 * Revision 1.14  1995/05/16  09:39:26  adam
 * LICENSE.
 *
 * Revision 1.13  1995/04/17  09:31:42  adam
 * Improved handling of qualifiers. Aliases or reserved words.
 *
 * Revision 1.12  1995/03/20  15:27:43  adam
 * Minor changes.
 *
 * Revision 1.11  1995/02/23  08:31:59  adam
 * Changed header.
 *
 * Revision 1.9  1995/02/16  13:20:06  adam
 * Spell fix.
 *
 * Revision 1.8  1995/02/14  19:59:42  adam
 * Removed a syntax error.
 *
 * Revision 1.7  1995/02/14  19:55:10  adam
 * Header files ccl.h/cclp.h are gone! They have been merged an
 * moved to ../include/ccl.h.
 * Node kind(s) in ccl_rpn_node have changed names.
 *
 * Revision 1.6  1995/02/14  16:20:55  adam
 * Qualifiers are read from a file now.
 *
 * Revision 1.5  1995/02/14  14:12:41  adam
 * Ranges for ordered qualfiers implemented (e.g. pd=1980-1990).
 *
 * Revision 1.4  1995/02/14  13:16:29  adam
 * Left and/or right truncation implemented.
 *
 * Revision 1.3  1995/02/14  10:25:56  adam
 * The constructions 'qualifier rel term ...' implemented.
 *
 * Revision 1.2  1995/02/13  15:15:07  adam
 * Added handling of qualifiers. Not finished yet.
 *
 * Revision 1.1  1995/02/13  12:35:20  adam
 * First version of CCL. Qualifiers aren't handled yet.
 *
 */

#include <stdlib.h>
#include <string.h>

#include "ccl.h"

/* returns type of current lookahead */
#define KIND (cclp->look_token->kind)

/* move one token forward */
#define ADVANCE cclp->look_token = cclp->look_token->next

/**
 * qual_val_type: test for existance of attribute type/value pair.
 * qa:     Attribute array
 * type:   Type of attribute to search for
 * value:  Value of attribute to seach for
 * return: 1 if found; 0 otherwise.
 */
static int qual_val_type (struct ccl_rpn_attr **qa, int type, int value,
                           char **attset)
{
    int i;
    struct ccl_rpn_attr *q;

    if (!qa)
        return 0;
    for (i = 0;  (q=qa[i]); i++)
        while (q)
        {
            if (q->type == type && q->kind == CCL_RPN_ATTR_NUMERIC &&
                q->value.numeric == value)
            {
                if (attset)
                    *attset = q->set;
                return 1;
            }
            q = q->next;
        }
    return 0;
}

/**
 * strxcat: concatenate strings.
 * n:      Null-terminated Destination string 
 * src:    Source string to be appended (not null-terminated)
 * len:    Length of source string.
 */
static void strxcat (char *n, const char *src, int len)
{
    while (*n)
        n++;
    while (--len >= 0)
        *n++ = *src++;
    *n = '\0';
}

/**
 * copy_token_name: Return copy of CCL token name
 * tp:      Pointer to token info.
 * return:  malloc(3) allocated copy of token name.
 */
static char *copy_token_name (struct ccl_token *tp)
{
    char *str = (char *)xmalloc (tp->len + 1);
    ccl_assert (str);
    memcpy (str, tp->name, tp->len);
    str[tp->len] = '\0';
    return str;
}

/**
 * mk_node: Create RPN node.
 * kind:   Type of node.
 * return: pointer to allocated node.
 */
static struct ccl_rpn_node *mk_node (int kind)
{
    struct ccl_rpn_node *p;
    p = (struct ccl_rpn_node *)xmalloc (sizeof(*p));
    ccl_assert (p);
    p->kind = kind;
    return p;
}

/**
 * ccl_rpn_delete: Delete RPN tree.
 * rpn:   Pointer to tree.
 */
void ccl_rpn_delete (struct ccl_rpn_node *rpn)
{
    struct ccl_rpn_attr *attr, *attr1;
    if (!rpn)
        return;
    switch (rpn->kind)
    {
    case CCL_RPN_AND:
    case CCL_RPN_OR:
    case CCL_RPN_NOT:
        ccl_rpn_delete (rpn->u.p[0]);
        ccl_rpn_delete (rpn->u.p[1]);
        break;
    case CCL_RPN_TERM:
        xfree (rpn->u.t.term);
        for (attr = rpn->u.t.attr_list; attr; attr = attr1)
        {
            attr1 = attr->next;
            if (attr->kind == CCL_RPN_ATTR_STRING)
                xfree(attr->value.str);
            if (attr->set)
                xfree (attr->set);
            xfree (attr);
        }
        break;
    case CCL_RPN_SET:
        xfree (rpn->u.setname);
        break;
    case CCL_RPN_PROX:
        ccl_rpn_delete (rpn->u.p[0]);
        ccl_rpn_delete (rpn->u.p[1]);
        ccl_rpn_delete (rpn->u.p[2]);
        break;
    }
    xfree (rpn);
}

static struct ccl_rpn_node *find_spec (CCL_parser cclp,
                                       struct ccl_rpn_attr **qa);

static int is_term_ok (int look, int *list)
{
    for (;*list >= 0; list++)
        if (look == *list)
            return 1;
    return 0;
}

static struct ccl_rpn_node *search_terms (CCL_parser cclp,
                                          struct ccl_rpn_attr **qa);

static struct ccl_rpn_attr *add_attr_node (struct ccl_rpn_node *p,
                                           const char *set, int type)
{
    struct ccl_rpn_attr *n;
    
    n = (struct ccl_rpn_attr *)xmalloc (sizeof(*n));
    ccl_assert (n);
    if (set)
    {
        n->set = (char*) xmalloc (strlen(set)+1);
        strcpy (n->set, set);
    }
    else
        n->set = 0;
    n->type = type;
    n->next = p->u.t.attr_list;
    p->u.t.attr_list = n;
    
    n->kind = CCL_RPN_ATTR_NUMERIC;
    n->value.numeric = 0;
    return n;
}

/**
 * add_attr_numeric: Add attribute (type/value) to RPN term node.
 * p:     RPN node of type term.
 * type:  Type of attribute
 * value: Value of attribute
 * set: Attribute set name
 */
static void add_attr_numeric (struct ccl_rpn_node *p, const char *set,
                              int type, int value)
{
    struct ccl_rpn_attr *n;

    n = add_attr_node(p, set, type);
    n->kind = CCL_RPN_ATTR_NUMERIC;
    n->value.numeric = value;
}

static void add_attr_string (struct ccl_rpn_node *p, const char *set,
                             int type, char *value)
{
    struct ccl_rpn_attr *n;

    n = add_attr_node(p, set, type);
    n->kind = CCL_RPN_ATTR_STRING;
    n->value.str = xstrdup(value);
}


/**
 * search_term: Parse CCL search term. 
 * cclp:   CCL Parser
 * qa:     Qualifier attributes already applied.
 * term_list: tokens we accept as terms in context
 * multi:  whether we accept "multiple" tokens
 * return: pointer to node(s); NULL on error.
 */
static struct ccl_rpn_node *search_term_x (CCL_parser cclp,
                                           struct ccl_rpn_attr **qa,
                                           int *term_list, int multi)
{
    struct ccl_rpn_node *p_top = 0;
    struct ccl_token *lookahead = cclp->look_token;
    int and_list = 0;
    int or_list = 0;
    char *attset;
    const char *truncation_aliases;

    truncation_aliases =
        ccl_qual_search_special(cclp->bibset, "truncation");
    if (!truncation_aliases)
        truncation_aliases = "?";

    if (qual_val_type (qa, CCL_BIB1_STR, CCL_BIB1_STR_AND_LIST, 0))
        and_list = 1;
    if (qual_val_type (qa, CCL_BIB1_STR, CCL_BIB1_STR_OR_LIST, 0))
        or_list = 1;
    while (1)
    {
        struct ccl_rpn_node *p;
        size_t no, i;
        int no_spaces = 0;
        int left_trunc = 0;
        int right_trunc = 0;
        int mid_trunc = 0;
        int relation_value = -1;
        int position_value = -1;
        int structure_value = -1;
        int truncation_value = -1;
        int completeness_value = -1;
        int len = 0;
        size_t max = 200;
        if (and_list || or_list || !multi)
            max = 1;
        
        /* ignore commas when dealing with and-lists .. */
        if (and_list && lookahead && lookahead->kind == CCL_TOK_COMMA)
        {
            lookahead = lookahead->next;
            ADVANCE;
            continue;
        }
        /* go through each TERM token. If no truncation attribute is yet
           met, then look for left/right truncation markers (?) and
           set left_trunc/right_trunc/mid_trunc accordingly */
        for (no = 0; no < max && is_term_ok(lookahead->kind, term_list); no++)
        {
            for (i = 0; i<lookahead->len; i++)
                if (lookahead->name[i] == ' ')
                    no_spaces++;
                else if (strchr(truncation_aliases, lookahead->name[i]))
                {
                    if (no == 0 && i == 0 && lookahead->len >= 1)
                        left_trunc = 1;
                    else if (!is_term_ok(lookahead->next->kind, term_list) &&
                             i == lookahead->len-1 && i >= 1)
                        right_trunc = 1;
                    else
                        mid_trunc = 1;
                }
            len += 1+lookahead->len+lookahead->ws_prefix_len;
            lookahead = lookahead->next;
        }

        if (len == 0)
            break;      /* no more terms . stop . */


        if (p_top)
        {
            if (or_list)
                p = mk_node (CCL_RPN_OR);
            else if (and_list)
                p = mk_node (CCL_RPN_AND);
            else
                p = mk_node (CCL_RPN_AND);
            p->u.p[0] = p_top;
            p_top = p;
        }
                
        /* create the term node, but wait a moment before adding the term */
        p = mk_node (CCL_RPN_TERM);
        p->u.t.attr_list = NULL;
        p->u.t.term = NULL;

        /* make the top node point to us.. */
        if (p_top)
            p_top->u.p[1] = p;
        else
            p_top = p;

        
        /* go through all attributes and add them to the attribute list */
        for (i=0; qa && qa[i]; i++)
        {
            struct ccl_rpn_attr *attr;
            
            for (attr = qa[i]; attr; attr = attr->next)
                switch(attr->kind)
                {
                case CCL_RPN_ATTR_STRING:
                    add_attr_string(p, attr->set, attr->type,
                                    attr->value.str);
                    break;
                case CCL_RPN_ATTR_NUMERIC:
                    if (attr->value.numeric > 0)
                    {   /* deal only with REAL attributes (positive) */
                        switch (attr->type)
                        {
                        case CCL_BIB1_REL:
                            if (relation_value != -1)
                                continue;
                            relation_value = attr->value.numeric;
                            break;
                        case CCL_BIB1_POS:
                            if (position_value != -1)
                                continue;
                            position_value = attr->value.numeric;
                            break;
                        case CCL_BIB1_STR:
                            if (structure_value != -1)
                                continue;
                            structure_value = attr->value.numeric;
                            break;
                        case CCL_BIB1_TRU:
                            if (truncation_value != -1)
                                continue;
                            truncation_value = attr->value.numeric;
                            left_trunc = right_trunc = mid_trunc = 0;
                            break;
                        case CCL_BIB1_COM:
                            if (completeness_value != -1)
                                continue;
                            completeness_value = attr->value.numeric;
                            break;
                        }
                        add_attr_numeric(p, attr->set, attr->type,
                                         attr->value.numeric);
                    }
                }
        }
        /* len now holds the number of characters in the RPN term */
        /* no holds the number of CCL tokens (1 or more) */
        
        if (structure_value == -1 && 
            qual_val_type (qa, CCL_BIB1_STR, CCL_BIB1_STR_WP, &attset))
        {   /* no structure attribute met. Apply either structure attribute 
               WORD or PHRASE depending on number of CCL tokens */
            if (no == 1 && no_spaces == 0)
                add_attr_numeric (p, attset, CCL_BIB1_STR, 2);
            else
                add_attr_numeric (p, attset, CCL_BIB1_STR, 1);
        }

        /* make the RPN token */
        p->u.t.term = (char *)xmalloc (len);
        ccl_assert (p->u.t.term);
        p->u.t.term[0] = '\0';
        for (i = 0; i<no; i++)
        {
            const char *src_str = cclp->look_token->name;
            int src_len = cclp->look_token->len;
            
            if (i == 0 && left_trunc)
            {
                src_len--;
                src_str++;
            }
            if (i == no-1 && right_trunc)
                src_len--;
            if (i && cclp->look_token->ws_prefix_len)
            {
                size_t len = strlen(p->u.t.term);
                memcpy(p->u.t.term + len, cclp->look_token->ws_prefix_buf,
                                cclp->look_token->ws_prefix_len);
                p->u.t.term[len + cclp->look_token->ws_prefix_len] = '\0';
            }
            strxcat (p->u.t.term, src_str, src_len);
            ADVANCE;
        }
        if (left_trunc && right_trunc)
        {
            if (!qual_val_type (qa, CCL_BIB1_TRU, CCL_BIB1_TRU_CAN_BOTH,
                                &attset))
            {
                cclp->error_code = CCL_ERR_TRUNC_NOT_BOTH;
                ccl_rpn_delete (p);
                return NULL;
            }
            add_attr_numeric (p, attset, CCL_BIB1_TRU, 3);
        }
        else if (right_trunc)
        {
            if (!qual_val_type (qa, CCL_BIB1_TRU, CCL_BIB1_TRU_CAN_RIGHT,
                                 &attset))
            {
                cclp->error_code = CCL_ERR_TRUNC_NOT_RIGHT;
                ccl_rpn_delete (p);
                return NULL;
            }
            add_attr_numeric (p, attset, CCL_BIB1_TRU, 1);
        }
        else if (left_trunc)
        {
            if (!qual_val_type (qa, CCL_BIB1_TRU, CCL_BIB1_TRU_CAN_LEFT,
                                &attset))
            {
                cclp->error_code = CCL_ERR_TRUNC_NOT_LEFT;
                ccl_rpn_delete (p);
                return NULL;
            }
            add_attr_numeric (p, attset, CCL_BIB1_TRU, 2);
        }
        else
        {
            if (qual_val_type (qa, CCL_BIB1_TRU, CCL_BIB1_TRU_CAN_NONE,
                               &attset))
                add_attr_numeric (p, attset, CCL_BIB1_TRU, 100);
        }
        if (!multi)
            break;
    }
    if (!p_top)
        cclp->error_code = CCL_ERR_TERM_EXPECTED;
    return p_top;
}

static struct ccl_rpn_node *search_term (CCL_parser cclp,
                                         struct ccl_rpn_attr **qa)
{
    static int list[] = {CCL_TOK_TERM, CCL_TOK_COMMA, -1};
    return search_term_x(cclp, qa, list, 0);
}

static
struct ccl_rpn_node *qualifiers_order (CCL_parser cclp,
                                       struct ccl_rpn_attr **ap, char *attset)
{
    int rel = 0;
    struct ccl_rpn_node *p;

    if (cclp->look_token->len == 1)
    {
        if (cclp->look_token->name[0] == '<')
            rel = 1;
        else if (cclp->look_token->name[0] == '=')
            rel = 3;
        else if (cclp->look_token->name[0] == '>')
            rel = 5;
    }
    else if (cclp->look_token->len == 2)
    {
        if (!memcmp (cclp->look_token->name, "<=", 2))
            rel = 2;
        else if (!memcmp (cclp->look_token->name, ">=", 2))
            rel = 4;
        else if (!memcmp (cclp->look_token->name, "<>", 2))
            rel = 6;
    }
    if (!rel)
    {
        cclp->error_code = CCL_ERR_BAD_RELATION;
        return NULL;
    }
    ADVANCE;  /* skip relation */
    if (rel == 3 &&
        qual_val_type(ap, CCL_BIB1_REL, CCL_BIB1_REL_PORDER, 0))
    {
        /* allow - inside term and treat it as range _always_ */
        /* relation is =. Extract "embedded" - to separate terms */
        if (KIND == CCL_TOK_TERM)
        {
            size_t i;
            for (i = 0; i<cclp->look_token->len; i++)
            {
                if (cclp->look_token->name[i] == '-')
                    break;
            }
            
            if (cclp->look_token->len > 1 && i == 0)
            {   /*  -xx*/
                struct ccl_token *ntoken = ccl_token_add (cclp->look_token);

                ntoken->kind = CCL_TOK_TERM;
                ntoken->name = cclp->look_token->name + 1;
                ntoken->len = cclp->look_token->len - 1;

                cclp->look_token->len = 1;
                cclp->look_token->name = "-";
            }
            else if (cclp->look_token->len > 1 && i == cclp->look_token->len-1)
            {   /* xx- */
                struct ccl_token *ntoken = ccl_token_add (cclp->look_token);

                ntoken->kind = CCL_TOK_TERM;
                ntoken->name = "-";
                ntoken->len = 1;

                (cclp->look_token->len)--;
            }
            else if (cclp->look_token->len > 2 && i < cclp->look_token->len)
            {   /* xx-yy */
                struct ccl_token *ntoken1 = ccl_token_add (cclp->look_token);
                struct ccl_token *ntoken2 = ccl_token_add (ntoken1);

                ntoken1->kind = CCL_TOK_TERM;  /* generate - */
                ntoken1->name = "-";
                ntoken1->len = 1;

                ntoken2->kind = CCL_TOK_TERM;  /* generate yy */
                ntoken2->name = cclp->look_token->name + (i+1);
                ntoken2->len = cclp->look_token->len - (i+1);

                cclp->look_token->len = i;     /* adjust xx */
            }
            else if (i == cclp->look_token->len &&
                     cclp->look_token->next &&
                     cclp->look_token->next->kind == CCL_TOK_TERM &&
                     cclp->look_token->next->len > 1 &&
                     cclp->look_token->next->name[0] == '-')
                     
            {   /* xx -yy */
                /* we _know_ that xx does not have - in it */
                struct ccl_token *ntoken = ccl_token_add (cclp->look_token);

                ntoken->kind = CCL_TOK_TERM;    /* generate - */
                ntoken->name = "-";
                ntoken->len = 1;

                (ntoken->next->name)++;        /* adjust yy */
                (ntoken->next->len)--; 
            }
        }
    }
        
    if (rel == 3 &&
        KIND == CCL_TOK_TERM &&
        cclp->look_token->next && cclp->look_token->next->len == 1 &&
        cclp->look_token->next->name[0] == '-')
    {
        struct ccl_rpn_node *p1;
        if (!(p1 = search_term (cclp, ap)))
            return NULL;
        ADVANCE;                   /* skip '-' */
        if (KIND == CCL_TOK_TERM)  /* = term - term  ? */
        {
            struct ccl_rpn_node *p2;
            
            if (!(p2 = search_term (cclp, ap)))
            {
                ccl_rpn_delete (p1);
                return NULL;
            }
            p = mk_node (CCL_RPN_AND);
            p->u.p[0] = p1;
            add_attr_numeric (p1, attset, CCL_BIB1_REL, 4);
            p->u.p[1] = p2;
            add_attr_numeric (p2, attset, CCL_BIB1_REL, 2);
            return p;
        }
        else                       /* = term -    */
        {
            add_attr_numeric (p1, attset, CCL_BIB1_REL, 4);
            return p1;
        }
    }
    else if (rel == 3 &&
             cclp->look_token->len == 1 &&
             cclp->look_token->name[0] == '-')   /* = - term  ? */
    {
        ADVANCE;
        if (!(p = search_term (cclp, ap)))
            return NULL;
        add_attr_numeric (p, attset, CCL_BIB1_REL, 2);
        return p;
    }
    else if (KIND == CCL_TOK_LP)
    {
        ADVANCE;
        if (!(p = find_spec (cclp, ap)))
            return NULL;
        if (KIND != CCL_TOK_RP)
        {
            cclp->error_code = CCL_ERR_RP_EXPECTED;
            ccl_rpn_delete (p);
            return NULL;
        }
        ADVANCE;
        return p;
    }
    else
    {
        if (!(p = search_terms (cclp, ap)))
            return NULL;
        add_attr_numeric (p, attset, CCL_BIB1_REL, rel);
        return p;
    }
    cclp->error_code = CCL_ERR_TERM_EXPECTED;
    return NULL;
}

static
struct ccl_rpn_node *qualifiers2 (CCL_parser cclp, struct ccl_rpn_attr **ap)
{
    char *attset;
    struct ccl_rpn_node *p;
    
    if (qual_val_type(ap, CCL_BIB1_REL, CCL_BIB1_REL_ORDER, &attset)
        || qual_val_type(ap, CCL_BIB1_REL, CCL_BIB1_REL_PORDER, &attset))
        return qualifiers_order(cclp, ap, attset);

    /* unordered relation */
    if (KIND != CCL_TOK_EQ)
    {
        cclp->error_code = CCL_ERR_EQ_EXPECTED;
        return NULL;
    }
    ADVANCE;
    if (KIND == CCL_TOK_LP)
    {
        ADVANCE;
        if (!(p = find_spec (cclp, ap)))
        {
            return NULL;
        }
        if (KIND != CCL_TOK_RP)
        {
            cclp->error_code = CCL_ERR_RP_EXPECTED;
            ccl_rpn_delete (p);
            return NULL;
        }
        ADVANCE;
    }
    else
        p = search_terms (cclp, ap);
    return p;
}

/**
 * qualifiers1: Parse CCL qualifiers and search terms. 
 * cclp:   CCL Parser
 * la:     Token pointer to RELATION token.
 * qa:     Qualifier attributes already applied.
 * return: pointer to node(s); NULL on error.
 */
static struct ccl_rpn_node *qualifiers1 (CCL_parser cclp, struct ccl_token *la,
                                         struct ccl_rpn_attr **qa)
{
    struct ccl_token *lookahead = cclp->look_token;
    struct ccl_token *look_start = cclp->look_token;
    struct ccl_rpn_attr **ap;
    struct ccl_rpn_node *node = 0;
    const char *field_str;
    int no = 0;
    int seq = 0;
    int i;
    int mode_merge = 1;
#if 0
    if (qa)
    {
        cclp->error_code = CCL_ERR_DOUBLE_QUAL;
        return NULL;
    }
#endif
    for (lookahead = cclp->look_token; lookahead != la;
         lookahead=lookahead->next)
        no++;
    if (qa)
        for (i=0; qa[i]; i++)
            no++;
    ap = (struct ccl_rpn_attr **)xmalloc ((no ? (no+1) : 2) * sizeof(*ap));
    ccl_assert (ap);

    field_str = ccl_qual_search_special(cclp->bibset, "field");
    if (field_str)
    {
        if (!strcmp (field_str, "or"))
            mode_merge = 0;
        else if (!strcmp (field_str, "merge"))
            mode_merge = 1;
    }
    if (!mode_merge)
    {
        /* consider each field separately and OR */
        lookahead = look_start;
        while (lookahead != la)
        {
            ap[1] = 0;
            seq = 0;
            while ((ap[0] = ccl_qual_search (cclp, lookahead->name,
                                             lookahead->len, seq)) != 0)
            {
                struct ccl_rpn_node *node_sub;
                cclp->look_token = la;
                
                node_sub = qualifiers2(cclp, ap);
                if (!node_sub)
                {
                    ccl_rpn_delete (node);
                    xfree (ap);
                    return 0;
                }
                if (node)
                {
                    struct ccl_rpn_node *node_this = mk_node(CCL_RPN_OR);
                    node_this->u.p[0] = node;
                    node_this->u.p[1] = node_sub;
                    node = node_this;
                }
                else
                    node = node_sub;
                seq++;
            }
            if (seq == 0)
            {
                cclp->look_token = lookahead;
                cclp->error_code = CCL_ERR_UNKNOWN_QUAL;
                xfree (ap);
                return NULL;
            }
            lookahead = lookahead->next;
            if (lookahead->kind == CCL_TOK_COMMA)
                lookahead = lookahead->next;
        }
    }
    else
    {
        /* merge attributes from ALL fields - including inherited ones */
        while (1)
        {
            struct ccl_rpn_node *node_sub;
            int found = 0;
            lookahead = look_start;
            for (i = 0; lookahead != la; i++)
            {
                ap[i] = ccl_qual_search (cclp, lookahead->name,
                                         lookahead->len, seq);
                if (ap[i])
                    found++;
                if (!ap[i] && seq > 0)
                    ap[i] = ccl_qual_search (cclp, lookahead->name,
                                             lookahead->len, 0);
                if (!ap[i])
                {
                    cclp->look_token = lookahead;
                    cclp->error_code = CCL_ERR_UNKNOWN_QUAL;
                    xfree (ap);
                    return NULL;
                }
                lookahead = lookahead->next;
                if (lookahead->kind == CCL_TOK_COMMA)
                    lookahead = lookahead->next;
            }
            if (qa)
            {
                struct ccl_rpn_attr **qa0 = qa;
                
                while (*qa0)
                    ap[i++] = *qa0++;
            }
            ap[i] = NULL;
            
            if (!found)
                break;
            
            cclp->look_token = lookahead;
            
            node_sub = qualifiers2(cclp, ap);
            if (!node_sub)
            {
                ccl_rpn_delete (node);
                break;
            }
            if (node)
            {
                struct ccl_rpn_node *node_this = mk_node(CCL_RPN_OR);
                node_this->u.p[0] = node;
                node_this->u.p[1] = node_sub;
                node = node_this;
            }
            else
                node = node_sub;
            seq++;
        }
    }
    xfree (ap);
    return node;
}


/**
 * search_terms: Parse CCL search terms - including proximity.
 * cclp:   CCL Parser
 * qa:     Qualifier attributes already applied.
 * return: pointer to node(s); NULL on error.
 */
static struct ccl_rpn_node *search_terms (CCL_parser cclp,
                                          struct ccl_rpn_attr **qa)
{
    static int list[] = {
        CCL_TOK_TERM, CCL_TOK_COMMA,CCL_TOK_EQ, CCL_TOK_REL, CCL_TOK_SET, -1};
    struct ccl_rpn_node *p1, *p2, *pn;
    p1 = search_term_x (cclp, qa, list, 1);
    if (!p1)
        return NULL;
    while (1)
    {
        if (KIND == CCL_TOK_PROX)
        {
            struct ccl_rpn_node *p_prox = 0;
            /* ! word order specified */
            /* % word order not specified */
            p_prox = mk_node(CCL_RPN_TERM);
            p_prox->u.t.term = (char *) xmalloc(1 + cclp->look_token->len);
            memcpy(p_prox->u.t.term, cclp->look_token->name,
                   cclp->look_token->len);
            p_prox->u.t.term[cclp->look_token->len] = 0;
            p_prox->u.t.attr_list = 0;

            ADVANCE;
            p2 = search_term_x (cclp, qa, list, 1);
            if (!p2)
            {
                ccl_rpn_delete (p1);
                return NULL;
            }
            pn = mk_node (CCL_RPN_PROX);
            pn->u.p[0] = p1;
            pn->u.p[1] = p2;
            pn->u.p[2] = p_prox;
            p1 = pn;
        }
        else if (is_term_ok(KIND, list))
        {
            p2 = search_term_x (cclp, qa, list, 1);
            if (!p2)
            {
                ccl_rpn_delete (p1);
                return NULL;
            }
            pn = mk_node (CCL_RPN_PROX);
            pn->u.p[0] = p1;
            pn->u.p[1] = p2;
            pn->u.p[2] = 0;
            p1 = pn;
        }
        else
            break;
    }
    return p1;
}

/**
 * search_elements: Parse CCL search elements
 * cclp:   CCL Parser
 * qa:     Qualifier attributes already applied.
 * return: pointer to node(s); NULL on error.
 */
static struct ccl_rpn_node *search_elements (CCL_parser cclp,
                                             struct ccl_rpn_attr **qa)
{
    struct ccl_rpn_node *p1;
    struct ccl_token *lookahead;
    if (KIND == CCL_TOK_LP)
    {
        ADVANCE;
        p1 = find_spec (cclp, qa);
        if (!p1)
            return NULL;
        if (KIND != CCL_TOK_RP)
        {
            cclp->error_code = CCL_ERR_RP_EXPECTED;
            ccl_rpn_delete (p1);
            return NULL;
        }
        ADVANCE;
        return p1;
    }
    else if (KIND == CCL_TOK_SET)
    {
        ADVANCE;
        if (KIND == CCL_TOK_EQ)
            ADVANCE;
        if (KIND != CCL_TOK_TERM)
        {
            cclp->error_code = CCL_ERR_SETNAME_EXPECTED;
            return NULL;
        }
        p1 = mk_node (CCL_RPN_SET);
        p1->u.setname = copy_token_name (cclp->look_token);
        ADVANCE;
        return p1;
    }
    lookahead = cclp->look_token;

    while (lookahead->kind==CCL_TOK_TERM)
    {
        lookahead = lookahead->next;
        if (lookahead->kind == CCL_TOK_REL || lookahead->kind == CCL_TOK_EQ)
            return qualifiers1 (cclp, lookahead, qa);
        if (lookahead->kind != CCL_TOK_COMMA)
            break;
        lookahead = lookahead->next;
    }
    if (qa)
        return search_terms (cclp, qa);
    else
    {
        struct ccl_rpn_attr *qa[2];
        struct ccl_rpn_node *node = 0;
        int seq;
        lookahead = cclp->look_token;

        qa[1] = 0;
        for(seq = 0; ;seq++)
        {
            struct ccl_rpn_node *node_sub;
            qa[0] = ccl_qual_search(cclp, "term", 4, seq);
            if (!qa[0])
                break;

            cclp->look_token = lookahead;

            node_sub = search_terms (cclp, qa);
            if (!node_sub)
            {
                ccl_rpn_delete (node);
                return 0;
            }
            if (node)
            {
                struct ccl_rpn_node *node_this = mk_node(CCL_RPN_OR);
                node_this->u.p[0] = node;
                node_this->u.p[1] = node_sub;
                node_this->u.p[2] = 0;
                node = node_this;
            }
            else
                node = node_sub;
        }
        if (!node)
            node = search_terms (cclp, 0);
        return node;
    }
}

/**
 * find_spec: Parse CCL find specification
 * cclp:   CCL Parser
 * qa:     Qualifier attributes already applied.
 * return: pointer to node(s); NULL on error.
 */
static struct ccl_rpn_node *find_spec (CCL_parser cclp,
                                       struct ccl_rpn_attr **qa)
{
    struct ccl_rpn_node *p1, *p2, *pn;
    if (!(p1 = search_elements (cclp, qa)))
        return NULL;
    while (1)
    {
        switch (KIND)
        {
        case CCL_TOK_AND:
            ADVANCE;
            p2 = search_elements (cclp, qa);
            if (!p2)
            {
                ccl_rpn_delete (p1);
                return NULL;
            }
            pn = mk_node (CCL_RPN_AND);
            pn->u.p[0] = p1;
            pn->u.p[1] = p2;
            pn->u.p[2] = 0;
            p1 = pn;
            continue;
        case CCL_TOK_OR:
            ADVANCE;
            p2 = search_elements (cclp, qa);
            if (!p2)
            {
                ccl_rpn_delete (p1);
                return NULL;
            }
            pn = mk_node (CCL_RPN_OR);
            pn->u.p[0] = p1;
            pn->u.p[1] = p2;
            pn->u.p[2] = 0;
            p1 = pn;
            continue;
        case CCL_TOK_NOT:
            ADVANCE;
            p2 = search_elements (cclp, qa);
            if (!p2)
            {
                ccl_rpn_delete (p1);
                return NULL;
            }
            pn = mk_node (CCL_RPN_NOT);
            pn->u.p[0] = p1;
            pn->u.p[1] = p2;
            pn->u.p[2] = 0;
            p1 = pn;
            continue;
        }
        break;
    }
    return p1;
}

struct ccl_rpn_node *ccl_parser_find (CCL_parser cclp, struct ccl_token *list)
{
    struct ccl_rpn_node *p;

    cclp->look_token = list;
    p = find_spec (cclp, NULL);
    if (p && KIND != CCL_TOK_EOL)
    {
        if (KIND == CCL_TOK_RP)
            cclp->error_code = CCL_ERR_BAD_RP;
        else
            cclp->error_code = CCL_ERR_OP_EXPECTED;
        ccl_rpn_delete (p);
        p = NULL;
    }
    cclp->error_pos = cclp->look_token->name;
    if (p)
        cclp->error_code = CCL_ERR_OK;
    else
        cclp->error_code = cclp->error_code;
    return p;
}

/**
 * ccl_find: Parse CCL find - token representation
 * bibset:  Bibset to be used for the parsing
 * list:    List of tokens
 * error:   Pointer to integer. Holds error no. on completion.
 * pos:     Pointer to char position. Holds approximate error position.
 * return:  RPN tree on successful completion; NULL otherwise.
 */
struct ccl_rpn_node *ccl_find (CCL_bibset bibset, struct ccl_token *list,
                               int *error, const char **pos)
{
    struct ccl_rpn_node *p;
    CCL_parser cclp = ccl_parser_create ();

    cclp->bibset = bibset;

    p = ccl_parser_find (cclp, list);

    *error = cclp->error_code;
    *pos = cclp->error_pos;

    ccl_parser_destroy (cclp);

    return p;
}

/**
 * ccl_find_str: Parse CCL find - string representation
 * bibset:  Bibset to be used for the parsing
 * str:     String to be parsed
 * error:   Pointer to integer. Holds error no. on completion.
 * pos:     Pointer to char position. Holds approximate error position.
 * return:  RPN tree on successful completion; NULL otherwise.
 */
struct ccl_rpn_node *ccl_find_str (CCL_bibset bibset, const char *str,
                                   int *error, int *pos)
{
    CCL_parser cclp = ccl_parser_create ();
    struct ccl_token *list;
    struct ccl_rpn_node *p;

    cclp->bibset = bibset;

    list = ccl_parser_tokenize (cclp, str);
    p = ccl_parser_find (cclp, list);

    *error = cclp->error_code;
    if (*error)
        *pos = cclp->error_pos - str;
    ccl_parser_destroy (cclp);
    ccl_token_del (list);
    return p;
}
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

