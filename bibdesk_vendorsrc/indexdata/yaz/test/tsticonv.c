/*
 * Copyright (C) 1995-2006, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: tsticonv.c,v 1.23 2006/10/04 16:59:34 mike Exp $
 */

#if HAVE_CONFIG_H
#include <config.h>
#endif

#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <ctype.h>

#include <yaz/yaz-util.h>
#include <yaz/test.h>

static int compare_buffers(char *msg, int no,
                           int expect_len, const char *expect_buf,
                           int got_len, const char *got_buf)
{
    if (expect_len == got_len
        && !memcmp(expect_buf, got_buf, expect_len))
        return 1;
    
    if (0) /* use 1 see how the buffers differ (for debug purposes) */
    {
        int i;
        printf("tsticonv test=%s i=%d failed\n", msg, no);
        printf("off got exp\n");
        for (i = 0; i<got_len || i<expect_len; i++)
        {
            char got_char[10];
            char expect_char[10];
            
            if (i < got_len)
                sprintf(got_char, "%02X", got_buf[i]);
            else
                sprintf(got_char, "?  ");
            
            if (i < expect_len)
                sprintf(expect_char, "%02X", expect_buf[i]);
            else
                sprintf(expect_char, "?  ");
            
            printf("%02d  %s  %s %c\n",
                   i, got_char, expect_char, got_buf[i] == expect_buf[i] ?
                   ' ' : '*');
            
        }
    }
    return 0;
}

static int tst_convert_l(yaz_iconv_t cd, size_t in_len, const char *in_buf,
                         size_t expect_len, const char *expect_buf)
{
    size_t r;
    char *inbuf= (char*) in_buf;
    size_t inbytesleft = in_len > 0 ? in_len : strlen(in_buf);
    char outbuf0[64];
    char *outbuf = outbuf0;

    while (inbytesleft)
    {
        size_t outbytesleft = outbuf0 + sizeof(outbuf0) - outbuf;
        if (outbytesleft > 12)
            outbytesleft = 12;
        r = yaz_iconv(cd, &inbuf, &inbytesleft, &outbuf, &outbytesleft);
        if (r == (size_t) (-1))
        {
            int e = yaz_iconv_error(cd);
            if (e != YAZ_ICONV_E2BIG)
                return 0;
        }
        else
            break;
    }
    return compare_buffers("tsticonv 22", 0,
                           expect_len, expect_buf,
                           outbuf - outbuf0, outbuf0);
}

static int tst_convert(yaz_iconv_t cd, const char *buf, const char *cmpbuf)
{
    int ret = 0;
    WRBUF b = wrbuf_alloc();
    char outbuf[12];
    size_t inbytesleft = strlen(buf);
    const char *inp = buf;
    while (inbytesleft)
    {
        size_t outbytesleft = sizeof(outbuf);
        char *outp = outbuf;
        size_t r = yaz_iconv(cd, (char**) &inp,  &inbytesleft,
                             &outp, &outbytesleft);
        if (r == (size_t) (-1))
        {
            int e = yaz_iconv_error(cd);
            if (e != YAZ_ICONV_E2BIG)
                break;
        }
        wrbuf_write(b, outbuf, outp - outbuf);
    }
    if (wrbuf_len(b) == strlen(cmpbuf) 
        && !memcmp(cmpbuf, wrbuf_buf(b), wrbuf_len(b)))
        ret = 1;
    else
        yaz_log(YLOG_LOG, "GOT (%.*s)", wrbuf_len(b), wrbuf_buf(b));
    wrbuf_free(b, 1);
    return ret;
}


/* some test strings in ISO-8859-1 format */
static const char *iso_8859_1_a[] = {
    "ax" ,
    "\xd8",
    "eneb\346r",
    "\xe5" "\xd8",
    "\xe5" "\xd8" "b",
    "\xe5" "\xe5",
    0 };

static void tst_marc8_to_ucs4b(void)
{
    yaz_iconv_t cd = yaz_iconv_open("UCS4", "MARC8");
    YAZ_CHECK(cd);
    if (!cd)
        return;
    
    YAZ_CHECK(tst_convert_l(
                  cd,
                  0,
                  "\033$1" "\x21\x2B\x3B" /* FF1F */ "\033(B" "o",
                  8, 
                  "\x00\x00\xFF\x1F" "\x00\x00\x00o"));
    YAZ_CHECK(tst_convert_l(
                  cd,
                  0,
                  "\033$1" "\x6F\x77\x29" /* AE0E */
                  "\x6F\x52\x7C" /* c0F4 */ "\033(B",
                  8,
                  "\x00\x00\xAE\x0E" "\x00\x00\xC0\xF4"));
    YAZ_CHECK(tst_convert_l(
                  cd,
                  0,
                  "\033$1"
                  "\x21\x50\x6E"  /* UCS 7CFB */
                  "\x21\x51\x31"  /* UCS 7D71 */
                  "\x21\x3A\x67"  /* UCS 5B89 */
                  "\x21\x33\x22"  /* UCS 5168 */
                  "\x21\x33\x53"  /* UCS 5206 */
                  "\x21\x44\x2B"  /* UCS 6790 */
                  "\033(B",
                  24, 
                  "\x00\x00\x7C\xFB"
                  "\x00\x00\x7D\x71"
                  "\x00\x00\x5B\x89"
                  "\x00\x00\x51\x68"
                  "\x00\x00\x52\x06"
                  "\x00\x00\x67\x90"));

    YAZ_CHECK(tst_convert_l(
                  cd,
                  0,
                  "\xB0\xB2",     /* AYN and oSLASH */
                  8, 
                  "\x00\x00\x02\xBB"  "\x00\x00\x00\xF8"));
    YAZ_CHECK(tst_convert_l(
                  cd,
                  0,
                  "\xF6\x61",     /* a underscore */
                  8, 
                  "\x00\x00\x00\x61"  "\x00\x00\x03\x32"));

    YAZ_CHECK(tst_convert_l(
                  cd,
                  0,
                  "\x61\xC2",     /* a, phonorecord mark */
                  8,
                  "\x00\x00\x00\x61"  "\x00\x00\x21\x17"));

    /* bug #258 */
    YAZ_CHECK(tst_convert_l(
                  cd,
                  0,
                  "el" "\xe8" "am\xe8" "an", /* elaman where a is a" */
                  32,
                  "\x00\x00\x00" "e"
                  "\x00\x00\x00" "l"
                  "\x00\x00\x00" "a"
                  "\x00\x00\x03\x08"
                  "\x00\x00\x00" "m"
                  "\x00\x00\x00" "a"
                  "\x00\x00\x03\x08"
                  "\x00\x00\x00" "n"));
    /* bug #260 */
    YAZ_CHECK(tst_convert_l(
                  cd,
                  0,
                  "\xe5\xe8\x41",
                  12, 
                  "\x00\x00\x00\x41" "\x00\x00\x03\x04" "\x00\x00\x03\x08"));
    /* bug #416 */
    YAZ_CHECK(tst_convert_l(
                  cd,
                  0,
                  "\xEB\x74\xEC\x73",
                  12,
                  "\x00\x00\x00\x74" "\x00\x00\x03\x61" "\x00\x00\x00\x73"));
    /* bug #416 */
    YAZ_CHECK(tst_convert_l(
                  cd,
                  0,
                  "\xFA\x74\xFB\x73",
                  12, 
                  "\x00\x00\x00\x74" "\x00\x00\x03\x60" "\x00\x00\x00\x73"));

    yaz_iconv_close(cd);
}

static void tst_ucs4b_to_utf8(void)
{
    yaz_iconv_t cd = yaz_iconv_open("UTF8", "UCS4");
    YAZ_CHECK(cd);
    if (!cd)
        return;
    YAZ_CHECK(tst_convert_l(
                  cd,
                  8,
                  "\x00\x00\xFF\x1F\x00\x00\x00o",
                  4,
                  "\xEF\xBC\x9F\x6F"));

    YAZ_CHECK(tst_convert_l(
                  cd,
                  8, 
                  "\x00\x00\xAE\x0E\x00\x00\xC0\xF4",
                  6,
                  "\xEA\xB8\x8E\xEC\x83\xB4"));
    yaz_iconv_close(cd);
}

static void dconvert(int mandatory, const char *tmpcode)
{
    int i;
    int ret;
    yaz_iconv_t cd;
    for (i = 0; iso_8859_1_a[i]; i++)
    {
        size_t r;
        char *inbuf = (char*) iso_8859_1_a[i];
        size_t inbytesleft = strlen(inbuf);
        char outbuf0[24];
        char outbuf1[10];
        char *outbuf = outbuf0;
        size_t outbytesleft = sizeof(outbuf0);

        cd = yaz_iconv_open(tmpcode, "ISO-8859-1");
        YAZ_CHECK(cd || !mandatory);
        if (!cd)
            return;
        r = yaz_iconv(cd, &inbuf, &inbytesleft, &outbuf, &outbytesleft);
        YAZ_CHECK(r != (size_t) (-1));
        yaz_iconv_close(cd);
        if (r == (size_t) (-1))
            return;
        
        cd = yaz_iconv_open("ISO-8859-1", tmpcode);
        YAZ_CHECK(cd || !mandatory);
        if (!cd)
            return;
        inbuf = outbuf0;
        inbytesleft = sizeof(outbuf0) - outbytesleft;

        outbuf = outbuf1;
        outbytesleft = sizeof(outbuf1);
        r = yaz_iconv(cd, &inbuf, &inbytesleft, &outbuf, &outbytesleft);
        YAZ_CHECK(r != (size_t) (-1));
        if (r != (size_t)(-1)) 
        {
            ret = compare_buffers("dconvert", i,
                                  strlen(iso_8859_1_a[i]), iso_8859_1_a[i],
                              sizeof(outbuf1) - outbytesleft, outbuf1);
            YAZ_CHECK(ret);
        }
        yaz_iconv_close(cd);
    }
}

int utf8_check(unsigned c)
{
    if (sizeof(c) >= 4)
    {
        size_t r;
        char src[4];
        char dst[4];
        char utf8buf[6];
        char *inbuf = src;
        size_t inbytesleft = 4;
        char *outbuf = utf8buf;
        size_t outbytesleft = sizeof(utf8buf);
        int i;
        yaz_iconv_t cd = yaz_iconv_open("UTF-8", "UCS4LE");
        if (!cd)
            return 0;
        for (i = 0; i<4; i++)
            src[i] = c >> (i*8);
        
        r = yaz_iconv(cd, &inbuf, &inbytesleft, &outbuf, &outbytesleft);
        yaz_iconv_close(cd);

        if (r == (size_t)(-1))
            return 0;

        cd = yaz_iconv_open("UCS4LE", "UTF-8");
        if (!cd)
            return 0;
        inbytesleft = sizeof(utf8buf) - outbytesleft;
        inbuf = utf8buf;

        outbuf = dst;
        outbytesleft = 4;

        r = yaz_iconv(cd, &inbuf, &inbytesleft, &outbuf, &outbytesleft);
        if (r == (size_t)(-1))
            return 0;

        yaz_iconv_close(cd);

        if (memcmp(src, dst, 4))
            return 0;
    }
    return 1;
}
        
static void tst_marc8_to_utf8(void)
{
    yaz_iconv_t cd = yaz_iconv_open("UTF-8", "MARC8");

    YAZ_CHECK(cd);
    if (!cd)
        return;

    YAZ_CHECK(tst_convert(cd, "Cours de math", 
                          "Cours de math"));
    /* COMBINING ACUTE ACCENT */
    YAZ_CHECK(tst_convert(cd, "Cours de mathâe", 
                          "Cours de mathe\xcc\x81"));
    yaz_iconv_close(cd);
}

static void tst_marc8s_to_utf8(void)
{
    yaz_iconv_t cd = yaz_iconv_open("UTF-8", "MARC8s");

    YAZ_CHECK(cd);
    if (!cd)
        return;

    YAZ_CHECK(tst_convert(cd, "Cours de math", 
                          "Cours de math"));
    /* E9: LATIN SMALL LETTER E WITH ACUTE */
    YAZ_CHECK(tst_convert(cd, "Cours de mathâe", 
                          "Cours de math\xc3\xa9"));

    yaz_iconv_close(cd);
}


static void tst_marc8_to_latin1(void)
{
    yaz_iconv_t cd = yaz_iconv_open("ISO-8859-1", "MARC8");

    YAZ_CHECK(cd);
    if (!cd)
        return;

    YAZ_CHECK(tst_convert(cd, "ax", "ax"));

    /* latin capital letter o with stroke */
    YAZ_CHECK(tst_convert(cd, "\xa2", "\xd8"));

    /* with latin small letter ae */
    YAZ_CHECK(tst_convert(cd, "eneb\xb5r", "eneb\346r"));

    YAZ_CHECK(tst_convert(cd, "\xea" "a\xa2", "\xe5" "\xd8"));

    YAZ_CHECK(tst_convert(cd, "\xea" "a\xa2" "b", "\xe5" "\xd8" "b"));

    YAZ_CHECK(tst_convert(cd, "\xea" "a"  "\xea" "a", "\xe5" "\xe5"));

    YAZ_CHECK(tst_convert(cd, "Cours de math", 
                          "Cours de math"));
    YAZ_CHECK(tst_convert(cd, "Cours de mathâe", 
                          "Cours de mathé"));
    YAZ_CHECK(tst_convert(cd, "12345678âe", 
                          "12345678é"));
    YAZ_CHECK(tst_convert(cd, "123456789âe", 
                          "123456789é"));
    YAZ_CHECK(tst_convert(cd, "1234567890âe", 
                          "1234567890é"));
    YAZ_CHECK(tst_convert(cd, "12345678901âe", 
                          "12345678901é"));
    YAZ_CHECK(tst_convert(cd, "Cours de mathâem", 
                          "Cours de mathém"));
    YAZ_CHECK(tst_convert(cd, "Cours de mathâematiques", 
                          "Cours de mathématiques"));

    yaz_iconv_close(cd);
}

static void tst_utf8_to_marc8(void)
{
    yaz_iconv_t cd = yaz_iconv_open("MARC8", "UTF-8");

    YAZ_CHECK(cd);
    if (!cd)
        return;

    YAZ_CHECK(tst_convert(cd, "Cours ", "Cours "));

    /** Pure ASCII. 11 characters (sizeof(outbuf)-1) */
    YAZ_CHECK(tst_convert(cd, "Cours de mat", "Cours de mat"));

    /** Pure ASCII. 12 characters (sizeof(outbuf)) */
    YAZ_CHECK(tst_convert(cd, "Cours de math", "Cours de math"));

    /** Pure ASCII. 13 characters (sizeof(outbuf)) */
    YAZ_CHECK(tst_convert(cd, "Cours de math.", "Cours de math."));

    /** UPPERCASE SCANDINAVIAN O */
    YAZ_CHECK(tst_convert(cd, "S\xc3\x98", "S\xa2"));

    /** ARING */
    YAZ_CHECK(tst_convert(cd, "A" "\xCC\x8A", "\xEA" "A"));

    /** A MACRON + UMLAUT, DIAERESIS */
    YAZ_CHECK(tst_convert(cd, "A" "\xCC\x84" "\xCC\x88",
                          "\xE5\xE8\x41"));
    
    /* Ligature spanning two characters */
    YAZ_CHECK(tst_convert(cd,
                          "\x74" "\xCD\xA1" "\x73",  /* UTF-8 */
                          "\xEB\x74\xEC\x73"));      /* MARC-8 */

    /* Double title spanning two characters */
    YAZ_CHECK(tst_convert(cd,
                          "\x74" "\xCD\xA0" "\x73",  /* UTF-8 */
                          "\xFA\x74\xFB\x73"));      /* MARC-8 */

    /** Ideographic question mark (Unicode FF1F) */
    YAZ_CHECK(tst_convert(cd,
                          "\xEF\xBC\x9F" "o",        /* UTF-8 */
                          "\033$1" "\x21\x2B\x3B" "\033(B" "o" ));


    /** Superscript 0 . bug #642 */
    YAZ_CHECK(tst_convert(cd,
                          "(\xe2\x81\xb0)",        /* UTF-8 */
                          "(\033p0\x1bs)"));
    
 
    yaz_iconv_close(cd);
}


static void tst_latin1_to_marc8(void)
{
    yaz_iconv_t cd = yaz_iconv_open("MARC8", "ISO-8859-1");

    YAZ_CHECK(cd);
    if (!cd)
        return;

    YAZ_CHECK(tst_convert(cd, "Cours ", "Cours "));

    /** Pure ASCII. 11 characters (sizeof(outbuf)-1) */
    YAZ_CHECK(tst_convert(cd, "Cours de mat", "Cours de mat"));

    /** Pure ASCII. 12 characters (sizeof(outbuf)) */
    YAZ_CHECK(tst_convert(cd, "Cours de math", "Cours de math"));

    /** Pure ASCII. 13 characters (sizeof(outbuf)) */
    YAZ_CHECK(tst_convert(cd, "Cours de math.", "Cours de math."));

    /** D8: UPPERCASE SCANDINAVIAN O */
    YAZ_CHECK(tst_convert(cd, "S\xd8", "S\xa2"));

    /** E9: LATIN SMALL LETTER E WITH ACUTE */
    YAZ_CHECK(tst_convert(cd, "Cours de math\xe9", "Cours de mathâe"));
    YAZ_CHECK(tst_convert(cd, "Cours de math", "Cours de math"
                  ));
    YAZ_CHECK(tst_convert(cd, "Cours de mathé", "Cours de mathâe" ));
    YAZ_CHECK(tst_convert(cd, "12345678é","12345678âe"));
    YAZ_CHECK(tst_convert(cd, "123456789é", "123456789âe"));
    YAZ_CHECK(tst_convert(cd, "1234567890é","1234567890âe"));
    YAZ_CHECK(tst_convert(cd, "12345678901é", "12345678901âe"));
    YAZ_CHECK(tst_convert(cd, "Cours de mathém", "Cours de mathâem"));
    YAZ_CHECK(tst_convert(cd, "Cours de mathématiques",
                          "Cours de mathâematiques"));
    yaz_iconv_close(cd);
}

static void tst_utf8_codes(void)
{
    YAZ_CHECK(utf8_check(3));
    YAZ_CHECK(utf8_check(127));
    YAZ_CHECK(utf8_check(128));
    YAZ_CHECK(utf8_check(255));
    YAZ_CHECK(utf8_check(256));
    YAZ_CHECK(utf8_check(900));
    YAZ_CHECK(utf8_check(1000));
    YAZ_CHECK(utf8_check(10000));
    YAZ_CHECK(utf8_check(100000));
    YAZ_CHECK(utf8_check(1000000));
    YAZ_CHECK(utf8_check(10000000));
    YAZ_CHECK(utf8_check(100000000));
}

int main (int argc, char **argv)
{
    YAZ_CHECK_INIT(argc, argv);

    tst_utf8_codes();

    tst_marc8_to_utf8();

    tst_marc8s_to_utf8();

    tst_marc8_to_latin1();

    tst_utf8_to_marc8();

    tst_latin1_to_marc8();

    tst_marc8_to_ucs4b();
    tst_ucs4b_to_utf8();

    dconvert(1, "UTF-8");
    dconvert(1, "ISO-8859-1");
    dconvert(1, "UCS4");
    dconvert(1, "UCS4LE");
    dconvert(0, "CP865");

    YAZ_CHECK_TERM;
}
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */
