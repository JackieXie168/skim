/*
 * Copyright (c) 1995-2007, Index Data
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of Index Data nor the names of its contributors
 *       may be used to endorse or promote products derived from this
 *       software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE REGENTS AND CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
/* $Id: record_conv.h,v 1.8 2007/01/03 08:42:14 adam Exp $ */

/**
 * \file record_conv.h
 * \brief Record Conversions Utility
 */

#ifndef YAZ_RECORD_CONV_H
#define YAZ_RECORD_CONV_H

#include <stddef.h>
#include <yaz/wrbuf.h>
#include <yaz/yconfig.h>
#include <yaz/xmltypes.h>

YAZ_BEGIN_CDECL

/** record conversion handle  */
typedef struct yaz_record_conv_struct *yaz_record_conv_t;

/** creates record handle
    \return record handle
*/
YAZ_EXPORT yaz_record_conv_t yaz_record_conv_create(void);

/** destroys record handle
    \param p record conversion handle
*/
YAZ_EXPORT void yaz_record_conv_destroy(yaz_record_conv_t p);

/** configures record conversion
    \param p record conversion handle
    \param node xmlNode pointer (root element of XML config)
    \retval 0 success
    \retval -1 failure

    On failure, use yaz_record_conv_get_error to get error string.
    
    \verbatim
    <backend syntax='xml'>
      <xslt stylesheet="dc2marcxml.xsl"/>
      <marc inputformat="xml" outputformat="marcxml" outputcharset="marc-8"/>
    </backend>
    \endverbatim

    \verbatim
    <backend syntax='usmarc' name='F'>
      <marc inputformat="marc" outputformat="marcxml" inputcharset="marc-8"/>
      <xslt stylesheet="marcxml2mods.xsl"/>
      <xslt stylesheet="mods2dc.xsl"/>
    </backend>
    \endverbatim
*/
YAZ_EXPORT
int yaz_record_conv_configure(yaz_record_conv_t p, const xmlNode *node);

/** performs record conversion
    \param p record conversion handle
    \param input_record_buf input record buffer
    \param input_record_len length of input record buffer
    \param output_record resultint record (WRBUF string)
    \retval 0 success
    \retval -1 failure

    On failure, use yaz_record_conv_get_error to get error string.
*/
YAZ_EXPORT
int yaz_record_conv_record(yaz_record_conv_t p, const char *input_record_buf,
                           size_t input_record_len,
                           WRBUF output_record);

/** returns error string (for last error)
    \param p record conversion handle
    \return error string
*/    
YAZ_EXPORT
const char *yaz_record_conv_get_error(yaz_record_conv_t p);


/** set path for opening stylesheets etc.
    \param p record conversion handle
    \param path file path (UNIX style with : / Windows with ;)
*/    
YAZ_EXPORT
void yaz_record_conv_set_path(yaz_record_conv_t p, const char *path);

YAZ_END_CDECL

#endif
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

