/*
 * Copyright (C) 1995-2005, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: srwtst.c,v 1.5 2006/07/06 10:17:55 adam Exp $
 */

#include <stdlib.h>
#include <yaz/srw.h>

#if YAZ_HAVE_XML2
Z_SOAP_Handler h[2] = {
    {"http://www.loc.gov/zing/srw/v1.0/", 0, (Z_SOAP_fun) yaz_srw_codec},
    {0, 0, 0}
};

int main(int argc, char **argv)
{
    char buf[163840];
    char *content_buf = buf;
    int content_len;
    int ret;
    size_t no;
    Z_SOAP *soap_package = 0;
    ODR decode, encode;
    int debug = 0;

    nmem_init();
    if (argc == 2 && !strcmp(argv[1], "debug"))
        debug = 1;
    no = fread(buf, 1, sizeof(buf), stdin);
    if (no < 1 || no == sizeof(buf))
    {
        fprintf(stderr, "Bad file or too big\n");
        exit (1);
    }
    decode = odr_createmem(ODR_DECODE);
    encode = odr_createmem(ODR_ENCODE);
    content_len = no;
    ret = z_soap_codec(decode, &soap_package, 
                       &content_buf, &content_len, h);
    if (!soap_package)
    {
        fprintf(stderr, "Decoding seriously failed\n");
        exit(1);
    }
    if (debug)
    {
        fprintf(stderr, "got NS = %s\n", soap_package->ns);
        if (soap_package->which == Z_SOAP_generic &&
            soap_package->u.generic->no == 0)
        {
            Z_SRW_PDU *sr = soap_package->u.generic->p;
            if (sr->which == Z_SRW_searchRetrieve_request)
            { 
                Z_SRW_searchRetrieveRequest *req = sr->u.request;
                switch(req->query_type)
                {
                case Z_SRW_query_type_cql:
                    fprintf(stderr, "CQL: %s\n", req->query.cql);
                    break;
                case Z_SRW_query_type_xcql:
                    fprintf(stderr, "XCQL\n");
                    break;
                case Z_SRW_query_type_pqf:
                    fprintf(stderr, "PQF: %s\n", req->query.pqf);
                    break;
                }
            }
            else if (sr->which == Z_SRW_searchRetrieve_response)
            {
                Z_SRW_searchRetrieveResponse *res = sr->u.response;
                if (res->records && res->num_records)
                {
                    int i;
                    for (i = 0; i<res->num_records; i++)
                    {
                        fprintf (stderr, "%d\n", i);
                        if (res->records[i].recordData_buf)
                            fwrite(res->records[i].recordData_buf, 1,
                                   res->records[i].recordData_len, stderr);
                    }
                }
            }

        }
    }
    ret = z_soap_codec(encode, &soap_package,
                       &content_buf, &content_len, h);
    if (content_buf && content_len)
        fwrite (content_buf, content_len, 1, stdout);
    else
    {
        fprintf(stderr, "No output!\n");
        exit(1);
    }
    odr_destroy(decode);
    odr_destroy(encode);
    nmem_exit();
    exit(0);
}
#else
int main(int argc, char **argv)
{
    fprintf(stderr, "SOAP disabled\n");
    exit(1);
}
#endif
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

