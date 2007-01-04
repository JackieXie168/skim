/*
 * Copyright (C) 1995-2006, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: session.h,v 1.12 2006/12/04 14:56:55 adam Exp $
 */
/**
 * \file session.h
 * \brief Internal Header for GFS.
 */
#ifndef SESSION_H
#define SESSION_H

#include <yaz/comstack.h>
#include <yaz/cql.h>
#include <yaz/odr.h>
#include <yaz/oid.h>
#include <yaz/proto.h>
#include <yaz/backend.h>
#include <yaz/retrieval.h>
#include "eventl.h"

struct gfs_server {
    statserv_options_block cb;
    char *host;
    int listen_ref;
    cql_transform_t cql_transform;
    void *server_node_ptr;
    char *directory;
    char *docpath;
    char *stylesheet;
    yaz_retrieval_t retrieval;
    struct gfs_server *next;
};

struct gfs_listen {
    char *id;
    char *address;
    struct gfs_listen *next;
};

typedef enum {
    REQUEST_IDLE,    /* the request is just sitting in the queue */
    REQUEST_PENDING  /* operation pending (b'end processing or network I/O*/
    /* this list will have more elements when acc/res control is added */
} request_state;

typedef struct request
{
    int len_refid;          /* length of referenceid */
    char *refid;            /* referenceid */
    request_state state;

    Z_GDU *gdu_request;     /* Current request */
    Z_APDU *apdu_request;   /* Current Z39.50 request */
    NMEM request_mem;    /* memory handle for request */

    int size_response;     /* size of buffer */
    int len_response;      /* length of encoded data */
    char *response;        /* encoded data waiting for transmission */

    void *clientData;
    struct request *next;
    struct request_q *q; 
} request;

typedef struct request_q
{
    request *head;
    request *tail;
    request *list;
    int num;
} request_q;

/*
 * association state.
 */
typedef enum
{
    ASSOC_NEW,                /* not initialized yet */
    ASSOC_UP,                 /* normal operation */
    ASSOC_DEAD                /* dead. Close if input arrives */
} association_state;

typedef struct association
{
    IOCHAN client_chan;           /* event-loop control */
    COMSTACK client_link;         /* communication handle */
    ODR decode;                   /* decoding stream */
    ODR encode;                   /* encoding stream */
    ODR print;                    /* printing stream (for -a) */
    char *encode_buffer;          /* temporary buffer for encoded data */
    int encoded_len;              /* length of encoded data */
    char *input_buffer;           /* input buffer (allocated by comstack) */
    int input_buffer_len;         /* length (size) of buffer */
    int input_apdu_len;           /* length of current incoming APDU */
    oid_proto proto;              /* protocol (PROTO_Z3950/PROTO_SR) */
    void *backend;                /* backend handle */
    request_q incoming;           /* Q of incoming PDUs */
    request_q outgoing;           /* Q of outgoing data buffers (enc. PDUs) */
    association_state state;

    /* session parameters */
    int preferredMessageSize;
    int maximumRecordSize;
    int version;                  /* highest version-bit set (2 or 3) */

    unsigned cs_get_mask;
    unsigned cs_put_mask;
    unsigned cs_accept_mask;

    struct bend_initrequest *init;
    statserv_options_block *last_control;

    struct gfs_server *server;
} association;

association *create_association(IOCHAN channel, COMSTACK link,
                                const char *apdufile);
void destroy_association(association *h);
void ir_session(IOCHAN h, int event);

void request_enq(request_q *q, request *r);
request *request_head(request_q *q);
request *request_deq(request_q *q);
request *request_deq_x(request_q *q, request *r);
void request_initq(request_q *q);
void request_delq(request_q *q);
request *request_get(request_q *q);
void request_release(request *r);

int statserv_must_terminate(void);

int control_association(association *assoc, const char *host, int force);

int ir_read(IOCHAN h, int event);

#endif
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

