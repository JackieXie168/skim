/*
 * Copyright (C) 2005-2006, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: tst_retrieval.c,v 1.8 2006/12/12 10:41:39 marc Exp $
 *
 */
#include <yaz/retrieval.h>
#include <yaz/test.h>
#include <yaz/wrbuf.h>
#include <string.h>
#include <yaz/log.h>
#include <yaz/libxml2_error.h>

#if HAVE_CONFIG_H
#include <config.h>
#endif

#if YAZ_HAVE_XSLT

#include <libxml/parser.h>
#include <libxml/tree.h>

yaz_retrieval_t conv_configure(const char *xmlstring, WRBUF w)
{
    xmlDocPtr doc = xmlParseMemory(xmlstring, strlen(xmlstring));
    if (!doc)
    {
        wrbuf_printf(w, "xmlParseMemory");
        return 0;
    }
    else
    {
        xmlNodePtr ptr = xmlDocGetRootElement(doc);
        yaz_retrieval_t p = yaz_retrieval_create();

        if (p)
        {
            const char *srcdir = getenv("srcdir");
            if (srcdir)
                yaz_retrieval_set_path(p, srcdir);
        }
        if (!ptr)
        {
            wrbuf_printf(w, "xmlDocGetRootElement");
            yaz_retrieval_destroy(p);
            p = 0;
        }
        else if (!p)
        {
            wrbuf_printf(w, "yaz_retrieval_create");
        }
        else
        {
            int r = yaz_retrieval_configure(p, ptr);
            
            if (r)
            {
                wrbuf_puts(w, yaz_retrieval_get_error(p));
                yaz_retrieval_destroy(p);
                p = 0;
            }
        }
        xmlFreeDoc(doc);
        return p;
    }    
}

int conv_configure_test(const char *xmlstring, const char *expect_error,
                        yaz_retrieval_t *pt)
{
    WRBUF w = wrbuf_alloc();
    int ret;

    yaz_retrieval_t p = conv_configure(xmlstring, w);

    if (!p)
    {
        if (expect_error && !strcmp(wrbuf_buf(w), expect_error))
            ret = 1;
        else
        {
            ret = 0;
            printf("%.*s\n", wrbuf_len(w), wrbuf_buf(w));
        }
    }
    else
    {
        if (expect_error)
        {
            ret = 0;
            yaz_retrieval_destroy(p);
        }
        else
        {
            if (pt)
                *pt = p;
            else
                yaz_retrieval_destroy(p);
            ret = 1;
        }
    }
    wrbuf_free(w, 1);
    return ret;
}

static void tst_configure(void)
{
    YAZ_CHECK(conv_configure_test("<bad", 
                                  "xmlParseMemory", 0));

    YAZ_CHECK(conv_configure_test("<bad/>", 
                                  "Expected element <retrievalinfo>", 0));

    YAZ_CHECK(conv_configure_test("<retrievalinfo/>", 0, 0));

    YAZ_CHECK(conv_configure_test("<retrievalinfo><bad/></retrievalinfo>",
                                  "Element <retrievalinfo>:"
                                  " expected element <retrieval>, got <bad>",
                                  0));

    YAZ_CHECK(conv_configure_test("<retrievalinfo><retrieval/>"
                                  "</retrievalinfo>",
                                  "Missing 'syntax' attribute", 0));


    YAZ_CHECK(conv_configure_test("<retrievalinfo>"
                                  "<retrieval" 
                                  " unknown=\"unknown\""
                                  ">"
                                  "</retrieval>"
                                  "</retrievalinfo>",
                                  "Element <retrieval>:  expected attributes "
                                  "'syntax', identifier' or 'name', got "
                                  "'unknown'", 0));

    YAZ_CHECK(conv_configure_test("<retrievalinfo>"
                                  "<retrieval" 
                                  " syntax=\"unknown_synt\""
                                  ">"
                                  "</retrieval>"
                                  "</retrievalinfo>",
                                  "Element <retrieval>:  unknown attribute "
                                  "value syntax='unknown_synt'", 0));

    YAZ_CHECK(conv_configure_test("<retrievalinfo>"
                                  "<retrieval" 
                                  " syntax=\"usmarc\""
                                  "/>"
                                  "</retrievalinfo>",
                                  0, 0));

    YAZ_CHECK(conv_configure_test("<retrievalinfo>"
                                  "<retrieval" 
                                  " syntax=\"usmarc\""
                                  " name=\"marcxml\"/>"
                                  "</retrievalinfo>",
                                  0, 0));


    YAZ_CHECK(conv_configure_test("<retrievalinfo>"
                                  "<retrieval" 
                                  " syntax=\"usmarc\""
                                  " name=\"marcxml\"" 
                                  " identifier=\"info:srw/schema/1/marcxml-v1.1\""
                                  "/>"
                                  "</retrievalinfo>",
                                  0, 0));



    YAZ_CHECK(conv_configure_test("<retrievalinfo>"
                                  "<retrieval" 
                                  " syntax=\"usmarc\""
                                  " identifier=\"info:srw/schema/1/marcxml-v1.1\""
                                  " name=\"marcxml\">"
                                  "<convert/>"
                                  "</retrieval>" 
                                  "</retrievalinfo>",
                                  "Element <retrieval>: expected zero or one element "
                                  "<backend>, got <convert>", 0));

    YAZ_CHECK(conv_configure_test("<retrievalinfo>"
                                  "<retrieval" 
                                  " syntax=\"usmarc\""
                                  " identifier=\"info:srw/schema/1/marcxml-v1.1\""
                                  " name=\"marcxml\">"
                                  " <backend syntax=\"usmarc\""
                                  " schema=\"marcxml\""
                                  "/>"
                                  "</retrieval>"
                                  "</retrievalinfo>",
                                  "Element <backend>: expected attributes 'syntax' or 'name,"
                                  " got 'schema'", 0));

    YAZ_CHECK(conv_configure_test("<retrievalinfo>"
                                  "<retrieval" 
                                  " syntax=\"usmarc\""
                                  " identifier=\"info:srw/schema/1/marcxml-v1.1\""
                                  " name=\"marcxml\">"
                                  " <backend syntax=\"usmarc\""
                                  " name=\"marcxml\""
                                  "/>"
                                  "</retrieval>"
                                  "</retrievalinfo>",
                                  0, 0));

    YAZ_CHECK(conv_configure_test("<retrievalinfo>"
                                  "<retrieval" 
                                  " syntax=\"usmarc\""
                                  " identifier=\"info:srw/schema/1/marcxml-v1.1\""
                                  " name=\"marcxml\">"
                                  " <backend syntax=\"unknown\""
                                  "/>"
                                  "</retrieval>"
                                  "</retrievalinfo>",
                                  "Element <backend syntax='unknown'>: "
                                  "attribute 'syntax' has invalid value "
                                  "'unknown'", 0));


    YAZ_CHECK(conv_configure_test("<retrievalinfo>"
                                  "<retrieval" 
                                  " syntax=\"usmarc\""
                                  " identifier=\"info:srw/schema/1/marcxml-v1.1\""
                                    " name=\"marcxml\">"
                                  " <backend syntax=\"usmarc\""
                                  " unknown=\"silly\""
                                  "/>"
                                  "</retrieval>"
                                  "</retrievalinfo>",
                                  "Element <backend>: expected attributes "
                                  "'syntax' or 'name, got 'unknown'", 0));


    YAZ_CHECK(conv_configure_test("<retrievalinfo>"
                                  "<retrieval syntax=\"usmarc\">"
                                  "<backend syntax=\"xml\" name=\"dc\">"
                                  "<xslt stylesheet=\"tst_record_conv.xsl\"/>"
                                  "<marc"
                                  " inputcharset=\"utf-8\""
                                  " outputcharset=\"non-existent\""
                                  " inputformat=\"xml\""
                                  " outputformat=\"marc\""
                                  "/>"
                                  "</backend>"
                                  "</retrieval>"
                                  "</retrievalinfo>",
                                  "Element <marc inputcharset='utf-8'"
                                  " outputcharset='non-existent'>: Unsupported character"
                                  " set mapping defined by attribute values", 0));

    YAZ_CHECK(conv_configure_test("<retrievalinfo>"
                                  "<retrieval syntax=\"usmarc\">"
                                  "<backend syntax=\"xml\" name=\"dc\">"
                                  "<xslt stylesheet=\"tst_record_conv.xsl\"/>"
                                  "<marc"
                                  " inputcharset=\"utf-8\""
                                  " outputcharset=\"marc-8\""
                                  " inputformat=\"not-existent\""
                                  " outputformat=\"marc\""
                                  "/>"
                                  "</backend>"
                                  "</retrieval>"
                                  "</retrievalinfo>",
                                  "Element <marc inputformat='not-existent'>:  Unsupported"
                                  " input format defined by attribute value", 0));

    YAZ_CHECK(conv_configure_test("<retrievalinfo>"
                                  "<retrieval syntax=\"usmarc\">"
                                  "<backend syntax=\"xml\" name=\"dc\">"
                                  "<xslt stylesheet=\"tst_record_conv.xsl\"/>"
                                  "<marc"
                                  " inputcharset=\"utf-8\""
                                  " outputcharset=\"marc-8\""
                                  " inputformat=\"xml\""
                                  " outputformat=\"marc\""
                                  "/>"
                                  "</backend>"
                                  "</retrieval>"
                                  "</retrievalinfo>",
                                  0, 0));

    YAZ_CHECK(conv_configure_test(
                                  "<retrievalinfo "
                                  " xmlns=\"http://indexdata.com/yaz\" version=\"1.0\">"
                                  "<retrieval syntax=\"grs-1\"/>"
                                  "<retrieval syntax=\"usmarc\" name=\"F\"/>"
                                  "<retrieval syntax=\"usmarc\" name=\"B\"/>"
                                  "<retrieval syntax=\"xml\" name=\"marcxml\" "
                                  "           identifier=\"info:srw/schema/1/marcxml-v1.1\">"
                                  "  <backend syntax=\"usmarc\" name=\"F\">"
                                  "    <marc inputformat=\"marc\" outputformat=\"marcxml\" "
                                  "            inputcharset=\"marc-8\"/>"
                                  "  </backend>"
                                  "</retrieval>"
                                  "<retrieval syntax=\"xml\" name=\"danmarc\">"
                                  "  <backend syntax=\"usmarc\" name=\"F\">"
                                  "    <marc inputformat=\"marc\" outputformat=\"marcxchange\" "
                                  "          inputcharset=\"marc-8\"/>"
                                  "  </backend>"
                                  "</retrieval>"
                                  "<retrieval syntax=\"xml\" name=\"dc\" "
                                  "           identifier=\"info:srw/schema/1/dc-v1.1\">"
                                  "  <backend syntax=\"usmarc\" name=\"F\">"
                                  "    <marc inputformat=\"marc\" outputformat=\"marcxml\" "
                                  "          inputcharset=\"marc-8\"/>"
                                  "    <xslt stylesheet=\"tst_record_conv.xsl\"/> "
                                  "  </backend>"
                                  "</retrieval>"
                                  "</retrievalinfo>",
                                  0, 0));

}

#endif

int main(int argc, char **argv)
{
    YAZ_CHECK_INIT(argc, argv);

    libxml2_error_to_yazlog(0 /* disable it */, "");

#if YAZ_HAVE_XSLT
    tst_configure();
#endif
    YAZ_CHECK_TERM;
}

/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

