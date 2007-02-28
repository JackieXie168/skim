/*
 * Copyright (C) 1995-2007, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: odr_oct.c,v 1.10 2007/01/03 08:42:15 adam Exp $
 */
/**
 * \file odr_oct.c
 * \brief Implements ODR OCTET codec
 */
#if HAVE_CONFIG_H
#include <config.h>
#endif

#include "odr-priv.h"

/*
 * Top level octet string en/decoder.
 * Returns 1 on success, 0 on error.
 */
int odr_octetstring(ODR o, Odr_oct **p, int opt, const char *name)
{
    int res, cons = 0;

    if (o->error)
        return 0;
    if (o->t_class < 0)
    {
        o->t_class = ODR_UNIVERSAL;
        o->t_tag = ODR_OCTETSTRING;
    }
    if ((res = ber_tag(o, p, o->t_class, o->t_tag, &cons, opt, name)) < 0)
        return 0;
    if (!res)
        return odr_missing(o, opt, name);
    if (o->direction == ODR_PRINT)
    {
        odr_prname(o, name);
        odr_printf(o, "OCTETSTRING(len=%d) ", (*p)->len);

        o->op->stream_write(o, o->print, ODR_OCTETSTRING,
                            (char*) (*p)->buf, (*p)->len);
        odr_printf(o, "\n");
        return 1;
    }
    if (o->direction == ODR_DECODE)
    {
        *p = (Odr_oct *)odr_malloc(o, sizeof(Odr_oct));
        (*p)->size= 0;
        (*p)->len = 0;
        (*p)->buf = 0;
    }
    if (ber_octetstring(o, *p, cons))
        return 1;
    odr_seterror(o, OOTHER, 43);
    return 0;
}

/*
 * Friendlier interface to octetstring.
 */
int odr_cstring(ODR o, char **p, int opt, const char *name)
{
    int cons = 0, res;
    Odr_oct *t;

    if (o->error)
        return 0;
    if (o->t_class < 0)
    {
        o->t_class = ODR_UNIVERSAL;
        o->t_tag = ODR_OCTETSTRING;
    }
    if ((res = ber_tag(o, p, o->t_class, o->t_tag, &cons, opt, name)) < 0)
        return 0;
    if (!res)
        return odr_missing(o, opt, name);
    if (o->direction == ODR_PRINT)
    {
        odr_prname(o, name);
        odr_printf(o, "'%s'\n", *p);
        return 1;
    }
    t = (Odr_oct *)odr_malloc(o, sizeof(Odr_oct)); /* wrapper for octstring */
    if (o->direction == ODR_ENCODE)
    {
        t->buf = (unsigned char *) *p;
        t->size = t->len = strlen(*p);
    }
    else
    {
        t->size= 0;
        t->len = 0;
        t->buf = 0;
    }
    if (!ber_octetstring(o, t, cons))
        return 0;
    if (o->direction == ODR_DECODE)
    {
        *p = (char *) t->buf;
        *(*p + t->len) = '\0';  /* ber_octs reserves space for this */
    }
    return 1;
}

/*
 * iconv interface to octetstring.
 */
int odr_iconv_string(ODR o, char **p, int opt, const char *name)
{
    int cons = 0, res;
    Odr_oct *t;

    if (o->error)
        return 0;
    if (o->t_class < 0)
    {
        o->t_class = ODR_UNIVERSAL;
        o->t_tag = ODR_OCTETSTRING;
    }
    if ((res = ber_tag(o, p, o->t_class, o->t_tag, &cons, opt, name)) < 0)
        return 0;
    if (!res)
        return odr_missing(o, opt, name);
    if (o->direction == ODR_PRINT)
    {
        odr_prname(o, name);
        odr_printf(o, "'%s'\n", *p);
        return 1;
    }
    t = (Odr_oct *)odr_malloc(o, sizeof(Odr_oct)); /* wrapper for octstring */
    if (o->direction == ODR_ENCODE)
    {
        t->buf = 0;

        if (o->op->iconv_handle != 0)
        {
            size_t inleft = strlen(*p);
            char *inbuf = *p;
            size_t outleft = 4 * inleft + 2;
            char *outbuf = (char *) odr_malloc (o, outleft);
            size_t ret;
            
            t->buf = (unsigned char *) outbuf;
            
            ret = yaz_iconv (o->op->iconv_handle, &inbuf, &inleft,
                             &outbuf, &outleft);
            if (ret == (size_t)(-1))
            {
                odr_seterror(o, ODATA, 44);
                return 0;
            }
            t->size = t->len = outbuf - (char*) t->buf;
        }
        if (!t->buf)
        {
            t->buf = (unsigned char *) *p;
            t->size = t->len = strlen(*p);
        }
    }
    else
    {
        t->size= 0;
        t->len = 0;
        t->buf = 0;
    }
    if (!ber_octetstring(o, t, cons))
        return 0;
    if (o->direction == ODR_DECODE)
    {
        *p = 0;

        if (o->op->iconv_handle != 0)
        {
            size_t inleft = t->len;
            char *inbuf = (char *) t->buf;
            size_t outleft = 4 * inleft + 2;
            char *outbuf = (char *) odr_malloc (o, outleft);
            size_t ret;

            *p = outbuf;
            
            ret = yaz_iconv (o->op->iconv_handle, &inbuf, &inleft,
                             &outbuf, &outleft);
            if (ret == (size_t)(-1))
            {
                odr_seterror(o, ODATA, 45);
                return 0;
            }
            inleft = outbuf - (char*) *p;
            
            (*p)[inleft] = '\0';    /* null terminate it */
        }
        if (!*p)
        {
            *p = (char *) t->buf;
            *(*p + t->len) = '\0';  /* ber_octs reserves space for this */
        }
    }
    return 1;
}
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

