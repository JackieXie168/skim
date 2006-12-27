/*
 * Copyright (C) 1995-2006, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: comstack.c,v 1.16 2006/08/24 13:25:45 adam Exp $
 */

/** 
 * \file comstack.c
 * \brief Implements Generic COMSTACK functions
 */

#include <string.h>
#include <ctype.h>
#include <errno.h>

#include "log.h"
#include "comstack.h"
#include "tcpip.h"
#include "unix.h"
#include "odr.h"

#ifdef WIN32
#define strncasecmp _strnicmp
#endif

static const char *cs_errlist[] =
{
    "No error or unspecified error",
    "System (lower-layer) error",
    "Operation out of state",
    "No data (operation would block)",
    "New data while half of old buffer is on the line (flow control)",
    "Permission denied",
    "SSL error",
    "Too large incoming buffer"
};

const char *cs_errmsg(int n)
{
    static char buf[250];

    if (n < CSNONE || n > CSLASTERROR) {
        sprintf(buf, "unknown comstack error %d", n);
        return buf;
    }
    if (n == CSYSERR) {
        sprintf(buf, "%s: %s", cs_errlist[n], strerror(errno));
        return buf;
    }
    return cs_errlist[n];
}

const char *cs_strerror(COMSTACK h)
{
    return cs_errmsg(h->cerrno);
}

void cs_get_host_args(const char *type_and_host, const char **args)
{
    
    *args = "";
    if (*type_and_host && strncmp(type_and_host, "unix:", 5))
    {
        const char *cp;
        cp = strstr(type_and_host, "://");
        if (cp)
            cp = cp+3;
        else
            cp = type_and_host;
        cp = strchr(cp, '/');
        if (cp)
            *args = cp+1;
    }
}

COMSTACK cs_create_host(const char *type_and_host, int blocking, void **vp)
{
    enum oid_proto proto = PROTO_Z3950;
    const char *host = 0;
    COMSTACK cs;
    CS_TYPE t;

    if (strncmp (type_and_host, "tcp:", 4) == 0)
    {
        t = tcpip_type;
        host = type_and_host + 4;
    }
    else if (strncmp (type_and_host, "ssl:", 4) == 0)
    {
#if HAVE_OPENSSL_SSL_H
        t = ssl_type;
        host = type_and_host + 4;
#else
        return 0;
#endif
    }
    else if (strncmp (type_and_host, "unix:", 5) == 0)
    {
#ifndef WIN32
        t = unix_type;
        host = type_and_host + 5;
#else
        return 0;
#endif
    }
    else if (strncmp(type_and_host, "http:", 5) == 0)
    {
        t = tcpip_type;
        host = type_and_host + 5;
        while (host[0] == '/')
            host++;
        proto = PROTO_HTTP;
    }
    else if (strncmp(type_and_host, "https:", 6) == 0)
    {
#if HAVE_OPENSSL_SSL_H
        t = ssl_type;
        host = type_and_host + 6;
        while (host[0] == '/')
            host++;
        proto = PROTO_HTTP;
#else
        return 0;
#endif
    }
    else
    {
        t = tcpip_type;
        host = type_and_host;
    }
    cs = cs_create (t, blocking, proto);
    if (!cs)
        return 0;

    if (!(*vp = cs_straddr(cs, host)))
    {
        cs_close (cs);
        return 0;
    }    
    return cs;
}

int cs_look (COMSTACK cs)
{
    return cs->event;
}

#define CHUNK_DEBUG 0
int cs_complete_auto(const unsigned char *buf, int len)
{
    if (len > 5 && buf[0] >= 0x20 && buf[0] < 0x7f
                && buf[1] >= 0x20 && buf[1] < 0x7f
                && buf[2] >= 0x20 && buf[2] < 0x7f)
    {
        /* deal with HTTP request/response */
        int i = 2, content_len = 0, chunked = 0;

        /* if dealing with HTTP responses - then default
           content length is unlimited (socket close) */
        if (!memcmp(buf, "HTTP/", 5))
            content_len = -1; 

        while (i <= len-4)
        {
            if (i > 8192)
            {
                return i;  /* do not allow more than 8K HTTP header */
            }
            if (buf[i] == '\r' && buf[i+1] == '\n')
            {
                i += 2;
                if (buf[i] == '\r' && buf[i+1] == '\n')
                {
                    if (chunked)
                    { 
                        /* inside chunked body .. */
                        while(1)
                        {
                            int j, chunk_len = 0;
                            i += 2;
#if CHUNK_DEBUG
/* debugging */
                            if (i <len-2)
                            {
                                printf ("\n<<<");
                                int j;
                                for (j = i; j <= i+4; j++)
                                    printf ("%c", buf[j]);
                                printf (">>>\n");
                            }
#endif
                            /* read chunk length */
                            while (1)
                                if (i >= len-2) {
#if CHUNK_DEBUG
/* debugging */                                    
                                    printf ("XXXXXXXX not there yet 1\n");
                                    printf ("i=%d len=%d\n", i, len);
#endif
                                    return 0;
                                } else if (isdigit(buf[i]))
                                    chunk_len = chunk_len * 16 + 
                                        (buf[i++] - '0');
                                else if (isupper(buf[i]))
                                    chunk_len = chunk_len * 16 + 
                                        (buf[i++] - ('A'-10));
                                else if (islower(buf[i]))
                                    chunk_len = chunk_len * 16 + 
                                        (buf[i++] - ('a'-10));
                                else
                                    break;
                            /* move forward until CRLF - skip chunk ext */
                            j = 0;
                            while (buf[i] != '\r' && buf[i+1] != '\n')
                            {
                                if (i >= len-2)
                                    return 0;   /* need more buffer .. */
                                if (++j > 1000)
                                    return i; /* enough.. stop */
                                i++;
                            }
                            /* got CRLF */
#if CHUNK_DEBUG
                            printf ("XXXXXX chunk_len=%d\n", chunk_len);
#endif                      
                            if (chunk_len < 0)
                                return i+2;    /* bad chunk_len */
                            if (chunk_len == 0)
                                break;
                            i += chunk_len+2;
                        }
                        /* consider trailing headers .. */
                        while(i <= len-4)
                        {
                            if (buf[i] == '\r' &&  buf[i+1] == '\n' &&
                                buf[i+2] == '\r' && buf[i+3] == '\n')
                                if (len >= i+4)
                                    return i+4;
                            i++;
                        }
#if CHUNK_DEBUG
/* debugging */
                        printf ("XXXXXXXXX not there yet 2\n");
                        printf ("i=%d len=%d\n", i, len);
#endif
                        return 0;
                    }
                    else
                    {   /* not chunked ; inside body */
                        /* i += 2 seems not to work with GCC -O2 .. 
                           so i+2 is used instead .. */
                        if (content_len == -1)
                            return 0;   /* no content length */
                        else if (len >= (i+2)+ content_len)
                        {
                            return (i+2)+ content_len;
                        }
                    }
                    break;
                }
                else if (i < len - 20 && 
                         !strncasecmp((const char *) buf+i, "Transfer-Encoding:", 18))
                {
                    i+=18;
                    while (buf[i] == ' ')
                        i++;
                    if (i < len - 8)
                        if (!strncasecmp((const char *) buf+i, "chunked", 7))
                            chunked = 1;
                }
                else if (i < len - 17 &&
                         !strncasecmp((const char *)buf+i, "Content-Length:", 15))
                {
                    i+= 15;
                    while (buf[i] == ' ')
                        i++;
                    content_len = 0;
                    while (i <= len-4 && isdigit(buf[i]))
                        content_len = content_len*10 + (buf[i++] - '0');
                    if (content_len < 0) /* prevent negative offsets */
                        content_len = 0;
                }
                else
                    i++;
            }
            else
                i++;
        }
        return 0;
    }
    return completeBER(buf, len);
}

void cs_set_max_recv_bytes(COMSTACK cs, int max_recv_bytes)
{
    cs->max_recv_bytes = max_recv_bytes;
}

/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

