/*
 * Copyright (C) 1995-2005, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: zoom-p.h,v 1.15 2006/11/01 15:39:05 adam Exp $
 */
/**
 * \file zoom-p.h
 * \brief Internal header for ZOOM implementation
 */

#include <yaz/proto.h>
#include <yaz/comstack.h>
#include <yaz/wrbuf.h>
#include <yaz/zoom.h>
#include <yaz/sortspec.h>
typedef struct ZOOM_Event_p *ZOOM_Event;

struct ZOOM_query_p {
    Z_Query *z_query;
    Z_SortKeySpecList *sort_spec;
    int refcount;
    ODR odr;
    char *query_string;
};

typedef enum {
    zoom_sru_error,
    zoom_sru_soap,
    zoom_sru_get,
    zoom_sru_post
} zoom_sru_mode;
    

typedef struct ZOOM_task_p *ZOOM_task;

#define STATE_IDLE 0
#define STATE_CONNECTING 1
#define STATE_ESTABLISHED 2

#define ZOOM_SELECT_READ 1
#define ZOOM_SELECT_WRITE 2
#define ZOOM_SELECT_EXCEPT 4

struct ZOOM_connection_p {
    enum oid_proto proto;
    COMSTACK cs;
    char *host_port;
    char *path;
    int error;
    char *addinfo;
    char *diagset;
    int state;
    int mask;
    int reconnect_ok;
    ODR odr_in;
    ODR odr_out;
    char *buf_in;
    int len_in;
    char *buf_out;
    int len_out;
    char *proxy;
    char *charset;
    char *lang;
    char *cookie_out;
    char *cookie_in;
    char *client_IP;
    int async;
    int support_named_resultsets;
    int last_event;
    ZOOM_task tasks;
    ZOOM_options options;
    ZOOM_resultset resultsets;
    ZOOM_Event m_queue_front;
    ZOOM_Event m_queue_back;
    zoom_sru_mode sru_mode;
};

struct ZOOM_options_entry {
    char *name;
    char *value;
    int len;                  /* of `value', which may contain NULs */
    struct ZOOM_options_entry *next;
};

struct ZOOM_options_p {
    int refcount;
    void *callback_handle;
    ZOOM_options_callback callback_func;
    struct ZOOM_options_entry *entries;
    ZOOM_options parent1;
    ZOOM_options parent2;
};


typedef struct ZOOM_record_cache_p *ZOOM_record_cache;

#define RECORD_HASH_SIZE  131

struct ZOOM_resultset_p {
    Z_SortKeySpecList *r_sort_spec;
    ZOOM_query query;
    int refcount;
    int size;
    int step;
    int piggyback;
    char *setname;
    char *schema;
    ODR odr;
    ZOOM_record_cache record_hash[RECORD_HASH_SIZE];
    ZOOM_options options;
    ZOOM_connection connection;
    ZOOM_resultset next;
    char **databaseNames;
    int num_databaseNames;
};

struct ZOOM_record_p {
    ODR odr;
    WRBUF wrbuf_marc;
    WRBUF wrbuf_iconv;
    WRBUF wrbuf_opac;
    Z_NamePlusRecord *npr;
};

struct ZOOM_record_cache_p {
    struct ZOOM_record_p rec;
    char *elementSetName;
    char *syntax;
    char *schema;
    int pos;
    ZOOM_record_cache next;
};

struct ZOOM_scanset_p {
    int refcount;
    ODR odr;
    ZOOM_options options;
    ZOOM_connection connection;
    Z_AttributesPlusTerm *termListAndStartPoint;
    Z_AttributeSetId *attributeSet;
    Z_ScanResponse *scan_response;
    char **databaseNames;
    int num_databaseNames;
};

struct ZOOM_package_p {
    int refcount;
    ODR odr_out;
    ZOOM_options options;
    ZOOM_connection connection;
    char *buf_out;
    int len_out;
};

struct ZOOM_task_p {
    int running;
    int which;
    union {
#define ZOOM_TASK_SEARCH 1
        struct {
            int count;
            int start;
            ZOOM_resultset resultset;
            char *syntax;
            char *elementSetName;
        } search;
#define ZOOM_TASK_RETRIEVE 2
        struct {
            int start;
            ZOOM_resultset resultset;
            int count;
            char *syntax;
            char *elementSetName;
        } retrieve;
#define ZOOM_TASK_CONNECT 3
#define ZOOM_TASK_SCAN 4
        struct {
            ZOOM_scanset scan;
        } scan;
#define ZOOM_TASK_PACKAGE 5
        ZOOM_package package;
#define ZOOM_TASK_SORT 6
        struct {
            ZOOM_resultset resultset;
            ZOOM_query q;
        } sort;
    } u;
    ZOOM_task next;
};

struct ZOOM_Event_p {
    int kind;
    ZOOM_Event next;
    ZOOM_Event prev;
};

void ZOOM_options_addref (ZOOM_options opt);
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

