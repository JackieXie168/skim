/*
 * Copyright (C) 1995-2007, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: yaz-xmlquery.c,v 1.6 2007/01/03 08:42:16 adam Exp $
 */

#include <stdlib.h>
#include <stdio.h>

#include <yaz/options.h>
#include <yaz/querytowrbuf.h>
#include <yaz/xmlquery.h>
#include <yaz/pquery.h>
#include <yaz/test.h>

#if YAZ_HAVE_XML2
#include <libxml/parser.h>
#endif

static char *prog = "yaz-xmlquery";

#if YAZ_HAVE_XML2
void pqftoxmlquery(const char *pqf)
{
    YAZ_PQF_Parser parser = yaz_pqf_create();
    ODR odr = odr_createmem(ODR_ENCODE);
    Z_RPNQuery *rpn;

    if (!parser)
    {
	fprintf(stderr, "%s: cannot create parser\n", prog);
	exit(1);
    }

    if (!odr)
    {
	fprintf(stderr, "%s: cannot create parser\n", prog);
	exit(1);
    }

    rpn = yaz_pqf_parse(parser, odr, pqf);

    yaz_pqf_destroy(parser);

    if (!rpn)
    {
	fprintf(stderr, "%s: pqf parse error for query %s\n", prog, pqf);
	exit(2);
    }
    else
    {
	xmlDocPtr doc = 0;
	
        yaz_rpnquery2xml(rpn, &doc);
        
        if (!doc)
	{
	    fprintf(stderr, "%s: yaz_rpnquery2xml failed for query %s\n",
		    prog, pqf);
	    exit(3);
	}
        else
        {
            xmlChar *buf_out = 0;
            int len_out = 0;

            xmlDocDumpMemory(doc, &buf_out, &len_out);

            if (!len_out || !buf_out)
	    {
		fprintf(stderr, "%s: xmlDocDumpMemory failed for query %s\n",
			prog, pqf);
		exit(4);
	    }
	    else
		fwrite(buf_out, len_out, 1, stdout);
            xmlFreeDoc(doc);
	}
    }    
    odr_destroy(odr);
}


void xmlquerytopqf(const char *xmlstr)
{
    xmlDocPtr doc;

    doc = xmlParseMemory(xmlstr, strlen(xmlstr));
    if (!doc)
    {
	fprintf(stderr, "%s: xml parse error for XML:\n%s\n", prog, xmlstr);
	exit(1);
    }
    else
    {
	int error_code = 0;
	const char *addinfo = 0;
	Z_Query *query = 0;
	ODR odr = odr_createmem(ODR_ENCODE);

	const xmlNode *root_element = xmlDocGetRootElement(doc);
	yaz_xml2query(root_element, &query, odr, &error_code, &addinfo);
	if (error_code)
	{
	    fprintf(stderr, "%s: yaz_xml2query failed code=%d addinfo=%s\n",
		    prog, error_code, addinfo);
	    exit(1);
	}
	else if (!query)
	{
	    fprintf(stderr, "%s: yaz_xml2query no query result\n",
		    prog);
	    exit(1);
	}
	else
	{
	    WRBUF w = wrbuf_alloc();
	    yaz_query_to_wrbuf(w, query);
	    printf("%s\n", wrbuf_buf(w));
	    wrbuf_free(w, 1);
	}
	odr_destroy(odr);
	xmlFreeDoc(doc);
    }
}

void xmlfiletopqf(const char *xmlfile)
{
    long sz;
    char *xmlstr;
    FILE *f = fopen(xmlfile, "rb");
    if (!f)
    {
	fprintf(stderr, "%s: cannot open %s\n", prog, xmlfile);
	exit(1);
    }
    fseek(f, 0, SEEK_END);
    sz = ftell(f);
    if (sz <= 0 || sz >= 1<<18)
    {
	fprintf(stderr, "%s: bad size for file %s\n", prog, xmlfile);
	exit(1);
    }
    rewind(f);
    xmlstr = xmalloc(sz+1);
    xmlstr[sz] = '\0';
    fread(xmlstr, sz, 1, f);
    fclose(f);
    
    xmlquerytopqf(xmlstr);
    xfree(xmlstr);
}
#endif

void usage(void)
{
    fprintf(stderr, "%s [-p pqf] [-x xmlfile]\n", prog);
    fprintf(stderr, " -p pqf      reads pqf. write xml to stdout\n");
    fprintf(stderr, " -x xmlfile  reads XML from file. write pqf to stdout\n");
    exit(1);
}

int main (int argc, char **argv)
{
#if YAZ_HAVE_XML2
    char *arg;
    int r;
    int active = 0;

    while ((r = options("-p:x:", argv, argc, &arg)) != -2)
    {
	switch(r)
	{
	case 'p':
	    pqftoxmlquery(arg);
	    active = 1;
	    break;
	case 'x':
	    xmlfiletopqf(arg);
	    active = 1;
	    break;
	case 0:
	    break;
	}
    }
    if (!active)
    {
	fprintf(stderr, "%s: nothing to do\n", prog);
	usage();
    }
#else
    fprintf(stderr, "%s: XML support not enabled.\n", prog);
    exit(1);
#endif
    return 0;
}

