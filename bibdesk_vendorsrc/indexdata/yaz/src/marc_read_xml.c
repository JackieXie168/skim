/*
 * Copyright (C) 1995-2006, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: marc_read_xml.c,v 1.1 2006/12/15 12:37:18 adam Exp $
 */

/**
 * \file marc_read_xml.c
 * \brief Implements reading of MARC as XML
 */

#if HAVE_CONFIG_H
#include <config.h>
#endif

#ifdef WIN32
#include <windows.h>
#endif

#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include "marcdisp.h"
#include "wrbuf.h"
#include <yaz/yaz-util.h>
#include <yaz/nmem_xml.h>

#if YAZ_HAVE_XML2
#include <libxml/tree.h>
#endif

#if YAZ_HAVE_XML2
int yaz_marc_read_xml_subfields(yaz_marc_t mt, const xmlNode *ptr)
{
    NMEM nmem = yaz_marc_get_nmem(mt);
    for (; ptr; ptr = ptr->next)
    {
        if (ptr->type == XML_ELEMENT_NODE)
        {
            if (!strcmp((const char *) ptr->name, "subfield"))
            {
                size_t ctrl_data_len = 0;
                char *ctrl_data_buf = 0;
                const xmlNode *p = 0, *ptr_code = 0;
                struct _xmlAttr *attr;
                for (attr = ptr->properties; attr; attr = attr->next)
                    if (!strcmp((const char *)attr->name, "code"))
                        ptr_code = attr->children;
                    else
                    {
                        yaz_marc_cprintf(
                            mt, "Bad attribute '%.80s' for 'subfield'",
                            attr->name);
                        return -1;
                    }
                if (!ptr_code)
                {
                    yaz_marc_cprintf(
                        mt, "Missing attribute 'code' for 'subfield'" );
                    return -1;
                }
                if (ptr_code->type == XML_TEXT_NODE)
                {
                    ctrl_data_len = 
                        strlen((const char *)ptr_code->content);
                }
                else
                {
                    yaz_marc_cprintf(
                        mt, "Missing value for 'code' in 'subfield'" );
                    return -1;
                }
                for (p = ptr->children; p ; p = p->next)
                    if (p->type == XML_TEXT_NODE)
                        ctrl_data_len += strlen((const char *)p->content);
                ctrl_data_buf = nmem_malloc(nmem, ctrl_data_len+1);
                strcpy(ctrl_data_buf, (const char *)ptr_code->content);
                for (p = ptr->children; p ; p = p->next)
                    if (p->type == XML_TEXT_NODE)
                        strcat(ctrl_data_buf, (const char *)p->content);
                yaz_marc_add_subfield(mt, ctrl_data_buf, ctrl_data_len);
            }
            else
            {
                yaz_marc_cprintf(
                    mt, "Expected element 'subfield', got '%.80s'", ptr->name);
                return -1;
            }
        }
    }
    return 0;
}

static int yaz_marc_read_xml_leader(yaz_marc_t mt, const xmlNode **ptr_p)
{
    int indicator_length;
    int identifier_length;
    int base_address;
    int length_data_entry;
    int length_starting;
    int length_implementation;
    const char *leader = 0;
    const xmlNode *ptr = *ptr_p;

    for(; ptr; ptr = ptr->next)
        if (ptr->type == XML_ELEMENT_NODE)
        {
            if (!strcmp((const char *) ptr->name, "leader"))
            {
                xmlNode *p = ptr->children;
                for(; p; p = p->next)
                    if (p->type == XML_TEXT_NODE)
                        leader = (const char *) p->content;
                break;
            }
            else
            {
                yaz_marc_cprintf(
                    mt, "Expected element 'leader', got '%.80s'", ptr->name);
                return -1;
            }
        }
    if (!leader)
    {
        yaz_marc_cprintf(mt, "Missing element 'leader'");
        return -1;
    }
    if (strlen(leader) != 24)
    {
        yaz_marc_cprintf(mt, "Bad length %d of leader data."
                         " Must have length of 24 characters", strlen(leader));
        return -1;
    }
    yaz_marc_set_leader(mt, leader,
                        &indicator_length,
                        &identifier_length,
                        &base_address,
                        &length_data_entry,
                        &length_starting,
                        &length_implementation);
    *ptr_p = ptr;
    return 0;
}

static int yaz_marc_read_xml_fields(yaz_marc_t mt, const xmlNode *ptr)
{
    for(; ptr; ptr = ptr->next)
        if (ptr->type == XML_ELEMENT_NODE)
        {
            if (!strcmp((const char *) ptr->name, "controlfield"))
            {
                const xmlNode *ptr_tag = 0;
                struct _xmlAttr *attr;
                for (attr = ptr->properties; attr; attr = attr->next)
                    if (!strcmp((const char *)attr->name, "tag"))
                        ptr_tag = attr->children;
                    else
                    {
                        yaz_marc_cprintf(
                            mt, "Bad attribute '%.80s' for 'controlfield'",
                            attr->name);
                        return -1;
                    }
                if (!ptr_tag)
                {
                    yaz_marc_cprintf(
                        mt, "Missing attribute 'tag' for 'controlfield'" );
                    return -1;
                }
                yaz_marc_add_controlfield_xml(mt, ptr_tag, ptr->children);
            }
            else if (!strcmp((const char *) ptr->name, "datafield"))
            {
                char indstr[11]; /* 0(unused), 1,....9, + zero term */
                const xmlNode *ptr_tag = 0;
                struct _xmlAttr *attr;
                int i;
                for (i = 0; i<11; i++)
                    indstr[i] = '\0';
                for (attr = ptr->properties; attr; attr = attr->next)
                    if (!strcmp((const char *)attr->name, "tag"))
                        ptr_tag = attr->children;
                    else if (strlen((const char *)attr->name) == 4 &&
                             !memcmp(attr->name, "ind", 3))
                    {
                        int no = atoi((const char *)attr->name+3);
                        if (attr->children
                            && attr->children->type == XML_TEXT_NODE)
                            indstr[no] = attr->children->content[0];
                    }
                    else
                    {
                        yaz_marc_cprintf(
                            mt, "Bad attribute '%.80s' for 'datafield'",
                            attr->name);
                        return -1;
                    }
                if (!ptr_tag)
                {
                    yaz_marc_cprintf(
                        mt, "Missing attribute 'tag' for 'datafield'" );
                    return -1;
                }
                /* note that indstr[0] is unused so we use indstr[1..] */
                yaz_marc_add_datafield_xml(mt, ptr_tag,
                                           indstr+1, strlen(indstr+1));
                
                if (yaz_marc_read_xml_subfields(mt, ptr->children))
                    return -1;
            }
            else
            {
                yaz_marc_cprintf(mt,
                                 "Expected element controlfield or datafield,"
                                 " got %.80s", ptr->name);
                return -1;
            }
        }
    return 0;
}
#endif

int yaz_marc_read_xml(yaz_marc_t mt, const xmlNode *ptr)
{
#if YAZ_HAVE_XML2
    for(; ptr; ptr = ptr->next)
        if (ptr->type == XML_ELEMENT_NODE)
        {
            if (!strcmp((const char *) ptr->name, "record"))
                break;
            else
            {
                yaz_marc_cprintf(
                    mt, "Unknown element '%.80s' in MARC XML reader",
                    ptr->name);
                return -1;
            }
        }
    if (!ptr)
    {
        yaz_marc_cprintf(mt, "Missing element 'record' in MARC XML record");
        return -1;
    }
    /* ptr points to record node now */
    ptr = ptr->children;
    if (yaz_marc_read_xml_leader(mt, &ptr))
        return -1;
    return yaz_marc_read_xml_fields(mt, ptr->next);
#else
    return -1;
#endif
}


/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

