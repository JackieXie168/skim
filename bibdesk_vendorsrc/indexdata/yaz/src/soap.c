/*
 * Copyright (C) 1995-2007, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: soap.c,v 1.17 2007/01/03 08:42:15 adam Exp $
 */
/**
 * \file soap.c
 * \brief Implements SOAP
 *
 * This implements encoding and decoding of SOAP packages using
 * Libxml2.
 */

#include <yaz/soap.h>

#if YAZ_HAVE_XML2
#include <libxml/parser.h>
#include <libxml/tree.h>

static const char *soap_v1_1 = "http://schemas.xmlsoap.org/soap/envelope/";
static const char *soap_v1_2 = "http://www.w3.org/2001/06/soap-envelope";

int z_soap_codec_enc_xsl(ODR o, Z_SOAP **pp, 
                         char **content_buf, int *content_len,
                         Z_SOAP_Handler *handlers,
                         const char *encoding,
                         const char *stylesheet)
{
    if (o->direction == ODR_DECODE)
    {
        Z_SOAP *p;
        xmlNodePtr ptr, pptr;
        xmlDocPtr doc;
        int i, ret;

        if (!content_buf || !*content_buf || !content_len)
            return -1;

        *pp = p = (Z_SOAP *) odr_malloc(o, sizeof(*p));
        p->ns = soap_v1_1;

        doc = xmlParseMemory(*content_buf, *content_len);
        if (!doc)
            return z_soap_error(o, p, "SOAP-ENV:Client",
                                "Bad XML Document", 0);

        ptr = xmlDocGetRootElement(doc);
        if (!ptr || !ptr->ns)
        {
            xmlFreeDoc(doc);
            return z_soap_error(o, p, "SOAP-ENV:Client",
                                "No Envelope element", 0);
        }
        /* check for SRU root node match */
        
        for (i = 0; handlers[i].ns; i++)
            if (!xmlStrcmp(ptr->ns->href, BAD_CAST handlers[i].ns))
                break;
        if (handlers[i].ns)
        {
            void *handler_data = 0;
            xmlNode p_top_tmp; /* pseudo parent node needed */

            p_top_tmp.children = ptr;
            ret = (*handlers[i].f)(o, &p_top_tmp, &handler_data,
                                   handlers[i].client_data,
                                   handlers[i].ns);
            
            if (ret || !handler_data)
                z_soap_error(o, p, "SOAP-ENV:Client",
                             "SOAP Handler returned error", 0);
            else
            {
                p->which = Z_SOAP_generic;
                p->u.generic = (Z_SOAP_Generic *)
                    odr_malloc(o, sizeof(*p->u.generic));
                p->u.generic->no = i;
                p->u.generic->ns = handlers[i].ns;
                p->u.generic->p = handler_data;
            }
            xmlFreeDoc(doc);
            return ret;
        }
        /* OK: assume SOAP */

        if (!ptr || ptr->type != XML_ELEMENT_NODE ||
            xmlStrcmp(ptr->name, BAD_CAST "Envelope") || !ptr->ns)
        {
            xmlFreeDoc(doc);
            return z_soap_error(o, p, "SOAP-ENV:Client",
                                "No Envelope element", 0);
        }
        else
        {
            /* determine SOAP version */
            const char * ns_envelope = (const char *) ptr->ns->href;
            if (!strcmp(ns_envelope, soap_v1_1))
                p->ns = soap_v1_1;
            else if (!strcmp(ns_envelope, soap_v1_2))
                p->ns = soap_v1_2;
            else
            {
                xmlFreeDoc(doc);
                return z_soap_error(o, p, "SOAP-ENV:Client",
                                    "Bad SOAP version", 0);
            }
        }
        ptr = ptr->children;
        while(ptr && ptr->type == XML_TEXT_NODE)
            ptr = ptr->next;
        if (ptr && ptr->type == XML_ELEMENT_NODE &&
            !xmlStrcmp(ptr->ns->href, BAD_CAST p->ns) &&
            !xmlStrcmp(ptr->name, BAD_CAST "Header"))
        {
            ptr = ptr->next;
            while(ptr && ptr->type == XML_TEXT_NODE)
                ptr = ptr->next;
        }
        /* check that Body is present */
        if (!ptr || ptr->type != XML_ELEMENT_NODE || 
            xmlStrcmp(ptr->name, BAD_CAST "Body"))
        {
            xmlFreeDoc(doc);
            return z_soap_error(o, p, "SOAP-ENV:Client",
                                "SOAP Body element not found", 0);
        }
        if (xmlStrcmp(ptr->ns->href, BAD_CAST p->ns))
        {
            xmlFreeDoc(doc);
            return z_soap_error(o, p, "SOAP-ENV:Client",
                                "SOAP bad NS for Body element", 0);
        }
        pptr = ptr;
        ptr = ptr->children;
        while (ptr && ptr->type == XML_TEXT_NODE)
            ptr = ptr->next;
        if (!ptr || ptr->type != XML_ELEMENT_NODE)
        {
            xmlFreeDoc(doc);
            return z_soap_error(o, p, "SOAP-ENV:Client",
                                "SOAP No content for Body", 0);
        }
        if (!ptr->ns)
        {
            xmlFreeDoc(doc);
            return z_soap_error(o, p, "SOAP-ENV:Client",
                                "SOAP No namespace for content", 0);
        }
        /* check for fault package */
        if (!xmlStrcmp(ptr->ns->href, BAD_CAST p->ns)
            && !xmlStrcmp(ptr->name, BAD_CAST "Fault") && ptr->children)
        {
            ptr = ptr->children;

            p->which = Z_SOAP_fault;
            p->u.fault = (Z_SOAP_Fault *) odr_malloc(o, sizeof(*p->u.fault));
            p->u.fault->fault_code = 0;
            p->u.fault->fault_string = 0;
            p->u.fault->details = 0;
            while (ptr)
            {
                if (ptr->children && ptr->children->type == XML_TEXT_NODE)
                {
                    if (!xmlStrcmp(ptr->name, BAD_CAST "faultcode"))
                        p->u.fault->fault_code =
                            odr_strdup(o, (const char *)
                                       ptr->children->content);
                    if (!xmlStrcmp(ptr->name, BAD_CAST "faultstring"))
                        p->u.fault->fault_string =
                            odr_strdup(o, (const char *)
                                       ptr->children->content);
                    if (!xmlStrcmp(ptr->name, BAD_CAST "details"))
                        p->u.fault->details =
                            odr_strdup(o, (const char *)
                                       ptr->children->content);
                }
                ptr = ptr->next;
            }
            ret = 0;
        }
        else
        {
            for (i = 0; handlers[i].ns; i++)
                if (!xmlStrcmp(ptr->ns->href, BAD_CAST handlers[i].ns))
                    break;
            if (handlers[i].ns)
            {
                void *handler_data = 0;
                ret = (*handlers[i].f)(o, pptr, &handler_data,
                                       handlers[i].client_data,
                                       handlers[i].ns);
                if (ret || !handler_data)
                    z_soap_error(o, p, "SOAP-ENV:Client",
                                 "SOAP Handler returned error", 0);
                else
                {
                    p->which = Z_SOAP_generic;
                    p->u.generic = (Z_SOAP_Generic *)
                        odr_malloc(o, sizeof(*p->u.generic));
                    p->u.generic->no = i;
                    p->u.generic->ns = handlers[i].ns;
                    p->u.generic->p = handler_data;
                }
            }
            else
            {
                ret = z_soap_error(o, p, "SOAP-ENV:Client", 
                                   "No handler for NS",
                                   (const char *)ptr->ns->href);
            }
        }
        xmlFreeDoc(doc);
        return ret;
    }
    else if (o->direction == ODR_ENCODE)
    {
        Z_SOAP *p = *pp;
        xmlNsPtr ns_env;
        xmlNodePtr envelope_ptr, body_ptr;

        xmlDocPtr doc = xmlNewDoc(BAD_CAST "1.0");

        envelope_ptr = xmlNewNode(0, BAD_CAST "Envelope");
        ns_env = xmlNewNs(envelope_ptr, BAD_CAST p->ns,
                          BAD_CAST "SOAP-ENV");
        xmlSetNs(envelope_ptr, ns_env);

        body_ptr = xmlNewChild(envelope_ptr, ns_env, BAD_CAST "Body",
                               0);
        xmlDocSetRootElement(doc, envelope_ptr);

        if (p->which == Z_SOAP_fault || p->which == Z_SOAP_error)
        {
            Z_SOAP_Fault *f = p->u.fault;
            xmlNodePtr fault_ptr = xmlNewChild(body_ptr, ns_env,
                                               BAD_CAST "Fault", 0);
            xmlNewChild(fault_ptr, ns_env, BAD_CAST "faultcode", 
                        BAD_CAST f->fault_code);
            xmlNewChild(fault_ptr, ns_env, BAD_CAST "faultstring",
                        BAD_CAST f->fault_string);
            if (f->details)
                xmlNewChild(fault_ptr, ns_env, BAD_CAST "details",
                            BAD_CAST f->details);
        }
        else if (p->which == Z_SOAP_generic)
        {
            int ret, no = p->u.generic->no;
            
            ret = (*handlers[no].f)(o, body_ptr, &p->u.generic->p,
                                    handlers[no].client_data,
                                    handlers[no].ns);
            if (ret)
            {
                xmlFreeDoc(doc);
                return ret;
            }
        }
        if (p->which == Z_SOAP_generic && !strcmp(p->ns, "SRU"))
        {
            xmlDocSetRootElement(doc, body_ptr->children);
            body_ptr->children = 0;
            xmlFreeNode(envelope_ptr);
        }
        if (stylesheet)
        {
            char *content = odr_malloc(o, strlen(stylesheet) + 40);
            
            xmlNodePtr pi, ptr = xmlDocGetRootElement(doc);
            sprintf(content, "type=\"text/xsl\" href=\"%s\"", stylesheet);
            pi = xmlNewPI(BAD_CAST "xml-stylesheet",
                          BAD_CAST content);
            xmlAddPrevSibling(ptr, pi);
        }
        if (1)
        {
            xmlChar *buf_out;
            int len_out;
            if (encoding)
                xmlDocDumpMemoryEnc(doc, &buf_out, &len_out, encoding);
            else
                xmlDocDumpMemory(doc, &buf_out, &len_out);
            *content_buf = (char *) odr_malloc(o, len_out);
            *content_len = len_out;
            memcpy(*content_buf, buf_out, len_out);
            xmlFree(buf_out);
        }
        xmlFreeDoc(doc);
        return 0;
    }
    return 0;
}
#else
int z_soap_codec_enc_xsl(ODR o, Z_SOAP **pp, 
                         char **content_buf, int *content_len,
                         Z_SOAP_Handler *handlers, const char *encoding,
                         const char *stylesheet)
{
    static char *err_xml =
        "<?xml version=\"1.0\"?>\n"
        "<SOAP-ENV:Envelope"
        " xmlns:SOAP-ENV=\"http://schemas.xmlsoap.org/soap/envelope/\">\n"
        "\t<SOAP-ENV:Body>\n"
        "\t\t<SOAP-ENV:Fault>\n"
        "\t\t\t<faultcode>SOAP-ENV:Server</faultcode>\n"
        "\t\t\t<faultstring>HTTP error</faultstring>\n"
        "\t\t\t<detail>SOAP not supported in this YAZ configuration</detail>\n"
        "\t\t</SOAP-ENV:Fault>\n"
        "\t</SOAP-ENV:Body>\n"
        "</SOAP-ENV:Envelope>\n";
    if (o->direction == ODR_ENCODE)
    {
        *content_buf = err_xml;
        *content_len = strlen(err_xml);
    }
    return -1;
}
#endif
int z_soap_codec_enc(ODR o, Z_SOAP **pp, 
                     char **content_buf, int *content_len,
                     Z_SOAP_Handler *handlers,
                     const char *encoding)
{
    return z_soap_codec_enc_xsl(o, pp, content_buf, content_len, handlers,
                                encoding, 0);
}

int z_soap_codec(ODR o, Z_SOAP **pp, 
                 char **content_buf, int *content_len,
                 Z_SOAP_Handler *handlers)
{
    return z_soap_codec_enc(o, pp, content_buf, content_len, handlers, 0);
}

int z_soap_error(ODR o, Z_SOAP *p,
                 const char *fault_code, const char *fault_string,
                 const char *details)
{
    p->which = Z_SOAP_error;
    p->u.soap_error = (Z_SOAP_Fault *) 
        odr_malloc(o, sizeof(*p->u.soap_error));
    p->u.soap_error->fault_code = odr_strdup(o, fault_code);
    p->u.soap_error->fault_string = odr_strdup(o, fault_string);
    if (details)
        p->u.soap_error->details = odr_strdup(o, details);
    else
        p->u.soap_error->details = 0;
    return -1;
}

/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

