/*
 * Copyright (C) 1995-2007, Index Data ApS
 * All rights reserved.
 *
 * $Id: cclxmlconfig.c,v 1.1 2007/01/08 13:20:58 adam Exp $
 */

/** \file cclxmlconfig.c
    \brief XML configuration for CCL
*/

#include <stdio.h>
#include <string.h>
#include <assert.h>

#include <yaz/ccl_xml.h>

#if YAZ_HAVE_XML2

static int ccl_xml_config_attr(CCL_bibset bibset, const char *default_set,
                               WRBUF wrbuf,
                               const xmlNode *ptr,
                               const char **addinfo)
{
    struct _xmlAttr *attr;
    const char *type = 0;
    const char *value = 0;
    const char *attrset = default_set;
    for (attr = ptr->properties; attr; attr = attr->next)
    {
        if (!xmlStrcmp(attr->name, BAD_CAST "type") &&
            attr->children && attr->children->type == XML_TEXT_NODE)
            type = (const char *) attr->children->content;
        else if (!xmlStrcmp(attr->name, BAD_CAST "value") &&
            attr->children && attr->children->type == XML_TEXT_NODE)
            value = (const char *) attr->children->content;
        else if (!xmlStrcmp(attr->name, BAD_CAST "attrset") &&
            attr->children && attr->children->type == XML_TEXT_NODE)
            attrset = (const char *) attr->children->content;
        else
        {
            *addinfo = "bad attribute for 'attr'. "
                "Expecting 'type', 'value', or 'attrset'";
            return 1;
        }
    }
    if (!type)
    {
        *addinfo = "missing attribute for 'type' for element 'attr'";
        return 1;
    }
    if (!value)
    {
        *addinfo = "missing attribute for 'value' for element 'attr'";
        return 1;
    }
    if (attrset)
        wrbuf_printf(wrbuf, "%s,%s=%s", attrset, type, value);
    else
        wrbuf_printf(wrbuf, "%s=%s", type, value);
    return 0;
}

static int ccl_xml_config_qual(CCL_bibset bibset, const char *default_set,
                               WRBUF wrbuf, 
                               const xmlNode *ptr,
                               const char **addinfo)
{
    struct _xmlAttr *attr;
    const char *name = 0;
    const xmlNode *a_ptr = ptr->children;
    for (attr = ptr->properties; attr; attr = attr->next)
    {
        if (!xmlStrcmp(attr->name, BAD_CAST "name") &&
            attr->children && attr->children->type == XML_TEXT_NODE)
            name = (const char *) attr->children->content;
        else
        {
            *addinfo = "bad attribute for 'qual'. Expecting 'name' only";
            return 1;
        }
    }
    if (!name)
    {
        *addinfo = "missing attribute 'name' for 'qual' element";
        return 1;
    }
    for (; a_ptr; a_ptr = a_ptr->next)
    {
        if (a_ptr->type == XML_ELEMENT_NODE)
        {
            if (!xmlStrcmp(a_ptr->name, BAD_CAST "attr"))
            {
                int r = ccl_xml_config_attr(bibset, default_set, wrbuf,
                                            a_ptr, addinfo);
                if (r)
                    return r;
                wrbuf_printf(wrbuf, " ");
            }
            else
            {
                *addinfo = "bad element: expecting 'attr'";
                return 1;
            }
        }
    }
    ccl_qual_fitem(bibset, wrbuf_cstr(wrbuf), name);
    return 0;
}

int ccl_xml_config_directive(CCL_bibset bibset, const xmlNode *ptr,
                             const char **addinfo)
{
    struct _xmlAttr *attr;
    const char *name = 0;
    const char *value = 0;
    for (attr = ptr->properties; attr; attr = attr->next)
    {
        if (!xmlStrcmp(attr->name, BAD_CAST "name") &&
            attr->children && attr->children->type == XML_TEXT_NODE)
            name = (const char *) attr->children->content;
        else if (!xmlStrcmp(attr->name, BAD_CAST "value") &&
            attr->children && attr->children->type == XML_TEXT_NODE)
            value = (const char *) attr->children->content;
        else
        {
            *addinfo = "bad attribute for 'diretive'. "
                "Expecting 'name' or 'value'";
            return 1;
        }
    }
    if (!name)
    {
        *addinfo = "missing attribute 'name' for 'directive' element";
        return 1;
    }
    if (!value)
    {
        *addinfo = "missing attribute 'name' for 'value' element";
        return 1;
    }
    ccl_qual_add_special(bibset, name, value);
    return 0;
}

int ccl_xml_config(CCL_bibset bibset, const xmlNode *ptr, const char **addinfo)
{
    if (ptr && ptr->type == XML_ELEMENT_NODE && 
        !xmlStrcmp(ptr->name, BAD_CAST "cclmap"))
    {
        const xmlNode *c_ptr;
        const char *set = 0;
        struct _xmlAttr *attr;
        for (attr = ptr->properties; attr; attr = attr->next)
        {
            if (!xmlStrcmp(attr->name, BAD_CAST "defaultattrset") &&
                attr->children && attr->children->type == XML_TEXT_NODE)
                set = (const char *) attr->children->content;
            else
            {
                *addinfo = "bad attribute for 'cclmap'. "
                    "expecting 'defaultattrset'";
                return 1;
            }
        }
        for (c_ptr = ptr->children; c_ptr; c_ptr = c_ptr->next)
        {
            if (c_ptr->type == XML_ELEMENT_NODE)
            {
                if (!xmlStrcmp(c_ptr->name, BAD_CAST "qual"))
                {
                    WRBUF wrbuf = wrbuf_alloc();
                    int r = ccl_xml_config_qual(bibset, set,
                                                wrbuf, c_ptr, addinfo);
                    wrbuf_destroy(wrbuf);
                    if (r)
                        return r;
                }
                else if (!xmlStrcmp(c_ptr->name, BAD_CAST "directive"))
                {
                    int r = ccl_xml_config_directive(bibset, c_ptr, addinfo);
                    if (r)
                        return r;
                }
                else
                {
                    *addinfo = "bad element for 'cclmap'. "
                        "expecting 'directive' or 'qual'";
                    return 1;
                }
            }
        }
    }
    return 0;
}
#else
int ccl_xml_config(CCL_bibset bibset, const xmlNode *ptr, const char **addinfo)
{
    *addinfo = "CCL XML configuration not supported. Libxml2 is disabled";
    return -1;
}
#endif

/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */
