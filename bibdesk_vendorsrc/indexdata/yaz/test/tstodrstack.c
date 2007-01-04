/*
 * Copyright (C) 1995-2005, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: tstodrstack.c,v 1.5 2006/10/04 16:59:34 mike Exp $
 *
 */
#include <stdlib.h>
#include <yaz/pquery.h>
#include <yaz/proto.h>
#include <yaz/test.h>

/** \brief build a 100 level query */
void test1(void)
{
    ODR odr = odr_createmem(ODR_ENCODE);
    YAZ_PQF_Parser parser = yaz_pqf_create();
    Z_RPNQuery *rpn_query;
    char qstr[10000];
    int i;
    int ret;

    YAZ_CHECK(odr);
    YAZ_CHECK(parser);

    *qstr = '\0';
    for (i = 0; i<100; i++)
        strcat(qstr, "@and 1 ");
    strcat(qstr, "1");

    rpn_query = yaz_pqf_parse (parser, odr, qstr);
    YAZ_CHECK(rpn_query);

    ret = z_RPNQuery(odr, &rpn_query, 0, 0);
    YAZ_CHECK(ret);

    yaz_pqf_destroy(parser);
    odr_destroy(odr);
}

/** \brief build a circular referenced query */
void test2(void)
{
    ODR odr = odr_createmem(ODR_ENCODE);
    YAZ_PQF_Parser parser = yaz_pqf_create();
    Z_RPNQuery *rpn_query;
    int ret;

    YAZ_CHECK(odr);

    rpn_query = yaz_pqf_parse (parser, odr, "@and @and a b c");
    YAZ_CHECK(rpn_query);

    /* make the circular reference */
    rpn_query->RPNStructure->u.complex->s1 = rpn_query->RPNStructure;

    ret = z_RPNQuery(odr, &rpn_query, 0, 0);  /* should fail */
    YAZ_CHECK(!ret);

    yaz_pqf_destroy(parser);
    odr_destroy(odr);
}

int main(int argc, char **argv)
{
    YAZ_CHECK_INIT(argc, argv);
    test1();
    test2();
    YAZ_CHECK_TERM;
}
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */
