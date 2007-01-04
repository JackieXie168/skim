/*
 * Copyright (C) 1995-2005, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: tstodr.c,v 1.8 2006/01/29 21:59:13 adam Exp $
 *
 */
#include <stdlib.h>
#include <stdio.h>
#include <yaz/odr.h>
#include <yaz/oid.h>
#include "tstodrcodec.h"

#include <yaz/test.h>

#define MYOID  "1.2.3.4.5.6.7.8.9.10.11.12.13.14.15.16.17.18.19"

void tst_MySequence1(ODR encode, ODR decode)
{
    int ret;
    char *ber_buf;
    int ber_len;
    Yc_MySequence *s = odr_malloc(encode, sizeof(*s));
    Yc_MySequence *t;

    YAZ_CHECK(s);
    s->first = odr_intdup(encode, 12345);
    s->second = odr_malloc(encode, sizeof(*s->second));
    s->second->buf = (unsigned char *) "hello";
    s->second->len = 5;
    s->second->size = 0;
    s->third = odr_intdup(encode, 1);
    s->fourth = odr_nullval();
    s->fifth = odr_intdup(encode, YC_MySequence_enum1);
    
    s->myoid = odr_getoidbystr(decode, MYOID);

    ret = yc_MySequence(encode, &s, 0, 0);
    YAZ_CHECK(ret);
    if (!ret)
        return;
    
    ber_buf = odr_getbuf(encode, &ber_len, 0);

    odr_setbuf(decode, ber_buf, ber_len, 0);

    ret = yc_MySequence(decode, &t, 0, 0);
    YAZ_CHECK(ret);
    if (!ret)
        return;

    YAZ_CHECK(t);

    YAZ_CHECK(t->first && *t->first == 12345);

    YAZ_CHECK(t->second && t->second->buf && t->second->len == 5);

    YAZ_CHECK(t->second && t->second->buf && t->second->len == 5 &&
              memcmp(t->second->buf, "hello", t->second->len) == 0);

    YAZ_CHECK(t->third && *t->third == 1);

    YAZ_CHECK(t->fourth);

    YAZ_CHECK(t->fifth && *t->fifth == YC_MySequence_enum1);

    YAZ_CHECK(t->myoid);
    if (t->myoid)
    {
        int *myoid = odr_getoidbystr(decode, MYOID);

        YAZ_CHECK(oid_oidcmp(myoid, t->myoid) == 0);
    }
}

void tst_MySequence2(ODR encode, ODR decode)
{
    int ret;
    Yc_MySequence *s = odr_malloc(encode, sizeof(*s));

    YAZ_CHECK(s);
    s->first = 0;  /* deliberately miss this .. */
    s->second = odr_malloc(encode, sizeof(*s->second));
    s->second->buf = (unsigned char *) "hello";
    s->second->len = 5;
    s->second->size = 0;
    s->third = odr_intdup(encode, 1);
    s->fourth = odr_nullval();
    s->fifth = odr_intdup(encode, YC_MySequence_enum1);
    s->myoid = odr_getoidbystr(encode, MYOID);

    ret = yc_MySequence(encode, &s, 0, 0); /* should fail */
    YAZ_CHECK(!ret);

    YAZ_CHECK(odr_geterror(encode) == OREQUIRED);

    YAZ_CHECK(strcmp(odr_getelement(encode), "first") == 0);
    odr_reset(encode);

    YAZ_CHECK(odr_geterror(encode) == ONONE);

    YAZ_CHECK(strcmp(odr_getelement(encode), "") == 0);
}

void tst_MySequence3(ODR encode, ODR decode)
{
    char buf[40];
    int i;
    Yc_MySequence *t;

    srand(123);
    for (i = 0; i<1000; i++)
    {
        int j;
        for (j = 0; j<sizeof(buf); j++)
            buf[j] = rand();

        for (j = 1; j<sizeof(buf); j++)
        {
            odr_setbuf(decode, buf, j, 0);
            yc_MySequence(decode, &t, 0, 0);
            odr_reset(decode);
        }
    }
}

static void tst(void)
{
    ODR odr_encode = odr_createmem(ODR_ENCODE);
    ODR odr_decode = odr_createmem(ODR_DECODE);

    YAZ_CHECK(odr_encode);
    YAZ_CHECK(odr_decode);

    tst_MySequence1(odr_encode, odr_decode);
    tst_MySequence2(odr_encode, odr_decode);
    tst_MySequence3(odr_encode, odr_decode);

    odr_destroy(odr_encode);
    odr_destroy(odr_decode);
}

int main(int argc, char **argv)
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

