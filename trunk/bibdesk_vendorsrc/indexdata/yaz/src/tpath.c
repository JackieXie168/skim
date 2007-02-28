/*
 * Copyright (C) 1995-2007, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: tpath.c,v 1.13 2007/01/03 08:42:15 adam Exp $
 */
/**
 * \file tpath.c
 * \brief File Path utilities
 */

#if HAVE_CONFIG_H
#include <config.h>
#endif


#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <yaz/tpath.h>
#include <yaz/log.h>
#include <sys/types.h>
#include <sys/stat.h>
#if HAVE_UNISTD_H
#include <unistd.h>
#endif

FILE *yaz_path_fopen(const char *path, const char *name, const char *mode)
{
    return yaz_fopen (path, name, mode, 0);
}

int yaz_fclose (FILE *f)
{
    return fclose (f);
}


size_t yaz_filepath_comp(const char **path_p, const char **comp)
{
    const char *path = *path_p;
    size_t len;
    const char *path_sep;

    /* somewhat dirty since we have to consider Windows
     * drive letters..
     */
    if (path[0] && strchr ("/\\.", path[0]))
        path_sep = strchr (path+1, ':');
    else if (path[0] && path[1])
        path_sep = strchr (path+2, ':');
    else
        path_sep = 0;
    
    if (path_sep)
    {
        len = path_sep - path;
        *path_p = path + len + 1;
    }
    else
    {
        len = strlen(path);
        *path_p = path + len;
    }
    *comp = path;
    return len;
}

char *yaz_filepath_resolve(const char *fname, const char *path,
                           const char *base, char *fullpath)
{
    for(;;)
    {
        struct stat stat_buf;
        size_t slen = 0;
       
        *fullpath = '\0';
        if (path)
        {
            const char *comp;
            size_t len = 0;

            len = yaz_filepath_comp(&path, &comp);
            if (!len)
                break;

            if (!strchr ("/\\", *comp) && base)
            {
                /* yes: make base the first part */
                strcpy (fullpath, base);
                slen = strlen(fullpath);
                fullpath[slen++] = '/';
            }
            memcpy (fullpath+slen, comp, len);
            slen += len;
            if (slen > 0 && !strchr("/\\", fullpath[slen-1]))
                fullpath[slen++] = '/';
        }
        strcpy (fullpath+slen, fname);
        if (stat(fullpath, &stat_buf) == 0)
            return fullpath;
        if (!path)
            break;
    }
    return 0;
}

FILE *yaz_fopen(const char *path, const char *fname, const char *mode,
                const char *base)
{
    char fullpath[1024];

    if (!yaz_filepath_resolve(fname, path, base, fullpath))
        return 0; /* failure */
    return fopen(fullpath, mode);
}

int yaz_is_abspath (const char *p)
{
    if (*p == '/')
        return 1;
#ifdef WIN32
    if (*p == '\\')
        return 1;
    if (*p && p[1] == ':' && isalpha(*p))
        return 1;
#endif
    return 0;
}
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

