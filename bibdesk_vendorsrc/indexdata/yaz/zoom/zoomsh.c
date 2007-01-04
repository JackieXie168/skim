/*
 * Copyright (C) 1995-2005, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: zoomsh.c,v 1.42 2006/10/31 14:08:03 adam Exp $
 */

/** \file zoomsh.c
    \brief ZOOM C command line tool (shell)
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#include <yaz/comstack.h>

#if HAVE_READLINE_READLINE_H
#include <readline/readline.h> 
#endif
#if HAVE_READLINE_HISTORY_H
#include <readline/history.h>
#endif

#include <yaz/xmalloc.h>

#include <yaz/log.h>
#include <yaz/nmem.h>
#include <yaz/zoom.h>
#include <yaz/oid.h>

#define MAX_CON 100

static int next_token (const char **cpp, const char **t_start)
{
    int len = 0;
    const char *cp = *cpp;
    while (*cp == ' ')
        cp++;
    if (*cp == '"')
    {
        cp++;
        *t_start = cp;
        while (*cp && *cp != '"')
        {
            cp++;
            len++;
        }
        if (*cp)
            cp++;
    }
    else
    {
        *t_start = cp;
        while (*cp && *cp != ' ' && *cp != '\r' && *cp != '\n')
        {
            cp++;
            len++;
        }
        if (len == 0)
            len = -1;
    }
    *cpp = cp;
    return len;  /* return -1 if no token was read .. */
}

static int next_token_copy (const char **cpp, char *buf_out, int buf_max)
{
    const char *start;
    int len = next_token (cpp, &start);
    if (len < 0)
    {
        *buf_out = 0;
        return len;
    }
    if (len >= buf_max)
        len = buf_max-1;
    memcpy (buf_out, start, len);
    buf_out[len] = '\0';
    return len;
}

static int is_command (const char *cmd_str, const char *this_str, int this_len)
{
    int cmd_len = strlen(cmd_str);
    if (cmd_len != this_len)
        return 0;
    if (memcmp (cmd_str, this_str, cmd_len))
        return 0;
    return 1;
}

static void cmd_set (ZOOM_connection *c, ZOOM_resultset *r,
                     ZOOM_options options,
                     const char **args)
{
    char key[40], val[80];

    if (next_token_copy (args, key, sizeof(key)) < 0)
    {
        printf ("missing argument for set\n");
        return ;
    }
    if (next_token_copy (args, val, sizeof(val)) < 0)
        ZOOM_options_set(options, key, 0);
    else
        ZOOM_options_set(options, key, val);
}

static void cmd_get (ZOOM_connection *c, ZOOM_resultset *r,
                     ZOOM_options options,
                     const char **args)
{
    char key[40];
    if (next_token_copy (args, key, sizeof(key)) < 0)
    {
        printf ("missing argument for get\n");
    }
    else
    {
        const char *val = ZOOM_options_get(options, key);
        printf ("%s = %s\n", key, val ? val : "<null>");
    }
}

static void cmd_rget(ZOOM_connection *c, ZOOM_resultset *r,
                     ZOOM_options options,
                     const char **args)
{
    char key[40];
    if (next_token_copy (args, key, sizeof(key)) < 0)
    {
        printf ("missing argument for get\n");
    }
    else
    {
        int i;
        for (i = 0; i<MAX_CON; i++)
        {
            const char *val;
            if (!r[i])
                continue;
            
            val = ZOOM_resultset_option_get(r[i], key);
            printf ("%s = %s\n", key, val ? val : "<null>");
        }
    }
}

static void cmd_close (ZOOM_connection *c, ZOOM_resultset *r,
                       ZOOM_options options,
                       const char **args)
{
    char host[60];
    int i;
    next_token_copy (args, host, sizeof(host));
    for (i = 0; i<MAX_CON; i++)
    {
        const char *h;
        if (!c[i])
            continue;
        if ((h = ZOOM_connection_option_get(c[i], "host"))
            && !strcmp (h, host))
        {
            ZOOM_connection_destroy (c[i]);
            c[i] = 0;
        }
        else if (*host == '\0')
        {
            ZOOM_connection_destroy (c[i]);
            c[i] = 0;
        }
    }
}

static void display_records (ZOOM_connection c,
                             ZOOM_resultset r,
                             int start, int count)
{
    int i;
    for (i = 0; i<count; i++)
    {
        int pos = i + start;
        ZOOM_record rec = ZOOM_resultset_record (r, pos);
        const char *db = ZOOM_record_get (rec, "database", 0);
        
        if (ZOOM_record_error(rec, 0, 0, 0))
        {
            const char *msg;
            const char *addinfo;
            const char *diagset;
            int error = ZOOM_record_error(rec, &msg, &addinfo, &diagset);
            
            printf("%d %s: %s (%s:%d) %s\n", pos, (db ? db : "unknown"),
                   msg, diagset, error, addinfo);
        }
        else
        {
            int len, opac_len;
            const char *render = ZOOM_record_get (rec, "render", &len);
            const char *opac_render = ZOOM_record_get (rec, "opac", &opac_len);
            const char *syntax = ZOOM_record_get (rec, "syntax", 0);
            /* if rec is non-null, we got a record for display */
            if (rec)
            {
                char oidbuf[100];
                (void) oid_name_to_dotstring(CLASS_RECSYN, syntax, oidbuf);
                printf ("%d %s %s (%s)\n",
                        pos, (db ? db : "unknown"), syntax, oidbuf);
                if (render)
                    fwrite (render, 1, len, stdout);
                printf ("\n");
                if (opac_render)
                    fwrite (opac_render, 1, opac_len, stdout);
            }
        }
            
    }
}

static void cmd_show (ZOOM_connection *c, ZOOM_resultset *r,
                      ZOOM_options options,
                      const char **args)
{
    int i;
    char start_str[10], count_str[10];

    if (next_token_copy (args, start_str, sizeof(start_str)) >= 0)
        ZOOM_options_set (options, "start", start_str);

    if (next_token_copy (args, count_str, sizeof(count_str)) >= 0)
        ZOOM_options_set (options, "count", count_str);

    for (i = 0; i<MAX_CON; i++)
        ZOOM_resultset_records (r[i], 0, atoi(start_str), atoi(count_str));
    while (ZOOM_event (MAX_CON, c))
        ;

    for (i = 0; i<MAX_CON; i++)
    {
        int error;
        const char *errmsg, *addinfo, *dset;
        /* display errors if any */
        if (!c[i])
            continue;
        if ((error = ZOOM_connection_error_x(c[i], &errmsg, &addinfo, &dset)))
            printf ("%s error: %s (%s:%d) %s\n",
                     ZOOM_connection_option_get(c[i], "host"), errmsg,
                     dset, error, addinfo);
        else if (r[i])
        {
            /* OK, no major errors. Display records... */
            int start = ZOOM_options_get_int (options, "start", 0);
            int count = ZOOM_options_get_int (options, "count", 0);
            display_records (c[i], r[i], start, count);
        }
    }
    ZOOM_options_set (options, "count", "0");
    ZOOM_options_set (options, "start", "0");
}

static void cmd_ext (ZOOM_connection *c, ZOOM_resultset *r,
                     ZOOM_options options,
                     const char **args)
{
    ZOOM_package p[MAX_CON];
    char ext_type_str[10];
    
    int i;

    if (next_token_copy (args, ext_type_str, sizeof(ext_type_str)) < 0)
        return;
    
    for (i = 0; i<MAX_CON; i++)
    {
        if (c[i])
        {
            p[i] = ZOOM_connection_package (c[i], 0);
            ZOOM_package_send(p[i], ext_type_str);
        }
        else
            p[i] = 0;
    }

    while (ZOOM_event (MAX_CON, c))
        ;

    for (i = 0; i<MAX_CON; i++)
    {
        int error;
        const char *errmsg, *addinfo, *dset;
        /* display errors if any */
        if (!p[i])
            continue;
        if ((error = ZOOM_connection_error_x(c[i], &errmsg, &addinfo, &dset)))
            printf ("%s error: %s (%s:%d) %s\n",
                     ZOOM_connection_option_get(c[i], "host"), errmsg,
                     dset, error, addinfo);
        else if (p[i])
        {
            const char *v;
            printf ("ok\n");
            v = ZOOM_package_option_get (p[i], "targetReference");
            if (v)
                printf("targetReference: %s\n", v);
            v = ZOOM_package_option_get (p[i], "xmlUpdateDoc");
            if (v)
                printf("xmlUpdateDoc: %s\n", v);
        }
        ZOOM_package_destroy (p[i]);
    }
}

static void cmd_debug (ZOOM_connection *c, ZOOM_resultset *r,
                       ZOOM_options options,
                       const char **args)
{
    yaz_log_init_level(YLOG_ALL);
}

static void cmd_search (ZOOM_connection *c, ZOOM_resultset *r,
                        ZOOM_options options,
                        const char **args)
{
    ZOOM_query s;
    const char *query_str = *args;
    int i;
    
    s = ZOOM_query_create ();
    while (*query_str == ' ')
        query_str++;
    if (memcmp(query_str, "cql:", 4) == 0)
    {
        ZOOM_query_cql (s, query_str + 4);
    }
    else if (ZOOM_query_prefix (s, query_str))
    {
        printf ("Bad PQF: %s\n", query_str);
        return;
    }
    for (i = 0; i<MAX_CON; i++)
    {
        if (c[i])
        {
            ZOOM_resultset_destroy (r[i]);
            r[i] = 0;
        }
        if (c[i])
            r[i] = ZOOM_connection_search (c[i], s);
    }

    while (ZOOM_event (MAX_CON, c))
        ;

    for (i = 0; i<MAX_CON; i++)
    {
        int error;
        const char *errmsg, *addinfo, *dset;
        /* display errors if any */
        if (!c[i])
            continue;
        if ((error = ZOOM_connection_error_x(c[i], &errmsg, &addinfo, &dset)))
            printf ("%s error: %s (%s:%d) %s\n",
                    ZOOM_connection_option_get(c[i], "host"), errmsg,
                    dset, error, addinfo);
        else if (r[i])
        {
            /* OK, no major errors. Look at the result count */
            int start = ZOOM_options_get_int (options, "start", 0);
            int count = ZOOM_options_get_int (options, "count", 0);

            printf ("%s: %ld hits\n", ZOOM_connection_option_get(c[i], "host"),
                    (long) ZOOM_resultset_size(r[i]));
            /* and display */
            display_records (c[i], r[i], start, count);
        }
    }
    ZOOM_query_destroy (s);
}

static void cmd_scan (ZOOM_connection *c, ZOOM_resultset *r,
                      ZOOM_options options,
                      const char **args)
{
    const char *start_term = *args;
    int i;
    ZOOM_scanset s[MAX_CON];
    
    while (*start_term == ' ')
        start_term++;

    for (i = 0; i<MAX_CON; i++)
    {
        if (c[i])
            s[i] = ZOOM_connection_scan(c[i], start_term);
        else
            s[i] = 0;
    }
    while (ZOOM_event(MAX_CON, c))
        ;
    for (i = 0; i<MAX_CON; i++)
    {
        if (s[i]) {
            size_t p, sz = ZOOM_scanset_size(s[i]);
            for (p = 0; p < sz; p++)
            {
                int occ = 0;
                int len = 0;
                const char *term = ZOOM_scanset_display_term(s[i], p,
                                &occ, &len);
                fwrite(term, 1, len, stdout);
                printf (" %d\n", occ);
            }            
            ZOOM_scanset_destroy(s[i]);
        }
    }
}

static void cmd_sort (ZOOM_connection *c, ZOOM_resultset *r,
                      ZOOM_options options,
                      const char **args)
{
    const char *sort_spec = *args;
    int i;
    
    while (*sort_spec == ' ')
        sort_spec++;
    
    for (i = 0; i<MAX_CON; i++)
    {
        if (r[i])
            ZOOM_resultset_sort(r[i], "yaz", sort_spec);
    }
    while (ZOOM_event(MAX_CON, c))
        ;
}

static void cmd_help (ZOOM_connection *c, ZOOM_resultset *r,
                      ZOOM_options options,
                      const char **args)
{
    printf ("connect <zurl>\n");
    printf ("search <pqf>\n");
    printf ("show [<start> [<count>]\n");
    printf ("scan <term>\n");
    printf ("quit\n");
    printf ("close <zurl>\n");
    printf ("ext <type>\n");
    printf ("set <option> [<value>]\n");
    printf ("get <option>\n");
    printf ("\n");
    printf ("options:\n");
    printf (" start\n");
    printf (" count\n");
    printf (" databaseName\n");
    printf (" preferredRecordSyntax\n");
    printf (" proxy\n");
    printf (" elementSetName\n");
    printf (" maximumRecordSize\n");
    printf (" preferredRecordSize\n");
    printf (" async\n");
    printf (" piggyback\n");
    printf (" group\n");
    printf (" user\n");
    printf (" password\n");
    printf (" implementationName\n");
    printf (" charset\n");
    printf (" lang\n");
}

static void cmd_connect (ZOOM_connection *c, ZOOM_resultset *r,
                         ZOOM_options options,
                         const char **args)
{
    int error;
    const char *errmsg, *addinfo, *dset;
    char host[60];
    int j, i;
    if (next_token_copy (args, host, sizeof(host)) < 0)
    {
        printf ("missing host after connect\n");
        return ;
    }
    for (j = -1, i = 0; i<MAX_CON; i++)
    {
        const char *h;
        if (c[i] && (h = ZOOM_connection_option_get(c[i], "host")) &&
            !strcmp (h, host))
        {
            ZOOM_connection_destroy (c[i]);
            break;
        }
        else if (c[i] == 0 && j == -1)
            j = i;
    }
    if (i == MAX_CON)  /* no match .. */
    {
        if (j == -1)
        {
            printf ("no more connection available\n");
            return;
        }
        i = j;   /* OK, use this one is available */
    }
    c[i] = ZOOM_connection_create (options);
    ZOOM_connection_connect (c[i], host, 0);
        
    if ((error = ZOOM_connection_error_x(c[i], &errmsg, &addinfo, &dset)))
       printf ("%s error: %s (%s:%d) %s\n",
            ZOOM_connection_option_get(c[i], "host"), errmsg,
            dset, error, addinfo);
}

static int cmd_parse (ZOOM_connection *c, ZOOM_resultset *r,
                      ZOOM_options options, 
                      const char **buf)
{
    int cmd_len;
    const char *cmd_str;

    cmd_len = next_token (buf, &cmd_str);
    if (cmd_len < 0)
        return 1;
    if (is_command ("quit", cmd_str, cmd_len))
        return 0;
    else if (is_command ("set", cmd_str, cmd_len))
        cmd_set (c, r, options, buf);
    else if (is_command ("get", cmd_str, cmd_len))
        cmd_get (c, r, options, buf);
    else if (is_command ("rget", cmd_str, cmd_len))
        cmd_rget (c, r, options, buf);
    else if (is_command ("connect", cmd_str, cmd_len))
        cmd_connect (c, r, options, buf);
    else if (is_command ("open", cmd_str, cmd_len))
        cmd_connect (c, r, options, buf);
    else if (is_command ("search", cmd_str, cmd_len))
        cmd_search (c, r, options, buf);
    else if (is_command ("find", cmd_str, cmd_len))
        cmd_search (c, r, options, buf);
    else if (is_command ("show", cmd_str, cmd_len))
        cmd_show (c, r, options, buf);
    else if (is_command ("close", cmd_str, cmd_len))
        cmd_close (c, r, options, buf);
    else if (is_command ("help", cmd_str, cmd_len))
        cmd_help(c, r, options, buf);
    else if (is_command ("ext", cmd_str, cmd_len))
        cmd_ext(c, r, options, buf);
    else if (is_command ("debug", cmd_str, cmd_len))
        cmd_debug(c, r, options, buf);
    else if (is_command ("scan", cmd_str, cmd_len))
        cmd_scan(c, r, options, buf);
    else if (is_command ("sort", cmd_str, cmd_len))
        cmd_sort(c, r, options, buf);
    else
        printf ("unknown command %.*s\n", cmd_len, cmd_str);
    return 2;
}

void shell(ZOOM_connection *c, ZOOM_resultset *r,
           ZOOM_options options)
{
    while (1)
    {
        char buf[1000];
        char *cp;
        const char *bp = buf;
#if HAVE_READLINE_READLINE_H
        char* line_in;
        line_in=readline("ZOOM>");
        if (!line_in)
            break;
#if HAVE_READLINE_HISTORY_H
        if (*line_in)
            add_history(line_in);
#endif
        if(strlen(line_in) > 999) {
            printf("Input line too long\n");
            break;
        };
        strcpy(buf,line_in);
        free (line_in);
#else    
        printf ("ZOOM>"); fflush (stdout);
        if (!fgets (buf, 999, stdin))
            break;
#endif 
        if ((cp = strchr(buf, '\n')))
            *cp = '\0';
        if (!cmd_parse (c, r, options, &bp))
            break;
    }
}

static void zoomsh(int argc, char **argv)
{
    ZOOM_options options = ZOOM_options_create();
    int i, res;
    ZOOM_connection z39_con[MAX_CON];
    ZOOM_resultset  z39_res[MAX_CON];

    for (i = 0; i<MAX_CON; i++)
    {
        z39_con[i] = 0;
        z39_res[i] = 0;
    }

    for (i = 0; i<MAX_CON; i++)
        z39_con[i] = 0;

    res = 1;
    for (i = 1; i<argc; i++)
    {
        const char *bp = argv[i];
        res = cmd_parse(z39_con, z39_res, options, &bp);
        if (res == 0)  /* received quit */
            break;
    }
    if (res)  /* do cmdline shell only if not quitting */
        shell(z39_con, z39_res, options);
    ZOOM_options_destroy(options);

    for (i = 0; i<MAX_CON; i++)
    {
        ZOOM_connection_destroy(z39_con[i]);
        ZOOM_resultset_destroy(z39_res[i]);
    }
}

int main(int argc, char **argv)
{
    const char *maskstr = 0;
    if (argc > 2 && !strcmp(argv[1], "-v"))
    {
        maskstr = argv[2];
        argv += 2;
        argc -= 2;
    }
    else if (argc > 1 && !strncmp(argv[1], "-v", 2))
    {
        maskstr = argv[1]+2;
        argv++;
        argc--;
    }
    if (maskstr)
    {
        int mask = yaz_log_mask_str(maskstr);
        yaz_log_init_level(mask);
    }
    nmem_init();
    zoomsh(argc, argv);
    nmem_exit();
    exit (0);
}
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

