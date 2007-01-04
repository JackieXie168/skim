/*
 * Copyright (C) 1995-2006, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: zoom-c.c,v 1.103 2006/12/17 16:03:01 adam Exp $
 */
/**
 * \file zoom-c.c
 * \brief Implements ZOOM C interface.
 */

#include <assert.h>
#include <string.h>
#include <errno.h>
#include "zoom-p.h"

#include <yaz/yaz-util.h>
#include <yaz/xmalloc.h>
#include <yaz/otherinfo.h>
#include <yaz/log.h>
#include <yaz/pquery.h>
#include <yaz/marcdisp.h>
#include <yaz/diagbib1.h>
#include <yaz/charneg.h>
#include <yaz/ill.h>
#include <yaz/srw.h>
#include <yaz/cql.h>
#include <yaz/ccl.h>

#if HAVE_SYS_TYPES_H
#include <sys/types.h>
#endif
#if HAVE_SYS_TIME_H
#include <sys/time.h>
#endif
#if HAVE_SYS_POLL_H
#include <sys/poll.h>
#endif
#if HAVE_SYS_SELECT_H
#include <sys/select.h>
#endif
#ifdef WIN32
#if FD_SETSIZE < 512
#define FD_SETSIZE 512
#endif
#include <winsock.h>
#endif

static int log_api = 0;
static int log_details = 0;

typedef enum {
    zoom_pending,
    zoom_complete
} zoom_ret;

static zoom_ret ZOOM_connection_send_init(ZOOM_connection c);
static zoom_ret do_write_ex(ZOOM_connection c, char *buf_out, int len_out);
static char *cql2pqf(ZOOM_connection c, const char *cql);

static void initlog(void)
{
    static int log_level_initialized = 0;
    if (!log_level_initialized)
    {
        log_api = yaz_log_module_level("zoom");
        log_details = yaz_log_module_level("zoomdetails");
        log_level_initialized = 1;
    }
}

static ZOOM_Event ZOOM_Event_create(int kind)
{
    ZOOM_Event event = (ZOOM_Event) xmalloc(sizeof(*event));
    event->kind = kind;
    event->next = 0;
    event->prev = 0;
    yaz_log(log_details, "ZOOM_Event_create(kind=%d)", kind);
    return event;
}

static void ZOOM_Event_destroy(ZOOM_Event event)
{
    xfree(event);
}

static void ZOOM_connection_put_event(ZOOM_connection c, ZOOM_Event event)
{
    if (c->m_queue_back)
    {
        c->m_queue_back->prev = event;
        assert(c->m_queue_front);
    }
    else
    {
        assert(!c->m_queue_front);
        c->m_queue_front = event;
    }
    event->next = c->m_queue_back;
    event->prev = 0;
    c->m_queue_back = event;
}

static ZOOM_Event ZOOM_connection_get_event(ZOOM_connection c)
{
    ZOOM_Event event = c->m_queue_front;
    if (!event)
    {
        c->last_event = ZOOM_EVENT_NONE;
        return 0;
    }
    assert(c->m_queue_back);
    c->m_queue_front = event->prev;
    if (c->m_queue_front)
    {
        assert(c->m_queue_back);
        c->m_queue_front->next = 0;
    }
    else
        c->m_queue_back = 0;
    c->last_event = event->kind;
    return event;
}


static void set_dset_error(ZOOM_connection c, int error,
                           const char *dset,
                           const char *addinfo, const char *addinfo2)
{
    char *cp;

    xfree(c->addinfo);
    c->addinfo = 0;
    c->error = error;
    if (!c->diagset || strcmp(dset, c->diagset))
    {
        xfree(c->diagset);
        c->diagset = xstrdup(dset);
        /* remove integer part from SRW diagset .. */
        if ((cp = strrchr(c->diagset, '/')))
            *cp = '\0';
    }
    if (addinfo && addinfo2)
    {
        c->addinfo = (char*) xmalloc(strlen(addinfo) + strlen(addinfo2) + 2);
        strcpy(c->addinfo, addinfo);
        strcat(c->addinfo, addinfo2);
    }
    else if (addinfo)
        c->addinfo = xstrdup(addinfo);
    if (error)
        yaz_log(log_api, "%p set_dset_error %s %s:%d %s %s",
                c, c->host_port ? c->host_port : "<>", dset, error,
                addinfo ? addinfo : "",
                addinfo2 ? addinfo2 : "");
}

#if YAZ_HAVE_XML2
static void set_HTTP_error(ZOOM_connection c, int error,
                           const char *addinfo, const char *addinfo2)
{
    set_dset_error(c, error, "HTTP", addinfo, addinfo2);
}
#endif

static void set_ZOOM_error(ZOOM_connection c, int error,
                           const char *addinfo)
{
    set_dset_error(c, error, "ZOOM", addinfo, 0);
}

static void clear_error(ZOOM_connection c)
{
    /*
     * If an error is tied to an operation then it's ok to clear: for
     * example, a diagnostic returned from a search is cleared by a
     * subsequent search.  However, problems such as Connection Lost
     * or Init Refused are not cleared, because they are not
     * recoverable: doing another search doesn't help.
     */
    switch (c->error)
    {
    case ZOOM_ERROR_CONNECT:
    case ZOOM_ERROR_MEMORY:
    case ZOOM_ERROR_DECODE:
    case ZOOM_ERROR_CONNECTION_LOST:
    case ZOOM_ERROR_INIT:
    case ZOOM_ERROR_INTERNAL:
    case ZOOM_ERROR_UNSUPPORTED_PROTOCOL:
        break;
    default:
        set_ZOOM_error(c, ZOOM_ERROR_NONE, 0);
    }
}

void ZOOM_connection_show_task(ZOOM_task task)
{
    switch(task->which)
    {
    case ZOOM_TASK_SEARCH:
        yaz_log(YLOG_LOG, "search p=%p", task);
        break;
    case ZOOM_TASK_RETRIEVE:
        yaz_log(YLOG_LOG, "retrieve p=%p", task);
        break;
    case ZOOM_TASK_CONNECT:
        yaz_log(YLOG_LOG, "connect p=%p", task);
        break;
    case ZOOM_TASK_SCAN:
        yaz_log(YLOG_LOG, "scant p=%p", task);
        break;
    }
}

void ZOOM_connection_show_tasks(ZOOM_connection c)
{
    ZOOM_task task;
    yaz_log(YLOG_LOG, "connection p=%p tasks", c);
    for (task = c->tasks; task; task = task->next)
        ZOOM_connection_show_task(task);
}

ZOOM_task ZOOM_connection_add_task(ZOOM_connection c, int which)
{
    ZOOM_task *taskp = &c->tasks;
    while (*taskp)
        taskp = &(*taskp)->next;
    *taskp = (ZOOM_task) xmalloc(sizeof(**taskp));
    (*taskp)->running = 0;
    (*taskp)->which = which;
    (*taskp)->next = 0;
    clear_error(c);
    return *taskp;
}

ZOOM_API(int) ZOOM_connection_is_idle(ZOOM_connection c)
{
    return c->tasks ? 0 : 1;
}

ZOOM_task ZOOM_connection_insert_task(ZOOM_connection c, int which)
{
    ZOOM_task task = (ZOOM_task) xmalloc(sizeof(*task));

    task->next = c->tasks;
    c->tasks = task;

    task->running = 0;
    task->which = which;
    clear_error(c);
    return task;
}

void ZOOM_connection_remove_task(ZOOM_connection c)
{
    ZOOM_task task = c->tasks;

    if (task)
    {
        c->tasks = task->next;
        switch (task->which)
        {
        case ZOOM_TASK_SEARCH:
            ZOOM_resultset_destroy(task->u.search.resultset);
            xfree(task->u.search.syntax);
            xfree(task->u.search.elementSetName);
            break;
        case ZOOM_TASK_RETRIEVE:
            ZOOM_resultset_destroy(task->u.retrieve.resultset);
            xfree(task->u.retrieve.syntax);
            xfree(task->u.retrieve.elementSetName);
            break;
        case ZOOM_TASK_CONNECT:
            break;
        case ZOOM_TASK_SCAN:
            ZOOM_scanset_destroy(task->u.scan.scan);
            break;
        case ZOOM_TASK_PACKAGE:
            ZOOM_package_destroy(task->u.package);
            break;
        case ZOOM_TASK_SORT:
            ZOOM_resultset_destroy(task->u.sort.resultset);
            ZOOM_query_destroy(task->u.sort.q);
            break;
        default:
            assert(0);
        }
        xfree(task);

        if (!c->tasks)
        {
            ZOOM_Event event = ZOOM_Event_create(ZOOM_EVENT_END);
            ZOOM_connection_put_event(c, event);
        }
    }
}

static int ZOOM_connection_exec_task(ZOOM_connection c);

void ZOOM_connection_remove_tasks(ZOOM_connection c)
{
    while (c->tasks)
        ZOOM_connection_remove_task(c);
}

static ZOOM_record record_cache_lookup(ZOOM_resultset r, int pos,
                                       const char *syntax,
                                       const char *elementSetName);

ZOOM_API(ZOOM_connection)
    ZOOM_connection_create(ZOOM_options options)
{
    ZOOM_connection c = (ZOOM_connection) xmalloc(sizeof(*c));

    initlog();

    yaz_log(log_api, "%p ZOOM_connection_create", c);

    c->proto = PROTO_Z3950;
    c->cs = 0;
    c->mask = 0;
    c->reconnect_ok = 0;
    c->state = STATE_IDLE;
    c->addinfo = 0;
    c->diagset = 0;
    set_ZOOM_error(c, ZOOM_ERROR_NONE, 0);
    c->buf_in = 0;
    c->len_in = 0;
    c->buf_out = 0;
    c->len_out = 0;
    c->resultsets = 0;

    c->options = ZOOM_options_create_with_parent(options);

    c->host_port = 0;
    c->path = 0;
    c->proxy = 0;
    
    c->charset = c->lang = 0;

    c->cookie_out = 0;
    c->cookie_in = 0;
    c->client_IP = 0;
    c->tasks = 0;

    c->odr_in = odr_createmem(ODR_DECODE);
    c->odr_out = odr_createmem(ODR_ENCODE);

    c->async = 0;
    c->support_named_resultsets = 0;
    c->last_event = ZOOM_EVENT_NONE;

    c->m_queue_front = 0;
    c->m_queue_back = 0;
    return c;
}


/* set database names. Take local databases (if set); otherwise
   take databases given in ZURL (if set); otherwise use Default */
static char **set_DatabaseNames(ZOOM_connection con, ZOOM_options options,
                                int *num, ODR odr)
{
    char **databaseNames;
    const char *cp = ZOOM_options_get(options, "databaseName");
    
    if ((!cp || !*cp) && con->host_port)
    {
        if (strncmp(con->host_port, "unix:", 5) == 0)
            cp = strchr(con->host_port+5, ':');
        else
            cp = strchr(con->host_port, '/');
        if (cp)
            cp++;
    }
    if (!cp)
        cp = "Default";
    nmem_strsplit(odr->mem, "+", cp,  &databaseNames, num);
    return databaseNames;
}

ZOOM_API(ZOOM_connection)
    ZOOM_connection_new(const char *host, int portnum)
{
    ZOOM_connection c = ZOOM_connection_create(0);

    ZOOM_connection_connect(c, host, portnum);
    return c;
}

static zoom_sru_mode get_sru_mode_from_string(const char *s)
{
    if (!s || !*s)
        return zoom_sru_soap;
    if (!yaz_matchstr(s, "soap"))
        return zoom_sru_soap;
    else if (!yaz_matchstr(s, "get"))
        return zoom_sru_get;
    else if (!yaz_matchstr(s, "post"))
        return zoom_sru_post;
    return zoom_sru_error;
}

ZOOM_API(void)
    ZOOM_connection_connect(ZOOM_connection c,
                            const char *host, int portnum)
{
    const char *val;
    ZOOM_task task;

    initlog();

    yaz_log(log_api, "%p ZOOM_connection_connect host=%s portnum=%d",
            c, host, portnum);

    set_ZOOM_error(c, ZOOM_ERROR_NONE, 0);
    ZOOM_connection_remove_tasks(c);

    if (c->cs)
    {
        yaz_log(log_details, "%p ZOOM_connection_connect reconnect ok", c);
        c->reconnect_ok = 1;
        return;
    }
    yaz_log(log_details, "%p ZOOM_connection_connect connect", c);
    xfree(c->proxy);
    val = ZOOM_options_get(c->options, "proxy");
    if (val && *val)
    {
        yaz_log(log_details, "%p ZOOM_connection_connect proxy=%s", c, val);
        c->proxy = xstrdup(val);
    }
    else
        c->proxy = 0;

    xfree(c->charset);
    val = ZOOM_options_get(c->options, "charset");
    if (val && *val)
    {
        yaz_log(log_details, "%p ZOOM_connection_connect charset=%s", c, val);
        c->charset = xstrdup(val);
    }
    else
        c->charset = 0;

    xfree(c->lang);
    val = ZOOM_options_get(c->options, "lang");
    if (val && *val)
    {
        yaz_log(log_details, "%p ZOOM_connection_connect lang=%s", c, val);
        c->lang = xstrdup(val);
    }
    else
        c->lang = 0;

    xfree(c->host_port);
    if (portnum)
    {
        char hostn[128];
        sprintf(hostn, "%.80s:%d", host, portnum);
        c->host_port = xstrdup(hostn);
    }
    else
        c->host_port = xstrdup(host);

    {
        /*
         * If the "<scheme>:" part of the host string is preceded by one
         * or more comma-separated <name>=<value> pairs, these are taken
         * to be options to be set on the connection object.  Among other
         * applications, this facility can be used to embed authentication
         * in a host string:
         *          user=admin,password=secret,tcp:localhost:9999
         */
        char *remainder = c->host_port;
        char *pcolon = strchr(remainder, ':');
        char *pcomma;
        char *pequals;
        while ((pcomma = strchr(remainder, ',')) != 0 &&
               (pcolon == 0 || pcomma < pcolon)) {
            *pcomma = '\0';
            if ((pequals = strchr(remainder, '=')) != 0) {
                *pequals = '\0';
                /*printf("# setting '%s'='%s'\n", remainder, pequals+1);*/
                ZOOM_connection_option_set(c, remainder, pequals+1);
            }
            remainder = pcomma+1;
        }

        if (remainder != c->host_port) {
            xfree(c->host_port);
            c->host_port = xstrdup(remainder);
            /*printf("# reset hp='%s'\n", remainder);*/
        }
    }

    val = ZOOM_options_get(c->options, "sru");
    c->sru_mode = get_sru_mode_from_string(val);

    ZOOM_options_set(c->options, "host", c->host_port);

    val = ZOOM_options_get(c->options, "cookie");
    if (val && *val)
    { 
        yaz_log(log_details, "%p ZOOM_connection_connect cookie=%s", c, val);
        c->cookie_out = xstrdup(val);
    }

    val = ZOOM_options_get(c->options, "clientIP");
    if (val && *val)
    {
        yaz_log(log_details, "%p ZOOM_connection_connect clientIP=%s",
                c, val);
        c->client_IP = xstrdup(val);
    }

    c->async = ZOOM_options_get_bool(c->options, "async", 0);
    yaz_log(log_details, "%p ZOOM_connection_connect async=%d", c, c->async);
 
    task = ZOOM_connection_add_task(c, ZOOM_TASK_CONNECT);

    if (!c->async)
    {
        while (ZOOM_event(1, &c))
            ;
    }
}

ZOOM_API(ZOOM_query)
    ZOOM_query_create(void)
{
    ZOOM_query s = (ZOOM_query) xmalloc(sizeof(*s));

    yaz_log(log_details, "%p ZOOM_query_create", s);
    s->refcount = 1;
    s->z_query = 0;
    s->sort_spec = 0;
    s->odr = odr_createmem(ODR_ENCODE);
    s->query_string = 0;

    return s;
}

ZOOM_API(void)
    ZOOM_query_destroy(ZOOM_query s)
{
    if (!s)
        return;

    (s->refcount)--;
    yaz_log(log_details, "%p ZOOM_query_destroy count=%d", s, s->refcount);
    if (s->refcount == 0)
    {
        odr_destroy(s->odr);
        xfree(s);
    }
}

ZOOM_API(int)
    ZOOM_query_prefix(ZOOM_query s, const char *str)
{
    s->query_string = odr_strdup(s->odr, str);
    s->z_query = (Z_Query *) odr_malloc(s->odr, sizeof(*s->z_query));
    s->z_query->which = Z_Query_type_1;
    s->z_query->u.type_1 =  p_query_rpn(s->odr, PROTO_Z3950, str);
    if (!s->z_query->u.type_1)
    {
        yaz_log(log_details, "%p ZOOM_query_prefix str=%s failed", s, str);
        s->z_query = 0;
        return -1;
    }
    yaz_log(log_details, "%p ZOOM_query_prefix str=%s", s, str);
    return 0;
}

ZOOM_API(int)
    ZOOM_query_cql(ZOOM_query s, const char *str)
{
    Z_External *ext;

    s->query_string = odr_strdup(s->odr, str);

    ext = (Z_External *) odr_malloc(s->odr, sizeof(*ext));
    ext->direct_reference = odr_getoidbystr(s->odr, "1.2.840.10003.16.2");
    ext->indirect_reference = 0;
    ext->descriptor = 0;
    ext->which = Z_External_CQL;
    ext->u.cql = s->query_string;
    
    s->z_query = (Z_Query *) odr_malloc(s->odr, sizeof(*s->z_query));
    s->z_query->which = Z_Query_type_104;
    s->z_query->u.type_104 =  ext;

    yaz_log(log_details, "%p ZOOM_query_cql str=%s", s, str);

    return 0;
}

/*
 * Translate the CQL string client-side into RPN which is passed to
 * the server.  This is useful for server's that don't themselves
 * support CQL, for which ZOOM_query_cql() is useless.  `conn' is used
 * only as a place to stash diagnostics if compilation fails; if this
 * information is not needed, a null pointer may be used.
 */
ZOOM_API(int)
    ZOOM_query_cql2rpn(ZOOM_query s, const char *str, ZOOM_connection conn)
{
    char *rpn;
    int ret;
    ZOOM_connection freeme = 0;

    yaz_log(log_details, "%p ZOOM_query_cql2rpn str=%s conn=%p", s, str, conn);
    if (conn == 0)
        conn = freeme = ZOOM_connection_create(0);

    rpn = cql2pqf(conn, str);
    if (freeme != 0)
        ZOOM_connection_destroy(freeme);
    if (rpn == 0)
        return -1;

    ret = ZOOM_query_prefix(s, rpn);
    xfree(rpn);
    return ret;
}

/*
 * Analogous in every way to ZOOM_query_cql2rpn(), except that there
 * is no analogous ZOOM_query_ccl() that just sends uninterpreted CCL
 * to the server, as the YAZ GFS doesn't know how to handle this.
 */
ZOOM_API(int)
    ZOOM_query_ccl2rpn(ZOOM_query s, const char *str, const char *config,
                       int *ccl_error, const char **error_string,
                       int *error_pos)
{
    int ret;
    struct ccl_rpn_node *rpn;
    CCL_bibset bibset = ccl_qual_mk();

    if (config)
        ccl_qual_buf(bibset, config);

    rpn = ccl_find_str(bibset, str, ccl_error, error_pos);
    if (!rpn)
    {
        *error_string = ccl_err_msg(*ccl_error);
        ret = -1;
    }
    else
    {
        WRBUF wr = wrbuf_alloc();
        ccl_pquery(wr, rpn);
        ccl_rpn_delete(rpn);
        ret = ZOOM_query_prefix(s, wrbuf_buf(wr));
        wrbuf_free(wr, 1);
    }
    ccl_qual_rm(&bibset);
    return ret;
}

ZOOM_API(int)
    ZOOM_query_sortby(ZOOM_query s, const char *criteria)
{
    s->sort_spec = yaz_sort_spec(s->odr, criteria);
    if (!s->sort_spec)
    {
        yaz_log(log_details, "%p ZOOM_query_sortby criteria=%s failed",
                s, criteria);
        return -1;
    }
    yaz_log(log_details, "%p ZOOM_query_sortby criteria=%s", s, criteria);
    return 0;
}

static zoom_ret do_write(ZOOM_connection c);

ZOOM_API(void)
    ZOOM_connection_destroy(ZOOM_connection c)
{
    ZOOM_resultset r;
    if (!c)
        return;
    yaz_log(log_api, "%p ZOOM_connection_destroy", c);
    if (c->cs)
        cs_close(c->cs);
    for (r = c->resultsets; r; r = r->next)
        r->connection = 0;

    xfree(c->buf_in);
    xfree(c->addinfo);
    xfree(c->diagset);
    odr_destroy(c->odr_in);
    odr_destroy(c->odr_out);
    ZOOM_options_destroy(c->options);
    ZOOM_connection_remove_tasks(c);
    xfree(c->host_port);
    xfree(c->path);
    xfree(c->proxy);
    xfree(c->charset);
    xfree(c->lang);
    xfree(c->cookie_out);
    xfree(c->cookie_in);
    xfree(c->client_IP);
    xfree(c);
}

void ZOOM_resultset_addref(ZOOM_resultset r)
{
    if (r)
    {
        (r->refcount)++;
        yaz_log(log_details, "%p ZOOM_resultset_addref count=%d",
                r, r->refcount);
    }
}

ZOOM_resultset ZOOM_resultset_create(void)
{
    int i;
    ZOOM_resultset r = (ZOOM_resultset) xmalloc(sizeof(*r));

    initlog();

    yaz_log(log_details, "%p ZOOM_resultset_create", r);
    r->refcount = 1;
    r->size = 0;
    r->odr = odr_createmem(ODR_ENCODE);
    r->piggyback = 1;
    r->setname = 0;
    r->schema = 0;
    r->step = 0;
    for (i = 0; i<RECORD_HASH_SIZE; i++)
        r->record_hash[i] = 0;
    r->r_sort_spec = 0;
    r->query = 0;
    r->connection = 0;
    r->next = 0;
    r->databaseNames = 0;
    r->num_databaseNames = 0;
    return r;
}

ZOOM_API(ZOOM_resultset)
    ZOOM_connection_search_pqf(ZOOM_connection c, const char *q)
{
    ZOOM_resultset r;
    ZOOM_query s = ZOOM_query_create();

    ZOOM_query_prefix(s, q);

    r = ZOOM_connection_search(c, s);
    ZOOM_query_destroy(s);
    return r;
}

ZOOM_API(ZOOM_resultset)
    ZOOM_connection_search(ZOOM_connection c, ZOOM_query q)
{
    ZOOM_resultset r = ZOOM_resultset_create();
    ZOOM_task task;
    const char *cp;
    int start, count;
    const char *syntax, *elementSetName;

    yaz_log(log_api, "%p ZOOM_connection_search set %p query %p", c, r, q);
    r->r_sort_spec = q->sort_spec;
    r->query = q;

    r->options = ZOOM_options_create_with_parent(c->options);

    start = ZOOM_options_get_int(r->options, "start", 0);
    count = ZOOM_options_get_int(r->options, "count", 0);
    {
        /* If "presentChunk" is defined use that; otherwise "step" */
        const char *cp = ZOOM_options_get(r->options, "presentChunk");
        r->step = ZOOM_options_get_int(r->options,
                                       (cp != 0 ? "presentChunk": "step"), 0);
    }
    r->piggyback = ZOOM_options_get_bool(r->options, "piggyback", 1);
    cp = ZOOM_options_get(r->options, "setname");
    if (cp)
        r->setname = xstrdup(cp);
    cp = ZOOM_options_get(r->options, "schema");
    if (cp)
        r->schema = xstrdup(cp);

    r->databaseNames = set_DatabaseNames(c, c->options, &r->num_databaseNames,
                                         r->odr);
    
    r->connection = c;

    r->next = c->resultsets;
    c->resultsets = r;

    if (c->host_port && c->proto == PROTO_HTTP)
    {
        if (!c->cs)
        {
            yaz_log(log_details, "ZOOM_connection_search: no comstack");
            ZOOM_connection_add_task(c, ZOOM_TASK_CONNECT);
        }
        else
        {
            yaz_log(log_details, "ZOOM_connection_search: reconnect");
            c->reconnect_ok = 1;
        }
    }

    task = ZOOM_connection_add_task(c, ZOOM_TASK_SEARCH);
    task->u.search.resultset = r;
    task->u.search.start = start;
    task->u.search.count = count;

    syntax = ZOOM_options_get(r->options, "preferredRecordSyntax"); 
    task->u.search.syntax = syntax ? xstrdup(syntax) : 0;
    elementSetName = ZOOM_options_get(r->options, "elementSetName");
    task->u.search.elementSetName = elementSetName 
        ? xstrdup(elementSetName) : 0;
   
    ZOOM_resultset_addref(r);

    (q->refcount)++;

    if (!c->async)
    {
        while (ZOOM_event(1, &c))
            ;
    }
    return r;
}

/*
 * This is the old result-set sorting API, which is maintained only
 * for the sake of binary compatibility.  There is no reason ever to
 * use this rather than ZOOM_resultset_sort1().
 */
ZOOM_API(void)
    ZOOM_resultset_sort(ZOOM_resultset r,
                        const char *sort_type, const char *sort_spec)
{
    (void) ZOOM_resultset_sort1(r, sort_type, sort_spec);
}

ZOOM_API(int)
    ZOOM_resultset_sort1(ZOOM_resultset r,
                         const char *sort_type, const char *sort_spec)
{
    ZOOM_connection c = r->connection;
    ZOOM_task task;
    ZOOM_query newq;

    newq = ZOOM_query_create();
    if (ZOOM_query_sortby(newq, sort_spec) < 0)
        return -1;

    yaz_log(log_api, "%p ZOOM_resultset_sort r=%p sort_type=%s sort_spec=%s",
            r, r, sort_type, sort_spec);
    if (!c)
        return 0;

    if (c->host_port && c->proto == PROTO_HTTP)
    {
        if (!c->cs)
        {
            yaz_log(log_details, "%p ZOOM_resultset_sort: no comstack", r);
            ZOOM_connection_add_task(c, ZOOM_TASK_CONNECT);
        }
        else
        {
            yaz_log(log_details, "%p ZOOM_resultset_sort: prepare reconnect",
                    r);
            c->reconnect_ok = 1;
        }
    }
    
    ZOOM_resultset_cache_reset(r);
    task = ZOOM_connection_add_task(c, ZOOM_TASK_SORT);
    task->u.sort.resultset = r;
    task->u.sort.q = newq;

    ZOOM_resultset_addref(r);  

    if (!c->async)
    {
        while (ZOOM_event(1, &c))
            ;
    }

    return 0;
}

ZOOM_API(void)
    ZOOM_resultset_cache_reset(ZOOM_resultset r)
{
    int i;
    for (i = 0; i<RECORD_HASH_SIZE; i++)
    {
        ZOOM_record_cache rc;
        for (rc = r->record_hash[i]; rc; rc = rc->next)
        {
            if (rc->rec.wrbuf_marc)
                wrbuf_free(rc->rec.wrbuf_marc, 1);
            if (rc->rec.wrbuf_iconv)
                wrbuf_free(rc->rec.wrbuf_iconv, 1);
            if (rc->rec.wrbuf_opac)
                wrbuf_free(rc->rec.wrbuf_opac, 1);
        }
        r->record_hash[i] = 0;
    }
}

ZOOM_API(void)
    ZOOM_resultset_destroy(ZOOM_resultset r)
{
    if (!r)
        return;
    (r->refcount)--;
    yaz_log(log_details, "%p ZOOM_resultset_destroy r=%p count=%d",
            r, r, r->refcount);
    if (r->refcount == 0)
    {
        ZOOM_resultset_cache_reset(r);

        if (r->connection)
        {
            /* remove ourselves from the resultsets in connection */
            ZOOM_resultset *rp = &r->connection->resultsets;
            while (1)
            {
                assert(*rp);   /* we must be in this list!! */
                if (*rp == r)
                {   /* OK, we're here - take us out of it */
                    *rp = (*rp)->next;
                    break;
                }
                rp = &(*rp)->next;
            }
        }
        ZOOM_query_destroy(r->query);
        ZOOM_options_destroy(r->options);
        odr_destroy(r->odr);
        xfree(r->setname);
        xfree(r->schema);
        xfree(r);
    }
}

ZOOM_API(size_t)
    ZOOM_resultset_size(ZOOM_resultset r)
{
    yaz_log(log_details, "ZOOM_resultset_size r=%p count=%d",
            r, r->size);
    return r->size;
}

static void do_close(ZOOM_connection c)
{
    if (c->cs)
        cs_close(c->cs);
    c->cs = 0;
    c->mask = 0;
    c->state = STATE_IDLE;
}

static int ZOOM_test_reconnect(ZOOM_connection c)
{
    if (!c->reconnect_ok)
        return 0;
    do_close(c);
    c->reconnect_ok = 0;
    c->tasks->running = 0;
    ZOOM_connection_insert_task(c, ZOOM_TASK_CONNECT);
    return 1;
}

static void ZOOM_resultset_retrieve(ZOOM_resultset r,
                                    int force_sync, int start, int count)
{
    ZOOM_task task;
    ZOOM_connection c;
    const char *cp;
    const char *syntax, *elementSetName;

    if (!r)
        return;
    yaz_log(log_details, "%p ZOOM_resultset_retrieve force_sync=%d start=%d"
            " count=%d", r, force_sync, start, count);
    c = r->connection;
    if (!c)
        return;

    if (c->host_port && c->proto == PROTO_HTTP)
    {
        if (!c->cs)
        {
            yaz_log(log_details, "%p ZOOM_resultset_retrieve: no comstack", r);
            ZOOM_connection_add_task(c, ZOOM_TASK_CONNECT);
        }
        else
        {
            yaz_log(log_details, "%p ZOOM_resultset_retrieve: prepare "
                    "reconnect", r);
            c->reconnect_ok = 1;
        }
    }
    task = ZOOM_connection_add_task(c, ZOOM_TASK_RETRIEVE);
    task->u.retrieve.resultset = r;
    task->u.retrieve.start = start;
    task->u.retrieve.count = count;

    syntax = ZOOM_options_get(r->options, "preferredRecordSyntax"); 
    task->u.retrieve.syntax = syntax ? xstrdup(syntax) : 0;
    elementSetName = ZOOM_options_get(r->options, "elementSetName");
    task->u.retrieve.elementSetName = elementSetName 
        ? xstrdup(elementSetName) : 0;

    cp = ZOOM_options_get(r->options, "schema");
    if (cp)
    {
        if (!r->schema || strcmp(r->schema, cp))
        {
            xfree(r->schema);
            r->schema = xstrdup(cp);
        }
    }

    ZOOM_resultset_addref(r);

    if (!r->connection->async || force_sync)
        while (r->connection && ZOOM_event(1, &r->connection))
            ;
}

ZOOM_API(void)
    ZOOM_resultset_records(ZOOM_resultset r, ZOOM_record *recs,
                           size_t start, size_t count)
{
    int force_present = 0;

    if (!r)
        return ;
    yaz_log(log_api, "%p ZOOM_resultset_records r=%p start=%ld count=%ld",
            r, r, (long) start, (long) count);
    if (count && recs)
        force_present = 1;
    ZOOM_resultset_retrieve(r, force_present, start, count);
    if (force_present)
    {
        size_t i;
        for (i = 0; i< count; i++)
            recs[i] = ZOOM_resultset_record_immediate(r, i+start);
    }
}

static void get_cert(ZOOM_connection c)
{
    char *cert_buf;
    int cert_len;
    
    if (cs_get_peer_certificate_x509(c->cs, &cert_buf, &cert_len))
    {
        ZOOM_connection_option_setl(c, "sslPeerCert",
                                    cert_buf, cert_len);
        xfree(cert_buf);
    }
}

static zoom_ret do_connect(ZOOM_connection c)
{
    void *add;
    const char *effective_host;

    if (c->proxy)
        effective_host = c->proxy;
    else
        effective_host = c->host_port;

    yaz_log(log_details, "%p do_connect effective_host=%s", c, effective_host);

    if (c->cs)
        cs_close(c->cs);
    c->cs = cs_create_host(effective_host, 0, &add);

    if (c->cs && c->cs->protocol == PROTO_HTTP)
    {
#if YAZ_HAVE_XML2
        const char *path = 0;

        c->proto = PROTO_HTTP;
        cs_get_host_args(c->host_port, &path);
        xfree(c->path);
        c->path = (char*) xmalloc(strlen(path)+2);
        c->path[0] = '/';
        strcpy(c->path+1, path);
#else
        set_ZOOM_error(c, ZOOM_ERROR_UNSUPPORTED_PROTOCOL, "SRW");
        do_close(c);
        return zoom_complete;
#endif
    }
    if (c->cs)
    {
        int ret = cs_connect(c->cs, add);
        if (ret == 0)
        {
            ZOOM_Event event = ZOOM_Event_create(ZOOM_EVENT_CONNECT);
            ZOOM_connection_put_event(c, event);
            get_cert(c);
            if (c->proto == PROTO_Z3950)
                ZOOM_connection_send_init(c);
            else
            {
                /* no init request for SRW .. */
                assert(c->tasks->which == ZOOM_TASK_CONNECT);
                ZOOM_connection_remove_task(c);
                c->mask = 0;
                ZOOM_connection_exec_task(c);
            }
            c->state = STATE_ESTABLISHED;
            return zoom_pending;
        }
        else if (ret > 0)
        {
            c->state = STATE_CONNECTING; 
            c->mask = ZOOM_SELECT_EXCEPT;
            if (c->cs->io_pending & CS_WANT_WRITE)
                c->mask += ZOOM_SELECT_WRITE;
            if (c->cs->io_pending & CS_WANT_READ)
                c->mask += ZOOM_SELECT_READ;
            return zoom_pending;
        }
    }
    c->state = STATE_IDLE;
    set_ZOOM_error(c, ZOOM_ERROR_CONNECT, c->host_port);
    return zoom_complete;
}

int z3950_connection_socket(ZOOM_connection c)
{
    if (c->cs)
        return cs_fileno(c->cs);
    return -1;
}

int z3950_connection_mask(ZOOM_connection c)
{
    if (c->cs)
        return c->mask;
    return 0;
}

static void otherInfo_attach(ZOOM_connection c, Z_APDU *a, ODR out)
{
    int i;
    for (i = 0; i<200; i++)
    {
        size_t len;
        Z_OtherInformation **oi;
        char buf[80];
        const char *val;
        const char *cp;
        int oidval;

        sprintf(buf, "otherInfo%d", i);
        val = ZOOM_options_get(c->options, buf);
        if (!val)
            break;
        cp = strchr(val, ':');
        if (!cp)
            continue;
        len = cp - val;
        if (len >= sizeof(buf))
            len = sizeof(buf)-1;
        memcpy(buf, val, len);
        buf[len] = '\0';
        oidval = oid_getvalbyname(buf);
        if (oidval == VAL_NONE)
            continue;
        
        yaz_oi_APDU(a, &oi);
        yaz_oi_set_string_oidval(oi, out, oidval, 1, cp+1);
    }
}

static int encode_APDU(ZOOM_connection c, Z_APDU *a, ODR out)
{
    assert(a);
    if (c->cookie_out)
    {
        Z_OtherInformation **oi;
        yaz_oi_APDU(a, &oi);
        yaz_oi_set_string_oidval(oi, out, VAL_COOKIE, 1, c->cookie_out);
    }
    if (c->client_IP)
    {
        Z_OtherInformation **oi;
        yaz_oi_APDU(a, &oi);
        yaz_oi_set_string_oidval(oi, out, VAL_CLIENT_IP, 1, c->client_IP);
    }
    otherInfo_attach(c, a, out);
    if (!z_APDU(out, &a, 0, 0))
    {
        FILE *outf = fopen("/tmp/apdu.txt", "a");
        if (a && outf)
        {
            ODR odr_pr = odr_createmem(ODR_PRINT);
            fprintf(outf, "a=%p\n", a);
            odr_setprint(odr_pr, outf);
            z_APDU(odr_pr, &a, 0, 0);
            odr_destroy(odr_pr);
        }
        yaz_log(log_api, "%p encoding_APDU: encoding failed", c);
        set_ZOOM_error(c, ZOOM_ERROR_ENCODE, 0);
        odr_reset(out);
        return -1;
    }
    yaz_log(log_details, "%p encoding_APDU encoding OK", c);
    return 0;
}

static zoom_ret send_APDU(ZOOM_connection c, Z_APDU *a)
{
    ZOOM_Event event;
    assert(a);
    if (encode_APDU(c, a, c->odr_out))
        return zoom_complete;
    yaz_log(log_details, "%p send APDU type=%d", c, a->which);
    c->buf_out = odr_getbuf(c->odr_out, &c->len_out, 0);
    event = ZOOM_Event_create(ZOOM_EVENT_SEND_APDU);
    ZOOM_connection_put_event(c, event);
    odr_reset(c->odr_out);
    return do_write(c);
}

/* returns 1 if PDU was sent OK (still pending )
   0 if PDU was not sent OK (nothing to wait for) 
*/

static zoom_ret ZOOM_connection_send_init(ZOOM_connection c)
{
    Z_APDU *apdu = zget_APDU(c->odr_out, Z_APDU_initRequest);
    Z_InitRequest *ireq = apdu->u.initRequest;
    Z_IdAuthentication *auth = (Z_IdAuthentication *)
        odr_malloc(c->odr_out, sizeof(*auth));
    const char *auth_groupId = ZOOM_options_get(c->options, "group");
    const char *auth_userId = ZOOM_options_get(c->options, "user");
    const char *auth_password = ZOOM_options_get(c->options, "password");
    char *version;

    /* support the pass for backwards compatibility */
    if (!auth_password)
        auth_password = ZOOM_options_get(c->options, "pass");
        
    ODR_MASK_SET(ireq->options, Z_Options_search);
    ODR_MASK_SET(ireq->options, Z_Options_present);
    ODR_MASK_SET(ireq->options, Z_Options_scan);
    ODR_MASK_SET(ireq->options, Z_Options_sort);
    ODR_MASK_SET(ireq->options, Z_Options_extendedServices);
    ODR_MASK_SET(ireq->options, Z_Options_namedResultSets);
    
    ODR_MASK_SET(ireq->protocolVersion, Z_ProtocolVersion_1);
    ODR_MASK_SET(ireq->protocolVersion, Z_ProtocolVersion_2);
    ODR_MASK_SET(ireq->protocolVersion, Z_ProtocolVersion_3);
    
    /* Index Data's Z39.50 Implementor Id is 81 */
    ireq->implementationId =
        odr_prepend(c->odr_out,
                    ZOOM_options_get(c->options, "implementationId"),
                    odr_prepend(c->odr_out, "81", ireq->implementationId));
    
    ireq->implementationName = 
        odr_prepend(c->odr_out,
                    ZOOM_options_get(c->options, "implementationName"),
                    odr_prepend(c->odr_out, "ZOOM-C",
                                ireq->implementationName));
    
    version = odr_strdup(c->odr_out, "$Revision: 1.103 $");
    if (strlen(version) > 10)   /* check for unexpanded CVS strings */
        version[strlen(version)-2] = '\0';
    ireq->implementationVersion = 
        odr_prepend(c->odr_out,
                    ZOOM_options_get(c->options, "implementationVersion"),
                    odr_prepend(c->odr_out, &version[11],
                                ireq->implementationVersion));
    
    *ireq->maximumRecordSize =
        ZOOM_options_get_int(c->options, "maximumRecordSize", 1024*1024);
    *ireq->preferredMessageSize =
        ZOOM_options_get_int(c->options, "preferredMessageSize", 1024*1024);
    
    if (auth_groupId || auth_password)
    {
        Z_IdPass *pass = (Z_IdPass *) odr_malloc(c->odr_out, sizeof(*pass));
        int i = 0;
        pass->groupId = 0;
        if (auth_groupId && *auth_groupId)
        {
            pass->groupId = (char *)
                odr_malloc(c->odr_out, strlen(auth_groupId)+1);
            strcpy(pass->groupId, auth_groupId);
            i++;
        }
        pass->userId = 0;
        if (auth_userId && *auth_userId)
        {
            pass->userId = (char *)
                odr_malloc(c->odr_out, strlen(auth_userId)+1);
            strcpy(pass->userId, auth_userId);
            i++;
        }
        pass->password = 0;
        if (auth_password && *auth_password)
        {
            pass->password = (char *)
                odr_malloc(c->odr_out, strlen(auth_password)+1);
            strcpy(pass->password, auth_password);
            i++;
        }
        if (i)
        {
            auth->which = Z_IdAuthentication_idPass;
            auth->u.idPass = pass;
            ireq->idAuthentication = auth;
        }
    }
    else if (auth_userId)
    {
        auth->which = Z_IdAuthentication_open;
        auth->u.open = (char *)
            odr_malloc(c->odr_out, strlen(auth_userId)+1);
        strcpy(auth->u.open, auth_userId);
        ireq->idAuthentication = auth;
    }
    if (c->proxy)
        yaz_oi_set_string_oidval(&ireq->otherInfo, c->odr_out,
                                 VAL_PROXY, 1, c->host_port);
    if (c->charset || c->lang)
    {
        Z_OtherInformation **oi;
        Z_OtherInformationUnit *oi_unit;
        
        yaz_oi_APDU(apdu, &oi);
        
        if ((oi_unit = yaz_oi_update(oi, c->odr_out, NULL, 0, 0)))
        {
            ODR_MASK_SET(ireq->options, Z_Options_negotiationModel);
            oi_unit->which = Z_OtherInfo_externallyDefinedInfo;
            oi_unit->information.externallyDefinedInfo =
                yaz_set_proposal_charneg_list(c->odr_out, " ",
                                              c->charset, c->lang, 1);
        }
    }
    assert(apdu);
    return send_APDU(c, apdu);
}

#if YAZ_HAVE_XML2
static zoom_ret send_srw(ZOOM_connection c, Z_SRW_PDU *sr)
{
    Z_GDU *gdu;
    ZOOM_Event event;

    gdu = z_get_HTTP_Request_host_path(c->odr_out, c->host_port, c->path);

    if (c->sru_mode == zoom_sru_get)
    {
        yaz_sru_get_encode(gdu->u.HTTP_Request, sr, c->odr_out, c->charset);
    }
    else if (c->sru_mode == zoom_sru_post)
    {
        yaz_sru_post_encode(gdu->u.HTTP_Request, sr, c->odr_out, c->charset);
    }
    else if (c->sru_mode == zoom_sru_soap)
    {
        yaz_sru_soap_encode(gdu->u.HTTP_Request, sr, c->odr_out, c->charset);
    }
    if (!z_GDU(c->odr_out, &gdu, 0, 0))
        return zoom_complete;
    c->buf_out = odr_getbuf(c->odr_out, &c->len_out, 0);
        
    event = ZOOM_Event_create(ZOOM_EVENT_SEND_APDU);
    ZOOM_connection_put_event(c, event);
    odr_reset(c->odr_out);
    return do_write(c);
}
#endif

#if YAZ_HAVE_XML2
static zoom_ret ZOOM_connection_srw_send_search(ZOOM_connection c)
{
    int i;
    int *start, *count;
    ZOOM_resultset resultset = 0;
    Z_SRW_PDU *sr = 0;
    const char *option_val = 0;

    if (c->error)                  /* don't continue on error */
        return zoom_complete;
    assert(c->tasks);
    switch(c->tasks->which)
    {
    case ZOOM_TASK_SEARCH:
        resultset = c->tasks->u.search.resultset;
        resultset->setname = xstrdup("default");
        ZOOM_options_set(resultset->options, "setname", resultset->setname);
        start = &c->tasks->u.search.start;
        count = &c->tasks->u.search.count;
        break;
    case ZOOM_TASK_RETRIEVE:
        resultset = c->tasks->u.retrieve.resultset;

        start = &c->tasks->u.retrieve.start;
        count = &c->tasks->u.retrieve.count;
        
        if (*start >= resultset->size)
            return zoom_complete;
        if (*start + *count > resultset->size)
            *count = resultset->size - *start;

        for (i = 0; i < *count; i++)
        {
            ZOOM_record rec =
                record_cache_lookup(resultset, i + *start,
                                    c->tasks->u.retrieve.syntax,
                                    c->tasks->u.retrieve.elementSetName);
            if (!rec)
                break;
            else
            {
                ZOOM_Event event = ZOOM_Event_create(ZOOM_EVENT_RECV_RECORD);
                ZOOM_connection_put_event(c, event);
            }
        }
        *start += i;
        *count -= i;

        if (*count == 0)
            return zoom_complete;
        break;
    default:
        return zoom_complete;
    }
    assert(resultset->query);
        
    sr = yaz_srw_get(c->odr_out, Z_SRW_searchRetrieve_request);

    if (resultset->query->z_query->which == Z_Query_type_104
        && resultset->query->z_query->u.type_104->which == Z_External_CQL)
    {
        sr->u.request->query_type = Z_SRW_query_type_cql;
        sr->u.request->query.cql =resultset->query->z_query->u.type_104->u.cql;
    }
    else if (resultset->query->z_query->which == Z_Query_type_1 &&
             resultset->query->z_query->u.type_1)
    {
        sr->u.request->query_type = Z_SRW_query_type_pqf;
        sr->u.request->query.pqf = resultset->query->query_string;
    }
    else
    {
        set_ZOOM_error(c, ZOOM_ERROR_UNSUPPORTED_QUERY, 0);
        return zoom_complete;
    }
    sr->u.request->startRecord = odr_intdup(c->odr_out, *start + 1);
    sr->u.request->maximumRecords = odr_intdup(
        c->odr_out, resultset->step>0 ? resultset->step : *count);
    sr->u.request->recordSchema = resultset->schema;
    
    option_val = ZOOM_resultset_option_get(resultset, "recordPacking");
    if (option_val)
        sr->u.request->recordPacking = odr_strdup(c->odr_out, option_val);

    option_val = ZOOM_resultset_option_get(resultset, "extraArgs");
    if (option_val)
        sr->extra_args = odr_strdup(c->odr_out, option_val);
    return send_srw(c, sr);
}
#else
static zoom_ret ZOOM_connection_srw_send_search(ZOOM_connection c)
{
    return zoom_complete;
}
#endif

static zoom_ret ZOOM_connection_send_search(ZOOM_connection c)
{
    ZOOM_resultset r;
    int lslb, ssub, mspn;
    const char *syntax;
    Z_APDU *apdu = zget_APDU(c->odr_out, Z_APDU_searchRequest);
    Z_SearchRequest *search_req = apdu->u.searchRequest;
    const char *elementSetName;
    const char *smallSetElementSetName;
    const char *mediumSetElementSetName;

    assert(c->tasks);
    assert(c->tasks->which == ZOOM_TASK_SEARCH);

    r = c->tasks->u.search.resultset;

    yaz_log(log_details, "%p ZOOM_connection_send_search set=%p", c, r);

    elementSetName =
        ZOOM_options_get(r->options, "elementSetName");
    smallSetElementSetName  =
        ZOOM_options_get(r->options, "smallSetElementSetName");
    mediumSetElementSetName =
        ZOOM_options_get(r->options, "mediumSetElementSetName");

    if (!smallSetElementSetName)
        smallSetElementSetName = elementSetName;

    if (!mediumSetElementSetName)
        mediumSetElementSetName = elementSetName;

    assert(r);
    assert(r->query);

    /* prepare query for the search request */
    search_req->query = r->query->z_query;
    if (!search_req->query)
    {
        set_ZOOM_error(c, ZOOM_ERROR_INVALID_QUERY, 0);
        return zoom_complete;
    }

    search_req->databaseNames = r->databaseNames;
    search_req->num_databaseNames = r->num_databaseNames;

    /* get syntax (no need to provide unless piggyback is in effect) */
    syntax = c->tasks->u.search.syntax;

    lslb = ZOOM_options_get_int(r->options, "largeSetLowerBound", -1);
    ssub = ZOOM_options_get_int(r->options, "smallSetUpperBound", -1);
    mspn = ZOOM_options_get_int(r->options, "mediumSetPresentNumber", -1);
    if (lslb != -1 && ssub != -1 && mspn != -1)
    {
        /* So're a Z39.50 expert? Let's hope you don't do sort */
        *search_req->largeSetLowerBound = lslb;
        *search_req->smallSetUpperBound = ssub;
        *search_req->mediumSetPresentNumber = mspn;
    }
    else if (c->tasks->u.search.start == 0 && c->tasks->u.search.count > 0
             && r->piggyback && !r->r_sort_spec && !r->schema)
    {
        /* Regular piggyback - do it unless we're going to do sort */
        *search_req->largeSetLowerBound = 2000000000;
        *search_req->smallSetUpperBound = 1;
        *search_req->mediumSetPresentNumber = 
            r->step>0 ? r->step : c->tasks->u.search.count;
    }
    else
    {
        /* non-piggyback. Need not provide elementsets or syntaxes .. */
        smallSetElementSetName = 0;
        mediumSetElementSetName = 0;
        syntax = 0;
    }
    if (smallSetElementSetName && *smallSetElementSetName)
    {
        Z_ElementSetNames *esn = (Z_ElementSetNames *)
            odr_malloc(c->odr_out, sizeof(*esn));
        
        esn->which = Z_ElementSetNames_generic;
        esn->u.generic = odr_strdup(c->odr_out, smallSetElementSetName);
        search_req->smallSetElementSetNames = esn;
    }
    if (mediumSetElementSetName && *mediumSetElementSetName)
    {
        Z_ElementSetNames *esn =(Z_ElementSetNames *)
            odr_malloc(c->odr_out, sizeof(*esn));
        
        esn->which = Z_ElementSetNames_generic;
        esn->u.generic = odr_strdup(c->odr_out, mediumSetElementSetName);
        search_req->mediumSetElementSetNames = esn;
    }
    if (syntax)
        search_req->preferredRecordSyntax =
            yaz_str_to_z3950oid(c->odr_out, CLASS_RECSYN, syntax);
    
    if (!r->setname)
    {
        if (c->support_named_resultsets)
        {
            char setname[14];
            int ord;
            /* find the lowest unused ordinal so that we re-use
               result sets on the server. */
            for (ord = 1; ; ord++)
            {
                ZOOM_resultset rp;
                sprintf(setname, "%d", ord);
                for (rp = c->resultsets; rp; rp = rp->next)
                    if (rp->setname && !strcmp(rp->setname, setname))
                        break;
                if (!rp)
                    break;
            }
            r->setname = xstrdup(setname);
            yaz_log(log_details, "%p ZOOM_connection_send_search: allocating "
                    "set %s", c, r->setname);
        }
        else
        {
            yaz_log(log_details, "%p ZOOM_connection_send_search: using "
                    "default set", c);
            r->setname = xstrdup("default");
        }
        ZOOM_options_set(r->options, "setname", r->setname);
    }
    search_req->resultSetName = odr_strdup(c->odr_out, r->setname);
    return send_APDU(c, apdu);
}

static void response_default_diag(ZOOM_connection c, Z_DefaultDiagFormat *r)
{
    int oclass;
    char *addinfo = 0;

    switch (r->which)
    {
    case Z_DefaultDiagFormat_v2Addinfo:
        addinfo = r->u.v2Addinfo;
        break;
    case Z_DefaultDiagFormat_v3Addinfo:
        addinfo = r->u.v3Addinfo;
        break;
    }
    xfree(c->addinfo);
    c->addinfo = 0;
    set_dset_error(c, *r->condition,
                   yaz_z3950oid_to_str(r->diagnosticSetId, &oclass),
                   addinfo, 0);
}

static void response_diag(ZOOM_connection c, Z_DiagRec *p)
{
    if (p->which != Z_DiagRec_defaultFormat)
        set_ZOOM_error(c, ZOOM_ERROR_DECODE, 0);
    else
        response_default_diag(c, p->u.defaultFormat);
}

ZOOM_API(ZOOM_record)
    ZOOM_record_clone(ZOOM_record srec)
{
    char *buf;
    int size;
    ODR odr_enc;
    ZOOM_record nrec;

    odr_enc = odr_createmem(ODR_ENCODE);
    if (!z_NamePlusRecord(odr_enc, &srec->npr, 0, 0))
        return 0;
    buf = odr_getbuf(odr_enc, &size, 0);
    
    nrec = (ZOOM_record) xmalloc(sizeof(*nrec));
    nrec->odr = odr_createmem(ODR_DECODE);
    nrec->wrbuf_marc = 0;
    nrec->wrbuf_iconv = 0;
    nrec->wrbuf_opac = 0;
    odr_setbuf(nrec->odr, buf, size, 0);
    z_NamePlusRecord(nrec->odr, &nrec->npr, 0, 0);
    
    odr_destroy(odr_enc);
    return nrec;
}

ZOOM_API(ZOOM_record)
    ZOOM_resultset_record_immediate(ZOOM_resultset s,size_t pos)
{
    const char *syntax =
        ZOOM_options_get(s->options, "preferredRecordSyntax"); 
    const char *elementSetName =
        ZOOM_options_get(s->options, "elementSetName");

    return record_cache_lookup(s, pos, syntax, elementSetName);
}

ZOOM_API(ZOOM_record)
    ZOOM_resultset_record(ZOOM_resultset r, size_t pos)
{
    ZOOM_record rec = ZOOM_resultset_record_immediate(r, pos);

    if (!rec)
    {
        /*
         * MIKE: I think force_sync should always be zero, but I don't
         * want to make this change until I get the go-ahead from
         * Adam, in case something depends on the old synchronous
         * behaviour.
         */
        int force_sync = 1;
        if (getenv("ZOOM_RECORD_NO_FORCE_SYNC")) force_sync = 0;
        ZOOM_resultset_retrieve(r, force_sync, pos, 1);
        rec = ZOOM_resultset_record_immediate(r, pos);
    }
    return rec;
}

ZOOM_API(void)
    ZOOM_record_destroy(ZOOM_record rec)
{
    if (!rec)
        return;
    if (rec->wrbuf_marc)
        wrbuf_free(rec->wrbuf_marc, 1);
    if (rec->wrbuf_iconv)
        wrbuf_free(rec->wrbuf_iconv, 1);
    if (rec->wrbuf_opac)
        wrbuf_free(rec->wrbuf_opac, 1);
    odr_destroy(rec->odr);
    xfree(rec);
}

static const char *marc_iconv_return(ZOOM_record rec, int marc_type,
                                     int *len,
                                     const char *buf, int sz,
                                     const char *record_charset)
{
    char to[40];
    char from[40];
    yaz_iconv_t cd = 0;
    yaz_marc_t mt = yaz_marc_create();

    *from = '\0';
    strcpy(to, "UTF-8");
    if (record_charset && *record_charset)
    {
        /* Use "from,to" or just "from" */
        const char *cp = strchr(record_charset, ',');
        int clen = strlen(record_charset);
        if (cp && cp[1])
        {
            strncpy( to, cp+1, sizeof(to)-1);
            to[sizeof(to)-1] = '\0';
            clen = cp - record_charset;
        }
        if (clen > sizeof(from)-1)
            clen = sizeof(from)-1;
        
        if (clen)
            strncpy(from, record_charset, clen);
        from[clen] = '\0';
    }

    if (*from && *to)
    {
        cd = yaz_iconv_open(to, from);
        yaz_marc_iconv(mt, cd);
    }

    yaz_marc_xml(mt, marc_type);
    if (!rec->wrbuf_marc)
        rec->wrbuf_marc = wrbuf_alloc();
    wrbuf_rewind(rec->wrbuf_marc);
    if (yaz_marc_decode_wrbuf(mt, buf, sz, rec->wrbuf_marc) > 0)
    {
        yaz_marc_destroy(mt);
        if (cd)
            yaz_iconv_close(cd);
        if (len)
            *len = wrbuf_len(rec->wrbuf_marc);
        return wrbuf_buf(rec->wrbuf_marc);
    }
    yaz_marc_destroy(mt);
    if (cd)
        yaz_iconv_close(cd);
    return 0;
}

static const char *record_iconv_return(ZOOM_record rec, int *len,
                                       const char *buf, int sz,
                                       const char *record_charset)
{
    char to[40];
    char from[40];
    yaz_iconv_t cd = 0;

    *from = '\0';
    strcpy(to, "UTF-8");
    if (record_charset && *record_charset)
    {
        /* Use "from,to" or just "from" */
        const char *cp = strchr(record_charset, ',');
        int clen = strlen(record_charset);
        if (cp && cp[1])
        {
            strncpy( to, cp+1, sizeof(to)-1);
            to[sizeof(to)-1] = '\0';
            clen = cp - record_charset;
        }
        if (clen > sizeof(from)-1)
            clen = sizeof(from)-1;
        
        if (clen)
            strncpy(from, record_charset, clen);
        from[clen] = '\0';
    }

    if (*from && *to && (cd = yaz_iconv_open(to, from)))
    {
        char outbuf[12];
        size_t inbytesleft = sz;
        const char *inp = buf;
        
        if (!rec->wrbuf_iconv)
            rec->wrbuf_iconv = wrbuf_alloc();

        wrbuf_rewind(rec->wrbuf_iconv);

        while (inbytesleft)
        {
            size_t outbytesleft = sizeof(outbuf);
            char *outp = outbuf;
            size_t r = yaz_iconv(cd, (char**) &inp,
                                 &inbytesleft, 
                                 &outp, &outbytesleft);
            if (r == (size_t) (-1))
            {
                int e = yaz_iconv_error(cd);
                if (e != YAZ_ICONV_E2BIG)
                    break;
            }
            wrbuf_write(rec->wrbuf_iconv, outbuf, outp - outbuf);
        }
        wrbuf_puts(rec->wrbuf_iconv, "");
        buf = wrbuf_buf(rec->wrbuf_iconv);
        sz = wrbuf_len(rec->wrbuf_iconv);
        yaz_iconv_close(cd);
    }
    if (len)
        *len = sz;
    return buf;
}

ZOOM_API(int)
    ZOOM_record_error(ZOOM_record rec, const char **cp,
                      const char **addinfo, const char **diagset)
{
    Z_NamePlusRecord *npr;
    
    if (!rec)
        return 0;
    npr = rec->npr;
    if (npr && npr->which == Z_NamePlusRecord_surrogateDiagnostic)
    {
        Z_DiagRec *diag_rec = npr->u.surrogateDiagnostic;
        int error = YAZ_BIB1_UNSPECIFIED_ERROR;
        const char *add = 0;

        if (diag_rec->which == Z_DiagRec_defaultFormat)
        {
            Z_DefaultDiagFormat *ddf = diag_rec->u.defaultFormat;
            int oclass;
    
            error = *ddf->condition;
            switch (ddf->which)
            {
            case Z_DefaultDiagFormat_v2Addinfo:
                add = ddf->u.v2Addinfo;
                break;
            case Z_DefaultDiagFormat_v3Addinfo:
                add = ddf->u.v3Addinfo;
                break;
            }
            if (diagset)
                *diagset = yaz_z3950oid_to_str(ddf->diagnosticSetId, &oclass);
        }
        else
        {
            if (diagset)
                *diagset = "Bib-1";
        }
        if (addinfo)
            *addinfo = add ? add : "";
        if (cp)
            *cp = diagbib1_str(error);
        return error;
    }
    return 0;
}

ZOOM_API(const char *)
    ZOOM_record_get(ZOOM_record rec, const char *type_spec, int *len)
{
    char type[40];
    char charset[40];
    char xpath[512];
    const char *cp;
    int i;
    Z_NamePlusRecord *npr;
    
    if (len)
        *len = 0; /* default return */
        
    if (!rec)
        return 0;
    npr = rec->npr;
    if (!npr)
        return 0;

    cp = type_spec;
    for (i = 0; cp[i] && i < sizeof(type)-1; i++)
    {
        if (cp[i] == ';' || cp[i] == ' ')
            break;
        type[i] = cp[i];
    }
    type[i] = '\0';
    charset[0] = '\0';
    while (type_spec[i] == ';')
    {
        i++;
        while (type_spec[i] == ' ')
            i++;
        if (!strncmp(type_spec+i, "charset=", 8))
        {
            int j = 0;
            i = i + 8; /* skip charset= */
            for (j = 0; type_spec[i]  && j < sizeof(charset)-1; i++, j++)
            {
                if (type_spec[i] == ';' || type_spec[i] == ' ')
                    break;
                charset[j] = cp[i];
            }
            charset[j] = '\0';
        }
        else if (!strncmp(type_spec+i, "xpath=", 6))
        {
            int j = 0; 
            i = i + 6;
            for (j = 0; type_spec[i] && j < sizeof(xpath)-1; i++, j++)
                xpath[j] = cp[i];
            xpath[j] = '\0';
        } 
        while (type_spec[i] == ' ')
            i++;
    }
    if (!strcmp(type, "database"))
    {
        if (len)
            *len = (npr->databaseName ? strlen(npr->databaseName) : 0);
        return npr->databaseName;
    }
    else if (!strcmp(type, "syntax"))
    {
        const char *desc = 0;   
        if (npr->which == Z_NamePlusRecord_databaseRecord)
        {
            Z_External *r = (Z_External *) npr->u.databaseRecord;
            oident *ent = oid_getentbyoid(r->direct_reference);
            if (ent)
                desc = ent->desc;
        }
        if (!desc)
            desc = "none";
        if (len)
            *len = strlen(desc);
        return desc;
    }
    if (npr->which != Z_NamePlusRecord_databaseRecord)
        return 0;

    /* from now on - we have a database record .. */
    if (!strcmp(type, "render"))
    {
        Z_External *r = (Z_External *) npr->u.databaseRecord;
        oident *ent = oid_getentbyoid(r->direct_reference);

        /* render bibliographic record .. */
        if (r->which == Z_External_OPAC)
        {
            r = r->u.opac->bibliographicRecord;
            if (!r)
                return 0;
            ent = oid_getentbyoid(r->direct_reference);
        }
        if (r->which == Z_External_sutrs)
            return record_iconv_return(rec, len,
                                       (char*) r->u.sutrs->buf,
                                       r->u.sutrs->len,
                                       charset);
        else if (r->which == Z_External_octet)
        {
            const char *ret_buf;
            switch (ent->value)
            {
            case VAL_SOIF:
            case VAL_HTML:
            case VAL_SUTRS:
                break;
            case VAL_TEXT_XML:
            case VAL_APPLICATION_XML:
                break;
            default:
                ret_buf = marc_iconv_return(
                    rec, YAZ_MARC_LINE, len,
                    (const char *) r->u.octet_aligned->buf,
                    r->u.octet_aligned->len,
                    charset);
                if (ret_buf)
                    return ret_buf;
            }
            return record_iconv_return(rec, len,
                                       (const char *) r->u.octet_aligned->buf,
                                       r->u.octet_aligned->len,
                                       charset);
        }
        else if (r->which == Z_External_grs1)
        {
            if (!rec->wrbuf_marc)
                rec->wrbuf_marc = wrbuf_alloc();
            wrbuf_rewind(rec->wrbuf_marc);
            yaz_display_grs1(rec->wrbuf_marc, r->u.grs1, 0);
            return record_iconv_return(rec, len,
                                       wrbuf_buf(rec->wrbuf_marc),
                                       wrbuf_len(rec->wrbuf_marc),
                                       charset);
        }
        return 0;
    }
    else if (!strcmp(type, "xml"))
    {
        Z_External *r = (Z_External *) npr->u.databaseRecord;
        oident *ent = oid_getentbyoid(r->direct_reference);

        /* render bibliographic record .. */
        if (r->which == Z_External_OPAC)
        {
            r = r->u.opac->bibliographicRecord;
            if (!r)
                return 0;
            ent = oid_getentbyoid(r->direct_reference);
        }
        
        if (r->which == Z_External_sutrs)
            return record_iconv_return(rec, len,
                                       (const char *) r->u.sutrs->buf,
                                       r->u.sutrs->len,
                                       charset);
        else if (r->which == Z_External_octet)
        {
            const char *ret_buf;
            int marc_decode_type = YAZ_MARC_MARCXML;

            switch (ent->value)
            {
            case VAL_SOIF:
            case VAL_HTML:
            case VAL_SUTRS:
                break;
            case VAL_TEXT_XML:
            case VAL_APPLICATION_XML:
                break;
            default:
                ret_buf = marc_iconv_return(
                    rec, marc_decode_type, len,
                    (const char *) r->u.octet_aligned->buf,
                    r->u.octet_aligned->len,
                    charset);
                if (ret_buf)
                    return ret_buf;
            }
            return record_iconv_return(rec, len,
                                       (const char *) r->u.octet_aligned->buf,
                                       r->u.octet_aligned->len,
                                       charset);
        }
        else if (r->which == Z_External_grs1)
        {
            if (len) *len = 5;
            return "GRS-1";
        }
        return 0;
    }
    else if (!strcmp(type, "raw"))
    {
        Z_External *r = (Z_External *) npr->u.databaseRecord;
        
        if (r->which == Z_External_sutrs)
        {
            if (len) *len = r->u.sutrs->len;
            return (const char *) r->u.sutrs->buf;
        }
        else if (r->which == Z_External_octet)
        {
            if (len) *len = r->u.octet_aligned->len;
            return (const char *) r->u.octet_aligned->buf;
        }
        else /* grs-1, explain, OPAC, ... */
        {
            if (len) *len = -1;
            return (const char *) npr->u.databaseRecord;
        }
        return 0;
    }
    else if (!strcmp (type, "ext"))
    {
        if (len) *len = -1;
        return (const char *) npr->u.databaseRecord;
    }
    else if (!strcmp (type, "opac"))
             
    {
        Z_External *r = (Z_External *) npr->u.databaseRecord;
        if (r->which == Z_External_OPAC)
        {
            if (!rec->wrbuf_opac)
                rec->wrbuf_opac = wrbuf_alloc();
            wrbuf_rewind(rec->wrbuf_opac);
            yaz_display_OPAC(rec->wrbuf_opac, r->u.opac, 0);
            return record_iconv_return(rec, len,
                                       wrbuf_buf(rec->wrbuf_opac),
                                       wrbuf_len(rec->wrbuf_opac),
                                       charset);
        }
    }
    return 0;
}

static int strcmp_null(const char *v1, const char *v2)
{
    if (!v1 && !v2)
        return 0;
    if (!v1 || !v2)
        return -1;
    return strcmp(v1, v2);
}

static size_t record_hash(int pos)
{
    if (pos < 0)
        pos = 0;
    return pos % RECORD_HASH_SIZE;
}

static void record_cache_add(ZOOM_resultset r, Z_NamePlusRecord *npr, 
                             int pos,
                             const char *syntax, const char *elementSetName)
{
    ZOOM_record_cache rc;
    
    ZOOM_Event event = ZOOM_Event_create(ZOOM_EVENT_RECV_RECORD);
    ZOOM_connection_put_event(r->connection, event);

    for (rc = r->record_hash[record_hash(pos)]; rc; rc = rc->next)
    {
        if (pos == rc->pos)
        {
            if (strcmp_null(r->schema, rc->schema))
                continue;
            if (strcmp_null(elementSetName,rc->elementSetName))
                continue;
            if (strcmp_null(syntax, rc->syntax))
                continue;
            /* not destroying rc->npr (it's handled by nmem )*/
            rc->rec.npr = npr;
            /* keeping wrbuf_marc too */
            return;
        }
    }
    rc = (ZOOM_record_cache) odr_malloc(r->odr, sizeof(*rc));
    rc->rec.npr = npr; 
    rc->rec.odr = 0;
    rc->rec.wrbuf_marc = 0;
    rc->rec.wrbuf_iconv = 0;
    rc->rec.wrbuf_opac = 0;
    if (elementSetName)
        rc->elementSetName = odr_strdup(r->odr, elementSetName);
    else
        rc->elementSetName = 0;

    if (syntax)
        rc->syntax = odr_strdup(r->odr, syntax);
    else
        rc->syntax = 0;

    if (r->schema)
        rc->schema = odr_strdup(r->odr, r->schema);
    else
        rc->schema = 0;

    rc->pos = pos;
    rc->next = r->record_hash[record_hash(pos)];
    r->record_hash[record_hash(pos)] = rc;
}

static ZOOM_record record_cache_lookup(ZOOM_resultset r, int pos,
                                       const char *syntax,
                                       const char *elementSetName)
{
    ZOOM_record_cache rc;
    
    for (rc = r->record_hash[record_hash(pos)]; rc; rc = rc->next)
    {
        if (pos == rc->pos)
        {
            if (strcmp_null(r->schema, rc->schema))
                continue;
            if (strcmp_null(elementSetName,rc->elementSetName))
                continue;
            if (strcmp_null(syntax, rc->syntax))
                continue;
            return &rc->rec;
        }
    }
    return 0;
}
                                             
static void handle_records(ZOOM_connection c, Z_Records *sr,
                           int present_phase)
{
    ZOOM_resultset resultset;
    int *start, *count;
    const char *syntax = 0, *elementSetName = 0;

    if (!c->tasks)
        return ;
    switch (c->tasks->which)
    {
    case ZOOM_TASK_SEARCH:
        resultset = c->tasks->u.search.resultset;
        start = &c->tasks->u.search.start;
        count = &c->tasks->u.search.count;
        syntax = c->tasks->u.search.syntax;
        elementSetName = c->tasks->u.search.elementSetName;
        break;
    case ZOOM_TASK_RETRIEVE:
        resultset = c->tasks->u.retrieve.resultset;        
        start = &c->tasks->u.retrieve.start;
        count = &c->tasks->u.retrieve.count;
        syntax = c->tasks->u.retrieve.syntax;
        elementSetName = c->tasks->u.retrieve.elementSetName;
        break;
    default:
        return;
    }
    if (sr && sr->which == Z_Records_NSD)
        response_default_diag(c, sr->u.nonSurrogateDiagnostic);
    else if (sr && sr->which == Z_Records_multipleNSD)
    {
        if (sr->u.multipleNonSurDiagnostics->num_diagRecs >= 1)
            response_diag(c, sr->u.multipleNonSurDiagnostics->diagRecs[0]);
        else
            set_ZOOM_error(c, ZOOM_ERROR_DECODE, 0);
    }
    else 
    {
        if (*count + *start > resultset->size)
            *count = resultset->size - *start;
        if (*count < 0)
            *count = 0;
        if (sr && sr->which == Z_Records_DBOSD)
        {
            int i;
            NMEM nmem = odr_extract_mem(c->odr_in);
            Z_NamePlusRecordList *p =
                sr->u.databaseOrSurDiagnostics;
            for (i = 0; i<p->num_records; i++)
            {
                record_cache_add(resultset, p->records[i], i + *start,
                                 syntax, elementSetName);
            }
            *count -= i;
            if (*count < 0)
                *count = 0;
            *start += i;
            yaz_log(log_details, 
                    "handle_records resultset=%p start=%d count=%d",
                    resultset, *start, *count);

            /* transfer our response to search_nmem .. we need it later */
            nmem_transfer(resultset->odr->mem, nmem);
            nmem_destroy(nmem);
            if (present_phase && p->num_records == 0)
            {
                /* present response and we didn't get any records! */
                Z_NamePlusRecord *myrec = 
                    zget_surrogateDiagRec(resultset->odr, 0, 14, 0);
                record_cache_add(resultset, myrec, *start,
                                 syntax, elementSetName);
            }
        }
        else if (present_phase)
        {
            /* present response and we didn't get any records! */
            Z_NamePlusRecord *myrec = 
                zget_surrogateDiagRec(resultset->odr, 0, 14, 0);
            record_cache_add(resultset, myrec, *start, syntax, elementSetName);
        }
    }
}

static void handle_present_response(ZOOM_connection c, Z_PresentResponse *pr)
{
    handle_records(c, pr->records, 1);
}

static void handle_queryExpressionTerm(ZOOM_options opt, const char *name,
                                       Z_Term *term)
{
    switch (term->which)
    {
    case Z_Term_general:
        ZOOM_options_setl(opt, name,
                          (const char *)(term->u.general->buf), 
                          term->u.general->len);
        break;
    case Z_Term_characterString:
        ZOOM_options_set(opt, name, term->u.characterString);
        break;
    case Z_Term_numeric:
        ZOOM_options_set_int(opt, name, *term->u.numeric);
        break;
    }
}

static void handle_queryExpression(ZOOM_options opt, const char *name,
                                   Z_QueryExpression *exp)
{
    char opt_name[80];
    
    switch (exp->which)
    {
    case Z_QueryExpression_term:
        if (exp->u.term && exp->u.term->queryTerm)
        {
            sprintf(opt_name, "%s.term", name);
            handle_queryExpressionTerm(opt, opt_name, exp->u.term->queryTerm);
        }
        break;
    case Z_QueryExpression_query:
        break;
    }
}

static void handle_searchResult(ZOOM_connection c, ZOOM_resultset resultset,
                                Z_OtherInformation *o)
{
    int i;
    for (i = 0; o && i < o->num_elements; i++)
    {
        if (o->list[i]->which == Z_OtherInfo_externallyDefinedInfo)
        {
            Z_External *ext = o->list[i]->information.externallyDefinedInfo;
            
            if (ext->which == Z_External_searchResult1)
            {
                int j;
                Z_SearchInfoReport *sr = ext->u.searchResult1;
                
                if (sr->num)
                    ZOOM_options_set_int(
                        resultset->options, "searchresult.size", sr->num);

                for (j = 0; j < sr->num; j++)
                {
                    Z_SearchInfoReport_s *ent =
                        ext->u.searchResult1->elements[j];
                    char pref[80];
                    
                    sprintf(pref, "searchresult.%d", j);

                    if (ent->subqueryId)
                    {
                        char opt_name[80];
                        sprintf(opt_name, "%s.id", pref);
                        ZOOM_options_set(resultset->options, opt_name,
                                         ent->subqueryId);
                    }
                    if (ent->subqueryExpression)
                    {
                        char opt_name[80];
                        sprintf(opt_name, "%s.subquery", pref);
                        handle_queryExpression(resultset->options, opt_name,
                                               ent->subqueryExpression);
                    }
                    if (ent->subqueryInterpretation)
                    {
                        char opt_name[80];
                        sprintf(opt_name, "%s.interpretation", pref);
                        handle_queryExpression(resultset->options, opt_name,
                                               ent->subqueryInterpretation);
                    }
                    if (ent->subqueryRecommendation)
                    {
                        char opt_name[80];
                        sprintf(opt_name, "%s.recommendation", pref);
                        handle_queryExpression(resultset->options, opt_name,
                                               ent->subqueryRecommendation);
                    }
                    if (ent->subqueryCount)
                    {
                        char opt_name[80];
                        sprintf(opt_name, "%s.count", pref);
                        ZOOM_options_set_int(resultset->options, opt_name,
                                             *ent->subqueryCount);
                    }                                             
                }
            }
        }
    }
}

static void handle_search_response(ZOOM_connection c, Z_SearchResponse *sr)
{
    ZOOM_resultset resultset;
    ZOOM_Event event;

    if (!c->tasks || c->tasks->which != ZOOM_TASK_SEARCH)
        return ;

    event = ZOOM_Event_create(ZOOM_EVENT_RECV_SEARCH);
    ZOOM_connection_put_event(c, event);

    resultset = c->tasks->u.search.resultset;

    handle_searchResult(c, resultset, sr->additionalSearchInfo);

    resultset->size = *sr->resultCount;
    handle_records(c, sr->records, 0);
}

static void sort_response(ZOOM_connection c, Z_SortResponse *res)
{
    if (res->diagnostics && res->num_diagnostics > 0)
        response_diag(c, res->diagnostics[0]);
}

static int scan_response(ZOOM_connection c, Z_ScanResponse *res)
{
    NMEM nmem = odr_extract_mem(c->odr_in);
    ZOOM_scanset scan;

    if (!c->tasks || c->tasks->which != ZOOM_TASK_SCAN)
        return 0;
    scan = c->tasks->u.scan.scan;

    if (res->entries && res->entries->nonsurrogateDiagnostics)
        response_diag(c, res->entries->nonsurrogateDiagnostics[0]);
    scan->scan_response = res;
    nmem_transfer(scan->odr->mem, nmem);
    if (res->stepSize)
        ZOOM_options_set_int(scan->options, "stepSize", *res->stepSize);
    if (res->positionOfTerm)
        ZOOM_options_set_int(scan->options, "position", *res->positionOfTerm);
    if (res->scanStatus)
        ZOOM_options_set_int(scan->options, "scanStatus", *res->scanStatus);
    if (res->numberOfEntriesReturned)
        ZOOM_options_set_int(scan->options, "number",
                             *res->numberOfEntriesReturned);
    nmem_destroy(nmem);
    return 1;
}

static zoom_ret send_sort(ZOOM_connection c,
                          ZOOM_resultset resultset)
{
    if (c->error)
        resultset->r_sort_spec = 0;
    if (resultset->r_sort_spec)
    {
        Z_APDU *apdu = zget_APDU(c->odr_out, Z_APDU_sortRequest);
        Z_SortRequest *req = apdu->u.sortRequest;
        
        req->num_inputResultSetNames = 1;
        req->inputResultSetNames = (Z_InternationalString **)
            odr_malloc(c->odr_out, sizeof(*req->inputResultSetNames));
        req->inputResultSetNames[0] =
            odr_strdup(c->odr_out, resultset->setname);
        req->sortedResultSetName = odr_strdup(c->odr_out, resultset->setname);
        req->sortSequence = resultset->r_sort_spec;
        resultset->r_sort_spec = 0;
        return send_APDU(c, apdu);
    }
    return zoom_complete;
}

static zoom_ret send_present(ZOOM_connection c)
{
    Z_APDU *apdu = 0;
    Z_PresentRequest *req = 0;
    int i = 0;
    const char *syntax = 0;
    const char *elementSetName = 0;
    ZOOM_resultset  resultset;
    int *start, *count;

    if (!c->tasks)
    {
        yaz_log(log_details, "%p send_present no tasks", c);
        return zoom_complete;
    }
    
    switch (c->tasks->which)
    {
    case ZOOM_TASK_SEARCH:
        resultset = c->tasks->u.search.resultset;
        start = &c->tasks->u.search.start;
        count = &c->tasks->u.search.count;
        syntax = c->tasks->u.search.syntax;
        elementSetName = c->tasks->u.search.elementSetName;
        break;
    case ZOOM_TASK_RETRIEVE:
        resultset = c->tasks->u.retrieve.resultset;
        start = &c->tasks->u.retrieve.start;
        count = &c->tasks->u.retrieve.count;
        syntax = c->tasks->u.retrieve.syntax;
        elementSetName = c->tasks->u.retrieve.elementSetName;
        break;
    default:
        return zoom_complete;
    }
    yaz_log(log_details, "%p send_present start=%d count=%d",
            c, *start, *count);

    if (*start < 0 || *count < 0 || *start + *count > resultset->size)
    {
        set_dset_error(c, YAZ_BIB1_PRESENT_REQUEST_OUT_OF_RANGE, "Bib-1",
                       "", 0);
    }
    if (c->error)                  /* don't continue on error */
        return zoom_complete;
    yaz_log(log_details, "send_present resultset=%p start=%d count=%d",
            resultset, *start, *count);

    for (i = 0; i < *count; i++)
    {
        ZOOM_record rec =
            record_cache_lookup(resultset, i + *start, syntax, elementSetName);
        if (!rec)
            break;
        else
        {
            ZOOM_Event event = ZOOM_Event_create(ZOOM_EVENT_RECV_RECORD);
            ZOOM_connection_put_event(c, event);
        }
    }
    *start += i;
    *count -= i;

    if (*count == 0)
    {
        yaz_log(log_details, "%p send_present skip=%d no more to fetch", c, i);
        return zoom_complete;
    }

    apdu = zget_APDU(c->odr_out, Z_APDU_presentRequest);
    req = apdu->u.presentRequest;

    if (i)
        yaz_log(log_details, "%p send_present skip=%d", c, i);

    *req->resultSetStartPoint = *start + 1;
    *req->numberOfRecordsRequested = resultset->step>0 ?
        resultset->step : *count;
    if (*req->numberOfRecordsRequested + *start > resultset->size)
        *req->numberOfRecordsRequested = resultset->size - *start;
    assert(*req->numberOfRecordsRequested > 0);

    if (syntax && *syntax)
        req->preferredRecordSyntax =
            yaz_str_to_z3950oid(c->odr_out, CLASS_RECSYN, syntax);

    if (resultset->schema && *resultset->schema)
    {
        Z_RecordComposition *compo = (Z_RecordComposition *)
            odr_malloc(c->odr_out, sizeof(*compo));

        req->recordComposition = compo;
        compo->which = Z_RecordComp_complex;
        compo->u.complex = (Z_CompSpec *)
            odr_malloc(c->odr_out, sizeof(*compo->u.complex));
        compo->u.complex->selectAlternativeSyntax = (bool_t *) 
            odr_malloc(c->odr_out, sizeof(bool_t));
        *compo->u.complex->selectAlternativeSyntax = 0;

        compo->u.complex->generic = (Z_Specification *)
            odr_malloc(c->odr_out, sizeof(*compo->u.complex->generic));

        compo->u.complex->generic->which = Z_Schema_oid;
        compo->u.complex->generic->schema.oid = (Odr_oid *)
            yaz_str_to_z3950oid (c->odr_out, CLASS_SCHEMA, resultset->schema);

        if (!compo->u.complex->generic->schema.oid)
        {
            /* OID wasn't a schema! Try record syntax instead. */

            compo->u.complex->generic->schema.oid = (Odr_oid *)
                yaz_str_to_z3950oid (c->odr_out, CLASS_RECSYN, resultset->schema);
        }
        if (elementSetName && *elementSetName)
        {
            compo->u.complex->generic->elementSpec = (Z_ElementSpec *)
                odr_malloc(c->odr_out, sizeof(Z_ElementSpec));
            compo->u.complex->generic->elementSpec->which =
                Z_ElementSpec_elementSetName;
            compo->u.complex->generic->elementSpec->u.elementSetName =
                odr_strdup(c->odr_out, elementSetName);
        }
        else
            compo->u.complex->generic->elementSpec = 0;
        compo->u.complex->num_dbSpecific = 0;
        compo->u.complex->dbSpecific = 0;
        compo->u.complex->num_recordSyntax = 0;
        compo->u.complex->recordSyntax = 0;
    }
    else if (elementSetName && *elementSetName)
    {
        Z_ElementSetNames *esn = (Z_ElementSetNames *)
            odr_malloc(c->odr_out, sizeof(*esn));
        Z_RecordComposition *compo = (Z_RecordComposition *)
            odr_malloc(c->odr_out, sizeof(*compo));
        
        esn->which = Z_ElementSetNames_generic;
        esn->u.generic = odr_strdup(c->odr_out, elementSetName);
        compo->which = Z_RecordComp_simple;
        compo->u.simple = esn;
        req->recordComposition = compo;
    }
    req->resultSetId = odr_strdup(c->odr_out, resultset->setname);
    return send_APDU(c, apdu);
}

ZOOM_API(ZOOM_scanset)
    ZOOM_connection_scan(ZOOM_connection c, const char *start)
{
    ZOOM_scanset s;
    ZOOM_query q = ZOOM_query_create();

    ZOOM_query_prefix(q, start);

    s = ZOOM_connection_scan1(c, q);
    ZOOM_query_destroy(q);
    return s;

}

ZOOM_API(ZOOM_scanset)
    ZOOM_connection_scan1(ZOOM_connection c, ZOOM_query q)
{
    char *start;
    char *freeme = 0;
    ZOOM_scanset scan = 0;

    /*
     * We need to check the query-type, so we can recognise CQL and
     * CCL and compile them into a form that we can use here.  The
     * ZOOM_query structure has no explicit `type' member, but
     * inspection of the ZOOM_query_prefix() and ZOOM_query_cql()
     * functions shows how the structure is set up in each case.
     */
    if (!q->z_query)
        return 0;
    else if (q->z_query->which == Z_Query_type_1) 
    {
        yaz_log(log_api, "%p ZOOM_connection_scan1 q=%p PQF '%s'",
                c, q, q->query_string);
        start = q->query_string;
    } 
    else if (q->z_query->which == Z_Query_type_104)
    {
        yaz_log(log_api, "%p ZOOM_connection_scan1 q=%p CQL '%s'",
                c, q, q->query_string);
        start = freeme = cql2pqf(c, q->query_string);
        if (start == 0)
            return 0;
    } 
    else
    {
        yaz_log(YLOG_FATAL, "%p ZOOM_connection_scan1 q=%p unknown type '%s'",
                c, q, q->query_string);
        abort();
    }
    
    scan = (ZOOM_scanset) xmalloc(sizeof(*scan));
    scan->connection = c;
    scan->odr = odr_createmem(ODR_DECODE);
    scan->options = ZOOM_options_create_with_parent(c->options);
    scan->refcount = 1;
    scan->scan_response = 0;
    scan->termListAndStartPoint =
        p_query_scan(scan->odr, PROTO_Z3950, &scan->attributeSet, start);
    xfree(freeme);

    scan->databaseNames = set_DatabaseNames(c, c->options,
                                            &scan->num_databaseNames,
                                            scan->odr);
    if (scan->termListAndStartPoint != 0)
    {
        ZOOM_task task = ZOOM_connection_add_task(c, ZOOM_TASK_SCAN);
        task->u.scan.scan = scan;
        
        (scan->refcount)++;
        if (!c->async)
        {
            while (ZOOM_event(1, &c))
                ;
        }
    }
    return scan;
}

ZOOM_API(void)
    ZOOM_scanset_destroy(ZOOM_scanset scan)
{
    if (!scan)
        return;
    (scan->refcount)--;
    if (scan->refcount == 0)
    {
        odr_destroy(scan->odr);
        
        ZOOM_options_destroy(scan->options);
        xfree(scan);
    }
}

static zoom_ret send_package(ZOOM_connection c)
{
    ZOOM_Event event;

    yaz_log(log_details, "%p send_package", c);
    if (!c->tasks)
        return zoom_complete;
    assert (c->tasks->which == ZOOM_TASK_PACKAGE);
    
    event = ZOOM_Event_create(ZOOM_EVENT_SEND_APDU);
    ZOOM_connection_put_event(c, event);
    
    c->buf_out = c->tasks->u.package->buf_out;
    c->len_out = c->tasks->u.package->len_out;

    return do_write(c);
}

static zoom_ret send_scan(ZOOM_connection c)
{
    ZOOM_scanset scan;
    Z_APDU *apdu = zget_APDU(c->odr_out, Z_APDU_scanRequest);
    Z_ScanRequest *req = apdu->u.scanRequest;

    yaz_log(log_details, "%p send_scan", c);
    if (!c->tasks)
        return zoom_complete;
    assert (c->tasks->which == ZOOM_TASK_SCAN);
    scan = c->tasks->u.scan.scan;

    req->termListAndStartPoint = scan->termListAndStartPoint;
    req->attributeSet = scan->attributeSet;

    *req->numberOfTermsRequested =
        ZOOM_options_get_int(scan->options, "number", 10);

    req->preferredPositionInResponse =
        odr_intdup(c->odr_out,
                   ZOOM_options_get_int(scan->options, "position", 1));

    req->stepSize =
        odr_intdup(c->odr_out,
                   ZOOM_options_get_int(scan->options, "stepSize", 0));
    
    req->databaseNames = scan->databaseNames;
    req->num_databaseNames = scan->num_databaseNames;

    return send_APDU(c, apdu);
}

ZOOM_API(size_t)
    ZOOM_scanset_size(ZOOM_scanset scan)
{
    if (!scan || !scan->scan_response || !scan->scan_response->entries)
        return 0;
    return scan->scan_response->entries->num_entries;
}

ZOOM_API(const char *)
    ZOOM_scanset_term(ZOOM_scanset scan, size_t pos,
                      int *occ, int *len)
{
    const char *term = 0;
    size_t noent = ZOOM_scanset_size(scan);
    Z_ScanResponse *res = scan->scan_response;
    
    *len = 0;
    *occ = 0;
    if (pos >= noent)
        return 0;
    if (res->entries->entries[pos]->which == Z_Entry_termInfo)
    {
        Z_TermInfo *t = res->entries->entries[pos]->u.termInfo;
        
        if (t->term->which == Z_Term_general)
        {
            term = (const char *) t->term->u.general->buf;
            *len = t->term->u.general->len;
        }
        *occ = t->globalOccurrences ? *t->globalOccurrences : 0;
    }
    return term;
}

ZOOM_API(const char *)
    ZOOM_scanset_display_term(ZOOM_scanset scan, size_t pos,
                              int *occ, int *len)
{
    const char *term = 0;
    size_t noent = ZOOM_scanset_size(scan);
    Z_ScanResponse *res = scan->scan_response;
    
    *len = 0;
    *occ = 0;
    if (pos >= noent)
        return 0;
    if (res->entries->entries[pos]->which == Z_Entry_termInfo)
    {
        Z_TermInfo *t = res->entries->entries[pos]->u.termInfo;

        if (t->displayTerm)
        {
            term = t->displayTerm;
            *len = strlen(term);
        }
        else if (t->term->which == Z_Term_general)
        {
            term = (const char *) t->term->u.general->buf;
            *len = t->term->u.general->len;
        }
        *occ = t->globalOccurrences ? *t->globalOccurrences : 0;
    }
    return term;
}

ZOOM_API(const char *)
    ZOOM_scanset_option_get(ZOOM_scanset scan, const char *key)
{
    return ZOOM_options_get(scan->options, key);
}

ZOOM_API(void)
    ZOOM_scanset_option_set(ZOOM_scanset scan, const char *key,
                            const char *val)
{
    ZOOM_options_set(scan->options, key, val);
}

static Z_APDU *create_es_package(ZOOM_package p, int type)
{
    const char *str;
    Z_APDU *apdu = zget_APDU(p->odr_out, Z_APDU_extendedServicesRequest);
    Z_ExtendedServicesRequest *req = apdu->u.extendedServicesRequest;
    
    *req->function = Z_ExtendedServicesRequest_create;
    
    str = ZOOM_options_get(p->options, "package-name");
    if (str && *str)
        req->packageName = nmem_strdup(p->odr_out->mem, str);
    
    str = ZOOM_options_get(p->options, "user-id");
    if (str)
        req->userId = nmem_strdup(p->odr_out->mem, str);
    
    req->packageType = yaz_oidval_to_z3950oid(p->odr_out, CLASS_EXTSERV,
                                              type);

    str = ZOOM_options_get(p->options, "function");
    if (str)
    {
        if (!strcmp (str, "create"))
            *req->function = 1;
        if (!strcmp (str, "delete"))
            *req->function = 2;
        if (!strcmp (str, "modify"))
            *req->function = 3;
    }
    return apdu;
}

static const char *ill_array_lookup(void *clientData, const char *idx)
{
    ZOOM_package p = (ZOOM_package) clientData;
    return ZOOM_options_get(p->options, idx+4);
}

static Z_External *encode_ill_request(ZOOM_package p)
{
    ODR out = p->odr_out;
    ILL_Request *req;
    Z_External *r = 0;
    struct ill_get_ctl ctl;
        
    ctl.odr = p->odr_out;
    ctl.clientData = p;
    ctl.f = ill_array_lookup;
        
    req = ill_get_ILLRequest(&ctl, "ill", 0);
        
    if (!ill_Request(out, &req, 0, 0))
    {
        int ill_request_size;
        char *ill_request_buf = odr_getbuf(out, &ill_request_size, 0);
        if (ill_request_buf)
            odr_setbuf(out, ill_request_buf, ill_request_size, 1);
        return 0;
    }
    else
    {
        oident oid;
        int illRequest_size = 0;
        char *illRequest_buf = odr_getbuf(out, &illRequest_size, 0);
                
        oid.proto = PROTO_GENERAL;
        oid.oclass = CLASS_GENERAL;
        oid.value = VAL_ISO_ILL_1;
                
        r = (Z_External *) odr_malloc(out, sizeof(*r));
        r->direct_reference = odr_oiddup(out,oid_getoidbyent(&oid)); 
        r->indirect_reference = 0;
        r->descriptor = 0;
        r->which = Z_External_single;
                
        r->u.single_ASN1_type =
            odr_create_Odr_oct(out,
                               (unsigned char *)illRequest_buf,
                               illRequest_size);
    }
    return r;
}

static Z_ItemOrder *encode_item_order(ZOOM_package p)
{
    Z_ItemOrder *req = (Z_ItemOrder *) odr_malloc(p->odr_out, sizeof(*req));
    const char *str;
    
    req->which = Z_IOItemOrder_esRequest;
    req->u.esRequest = (Z_IORequest *) 
        odr_malloc(p->odr_out,sizeof(Z_IORequest));

    /* to keep part ... */
    req->u.esRequest->toKeep = (Z_IOOriginPartToKeep *)
        odr_malloc(p->odr_out,sizeof(Z_IOOriginPartToKeep));
    req->u.esRequest->toKeep->supplDescription = 0;
    req->u.esRequest->toKeep->contact = (Z_IOContact *)
        odr_malloc(p->odr_out, sizeof(*req->u.esRequest->toKeep->contact));
        
    str = ZOOM_options_get(p->options, "contact-name");
    req->u.esRequest->toKeep->contact->name = str ?
        nmem_strdup(p->odr_out->mem, str) : 0;
        
    str = ZOOM_options_get(p->options, "contact-phone");
    req->u.esRequest->toKeep->contact->phone = str ?
        nmem_strdup(p->odr_out->mem, str) : 0;
        
    str = ZOOM_options_get(p->options, "contact-email");
    req->u.esRequest->toKeep->contact->email = str ?
        nmem_strdup(p->odr_out->mem, str) : 0;
        
    req->u.esRequest->toKeep->addlBilling = 0;
        
    /* not to keep part ... */
    req->u.esRequest->notToKeep = (Z_IOOriginPartNotToKeep *)
        odr_malloc(p->odr_out,sizeof(Z_IOOriginPartNotToKeep));
        
    str = ZOOM_options_get(p->options, "itemorder-setname");
    if (!str)
        str = "default";

    if (!*str) 
        req->u.esRequest->notToKeep->resultSetItem = 0;
    else
    {
        req->u.esRequest->notToKeep->resultSetItem = (Z_IOResultSetItem *)
            odr_malloc(p->odr_out, sizeof(Z_IOResultSetItem));

        req->u.esRequest->notToKeep->resultSetItem->resultSetId =
            nmem_strdup(p->odr_out->mem, str);
        req->u.esRequest->notToKeep->resultSetItem->item =
            (int *) odr_malloc(p->odr_out, sizeof(int));
        
        str = ZOOM_options_get(p->options, "itemorder-item");
        *req->u.esRequest->notToKeep->resultSetItem->item =
            (str ? atoi(str) : 1);
    }
    req->u.esRequest->notToKeep->itemRequest = encode_ill_request(p);
    
    return req;
}

Z_APDU *create_admin_package(ZOOM_package p, int type, 
                             Z_ESAdminOriginPartToKeep **toKeepP,
                             Z_ESAdminOriginPartNotToKeep **notToKeepP)
{
    Z_APDU *apdu = create_es_package(p, VAL_ADMINSERVICE);
    if (apdu)
    {
        Z_ESAdminOriginPartToKeep  *toKeep;
        Z_ESAdminOriginPartNotToKeep  *notToKeep;
        Z_External *r = (Z_External *) odr_malloc(p->odr_out, sizeof(*r));
        const char *first_db = "Default";
        int num_db;
        char **db = set_DatabaseNames(p->connection, p->options, &num_db,
                                      p->odr_out);
        if (num_db > 0)
            first_db = db[0];
            
        r->direct_reference =
            yaz_oidval_to_z3950oid(p->odr_out, CLASS_EXTSERV,
                                   VAL_ADMINSERVICE);
        r->descriptor = 0;
        r->indirect_reference = 0;
        r->which = Z_External_ESAdmin;
        
        r->u.adminService = (Z_Admin *)
            odr_malloc(p->odr_out, sizeof(*r->u.adminService));
        r->u.adminService->which = Z_Admin_esRequest;
        r->u.adminService->u.esRequest = (Z_AdminEsRequest *)
            odr_malloc(p->odr_out, sizeof(*r->u.adminService->u.esRequest));
        
        toKeep = r->u.adminService->u.esRequest->toKeep =
            (Z_ESAdminOriginPartToKeep *) 
            odr_malloc(p->odr_out, sizeof(*r->u.adminService->u.esRequest->toKeep));
        toKeep->which = type;
        toKeep->databaseName = odr_strdup(p->odr_out, first_db);
        toKeep->u.create = odr_nullval();
        apdu->u.extendedServicesRequest->taskSpecificParameters = r;
        
        r->u.adminService->u.esRequest->notToKeep = notToKeep =
            (Z_ESAdminOriginPartNotToKeep *)
            odr_malloc(p->odr_out,
                       sizeof(*r->u.adminService->u.esRequest->notToKeep));
        notToKeep->which = Z_ESAdminOriginPartNotToKeep_recordsWillFollow;
        notToKeep->u.recordsWillFollow = odr_nullval();
        if (toKeepP)
            *toKeepP = toKeep;
        if (notToKeepP)
            *notToKeepP = notToKeep;
    }
    return apdu;
}

static Z_APDU *create_xmlupdate_package(ZOOM_package p)
{
    Z_APDU *apdu = create_es_package(p, VAL_XMLES);
    Z_ExtendedServicesRequest *req = apdu->u.extendedServicesRequest;
    Z_External *ext = (Z_External *) odr_malloc(p->odr_out, sizeof(*ext));
    const char *doc = ZOOM_options_get(p->options, "doc");

    if (!doc)
        doc = "";

    req->taskSpecificParameters = ext;
    ext->direct_reference = req->packageType;
    ext->descriptor = 0;
    ext->indirect_reference = 0;
    
    ext->which = Z_External_octet;
    ext->u.single_ASN1_type =
        odr_create_Odr_oct(p->odr_out, (const unsigned char *) doc,
                           strlen(doc));
    return apdu;
}

static Z_APDU *create_update_package(ZOOM_package p)
{
    Z_APDU *apdu = 0;
    const char *first_db = "Default";
    int num_db;
    char **db = set_DatabaseNames(p->connection, p->options, &num_db, p->odr_out);
    const char *action = ZOOM_options_get(p->options, "action");
    const char *recordIdOpaque = ZOOM_options_get(p->options, "recordIdOpaque");
    const char *recordIdNumber = ZOOM_options_get(p->options, "recordIdNumber");
    const char *record_buf = ZOOM_options_get(p->options, "record");
    const char *syntax_str = ZOOM_options_get(p->options, "syntax");
    int syntax_oid = VAL_NONE;
    int action_no = -1;
    
    if (syntax_str)
        syntax_oid = oid_getvalbyname(syntax_str);
    if (!record_buf)
    {
        record_buf = "void";
        syntax_oid = VAL_SUTRS;
    }
    if (syntax_oid == VAL_NONE)
        syntax_oid = VAL_TEXT_XML;
    
    if (num_db > 0)
        first_db = db[0];
    
    if (!action)
        action = "specialUpdate";
    
    if (!strcmp(action, "recordInsert"))
        action_no = Z_IUOriginPartToKeep_recordInsert;
    else if (!strcmp(action, "recordReplace"))
        action_no = Z_IUOriginPartToKeep_recordReplace;
    else if (!strcmp(action, "recordDelete"))
        action_no = Z_IUOriginPartToKeep_recordDelete;
    else if (!strcmp(action, "elementUpdate"))
        action_no = Z_IUOriginPartToKeep_elementUpdate;
    else if (!strcmp(action, "specialUpdate"))
        action_no = Z_IUOriginPartToKeep_specialUpdate;
    else
        return 0;

    apdu = create_es_package(p, VAL_DBUPDATE);
    if (apdu)
    {
        Z_IUOriginPartToKeep *toKeep;
        Z_IUSuppliedRecords *notToKeep;
        Z_External *r = (Z_External *)
            odr_malloc(p->odr_out, sizeof(*r));
        
        apdu->u.extendedServicesRequest->taskSpecificParameters = r;
        
        r->direct_reference =
            yaz_oidval_to_z3950oid(p->odr_out, CLASS_EXTSERV,
                                   VAL_DBUPDATE);
        r->descriptor = 0;
        r->which = Z_External_update;
        r->indirect_reference = 0;
        r->u.update = (Z_IUUpdate *)
            odr_malloc(p->odr_out, sizeof(*r->u.update));
        
        r->u.update->which = Z_IUUpdate_esRequest;
        r->u.update->u.esRequest = (Z_IUUpdateEsRequest *)
            odr_malloc(p->odr_out, sizeof(*r->u.update->u.esRequest));
        toKeep = r->u.update->u.esRequest->toKeep = 
            (Z_IUOriginPartToKeep *)
            odr_malloc(p->odr_out, sizeof(*toKeep));
        
        toKeep->databaseName = odr_strdup(p->odr_out, first_db);
        toKeep->schema = 0;
        toKeep->elementSetName = 0;
        toKeep->actionQualifier = 0;
        toKeep->action = odr_intdup(p->odr_out, action_no);
        
        notToKeep = r->u.update->u.esRequest->notToKeep = 
            (Z_IUSuppliedRecords *)
            odr_malloc(p->odr_out, sizeof(*notToKeep));
        notToKeep->num = 1;
        notToKeep->elements = (Z_IUSuppliedRecords_elem **)
            odr_malloc(p->odr_out, sizeof(*notToKeep->elements));
        notToKeep->elements[0] = (Z_IUSuppliedRecords_elem *)
            odr_malloc(p->odr_out, sizeof(**notToKeep->elements));
        notToKeep->elements[0]->which = Z_IUSuppliedRecords_elem_opaque;
        if (recordIdOpaque)
        {
            notToKeep->elements[0]->u.opaque = 
                odr_create_Odr_oct(p->odr_out,
                                   (const unsigned char *) recordIdOpaque,
                                   strlen(recordIdOpaque));
        }
        else if (recordIdNumber)
        {
            notToKeep->elements[0]->which = Z_IUSuppliedRecords_elem_number;
            
            notToKeep->elements[0]->u.number =
                odr_intdup(p->odr_out, atoi(recordIdNumber));
        }
        else
            notToKeep->elements[0]->u.opaque = 0;
        notToKeep->elements[0]->supplementalId = 0;
        notToKeep->elements[0]->correlationInfo = 0;
        notToKeep->elements[0]->record =
            z_ext_record(p->odr_out, syntax_oid,
                         record_buf, strlen(record_buf));
    }
    if (0 && apdu)
    {
        ODR print = odr_createmem(ODR_PRINT);

        z_APDU(print, &apdu, 0, 0);
        odr_destroy(print);
    }
    return apdu;
}

ZOOM_API(void)
    ZOOM_package_send(ZOOM_package p, const char *type)
{
    Z_APDU *apdu = 0;
    ZOOM_connection c;
    if (!p)
        return;
    c = p->connection;
    odr_reset(p->odr_out);
    xfree(p->buf_out);
    p->buf_out = 0;
    if (!strcmp(type, "itemorder"))
    {
        apdu = create_es_package(p, VAL_ITEMORDER);
        if (apdu)
        {
            Z_External *r = (Z_External *) odr_malloc(p->odr_out, sizeof(*r));
            
            r->direct_reference =
                yaz_oidval_to_z3950oid(p->odr_out, CLASS_EXTSERV,
                                       VAL_ITEMORDER);
            r->descriptor = 0;
            r->which = Z_External_itemOrder;
            r->indirect_reference = 0;
            r->u.itemOrder = encode_item_order(p);

            apdu->u.extendedServicesRequest->taskSpecificParameters = r;
        }
    }
    else if (!strcmp(type, "create"))  /* create database */
    {
        apdu = create_admin_package(p, Z_ESAdminOriginPartToKeep_create,
                                    0, 0);
    }   
    else if (!strcmp(type, "drop"))  /* drop database */
    {
        apdu = create_admin_package(p, Z_ESAdminOriginPartToKeep_drop,
                                    0, 0);
    }
    else if (!strcmp(type, "commit"))  /* commit changes */
    {
        apdu = create_admin_package(p, Z_ESAdminOriginPartToKeep_commit,
                                    0, 0);
    }
    else if (!strcmp(type, "update")) /* update record(s) */
    {
        apdu = create_update_package(p);
    }
    else if (!strcmp(type, "xmlupdate"))
    {
        apdu = create_xmlupdate_package(p);
    }
    if (apdu)
    {
        if (encode_APDU(p->connection, apdu, p->odr_out) == 0)
        {
            char *buf;

            ZOOM_task task = ZOOM_connection_add_task(c, ZOOM_TASK_PACKAGE);
            task->u.package = p;
            buf = odr_getbuf(p->odr_out, &p->len_out, 0);
            p->buf_out = (char *) xmalloc(p->len_out);
            memcpy(p->buf_out, buf, p->len_out);
            
            (p->refcount)++;
            if (!c->async)
            {
                while (ZOOM_event(1, &c))
                    ;
            }
        }
    }
}

ZOOM_API(ZOOM_package)
    ZOOM_connection_package(ZOOM_connection c, ZOOM_options options)
{
    ZOOM_package p = (ZOOM_package) xmalloc(sizeof(*p));

    p->connection = c;
    p->odr_out = odr_createmem(ODR_ENCODE);
    p->options = ZOOM_options_create_with_parent2(options, c->options);
    p->refcount = 1;
    p->buf_out = 0;
    p->len_out = 0;
    return p;
}

ZOOM_API(void)
    ZOOM_package_destroy(ZOOM_package p)
{
    if (!p)
        return;
    (p->refcount)--;
    if (p->refcount == 0)
    {
        odr_destroy(p->odr_out);
        xfree(p->buf_out);
        
        ZOOM_options_destroy(p->options);
        xfree(p);
    }
}

ZOOM_API(const char *)
    ZOOM_package_option_get(ZOOM_package p, const char *key)
{
    return ZOOM_options_get(p->options, key);
}


ZOOM_API(void)
    ZOOM_package_option_set(ZOOM_package p, const char *key,
                            const char *val)
{
    ZOOM_options_set(p->options, key, val);
}

static int ZOOM_connection_exec_task(ZOOM_connection c)
{
    ZOOM_task task = c->tasks;
    zoom_ret ret = zoom_complete;

    if (!task)
        return 0;
    yaz_log(log_details, "%p ZOOM_connection_exec_task type=%d run=%d",
            c, task->which, task->running);
    if (c->error != ZOOM_ERROR_NONE)
    {
        yaz_log(log_details, "%p ZOOM_connection_exec_task "
                "removing tasks because of error = %d", c, c->error);
        ZOOM_connection_remove_tasks(c);
        return 0;
    }
    if (task->running)
    {
        yaz_log(log_details, "%p ZOOM_connection_exec_task "
                "task already running", c);
        return 0;
    }
    task->running = 1;
    ret = zoom_complete;
    if (c->cs || task->which == ZOOM_TASK_CONNECT)
    {
        switch (task->which)
        {
        case ZOOM_TASK_SEARCH:
            if (c->proto == PROTO_HTTP)
                ret = ZOOM_connection_srw_send_search(c);
            else
                ret = ZOOM_connection_send_search(c);
            break;
        case ZOOM_TASK_RETRIEVE:
            if (c->proto == PROTO_HTTP)
                ret = ZOOM_connection_srw_send_search(c);
            else
                ret = send_present(c);
            break;
        case ZOOM_TASK_CONNECT:
            ret = do_connect(c);
            break;
        case ZOOM_TASK_SCAN:
            ret = send_scan(c);
            break;
        case ZOOM_TASK_PACKAGE:
            ret = send_package(c);
            break;
        case ZOOM_TASK_SORT:
            c->tasks->u.sort.resultset->r_sort_spec = 
                c->tasks->u.sort.q->sort_spec;
            ret = send_sort(c, c->tasks->u.sort.resultset);
            break;
        }
    }
    else
    {
        yaz_log(log_details, "%p ZOOM_connection_exec_task "
                "remove tasks because no connection exist", c);
        ZOOM_connection_remove_tasks(c);
    }
    if (ret == zoom_complete)
    {
        yaz_log(log_details, "%p ZOOM_connection_exec_task "
                "task removed (complete)", c);
        ZOOM_connection_remove_task(c);
        return 0;
    }
    yaz_log(log_details, "%p ZOOM_connection_exec_task "
            "task pending", c);
    return 1;
}

static zoom_ret send_sort_present(ZOOM_connection c)
{
    zoom_ret r = zoom_complete;

    if (c->tasks && c->tasks->which == ZOOM_TASK_SEARCH)
        r = send_sort(c, c->tasks->u.search.resultset);
    if (r == zoom_complete)
        r = send_present(c);
    return r;
}

static int es_response(ZOOM_connection c,
                       Z_ExtendedServicesResponse *res)
{
    if (!c->tasks || c->tasks->which != ZOOM_TASK_PACKAGE)
        return 0;
    if (res->diagnostics && res->num_diagnostics > 0)
        response_diag(c, res->diagnostics[0]);
    if (res->taskPackage &&
        res->taskPackage->which == Z_External_extendedService)
    {
        Z_TaskPackage *taskPackage = res->taskPackage->u.extendedService;
        Odr_oct *id = taskPackage->targetReference;
        
        if (id)
            ZOOM_options_setl(c->tasks->u.package->options,
                              "targetReference", (char*) id->buf, id->len);
    }
    if (res->taskPackage && 
        res->taskPackage->which == Z_External_octet)
    {
        Odr_oct *doc = res->taskPackage->u.octet_aligned;
        ZOOM_options_setl(c->tasks->u.package->options,
                          "xmlUpdateDoc", (char*) doc->buf, doc->len);
    }
    return 1;
}

static void interpret_init_diag(ZOOM_connection c,
                                Z_DiagnosticFormat *diag)
{
    if (diag->num > 0)
    {
        Z_DiagnosticFormat_s *ds = diag->elements[0];
        if (ds->which == Z_DiagnosticFormat_s_defaultDiagRec)
            response_default_diag(c, ds->u.defaultDiagRec);
    }
}


static void interpret_otherinformation_field(ZOOM_connection c,
                                             Z_OtherInformation *ui)
{
    int i;
    for (i = 0; i < ui->num_elements; i++)
    {
        Z_OtherInformationUnit *unit = ui->list[i];
        if (unit->which == Z_OtherInfo_externallyDefinedInfo &&
            unit->information.externallyDefinedInfo &&
            unit->information.externallyDefinedInfo->which ==
            Z_External_diag1) 
        {
            interpret_init_diag(c, unit->information.externallyDefinedInfo->u.diag1);
        } 
    }
}


static void set_init_option(const char *name, void *clientData) {
    ZOOM_connection c = clientData;
    char buf[80];

    sprintf(buf, "init_opt_%.70s", name);
    ZOOM_connection_option_set(c, buf, "1");
}


static void recv_apdu(ZOOM_connection c, Z_APDU *apdu)
{
    Z_InitResponse *initrs;
    
    c->mask = 0;
    yaz_log(log_details, "%p recv_apdu apdu->which=%d", c, apdu->which);
    switch(apdu->which)
    {
    case Z_APDU_initResponse:
        yaz_log(log_api, "%p recv_apd: Received Init response", c);
        initrs = apdu->u.initResponse;
        ZOOM_connection_option_set(c, "serverImplementationId",
                                   initrs->implementationId ?
                                   initrs->implementationId : "");
        ZOOM_connection_option_set(c, "serverImplementationName",
                                   initrs->implementationName ?
                                   initrs->implementationName : "");
        ZOOM_connection_option_set(c, "serverImplementationVersion",
                                   initrs->implementationVersion ?
                                   initrs->implementationVersion : "");
        /* Set the three old options too, for old applications */
        ZOOM_connection_option_set(c, "targetImplementationId",
                                   initrs->implementationId ?
                                   initrs->implementationId : "");
        ZOOM_connection_option_set(c, "targetImplementationName",
                                   initrs->implementationName ?
                                   initrs->implementationName : "");
        ZOOM_connection_option_set(c, "targetImplementationVersion",
                                   initrs->implementationVersion ?
                                   initrs->implementationVersion : "");

        /* Make initrs->options available as ZOOM-level options */
        yaz_init_opt_decode(initrs->options, set_init_option, (void*) c);

        if (!*initrs->result)
        {
            Z_External *uif = initrs->userInformationField;

            set_ZOOM_error(c, ZOOM_ERROR_INIT, 0); /* default error */

            if (uif && uif->which == Z_External_userInfo1)
                interpret_otherinformation_field(c, uif->u.userInfo1);
        }
        else
        {
            char *cookie =
                yaz_oi_get_string_oidval(&apdu->u.initResponse->otherInfo,
                                         VAL_COOKIE, 1, 0);
            xfree(c->cookie_in);
            c->cookie_in = 0;
            if (cookie)
                c->cookie_in = xstrdup(cookie);
            if (ODR_MASK_GET(initrs->options, Z_Options_namedResultSets) &&
                ODR_MASK_GET(initrs->protocolVersion, Z_ProtocolVersion_3))
                c->support_named_resultsets = 1;
            if (c->tasks)
            {
                assert(c->tasks->which == ZOOM_TASK_CONNECT);
                ZOOM_connection_remove_task(c);
            }
            ZOOM_connection_exec_task(c);
        }
        if (ODR_MASK_GET(initrs->options, Z_Options_negotiationModel))
        {
            NMEM tmpmem = nmem_create();
            Z_CharSetandLanguageNegotiation *p =
                yaz_get_charneg_record(initrs->otherInfo);
            
            if (p)
            {
                char *charset = NULL, *lang = NULL;
                int sel;
                
                yaz_get_response_charneg(tmpmem, p, &charset, &lang, &sel);
                yaz_log(log_details, "%p recv_apdu target accepted: "
                        "charset %s, language %s, select %d",
                        c,
                        charset ? charset : "none", lang ? lang : "none", sel);
                if (charset)
                    ZOOM_connection_option_set(c, "negotiation-charset",
                                               charset);
                if (lang)
                    ZOOM_connection_option_set(c, "negotiation-lang",
                                               lang);

                ZOOM_connection_option_set(
                    c,  "negotiation-charset-in-effect-for-records",
                    (sel != 0) ? "1" : "0");
                nmem_destroy(tmpmem);
            }
        }       
        break;
    case Z_APDU_searchResponse:
        yaz_log(log_api, "%p recv_apdu Search response", c);
        handle_search_response(c, apdu->u.searchResponse);
        if (send_sort_present(c) == zoom_complete)
            ZOOM_connection_remove_task(c);
        break;
    case Z_APDU_presentResponse:
        yaz_log(log_api, "%p recv_apdu Present response", c);
        handle_present_response(c, apdu->u.presentResponse);
        if (send_present(c) == zoom_complete)
            ZOOM_connection_remove_task(c);
        break;
    case Z_APDU_sortResponse:
        yaz_log(log_api, "%p recv_apdu Sort response", c);
        sort_response(c, apdu->u.sortResponse);
        if (send_present(c) == zoom_complete)
            ZOOM_connection_remove_task(c);
        break;
    case Z_APDU_scanResponse:
        yaz_log(log_api, "%p recv_apdu Scan response", c);
        scan_response(c, apdu->u.scanResponse);
        ZOOM_connection_remove_task(c);
        break;
    case Z_APDU_extendedServicesResponse:
        yaz_log(log_api, "%p recv_apdu Extended Services response", c);
        es_response(c, apdu->u.extendedServicesResponse);
        ZOOM_connection_remove_task(c);
        break;
    case Z_APDU_close:
        yaz_log(log_api, "%p recv_apdu Close PDU", c);
        if (!ZOOM_test_reconnect(c))
        {
            set_ZOOM_error(c, ZOOM_ERROR_CONNECTION_LOST, c->host_port);
            do_close(c);
        }
        break;
    default:
        yaz_log(log_api, "%p Received unknown PDU", c);
        set_ZOOM_error(c, ZOOM_ERROR_DECODE, 0);
        do_close(c);
    }
}

#if YAZ_HAVE_XML2
static void handle_srw_response(ZOOM_connection c,
                                Z_SRW_searchRetrieveResponse *res)
{
    ZOOM_resultset resultset = 0;
    int i;
    NMEM nmem;
    ZOOM_Event event;
    int *start;
    const char *syntax, *elementSetName;

    if (!c->tasks)
        return;

    switch(c->tasks->which)
    {
    case ZOOM_TASK_SEARCH:
        resultset = c->tasks->u.search.resultset;
        start = &c->tasks->u.search.start;
        syntax = c->tasks->u.search.syntax;
        elementSetName = c->tasks->u.search.elementSetName;        
        break;
    case ZOOM_TASK_RETRIEVE:
        resultset = c->tasks->u.retrieve.resultset;
        start = &c->tasks->u.retrieve.start;
        syntax = c->tasks->u.retrieve.syntax;
        elementSetName = c->tasks->u.retrieve.elementSetName;
        break;
    default:
        return;
    }
    event = ZOOM_Event_create(ZOOM_EVENT_RECV_SEARCH);
    ZOOM_connection_put_event(c, event);

    resultset->size = 0;

    yaz_log(log_details, "%p handle_srw_response got SRW response OK", c);
    
    if (res->numberOfRecords)
        resultset->size = *res->numberOfRecords;

    for (i = 0; i<res->num_records; i++)
    {
        int pos;

        Z_NamePlusRecord *npr = (Z_NamePlusRecord *)
            odr_malloc(c->odr_in, sizeof(Z_NamePlusRecord));

        if (res->records[i].recordPosition && 
            *res->records[i].recordPosition > 0)
            pos = *res->records[i].recordPosition - 1;
        else
            pos = *start + i;
        
        npr->databaseName = 0;
        npr->which = Z_NamePlusRecord_databaseRecord;
        npr->u.databaseRecord = (Z_External *)
            odr_malloc(c->odr_in, sizeof(Z_External));
        npr->u.databaseRecord->descriptor = 0;
        npr->u.databaseRecord->direct_reference =
            yaz_oidval_to_z3950oid(c->odr_in, CLASS_RECSYN, VAL_TEXT_XML);
        npr->u.databaseRecord->which = Z_External_octet;

        npr->u.databaseRecord->u.octet_aligned = (Odr_oct *)
            odr_malloc(c->odr_in, sizeof(Odr_oct));
        npr->u.databaseRecord->u.octet_aligned->buf = (unsigned char*)
            res->records[i].recordData_buf;
        npr->u.databaseRecord->u.octet_aligned->len = 
            npr->u.databaseRecord->u.octet_aligned->size = 
            res->records[i].recordData_len;
        record_cache_add(resultset, npr, pos, syntax, elementSetName);
    }
    if (res->num_diagnostics > 0)
    {
        const char *uri = res->diagnostics[0].uri;
        if (uri)
        {
            int code = 0;       
            const char *cp;
            if ((cp = strrchr(uri, '/')))
                code = atoi(cp+1);
            set_dset_error(c, code, uri,
                           res->diagnostics[0].details, 0);
        }
    }
    nmem = odr_extract_mem(c->odr_in);
    nmem_transfer(resultset->odr->mem, nmem);
    nmem_destroy(nmem);
}
#endif

#if YAZ_HAVE_XML2
static void handle_http(ZOOM_connection c, Z_HTTP_Response *hres)
{
    int ret = -1;
    const char *content_type = z_HTTP_header_lookup(hres->headers,
                                                    "Content-Type");
    const char *connection_head = z_HTTP_header_lookup(hres->headers,
                                                       "Connection");
    c->mask = 0;
    yaz_log(log_details, "%p handle_http", c);

    if (content_type && !yaz_strcmp_del("text/xml", content_type, "; "))
    {
        Z_SOAP *soap_package = 0;
        ODR o = c->odr_in;
        Z_SOAP_Handler soap_handlers[2] = {
            {YAZ_XMLNS_SRU_v1_1, 0, (Z_SOAP_fun) yaz_srw_codec},
            {0, 0, 0}
        };
        ret = z_soap_codec(o, &soap_package,
                           &hres->content_buf, &hres->content_len,
                           soap_handlers);
        if (!ret && soap_package->which == Z_SOAP_generic &&
            soap_package->u.generic->no == 0)
        {
            Z_SRW_PDU *sr = (Z_SRW_PDU*) soap_package->u.generic->p;
            if (sr->which == Z_SRW_searchRetrieve_response)
                handle_srw_response(c, sr->u.response);
            else
                ret = -1;
        }
        else if (!ret && (soap_package->which == Z_SOAP_fault
                          || soap_package->which == Z_SOAP_error))
        {
            set_HTTP_error(c, hres->code,
                           soap_package->u.fault->fault_code,
                           soap_package->u.fault->fault_string);
        }
        else
            ret = -1;
    }
    if (ret)
    {
        if (hres->code != 200)
            set_HTTP_error(c, hres->code, 0, 0);
        else
            set_ZOOM_error(c, ZOOM_ERROR_DECODE, 0);
        do_close(c);
    }
    ZOOM_connection_remove_task(c);
    if (!strcmp(hres->version, "1.0"))
    {
        /* HTTP 1.0: only if Keep-Alive we stay alive.. */
        if (!connection_head || strcmp(connection_head, "Keep-Alive"))
            do_close(c);
    }
    else 
    {
        /* HTTP 1.1: only if no close we stay alive .. */
        if (connection_head && !strcmp(connection_head, "close"))
            do_close(c);
    }
}
#endif

static int do_read(ZOOM_connection c)
{
    int r, more;
    ZOOM_Event event;
    
    event = ZOOM_Event_create(ZOOM_EVENT_RECV_DATA);
    ZOOM_connection_put_event(c, event);
    
    r = cs_get(c->cs, &c->buf_in, &c->len_in);
    more = cs_more(c->cs);
    yaz_log(log_details, "%p do_read len=%d more=%d", c, r, more);
    if (r == 1)
        return 0;
    if (r <= 0)
    {
        if (ZOOM_test_reconnect(c))
        {
            yaz_log(log_details, "%p do_read reconnect read", c);
        }
        else
        {
            set_ZOOM_error(c, ZOOM_ERROR_CONNECTION_LOST, c->host_port);
            do_close(c);
        }
    }
    else
    {
        Z_GDU *gdu;
        ZOOM_Event event;

        odr_reset(c->odr_in);
        odr_setbuf(c->odr_in, c->buf_in, r, 0);
        event = ZOOM_Event_create(ZOOM_EVENT_RECV_APDU);
        ZOOM_connection_put_event(c, event);

        if (!z_GDU(c->odr_in, &gdu, 0, 0))
        {
            int x;
            int err = odr_geterrorx(c->odr_in, &x);
            char msg[60];
            const char *element = odr_getelement(c->odr_in);
            sprintf(msg, "ODR code %d:%d element=%-20s",
                    err, x, element ? element : "<unknown>");
            set_ZOOM_error(c, ZOOM_ERROR_DECODE, msg);
            do_close(c);
        }
        else if (gdu->which == Z_GDU_Z3950)
            recv_apdu(c, gdu->u.z3950);
        else if (gdu->which == Z_GDU_HTTP_Response)
        {
#if YAZ_HAVE_XML2
            handle_http(c, gdu->u.HTTP_Response);
#else
            set_ZOOM_error(c, ZOOM_ERROR_DECODE, 0);
            do_close(c);
#endif
        }
        c->reconnect_ok = 0;
    }
    return 1;
}

static zoom_ret do_write_ex(ZOOM_connection c, char *buf_out, int len_out)
{
    int r;
    ZOOM_Event event;
    
    event = ZOOM_Event_create(ZOOM_EVENT_SEND_DATA);
    ZOOM_connection_put_event(c, event);

    yaz_log(log_details, "%p do_write_ex len=%d", c, len_out);
    if ((r = cs_put(c->cs, buf_out, len_out)) < 0)
    {
        yaz_log(log_details, "%p do_write_ex write failed", c);
        if (ZOOM_test_reconnect(c))
        {
            return zoom_pending;
        }
        if (c->state == STATE_CONNECTING)
            set_ZOOM_error(c, ZOOM_ERROR_CONNECT, c->host_port);
        else
            set_ZOOM_error(c, ZOOM_ERROR_CONNECTION_LOST, c->host_port);
        do_close(c);
        return zoom_complete;
    }
    else if (r == 1)
    {    
        c->mask = ZOOM_SELECT_EXCEPT;
        if (c->cs->io_pending & CS_WANT_WRITE)
            c->mask += ZOOM_SELECT_WRITE;
        if (c->cs->io_pending & CS_WANT_READ)
            c->mask += ZOOM_SELECT_READ;
        yaz_log(log_details, "%p do_write_ex write incomplete mask=%d",
                c, c->mask);
    }
    else
    {
        c->mask = ZOOM_SELECT_READ|ZOOM_SELECT_EXCEPT;
        yaz_log(log_details, "%p do_write_ex write complete mask=%d",
                c, c->mask);
    }
    return zoom_pending;
}

static zoom_ret do_write(ZOOM_connection c)
{
    return do_write_ex(c, c->buf_out, c->len_out);
}


ZOOM_API(const char *)
    ZOOM_connection_option_get(ZOOM_connection c, const char *key)
{
    return ZOOM_options_get(c->options, key);
}

ZOOM_API(const char *)
    ZOOM_connection_option_getl(ZOOM_connection c, const char *key, int *lenp)
{
    return ZOOM_options_getl(c->options, key, lenp);
}

ZOOM_API(void)
    ZOOM_connection_option_set(ZOOM_connection c, const char *key,
                               const char *val)
{
    ZOOM_options_set(c->options, key, val);
}

ZOOM_API(void)
    ZOOM_connection_option_setl(ZOOM_connection c, const char *key,
                                const char *val, int len)
{
    ZOOM_options_setl(c->options, key, val, len);
}

ZOOM_API(const char *)
    ZOOM_resultset_option_get(ZOOM_resultset r, const char *key)
{
    return ZOOM_options_get(r->options, key);
}

ZOOM_API(void)
    ZOOM_resultset_option_set(ZOOM_resultset r, const char *key,
                              const char *val)
{
    ZOOM_options_set(r->options, key, val);
}


ZOOM_API(int)
    ZOOM_connection_errcode(ZOOM_connection c)
{
    return ZOOM_connection_error(c, 0, 0);
}

ZOOM_API(const char *)
    ZOOM_connection_errmsg(ZOOM_connection c)
{
    const char *msg;
    ZOOM_connection_error(c, &msg, 0);
    return msg;
}

ZOOM_API(const char *)
    ZOOM_connection_addinfo(ZOOM_connection c)
{
    const char *addinfo;
    ZOOM_connection_error(c, 0, &addinfo);
    return addinfo;
}

ZOOM_API(const char *)
    ZOOM_connection_diagset(ZOOM_connection c)
{
    const char *diagset;
    ZOOM_connection_error_x(c, 0, 0, &diagset);
    return diagset;
}

ZOOM_API(const char *)
    ZOOM_diag_str(int error)
{
    switch (error)
    {
    case ZOOM_ERROR_NONE:
        return "No error";
    case ZOOM_ERROR_CONNECT:
        return "Connect failed";
    case ZOOM_ERROR_MEMORY:
        return "Out of memory";
    case ZOOM_ERROR_ENCODE:
        return "Encoding failed";
    case ZOOM_ERROR_DECODE:
        return "Decoding failed";
    case ZOOM_ERROR_CONNECTION_LOST:
        return "Connection lost";
    case ZOOM_ERROR_INIT:
        return "Init rejected";
    case ZOOM_ERROR_INTERNAL:
        return "Internal failure";
    case ZOOM_ERROR_TIMEOUT:
        return "Timeout";
    case ZOOM_ERROR_UNSUPPORTED_PROTOCOL:
        return "Unsupported protocol";
    case ZOOM_ERROR_UNSUPPORTED_QUERY:
        return "Unsupported query type";
    case ZOOM_ERROR_INVALID_QUERY:
        return "Invalid query";
    case ZOOM_ERROR_CQL_PARSE:
        return "CQL parsing error";
    case ZOOM_ERROR_CQL_TRANSFORM:
        return "CQL transformation error";
    case ZOOM_ERROR_CCL_CONFIG:
        return "CCL configuration error";
    case ZOOM_ERROR_CCL_PARSE:
        return "CCL parsing error";
    default:
        return diagbib1_str(error);
    }
}

ZOOM_API(int)
    ZOOM_connection_error_x(ZOOM_connection c, const char **cp,
                            const char **addinfo, const char **diagset)
{
    int error = c->error;
    if (cp)
    {
        if (!c->diagset || !strcmp(c->diagset, "ZOOM"))
            *cp = ZOOM_diag_str(error);
        else if (!strcmp(c->diagset, "HTTP"))
            *cp = z_HTTP_errmsg(c->error);
        else if (!strcmp(c->diagset, "Bib-1"))
            *cp = ZOOM_diag_str(error);
        else if (!strcmp(c->diagset, "info:srw/diagnostic/1"))
            *cp = yaz_diag_srw_str(c->error);
        else
            *cp = "Unknown error and diagnostic set";
    }
    if (addinfo)
        *addinfo = c->addinfo ? c->addinfo : "";
    if (diagset)
        *diagset = c->diagset ? c->diagset : "";
    return c->error;
}

ZOOM_API(int)
    ZOOM_connection_error(ZOOM_connection c, const char **cp,
                          const char **addinfo)
{
    return ZOOM_connection_error_x(c, cp, addinfo, 0);
}

static void ZOOM_connection_do_io(ZOOM_connection c, int mask)
{
    ZOOM_Event event = 0;
    int r = cs_look(c->cs);
    yaz_log(log_details, "%p ZOOM_connection_do_io mask=%d cs_look=%d",
            c, mask, r);
    
    if (r == CS_NONE)
    {
        event = ZOOM_Event_create(ZOOM_EVENT_CONNECT);
        set_ZOOM_error(c, ZOOM_ERROR_CONNECT, c->host_port);
        do_close(c);
        ZOOM_connection_put_event(c, event);
    }
    else if (r == CS_CONNECT)
    {
        int ret = ret = cs_rcvconnect(c->cs);
        yaz_log(log_details, "%p ZOOM_connection_do_io "
                "cs_rcvconnect returned %d", c, ret);
        if (ret == 1)
        {
            c->mask = ZOOM_SELECT_EXCEPT;
            if (c->cs->io_pending & CS_WANT_WRITE)
                c->mask += ZOOM_SELECT_WRITE;
            if (c->cs->io_pending & CS_WANT_READ)
                c->mask += ZOOM_SELECT_READ;
        }
        else if (ret == 0)
        {
            event = ZOOM_Event_create(ZOOM_EVENT_CONNECT);
            ZOOM_connection_put_event(c, event);
            get_cert(c);
            if (c->proto == PROTO_Z3950)
                ZOOM_connection_send_init(c);
            else
            {
                /* no init request for SRW .. */
                assert(c->tasks->which == ZOOM_TASK_CONNECT);
                ZOOM_connection_remove_task(c);
                c->mask = 0;
                ZOOM_connection_exec_task(c);
            }
            c->state = STATE_ESTABLISHED;
        }
        else
        {
            set_ZOOM_error(c, ZOOM_ERROR_CONNECT, c->host_port);
            do_close(c);
        }
    }
    else
    {
        if (mask & ZOOM_SELECT_EXCEPT)
        {
            if (ZOOM_test_reconnect(c))
            {
                event = ZOOM_Event_create(ZOOM_EVENT_CONNECT);
                ZOOM_connection_put_event(c, event);
            }
            else
            {
                set_ZOOM_error(c, ZOOM_ERROR_CONNECTION_LOST, c->host_port);
                do_close(c);
            }
            return;
        }
        if (mask & ZOOM_SELECT_READ)
            do_read(c);
        if (c->cs && (mask & ZOOM_SELECT_WRITE))
            do_write(c);
    }
}

ZOOM_API(int)
    ZOOM_connection_last_event(ZOOM_connection cs)
{
    if (!cs)
        return ZOOM_EVENT_NONE;
    return cs->last_event;
}

ZOOM_API(int)
    ZOOM_event(int no, ZOOM_connection *cs)
{
    int timeout = 30;      /* default timeout in seconds */
    int timeout_set = 0;   /* whether it was overriden at all */
#if HAVE_SYS_POLL_H
    struct pollfd pollfds[1024];
    ZOOM_connection poll_cs[1024];
#else
    struct timeval tv;
    fd_set input, output, except;
#endif
    int i, r, nfds;
    int max_fd = 0;

    yaz_log(log_details, "ZOOM_event(no=%d,cs=%p)", no, cs);
    
    for (i = 0; i<no; i++)
    {
        ZOOM_connection c = cs[i];
        ZOOM_Event event;

#if 0
        if (c)
            ZOOM_connection_show_tasks(c);
#endif

        if (c && (event = ZOOM_connection_get_event(c)))
        {
            ZOOM_Event_destroy(event);
            return i+1;
        }
    }
    for (i = 0; i<no; i++)
    {
        ZOOM_connection c = cs[i];
        if (c)
        {
            ZOOM_Event event;
            ZOOM_connection_exec_task(c);
            if ((event = ZOOM_connection_get_event(c)))
            {
                ZOOM_Event_destroy(event);
                return i+1;
            }
        }
    }
#if HAVE_SYS_POLL_H

#else
    FD_ZERO(&input);
    FD_ZERO(&output);
    FD_ZERO(&except);
#endif
    nfds = 0;
    for (i = 0; i<no; i++)
    {
        ZOOM_connection c = cs[i];
        int fd, mask;
        int this_timeout;
        
        if (!c)
            continue;
        fd = z3950_connection_socket(c);
        mask = z3950_connection_mask(c);

        if (fd == -1)
            continue;
        if (max_fd < fd)
            max_fd = fd;
        
        /* -1 is used for indefinite timeout (no timeout), so -2 here. */
        this_timeout = ZOOM_options_get_int(c->options, "timeout", -2);
        if (this_timeout != -2)
        {
            /* ensure the minimum timeout is used */
            if (!timeout_set)
                timeout = this_timeout;
            else if (this_timeout != -1 && this_timeout < timeout)
                timeout = this_timeout;
            timeout_set = 1;
        }               
#if HAVE_SYS_POLL_H
        if (mask)
        {
            short poll_events = 0;

            if (mask & ZOOM_SELECT_READ)
                poll_events += POLLIN;
            if (mask & ZOOM_SELECT_WRITE)
                poll_events += POLLOUT;
            if (mask & ZOOM_SELECT_EXCEPT)
                poll_events += POLLERR;
            pollfds[nfds].fd = fd;
            pollfds[nfds].events = poll_events;
            pollfds[nfds].revents = 0;
            poll_cs[nfds] = c;
            nfds++;
        }
#else
        if (mask & ZOOM_SELECT_READ)
        {
            FD_SET(fd, &input);
            nfds++;
        }
        if (mask & ZOOM_SELECT_WRITE)
        {
            FD_SET(fd, &output);
            nfds++;
        }
        if (mask & ZOOM_SELECT_EXCEPT)
        {
            FD_SET(fd, &except);
            nfds++;
        }
#endif
    }
    if (!nfds)
        return 0;

#if HAVE_SYS_POLL_H
    while ((r = poll(pollfds, nfds,
         (timeout == -1 ? -1 : timeout * 1000))) < 0
          && errno == EINTR)
    {
        ;
    }
    if (r < 0)
        yaz_log(YLOG_WARN|YLOG_ERRNO, "ZOOM_event: poll");
    for (i = 0; i<nfds; i++)
    {
        ZOOM_connection c = poll_cs[i];
        if (r && c->mask)
        {
            int mask = 0;
            if (pollfds[i].revents & POLLIN)
                mask += ZOOM_SELECT_READ;
            if (pollfds[i].revents & POLLOUT)
                mask += ZOOM_SELECT_WRITE;
            if (pollfds[i].revents & POLLERR)
                mask += ZOOM_SELECT_EXCEPT;
            if (mask)
                ZOOM_connection_do_io(c, mask);
        }
        else if (r == 0 && c->mask)
        {
            ZOOM_Event event = ZOOM_Event_create(ZOOM_EVENT_TIMEOUT);
            /* timeout and this connection was waiting */
            set_ZOOM_error(c, ZOOM_ERROR_TIMEOUT, 0);
            do_close(c);
            ZOOM_connection_put_event(c, event);
        }
    }
#else
    tv.tv_sec = timeout;
    tv.tv_usec = 0;

    while ((r = select(max_fd+1, &input, &output, &except,
                       (timeout == -1 ? 0 : &tv))) < 0 && errno == EINTR)
    {
        ;
    }
    if (r < 0)
        yaz_log(YLOG_WARN|YLOG_ERRNO, "ZOOM_event: select");

    r = select(max_fd+1, &input, &output, &except, (timeout == -1 ? 0 : &tv));
    for (i = 0; i<no; i++)
    {
        ZOOM_connection c = cs[i];
        int fd, mask;

        if (!c)
            continue;
        fd = z3950_connection_socket(c);
        mask = 0;
        if (r && c->mask)
        {
            /* no timeout and real socket */
            if (FD_ISSET(fd, &input))
                mask += ZOOM_SELECT_READ;
            if (FD_ISSET(fd, &output))
                mask += ZOOM_SELECT_WRITE;
            if (FD_ISSET(fd, &except))
                mask += ZOOM_SELECT_EXCEPT;
            if (mask)
                ZOOM_connection_do_io(c, mask);
        }
        if (r == 0 && c->mask)
        {
            ZOOM_Event event = ZOOM_Event_create(ZOOM_EVENT_TIMEOUT);
            /* timeout and this connection was waiting */
            set_ZOOM_error(c, ZOOM_ERROR_TIMEOUT, 0);
            do_close(c);
            ZOOM_connection_put_event(c, event);
        }
    }
#endif
    for (i = 0; i<no; i++)
    {
        ZOOM_connection c = cs[i];
        ZOOM_Event event;
        if (c && (event = ZOOM_connection_get_event(c)))
        {
            ZOOM_Event_destroy(event);
            return i+1;
        }
    }
    return 0;
}


/*
 * Returns an xmalloc()d string containing RPN that corresponds to the
 * CQL passed in.  On error, sets the Connection object's error state
 * and returns a null pointer.
 * ### We could cache CQL parser and/or transformer in Connection.
 */
static char *cql2pqf(ZOOM_connection c, const char *cql)
{
    CQL_parser parser;
    int error;
    struct cql_node *node;
    const char *cqlfile;
    static cql_transform_t trans;
    char pqfbuf[512];

    parser = cql_parser_create();
    if ((error = cql_parser_string(parser, cql)) != 0) {
        cql_parser_destroy(parser);
        set_ZOOM_error(c, ZOOM_ERROR_CQL_PARSE, cql);
        return 0;
    }

    node = cql_parser_result(parser);
    /* ### Do not call cql_parser_destroy() yet: it destroys `node'! */

    cqlfile = ZOOM_connection_option_get(c, "cqlfile");
    if (cqlfile == 0) {
        cql_parser_destroy(parser);
        cql_node_destroy(node);
        set_ZOOM_error(c, ZOOM_ERROR_CQL_TRANSFORM, "no CQL transform file");
        return 0;
    }

    if ((trans = cql_transform_open_fname(cqlfile)) == 0) {
        char buf[512];        
        cql_parser_destroy(parser);
        cql_node_destroy(node);
        sprintf(buf, "can't open CQL transform file '%.200s': %.200s",
                cqlfile, strerror(errno));
        set_ZOOM_error(c, ZOOM_ERROR_CQL_TRANSFORM, buf);
        return 0;
    }

    error = cql_transform_buf(trans, node, pqfbuf, sizeof pqfbuf);
    cql_parser_destroy(parser);
    cql_node_destroy(node);
    if (error != 0) {
        char buf[512];
        const char *addinfo;
        error = cql_transform_error(trans, &addinfo);
        cql_transform_close(trans);
        sprintf(buf, "%.200s (addinfo=%.200s)", cql_strerror(error), addinfo);
        set_ZOOM_error(c, ZOOM_ERROR_CQL_TRANSFORM, buf);
        return 0;
    }

    cql_transform_close(trans);
    return xstrdup(pqfbuf);
}

/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

