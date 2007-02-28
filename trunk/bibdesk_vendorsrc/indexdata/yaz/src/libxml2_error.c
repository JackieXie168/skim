/*
 * Copyright (C) 2007, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: libxml2_error.c,v 1.3 2007/01/03 08:42:15 adam Exp $
 */
/**
 * \file libxml2_error.c
 * \brief Libxml2 error handling
 */

#include <stdlib.h>
#include <stdarg.h>
#include <yaz/log.h>
#include <yaz/libxml2_error.h>

#if YAZ_HAVE_XML2
#include <libxml/xmlerror.h>
#endif

#if YAZ_HAVE_XSLT
#include <libxslt/xsltutils.h>
#endif

static int libxml2_error_level = 0;

static void proxy_xml_error_handler(void *ctx, const char *fmt, ...)
{
    char buf[1024];

    va_list ap;
    va_start(ap, fmt);

#ifdef WIN32
    vsprintf(buf, fmt, ap);
#else
    vsnprintf(buf, sizeof(buf), fmt, ap);
#endif
    yaz_log(libxml2_error_level, "%s: %s", (char*) ctx, buf);

    va_end (ap);
}

int libxml2_error_to_yazlog(int level, const char *lead_msg)
{
    libxml2_error_level = level;
#if YAZ_HAVE_XSLT
    xsltSetGenericErrorFunc((void *) "XSLT", proxy_xml_error_handler);
#endif
#if YAZ_HAVE_XML2
    xmlSetGenericErrorFunc((void *) "XML", proxy_xml_error_handler);
    return 0;
#else
    return -1;
#endif
}

/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

