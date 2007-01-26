/*
 * Copyright (C) 1995-2007, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: tst_comstack.c,v 1.1 2007/01/11 10:30:41 adam Exp $
 */

#include <stdlib.h>
#include <stdio.h>

#include <yaz/test.h>
#include <yaz/comstack.h>

static void tst_http_request(void)
{
    {
        /* no content, no headers */
        const char *http_buf = 
            /*123456789012345678 */
            "GET / HTTP/1.1\r\n"
            "\r\n"
            "GET / HTTP/1.0\r\n";
        
        YAZ_CHECK_EQ(cs_complete_http(http_buf, 1), 0);
        YAZ_CHECK_EQ(cs_complete_http(http_buf, 2), 0);
        YAZ_CHECK_EQ(cs_complete_http(http_buf, 16), 0);
        YAZ_CHECK_EQ(cs_complete_http(http_buf, 17), 0);
        YAZ_CHECK_EQ(cs_complete_http(http_buf, 18), 18);
        YAZ_CHECK_EQ(cs_complete_http(http_buf, 19), 18);
    }
    {
        /* one header, no content */
        const char *http_buf = 
            /*123456789012345678 */
            "GET / HTTP/1.1\r\n"
            "Content-Type: x\r\n"
            "\r\n"
            "GET / HTTP/1.0\r\n";
        
        YAZ_CHECK_EQ(cs_complete_http(http_buf, 1), 0);
        YAZ_CHECK_EQ(cs_complete_http(http_buf, 2), 0);
        YAZ_CHECK_EQ(cs_complete_http(http_buf, 34), 0);
        YAZ_CHECK_EQ(cs_complete_http(http_buf, 35), 35);
        YAZ_CHECK_EQ(cs_complete_http(http_buf, 36), 35);
    }        
    {
        /* one content-length header, length 0 */
        const char *http_buf = 
            /*123456789012345678 */
            "GET / HTTP/1.1\r\n"
            "Content-Length: 0\r\n"
            "\r\n"
            "GET / HTTP/1.0\r\n";
        
        YAZ_CHECK_EQ(cs_complete_http(http_buf, 1), 0);
        YAZ_CHECK_EQ(cs_complete_http(http_buf, 2), 0);
        YAZ_CHECK_EQ(cs_complete_http(http_buf, 35), 0);
        YAZ_CHECK_EQ(cs_complete_http(http_buf, 37), 37);
        YAZ_CHECK_EQ(cs_complete_http(http_buf, 38), 37);
    }        
    {
        /* one content-length header, length 5 */
        const char *http_buf = 
            /*123456789012345678 */
            "GET / HTTP/1.1\r\n"
            "Content-Length: 5\r\n"
            "\r\n"
            "ABCDE"
            "GET / HTTP/1.0\r\n";
        
        YAZ_CHECK_EQ(cs_complete_http(http_buf, 1), 0);
        YAZ_CHECK_EQ(cs_complete_http(http_buf, 2), 0);
        YAZ_CHECK_EQ(cs_complete_http(http_buf, 41), 0);
        YAZ_CHECK_EQ(cs_complete_http(http_buf, 42), 42);
        YAZ_CHECK_EQ(cs_complete_http(http_buf, 43), 42);
    }        
    {
        /* LF only in GET, one content-length header, length 5 */
        const char *http_buf = 
            /*123456789012345678 */
            "GET / HTTP/1.1\n"
            "Content-Length: 5\r\n"
            "\r\n"
            "ABCDE"
            "GET / HTTP/1.0\r\n";
        
        YAZ_CHECK_EQ(cs_complete_http(http_buf, 1), 0);
        YAZ_CHECK_EQ(cs_complete_http(http_buf, 2), 0);
        YAZ_CHECK_EQ(cs_complete_http(http_buf, 40), 0);
        YAZ_CHECK_EQ(cs_complete_http(http_buf, 41), 41);
        YAZ_CHECK_EQ(cs_complete_http(http_buf, 42), 41);
    }        
    {
        /* LF only in all places, one content-length header, length 5 */
        const char *http_buf = 
            /*123456789012345678 */
            "GET / HTTP/1.1\n"
            "Content-Length: 5\n"
            "\n"
            "ABCDE"
            "GET / HTTP/1.0\r\n";
        
        YAZ_CHECK_EQ(cs_complete_http(http_buf, 1), 0);
        YAZ_CHECK_EQ(cs_complete_http(http_buf, 2), 0);
        YAZ_CHECK_EQ(cs_complete_http(http_buf, 38), 0);
        YAZ_CHECK_EQ(cs_complete_http(http_buf, 39), 39);
        YAZ_CHECK_EQ(cs_complete_http(http_buf, 40), 39);
    }        

    {
        /* one header, unknown transfer-encoding (no content) */
        const char *http_buf = 
            /*12345678901234567890123456789 */
            "GET / HTTP/1.1\r\n"
            "Transfer-Encoding: chunke_\r\n"
            "\r\n"
            "GET / HTTP/1.0\r\n";
        
        YAZ_CHECK_EQ(cs_complete_http(http_buf, 45), 0);
        YAZ_CHECK_EQ(cs_complete_http(http_buf, 46), 46);
    }        

    {
        /* one header, one chunk */
        const char *http_buf = 
            /*12345678901234567890123456789 */
            "GET / HTTP/1.1\r\n"
            "Transfer-Encoding: chunked\r\n"
            "\r\n"
            "3\r\n"
            "123\r\n"
            "0\r\n\r\n"
            "GET / HTTP/1.0\r\n";
        
        YAZ_CHECK_EQ(cs_complete_http(http_buf, 58), 0);
        YAZ_CHECK_EQ(cs_complete_http(http_buf, 59), 59);
    }        

    {
        /* one header, two chunks */
        const char *http_buf = 
            /*12345678901234567890123456789 */
            "GET / HTTP/1.1\r\n"
            "Transfer-Encoding: chunked\r\n"
            "\r\n"
            "3\r\n"
            "123\r\n"
            "2\r\n"
            "12\n"
            "0\r\n\r\n"
            "GET / HTTP/1.0\r\n";
        
        YAZ_CHECK_EQ(cs_complete_http(http_buf, 64), 0);
        YAZ_CHECK_EQ(cs_complete_http(http_buf, 65), 65);
    }        
}

static void tst_http_response(void)
{
    {
        /* unlimited content, no headers */
        const char *http_buf = 
            /*123456789012345678 */
            "HTTP/1.1 200 OK\r\n"
            "\r\n"
            "HTTP/1.1 200 OK\r\n";
        
        YAZ_CHECK_EQ(cs_complete_http(http_buf, 1), 0);
        YAZ_CHECK_EQ(cs_complete_http(http_buf, 2), 0);
        YAZ_CHECK_EQ(cs_complete_http(http_buf, 24), 0);
    }
    {
        /* response, content  */
        const char *http_buf = 
            /*123456789012345678 */
            "HTTP/1.1 200 OK\r\n"
            "Content-Length: 2\r\n"
            "\r\n"
            "12"
            "HTTP/1.1 200 OK\r\n";
        
        YAZ_CHECK_EQ(cs_complete_http(http_buf, 1), 0);
        YAZ_CHECK_EQ(cs_complete_http(http_buf, 2), 0);
        YAZ_CHECK_EQ(cs_complete_http(http_buf, 39), 0);
        YAZ_CHECK_EQ(cs_complete_http(http_buf, 40), 40);
        YAZ_CHECK_EQ(cs_complete_http(http_buf, 41), 40);
    }
}


int main (int argc, char **argv)
{
    YAZ_CHECK_INIT(argc, argv);
    YAZ_CHECK_LOG();
    tst_http_request();
    tst_http_response();
    YAZ_CHECK_TERM;
}

/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

