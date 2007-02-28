/*
 * Copyright (C) 1995-2007, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: comstack.c,v 1.18 2007/01/11 10:30:41 adam Exp $
 */

/** 
 * \file comstack.c
 * \brief Implements Generic COMSTACK functions
 */

#include <string.h>
#include <ctype.h>
#include <errno.h>

#include <yaz/log.h>
#include <yaz/comstack.h>
#include <yaz/tcpip.h>
#include <yaz/unix.h>
#include <yaz/odr.h>

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

static int skip_crlf(const char *buf, int len, int *i)
{
    if (*i < len)
    {
        if (buf[*i] == '\r' && *i < len-1 && buf[*i + 1] == '\n')
        {
            (*i) += 2;
            return 1;
        }
        else if (buf[*i] == '\n')
        {
            (*i)++;
            return 1;
        }
    }
    return 0;
}

#define CHUNK_DEBUG 0

int cs_complete_http(const char *buf, int len)
{
    /* deal with HTTP request/response */
    int i = 2, content_len = 0, chunked = 0;

    if (len < 6)
        return 0;

    /* if dealing with HTTP responses - then default
       content length is unlimited (socket close) */
    if (!memcmp(buf, "HTTP/", 5))
        content_len = -1; 

#if 0
    printf("len = %d\n", len);
    fwrite (buf, 1, len, stdout);
    printf("----------\n");
#endif
    while (i <= len-2)
    {
        if (i > 8192)
        {
            return i;  /* do not allow more than 8K HTTP header */
        }
        if (skip_crlf(buf, len, &i))
        {
            if (skip_crlf(buf, len, &i))
            {
                /* inside content */
                if (chunked)
                { 
                    /* inside chunked body .. */
                    while(1)
                    {
                        int chunk_len = 0;
#if CHUNK_DEBUG
                        if (i < len-2)
                        {
                            printf ("\n<<<");
                            int j;
                            for (j = i; j <= i+3; j++)
                                printf ("%c", buf[j]);
                            printf (">>>\n");
                        }
#endif
                        /* read chunk length */
                        while (1)
                            if (i >= len-2) {
#if CHUNK_DEBUG
                                printf ("returning incomplete read at 1\n");
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
                        if (chunk_len == 0)
                            break;
                        if (chunk_len < 0)
                            return i;
                        
                        while (1)
                        {
                            if (i >= len -1)
                                return 0;
                            if (skip_crlf(buf, len, &i))
                                break;
                            i++;
                        }
                        /* got CRLF */
#if CHUNK_DEBUG
                        printf ("chunk_len=%d\n", chunk_len);
#endif                      
                        i += chunk_len;
                        if (i >= len-2)
                            return 0;
                        if (!skip_crlf(buf, len, &i))
                            return 0;
                    }
                    /* consider trailing headers .. */
                    while (i < len)
                    {
                        if (skip_crlf(buf, len, &i))
                        {
                            if (skip_crlf(buf, len, &i))
                                return i;
                        }
                        else
                            i++;
                    }
#if CHUNK_DEBUG
                    printf ("returning incomplete read at 2\n");
                    printf ("i=%d len=%d\n", i, len);
#endif
                    return 0;
                }
                else
                {   /* not chunked ; inside body */
                    if (content_len == -1)
                        return 0;   /* no content length */
                    else if (len >= i + content_len)
                    {
                        return i + content_len;
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

int cs_complete_auto(const unsigned char *buf, int len)
{
    if (len > 5 && buf[0] >= 0x20 && buf[0] < 0x7f
                && buf[1] >= 0x20 && buf[1] < 0x7f
                && buf[2] >= 0x20 && buf[2] < 0x7f)
    {
        int r = cs_complete_http((const char *) buf, len);
        return r;
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

