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
/* $Id: log.h,v 1.42 2007/01/03 08:42:14 adam Exp $ */

/**
 * \file log.h
 * \brief Logging utility
 */

#ifndef YAZ_LOG_H
#define YAZ_LOG_H

#include <stdio.h>
#include <yaz/yconfig.h>

YAZ_BEGIN_CDECL

/** \brief log level: fatal */
#define YLOG_FATAL  0x00000001
/** \brief log level: debugging */
#define YLOG_DEBUG  0x00000002
/** \brief log level: warning */
#define YLOG_WARN   0x00000004
/** \brief log level: log (regular) */
#define YLOG_LOG    0x00000008
/** \brief log level: append system error message */
#define YLOG_ERRNO  0x00000010
/** \brief log level: application */
#define YLOG_APP    0x00000040 
/** \brief log level: malloc debug */
#define YLOG_MALLOC 0x00000080
/** \brief log level: do not output date and time */
#define YLOG_NOTIME 0x00000100
/** \brief log level: application 2 */
#define YLOG_APP2   0x00000200 
/** \brief log level: application 3 */
#define YLOG_APP3   0x00000400
/** \brief log level: flush */
#define YLOG_FLUSH  0x00000800
/** \brief dynamic log level start */
#define YLOG_LOGLVL 0x00001000 /* log when modules query log levels */
                              /* this has to be a hard-coded bit, not to loop*/

#define YLOG_ALL   (0xffff&~YLOG_MALLOC&~YLOG_NOTIME)

/** \brief default log level */
#define YLOG_DEFAULT_LEVEL \
    (YLOG_FATAL | YLOG_ERRNO | YLOG_LOG | YLOG_WARN | YLOG_FLUSH)
/* not having flush here confuses Solaris users, who won't see any logs until
 * (and if) the program exits normally */

/** \brief last bit for regular log bits . Rest are dynamic */
#define YLOG_LAST_BIT YLOG_LOGLVL

/** \brief sets level, prefix and filename for logging
    \param level log level
    \param prefix log message prefix
    \param fname filename 
*/
YAZ_EXPORT void yaz_log_init(int level, const char *prefix, const char *fname);

/** \brief sets log to a file 
    \param fname filename 
*/
YAZ_EXPORT void yaz_log_init_file(const char *fname);

/** \brief sets log level
    \param level (combination of YLOG_..)
*/
YAZ_EXPORT void yaz_log_init_level(int level);

/** \brief sets log message prefix 
    \param prefix log message prefix
*/
YAZ_EXPORT void yaz_log_init_prefix(const char *prefix);

/** \brief sets second log message prefix
    \param prefix log message prefix
*/
YAZ_EXPORT void yaz_log_init_prefix2(const char *prefix);

/** \brief sets time format for log mesages
    \param fmt format (strftime)

    Sets the format of the timestamp. See man 3 strftime.
    Calling with "old" sets to the old format "11:55:06-02/11"
    Calling with NULL or "" sets to the new format "20041102-115719"
    If not called at all, the old format is used, for backward compatibility
*/
YAZ_EXPORT void yaz_log_time_format(const char *fmt);

/** \brief sets limit in bytes for size for log file 
    \param mx size in bytes

    Sets the max size for a log file. Zero means no limit.
    Negative means built-in limit (1GB)
*/
YAZ_EXPORT void yaz_log_init_max_size(int mx);

/** \brief Writes log message
    \param level log level mask
    \param fmt format string ala printf
    
    Writes an entry in the log. Defaults to stderr if not initialized or
    to a file with yaz_log_init_file(). The level must match the level set
    via yaz_log_init_level(), optionally defined via yaz_log_mask_str().
*/
YAZ_EXPORT void yaz_log(int level, const char *fmt, ...)
#ifdef __GNUC__
        __attribute__ ((format (printf, 2, 3)))
#endif
        ;

/** \brief converts log level string to log level (integer)
    \param str log level string
    \return log level mask
    
    yaz_log_mask_str() converts a comma-separated list of log levels to a
    bit mask. Starts from default level, and adds bits as specified,
    unless 'none' is specified, which clears the list. If a name matches
    the name of a YLOG_BIT above, that one is set. Otherwise a new value is
    picked, and given to that name, to be found with yaz_log_module_level() 
*/
YAZ_EXPORT int yaz_log_mask_str(const char *str);

/** \brief converts log level string to log level with "start" level
    \param str log level string
    \param level initialing log level
    \return log level mask

    yaz_log_mask_str_x() is like yaz_log_mask_str(), but with a given start
    value
*/
YAZ_EXPORT int yaz_log_mask_str_x(const char *str, int level);


/** \brief returns level for module
    \param name module name

    yaz_log_module_level() returns a log level mask corresponding to the
    module name. If that had been specified on the -v arguments (that is
    passed to yaz_log_mask_str()), then a non-zero mask is returned. If
    not, we get a zero. This can later be used in yaz_log for the level
    argument
 */
YAZ_EXPORT int yaz_log_module_level(const char *name);

/** \brief returns FILE handle for log or NULL if no file is in use
    \retval FILE FILE handle in use
    \retval NULL log is currently not written to a file
*/
YAZ_EXPORT FILE *yaz_log_file(void);

/** \brief sets custom log handler
    \param func custom log handler
    \param info custom pointer to be passed to func handler
    
    Allows log output to be captured to something else.. The
    func parameter takes a log level, a message + custom pointer
*/
YAZ_EXPORT void yaz_log_set_handler(void (*func)(int, const char *,
                                                 void *), void *info);

YAZ_EXPORT void yaz_log_reopen(void);

/** \brief Truncate the log file */
YAZ_EXPORT void yaz_log_trunc(void);

YAZ_EXPORT void log_event_start(void (*func)(int level, const char *msg,
                                             void *info), void *info);

YAZ_EXPORT void log_event_end(void (*func)(int level, const char *msg,
                                           void *info), void *info);

/* if syslog.h is already included, do not define the old LOG_'s */
#ifdef LOG_DEBUG
#undef YAZ_USE_NEW_LOG
#define YAZ_USE_NEW_LOG 1
#endif

#if YAZ_USE_NEW_LOG

#else

#include <yaz/xmalloc.h>

/** The old LOG_ bit names are here for compatibility only. They may 
    conflict with bits defined in syslog.h, or other places. 'LOG'
    really is not such a good name. YLOG must be more unique
*/

/** \brief old log level */
#define LOG_FATAL  YLOG_FATAL
/** \brief old log level */
#define LOG_DEBUG  YLOG_DEBUG
/** \brief old log level */
#define LOG_WARN   YLOG_WARN
/** \brief old log level */
#define LOG_LOG    YLOG_LOG
/** \brief old log level */
#define LOG_ERRNO  YLOG_ERRNO 
/** \brief old log level */
#define LOG_FILE   0x00000020
/** \brief old log level */
#define LOG_APP    YLOG_APP
/** \brief old log level */
#define LOG_MALLOC YLOG_MALLOC
/** \brief old log level */
#define LOG_NOTIME YLOG_NOTIME
/** \brief old log level */
#define LOG_APP2   YLOG_APP2
/** \brief old log level */
#define LOG_APP3   YLOG_APP3
/** \brief old log level */
#define LOG_FLUSH  YLOG_FLUSH 
/** \brief old log level */
#define LOG_ALL    YLOG_ALL
/** \brief old log level */
#define LOG_DEFAULT_LEVEL YLOG_DEFAULT_LEVEL

/** \brief logf is deprecated, as it conflicts with a math function */
#define logf yaz_log

#endif /* if !YAZ_USE_NEW_LOG  */

YAZ_END_CDECL

#endif
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

