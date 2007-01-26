/*
 * Copyright (C) 1995-2007, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: timing.c,v 1.4 2007/01/05 14:05:24 adam Exp $
 */

/**
 * \file timing.c
 * \brief Timing Utilities
 */

#if HAVE_CONFIG_H
#include <config.h>
#endif

#ifdef WIN32
#include <windows.h>
#endif
#include <stdlib.h>

#if HAVE_SYS_TIMES_H
#include <sys/times.h>
#endif
#if HAVE_SYS_TIME_H
#include <sys/time.h>
#endif
#include <time.h>

#include <yaz/xmalloc.h>
#include <yaz/timing.h>

struct yaz_timing {
#if HAVE_SYS_TIMES_H
    struct tms tms1, tms2;
#endif
#if HAVE_SYS_TIME_H
    struct timeval start_time, end_time;
#endif
#ifdef WIN32
    ULONGLONG start_time, end_time;
    ULONGLONG start_time_sys, start_time_user;
    ULONGLONG end_time_sys, end_time_user;
#endif
    double real_sec, user_sec, sys_sec;
};

yaz_timing_t yaz_timing_create(void)
{
    yaz_timing_t t = xmalloc(sizeof(*t));
    yaz_timing_start(t);
    return t;
}

#ifdef WIN32
static void get_process_time(ULONGLONG *lp_user, ULONGLONG *lp_sys)
{
    FILETIME create_t, exit_t, sys_t, user_t;
    ULARGE_INTEGER li;

    GetProcessTimes(GetCurrentProcess(), &create_t, &exit_t, &sys_t, &user_t);
    li.LowPart = user_t.dwLowDateTime;
    li.HighPart = user_t.dwHighDateTime;
    *lp_user = li.QuadPart;

    li.LowPart = sys_t.dwLowDateTime;
    li.HighPart = sys_t.dwHighDateTime;
    *lp_sys = li.QuadPart;
}
static void get_date_as_largeinteger(ULONGLONG *lp)
{
    FILETIME f;
    ULARGE_INTEGER li;
    GetSystemTimeAsFileTime(&f);
    li.LowPart = f.dwLowDateTime;
    li.HighPart = f.dwHighDateTime;

    *lp = li.QuadPart;
}
#endif

void yaz_timing_start(yaz_timing_t t)
{
#if HAVE_SYS_TIMES_H
    times(&t->tms1);
    t->user_sec = 0.0;
    t->sys_sec = 0.0;
#else
    t->user_sec = -1.0;
    t->sys_sec = -1.0;
#endif
    t->real_sec = -1.0;
#if HAVE_SYS_TIME_H
    gettimeofday(&t->start_time, 0);
    t->real_sec = 0.0;
#endif
#ifdef WIN32
    t->real_sec = 0.0;
    t->user_sec = 0.0;
    t->sys_sec = 0.0;
    get_date_as_largeinteger(&t->start_time);
    get_process_time(&t->start_time_user, &t->start_time_sys);
#endif
}

void yaz_timing_stop(yaz_timing_t t)
{
#if HAVE_SYS_TIMES_H
    times(&t->tms2);
    
    t->user_sec = (double) (t->tms2.tms_utime - t->tms1.tms_utime)/100;
    t->sys_sec = (double) (t->tms2.tms_stime - t->tms1.tms_stime)/100;
#endif
#if HAVE_SYS_TIME_H
    gettimeofday(&t->end_time, 0);
    t->real_sec = ((t->end_time.tv_sec - t->start_time.tv_sec) * 1000000.0 +
                   t->end_time.tv_usec - t->start_time.tv_usec) / 1000000;
    
#endif
#ifdef WIN32
    get_date_as_largeinteger(&t->end_time);
    t->real_sec = (t->end_time - t->start_time) / 10000000.0;

    get_process_time(&t->end_time_user, &t->end_time_sys);
    t->user_sec = (t->end_time_user - t->start_time_user) / 10000000.0;
    t->sys_sec = (t->end_time_sys - t->start_time_sys) / 10000000.0;
#endif
}

double yaz_timing_get_real(yaz_timing_t t)
{
    return t->real_sec;
}

double yaz_timing_get_user(yaz_timing_t t)
{
    return t->user_sec;
}

double yaz_timing_get_sys(yaz_timing_t t)
{
    return t->sys_sec;
}

void yaz_timing_destroy(yaz_timing_t *tp)
{
    if (*tp)
    {
        xfree(*tp);
        *tp = 0;
    }
}

/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

