/*
 * Copyright (C) 1995-2005, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: tstsoap1.c,v 1.8 2006/10/04 16:59:34 mike Exp $
 */

#include <stdlib.h>
#if YAZ_HAVE_XML2
#include <libxml/parser.h>
#endif
#include <yaz/test.h>

void tst(void)
{
#if YAZ_HAVE_XML2
    xmlChar *buf_out;
    int len_out;
    xmlDocPtr doc;
    xmlNodePtr top;
#if 0
    const char *val = "jordbær"; /* makes xmlDocDumpMemory hang .. */
#else
    const char *val = "jordbaer"; /* OK */
#endif
    doc = xmlNewDoc(BAD_CAST "1.0");
    YAZ_CHECK(doc);

    top = xmlNewNode(0, BAD_CAST "top");
    YAZ_CHECK(top);
    
    xmlNewTextChild(top, 0, BAD_CAST "sub", BAD_CAST val);
    xmlDocSetRootElement(doc, top);
    
    xmlDocDumpMemory(doc, &buf_out, &len_out);
#if 0
    printf("%*s", len_out, buf_out);
#endif


/* YAZ_HAVE_XML2 */
#endif
}

int main(int argc, char **argv)
{
    YAZ_CHECK_INIT(argc, argv);
#if YAZ_HAVE_XML2
    LIBXML_TEST_VERSION;
#endif
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

