/*
 * Copyright (C) 1995-2005, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: tstpquery.c,v 1.3 2006/10/04 16:59:34 mike Exp $
 */

#include <stdlib.h>
#include <stdio.h>

#include <yaz/wrbuf.h>
#include <yaz/querytowrbuf.h>
#include <yaz/pquery.h>
#include <yaz/test.h>

int expect_pqf(const char *pqf, const char *expect_pqf, int expect_error)
{
    YAZ_PQF_Parser parser = yaz_pqf_create();
    int res = 0;
    ODR odr = odr_createmem(ODR_ENCODE);
    Z_RPNQuery *rpn;

    if (!parser)
        return 0;

    if (!odr)
        return 0;

    rpn = yaz_pqf_parse(parser, odr, pqf);

    if (!rpn)
    {
        const char *msg;
        size_t offset;
        int got_error = yaz_pqf_error (parser, &msg, &offset);

        if (expect_error == got_error)
            res = 1;
    }
    else if (expect_error == YAZ_PQF_ERROR_NONE)
    {
        WRBUF wrbuf = wrbuf_alloc();
        
        if (wrbuf)
        {
            yaz_rpnquery_to_wrbuf(wrbuf, rpn);
            
            if (!strcmp(wrbuf_buf(wrbuf), expect_pqf))
                res = 1;
            wrbuf_free(wrbuf, 1);
        }
    }
    yaz_pqf_destroy(parser);
    odr_destroy(odr);
    return res;
}

static void tst(void)
{
    YAZ_CHECK(expect_pqf("a", "@attrset Bib-1 a", YAZ_PQF_ERROR_NONE));
    YAZ_CHECK(expect_pqf("@attr 1=4 a", "@attrset Bib-1 @attr 1=4 a", YAZ_PQF_ERROR_NONE));
    YAZ_CHECK(expect_pqf("a b", "", YAZ_PQF_ERROR_EXTRA));
    YAZ_CHECK(expect_pqf("@and a", "", YAZ_PQF_ERROR_MISSING));
    YAZ_CHECK(expect_pqf("@attr p=q a", "", YAZ_PQF_ERROR_BAD_INTEGER));
    YAZ_CHECK(expect_pqf("@prox 0 0 0 0 k 0 a b",
                         "@attrset Bib-1 @prox 0 0 0 0 k 0 a b",
                         YAZ_PQF_ERROR_NONE));
    YAZ_CHECK(expect_pqf("@prox 0 0 0 0 3 0 a b", "",
                         YAZ_PQF_ERROR_PROXIMITY));
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

