/*
 * Copyright (C) 2005-2007, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: tst_record_conv.c,v 1.13 2007/01/03 08:42:16 adam Exp $
 *
 */
#include <yaz/record_conv.h>
#include <yaz/test.h>
#include <yaz/wrbuf.h>
#include <string.h>
#include <yaz/log.h>
#include <yaz/libxml2_error.h>

#if HAVE_CONFIG_H
#include <config.h>
#endif

#if YAZ_HAVE_XML2

#include <libxml/parser.h>
#include <libxml/tree.h>

yaz_record_conv_t conv_configure(const char *xmlstring, WRBUF w)
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
        yaz_record_conv_t p = yaz_record_conv_create();

        if (p)
        {
            const char *srcdir = getenv("srcdir");
            if (srcdir)
                yaz_record_conv_set_path(p, srcdir);
        }
        if (!ptr)
        {
            wrbuf_printf(w, "xmlDocGetRootElement");
            yaz_record_conv_destroy(p);
            p = 0;
        }
        else if (!p)
        {
            wrbuf_printf(w, "yaz_record_conv_create");
        }
        else
        {


            int r = yaz_record_conv_configure(p, ptr);
            
            if (r)
            {
                wrbuf_puts(w, yaz_record_conv_get_error(p));
                yaz_record_conv_destroy(p);
                p = 0;
            }
        }
        xmlFreeDoc(doc);
        return p;
    }    
}

int conv_configure_test(const char *xmlstring, const char *expect_error,
                        yaz_record_conv_t *pt)
{
    WRBUF w = wrbuf_alloc();
    int ret;

    yaz_record_conv_t p = conv_configure(xmlstring, w);

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
            ret = 0;
        else
            ret = 1;
    }

    if (pt)
        *pt = p;
    else
        if (p)
            yaz_record_conv_destroy(p);

    wrbuf_free(w, 1);
    return ret;
}

static void tst_configure(void)
{



    YAZ_CHECK(conv_configure_test("<bad", "xmlParseMemory", 0));


    YAZ_CHECK(conv_configure_test("<backend syntax='usmarc' name='F'>"
                                  "<bad/></backend>",
                                  "Element <backend>: expected <marc> or "
                                  "<xslt> element, got <bad>", 0));

#if YAZ_HAVE_XSLT
    YAZ_CHECK(conv_configure_test("<backend syntax='usmarc' name='F'>"
                                  "<xslt stylesheet=\"tst_record_conv.xsl\"/>"
                                  "<marc"
                                  " inputcharset=\"marc-8\""
                                  " outputcharset=\"marc-8\""
                                  "/>"
                                  "</backend>",
                                  "Element <marc>: attribute 'inputformat' "
                                  "required", 0));
    YAZ_CHECK(conv_configure_test("<backend syntax='usmarc' name='F'>"
                                  "<xslt/>"
                                  "</backend>",
                                  "Element <xslt>: attribute 'stylesheet' "
                                  "expected", 0));
    YAZ_CHECK(conv_configure_test("<backend syntax='usmarc' name='F'>"
                                  "<marc"
                                  " inputcharset=\"utf-8\""
                                  " outputcharset=\"marc-8\""
                                  " inputformat=\"xml\""
                                  " outputformat=\"marc\""
                                  "/>"
                                  "<xslt stylesheet=\"tst_record_conv.xsl\"/>"
                                  "</backend>",
                                  0, 0));
#else
    YAZ_CHECK(conv_configure_test("<backend syntax='usmarc' name='F'>"
                                  "<xslt stylesheet=\"tst_record_conv.xsl\"/>"
                                  "</backend>",
                                  "xslt unsupported."
                                  " YAZ compiled without XSLT support", 0));
#endif 
}

static int conv_convert_test(yaz_record_conv_t p,
                             const char *input_record,
                             const char *output_expect_record)
{
    int ret = 0;
    if (!p)
    {
        YAZ_CHECK(ret);
    }
    else
    {
        WRBUF output_record = wrbuf_alloc();
        int r = yaz_record_conv_record(p, input_record, strlen(input_record),
                                       output_record);
        if (r)
        {
            if (output_expect_record)
            {
                printf("yaz_record_conv error=%s\n",
                       yaz_record_conv_get_error(p));
                ret = 0;
            }
            else
                ret = 1;
        }
        else
        {
            if (!output_expect_record)
            {
                ret = 0;
            }
            else if (strlen(output_expect_record) != wrbuf_len(output_record))
            {
                int expect_len = strlen(output_expect_record);
                ret = 0;
                printf("output_record expect-len=%d got-len=%d\n", expect_len,
                       wrbuf_len(output_record));
                printf("got-output_record = %.*s\n",
                       wrbuf_len(output_record), wrbuf_buf(output_record));
                printf("output_expect_record = %s\n",
                       output_expect_record);
            }
            else if (memcmp(output_expect_record, wrbuf_buf(output_record),
                            strlen(output_expect_record)))
            {
                ret = 0;
                printf("got-output_record = %.*s\n",
                       wrbuf_len(output_record), wrbuf_buf(output_record));
                printf("output_expect_record = %s\n",
                       output_expect_record);
            }
            else
            {
                ret = 1;
            }
        }
        wrbuf_free(output_record, 1);
    }
    return ret;
}

static void tst_convert1(void)
{
    yaz_record_conv_t p = 0;
    const char *marcxml_rec =
        "<record xmlns=\"http://www.loc.gov/MARC21/slim\">\n"
        "  <leader>00080nam a22000498a 4500</leader>\n"
        "  <controlfield tag=\"001\">   11224466 </controlfield>\n"
        "  <datafield tag=\"010\" ind1=\" \" ind2=\" \">\n"
        "    <subfield code=\"a\">   11224466 </subfield>\n"
        "  </datafield>\n"
        "</record>\n";
    const char *iso2709_rec =
        "\x30\x30\x30\x38\x30\x6E\x61\x6D\x20\x61\x32\x32\x30\x30\x30\x34"
        "\x39\x38\x61\x20\x34\x35\x30\x30\x30\x30\x31\x30\x30\x31\x33\x30"
        "\x30\x30\x30\x30\x30\x31\x30\x30\x30\x31\x37\x30\x30\x30\x31\x33"
        "\x1E\x20\x20\x20\x31\x31\x32\x32\x34\x34\x36\x36\x20\x1E\x20\x20"
        "\x1F\x61\x20\x20\x20\x31\x31\x32\x32\x34\x34\x36\x36\x20\x1E\x1D";

    YAZ_CHECK(conv_configure_test("<backend>"
                                  "<marc"
                                  " inputcharset=\"utf-8\""
                                  " outputcharset=\"marc-8\""
                                  " inputformat=\"xml\""
                                  " outputformat=\"marc\""
                                  "/>"
                                  "</backend>",
                                  0, &p));
    YAZ_CHECK(conv_convert_test(p, marcxml_rec, iso2709_rec));
    yaz_record_conv_destroy(p);

    YAZ_CHECK(conv_configure_test("<backend>"
                                  "<marc"
                                  " outputcharset=\"utf-8\""
                                  " inputcharset=\"marc-8\""
                                  " outputformat=\"marcxml\""
                                  " inputformat=\"marc\""
                                  "/>"
                                  "</backend>",
                                  0, &p));
    YAZ_CHECK(conv_convert_test(p, iso2709_rec, marcxml_rec));
    yaz_record_conv_destroy(p);


    YAZ_CHECK(conv_configure_test("<backend>"
                                  "<xslt stylesheet=\"tst_record_conv.xsl\"/>"
                                  "<xslt stylesheet=\"tst_record_conv.xsl\"/>"
                                  "<marc"
                                  " inputcharset=\"utf-8\""
                                  " outputcharset=\"marc-8\""
                                  " inputformat=\"xml\""
                                  " outputformat=\"marc\""
                                  "/>"
                                  "<marc"
                                  " outputcharset=\"utf-8\""
                                  " inputcharset=\"marc-8\""
                                  " outputformat=\"marcxml\""
                                  " inputformat=\"marc\""
                                  "/>"
                                  "</backend>",
                                  0, &p));
    YAZ_CHECK(conv_convert_test(p, marcxml_rec, marcxml_rec));
    yaz_record_conv_destroy(p);


    YAZ_CHECK(conv_configure_test("<backend>"
                                  "<xslt stylesheet=\"tst_record_conv.xsl\"/>"
                                  "<xslt stylesheet=\"tst_record_conv.xsl\"/>"
                                  "<marc"
                                  " outputcharset=\"marc-8\""
                                  " inputformat=\"xml\""
                                  " outputformat=\"marc\""
                                  "/>"
                                  "<marc"
                                  " inputcharset=\"marc-8\""
                                  " outputformat=\"marcxml\""
                                  " inputformat=\"marc\""
                                  "/>"
                                  "</backend>",
                                  0, &p));
    YAZ_CHECK(conv_convert_test(p, marcxml_rec, marcxml_rec));
    yaz_record_conv_destroy(p);
}

static void tst_convert2(void)
{
    yaz_record_conv_t p = 0;
    const char *marcxml_rec =
        "<record xmlns=\"http://www.loc.gov/MARC21/slim\">\n"
        "  <leader>00080nam a22000498a 4500</leader>\n"
        "  <controlfield tag=\"001\">   11224466 </controlfield>\n"
        "  <datafield tag=\"010\" ind1=\" \" ind2=\" \">\n"
        "    <subfield code=\"a\">k&#xf8;benhavn</subfield>\n"
        "  </datafield>\n"
        "</record>\n";
    const char *iso2709_rec =
        "\x30\x30\x30\x37\x37\x6E\x61\x6D\x20\x61\x32\x32\x30\x30\x30\x34"
        "\x39\x38\x61\x20\x34\x35\x30\x30\x30\x30\x31\x30\x30\x31\x33\x30"
        "\x30\x30\x30\x30\x30\x31\x30\x30\x30\x31\x34\x30\x30\x30\x31\x33"
        "\x1E\x20\x20\x20\x31\x31\x32\x32\x34\x34\x36\x36\x20\x1E\x20\x20"
        "\x1F\x61\x6b\xb2\x62\x65\x6e\x68\x61\x76\x6e\x1E\x1D";

    YAZ_CHECK(conv_configure_test("<backend>"
                                  "<marc"
                                  " inputcharset=\"utf-8\""
                                  " outputcharset=\"marc-8\""
                                  " inputformat=\"xml\""
                                  " outputformat=\"marc\""
                                  "/>"
                                  "</backend>",
                                  0, &p));
    YAZ_CHECK(conv_convert_test(p, marcxml_rec, iso2709_rec));
    yaz_record_conv_destroy(p);
}

#endif

int main(int argc, char **argv)
{
    YAZ_CHECK_INIT(argc, argv);
    libxml2_error_to_yazlog(0 /* disable log */, 0);
#if YAZ_HAVE_XML2
    tst_configure();
#endif
#if  YAZ_HAVE_XSLT 
    tst_convert1();
    tst_convert2();
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

