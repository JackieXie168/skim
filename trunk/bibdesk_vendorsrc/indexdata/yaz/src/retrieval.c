/*
 * Copyright (C) 2005-2007, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: retrieval.c,v 1.15 2007/01/03 08:42:15 adam Exp $
 */
/**
 * \file retrieval.c
 * \brief Retrieval utility
 */

#if HAVE_CONFIG_H
#include <config.h>
#endif

#include <string.h>
#include <yaz/retrieval.h>
#include <yaz/wrbuf.h>
#include <yaz/xmalloc.h>
#include <yaz/nmem.h>
#include <yaz/tpath.h>
#include <yaz/proto.h>

#if YAZ_HAVE_XML2
#include <libxml/parser.h>
#include <libxml/tree.h>
#include <libxml/xinclude.h>

/** \brief The internal structure for yaz_retrieval_t */
struct yaz_retrieval_struct {
    /** \brief ODR memory for configuration */
    ODR odr;

    /** \brief odr's NMEM memory (odr->mem) */
    NMEM nmem;

    /** \brief string buffer for error messages */
    WRBUF wr_error;

    /** \brief path for opening files  */
    char *path;

    /** \brief retrieval list */
    struct yaz_retrieval_elem *list;

    /** \brief last pointer in retrieval list */
    struct yaz_retrieval_elem **list_p;
};

/** \brief information per 'retrieval' construct */
struct yaz_retrieval_elem {
    /** \brief schema identifier */
    const char *identifier;
    /** \brief schema name , short-hand such as "dc" */
    const char *name;
    /** \brief record syntax */
    int *syntax;

    /** \brief backend name */
    const char *backend_name;
    /** \brief backend syntax */
    int *backend_syntax;

    /** \brief record conversion */
    yaz_record_conv_t record_conv;

    /** \brief next element in list */
    struct yaz_retrieval_elem *next;
};

static void yaz_retrieval_reset(yaz_retrieval_t p);

yaz_retrieval_t yaz_retrieval_create()
{
    yaz_retrieval_t p = xmalloc(sizeof(*p));
    p->odr = odr_createmem(ODR_ENCODE);
    p->nmem = p->odr->mem;
    p->wr_error = wrbuf_alloc();
    p->list = 0;
    p->path = 0;
    yaz_retrieval_reset(p);
    return p;
}

void yaz_retrieval_destroy(yaz_retrieval_t p)
{
    if (p)
    {
        yaz_retrieval_reset(p);
        odr_destroy(p->odr);
        wrbuf_free(p->wr_error, 1);
        xfree(p->path);
        xfree(p);
    }
}

void yaz_retrieval_reset(yaz_retrieval_t p)
{
    struct yaz_retrieval_elem *el = p->list;
    for(; el; el = el->next)
        yaz_record_conv_destroy(el->record_conv);

    wrbuf_rewind(p->wr_error);
    odr_reset(p->odr);

    p->list = 0;
    p->list_p = &p->list;
}

/** \brief parse retrieval XML config */
static int conf_retrieval(yaz_retrieval_t p, const xmlNode *ptr)
{

    struct _xmlAttr *attr;
    struct yaz_retrieval_elem *el = nmem_malloc(p->nmem, sizeof(*el));

    el->syntax = 0;
    el->identifier = 0;
    el->name = 0;
    el->backend_name = 0;
    el->backend_syntax = 0;

    el->next = 0;

    for (attr = ptr->properties; attr; attr = attr->next)
    {
        if (!xmlStrcmp(attr->name, BAD_CAST "syntax") &&
            attr->children && attr->children->type == XML_TEXT_NODE)
        {
            el->syntax = yaz_str_to_z3950oid(
                p->odr, CLASS_RECSYN,
                (const char *) attr->children->content);
            if (!el->syntax)
            {
                wrbuf_printf(p->wr_error, "Element <retrieval>: "
                             " unknown attribute value syntax='%s'",
                             (const char *) attr->children->content);
                return -1;
            }
        }
        else if (!xmlStrcmp(attr->name, BAD_CAST "identifier") &&
                 attr->children && attr->children->type == XML_TEXT_NODE)
            el->identifier =
                nmem_strdup(p->nmem, (const char *) attr->children->content);
        else if (!xmlStrcmp(attr->name, BAD_CAST "name") &&
                 attr->children && attr->children->type == XML_TEXT_NODE)
            el->name = 
                nmem_strdup(p->nmem, (const char *) attr->children->content);
        else
        {
            wrbuf_printf(p->wr_error, "Element <retrieval>: "
                         " expected attributes 'syntax', identifier' or "
                         "'name', got '%s'", attr->name);
            return -1;
        }
    }

    if (!el->syntax)
    {
        wrbuf_printf(p->wr_error, "Missing 'syntax' attribute");
        return -1;
    }

    /* parsing backend element */

    el->record_conv = 0; /* OK to have no 'backend' sub content */
    for (ptr = ptr->children; ptr; ptr = ptr->next)
    {
        if (ptr->type == XML_ELEMENT_NODE
            && 0 != strcmp((const char *) ptr->name, "backend")){
            wrbuf_printf(p->wr_error, "Element <retrieval>: expected"
                         " zero or one element <backend>, got <%s>",
                         (const char *) ptr->name);
            return -1;
        }

        else {

            /* parsing attributees */
            struct _xmlAttr *attr;
            for (attr = ptr->properties; attr; attr = attr->next){
            
                if (!xmlStrcmp(attr->name, BAD_CAST "name") 
                         && attr->children 
                         && attr->children->type == XML_TEXT_NODE)
                    el->backend_name 
                        = nmem_strdup(p->nmem, 
                                      (const char *) attr->children->content);

                else if (!xmlStrcmp(attr->name, BAD_CAST "syntax") 
                         && attr->children 
                         && attr->children->type == XML_TEXT_NODE){
                    el->backend_syntax 
                    = yaz_str_to_z3950oid(p->odr, CLASS_RECSYN,
                       (const char *) attr->children->content);
                    
                    if (!el->backend_syntax){
                        wrbuf_printf(p->wr_error, 
                                     "Element <backend syntax='%s'>: "
                                     "attribute 'syntax' has invalid "
                                     "value '%s'", 
                                     attr->children->content,
                                     attr->children->content);
                        return -1;
                    } 
                }
                else {
                    wrbuf_printf(p->wr_error, "Element <backend>: expected "
                                 "attributes 'syntax' or 'name, got '%s'", 
                                 attr->name);
                    return -1;
                }
            }
          
 
            /* parsing internal of record conv */
            el->record_conv = yaz_record_conv_create();
            
            yaz_record_conv_set_path(el->record_conv, p->path);

        
            if (yaz_record_conv_configure(el->record_conv, ptr))
            {
                wrbuf_printf(p->wr_error, "%s",
                             yaz_record_conv_get_error(el->record_conv));
                yaz_record_conv_destroy(el->record_conv);
                return -1;
            }
        }
    }
    
    *p->list_p = el;
    p->list_p = &el->next;
    return 0;
}

int yaz_retrieval_configure(yaz_retrieval_t p, const xmlNode *ptr)
{
    yaz_retrieval_reset(p);

    if (ptr && ptr->type == XML_ELEMENT_NODE &&
        !strcmp((const char *) ptr->name, "retrievalinfo"))
    {
        for (ptr = ptr->children; ptr; ptr = ptr->next)
        {
            if (ptr->type != XML_ELEMENT_NODE)
                continue;
            if (!strcmp((const char *) ptr->name, "retrieval"))
            {
                if (conf_retrieval(p, ptr))
                    return -1;
            }
            else
            {
                wrbuf_printf(p->wr_error, "Element <retrievalinfo>: "
                             "expected element <retrieval>, got <%s>", 
                             ptr->name);
                return -1;
            }
        }
    }
    else
    {
        wrbuf_printf(p->wr_error, "Expected element <retrievalinfo>");
        return -1;
    }
    return 0;
}

int yaz_retrieval_request(yaz_retrieval_t p,
                          const char *schema, int *syntax,
                          const char **match_schema, int **match_syntax,
                          yaz_record_conv_t *rc,
                          const char **backend_schema,
                          int **backend_syntax)
{
    struct yaz_retrieval_elem *el = p->list;
    int syntax_matches = 0;
    int schema_matches = 0;

    wrbuf_rewind(p->wr_error);
    if (!el)
        return 0;
    for(; el; el = el->next)
    {
        int schema_ok = 0;
        int syntax_ok = 0;

        if (!schema)
            schema_ok = 1;
        else
        {
            if (el->name && !strcmp(schema, el->name))
                schema_ok = 1;
            if (el->identifier && !strcmp(schema, el->identifier))
                schema_ok = 1;
            if (!el->name && !el->identifier)
                schema_ok = 1;
        }
        
        if (syntax && el->syntax && !oid_oidcmp(syntax, el->syntax))
            syntax_ok = 1;
        if (!syntax)
            syntax_ok = 1;

        if (syntax_ok)
            syntax_matches++;
        if (schema_ok)
            schema_matches++;
        if (syntax_ok && schema_ok)
        {
            *match_syntax = el->syntax;
            if (el->identifier)
                *match_schema = el->identifier;
            else
                *match_schema = 0;
            if (backend_schema)
            {
                if (el->backend_name)
                    *backend_schema = el->backend_name;
                else if (el->name)
                    *backend_schema = el->name;                    
                else
                    *backend_schema = schema;
            }
            if (backend_syntax)
            {
                if (el->backend_syntax)
                    *backend_syntax = el->backend_syntax;
                else
                    *backend_syntax = el->syntax;
            }
            if (rc)
                *rc = el->record_conv;
            return 0;
        }
    }
    if (!syntax_matches && syntax)
    {
        char buf[OID_STR_MAX];
        wrbuf_printf(p->wr_error, "%s", oid_to_dotstring(syntax, buf));
        return 2;
    }
    if (schema)
        wrbuf_printf(p->wr_error, "%s", schema);
    if (!schema_matches)
        return 1;
    return 3;
}

const char *yaz_retrieval_get_error(yaz_retrieval_t p)
{
    return wrbuf_buf(p->wr_error);
}

void yaz_retrieval_set_path(yaz_retrieval_t p, const char *path)
{
    xfree(p->path);
    p->path = 0;
    if (path)
        p->path = xstrdup(path);
}

#endif

/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

