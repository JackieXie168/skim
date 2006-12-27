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
 * \file cclqual.c
 * \brief Implements CCL qualifier utilities
 */
/* CCL qualifiers
 * Europagate, 1995
 *
 * $Id: cclqual.c,v 1.3 2005/06/25 15:46:03 adam Exp $
 *
 * Old Europagate Log:
 *
 * Revision 1.9  1995/05/16  09:39:27  adam
 * LICENSE.
 *
 * Revision 1.8  1995/05/11  14:03:57  adam
 * Changes in the reading of qualifier(s). New function: ccl_qual_fitem.
 * New variable ccl_case_sensitive, which controls whether reserved
 * words and field names are case sensitive or not.
 *
 * Revision 1.7  1995/04/17  09:31:46  adam
 * Improved handling of qualifiers. Aliases or reserved words.
 *
 * Revision 1.6  1995/02/23  08:32:00  adam
 * Changed header.
 *
 * Revision 1.4  1995/02/14  19:55:12  adam
 * Header files ccl.h/cclp.h are gone! They have been merged an
 * moved to ../include/ccl.h.
 * Node kind(s) in ccl_rpn_node have changed names.
 *
 * Revision 1.3  1995/02/14  16:20:56  adam
 * Qualifiers are read from a file now.
 *
 * Revision 1.2  1995/02/14  10:25:56  adam
 * The constructions 'qualifier rel term ...' implemented.
 *
 * Revision 1.1  1995/02/13  15:15:07  adam
 * Added handling of qualifiers. Not finished yet.
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "ccl.h"

/** Definition of CCL_bibset pointer */
struct ccl_qualifiers {
    struct ccl_qualifier *list;
    struct ccl_qualifier_special *special;
};


/** CCL Qualifier special */
struct ccl_qualifier_special {
    char *name;
    char *value;
    struct ccl_qualifier_special *next;
};


static struct ccl_qualifier *ccl_qual_lookup (CCL_bibset b,
                                              const char *n, size_t len)
{
    struct ccl_qualifier *q;
    for (q = b->list; q; q = q->next)
        if (len == strlen(q->name) && !memcmp (q->name, n, len))
            break;
    return q;
}


void ccl_qual_add_special (CCL_bibset bibset, const char *n, const char *v)
{
    struct ccl_qualifier_special *p;
    const char *pe;

    for (p = bibset->special; p && strcmp(p->name, n); p = p->next)
        ;
    if (p)
        xfree (p->value);
    else
    {
        p = (struct ccl_qualifier_special *) xmalloc (sizeof(*p));
        p->name = ccl_strdup (n);
        p->value = 0;
        p->next = bibset->special;
        bibset->special = p;
    }
    while (strchr(" \t", *v))
        ++v;
    for (pe = v + strlen(v); pe != v; --pe)
        if (!strchr(" \n\r\t", pe[-1]))
            break;
    p->value = (char*) xmalloc (pe - v + 1);
    if (pe - v)
        memcpy (p->value, v, pe - v);
    p->value[pe - v] = '\0';
}

static int next_token(const char **cpp, const char **dst)
{
    int len = 0;
    const char *cp = *cpp;
    while (*cp && strchr(" \r\n\t\f", *cp))
        cp++;
    if (dst)
        *dst = cp;
    len = 0;
    while (*cp && !strchr(" \r\n\t\f", *cp))
    {
        cp++;
        len++;
    }
    *cpp = cp;
    return len;
}

void ccl_qual_add_combi (CCL_bibset b, const char *n, const char *names)
{
    const char *cp, *cp1;
    int i, len;
    struct ccl_qualifier *q;
    for (q = b->list; q && strcmp(q->name, n); q = q->next)
        ;
    if (q)
        return ;
    q = (struct ccl_qualifier *) xmalloc (sizeof(*q));
    q->name = ccl_strdup (n);
    q->attr_list = 0;
    q->next = b->list;
    b->list = q;
    
    cp = names;
    for (i = 0; next_token(&cp, 0); i++)
        ;
    q->no_sub = i;
    q->sub = (struct ccl_qualifier **) xmalloc (sizeof(*q->sub) *
                                               (1+q->no_sub));
    cp = names;
    for (i = 0; (len = next_token(&cp, &cp1)); i++)
    {
        q->sub[i] = ccl_qual_lookup (b, cp1, len);
    }
}

/**
 * ccl_qual_add: Add qualifier to Bibset. If qualifier already
 *               exists, then attributes are appendend to old
 *               definition.
 * name:    name of qualifier
 * no:      No of attribute type/value pairs.
 * pairs:   Attributes. pairs[0] first type, pair[1] first value,
 *          ... pair[2*no-2] last type, pair[2*no-1] last value.
 */

void ccl_qual_add_set (CCL_bibset b, const char *name, int no,
                       int *type_ar, int *value_ar, char **svalue_ar,
                       char **attsets)
{
    struct ccl_qualifier *q;
    struct ccl_rpn_attr **attrp;

    ccl_assert (b);
    for (q = b->list; q; q = q->next)
        if (!strcmp (name, q->name))
            break;
    if (!q)
    {
        struct ccl_qualifier *new_qual =
            (struct ccl_qualifier *)xmalloc (sizeof(*new_qual));
        ccl_assert (new_qual);
        
        new_qual->next = b->list;
        b->list = new_qual;
        
        new_qual->name = ccl_strdup (name);
        attrp = &new_qual->attr_list;

        new_qual->no_sub = 0;
        new_qual->sub = 0;
    }
    else
    {
        if (q->sub)  /* suspect.. */
            xfree (q->sub);
        attrp = &q->attr_list;
        while (*attrp)
            attrp = &(*attrp)->next;
    }
    while (--no >= 0)
    {
        struct ccl_rpn_attr *attr;

        attr = (struct ccl_rpn_attr *)xmalloc (sizeof(*attr));
        ccl_assert (attr);
        attr->set = *attsets++;
        attr->type = *type_ar++;
        if (*svalue_ar)
        {
            attr->kind = CCL_RPN_ATTR_STRING;
            attr->value.str = *svalue_ar;
        }
        else
        {
            attr->kind = CCL_RPN_ATTR_NUMERIC;
            attr->value.numeric = *value_ar;
        }
        svalue_ar++;
        value_ar++;
        *attrp = attr;
        attrp = &attr->next;
    }
    *attrp = NULL;
}

/**
 * ccl_qual_mk: Make new (empty) bibset.
 * return:   empty bibset.
 */
CCL_bibset ccl_qual_mk (void)
{
    CCL_bibset b = (CCL_bibset)xmalloc (sizeof(*b));
    ccl_assert (b);
    b->list = NULL;     
    b->special = NULL;
    return b;
}

/**
 * ccl_qual_rm: Delete bibset.
 * b:        pointer to bibset
 */
void ccl_qual_rm (CCL_bibset *b)
{
    struct ccl_qualifier *q, *q1;
    struct ccl_qualifier_special *sp, *sp1;

    if (!*b)
        return;
    for (q = (*b)->list; q; q = q1)
    {
        struct ccl_rpn_attr *attr, *attr1;

        for (attr = q->attr_list; attr; attr = attr1)
        {
            attr1 = attr->next;
            if (attr->set)
                xfree(attr->set);
            if (attr->kind == CCL_RPN_ATTR_STRING)
                xfree(attr->value.str);
            xfree (attr);
        }
        q1 = q->next;
        xfree (q->name);
        if (q->sub)
            xfree (q->sub);
        xfree (q);
    }
    for (sp = (*b)->special; sp; sp = sp1)
    {
        sp1 = sp->next;
        xfree (sp->name);
        xfree (sp->value);
        xfree (sp);
    }
    xfree (*b);
    *b = NULL;
}

/**
 * ccl_qual_search: Search for qualifier in bibset.
 * b:      Bibset
 * name:   Name of qualifier to search for (need no null-termination)
 * len:    Length of name.
 * return: Attribute info. NULL if not found.
 */
struct ccl_rpn_attr *ccl_qual_search (CCL_parser cclp,
                                      const char *name, size_t len,
                                      int seq)
{
    struct ccl_qualifier *q;
    const char *aliases;
    int case_sensitive = cclp->ccl_case_sensitive;

    ccl_assert (cclp);
    if (!cclp->bibset)
        return NULL;

    aliases = ccl_qual_search_special(cclp->bibset, "case");
    if (aliases)
        case_sensitive = atoi(aliases);

    for (q = cclp->bibset->list; q; q = q->next)
        if (strlen(q->name) == len)
        {
            if (case_sensitive)
            {
                if (!memcmp (name, q->name, len))
                    break;
            }
            else
            {
                if (!ccl_memicmp (name, q->name, len))
                    break;
            }
        }
    if (q)
    {
        if (q->attr_list && seq == 0)
            return q->attr_list;
        if (seq < q->no_sub && q->sub[seq])
        {
            return q->sub[seq]->attr_list;
        }
    }
    return 0;
}

const char *ccl_qual_search_special (CCL_bibset b,
                                     const char *name)
{
    struct ccl_qualifier_special *q;
    if (!b)
        return 0;
    for (q = b->special; q && strcmp(q->name, name); q = q->next)
        ;
    if (q)
        return q->value;
    return 0;
}
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

