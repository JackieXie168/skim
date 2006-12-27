/* $Id: xcqlutil.c,v 1.6 2005/06/25 15:46:06 adam Exp $
   Copyright (C) 1995-2005, Index Data ApS
   Index Data Aps

This file is part of the YAZ toolkit.

See the file LICENSE.
*/

/**
 * \file xcqlutil.c
 * \brief Implements CQL to XCQL conversion.
 */

#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#include "cql.h"

static void pr_n(const char *buf, 
                void (*pr)(const char *buf, void *client_data),
                void *client_data, int n)
{
    int i;
    for (i = 0; i<n; i++)
        (*pr)(" ", client_data);
    (*pr)(buf, client_data);
}

static void pr_cdata(const char *buf,
                     void (*pr)(const char *buf, void *client_data),
                     void *client_data)
{
    const char *src = buf;
    char bf[2];
    while (*src)
    {
        switch(*src)
        {
        case '&':
            (*pr)("&amp;", client_data);
            break;
        case '<':
            (*pr)("&lt;", client_data);
            break;
        case '>':
            (*pr)("&gt;", client_data);
            break;
        default:
            bf[0] = *src;
            bf[1] = 0;
            (*pr)(bf, client_data);
        }
        src++;
    }
}
                    
static void prefixes(struct cql_node *cn,
                     void (*pr)(const char *buf, void *client_data),
                     void *client_data, int level)
{
    int head = 0;
    if (cn->u.st.index_uri)
    {
        pr_n("<prefixes>\n", pr, client_data, level);
        head = 1;

        pr_n("<prefix>\n", pr, client_data, level+2);
        pr_n("<identifier>", pr, client_data, level+4);
        pr_cdata(cn->u.st.index_uri, pr, client_data);
        pr_n("</identifier>\n", pr, client_data, 0);
        pr_n("</prefix>\n", pr, client_data, level+2);
    }
    if (cn->u.st.relation_uri && cn->u.st.relation)
    {
        if (!head)
            pr_n("<prefixes>\n", pr, client_data, level);
        pr_n("<prefix>\n", pr, client_data, level+2);
        pr_n("<name>", pr, client_data, level+4);
        pr_cdata("rel", pr, client_data);
        pr_n("</name>\n", pr, client_data, 0);
        pr_n("<identifier>", pr, client_data, level+4);
        pr_cdata(cn->u.st.relation_uri, pr, client_data);
        pr_n("</identifier>\n", pr, client_data, 0);
        pr_n("</prefix>\n", pr, client_data, level+2);
    }
    if (head)
        pr_n("</prefixes>\n", pr, client_data, level);
}
                     
static void cql_to_xml_mod(struct cql_node *m,
                           void (*pr)(const char *buf, void *client_data),
                           void *client_data, int level)
{
    if (m)
    {
        pr_n("<modifiers>\n", pr, client_data, level);
        for (; m; m = m->u.st.modifiers)
        {
            pr_n("<modifier>\n", pr, client_data, level+2);
            pr_n("<type>", pr, client_data, level+4);
            pr_cdata(m->u.st.index, pr, client_data);
            pr_n("</type>\n", pr, client_data, 0);
            if (m->u.st.relation)
            {
                pr_n("<relation>", pr, client_data, level+4);
                pr_cdata(m->u.st.relation, pr, client_data);
                pr_n("</relation>\n", pr, client_data, 0);
            }
            if (m->u.st.term)
            {
                pr_n("<value>", pr, client_data, level+4);
                pr_cdata(m->u.st.term, pr, client_data);
                pr_n("</value>\n", pr, client_data, 0);
            }
            pr_n("</modifier>\n", pr, client_data, level+2);
        }
        pr_n("</modifiers>\n", pr, client_data, level);
    }
}

static void cql_to_xml_r(struct cql_node *cn,
                         void (*pr)(const char *buf, void *client_data),
                         void *client_data, int level)
{
    if (!cn)
        return;
    switch (cn->which)
    {
    case CQL_NODE_ST:
        pr_n("<searchClause>\n", pr, client_data, level);
        prefixes(cn, pr, client_data, level+2);
        if (cn->u.st.index)
        {
            pr_n("<index>", pr, client_data, level+2);
            pr_cdata(cn->u.st.index, pr, client_data);
            pr_n("</index>\n", pr, client_data, 0);
        }
        if (cn->u.st.relation)
        {
            pr_n("<relation>\n", pr, client_data, level+2);
            pr_n("<value>", pr, client_data, level+4);
            if (cn->u.st.relation_uri)
                pr_cdata("rel.", pr, client_data);
            pr_cdata(cn->u.st.relation, pr, client_data);
            pr_n("</value>\n", pr, client_data, 0);

            if (cn->u.st.relation_uri)
            {
                pr_n("<identifier>", pr, client_data, level+4);
                pr_cdata(cn->u.st.relation_uri, pr, client_data);
                pr_n("</identifier>\n", pr, client_data, 0);
            }
            cql_to_xml_mod(cn->u.st.modifiers,
                           pr, client_data, level+4);

            pr_n("</relation>\n", pr, client_data, level+2);
        }
        if (cn->u.st.term)
        {
            pr_n("<term>", pr, client_data, level+2);
            pr_cdata(cn->u.st.term, pr, client_data);
            pr_n("</term>\n", pr, client_data, 0);
        }
        pr_n("</searchClause>\n", pr, client_data, level);
        break;
    case CQL_NODE_BOOL:
        pr_n("<triple>\n", pr, client_data, level);
        if (cn->u.boolean.value)
        {
            pr_n("<boolean>\n", pr, client_data, level+2);

            pr_n("<value>", pr, client_data, level+4);
            pr_cdata(cn->u.boolean.value, pr, client_data);
            pr_n("</value>\n", pr, client_data, 0);

            cql_to_xml_mod(cn->u.boolean.modifiers,
                           pr, client_data, level+4);

            pr_n("</boolean>\n", pr, client_data, level+2);
        }
        if (cn->u.boolean.left)
        {
            printf ("%*s<leftOperand>\n", level+2, "");
            cql_to_xml_r(cn->u.boolean.left, pr, client_data, level+4);
            printf ("%*s</leftOperand>\n", level+2, "");
        }
        if (cn->u.boolean.right)
        {
            printf ("%*s<rightOperand>\n", level+2, "");
            cql_to_xml_r(cn->u.boolean.right, pr, client_data, level+4);
            printf ("%*s</rightOperand>\n", level+2, "");
        }
        pr_n("</triple>\n", pr, client_data, level);
    }
}

void cql_to_xml(struct cql_node *cn, 
                void (*pr)(const char *buf, void *client_data),
                void *client_data)
{
    cql_to_xml_r(cn, pr, client_data, 0);
}

void cql_to_xml_stdio(struct cql_node *cn, FILE *f)
{
    cql_to_xml(cn, cql_fputs, f);
}

void cql_buf_write_handler (const char *b, void *client_data)
{
    struct cql_buf_write_info *info = (struct cql_buf_write_info *)client_data;
    int l = strlen(b);
    if (info->off < 0 || (info->off + l >= info->max))
    {
        info->off = -1;
        return;
    }
    memcpy (info->buf + info->off, b, l);
    info->off += l;
}

int cql_to_xml_buf(struct cql_node *cn, char *out, int max)
{
    struct cql_buf_write_info info;
    info.off = 0;
    info.max = max;
    info.buf = out;
    cql_to_xml(cn, cql_buf_write_handler, &info);
    if (info.off >= 0)
        info.buf[info.off] = '\0';
    return info.off;
}

/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

