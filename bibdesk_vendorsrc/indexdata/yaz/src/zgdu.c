/*
 * Copyright (C) 1995-2007, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: zgdu.c,v 1.19 2007/01/11 10:55:57 adam Exp $
 */

/**
 * \file zgdu.c
 * \brief Implements HTTP and Z39.50 encoding and decoding.
 */

#include <string.h>
#include <yaz/odr.h>
#include <yaz/zgdu.h>

int z_GDU (ODR o, Z_GDU **p, int opt, const char *name)
{
    if (o->direction == ODR_DECODE) {
        *p = (Z_GDU *) odr_malloc(o, sizeof(**p));
        if (o->size > 10 && !memcmp(o->buf, "HTTP/", 5))
        {
            (*p)->which = Z_GDU_HTTP_Response;
            return yaz_decode_http_response(o, &(*p)->u.HTTP_Response);

        }
        else if (o->size > 5 &&
            o->buf[0] >= 0x20 && o->buf[0] < 0x7f
            && o->buf[1] >= 0x20 && o->buf[1] < 0x7f
            && o->buf[2] >= 0x20 && o->buf[2] < 0x7f
            && o->buf[3] >= 0x20 && o->buf[3] < 0x7f)
        {
            (*p)->which = Z_GDU_HTTP_Request;
            return yaz_decode_http_request(o, &(*p)->u.HTTP_Request);
        }
        else
        {
            (*p)->which = Z_GDU_Z3950;
            return z_APDU(o, &(*p)->u.z3950, opt, 0);
        }
    }
    else /* ENCODE or PRINT */
    {
        switch((*p)->which)
        {
        case Z_GDU_HTTP_Response:
            return yaz_encode_http_response(o, (*p)->u.HTTP_Response);
        case Z_GDU_HTTP_Request:
            return yaz_encode_http_request(o, (*p)->u.HTTP_Request);
        case Z_GDU_Z3950:
            return z_APDU(o, &(*p)->u.z3950, opt, 0);
        }
    }
    return 0;
}

/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

