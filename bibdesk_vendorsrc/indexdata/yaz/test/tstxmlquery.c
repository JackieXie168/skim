/*
 * Copyright (C) 1995-2007, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: tstxmlquery.c,v 1.14 2007/01/03 08:42:16 adam Exp $
 */

#include <stdlib.h>
#include <stdio.h>

#include <yaz/wrbuf.h>
#include <yaz/querytowrbuf.h>
#include <yaz/xmlquery.h>
#include <yaz/pquery.h>
#include <yaz/test.h>

#if YAZ_HAVE_XML2
#include <libxml/parser.h>
#include <libxml/tree.h>
#endif

enum pqf2xml_status {
    PQF_FAILED,
    QUERY2XML_FAILED,
    XML_NO_MATCH,
    XML_MATCH,
    XML_NO_ERROR
};

enum pqf2xml_status pqf2xml_text(const char *pqf, const char *expect_xml,
                                 const char *expect_pqf)
{
    YAZ_PQF_Parser parser = yaz_pqf_create();
    ODR odr = odr_createmem(ODR_ENCODE);
    Z_RPNQuery *rpn;
    enum pqf2xml_status status = XML_NO_ERROR;

    YAZ_CHECK(parser);

    YAZ_CHECK(odr);

    rpn = yaz_pqf_parse(parser, odr, pqf);

    yaz_pqf_destroy(parser);

    if (!rpn)
        status = PQF_FAILED;
    else
    {
#if YAZ_HAVE_XML2
        xmlDocPtr doc = 0;

        yaz_rpnquery2xml(rpn, &doc);
        
        if (!doc)
            status = QUERY2XML_FAILED;
        else
        {
            char *buf_out;
            int len_out;

            xmlDocDumpMemory(doc, (xmlChar **) &buf_out, &len_out);
            
            if (len_out == strlen(expect_xml)
                && memcmp(buf_out, expect_xml, len_out) == 0)
            {
                Z_Query *query2 = 0;
                int error_code = 0;
                const char *addinfo = 0;
                const xmlNode *root_element = xmlDocGetRootElement(doc);
                ODR odr2 = odr_createmem(ODR_ENCODE);
                
                yaz_xml2query(root_element, &query2, odr2,
                              &error_code, &addinfo);
                if (error_code || !query2)
                    status = XML_NO_MATCH;
                else
                {
                    WRBUF w = wrbuf_alloc();
                    yaz_query_to_wrbuf(w, query2);
                    if (!expect_pqf || strcmp(expect_pqf, wrbuf_buf(w)) == 0)
                        status = XML_MATCH;
                    else
                    {
                        status = XML_NO_MATCH;
                        printf("Result: %s\n", wrbuf_buf(w));
                    }
                    wrbuf_free(w, 1);
                }
                odr_destroy(odr2);
            }
            else
            {
                printf("%.*s\n", len_out, buf_out);
                status = XML_NO_MATCH;
            }
            xmlFreeDoc(doc);
        }
#else
        status = QUERY2XML_FAILED;
#endif
    }
    odr_destroy(odr);
    return status;
}

static void tst(void)
{
    YAZ_CHECK_EQ(pqf2xml_text("@attr 1=4 bad query", "", 0), PQF_FAILED);
#if YAZ_HAVE_XML2
    YAZ_CHECK_EQ(pqf2xml_text(
                     "@attr 1=4 computer", 
                     "<?xml version=\"1.0\"?>\n"
                     "<query><rpn set=\"Bib-1\">"
                     "<apt><attr type=\"1\" value=\"4\"/>"
                     "<term type=\"general\">computer</term></apt>"
                     "</rpn></query>\n",
                     "RPN @attrset Bib-1 @attr 1=4 computer"
                     ), XML_MATCH);
    
    YAZ_CHECK_EQ(pqf2xml_text(
                     "@attr 2=1 @attr 1=title computer",
                     "<?xml version=\"1.0\"?>\n"
                     "<query><rpn set=\"Bib-1\">"
                     "<apt><attr type=\"1\" value=\"title\"/>"
                     "<attr type=\"2\" value=\"1\"/>"
                     "<term type=\"general\">computer</term></apt>"
                     "</rpn></query>\n",
                     "RPN @attrset Bib-1 @attr \"1=title\" @attr 2=1 computer"
                     ), XML_MATCH);

    YAZ_CHECK_EQ(pqf2xml_text(
                     "@attr 2=1 @attr exp1 1=1 computer",
                     "<?xml version=\"1.0\"?>\n"
                     "<query><rpn set=\"Bib-1\">"
                     "<apt><attr set=\"Exp-1\" type=\"1\" value=\"1\"/>"
                     "<attr type=\"2\" value=\"1\"/>"
                     "<term type=\"general\">computer</term></apt>"
                     "</rpn></query>\n",
                     "RPN @attrset Bib-1 @attr Exp-1 1=1 @attr 2=1 computer"
                     ), XML_MATCH);
    
    YAZ_CHECK_EQ(pqf2xml_text(
                     "@and a b", 
                     "<?xml version=\"1.0\"?>\n"
                     "<query><rpn set=\"Bib-1\">"
                     "<operator type=\"and\">"
                     "<apt><term type=\"general\">a</term></apt>"
                     "<apt><term type=\"general\">b</term></apt>"
                     "</operator></rpn></query>\n",
                     "RPN @attrset Bib-1 @and a b"
                     ), XML_MATCH);
    
    YAZ_CHECK_EQ(pqf2xml_text(
                     "@or @and a b c", 
                     "<?xml version=\"1.0\"?>\n"
                     "<query><rpn set=\"Bib-1\">"
                     "<operator type=\"or\">"
                     "<operator type=\"and\">"
                     "<apt><term type=\"general\">a</term></apt>"
                     "<apt><term type=\"general\">b</term></apt></operator>"
                     "<apt><term type=\"general\">c</term></apt>"
                     "</operator></rpn></query>\n",
                     "RPN @attrset Bib-1 @or @and a b c"
                     ), XML_MATCH);

    YAZ_CHECK_EQ(pqf2xml_text(
                     "@set abe", 
                     "<?xml version=\"1.0\"?>\n"
                     "<query><rpn set=\"Bib-1\">"
                     "<rset>abe</rset></rpn></query>\n",
                     "RPN @attrset Bib-1 @set abe"
                     ), XML_MATCH);

    YAZ_CHECK_EQ(pqf2xml_text(
                     /* exclusion, distance, ordered, relationtype, 
                        knownunit, proxunit */
                     "@prox 0 3 1 2 k 2           a b", 
                     "<?xml version=\"1.0\"?>\n"
                     "<query><rpn set=\"Bib-1\">"
                     "<operator type=\"prox\" exclusion=\"false\" "
                     "distance=\"3\" "
                     "ordered=\"true\" "
                     "relationType=\"2\" "
                     "knownProximityUnit=\"2\">"
                     "<apt><term type=\"general\">a</term></apt>"
                     "<apt><term type=\"general\">b</term></apt>"
                     "</operator></rpn></query>\n",
                     "RPN @attrset Bib-1 @prox 0 3 1 2 k 2 a b"
                     ), XML_MATCH);

    YAZ_CHECK_EQ(pqf2xml_text(
                     "@term numeric 32", 
                     "<?xml version=\"1.0\"?>\n"
                     "<query><rpn set=\"Bib-1\">"
                     "<apt>"
                     "<term type=\"numeric\">32</term></apt>"
                     "</rpn></query>\n",
                     "RPN @attrset Bib-1 @term numeric 32"
                     ), XML_MATCH);
    
    YAZ_CHECK_EQ(pqf2xml_text(
                     "@term string computer", 
                     "<?xml version=\"1.0\"?>\n"
                     "<query><rpn set=\"Bib-1\">"
                     "<apt>"
                     "<term type=\"string\">computer</term></apt>"
                     "</rpn></query>\n",
                     "RPN @attrset Bib-1 @term string computer"
                     ), XML_MATCH);
    
    YAZ_CHECK_EQ(pqf2xml_text(
                     "@term null void", 
                     "<?xml version=\"1.0\"?>\n"
                     "<query><rpn set=\"Bib-1\">"
                     "<apt>"
                     "<term type=\"null\"/></apt>"
                     "</rpn></query>\n",
                     "RPN @attrset Bib-1 @term null x"
                     ), XML_MATCH);

    YAZ_CHECK_EQ(pqf2xml_text(
                     "@attrset gils @attr 4=2 x", 
                     "<?xml version=\"1.0\"?>\n"
                     "<query><rpn set=\"GILS\">"
                     "<apt>"
                     "<attr type=\"4\" value=\"2\"/>"
                     "<term type=\"general\">x</term></apt>"
                     "</rpn></query>\n",
                     "RPN @attrset GILS @attr 4=2 x"
                     ), XML_MATCH);
#endif
}

int main (int argc, char **argv)
{
    YAZ_CHECK_INIT(argc, argv);
    tst();
    YAZ_CHECK_TERM;
}

/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

