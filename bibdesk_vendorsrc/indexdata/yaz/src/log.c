/*
 * Copyright (C) 1995-2007, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: log.c,v 1.45 2007/01/03 08:42:15 adam Exp $
 */

/**
 * \file log.c
 * \brief Logging utility
 */

#if HAVE_CONFIG_H
#include <config.h>
#endif

#ifdef WIN32
#include <windows.h>
#endif

#if YAZ_POSIX_THREADS
#include <pthread.h>
#endif

#if YAZ_GNU_THREADS
#include <pth.h>
#endif

#include <sys/stat.h>
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>
#include <stdarg.h>
#include <errno.h>
#include <time.h>
#include <yaz/nmem.h>
#include <yaz/log.h>
#include <yaz/xmalloc.h>

static NMEM_MUTEX log_mutex = 0;

#define HAS_STRERROR 1


#if HAS_STRERROR

#else
char *strerror(int n)
{
    extern char *sys_errlist[];
    return sys_errlist[n];
}

#endif


static int l_level = YLOG_DEFAULT_LEVEL;

enum l_file_type { use_stderr, use_none, use_file };
static enum l_file_type yaz_file_type = use_stderr;
static FILE *yaz_global_log_file = NULL;

static void (*start_hook_func)(int, const char *, void *) = NULL;
static void *start_hook_info;

static void (*end_hook_func)(int, const char *, void *) = NULL;
static void *end_hook_info;

static void (*hook_func)(int, const char *, void *) = NULL;
static void *hook_info;

static char l_prefix[512] = "";
static char l_prefix2[512] = "";
static char l_fname[512] = "";


static char l_old_default_format[] = "%H:%M:%S-%d/%m";
static char l_new_default_format[] = "%Y%m%d-%H%M%S";
#define TIMEFORMAT_LEN 50
static char l_custom_format[TIMEFORMAT_LEN] = "";
static char *l_actual_format = l_old_default_format;

/** l_max_size tells when to rotate the log. Default is 1 GB 
    This is almost the same as never, but it saves applications in the
    case of 2 or 4 GB file size limits..
 */
static int l_max_size = 1024*1024*1024;

#define MAX_MASK_NAMES 35   /* 32 bits plus a few combo names */
static struct {
    int mask;
    char *name;
} mask_names[MAX_MASK_NAMES] =
{
    { YLOG_FATAL,  "fatal"},
    { YLOG_DEBUG,  "debug"},
    { YLOG_WARN,   "warn" },
    { YLOG_LOG,    "log"  },
    { YLOG_ERRNO,  ""},
    { YLOG_MALLOC, "malloc"},
    { YLOG_APP,    "app"  },
    { YLOG_NOTIME, "notime" },
    { YLOG_APP2,   "app2" }, 
    { YLOG_APP3,   "app3" },
    { YLOG_ALL,    "all"  },
    { YLOG_FLUSH,  "flush" },
    { YLOG_LOGLVL, "loglevel" }, 
    { 0,           "none" },
    { 0, NULL }
    /* the rest will be filled in if the user defines dynamic modules*/
};  

static unsigned int next_log_bit = YLOG_LAST_BIT<<1; /* first dynamic bit */

static void internal_log_init(void)
{
    static int mutex_init_flag = 0; /* not yet initialized */
    char *env;

    if (mutex_init_flag)
        return;
    mutex_init_flag = 1; /* here, 'cause nmem_mutex_create may call yaz_log */

    nmem_mutex_create(&log_mutex);

    env = getenv("YAZ_LOG");
    if (env)
        l_level = yaz_log_mask_str_x(env, l_level);
}


FILE *yaz_log_file(void)
{
    FILE *f = 0;
    switch(yaz_file_type)
    {
        case use_stderr: f = stderr; break;
        case use_none: f = 0; break;
        case use_file: f = yaz_global_log_file; break;
    }
    return f;
}

void yaz_log_close(void)
{
    if (yaz_file_type == use_file && yaz_global_log_file)
    {
        fclose(yaz_global_log_file);
        yaz_global_log_file = 0;
    }
}

void yaz_log_init_file(const char *fname)
{
    internal_log_init();

    yaz_log_close();
    if (fname)
    {
        if (*fname == '\0')
            yaz_file_type = use_stderr; /* empty name; use stderr */
        else
            yaz_file_type = use_file;
        strncpy(l_fname, fname, sizeof(l_fname)-1);
        l_fname[sizeof(l_fname)-1] = '\0';
    }
    else
    {
        yaz_file_type = use_none;  /* NULL name; use no file at all */
        l_fname[0] = '\0'; 
    }
    yaz_log_reopen();
}

static void rotate_log(const char *cur_fname)
{
    int i;

#ifdef WIN32
    /* windows can't rename a file if it is open */
    yaz_log_close();
#endif
    for (i = 0; i<9; i++)
    {
        char fname_str[FILENAME_MAX];
        struct stat stat_buf;

        sprintf(fname_str, "%s.%d", cur_fname, i);
        if (stat(fname_str, &stat_buf) != 0)
            break;
    }
    for (; i >= 0; --i)
    {
        char fname_str[2][FILENAME_MAX];

        if (i > 0)
            sprintf(fname_str[0], "%s.%d", cur_fname, i-1);
        else
            sprintf(fname_str[0], "%s", cur_fname);
        sprintf(fname_str[1], "%s.%d", cur_fname, i);
#ifdef WIN32
        MoveFileEx(fname_str[0], fname_str[1], MOVEFILE_REPLACE_EXISTING);
#else
        rename(fname_str[0], fname_str[1]);
#endif
    }
}


void yaz_log_init_level(int level)
{
    internal_log_init();
    if ( (l_level & YLOG_FLUSH) != (level & YLOG_FLUSH) )
    {
        l_level = level;
        yaz_log_reopen(); /* make sure we set buffering right */
    } 
    else
        l_level = level;

    if (l_level  & YLOG_LOGLVL)
    {  /* dump the log level bits */
        const char *bittype = "Static ";
        int i, sz;

        yaz_log(YLOG_LOGLVL, "Setting log level to %d = 0x%08x",
                l_level, l_level);
        /* determine size of mask_names (locked) */
        nmem_mutex_enter(log_mutex);
        for (sz = 0; mask_names[sz].name; sz++)
            ;
        nmem_mutex_leave(log_mutex);
        /* second pass without lock */
        for (i = 0; i < sz; i++)
            if (mask_names[i].mask && *mask_names[i].name)
                if (strcmp(mask_names[i].name, "all") != 0)
                {
                    yaz_log(YLOG_LOGLVL, "%s log bit %08x '%s' is %s",
                            bittype, mask_names[i].mask, mask_names[i].name,
                            (level & mask_names[i].mask)?  "ON": "off");
                    if (mask_names[i].mask > YLOG_LAST_BIT)
                        bittype = "Dynamic";
                }
    }
}

void yaz_log_init_prefix(const char *prefix)
{
    if (prefix && *prefix)
        sprintf(l_prefix, "%.511s ", prefix);
    else
        *l_prefix = 0;
}

void yaz_log_init_prefix2(const char *prefix)
{
    if (prefix && *prefix)
        sprintf(l_prefix2, "%.511s ", prefix);
    else
        *l_prefix2 = 0;
}

void yaz_log_init(int level, const char *prefix, const char *fname)
{
    internal_log_init();
    yaz_log_init_level(level);
    yaz_log_init_prefix(prefix);
    if (fname && *fname)
        yaz_log_init_file(fname);
}

void yaz_log_init_max_size(int mx)
{
    if (mx > 0)
        l_max_size = mx;
    else
        l_max_size = 0;
}

void yaz_log_set_handler(void (*func)(int, const char *, void *), void *info)
{
    hook_func = func;
    hook_info = info;
}

void log_event_start(void (*func)(int, const char *, void *), void *info)
{
     start_hook_func = func;
     start_hook_info = info;
}

void log_event_end(void (*func)(int, const char *, void *), void *info)
{
     end_hook_func = func;
     end_hook_info = info;
}

static void yaz_log_open_check(struct tm *tm, int force, const char *filemode)
{
    char new_filename[512];
    static char cur_filename[512] = "";

    if (yaz_file_type != use_file)
        return;

    if (l_fname && *l_fname)
    {
        strftime(new_filename, sizeof(new_filename)-1, l_fname, tm);
        if (strcmp(new_filename, cur_filename))
        {
            strcpy(cur_filename, new_filename);
            force = 1;
        }
    }

    if (l_max_size > 0 && yaz_global_log_file)
    {
        long flen = ftell(yaz_global_log_file);
        if (flen > l_max_size)
        {
            rotate_log(cur_filename);
            force = 1;
        }
    }
    if (force && *cur_filename)
    {
        FILE *new_file;
#ifdef WIN32
        yaz_log_close();
#endif
        new_file = fopen(cur_filename, filemode);
        if (new_file)
        {
            yaz_log_close();
            yaz_global_log_file = new_file;
            if (l_level & YLOG_FLUSH)
                setvbuf(yaz_global_log_file, 0, _IONBF, 0);
        }
        else
        {
            /* disable log rotate */
            l_max_size = 0;
        }
    }
}

static void yaz_log_do_reopen(const char *filemode)
{
    time_t cur_time = time(0);
#if HAVE_LOCALTIME_R
    struct tm tm0, *tm = &tm0;
#else
    struct tm *tm;
#endif

    nmem_mutex_enter(log_mutex);
#if HAVE_LOCALTIME_R
    localtime_r(&cur_time, tm);
#else
    tm = localtime(&cur_time);
#endif
    yaz_log_open_check(tm, 1, filemode);
    nmem_mutex_leave(log_mutex);
}


void yaz_log_reopen()
{
    yaz_log_do_reopen("a");
}

void yaz_log_trunc()
{
    yaz_log_do_reopen("w");
}



static void yaz_strftime(char *dst, size_t sz,
                         const char *fmt, const struct tm *tm)
{
    const char *cp = strstr(fmt, "%!");
    if (cp && strlen(fmt) < 60)
    {
        char fmt2[80];
        char tpidstr[20];
#ifdef WIN32
        DWORD tid = GetCurrentThreadId();
#else
        long tid = 0;
#if YAZ_POSIX_THREADS
        tid = pthread_self();
#endif
#endif
        memcpy(fmt2, fmt, cp-fmt);
        fmt2[cp-fmt] = '\0';
        sprintf(tpidstr, "%08lx", (long) tid);
        strcat(fmt2, tpidstr);
        strcat(fmt2, cp+2);
        strftime(dst, sz, fmt2, tm);     
    }
    else
        strftime(dst, sz, fmt, tm);
}
                            
static void yaz_log_to_file(int level, const char *log_message)
{
    FILE *file;
    time_t ti = time(0);
#if HAVE_LOCALTIME_R
    struct tm tm0, *tm = &tm0;
#else
    struct tm *tm;
#endif

    internal_log_init();

    nmem_mutex_enter(log_mutex);
    
#if HAVE_LOCALTIME_R
    localtime_r(&ti, tm);
#else
    tm = localtime(&ti);
#endif
    
    yaz_log_open_check(tm, 0, "a");  
    file = yaz_log_file(); /* file may change in yaz_log_open_check */

    if (file)
    {
        char tbuf[TIMEFORMAT_LEN];
        char flags[1024];
        int i;
        
        *flags = '\0';
        for (i = 0; level && mask_names[i].name; i++)
            if ( mask_names[i].mask & level)
            {
                if (*mask_names[i].name && mask_names[i].mask && 
                    mask_names[i].mask != YLOG_ALL)
                {
                    sprintf(flags + strlen(flags), "[%s]", mask_names[i].name);
                    level &= ~mask_names[i].mask;
                }
            }
        
        if (l_level & YLOG_NOTIME)
            tbuf[0] = '\0';
        else
            yaz_strftime(tbuf, TIMEFORMAT_LEN-1, l_actual_format, tm);
        tbuf[TIMEFORMAT_LEN-1] = '\0';
        
        fprintf(file, "%s %s%s %s%s\n", tbuf, l_prefix, flags, l_prefix2,
                log_message);
        if (l_level & YLOG_FLUSH)
            fflush(file);
    }
    nmem_mutex_leave(log_mutex);
}

void yaz_log(int level, const char *fmt, ...)
{
    va_list ap;
    char buf[4096];
    FILE *file;
    int o_level = level;

    internal_log_init();
    if (!(level & l_level))
        return;
    va_start(ap, fmt);
#ifdef WIN32
    _vsnprintf(buf, sizeof(buf)-1, fmt, ap);
#else
/* !WIN32 */
#if HAVE_VSNPRINTF
    vsnprintf(buf, sizeof(buf), fmt, ap);
#else
    vsprintf(buf, fmt, ap);
#endif
#endif
/* WIN32 */
    if (o_level & YLOG_ERRNO)
    {
        strcat(buf, " [");
        yaz_strerror(buf+strlen(buf), 2048);
        strcat(buf, "]");
    }
    va_end (ap);
    if (start_hook_func)
        (*start_hook_func)(o_level, buf, start_hook_info);
    if (hook_func)
        (*hook_func)(o_level, buf, hook_info);
    file = yaz_log_file();
    if (file)
        yaz_log_to_file(level, buf);
    if (end_hook_func)
        (*end_hook_func)(o_level, buf, end_hook_info);
}

void yaz_log_time_format(const char *fmt)
{
    if ( !fmt || !*fmt) 
    { /* no format, default to new */
        l_actual_format = l_new_default_format;
        return; 
    }
    if (0==strcmp(fmt, "old"))
    { /* force the old format */
        l_actual_format = l_old_default_format;
        return; 
    }
    /* else use custom format */
    strncpy(l_custom_format, fmt, TIMEFORMAT_LEN-1);
    l_custom_format[TIMEFORMAT_LEN-1] = '\0';
    l_actual_format = l_custom_format;
}

/** cleans a loglevel name from leading paths and suffixes */
static char *clean_name(const char *name, int len, char *namebuf, int buflen)
{
    char *p = namebuf;
    char *start = namebuf;
    if (buflen <= len)
        len = buflen-1; 
    strncpy(namebuf, name, len);
    namebuf[len] = '\0';
    while ((p = strchr(start, '/')))
        start = p+1;
    if ((p = strrchr(start, '.')))
        *p = '\0';
    return start;
}

static int define_module_bit(const char *name)
{
    int i;

    nmem_mutex_enter(log_mutex);
    for (i = 0; mask_names[i].name; i++)
        if (0 == strcmp(mask_names[i].name, name))
        {
            nmem_mutex_leave(log_mutex);
            return mask_names[i].mask;
        }
    if ( (i>=MAX_MASK_NAMES) || (next_log_bit & (1<<31) ))
    {
        nmem_mutex_leave(log_mutex);
        yaz_log(YLOG_WARN, "No more log bits left, not logging '%s'", name);
        return 0;
    }
    mask_names[i].mask = next_log_bit;
    next_log_bit = next_log_bit<<1;
    mask_names[i].name = malloc(strlen(name)+1);
    strcpy(mask_names[i].name, name);
    mask_names[i+1].name = NULL;
    mask_names[i+1].mask = 0;
    nmem_mutex_leave(log_mutex);
    return mask_names[i].mask;
}

int yaz_log_module_level(const char *name)
{
    int i;
    char clean[255];
    char *n = clean_name(name, strlen(name), clean, sizeof(clean));
    internal_log_init();
    
    nmem_mutex_enter(log_mutex);
    for (i = 0; mask_names[i].name; i++)
        if (0==strcmp(n, mask_names[i].name))
        {
            nmem_mutex_leave(log_mutex);
            yaz_log(YLOG_LOGLVL, "returning log bit 0x%x for '%s' %s",
                    mask_names[i].mask, n, 
                    strcmp(n,name) ? name : "");
            return mask_names[i].mask;
        }
    nmem_mutex_leave(log_mutex);
    yaz_log(YLOG_LOGLVL, "returning NO log bit for '%s' %s", n, 
            strcmp(n, name) ? name : "" );
    return 0;
}

int yaz_log_mask_str(const char *str)
{
    internal_log_init(); /* since l_level may be affected */
    return yaz_log_mask_str_x(str, l_level);
}

int yaz_log_mask_str_x(const char *str, int level)
{
    const char *p;

    internal_log_init();
    while (*str)
    {
        int negated = 0;
        for (p = str; *p && *p != ','; p++)
            ;
        if (*str=='-')
        {
            negated = 1;
            str++;
        }
        if (isdigit(*(unsigned char *) str))
        {
            level = atoi(str);
        }
        else 
        {
            char clean[509];
            char *n = clean_name(str, p-str, clean, sizeof(clean));
            int mask = define_module_bit(n);
            if (!mask)
                level = 0;  /* 'none' clears them all */
            else if (negated)
                level &= ~mask;
            else
                level |= mask;
        }
        if (*p == ',')
            p++;
        str = p;
    }
    return level;
}
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */
