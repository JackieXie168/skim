/*
 * Copyright (C) 1995-2007, Index Data ApS
 * All rights reserved.
 *
 * $Id: readconf.c,v 1.7 2007/01/03 08:42:15 adam Exp $
 */

/**
 * \file readconf.c
 * \brief Implements config file reading
 */

#if HAVE_CONFIG_H
#include <config.h>
#endif

#include <stdio.h>
#include <ctype.h>

#include <yaz/log.h>
#include <yaz/readconf.h>

#define l_isspace(c) ((c) == '\t' || (c) == ' ' || (c) == '\n' || (c) == '\r')

int readconf_line(FILE *f, int *lineno, char *line, int len,
                  char *argv[], int num)
{
    char *p;
    int argc;
    
    while ((p = fgets(line, len, f)))
    {
        (*lineno)++;
        while (*p && l_isspace(*p))
            p++;
        if (*p && *p != '#')
            break;
    }
    if (!p)
        return 0;
    
    for (argc = 0; *p ; argc++)
    {
        if (*p == '#')  /* trailing comment */
            break;
        argv[argc] = p;
        while (*p && !l_isspace(*p))
            p++;
        if (*p)
        {
            *(p++) = '\0';
            while (*p && l_isspace(*p))
                p++;
        }
    }
    return argc;
}

/*
 * Read lines of a configuration file.
 */
int readconf(char *name, void *rprivate,
             int (*fun)(char *name, void *rprivate, int argc, char *argv[]))
{
    FILE *f;
    char line[512], *m_argv[50];
    int m_argc;
    int lineno = 0;
    
    if (!(f = fopen(name, "r")))
    {
        yaz_log(YLOG_WARN|YLOG_ERRNO, "readconf: %s", name);
        return -1;
    }
    for (;;)
    {
        int res;
        
        if (!(m_argc = readconf_line(f, &lineno, line, 512, m_argv, 50)))
        {
            fclose(f);
            return 0;
        }

        if ((res = (*fun)(name, rprivate, m_argc, m_argv)))
        {
            fclose(f);
            return res;
        }
    }
}
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

