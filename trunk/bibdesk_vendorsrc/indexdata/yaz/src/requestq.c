/*
 * Copyright (C) 1995-2007, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: requestq.c,v 1.5 2007/01/03 08:42:15 adam Exp $
 */
/**
 * \file requestq.c
 * \brief Implements Simple queue management for GFS.
 *
 * We also use the request-freelist to store encoding buffers, rather than
 * freeing and xmalloc'ing them on each cycle.
 */

#include <stdlib.h>

#include <yaz/xmalloc.h>
#include "session.h"

void request_enq(request_q *q, request *r)
{
    if (q->tail)
        q->tail->next = r;
    else
        q->head = r;
    q->tail = r;
    q->num++;
}

request *request_head(request_q *q)
{
    return q->head;
}

request *request_deq(request_q *q)
{
    request *r = q->head;

    if (!r)
        return 0;
    q->head = q->head->next;
    if (!q->head)
        q->tail = 0;
    q->num--;
    return r;
}

void request_initq(request_q *q)
{
    q->head = q->tail = q->list = 0;
    q->num = 0;
}

void request_delq(request_q *q)
{
    request *r1, *r = q->list;
    while (r)
    {
        xfree (r->response);
        r1 = r;
        r = r->next;
        xfree (r1);
    }
}

request *request_get(request_q *q)
{
    request *r = q->list;

    if (r)
        q->list = r->next;
    else
    {
        if (!(r = (request *)xmalloc(sizeof(*r))))
            abort();
        r->response = 0;
        r->size_response = 0;
    }
    r->q = q;
    r->len_refid = 0;
    r->refid = 0;
    r->gdu_request = 0;
    r->apdu_request = 0;
    r->request_mem = 0;
    r->len_response = 0;
    r->clientData = 0;
    r->state = REQUEST_IDLE;
    r->next = 0;
    return r;
}

void request_release(request *r)
{
    request_q *q = r->q;
    r->next = q->list;
    q->list = r;
}

/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

