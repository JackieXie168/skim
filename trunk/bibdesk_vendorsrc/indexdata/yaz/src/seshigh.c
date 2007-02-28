/*
 * Copyright (C) 1995-2007, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: seshigh.c,v 1.109 2007/01/16 14:12:38 adam Exp $
 */
/**
 * \file seshigh.c
 * \brief Implements GFS session logic.
 *
 * Frontend server logic.
 *
 * This code receives incoming APDUs, and handles client requests by means
 * of the backend API.
 *
 * Some of the code is getting quite involved, compared to simpler servers -
 * primarily because it is asynchronous both in the communication with
 * the user and the backend. We think the complexity will pay off in
 * the form of greater flexibility when more asynchronous facilities
 * are implemented.
 *
 * Memory management has become somewhat involved. In the simple case, where
 * only one PDU is pending at a time, it will simply reuse the same memory,
 * once it has found its working size. When we enable multiple concurrent
 * operations, perhaps even with multiple parallel calls to the backend, it
 * will maintain a pool of buffers for encoding and decoding, trying to
 * minimize memory allocation/deallocation during normal operation.
 *
 */

#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include <ctype.h>

#if HAVE_SYS_TYPES_H
#include <sys/types.h>
#endif
#if HAVE_SYS_STAT_H
#include <sys/stat.h>
#endif

#ifdef WIN32
#include <io.h>
#define S_ISREG(x) (x & _S_IFREG)
#include <process.h>
#endif

#if HAVE_UNISTD_H
#include <unistd.h>
#endif

#if YAZ_HAVE_XML2
#include <libxml/parser.h>
#include <libxml/tree.h>
#endif

#include <yaz/yconfig.h>
#include <yaz/xmalloc.h>
#include <yaz/comstack.h>
#include "eventl.h"
#include "session.h"
#include "mime.h"
#include <yaz/proto.h>
#include <yaz/oid.h>
#include <yaz/log.h>
#include <yaz/logrpn.h>
#include <yaz/querytowrbuf.h>
#include <yaz/statserv.h>
#include <yaz/diagbib1.h>
#include <yaz/charneg.h>
#include <yaz/otherinfo.h>
#include <yaz/yaz-util.h>
#include <yaz/pquery.h>

#include <yaz/srw.h>
#include <yaz/backend.h>

static void process_gdu_request(association *assoc, request *req);
static int process_z_request(association *assoc, request *req, char **msg);
void backend_response(IOCHAN i, int event);
static int process_gdu_response(association *assoc, request *req, Z_GDU *res);
static int process_z_response(association *assoc, request *req, Z_APDU *res);
static Z_APDU *process_initRequest(association *assoc, request *reqb);
static Z_External *init_diagnostics(ODR odr, int errcode,
                                    const char *errstring);
static Z_APDU *process_searchRequest(association *assoc, request *reqb,
    int *fd);
static Z_APDU *response_searchRequest(association *assoc, request *reqb,
    bend_search_rr *bsrr, int *fd);
static Z_APDU *process_presentRequest(association *assoc, request *reqb,
    int *fd);
static Z_APDU *process_scanRequest(association *assoc, request *reqb, int *fd);
static Z_APDU *process_sortRequest(association *assoc, request *reqb, int *fd);
static void process_close(association *assoc, request *reqb);
void save_referenceId (request *reqb, Z_ReferenceId *refid);
static Z_APDU *process_deleteRequest(association *assoc, request *reqb,
    int *fd);
static Z_APDU *process_segmentRequest (association *assoc, request *reqb);

static Z_APDU *process_ESRequest(association *assoc, request *reqb, int *fd);

/* dynamic logging levels */
static int logbits_set = 0;
static int log_session = 0; /* one-line logs for session */
static int log_sessiondetail = 0; /* more detailed stuff */
static int log_request = 0; /* one-line logs for requests */
static int log_requestdetail = 0;  /* more detailed stuff */

/** get_logbits sets global loglevel bits */
static void get_logbits(void)
{ /* needs to be called after parsing cmd-line args that can set loglevels!*/
    if (!logbits_set)
    {
        logbits_set = 1;
        log_session = yaz_log_module_level("session"); 
        log_sessiondetail = yaz_log_module_level("sessiondetail");
        log_request = yaz_log_module_level("request");
        log_requestdetail = yaz_log_module_level("requestdetail"); 
    }
}



static void wr_diag(WRBUF w, int error, const char *addinfo)
{
    wrbuf_printf(w, "ERROR %d+", error);
    wrbuf_puts_replace_char(w, diagbib1_str(error), ' ', '_');
    if (addinfo){
        wrbuf_puts(w, "+");
        wrbuf_puts_replace_char(w, addinfo, ' ', '_');
    }
    
    wrbuf_puts(w, " ");    
}


/*
 * Create and initialize a new association-handle.
 *  channel  : iochannel for the current line.
 *  link     : communications channel.
 * Returns: 0 or a new association handle.
 */
association *create_association(IOCHAN channel, COMSTACK link,
                                const char *apdufile)
{
    association *anew;

    if (!logbits_set)
        get_logbits();
    if (!(anew = (association *)xmalloc(sizeof(*anew))))
        return 0;
    anew->init = 0;
    anew->version = 0;
    anew->last_control = 0;
    anew->client_chan = channel;
    anew->client_link = link;
    anew->cs_get_mask = 0;
    anew->cs_put_mask = 0;
    anew->cs_accept_mask = 0;
    if (!(anew->decode = odr_createmem(ODR_DECODE)) ||
        !(anew->encode = odr_createmem(ODR_ENCODE)))
        return 0;
    if (apdufile && *apdufile)
    {
        FILE *f;

        if (!(anew->print = odr_createmem(ODR_PRINT)))
            return 0;
        if (*apdufile == '@')
        {
            odr_setprint(anew->print, yaz_log_file());
        }       
        else if (*apdufile != '-')
        {
            char filename[256];
            sprintf(filename, "%.200s.%ld", apdufile, (long)getpid());
            if (!(f = fopen(filename, "w")))
            {
                yaz_log(YLOG_WARN|YLOG_ERRNO, "%s", filename);
                return 0;
            }
            setvbuf(f, 0, _IONBF, 0);
            odr_setprint(anew->print, f);
        }
    }
    else
        anew->print = 0;
    anew->input_buffer = 0;
    anew->input_buffer_len = 0;
    anew->backend = 0;
    anew->state = ASSOC_NEW;
    request_initq(&anew->incoming);
    request_initq(&anew->outgoing);
    anew->proto = cs_getproto(link);
    anew->server = 0;
    return anew;
}

/*
 * Free association and release resources.
 */
void destroy_association(association *h)
{
    statserv_options_block *cb = statserv_getcontrol();
    request *req;

    xfree(h->init);
    odr_destroy(h->decode);
    odr_destroy(h->encode);
    if (h->print)
        odr_destroy(h->print);
    if (h->input_buffer)
    xfree(h->input_buffer);
    if (h->backend)
        (*cb->bend_close)(h->backend);
    while ((req = request_deq(&h->incoming)))
        request_release(req);
    while ((req = request_deq(&h->outgoing)))
        request_release(req);
    request_delq(&h->incoming);
    request_delq(&h->outgoing);
    xfree(h);
    xmalloc_trav("session closed");
    if (cb && cb->one_shot)
    {
        exit (0);
    }
}

static void do_close_req(association *a, int reason, char *message,
                         request *req)
{
    Z_APDU apdu;
    Z_Close *cls = zget_Close(a->encode);
    
    /* Purge request queue */
    while (request_deq(&a->incoming));
    while (request_deq(&a->outgoing));
    if (a->version >= 3)
    {
        yaz_log(log_requestdetail, "Sending Close PDU, reason=%d, message=%s",
            reason, message ? message : "none");
        apdu.which = Z_APDU_close;
        apdu.u.close = cls;
        *cls->closeReason = reason;
        cls->diagnosticInformation = message;
        process_z_response(a, req, &apdu);
        iochan_settimeout(a->client_chan, 20);
    }
    else
    {
        request_release(req);
        yaz_log(log_requestdetail, "v2 client. No Close PDU");
        iochan_setevent(a->client_chan, EVENT_TIMEOUT); /* force imm close */
        a->cs_put_mask = 0;
    }
    a->state = ASSOC_DEAD;
}

static void do_close(association *a, int reason, char *message)
{
    request *req = request_get(&a->outgoing);
    do_close_req (a, reason, message, req);
}


int ir_read(IOCHAN h, int event)
{
    association *assoc = (association *)iochan_getdata(h);
    COMSTACK conn = assoc->client_link;
    request *req;
    
    if ((assoc->cs_put_mask & EVENT_INPUT) == 0 && (event & assoc->cs_get_mask))
    {
        yaz_log(YLOG_DEBUG, "ir_session (input)");
        /* We aren't speaking to this fellow */
        if (assoc->state == ASSOC_DEAD)
        {
            yaz_log(log_sessiondetail, "Connection closed - end of session");
            cs_close(conn);
            destroy_association(assoc);
            iochan_destroy(h);
            return 0;
        }
        assoc->cs_get_mask = EVENT_INPUT;

        do
        {
            int res = cs_get(conn, &assoc->input_buffer,
                             &assoc->input_buffer_len);
            if (res < 0 && cs_errno(conn) == CSBUFSIZE)
            {
                yaz_log(log_session, "Connection error: %s res=%d",
                        cs_errmsg(cs_errno(conn)), res);
                req = request_get(&assoc->incoming); /* get a new request */
                do_close_req(assoc, Z_Close_protocolError, 
                             "Incoming package too large", req);
                return 0;
            }
            else if (res <= 0)
            {
                yaz_log(log_session, "Connection closed by client");
                assoc->state = ASSOC_DEAD;
                return 0;
            }
            else if (res == 1) /* incomplete read - wait for more  */
            {
                if (conn->io_pending & CS_WANT_WRITE)
                    assoc->cs_get_mask |= EVENT_OUTPUT;
                iochan_setflag(h, assoc->cs_get_mask);
                return 0;
            }
            /* we got a complete PDU. Let's decode it */
            yaz_log(YLOG_DEBUG, "Got PDU, %d bytes: lead=%02X %02X %02X", res,
                    assoc->input_buffer[0] & 0xff,
                    assoc->input_buffer[1] & 0xff,
                    assoc->input_buffer[2] & 0xff);
            req = request_get(&assoc->incoming); /* get a new request */
            odr_reset(assoc->decode);
            odr_setbuf(assoc->decode, assoc->input_buffer, res, 0);
            if (!z_GDU(assoc->decode, &req->gdu_request, 0, 0))
            {
                yaz_log(YLOG_WARN, "ODR error on incoming PDU: %s [element %s] "
                        "[near byte %ld] ",
                        odr_errmsg(odr_geterror(assoc->decode)),
                        odr_getelement(assoc->decode),
                        (long) odr_offset(assoc->decode));
                if (assoc->decode->error != OHTTP)
                {
                    yaz_log(YLOG_WARN, "PDU dump:");
                    odr_dumpBER(yaz_log_file(), assoc->input_buffer, res);
                    request_release(req);
                    do_close(assoc, Z_Close_protocolError, "Malformed package");
                }
                else
                {
                    Z_GDU *p = z_get_HTTP_Response(assoc->encode, 400);
                    assoc->state = ASSOC_DEAD;
                    process_gdu_response(assoc, req, p);
                }
                return 0;
            }
            req->request_mem = odr_extract_mem(assoc->decode);
            if (assoc->print) 
            {
                if (!z_GDU(assoc->print, &req->gdu_request, 0, 0))
                    yaz_log(YLOG_WARN, "ODR print error: %s", 
                            odr_errmsg(odr_geterror(assoc->print)));
                odr_reset(assoc->print);
            }
            request_enq(&assoc->incoming, req);
        }
        while (cs_more(conn));
    }
    return 1;
}

/*
 * This is where PDUs from the client are read and the further
 * processing is initiated. Flow of control moves down through the
 * various process_* functions below, until the encoded result comes back up
 * to the output handler in here.
 * 
 *  h     : the I/O channel that has an outstanding event.
 *  event : the current outstanding event.
 */
void ir_session(IOCHAN h, int event)
{
    int res;
    association *assoc = (association *)iochan_getdata(h);
    COMSTACK conn = assoc->client_link;
    request *req;

    assert(h && conn && assoc);
    if (event == EVENT_TIMEOUT)
    {
        if (assoc->state != ASSOC_UP)
        {
            yaz_log(YLOG_DEBUG, "Final timeout - closing connection.");
            /* do we need to lod this at all */
            cs_close(conn);
            destroy_association(assoc);
            iochan_destroy(h);
        }
        else
        {
            yaz_log(log_sessiondetail, 
                    "Session idle too long. Sending close.");
            do_close(assoc, Z_Close_lackOfActivity, 0);
        }
        return;
    }
    if (event & assoc->cs_accept_mask)
    {
        if (!cs_accept (conn))
        {
            yaz_log (YLOG_WARN, "accept failed");
            destroy_association(assoc);
            iochan_destroy(h);
        }
        iochan_clearflag (h, EVENT_OUTPUT);
        if (conn->io_pending) 
        {   /* cs_accept didn't complete */
            assoc->cs_accept_mask = 
                ((conn->io_pending & CS_WANT_WRITE) ? EVENT_OUTPUT : 0) |
                ((conn->io_pending & CS_WANT_READ) ? EVENT_INPUT : 0);

            iochan_setflag (h, assoc->cs_accept_mask);
        }
        else
        {   /* cs_accept completed. Prepare for reading (cs_get) */
            assoc->cs_accept_mask = 0;
            assoc->cs_get_mask = EVENT_INPUT;
            iochan_setflag (h, assoc->cs_get_mask);
        }
        return;
    }
    if (event & assoc->cs_get_mask) /* input */
    {
        if (!ir_read(h, event))
            return;
        req = request_head(&assoc->incoming);
        if (req->state == REQUEST_IDLE)
        {
            request_deq(&assoc->incoming);
            process_gdu_request(assoc, req);
        }
    }
    if (event & assoc->cs_put_mask)
    {
        request *req = request_head(&assoc->outgoing);

        assoc->cs_put_mask = 0;
        yaz_log(YLOG_DEBUG, "ir_session (output)");
        req->state = REQUEST_PENDING;
        switch (res = cs_put(conn, req->response, req->len_response))
        {
        case -1:
            yaz_log(log_sessiondetail, "Connection closed by client");
            cs_close(conn);
            destroy_association(assoc);
            iochan_destroy(h);
            break;
        case 0: /* all sent - release the request structure */
            yaz_log(YLOG_DEBUG, "Wrote PDU, %d bytes", req->len_response);
#if 0
            yaz_log(YLOG_DEBUG, "HTTP out:\n%.*s", req->len_response,
                    req->response);
#endif
            nmem_destroy(req->request_mem);
            request_deq(&assoc->outgoing);
            request_release(req);
            if (!request_head(&assoc->outgoing))
            {   /* restore mask for cs_get operation ... */
                iochan_clearflag(h, EVENT_OUTPUT|EVENT_INPUT);
                iochan_setflag(h, assoc->cs_get_mask);
                if (assoc->state == ASSOC_DEAD)
                    iochan_setevent(assoc->client_chan, EVENT_TIMEOUT);
            }
            else
            {
                assoc->cs_put_mask = EVENT_OUTPUT;
            }
            break;
        default:
            if (conn->io_pending & CS_WANT_WRITE)
                assoc->cs_put_mask |= EVENT_OUTPUT;
            if (conn->io_pending & CS_WANT_READ)
                assoc->cs_put_mask |= EVENT_INPUT;
            iochan_setflag(h, assoc->cs_put_mask);
        }
    }
    if (event & EVENT_EXCEPT)
    {
        yaz_log(YLOG_WARN, "ir_session (exception)");
        cs_close(conn);
        destroy_association(assoc);
        iochan_destroy(h);
    }
}

static int process_z_request(association *assoc, request *req, char **msg);


static void assoc_init_reset(association *assoc)
{
    xfree (assoc->init);
    assoc->init = (bend_initrequest *) xmalloc (sizeof(*assoc->init));

    assoc->init->stream = assoc->encode;
    assoc->init->print = assoc->print;
    assoc->init->auth = 0;
    assoc->init->referenceId = 0;
    assoc->init->implementation_version = 0;
    assoc->init->implementation_id = 0;
    assoc->init->implementation_name = 0;
    assoc->init->bend_sort = NULL;
    assoc->init->bend_search = NULL;
    assoc->init->bend_present = NULL;
    assoc->init->bend_esrequest = NULL;
    assoc->init->bend_delete = NULL;
    assoc->init->bend_scan = NULL;
    assoc->init->bend_segment = NULL;
    assoc->init->bend_fetch = NULL;
    assoc->init->bend_explain = NULL;
    assoc->init->bend_srw_scan = NULL;
    assoc->init->bend_srw_update = NULL;

    assoc->init->charneg_request = NULL;
    assoc->init->charneg_response = NULL;

    assoc->init->decode = assoc->decode;
    assoc->init->peer_name = 
        odr_strdup (assoc->encode, cs_addrstr(assoc->client_link));

    yaz_log(log_requestdetail, "peer %s", assoc->init->peer_name);
}

static int srw_bend_init(association *assoc, Z_SRW_diagnostic **d, int *num, Z_SRW_PDU *sr)
{
    statserv_options_block *cb = statserv_getcontrol();
    if (!assoc->init)
    {
        const char *encoding = "UTF-8";
        Z_External *ce;
        bend_initresult *binitres;

        yaz_log(log_requestdetail, "srw_bend_init config=%s", cb->configname);
        assoc_init_reset(assoc);
        
        if (sr->username)
        {
            Z_IdAuthentication *auth = odr_malloc(assoc->decode, sizeof(*auth));
            int len;

            len = strlen(sr->username) + 1;
            if (sr->password) 
                len += strlen(sr->password) + 2;
            auth->which = Z_IdAuthentication_open;
            auth->u.open = odr_malloc(assoc->decode, len);
            strcpy(auth->u.open, sr->username);
            if (sr->password && *sr->password)
            {
                strcat(auth->u.open, "/");
                strcat(auth->u.open, sr->password);
            }
            assoc->init->auth = auth;
        }

#if 1
        ce = yaz_set_proposal_charneg(assoc->decode, &encoding, 1, 0, 0, 1);
        assoc->init->charneg_request = ce->u.charNeg3;
#endif
        assoc->backend = 0;
        if (!(binitres = (*cb->bend_init)(assoc->init)))
        {
            assoc->state = ASSOC_DEAD;
            yaz_add_srw_diagnostic(assoc->encode, d, num,
                            YAZ_SRW_AUTHENTICATION_ERROR, 0);
            return 0;
        }
        assoc->backend = binitres->handle;
        assoc->init->auth = 0;
        if (binitres->errcode)
        {
            int srw_code = yaz_diag_bib1_to_srw(binitres->errcode);
            assoc->state = ASSOC_DEAD;
            yaz_add_srw_diagnostic(assoc->encode, d, num, srw_code,
                                   binitres->errstring);
            return 0;
        }
        return 1;
    }
    return 1;
}

static int retrieve_fetch(association *assoc, bend_fetch_rr *rr)
{
#if YAZ_HAVE_XML2
    yaz_record_conv_t rc = 0;
    const char *match_schema = 0;
    int *match_syntax = 0;

    if (assoc->server)
    {
        int r;
        const char *input_schema = yaz_get_esn(rr->comp);
        Odr_oid *input_syntax_raw = rr->request_format_raw;
        
        const char *backend_schema = 0;
        Odr_oid *backend_syntax = 0;

        r = yaz_retrieval_request(assoc->server->retrieval,
                                  input_schema,
                                  input_syntax_raw,
                                  &match_schema,
                                  &match_syntax,
                                  &rc,
                                  &backend_schema,
                                  &backend_syntax);
        if (r == -1) /* error ? */
        {
            const char *details = yaz_retrieval_get_error(
                assoc->server->retrieval);

            rr->errcode = YAZ_BIB1_SYSTEM_ERROR_IN_PRESENTING_RECORDS;
            if (details)
                rr->errstring = odr_strdup(rr->stream, details);
            return -1;
        }
        else if (r == 1 || r == 3)
        {
            const char *details = input_schema;
            rr->errcode =  YAZ_BIB1_ELEMENT_SET_NAMES_UNSUPP;
            if (details)
                rr->errstring = odr_strdup(rr->stream, details);
            return -1;
        }
        else if (r == 2)
        {
            rr->errcode = YAZ_BIB1_RECORD_SYNTAX_UNSUPP;
            if (input_syntax_raw)
            {
                char oidbuf[OID_STR_MAX];
                oid_to_dotstring(input_syntax_raw, oidbuf);
                rr->errstring = odr_strdup(rr->stream, oidbuf);
            }
            return -1;
        }
        if (backend_schema)
        {
            yaz_set_esn(&rr->comp, backend_schema, rr->stream->mem);
        }
        if (backend_syntax)
        {
            oident *oident_syntax = oid_getentbyoid(backend_syntax);

            rr->request_format_raw = backend_syntax;
            
            if (oident_syntax)
                rr->request_format = oident_syntax->value;
            else
                rr->request_format = VAL_NONE;
        }
    }
    (*assoc->init->bend_fetch)(assoc->backend, rr);
    if (rc && rr->record && rr->errcode == 0 && rr->len > 0)
    {   /* post conversion must take place .. */
        WRBUF output_record = wrbuf_alloc();
        int r = yaz_record_conv_record(rc, rr->record, rr->len, output_record);
        if (r)
        {
            const char *details = yaz_record_conv_get_error(rc);
            rr->errcode = YAZ_BIB1_SYSTEM_ERROR_IN_PRESENTING_RECORDS;
            if (details)
                rr->errstring = odr_strdup(rr->stream, details);
        }
        else
        {
            rr->len = wrbuf_len(output_record);
            rr->record = odr_malloc(rr->stream, rr->len);
            memcpy(rr->record, wrbuf_buf(output_record), rr->len);
        }
        wrbuf_free(output_record, 1);
    }
    if (match_syntax)
    {
        struct oident *oi = oid_getentbyoid(match_syntax);
        rr->output_format = oi ? oi->value : VAL_NONE;
        rr->output_format_raw = match_syntax;
    }
    if (match_schema)
        rr->schema = odr_strdup(rr->stream, match_schema);
    return 0;
#else
    (*assoc->init->bend_fetch)(assoc->backend, rr);
#endif
}

static int srw_bend_fetch(association *assoc, int pos,
                          Z_SRW_searchRetrieveRequest *srw_req,
                          Z_SRW_record *record,
                          const char **addinfo)
{
    bend_fetch_rr rr;
    ODR o = assoc->encode;

    rr.setname = "default";
    rr.number = pos;
    rr.referenceId = 0;
    rr.request_format = VAL_TEXT_XML;
    rr.request_format_raw = yaz_oidval_to_z3950oid(assoc->decode,
                                                   CLASS_RECSYN,
                                                   VAL_TEXT_XML);
    rr.comp = (Z_RecordComposition *)
            odr_malloc(assoc->decode, sizeof(*rr.comp));
    rr.comp->which = Z_RecordComp_complex;
    rr.comp->u.complex = (Z_CompSpec *)
            odr_malloc(assoc->decode, sizeof(Z_CompSpec));
    rr.comp->u.complex->selectAlternativeSyntax = (bool_t *)
        odr_malloc(assoc->encode, sizeof(bool_t));
    *rr.comp->u.complex->selectAlternativeSyntax = 0;    
    rr.comp->u.complex->num_dbSpecific = 0;
    rr.comp->u.complex->dbSpecific = 0;
    rr.comp->u.complex->num_recordSyntax = 0; 
    rr.comp->u.complex->recordSyntax = 0;

    rr.comp->u.complex->generic = (Z_Specification *) 
            odr_malloc(assoc->decode, sizeof(Z_Specification));

    /* schema uri = recordSchema (or NULL if recordSchema is not given) */
    rr.comp->u.complex->generic->which = Z_Schema_uri;
    rr.comp->u.complex->generic->schema.uri = srw_req->recordSchema;

    /* ESN = recordSchema if recordSchema is present */
    rr.comp->u.complex->generic->elementSpec = 0;
    if (srw_req->recordSchema)
    {
        rr.comp->u.complex->generic->elementSpec = 
            (Z_ElementSpec *) odr_malloc(assoc->encode, sizeof(Z_ElementSpec));
        rr.comp->u.complex->generic->elementSpec->which = 
            Z_ElementSpec_elementSetName;
        rr.comp->u.complex->generic->elementSpec->u.elementSetName =
            srw_req->recordSchema;
    }
    
    rr.stream = assoc->encode;
    rr.print = assoc->print;

    rr.basename = 0;
    rr.len = 0;
    rr.record = 0;
    rr.last_in_set = 0;
    rr.errcode = 0;
    rr.errstring = 0;
    rr.surrogate_flag = 0;
    rr.schema = srw_req->recordSchema;

    if (!assoc->init->bend_fetch)
        return 1;

    retrieve_fetch(assoc, &rr);

    if (rr.errcode && rr.surrogate_flag)
    {
        int code = yaz_diag_bib1_to_srw(rr.errcode);
        const char *message = yaz_diag_srw_str(code);
        int len = 200;
        if (message)
            len += strlen(message);
        if (rr.errstring)
            len += strlen(rr.errstring);

        record->recordData_buf = odr_malloc(o, len);
        
        sprintf(record->recordData_buf, "<diagnostic "
                "xmlns=\"http://www.loc.gov/zing/srw/diagnostic/\">\n"
                " <uri>info:srw/diagnostic/1/%d</uri>\n", code);
        if (rr.errstring)
            sprintf(record->recordData_buf + strlen(record->recordData_buf),
                    " <details>%s</details>\n", rr.errstring);
        if (message)
            sprintf(record->recordData_buf + strlen(record->recordData_buf),
                    " <message>%s</message>\n", message);
        sprintf(record->recordData_buf + strlen(record->recordData_buf),
                "</diagnostic>\n");
        record->recordData_len = strlen(record->recordData_buf);
        record->recordPosition = odr_intdup(o, pos);
        record->recordSchema = "info:srw/schema/1/diagnostics-v1.1";
        return 0;
    }
    else if (rr.len >= 0)
    {
        record->recordData_buf = rr.record;
        record->recordData_len = rr.len;
        record->recordPosition = odr_intdup(o, pos);
        if (rr.schema)
            record->recordSchema = odr_strdup(o, rr.schema);
        else
            record->recordSchema = 0;
    }
    if (rr.errcode)
    {
        *addinfo = rr.errstring;
        return rr.errcode;
    }
    return 0;
}

static int cql2pqf(ODR odr, const char *cql, cql_transform_t ct,
                   Z_Query *query_result)
{
    /* have a CQL query and  CQL to PQF transform .. */
    CQL_parser cp = cql_parser_create();
    int r;
    int srw_errcode = 0;
    const char *add = 0;
    char rpn_buf[5120];
            
    r = cql_parser_string(cp, cql);
    if (r)
    {
        /* CQL syntax error */
        srw_errcode = 10; 
    }
    if (!r)
    {
        /* Syntax OK */
        r = cql_transform_buf(ct,
                              cql_parser_result(cp),
                              rpn_buf, sizeof(rpn_buf)-1);
        if (r)
            srw_errcode  = cql_transform_error(ct, &add);
    }
    if (!r)
    {
        /* Syntax & transform OK. */
        /* Convert PQF string to Z39.50 to RPN query struct */
        YAZ_PQF_Parser pp = yaz_pqf_create();
        Z_RPNQuery *rpnquery = yaz_pqf_parse(pp, odr, rpn_buf);
        if (!rpnquery)
        {
            size_t off;
            const char *pqf_msg;
            int code = yaz_pqf_error(pp, &pqf_msg, &off);
            yaz_log(YLOG_WARN, "PQF Parser Error %s (code %d)",
                    pqf_msg, code);
            srw_errcode = 10;
        }
        else
        {
            query_result->which = Z_Query_type_1;
            query_result->u.type_1 = rpnquery;
        }
        yaz_pqf_destroy(pp);
    }
    cql_parser_destroy(cp);
    return srw_errcode;
}

static int cql2pqf_scan(ODR odr, const char *cql, cql_transform_t ct,
                        Z_AttributesPlusTerm *result)
{
    Z_Query query;
    Z_RPNQuery *rpn;
    int srw_error = cql2pqf(odr, cql, ct, &query);
    if (srw_error)
        return srw_error;
    if (query.which != Z_Query_type_1 && query.which != Z_Query_type_101)
        return 10; /* bad query type */
    rpn = query.u.type_1;
    if (!rpn->RPNStructure) 
        return 10; /* must be structure */
    if (rpn->RPNStructure->which != Z_RPNStructure_simple)
        return 10; /* must be simple */
    if (rpn->RPNStructure->u.simple->which != Z_Operand_APT)
        return 10; /* must be attributes plus term node .. */
    memcpy(result, rpn->RPNStructure->u.simple->u.attributesPlusTerm,
           sizeof(*result));
    return 0;
}
                   
static void srw_bend_search(association *assoc, request *req,
                            Z_SRW_PDU *sr,
                            Z_SRW_searchRetrieveResponse *srw_res,
                            int *http_code)
{
    int srw_error = 0;
    Z_External *ext;
    Z_SRW_searchRetrieveRequest *srw_req = sr->u.request;
    
    *http_code = 200;
    yaz_log(log_requestdetail, "Got SRW SearchRetrieveRequest");
    srw_bend_init(assoc, &srw_res->diagnostics, &srw_res->num_diagnostics, sr);
    if (srw_res->num_diagnostics == 0 && assoc->init)
    {
        bend_search_rr rr;
        rr.setname = "default";
        rr.replace_set = 1;
        rr.num_bases = 1;
        rr.basenames = &srw_req->database;
        rr.referenceId = 0;
        rr.srw_sortKeys = 0;
        rr.srw_setname = 0;
        rr.srw_setnameIdleTime = 0;
        rr.estimated_hit_count = 0;
        rr.partial_resultset = 0;
        rr.query = (Z_Query *) odr_malloc (assoc->decode, sizeof(*rr.query));
        rr.query->u.type_1 = 0;
        
        if (srw_req->query_type == Z_SRW_query_type_cql)
        {
            if (assoc->server && assoc->server->cql_transform)
            {
                int srw_errcode = cql2pqf(assoc->encode, srw_req->query.cql,
                                          assoc->server->cql_transform,
                                          rr.query);
                if (srw_errcode)
                {
                    yaz_add_srw_diagnostic(assoc->encode,
                                           &srw_res->diagnostics,
                                           &srw_res->num_diagnostics,
                                           srw_errcode, 0);
                }
            }
            else
            {
                /* CQL query to backend. Wrap it - Z39.50 style */
                ext = (Z_External *) odr_malloc(assoc->decode, sizeof(*ext));
                ext->direct_reference = odr_getoidbystr(assoc->decode, 
                                                        "1.2.840.10003.16.2");
                ext->indirect_reference = 0;
                ext->descriptor = 0;
                ext->which = Z_External_CQL;
                ext->u.cql = srw_req->query.cql;
                
                rr.query->which = Z_Query_type_104;
                rr.query->u.type_104 =  ext;
            }
        }
        else if (srw_req->query_type == Z_SRW_query_type_pqf)
        {
            Z_RPNQuery *RPNquery;
            YAZ_PQF_Parser pqf_parser;
            
            pqf_parser = yaz_pqf_create ();
            
            RPNquery = yaz_pqf_parse (pqf_parser, assoc->decode,
                                      srw_req->query.pqf);
            if (!RPNquery)
            {
                const char *pqf_msg;
                size_t off;
                int code = yaz_pqf_error (pqf_parser, &pqf_msg, &off);
                yaz_log(log_requestdetail, "Parse error %d %s near offset %ld",
                        code, pqf_msg, (long) off);
                srw_error = YAZ_SRW_QUERY_SYNTAX_ERROR;
            }
            
            rr.query->which = Z_Query_type_1;
            rr.query->u.type_1 =  RPNquery;
            
            yaz_pqf_destroy (pqf_parser);
        }
        else
        {
            yaz_add_srw_diagnostic(assoc->encode, &srw_res->diagnostics,
                                   &srw_res->num_diagnostics,
                                   YAZ_SRW_UNSUPP_QUERY_TYPE, 0);
        }
        if (rr.query->u.type_1)
        {
            rr.stream = assoc->encode;
            rr.decode = assoc->decode;
            rr.print = assoc->print;
            rr.request = req;
            if ( srw_req->sort.sortKeys )
                rr.srw_sortKeys = odr_strdup(assoc->encode, 
                                             srw_req->sort.sortKeys );
            rr.association = assoc;
            rr.fd = 0;
            rr.hits = 0;
            rr.errcode = 0;
            rr.errstring = 0;
            rr.search_info = 0;
            yaz_log_zquery_level(log_requestdetail,rr.query);
            
            (assoc->init->bend_search)(assoc->backend, &rr);
            if (rr.errcode)
            {
                if (rr.errcode == YAZ_BIB1_DATABASE_UNAVAILABLE)
                {
                    *http_code = 404;
                }
                else
                {
                    srw_error = yaz_diag_bib1_to_srw (rr.errcode);
                    yaz_add_srw_diagnostic(assoc->encode,
                                           &srw_res->diagnostics,
                                           &srw_res->num_diagnostics,
                                           srw_error, rr.errstring);
                }
            }
            else
            {
                int number = srw_req->maximumRecords ? *srw_req->maximumRecords : 0;
                int start = srw_req->startRecord ? *srw_req->startRecord : 1;
                
                yaz_log(log_requestdetail, "Request to pack %d+%d out of %d",
                        start, number, rr.hits);
                
                srw_res->numberOfRecords = odr_intdup(assoc->encode, rr.hits);
		if (rr.srw_setname)
                {
                    srw_res->resultSetId =
                        odr_strdup(assoc->encode, rr.srw_setname );
                    srw_res->resultSetIdleTime =
                        odr_intdup(assoc->encode, *rr.srw_setnameIdleTime );
		}
                
                if ((rr.hits > 0 && start > rr.hits) || start < 1)
                {
                    yaz_add_srw_diagnostic(
                        assoc->encode, 
                        &srw_res->diagnostics, &srw_res->num_diagnostics,
                        YAZ_SRW_FIRST_RECORD_POSITION_OUT_OF_RANGE, 0);
                }
                else if (number > 0)
                {
                    int i;
                    int ok = 1;
                    if (start + number > rr.hits)
                        number = rr.hits - start + 1;
                    
                    /* Call bend_present if defined */
                    if (assoc->init->bend_present)
                    {
                        bend_present_rr *bprr = (bend_present_rr*)
                            odr_malloc (assoc->decode, sizeof(*bprr));
                        bprr->setname = "default";
                        bprr->start = start;
                        bprr->number = number;
                        bprr->format = VAL_TEXT_XML;
                        if (srw_req->recordSchema)
                        {
                            bprr->comp = (Z_RecordComposition *) odr_malloc(assoc->decode,
                                                                            sizeof(*bprr->comp));
                            bprr->comp->which = Z_RecordComp_simple;
                            bprr->comp->u.simple = (Z_ElementSetNames *)
                                odr_malloc(assoc->decode, sizeof(Z_ElementSetNames));
                            bprr->comp->u.simple->which = Z_ElementSetNames_generic;
                            bprr->comp->u.simple->u.generic = srw_req->recordSchema;
                        }
                        else
                        {
                            bprr->comp = 0;
                        }
                        bprr->stream = assoc->encode;
                        bprr->referenceId = 0;
                        bprr->print = assoc->print;
                        bprr->request = req;
                        bprr->association = assoc;
                        bprr->errcode = 0;
                        bprr->errstring = NULL;
                        (*assoc->init->bend_present)(assoc->backend, bprr);
                        
                        if (!bprr->request)
                            return;
                        if (bprr->errcode)
                        {
                            srw_error = yaz_diag_bib1_to_srw (bprr->errcode);
                            yaz_add_srw_diagnostic(assoc->encode,
                                                   &srw_res->diagnostics,
                                                   &srw_res->num_diagnostics,
                                                   srw_error, bprr->errstring);
                            ok = 0;
                        }
                    }
                    
                    if (ok)
                    {
                        int j = 0;
                        int packing = Z_SRW_recordPacking_string;
                        if (srw_req->recordPacking)
                        {
                            packing = 
                                yaz_srw_str_to_pack(srw_req->recordPacking);
                            if (packing == -1)
                                packing = Z_SRW_recordPacking_string;
                        }
                        srw_res->records = (Z_SRW_record *)
                            odr_malloc(assoc->encode,
                                       number * sizeof(*srw_res->records));
                        
                        srw_res->extra_records = (Z_SRW_extra_record **)
                            odr_malloc(assoc->encode,
                                       number*sizeof(*srw_res->extra_records));

                        for (i = 0; i<number; i++)
                        {
                            int errcode;
                            const char *addinfo = 0;
                            
                            srw_res->records[j].recordPacking = packing;
                            srw_res->records[j].recordData_buf = 0;
                            srw_res->extra_records[j] = 0;
                            yaz_log(YLOG_DEBUG, "srw_bend_fetch %d", i+start);
                            errcode = srw_bend_fetch(assoc, i+start, srw_req,
                                                     srw_res->records + j,
                                                     &addinfo);
                            if (errcode)
                            {
                                yaz_add_srw_diagnostic(assoc->encode,
                                                       &srw_res->diagnostics,
                                                       &srw_res->num_diagnostics,
                                                       yaz_diag_bib1_to_srw (errcode),
                                                       addinfo);
                                
                                break;
                            }
                            if (srw_res->records[j].recordData_buf)
                                j++;
                        }
                        srw_res->num_records = j;
                        if (!j)
                            srw_res->records = 0;
                    }
                }
                if (rr.estimated_hit_count || rr.partial_resultset)
                {
                    yaz_add_srw_diagnostic(
                        assoc->encode,
                        &srw_res->diagnostics,
                        &srw_res->num_diagnostics,
                        YAZ_SRW_RESULT_SET_CREATED_WITH_VALID_PARTIAL_RESULTS_AVAILABLE,
                        0);
                }
            }
        }
    }
    if (log_request)
    {
        const char *querystr = "?";
        const char *querytype = "?";
        WRBUF wr = wrbuf_alloc();

        switch (srw_req->query_type)
        {
        case Z_SRW_query_type_cql:
            querytype = "CQL";
            querystr = srw_req->query.cql;
            break;
        case Z_SRW_query_type_pqf:
            querytype = "PQF";
            querystr = srw_req->query.pqf;
            break;
        }
        wrbuf_printf(wr, "SRWSearch ");
        wrbuf_printf(wr, srw_req->database);
        wrbuf_printf(wr, " ");
        if (srw_res->num_diagnostics)
            wrbuf_printf(wr, "ERROR %s", srw_res->diagnostics[0].uri);
        else if (*http_code != 200)
            wrbuf_printf(wr, "ERROR info:http/%d", *http_code);
        else if (srw_res->numberOfRecords)
        {
            wrbuf_printf(wr, "OK %d",
                         (srw_res->numberOfRecords ?
                          *srw_res->numberOfRecords : 0));
        }
        wrbuf_printf(wr, " %s %d+%d", 
                     (srw_res->resultSetId ?
                      srw_res->resultSetId : "-"),
                     (srw_req->startRecord ? *srw_req->startRecord : 1), 
                     srw_res->num_records);
        yaz_log(log_request, "%s %s: %s", wrbuf_buf(wr), querytype, querystr);
        wrbuf_free(wr, 1);
    }
}

static char *srw_bend_explain_default(void *handle, bend_explain_rr *rr)
{
#if YAZ_HAVE_XML2
    xmlNodePtr ptr = rr->server_node_ptr;
    if (!ptr)
        return 0;
    for (ptr = ptr->children; ptr; ptr = ptr->next)
    {
        if (ptr->type != XML_ELEMENT_NODE)
            continue;
        if (!strcmp((const char *) ptr->name, "explain"))
        {
            int len;
            xmlDocPtr doc = xmlNewDoc(BAD_CAST "1.0");
            xmlChar *buf_out;
            char *content;

            ptr = xmlCopyNode(ptr, 1);
        
            xmlDocSetRootElement(doc, ptr);
            
            xmlDocDumpMemory(doc, &buf_out, &len);
            content = (char*) odr_malloc(rr->stream, 1+len);
            memcpy(content, buf_out, len);
            content[len] = '\0';
            
            xmlFree(buf_out);
            xmlFreeDoc(doc);
            rr->explain_buf = content;
            return 0;
        }
    }
#endif
    return 0;
}

static void srw_bend_explain(association *assoc, request *req,
                             Z_SRW_PDU *sr,
                             Z_SRW_explainResponse *srw_res,
                             int *http_code)
{
    Z_SRW_explainRequest *srw_req = sr->u.explain_request;
    yaz_log(log_requestdetail, "Got SRW ExplainRequest");
    *http_code = 404;
    srw_bend_init(assoc, &srw_res->diagnostics, &srw_res->num_diagnostics, sr);
    if (assoc->init)
    {
        bend_explain_rr rr;
        
        rr.stream = assoc->encode;
        rr.decode = assoc->decode;
        rr.print = assoc->print;
        rr.explain_buf = 0;
        rr.database = srw_req->database;
        if (assoc->server)
            rr.server_node_ptr = assoc->server->server_node_ptr;
        else
            rr.server_node_ptr = 0;
        rr.schema = "http://explain.z3950.org/dtd/2.0/";
        if (assoc->init->bend_explain)
            (*assoc->init->bend_explain)(assoc->backend, &rr);
        else
            srw_bend_explain_default(assoc->backend, &rr);

        if (rr.explain_buf)
        {
            int packing = Z_SRW_recordPacking_string;
            if (srw_req->recordPacking)
            {
                packing = 
                    yaz_srw_str_to_pack(srw_req->recordPacking);
                if (packing == -1)
                    packing = Z_SRW_recordPacking_string;
            }
            srw_res->record.recordSchema = rr.schema;
            srw_res->record.recordPacking = packing;
            srw_res->record.recordData_buf = rr.explain_buf;
            srw_res->record.recordData_len = strlen(rr.explain_buf);
            srw_res->record.recordPosition = 0;
            *http_code = 200;
        }
    }
}

static void srw_bend_scan(association *assoc, request *req,
                          Z_SRW_PDU *sr,
                          Z_SRW_scanResponse *srw_res,
                          int *http_code)
{
    Z_SRW_scanRequest *srw_req = sr->u.scan_request;
    yaz_log(log_requestdetail, "Got SRW ScanRequest");

    *http_code = 200;
    srw_bend_init(assoc, &srw_res->diagnostics, &srw_res->num_diagnostics, sr);
    if (srw_res->num_diagnostics == 0 && assoc->init)
    {
        struct scan_entry *save_entries;

        bend_scan_rr *bsrr = (bend_scan_rr *)
            odr_malloc (assoc->encode, sizeof(*bsrr));
        bsrr->num_bases = 1;
        bsrr->basenames = &srw_req->database;

        bsrr->num_entries = srw_req->maximumTerms ?
            *srw_req->maximumTerms : 10;
        bsrr->term_position = srw_req->responsePosition ?
            *srw_req->responsePosition : 1;

        bsrr->errcode = 0;
        bsrr->errstring = 0;
        bsrr->referenceId = 0;
        bsrr->stream = assoc->encode;
        bsrr->print = assoc->print;
        bsrr->step_size = odr_intdup(assoc->decode, 0);
        bsrr->entries = 0;

        if (bsrr->num_entries > 0) 
        {
            int i;
            bsrr->entries = odr_malloc(assoc->decode, sizeof(*bsrr->entries) *
                                       bsrr->num_entries);
            for (i = 0; i<bsrr->num_entries; i++)
            {
                bsrr->entries[i].term = 0;
                bsrr->entries[i].occurrences = 0;
                bsrr->entries[i].errcode = 0;
                bsrr->entries[i].errstring = 0;
                bsrr->entries[i].display_term = 0;
            }
        }
        save_entries = bsrr->entries;  /* save it so we can compare later */

        if (srw_req->query_type == Z_SRW_query_type_pqf &&
            assoc->init->bend_scan)
        {
            Odr_oid *scan_attributeSet = 0;
            oident *attset;
            YAZ_PQF_Parser pqf_parser = yaz_pqf_create();
            
            bsrr->term = yaz_pqf_scan(pqf_parser, assoc->decode,
                                      &scan_attributeSet, 
                                      srw_req->scanClause.pqf); 
            if (scan_attributeSet &&
                (attset = oid_getentbyoid(scan_attributeSet)) &&
                (attset->oclass == CLASS_ATTSET ||
                 attset->oclass == CLASS_GENERAL))
                bsrr->attributeset = attset->value;
            else
                bsrr->attributeset = VAL_NONE;
            yaz_pqf_destroy(pqf_parser);
            bsrr->scanClause = 0;
            ((int (*)(void *, bend_scan_rr *))
             (*assoc->init->bend_scan))(assoc->backend, bsrr);
        }
        else if (srw_req->query_type == Z_SRW_query_type_cql
                 && assoc->init->bend_scan && assoc->server
                 && assoc->server->cql_transform)
        {
            int srw_error;
            bsrr->scanClause = 0;
            bsrr->attributeset = VAL_NONE;
            bsrr->term = odr_malloc(assoc->decode, sizeof(*bsrr->term));
            srw_error = cql2pqf_scan(assoc->encode,
                                     srw_req->scanClause.cql,
                                     assoc->server->cql_transform,
                                     bsrr->term);
            if (srw_error)
                yaz_add_srw_diagnostic(assoc->encode, &srw_res->diagnostics,
                                       &srw_res->num_diagnostics,
                                       srw_error, 0);
            else
            {
                ((int (*)(void *, bend_scan_rr *))
                 (*assoc->init->bend_scan))(assoc->backend, bsrr);
            }
        }
        else if (srw_req->query_type == Z_SRW_query_type_cql
                 && assoc->init->bend_srw_scan)
        {
            bsrr->term = 0;
            bsrr->attributeset = VAL_NONE;
            bsrr->scanClause = srw_req->scanClause.cql;
            ((int (*)(void *, bend_scan_rr *))
             (*assoc->init->bend_srw_scan))(assoc->backend, bsrr);
        }
        else
        {
            yaz_add_srw_diagnostic(assoc->encode, &srw_res->diagnostics,
                                   &srw_res->num_diagnostics,
                                   YAZ_SRW_UNSUPP_OPERATION, "scan");
        }
        if (bsrr->errcode)
        {
            int srw_error;
            if (bsrr->errcode == YAZ_BIB1_DATABASE_UNAVAILABLE)
            {
                *http_code = 404;
                return;
            }
            srw_error = yaz_diag_bib1_to_srw (bsrr->errcode);

            yaz_add_srw_diagnostic(assoc->encode, &srw_res->diagnostics,
                                   &srw_res->num_diagnostics,
                                   srw_error, bsrr->errstring);
        }
        else if (srw_res->num_diagnostics == 0 && bsrr->num_entries)
        {
            int i;
            srw_res->terms = (Z_SRW_scanTerm*)
                odr_malloc(assoc->encode, sizeof(*srw_res->terms) *
                           bsrr->num_entries);

            srw_res->num_terms =  bsrr->num_entries;
            for (i = 0; i<bsrr->num_entries; i++)
            {
                Z_SRW_scanTerm *t = srw_res->terms + i;
                t->value = odr_strdup(assoc->encode, bsrr->entries[i].term);
                t->numberOfRecords =
                    odr_intdup(assoc->encode, bsrr->entries[i].occurrences);
                t->displayTerm = 0;
                if (save_entries == bsrr->entries && 
                    bsrr->entries[i].display_term)
                {
                    /* the entries was _not_ set by the handler. So it's
                       safe to test for new member display_term. It is
                       NULL'ed by us.
                    */
                    t->displayTerm = odr_strdup(assoc->encode, 
                                                bsrr->entries[i].display_term);
                }
                t->whereInList = 0;
            }
        }
    }
    if (log_request)
    {
        WRBUF wr = wrbuf_alloc();
        const char *querytype = 0;
        const char *querystr = 0;

        switch(srw_req->query_type)
        {
        case Z_SRW_query_type_pqf:
            querytype = "PQF";
            querystr = srw_req->scanClause.pqf;
            break;
        case Z_SRW_query_type_cql:
            querytype = "CQL";
            querystr = srw_req->scanClause.cql;
            break;
        default:
            querytype = "UNKNOWN";
            querystr = "";
        }

        wrbuf_printf(wr, "SRWScan ");
        wrbuf_printf(wr, srw_req->database);
        wrbuf_printf(wr, " ");

        if (srw_res->num_diagnostics)
            wrbuf_printf(wr, "ERROR %s - ", srw_res->diagnostics[0].uri);
        else if (srw_res->num_terms)
            wrbuf_printf(wr, "OK %d - ", srw_res->num_terms);
        else
            wrbuf_printf(wr, "OK - - ");

        wrbuf_printf(wr, "%d+%d+0 ",
                     (srw_req->responsePosition ? 
                      *srw_req->responsePosition : 1),
                     (srw_req->maximumTerms ?
                      *srw_req->maximumTerms : 1));
        /* there is no step size in SRU/W ??? */
        wrbuf_printf(wr, "%s: %s ", querytype, querystr);
        yaz_log(log_request, "%s ", wrbuf_buf(wr) );
        wrbuf_free(wr, 1);
    }

}

static void srw_bend_update(association *assoc, request *req,
			    Z_SRW_PDU *sr,
			    Z_SRW_updateResponse *srw_res,
			    int *http_code)
{
    Z_SRW_updateRequest *srw_req = sr->u.update_request;
    yaz_log(log_session, "SRWUpdate action=%s", srw_req->operation);
    yaz_log(YLOG_DEBUG, "num_diag = %d", srw_res->num_diagnostics );
    *http_code = 404;
    srw_bend_init(assoc, &srw_res->diagnostics, &srw_res->num_diagnostics, sr);
    if (assoc->init)
    {
	bend_update_rr rr;
        Z_SRW_extra_record *extra = srw_req->extra_record;
	
	rr.stream = assoc->encode;
	rr.print = assoc->print;
        rr.num_bases = 1;
        rr.basenames = &srw_req->database;
	rr.operation = srw_req->operation;
	rr.operation_status = "failed";
	rr.record_id = 0;
        rr.record_versions = 0;
        rr.num_versions = 0;
        rr.record_packing = "string";
	rr.record_schema = 0;
        rr.record_data = 0;
        rr.extra_record_data = 0;
        rr.extra_request_data = 0;
        rr.extra_response_data = 0;
        rr.uri = 0;
        rr.message = 0;
        rr.details = 0;
        
	*http_code = 200;
        if (rr.operation == 0)
        {
            yaz_add_sru_update_diagnostic(
                assoc->encode, &srw_res->diagnostics,
                &srw_res->num_diagnostics,
                YAZ_SRU_UPDATE_MISSING_MANDATORY_ELEMENT_RECORD_REJECTED,
                "action" );
            return;
        }
        yaz_log(YLOG_DEBUG, "basename = %s", rr.basenames[0] );
        yaz_log(YLOG_DEBUG, "Operation = %s", rr.operation );
	if (!strcmp( rr.operation, "delete"))
        {
            if (srw_req->record && !srw_req->record->recordSchema)
            {
                rr.record_schema = odr_strdup(
                    assoc->encode,
                    srw_req->record->recordSchema);
            }
            if (srw_req->record)
            {
                rr.record_data = odr_strdupn(
                    assoc->encode, 
                    srw_req->record->recordData_buf,
                    srw_req->record->recordData_len );
            }
            if (extra && extra->extraRecordData_len)
            {
                rr.extra_record_data = odr_strdupn(
                    assoc->encode, 
                    extra->extraRecordData_buf,
                    extra->extraRecordData_len );
            }
            if (srw_req->recordId)
                rr.record_id = srw_req->recordId;
            else if (extra && extra->recordIdentifier)
                rr.record_id = extra->recordIdentifier;
	}
	else if (!strcmp(rr.operation, "replace"))
        {
            if (srw_req->recordId)
                rr.record_id = srw_req->recordId;
            else if (extra && extra->recordIdentifier)
                rr.record_id = extra->recordIdentifier;
            else 
            {
                yaz_add_sru_update_diagnostic(
                    assoc->encode, &srw_res->diagnostics,
                    &srw_res->num_diagnostics,
                    YAZ_SRU_UPDATE_MISSING_MANDATORY_ELEMENT_RECORD_REJECTED,
                    "recordIdentifier");
            }
            if (!srw_req->record)
            {
                yaz_add_sru_update_diagnostic(
                    assoc->encode, &srw_res->diagnostics,
                    &srw_res->num_diagnostics,
                    YAZ_SRU_UPDATE_MISSING_MANDATORY_ELEMENT_RECORD_REJECTED,
                    "record");
            }
            else 
            {
                if (srw_req->record->recordSchema)
                    rr.record_schema = odr_strdup(
                        assoc->encode, srw_req->record->recordSchema);
                if (srw_req->record->recordData_len )
                {
                    rr.record_data = odr_strdupn(assoc->encode, 
                                                 srw_req->record->recordData_buf,
                                                 srw_req->record->recordData_len );
                }
                else 
                {
                    yaz_add_sru_update_diagnostic(
                        assoc->encode, &srw_res->diagnostics,
                        &srw_res->num_diagnostics,
                        YAZ_SRU_UPDATE_MISSING_MANDATORY_ELEMENT_RECORD_REJECTED,                                              
                        "recordData" );
                }
            }
            if (extra && extra->extraRecordData_len)
            {
                rr.extra_record_data = odr_strdupn(
                    assoc->encode, 
                    extra->extraRecordData_buf,
                    extra->extraRecordData_len );
            }
	}
	else if (!strcmp(rr.operation, "insert"))
        {
            if (srw_req->recordId)
                rr.record_id = srw_req->recordId; 
            else if (extra)
                rr.record_id = extra->recordIdentifier;
            
            if (srw_req->record)
            {
                if (srw_req->record->recordSchema)
                    rr.record_schema = odr_strdup(
                        assoc->encode, srw_req->record->recordSchema);
            
                if (srw_req->record->recordData_len)
                    rr.record_data = odr_strdupn(
                        assoc->encode, 
                        srw_req->record->recordData_buf,
                        srw_req->record->recordData_len );
            }
            if (extra && extra->extraRecordData_len)
            {
                rr.extra_record_data = odr_strdupn(
                    assoc->encode, 
                    extra->extraRecordData_buf,
                    extra->extraRecordData_len );
            }
	}
	else 
            yaz_add_sru_update_diagnostic(assoc->encode, &srw_res->diagnostics,
                                          &srw_res->num_diagnostics,
                                          YAZ_SRU_UPDATE_INVALID_ACTION,
                                          rr.operation );

        if (srw_req->record)
        {
            const char *pack_str = 
                yaz_srw_pack_to_str(srw_req->record->recordPacking);
            if (pack_str)
                rr.record_packing = odr_strdup(assoc->encode, pack_str);
        }

        if (srw_req->num_recordVersions)
        {
            rr.record_versions = srw_req->recordVersions;
            rr.num_versions = srw_req->num_recordVersions;
        }
        if (srw_req->extraRequestData_len)
        {
            rr.extra_request_data = odr_strdupn(assoc->encode,
                                                srw_req->extraRequestData_buf,
                                                srw_req->extraRequestData_len );
        }
        if (srw_res->num_diagnostics == 0)
        {
            if ( assoc->init->bend_srw_update)
                (*assoc->init->bend_srw_update)(assoc->backend, &rr);
            else 
                yaz_add_sru_update_diagnostic(
                    assoc->encode, &srw_res->diagnostics,
                    &srw_res->num_diagnostics,
                    YAZ_SRU_UPDATE_UNSPECIFIED_DATABASE_ERROR,
                    "No Update backend handler");
        }

        if (rr.uri)
            yaz_add_srw_diagnostic_uri(assoc->encode,
                                       &srw_res->diagnostics,
                                       &srw_res->num_diagnostics,
                                       rr.uri, 
                                       rr.message,
                                       rr.details);
	srw_res->recordId = rr.record_id;
	srw_res->operationStatus = rr.operation_status;
	srw_res->recordVersions = rr.record_versions;
	srw_res->num_recordVersions = rr.num_versions;
        if (srw_res->extraResponseData_len)
        {
            srw_res->extraResponseData_buf = rr.extra_response_data;
            srw_res->extraResponseData_len = strlen(rr.extra_response_data);
        }
	if (srw_res->num_diagnostics == 0 && rr.record_data)
        {
            srw_res->record = yaz_srw_get_record(assoc->encode);
            srw_res->record->recordSchema = rr.record_schema;
            if (rr.record_packing)
            {
                int pack = yaz_srw_str_to_pack(rr.record_packing);

                if (pack == -1)
                {
                    pack = Z_SRW_recordPacking_string;
                    yaz_log(YLOG_WARN, "Back packing %s from backend",
                            rr.record_packing);
                }
                srw_res->record->recordPacking = pack;
            }
            srw_res->record->recordData_buf = rr.record_data;
            srw_res->record->recordData_len = strlen(rr.record_data);
            if (rr.extra_record_data)
            {
                Z_SRW_extra_record *ex = 
                    yaz_srw_get_extra_record(assoc->encode);
                srw_res->extra_record = ex;
                ex->extraRecordData_buf = rr.extra_record_data;
                ex->extraRecordData_len = strlen(rr.extra_record_data);
            }
        }
    }
}

/* check if path is OK (1); BAD (0) */
static int check_path(const char *path)
{
    if (*path != '/')
        return 0;
    if (strstr(path, ".."))
        return 0;
    return 1;
}

static char *read_file(const char *fname, ODR o, int *sz)
{
    char *buf;
    FILE *inf = fopen(fname, "rb");
    if (!inf)
        return 0;

    fseek(inf, 0L, SEEK_END);
    *sz = ftell(inf);
    rewind(inf);
    buf = odr_malloc(o, *sz);
    fread(buf, 1, *sz, inf);
    fclose(inf);
    return buf;     
}

static void process_http_request(association *assoc, request *req)
{
    Z_HTTP_Request *hreq = req->gdu_request->u.HTTP_Request;
    ODR o = assoc->encode;
    int r = 2;  /* 2=NOT TAKEN, 1=TAKEN, 0=SOAP TAKEN */
    Z_SRW_PDU *sr = 0;
    Z_SOAP *soap_package = 0;
    Z_GDU *p = 0;
    char *charset = 0;
    Z_HTTP_Response *hres = 0;
    int keepalive = 1;
    const char *stylesheet = 0; /* for now .. set later */
    Z_SRW_diagnostic *diagnostic = 0;
    int num_diagnostic = 0;
    const char *host = z_HTTP_header_lookup(hreq->headers, "Host");

    if (!control_association(assoc, host, 0))
    {
        p = z_get_HTTP_Response(o, 404);
        r = 1;
    }
    if (r == 2 && assoc->server && assoc->server->docpath
        && hreq->path[0] == '/' 
        && 
        /* check if path is a proper prefix of documentroot */
        strncmp(hreq->path+1, assoc->server->docpath,
                strlen(assoc->server->docpath))
        == 0)
    {   
        if (!check_path(hreq->path))
        {
            yaz_log(YLOG_LOG, "File %s access forbidden", hreq->path+1);
            p = z_get_HTTP_Response(o, 404);
        }
        else
        {
            int content_size = 0;
            char *content_buf = read_file(hreq->path+1, o, &content_size);
            if (!content_buf)
            {
                yaz_log(YLOG_LOG, "File %s not found", hreq->path+1);
                p = z_get_HTTP_Response(o, 404);
            }
            else
            {
                const char *ctype = 0;
                yaz_mime_types types = yaz_mime_types_create();
                
                yaz_mime_types_add(types, "xsl", "application/xml");
                yaz_mime_types_add(types, "xml", "application/xml");
                yaz_mime_types_add(types, "css", "text/css");
                yaz_mime_types_add(types, "html", "text/html");
                yaz_mime_types_add(types, "htm", "text/html");
                yaz_mime_types_add(types, "txt", "text/plain");
                yaz_mime_types_add(types, "js", "application/x-javascript");
                
                yaz_mime_types_add(types, "gif", "image/gif");
                yaz_mime_types_add(types, "png", "image/png");
                yaz_mime_types_add(types, "jpg", "image/jpeg");
                yaz_mime_types_add(types, "jpeg", "image/jpeg");
                
                ctype = yaz_mime_lookup_fname(types, hreq->path);
                if (!ctype)
                {
                    yaz_log(YLOG_LOG, "No mime type for %s", hreq->path+1);
                    p = z_get_HTTP_Response(o, 404);
                }
                else
                {
                    p = z_get_HTTP_Response(o, 200);
                    hres = p->u.HTTP_Response;
                    hres->content_buf = content_buf;
                    hres->content_len = content_size;
                    z_HTTP_header_add(o, &hres->headers, "Content-Type", ctype);
                }
                yaz_mime_types_destroy(types);
            }
        }
        r = 1;
    }

    if (r == 2)
    {
        r = yaz_srw_decode(hreq, &sr, &soap_package, assoc->decode, &charset);
        yaz_log(YLOG_DEBUG, "yaz_srw_decode returned %d", r);
    }
    if (r == 2)  /* not taken */
    {
        r = yaz_sru_decode(hreq, &sr, &soap_package, assoc->decode, &charset,
                           &diagnostic, &num_diagnostic);
        yaz_log(YLOG_DEBUG, "yaz_sru_decode returned %d", r);
    }
    if (r == 0)  /* decode SRW/SRU OK .. */
    {
        int http_code = 200;
        if (sr->which == Z_SRW_searchRetrieve_request)
        {
            Z_SRW_PDU *res =
                yaz_srw_get(assoc->encode, Z_SRW_searchRetrieve_response);

            stylesheet = sr->u.request->stylesheet;
            if (num_diagnostic)
            {
                res->u.response->diagnostics = diagnostic;
                res->u.response->num_diagnostics = num_diagnostic;
            }
            else
            {
                srw_bend_search(assoc, req, sr, res->u.response, 
                                &http_code);
            }
            if (http_code == 200)
                soap_package->u.generic->p = res;
        }
        else if (sr->which == Z_SRW_explain_request)
        {
            Z_SRW_PDU *res = yaz_srw_get(o, Z_SRW_explain_response);
            stylesheet = sr->u.explain_request->stylesheet;
            if (num_diagnostic)
            {   
                res->u.explain_response->diagnostics = diagnostic;
                res->u.explain_response->num_diagnostics = num_diagnostic;
            }
            srw_bend_explain(assoc, req, sr,
                             res->u.explain_response, &http_code);
            if (http_code == 200)
                soap_package->u.generic->p = res;
        }
        else if (sr->which == Z_SRW_scan_request)
        {
            Z_SRW_PDU *res = yaz_srw_get(o, Z_SRW_scan_response);
            stylesheet = sr->u.scan_request->stylesheet;
            if (num_diagnostic)
            {   
                res->u.scan_response->diagnostics = diagnostic;
                res->u.scan_response->num_diagnostics = num_diagnostic;
            }
            srw_bend_scan(assoc, req, sr,
                          res->u.scan_response, &http_code);
            if (http_code == 200)
                soap_package->u.generic->p = res;
        }
        else if (sr->which == Z_SRW_update_request)
        {
            Z_SRW_PDU *res = yaz_srw_get(o, Z_SRW_update_response);
            yaz_log(YLOG_DEBUG, "handling SRW UpdateRequest");
            if (num_diagnostic)
            {   
                res->u.update_response->diagnostics = diagnostic;
                res->u.update_response->num_diagnostics = num_diagnostic;
            }
            yaz_log(YLOG_DEBUG, "num_diag = %d", res->u.update_response->num_diagnostics );
            srw_bend_update(assoc, req, sr,
                            res->u.update_response, &http_code);
            if (http_code == 200)
                soap_package->u.generic->p = res;
        }
        else
        {
            yaz_log(log_request, "SOAP ERROR"); 
            /* FIXME - what error, what query */
            http_code = 500;
            z_soap_error(assoc->encode, soap_package,
                         "SOAP-ENV:Client", "Bad method", 0); 
        }
        if (http_code == 200 || http_code == 500)
        {
            static Z_SOAP_Handler soap_handlers[4] = {
#if YAZ_HAVE_XML2
                {YAZ_XMLNS_SRU_v1_1, 0, (Z_SOAP_fun) yaz_srw_codec},
                {YAZ_XMLNS_SRU_v1_0, 0, (Z_SOAP_fun) yaz_srw_codec},
                {YAZ_XMLNS_UPDATE_v0_9, 0, (Z_SOAP_fun) yaz_ucp_codec},
#endif
                {0, 0, 0}
            };
            char ctype[60];
            int ret;
            p = z_get_HTTP_Response(o, 200);
            hres = p->u.HTTP_Response;

            if (!stylesheet && assoc->server)
                stylesheet = assoc->server->stylesheet;

            /* empty stylesheet means NO stylesheet */
            if (stylesheet && *stylesheet == '\0')
                stylesheet = 0;

            ret = z_soap_codec_enc_xsl(assoc->encode, &soap_package,
                                       &hres->content_buf, &hres->content_len,
                                       soap_handlers, charset, stylesheet);
            hres->code = http_code;

            strcpy(ctype, "text/xml");
            if (charset)
            {
                strcat(ctype, "; charset=");
                strcat(ctype, charset);
            }
            z_HTTP_header_add(o, &hres->headers, "Content-Type", ctype);
        }
        else
            p = z_get_HTTP_Response(o, http_code);
    }

    if (p == 0)
        p = z_get_HTTP_Response(o, 500);
    hres = p->u.HTTP_Response;
    if (!strcmp(hreq->version, "1.0")) 
    {
        const char *v = z_HTTP_header_lookup(hreq->headers, "Connection");
        if (v && !strcmp(v, "Keep-Alive"))
            keepalive = 1;
        else
            keepalive = 0;
        hres->version = "1.0";
    }
    else
    {
        const char *v = z_HTTP_header_lookup(hreq->headers, "Connection");
        if (v && !strcmp(v, "close"))
            keepalive = 0;
        else
            keepalive = 1;
        hres->version = "1.1";
    }
    if (!keepalive)
    {
        z_HTTP_header_add(o, &hres->headers, "Connection", "close");
        assoc->state = ASSOC_DEAD;
        assoc->cs_get_mask = 0;
    }
    else
    {
        int t;
        const char *alive = z_HTTP_header_lookup(hreq->headers, "Keep-Alive");

        if (alive && isdigit(*(const unsigned char *) alive))
            t = atoi(alive);
        else
            t = 15;
        if (t < 0 || t > 3600)
            t = 3600;
        iochan_settimeout(assoc->client_chan,t);
        z_HTTP_header_add(o, &hres->headers, "Connection", "Keep-Alive");
    }
    process_gdu_response(assoc, req, p);
}

static void process_gdu_request(association *assoc, request *req)
{
    if (req->gdu_request->which == Z_GDU_Z3950)
    {
        char *msg = 0;
        req->apdu_request = req->gdu_request->u.z3950;
        if (process_z_request(assoc, req, &msg) < 0)
            do_close_req(assoc, Z_Close_systemProblem, msg, req);
    }
    else if (req->gdu_request->which == Z_GDU_HTTP_Request)
        process_http_request(assoc, req);
    else
    {
        do_close_req(assoc, Z_Close_systemProblem, "bad protocol packet", req);
    }
}

/*
 * Initiate request processing.
 */
static int process_z_request(association *assoc, request *req, char **msg)
{
    int fd = -1;
    Z_APDU *res;
    int retval;
    
    *msg = "Unknown Error";
    assert(req && req->state == REQUEST_IDLE);
    if (req->apdu_request->which != Z_APDU_initRequest && !assoc->init)
    {
        *msg = "Missing InitRequest";
        return -1;
    }
    switch (req->apdu_request->which)
    {
    case Z_APDU_initRequest:
        res = process_initRequest(assoc, req); break;
    case Z_APDU_searchRequest:
        res = process_searchRequest(assoc, req, &fd); break;
    case Z_APDU_presentRequest:
        res = process_presentRequest(assoc, req, &fd); break;
    case Z_APDU_scanRequest:
        if (assoc->init->bend_scan)
            res = process_scanRequest(assoc, req, &fd);
        else
        {
            *msg = "Cannot handle Scan APDU";
            return -1;
        }
        break;
    case Z_APDU_extendedServicesRequest:
        if (assoc->init->bend_esrequest)
            res = process_ESRequest(assoc, req, &fd);
        else
        {
            *msg = "Cannot handle Extended Services APDU";
            return -1;
        }
        break;
    case Z_APDU_sortRequest:
        if (assoc->init->bend_sort)
            res = process_sortRequest(assoc, req, &fd);
        else
        {
            *msg = "Cannot handle Sort APDU";
            return -1;
        }
        break;
    case Z_APDU_close:
        process_close(assoc, req);
        return 0;
    case Z_APDU_deleteResultSetRequest:
        if (assoc->init->bend_delete)
            res = process_deleteRequest(assoc, req, &fd);
        else
        {
            *msg = "Cannot handle Delete APDU";
            return -1;
        }
        break;
    case Z_APDU_segmentRequest:
        if (assoc->init->bend_segment)
        {
            res = process_segmentRequest (assoc, req);
        }
        else
        {
            *msg = "Cannot handle Segment APDU";
            return -1;
        }
        break;
    case Z_APDU_triggerResourceControlRequest:
        return 0;
    default:
        *msg = "Bad APDU received";
        return -1;
    }
    if (res)
    {
        yaz_log(YLOG_DEBUG, "  result immediately available");
        retval = process_z_response(assoc, req, res);
    }
    else if (fd < 0)
    {
        yaz_log(YLOG_DEBUG, "  result unavailble");
        retval = 0;
    }
    else /* no result yet - one will be provided later */
    {
        IOCHAN chan;

        /* Set up an I/O handler for the fd supplied by the backend */

        yaz_log(YLOG_DEBUG, "   establishing handler for result");
        req->state = REQUEST_PENDING;
        if (!(chan = iochan_create(fd, backend_response, EVENT_INPUT, 0)))
            abort();
        iochan_setdata(chan, assoc);
        retval = 0;
    }
    return retval;
}

/*
 * Handle message from the backend.
 */
void backend_response(IOCHAN i, int event)
{
    association *assoc = (association *)iochan_getdata(i);
    request *req = request_head(&assoc->incoming);
    Z_APDU *res;
    int fd;

    yaz_log(YLOG_DEBUG, "backend_response");
    assert(assoc && req && req->state != REQUEST_IDLE);
    /* determine what it is we're waiting for */
    switch (req->apdu_request->which)
    {
        case Z_APDU_searchRequest:
            res = response_searchRequest(assoc, req, 0, &fd); break;
#if 0
        case Z_APDU_presentRequest:
            res = response_presentRequest(assoc, req, 0, &fd); break;
        case Z_APDU_scanRequest:
            res = response_scanRequest(assoc, req, 0, &fd); break;
#endif
        default:
            yaz_log(YLOG_FATAL, "Serious programmer's lapse or bug");
            abort();
    }
    if ((res && process_z_response(assoc, req, res) < 0) || fd < 0)
    {
        yaz_log(YLOG_WARN, "Fatal error when talking to backend");
        do_close(assoc, Z_Close_systemProblem, 0);
        iochan_destroy(i);
        return;
    }
    else if (!res) /* no result yet - try again later */
    {
        yaz_log(YLOG_DEBUG, "   no result yet");
        iochan_setfd(i, fd); /* in case fd has changed */
    }
}

/*
 * Encode response, and transfer the request structure to the outgoing queue.
 */
static int process_gdu_response(association *assoc, request *req, Z_GDU *res)
{
    odr_setbuf(assoc->encode, req->response, req->size_response, 1);

    if (assoc->print)
    {
        if (!z_GDU(assoc->print, &res, 0, 0))
            yaz_log(YLOG_WARN, "ODR print error: %s", 
                odr_errmsg(odr_geterror(assoc->print)));
        odr_reset(assoc->print);
    }
    if (!z_GDU(assoc->encode, &res, 0, 0))
    {
        yaz_log(YLOG_WARN, "ODR error when encoding PDU: %s [element %s]",
                odr_errmsg(odr_geterror(assoc->decode)),
                odr_getelement(assoc->decode));
        return -1;
    }
    req->response = odr_getbuf(assoc->encode, &req->len_response,
        &req->size_response);
    odr_setbuf(assoc->encode, 0, 0, 0); /* don'txfree if we abort later */
    odr_reset(assoc->encode);
    req->state = REQUEST_IDLE;
    request_enq(&assoc->outgoing, req);
    /* turn the work over to the ir_session handler */
    iochan_setflag(assoc->client_chan, EVENT_OUTPUT);
    assoc->cs_put_mask = EVENT_OUTPUT;
    /* Is there more work to be done? give that to the input handler too */
    for (;;)
    {
        req = request_head(&assoc->incoming);
        if (req && req->state == REQUEST_IDLE)
        {
            request_deq(&assoc->incoming);
            process_gdu_request(assoc, req);
        }
        else
            break;
    }
    return 0;
}

/*
 * Encode response, and transfer the request structure to the outgoing queue.
 */
static int process_z_response(association *assoc, request *req, Z_APDU *res)
{
    Z_GDU *gres = (Z_GDU *) odr_malloc(assoc->encode, sizeof(*res));
    gres->which = Z_GDU_Z3950;
    gres->u.z3950 = res;

    return process_gdu_response(assoc, req, gres);
}

static char *get_vhost(Z_OtherInformation *otherInfo)
{
    return yaz_oi_get_string_oidval(&otherInfo, VAL_PROXY, 1, 0);
}

/*
 * Handle init request.
 * At the moment, we don't check the options
 * anywhere else in the code - we just try not to do anything that would
 * break a naive client. We'll toss 'em into the association block when
 * we need them there.
 */
static Z_APDU *process_initRequest(association *assoc, request *reqb)
{
    Z_InitRequest *req = reqb->apdu_request->u.initRequest;
    Z_APDU *apdu = zget_APDU(assoc->encode, Z_APDU_initResponse);
    Z_InitResponse *resp = apdu->u.initResponse;
    bend_initresult *binitres;
    char *version;
    char options[140];
    statserv_options_block *cb = 0;  /* by default no control for backend */

    if (control_association(assoc, get_vhost(req->otherInfo), 1))
        cb = statserv_getcontrol();  /* got control block for backend */

    if (cb && assoc->backend)
        (*cb->bend_close)(assoc->backend);

    yaz_log(log_requestdetail, "Got initRequest");
    if (req->implementationId)
        yaz_log(log_requestdetail, "Id:        %s",
                req->implementationId);
    if (req->implementationName)
        yaz_log(log_requestdetail, "Name:      %s",
                req->implementationName);
    if (req->implementationVersion)
        yaz_log(log_requestdetail, "Version:   %s",
                req->implementationVersion);
    
    assoc_init_reset(assoc);

    assoc->init->auth = req->idAuthentication;
    assoc->init->referenceId = req->referenceId;

    if (ODR_MASK_GET(req->options, Z_Options_negotiationModel))
    {
        Z_CharSetandLanguageNegotiation *negotiation =
            yaz_get_charneg_record (req->otherInfo);
        if (negotiation &&
            negotiation->which == Z_CharSetandLanguageNegotiation_proposal)
            assoc->init->charneg_request = negotiation;
    }

    assoc->backend = 0;
    if (cb)
    {
        if (req->implementationVersion)
            yaz_log(log_requestdetail, "Config:    %s",
                    cb->configname);
    
        iochan_settimeout(assoc->client_chan, cb->idle_timeout * 60);
        
        /* we have a backend control block, so call that init function */
        if (!(binitres = (*cb->bend_init)(assoc->init)))
        {
            yaz_log(YLOG_WARN, "Bad response from backend.");
            return 0;
        }
        assoc->backend = binitres->handle;
    }
    else
    {
        /* no backend. return error */
        binitres = odr_malloc(assoc->encode, sizeof(*binitres));
        binitres->errstring = 0;
        binitres->errcode = YAZ_BIB1_PERMANENT_SYSTEM_ERROR;
        iochan_settimeout(assoc->client_chan, 10);
    }
    if ((assoc->init->bend_sort))
        yaz_log (YLOG_DEBUG, "Sort handler installed");
    if ((assoc->init->bend_search))
        yaz_log (YLOG_DEBUG, "Search handler installed");
    if ((assoc->init->bend_present))
        yaz_log (YLOG_DEBUG, "Present handler installed");   
    if ((assoc->init->bend_esrequest))
        yaz_log (YLOG_DEBUG, "ESRequest handler installed");   
    if ((assoc->init->bend_delete))
        yaz_log (YLOG_DEBUG, "Delete handler installed");   
    if ((assoc->init->bend_scan))
        yaz_log (YLOG_DEBUG, "Scan handler installed");   
    if ((assoc->init->bend_segment))
        yaz_log (YLOG_DEBUG, "Segment handler installed");   
    
    resp->referenceId = req->referenceId;
    *options = '\0';
    /* let's tell the client what we can do */
    if (ODR_MASK_GET(req->options, Z_Options_search))
    {
        ODR_MASK_SET(resp->options, Z_Options_search);
        strcat(options, "srch");
    }
    if (ODR_MASK_GET(req->options, Z_Options_present))
    {
        ODR_MASK_SET(resp->options, Z_Options_present);
        strcat(options, " prst");
    }
    if (ODR_MASK_GET(req->options, Z_Options_delSet) &&
        assoc->init->bend_delete)
    {
        ODR_MASK_SET(resp->options, Z_Options_delSet);
        strcat(options, " del");
    }
    if (ODR_MASK_GET(req->options, Z_Options_extendedServices) &&
        assoc->init->bend_esrequest)
    {
        ODR_MASK_SET(resp->options, Z_Options_extendedServices);
        strcat (options, " extendedServices");
    }
    if (ODR_MASK_GET(req->options, Z_Options_namedResultSets))
    {
        ODR_MASK_SET(resp->options, Z_Options_namedResultSets);
        strcat(options, " namedresults");
    }
    if (ODR_MASK_GET(req->options, Z_Options_scan) && assoc->init->bend_scan)
    {
        ODR_MASK_SET(resp->options, Z_Options_scan);
        strcat(options, " scan");
    }
    if (ODR_MASK_GET(req->options, Z_Options_concurrentOperations))
    {
        ODR_MASK_SET(resp->options, Z_Options_concurrentOperations);
        strcat(options, " concurrop");
    }
    if (ODR_MASK_GET(req->options, Z_Options_sort) && assoc->init->bend_sort)
    {
        ODR_MASK_SET(resp->options, Z_Options_sort);
        strcat(options, " sort");
    }

    if (ODR_MASK_GET(req->options, Z_Options_negotiationModel)
        && assoc->init->charneg_response)
    {
        Z_OtherInformation **p;
        Z_OtherInformationUnit *p0;
        
        yaz_oi_APDU(apdu, &p);
        
        if ((p0=yaz_oi_update(p, assoc->encode, NULL, 0, 0))) {
            ODR_MASK_SET(resp->options, Z_Options_negotiationModel);
            
            p0->which = Z_OtherInfo_externallyDefinedInfo;
            p0->information.externallyDefinedInfo =
                assoc->init->charneg_response;
        }
        ODR_MASK_SET(resp->options, Z_Options_negotiationModel);
        strcat(options, " negotiation");
    }
        
    if (ODR_MASK_GET(req->options, Z_Options_triggerResourceCtrl))
        ODR_MASK_SET(resp->options, Z_Options_triggerResourceCtrl);

    if (ODR_MASK_GET(req->protocolVersion, Z_ProtocolVersion_1))
    {
        ODR_MASK_SET(resp->protocolVersion, Z_ProtocolVersion_1);
        assoc->version = 1; /* 1 & 2 are equivalent */
    }
    if (ODR_MASK_GET(req->protocolVersion, Z_ProtocolVersion_2))
    {
        ODR_MASK_SET(resp->protocolVersion, Z_ProtocolVersion_2);
        assoc->version = 2;
    }
    if (ODR_MASK_GET(req->protocolVersion, Z_ProtocolVersion_3))
    {
        ODR_MASK_SET(resp->protocolVersion, Z_ProtocolVersion_3);
        assoc->version = 3;
    }

    yaz_log(log_requestdetail, "Negotiated to v%d: %s", assoc->version, options);

    if (*req->maximumRecordSize < assoc->maximumRecordSize)
        assoc->maximumRecordSize = *req->maximumRecordSize;

    if (*req->preferredMessageSize < assoc->preferredMessageSize)
        assoc->preferredMessageSize = *req->preferredMessageSize;

    resp->preferredMessageSize = &assoc->preferredMessageSize;
    resp->maximumRecordSize = &assoc->maximumRecordSize;

    resp->implementationId = odr_prepend(assoc->encode,
                assoc->init->implementation_id,
                resp->implementationId);

    resp->implementationName = odr_prepend(assoc->encode,
                assoc->init->implementation_name,
                odr_prepend(assoc->encode, "GFS", resp->implementationName));

    version = odr_strdup(assoc->encode, "$Revision: 1.109 $");
    if (strlen(version) > 10)   /* check for unexpanded CVS strings */
        version[strlen(version)-2] = '\0';
    resp->implementationVersion = odr_prepend(assoc->encode,
                assoc->init->implementation_version,
                odr_prepend(assoc->encode, &version[11],
                            resp->implementationVersion));

    if (binitres->errcode)
    {
        assoc->state = ASSOC_DEAD;
        resp->userInformationField =
            init_diagnostics(assoc->encode, binitres->errcode,
                             binitres->errstring);
        *resp->result = 0;
    }
    if (log_request)
    {
        if (!req->idAuthentication)
            yaz_log(log_request, "Auth none");
        else if (req->idAuthentication->which == Z_IdAuthentication_open)
        {
            const char *open = req->idAuthentication->u.open;
            const char *slash = strchr(open, '/');
            int len;
            if (slash)
                len = slash - open;
            else
                len = strlen(open);
                yaz_log(log_request, "Auth open %.*s", len, open);
        }
        else if (req->idAuthentication->which == Z_IdAuthentication_idPass)
        {
            const char *user = req->idAuthentication->u.idPass->userId;
            const char *group = req->idAuthentication->u.idPass->groupId;
            yaz_log(log_request, "Auth idPass %s %s",
                    user ? user : "-", group ? group : "-");
        }
        else if (req->idAuthentication->which 
                 == Z_IdAuthentication_anonymous)
        {
            yaz_log(log_request, "Auth anonymous");
        }
        else
        {
            yaz_log(log_request, "Auth other");
        }
    }
    if (log_request)
    {
        WRBUF wr = wrbuf_alloc();
        wrbuf_printf(wr, "Init ");
        if (binitres->errcode)
            wrbuf_printf(wr, "ERROR %d", binitres->errcode);
        else
            wrbuf_printf(wr, "OK -");
        wrbuf_printf(wr, " ID:%s Name:%s Version:%s",
                     (req->implementationId ? req->implementationId :"-"), 
                     (req->implementationName ?
                      req->implementationName : "-"),
                     (req->implementationVersion ?
                      req->implementationVersion : "-")
            );
        yaz_log(log_request, "%s", wrbuf_buf(wr));
        wrbuf_free(wr, 1);
    }
    return apdu;
}

/*
 * Set the specified `errcode' and `errstring' into a UserInfo-1
 * external to be returned to the client in accordance with Z35.90
 * Implementor Agreement 5 (Returning diagnostics in an InitResponse):
 *      http://lcweb.loc.gov/z3950/agency/agree/initdiag.html
 */
static Z_External *init_diagnostics(ODR odr, int error, const char *addinfo)
{
    yaz_log(log_requestdetail, "[%d] %s%s%s", error, diagbib1_str(error),
        addinfo ? " -- " : "", addinfo ? addinfo : "");
    return zget_init_diagnostics(odr, error, addinfo);
}

/*
 * nonsurrogate diagnostic record.
 */
static Z_Records *diagrec(association *assoc, int error, char *addinfo)
{
    Z_Records *rec = (Z_Records *) odr_malloc (assoc->encode, sizeof(*rec));

    yaz_log(log_requestdetail, "[%d] %s%s%s", error, diagbib1_str(error),
            addinfo ? " -- " : "", addinfo ? addinfo : "");

    rec->which = Z_Records_NSD;
    rec->u.nonSurrogateDiagnostic = zget_DefaultDiagFormat(assoc->encode,
                                                           error, addinfo);
    return rec;
}

/*
 * surrogate diagnostic.
 */
static Z_NamePlusRecord *surrogatediagrec(association *assoc, 
                                          const char *dbname,
                                          int error, const char *addinfo)
{
    yaz_log(log_requestdetail, "[%d] %s%s%s", error, diagbib1_str(error),
            addinfo ? " -- " : "", addinfo ? addinfo : "");
    return zget_surrogateDiagRec(assoc->encode, dbname, error, addinfo);
}

static Z_Records *pack_records(association *a, char *setname, int start,
                               int *num, Z_RecordComposition *comp,
                               int *next, int *pres, oid_value format,
                               Z_ReferenceId *referenceId,
                               int *oid, int *errcode)
{
    int recno, total_length = 0, toget = *num, dumped_records = 0;
    Z_Records *records =
        (Z_Records *) odr_malloc (a->encode, sizeof(*records));
    Z_NamePlusRecordList *reclist =
        (Z_NamePlusRecordList *) odr_malloc (a->encode, sizeof(*reclist));
    Z_NamePlusRecord **list =
        (Z_NamePlusRecord **) odr_malloc (a->encode, sizeof(*list) * toget);

    records->which = Z_Records_DBOSD;
    records->u.databaseOrSurDiagnostics = reclist;
    reclist->num_records = 0;
    reclist->records = list;
    *pres = Z_PresentStatus_success;
    *num = 0;
    *next = 0;

    yaz_log(log_requestdetail, "Request to pack %d+%d %s", start, toget, setname);
    yaz_log(log_requestdetail, "pms=%d, mrs=%d", a->preferredMessageSize,
        a->maximumRecordSize);
    for (recno = start; reclist->num_records < toget; recno++)
    {
        bend_fetch_rr freq;
        Z_NamePlusRecord *thisrec;
        int this_length = 0;
        /*
         * we get the number of bytes allocated on the stream before any
         * allocation done by the backend - this should give us a reasonable
         * idea of the total size of the data so far.
         */
        total_length = odr_total(a->encode) - dumped_records;
        freq.errcode = 0;
        freq.errstring = 0;
        freq.basename = 0;
        freq.len = 0;
        freq.record = 0;
        freq.last_in_set = 0;
        freq.setname = setname;
        freq.surrogate_flag = 0;
        freq.number = recno;
        freq.comp = comp;
        freq.request_format = format;
        freq.request_format_raw = oid;
        freq.output_format = format;
        freq.output_format_raw = 0;
        freq.stream = a->encode;
        freq.print = a->print;
        freq.referenceId = referenceId;
        freq.schema = 0;

        retrieve_fetch(a, &freq);

        *next = freq.last_in_set ? 0 : recno + 1;

        /* backend should be able to signal whether error is system-wide
           or only pertaining to current record */
        if (freq.errcode)
        {
            if (!freq.surrogate_flag)
            {
                char s[20];
                *pres = Z_PresentStatus_failure;
                /* for 'present request out of range',
                   set addinfo to record position if not set */
                if (freq.errcode == YAZ_BIB1_PRESENT_REQUEST_OUT_OF_RANGE  && 
                                freq.errstring == 0)
                {
                    sprintf (s, "%d", recno);
                    freq.errstring = s;
                }
                if (errcode)
                    *errcode = freq.errcode;
                return diagrec(a, freq.errcode, freq.errstring);
            }
            reclist->records[reclist->num_records] =
                surrogatediagrec(a, freq.basename, freq.errcode,
                                 freq.errstring);
            reclist->num_records++;
            continue;
        }
        if (freq.record == 0)  /* no error and no record ? */
        {
            *next = 0;   /* signal end-of-set and stop */
            break;
        }
        if (freq.len >= 0)
            this_length = freq.len;
        else
            this_length = odr_total(a->encode) - total_length - dumped_records;
        yaz_log(YLOG_DEBUG, "  fetched record, len=%d, total=%d dumped=%d",
            this_length, total_length, dumped_records);
        if (a->preferredMessageSize > 0 &&
                this_length + total_length > a->preferredMessageSize)
        {
            /* record is small enough, really */
            if (this_length <= a->preferredMessageSize && recno > start)
            {
                yaz_log(log_requestdetail, "  Dropped last normal-sized record");
                *pres = Z_PresentStatus_partial_2;
                break;
            }
            /* record can only be fetched by itself */
            if (this_length < a->maximumRecordSize)
            {
                yaz_log(log_requestdetail, "  Record > prefmsgsz");
                if (toget > 1)
                {
                    yaz_log(YLOG_DEBUG, "  Dropped it");
                    reclist->records[reclist->num_records] =
                         surrogatediagrec(a, freq.basename, 16, 0);
                    reclist->num_records++;
                    dumped_records += this_length;
                    continue;
                }
            }
            else /* too big entirely */
            {
                yaz_log(log_requestdetail, "Record > maxrcdsz this=%d max=%d",
                        this_length, a->maximumRecordSize);
                reclist->records[reclist->num_records] =
                    surrogatediagrec(a, freq.basename, 17, 0);
                reclist->num_records++;
                dumped_records += this_length;
                continue;
            }
        }

        if (!(thisrec = (Z_NamePlusRecord *)
              odr_malloc(a->encode, sizeof(*thisrec))))
            return 0;
        if (freq.basename)
            thisrec->databaseName = odr_strdup(a->encode, freq.basename);
        else
            thisrec->databaseName = 0;
        thisrec->which = Z_NamePlusRecord_databaseRecord;

        if (freq.output_format_raw)
        {
            struct oident *ident = oid_getentbyoid(freq.output_format_raw);
            freq.output_format = ident->value;
        }
        thisrec->u.databaseRecord = z_ext_record(a->encode, freq.output_format,
                                                 freq.record, freq.len);
        if (!thisrec->u.databaseRecord)
            return 0;
        reclist->records[reclist->num_records] = thisrec;
        reclist->num_records++;
    }
    *num = reclist->num_records;
    return records;
}

static Z_APDU *process_searchRequest(association *assoc, request *reqb,
    int *fd)
{
    Z_SearchRequest *req = reqb->apdu_request->u.searchRequest;
    bend_search_rr *bsrr = 
        (bend_search_rr *)nmem_malloc (reqb->request_mem, sizeof(*bsrr));
    
    yaz_log(log_requestdetail, "Got SearchRequest.");
    bsrr->fd = fd;
    bsrr->request = reqb;
    bsrr->association = assoc;
    bsrr->referenceId = req->referenceId;
    save_referenceId (reqb, bsrr->referenceId);
    bsrr->srw_sortKeys = 0;
    bsrr->srw_setname = 0;
    bsrr->srw_setnameIdleTime = 0;
    bsrr->estimated_hit_count = 0;
    bsrr->partial_resultset = 0;

    yaz_log (log_requestdetail, "ResultSet '%s'", req->resultSetName);
    if (req->databaseNames)
    {
        int i;
        for (i = 0; i < req->num_databaseNames; i++)
            yaz_log(log_requestdetail, "Database '%s'", req->databaseNames[i]);
    }

    yaz_log_zquery_level(log_requestdetail,req->query);

    if (assoc->init->bend_search)
    {
        bsrr->setname = req->resultSetName;
        bsrr->replace_set = *req->replaceIndicator;
        bsrr->num_bases = req->num_databaseNames;
        bsrr->basenames = req->databaseNames;
        bsrr->query = req->query;
        bsrr->stream = assoc->encode;
        nmem_transfer(bsrr->stream->mem, reqb->request_mem);
        bsrr->decode = assoc->decode;
        bsrr->print = assoc->print;
        bsrr->hits = 0;
        bsrr->errcode = 0;
        bsrr->errstring = NULL;
        bsrr->search_info = NULL;

        if (assoc->server && assoc->server->cql_transform 
            && req->query->which == Z_Query_type_104
            && req->query->u.type_104->which == Z_External_CQL)
        {
            /* have a CQL query and a CQL to PQF transform .. */
            int srw_errcode = 
                cql2pqf(bsrr->stream, req->query->u.type_104->u.cql,
                        assoc->server->cql_transform, bsrr->query);
            if (srw_errcode)
                bsrr->errcode = yaz_diag_srw_to_bib1(srw_errcode);
        }
        if (!bsrr->errcode)
            (assoc->init->bend_search)(assoc->backend, bsrr);
        if (!bsrr->request)  /* backend not ready with the search response */
            return 0;  /* should not be used any more */
    }
    else
    { 
        /* FIXME - make a diagnostic for it */
        yaz_log(YLOG_WARN,"Search not supported ?!?!");
    }
    return response_searchRequest(assoc, reqb, bsrr, fd);
}

int bend_searchresponse(void *handle, bend_search_rr *bsrr) {return 0;}

/*
 * Prepare a searchresponse based on the backend results. We probably want
 * to look at making the fetching of records nonblocking as well, but
 * so far, we'll keep things simple.
 * If bsrt is null, that means we're called in response to a communications
 * event, and we'll have to get the response for ourselves.
 */
static Z_APDU *response_searchRequest(association *assoc, request *reqb,
    bend_search_rr *bsrt, int *fd)
{
    Z_SearchRequest *req = reqb->apdu_request->u.searchRequest;
    Z_APDU *apdu = (Z_APDU *)odr_malloc (assoc->encode, sizeof(*apdu));
    Z_SearchResponse *resp = (Z_SearchResponse *)
        odr_malloc (assoc->encode, sizeof(*resp));
    int *nulint = odr_intdup (assoc->encode, 0);
    int *next = odr_intdup(assoc->encode, 0);
    int *none = odr_intdup(assoc->encode, Z_SearchResponse_none);
    int returnedrecs = 0;

    apdu->which = Z_APDU_searchResponse;
    apdu->u.searchResponse = resp;
    resp->referenceId = req->referenceId;
    resp->additionalSearchInfo = 0;
    resp->otherInfo = 0;
    *fd = -1;
    if (!bsrt && !bend_searchresponse(assoc->backend, bsrt))
    {
        yaz_log(YLOG_FATAL, "Bad result from backend");
        return 0;
    }
    else if (bsrt->errcode)
    {
        resp->records = diagrec(assoc, bsrt->errcode, bsrt->errstring);
        resp->resultCount = nulint;
        resp->numberOfRecordsReturned = nulint;
        resp->nextResultSetPosition = nulint;
        resp->searchStatus = nulint;
        resp->resultSetStatus = none;
        resp->presentStatus = 0;
    }
    else
    {
        bool_t *sr = odr_intdup(assoc->encode, 1);
        int *toget = odr_intdup(assoc->encode, 0);
        Z_RecordComposition comp, *compp = 0;

        yaz_log (log_requestdetail, "resultCount: %d", bsrt->hits);

        resp->records = 0;
        resp->resultCount = &bsrt->hits;

        comp.which = Z_RecordComp_simple;
        /* how many records does the user agent want, then? */
        if (bsrt->hits <= *req->smallSetUpperBound)
        {
            *toget = bsrt->hits;
            if ((comp.u.simple = req->smallSetElementSetNames))
                compp = &comp;
        }
        else if (bsrt->hits < *req->largeSetLowerBound)
        {
            *toget = *req->mediumSetPresentNumber;
            if (*toget > bsrt->hits)
                *toget = bsrt->hits;
            if ((comp.u.simple = req->mediumSetElementSetNames))
                compp = &comp;
        }
        else
            *toget = 0;

        if (*toget && !resp->records)
        {
            oident *prefformat;
            oid_value form;
            int *presst = odr_intdup(assoc->encode, 0);

            if (!(prefformat = oid_getentbyoid(req->preferredRecordSyntax)))
                form = VAL_NONE;
            else
                form = prefformat->value;

            /* Call bend_present if defined */
            if (assoc->init->bend_present)
            {
                bend_present_rr *bprr = (bend_present_rr *)
                    nmem_malloc (reqb->request_mem, sizeof(*bprr));
                bprr->setname = req->resultSetName;
                bprr->start = 1;
                bprr->number = *toget;
                bprr->format = form;
                bprr->comp = compp;
                bprr->referenceId = req->referenceId;
                bprr->stream = assoc->encode;
                bprr->print = assoc->print;
                bprr->request = reqb;
                bprr->association = assoc;
                bprr->errcode = 0;
                bprr->errstring = NULL;
                (*assoc->init->bend_present)(assoc->backend, bprr);

                if (!bprr->request)
                    return 0;
                if (bprr->errcode)
                {
                    resp->records = diagrec(assoc, bprr->errcode, bprr->errstring);
                    *resp->presentStatus = Z_PresentStatus_failure;
                }
            }

            if (!resp->records)
                resp->records = pack_records(assoc, req->resultSetName, 1,
                                             toget, compp, next, presst, form, req->referenceId,
                                             req->preferredRecordSyntax, NULL);
            if (!resp->records)
                return 0;
            resp->numberOfRecordsReturned = toget;
            returnedrecs = *toget;
            resp->presentStatus = presst;
        }
        else
        {
            if (*resp->resultCount)
                *next = 1;
            resp->numberOfRecordsReturned = nulint;
            resp->presentStatus = 0;
        }
        resp->nextResultSetPosition = next;
        resp->searchStatus = sr;
        resp->resultSetStatus = 0;
        if (bsrt->estimated_hit_count)
        {
            resp->resultSetStatus = odr_intdup(assoc->encode, 
                                               Z_SearchResponse_estimate);
        }
        else if (bsrt->partial_resultset)
        {
            resp->resultSetStatus = odr_intdup(assoc->encode, 
                                               Z_SearchResponse_subset);
        }
    }
    resp->additionalSearchInfo = bsrt->search_info;

    if (log_request)
    {
        int i;
        WRBUF wr = wrbuf_alloc();

        for (i = 0 ; i < req->num_databaseNames; i++){
            if (i)
                wrbuf_printf(wr, "+");
            wrbuf_printf(wr, req->databaseNames[i]);
        }
        wrbuf_printf(wr, " ");
        
        if (bsrt->errcode)
            wrbuf_printf(wr, "ERROR %d", bsrt->errcode);
        else
            wrbuf_printf(wr, "OK %d", bsrt->hits);
        wrbuf_printf(wr, " %s 1+%d ",
                     req->resultSetName, returnedrecs);
        yaz_query_to_wrbuf(wr, req->query);
        
        yaz_log(log_request, "Search %s", wrbuf_buf(wr));
        wrbuf_free(wr, 1);
    }
    return apdu;
}

/*
 * Maybe we got a little over-friendly when we designed bend_fetch to
 * get only one record at a time. Some backends can optimise multiple-record
 * fetches, and at any rate, there is some overhead involved in
 * all that selecting and hopping around. Problem is, of course, that the
 * frontend can't know ahead of time how many records it'll need to
 * fill the negotiated PDU size. Annoying. Segmentation or not, Z/SR
 * is downright lousy as a bulk data transfer protocol.
 *
 * To start with, we'll do the fetching of records from the backend
 * in one operation: To save some trips in and out of the event-handler,
 * and to simplify the interface to pack_records. At any rate, asynch
 * operation is more fun in operations that have an unpredictable execution
 * speed - which is normally more true for search than for present.
 */
static Z_APDU *process_presentRequest(association *assoc, request *reqb,
                                      int *fd)
{
    Z_PresentRequest *req = reqb->apdu_request->u.presentRequest;
    oident *prefformat;
    oid_value form;
    Z_APDU *apdu;
    Z_PresentResponse *resp;
    int *next;
    int *num;
    int errcode = 0;
    const char *errstring = 0;

    yaz_log(log_requestdetail, "Got PresentRequest.");

    if (!(prefformat = oid_getentbyoid(req->preferredRecordSyntax)))
        form = VAL_NONE;
    else
        form = prefformat->value;
    resp = (Z_PresentResponse *)odr_malloc (assoc->encode, sizeof(*resp));
    resp->records = 0;
    resp->presentStatus = odr_intdup(assoc->encode, 0);
    if (assoc->init->bend_present)
    {
        bend_present_rr *bprr = (bend_present_rr *)
            nmem_malloc (reqb->request_mem, sizeof(*bprr));
        bprr->setname = req->resultSetId;
        bprr->start = *req->resultSetStartPoint;
        bprr->number = *req->numberOfRecordsRequested;
        bprr->format = form;
        bprr->comp = req->recordComposition;
        bprr->referenceId = req->referenceId;
        bprr->stream = assoc->encode;
        bprr->print = assoc->print;
        bprr->request = reqb;
        bprr->association = assoc;
        bprr->errcode = 0;
        bprr->errstring = NULL;
        (*assoc->init->bend_present)(assoc->backend, bprr);
        
        if (!bprr->request)
            return 0; /* should not happen */
        if (bprr->errcode)
        {
            resp->records = diagrec(assoc, bprr->errcode, bprr->errstring);
            *resp->presentStatus = Z_PresentStatus_failure;
            errcode = bprr->errcode;
            errstring = bprr->errstring;
        }
    }
    apdu = (Z_APDU *)odr_malloc (assoc->encode, sizeof(*apdu));
    next = odr_intdup(assoc->encode, 0);
    num = odr_intdup(assoc->encode, 0);
    
    apdu->which = Z_APDU_presentResponse;
    apdu->u.presentResponse = resp;
    resp->referenceId = req->referenceId;
    resp->otherInfo = 0;
    
    if (!resp->records)
    {
        *num = *req->numberOfRecordsRequested;
        resp->records =
            pack_records(assoc, req->resultSetId, *req->resultSetStartPoint,
                         num, req->recordComposition, next,
                         resp->presentStatus,
                         form, req->referenceId, req->preferredRecordSyntax, 
                         &errcode);
    }
    if (log_request)
    {
        WRBUF wr = wrbuf_alloc();
        wrbuf_printf(wr, "Present ");

        if (*resp->presentStatus == Z_PresentStatus_failure)
            wrbuf_printf(wr, "ERROR %d ", errcode);
        else if (*resp->presentStatus == Z_PresentStatus_success)
            wrbuf_printf(wr, "OK -  ");
        else
            wrbuf_printf(wr, "Partial %d - ", *resp->presentStatus);

        wrbuf_printf(wr, " %s %d+%d ",
                req->resultSetId, *req->resultSetStartPoint,
                *req->numberOfRecordsRequested);
        yaz_log(log_request, "%s", wrbuf_buf(wr) );
        wrbuf_free(wr, 1);
    }
    if (!resp->records)
        return 0;
    resp->numberOfRecordsReturned = num;
    resp->nextResultSetPosition = next;
    
    return apdu;
}

/*
 * Scan was implemented rather in a hurry, and with support for only the basic
 * elements of the service in the backend API. Suggestions are welcome.
 */
static Z_APDU *process_scanRequest(association *assoc, request *reqb, int *fd)
{
    Z_ScanRequest *req = reqb->apdu_request->u.scanRequest;
    Z_APDU *apdu = (Z_APDU *)odr_malloc (assoc->encode, sizeof(*apdu));
    Z_ScanResponse *res = (Z_ScanResponse *)
        odr_malloc (assoc->encode, sizeof(*res));
    int *scanStatus = odr_intdup(assoc->encode, Z_Scan_failure);
    int *numberOfEntriesReturned = odr_intdup(assoc->encode, 0);
    Z_ListEntries *ents = (Z_ListEntries *)
        odr_malloc (assoc->encode, sizeof(*ents));
    Z_DiagRecs *diagrecs_p = NULL;
    oident *attset;
    bend_scan_rr *bsrr = (bend_scan_rr *)
        odr_malloc (assoc->encode, sizeof(*bsrr));
    struct scan_entry *save_entries;

    yaz_log(log_requestdetail, "Got ScanRequest");

    apdu->which = Z_APDU_scanResponse;
    apdu->u.scanResponse = res;
    res->referenceId = req->referenceId;

    /* if step is absent, set it to 0 */
    res->stepSize = odr_intdup(assoc->encode, 0);
    if (req->stepSize)
        *res->stepSize = *req->stepSize;

    res->scanStatus = scanStatus;
    res->numberOfEntriesReturned = numberOfEntriesReturned;
    res->positionOfTerm = 0;
    res->entries = ents;
    ents->num_entries = 0;
    ents->entries = NULL;
    ents->num_nonsurrogateDiagnostics = 0;
    ents->nonsurrogateDiagnostics = NULL;
    res->attributeSet = 0;
    res->otherInfo = 0;

    if (req->databaseNames)
    {
        int i;
        for (i = 0; i < req->num_databaseNames; i++)
            yaz_log (log_requestdetail, "Database '%s'", req->databaseNames[i]);
    }
    bsrr->scanClause = 0;
    bsrr->errcode = 0;
    bsrr->errstring = 0;
    bsrr->num_bases = req->num_databaseNames;
    bsrr->basenames = req->databaseNames;
    bsrr->num_entries = *req->numberOfTermsRequested;
    bsrr->term = req->termListAndStartPoint;
    bsrr->referenceId = req->referenceId;
    bsrr->stream = assoc->encode;
    bsrr->print = assoc->print;
    bsrr->step_size = res->stepSize;
    bsrr->entries = 0;
    /* For YAZ 2.0 and earlier it was the backend handler that
       initialized entries (member display_term did not exist)
       YAZ 2.0 and later sets 'entries'  and initialize all members
       including 'display_term'. If YAZ 2.0 or later sees that
       entries was modified - we assume that it is an old handler and
       that 'display_term' is _not_ set.
    */
    if (bsrr->num_entries > 0) 
    {
        int i;
        bsrr->entries = odr_malloc(assoc->decode, sizeof(*bsrr->entries) *
                                   bsrr->num_entries);
        for (i = 0; i<bsrr->num_entries; i++)
        {
            bsrr->entries[i].term = 0;
            bsrr->entries[i].occurrences = 0;
            bsrr->entries[i].errcode = 0;
            bsrr->entries[i].errstring = 0;
            bsrr->entries[i].display_term = 0;
        }
    }
    save_entries = bsrr->entries;  /* save it so we can compare later */

    if (req->attributeSet &&
        (attset = oid_getentbyoid(req->attributeSet)) &&
        (attset->oclass == CLASS_ATTSET || attset->oclass == CLASS_GENERAL))
        bsrr->attributeset = attset->value;
    else
        bsrr->attributeset = VAL_NONE;
    log_scan_term_level (log_requestdetail, req->termListAndStartPoint, 
            bsrr->attributeset);
    bsrr->term_position = req->preferredPositionInResponse ?
        *req->preferredPositionInResponse : 1;

    ((int (*)(void *, bend_scan_rr *))
     (*assoc->init->bend_scan))(assoc->backend, bsrr);

    if (bsrr->errcode)
        diagrecs_p = zget_DiagRecs(assoc->encode,
                                   bsrr->errcode, bsrr->errstring);
    else
    {
        int i;
        Z_Entry **tab = (Z_Entry **)
            odr_malloc (assoc->encode, sizeof(*tab) * bsrr->num_entries);
        
        if (bsrr->status == BEND_SCAN_PARTIAL)
            *scanStatus = Z_Scan_partial_5;
        else
            *scanStatus = Z_Scan_success;
        ents->entries = tab;
        ents->num_entries = bsrr->num_entries;
        res->numberOfEntriesReturned = &ents->num_entries;          
        res->positionOfTerm = &bsrr->term_position;
        for (i = 0; i < bsrr->num_entries; i++)
        {
            Z_Entry *e;
            Z_TermInfo *t;
            Odr_oct *o;
            
            tab[i] = e = (Z_Entry *)odr_malloc(assoc->encode, sizeof(*e));
            if (bsrr->entries[i].occurrences >= 0)
            {
                e->which = Z_Entry_termInfo;
                e->u.termInfo = t = (Z_TermInfo *)
                    odr_malloc(assoc->encode, sizeof(*t));
                t->suggestedAttributes = 0;
                t->displayTerm = 0;
                if (save_entries == bsrr->entries && 
                    bsrr->entries[i].display_term)
                {
                    /* the entries was _not_ set by the handler. So it's
                       safe to test for new member display_term. It is
                       NULL'ed by us.
                    */
                    t->displayTerm = odr_strdup(assoc->encode,
                                                bsrr->entries[i].display_term);
                }
                t->alternativeTerm = 0;
                t->byAttributes = 0;
                t->otherTermInfo = 0;
                t->globalOccurrences = &bsrr->entries[i].occurrences;
                t->term = (Z_Term *)
                    odr_malloc(assoc->encode, sizeof(*t->term));
                t->term->which = Z_Term_general;
                t->term->u.general = o =
                    (Odr_oct *)odr_malloc(assoc->encode, sizeof(Odr_oct));
                o->buf = (unsigned char *)
                    odr_malloc(assoc->encode, o->len = o->size =
                               strlen(bsrr->entries[i].term));
                memcpy(o->buf, bsrr->entries[i].term, o->len);
                yaz_log(YLOG_DEBUG, "  term #%d: '%s' (%d)", i,
                         bsrr->entries[i].term, bsrr->entries[i].occurrences);
            }
            else
            {
                Z_DiagRecs *drecs = zget_DiagRecs(assoc->encode,
                                                  bsrr->entries[i].errcode,
                                                  bsrr->entries[i].errstring);
                assert (drecs->num_diagRecs == 1);
                e->which = Z_Entry_surrogateDiagnostic;
                assert (drecs->diagRecs[0]);
                e->u.surrogateDiagnostic = drecs->diagRecs[0];
            }
        }
    }
    if (diagrecs_p)
    {
        ents->num_nonsurrogateDiagnostics = diagrecs_p->num_diagRecs;
        ents->nonsurrogateDiagnostics = diagrecs_p->diagRecs;
    }
    if (log_request)
    {
        int i;
        WRBUF wr = wrbuf_alloc();
        wrbuf_printf(wr, "Scan ");
        for (i = 0 ; i < req->num_databaseNames; i++){
            if (i)
                wrbuf_printf(wr, "+");
            wrbuf_printf(wr, req->databaseNames[i]);
        }
        wrbuf_printf(wr, " ");
        
        if (bsrr->errcode){
            wr_diag(wr, bsrr->errcode, bsrr->errstring);
            wrbuf_printf(wr, " ");
        }
        else
            wrbuf_printf(wr, "OK "); 
        /* else if (*res->scanStatus == Z_Scan_success) */
        /*    wrbuf_printf(wr, "OK "); */
        /* else */
        /* wrbuf_printf(wr, "Partial "); */

        if (*res->numberOfEntriesReturned)
            wrbuf_printf(wr, "%d - ", *res->numberOfEntriesReturned);
        else
            wrbuf_printf(wr, "0 - ");

        wrbuf_printf(wr, "%d+%d+%d ",
                     (req->preferredPositionInResponse ?
                      *req->preferredPositionInResponse : 1),
                     *req->numberOfTermsRequested,
                     (res->stepSize ? *res->stepSize : 1));

        yaz_scan_to_wrbuf(wr, req->termListAndStartPoint, 
                          bsrr->attributeset);
        yaz_log(log_request, "%s", wrbuf_buf(wr) );
        wrbuf_free(wr, 1);
    }
    return apdu;
}

static Z_APDU *process_sortRequest(association *assoc, request *reqb,
    int *fd)
{
    int i;
    Z_SortRequest *req = reqb->apdu_request->u.sortRequest;
    Z_SortResponse *res = (Z_SortResponse *)
        odr_malloc (assoc->encode, sizeof(*res));
    bend_sort_rr *bsrr = (bend_sort_rr *)
        odr_malloc (assoc->encode, sizeof(*bsrr));

    Z_APDU *apdu = (Z_APDU *)odr_malloc (assoc->encode, sizeof(*apdu));

    yaz_log(log_requestdetail, "Got SortRequest.");

    bsrr->num_input_setnames = req->num_inputResultSetNames;
    for (i=0;i<req->num_inputResultSetNames;i++)
        yaz_log(log_requestdetail, "Input resultset: '%s'",
                req->inputResultSetNames[i]);
    bsrr->input_setnames = req->inputResultSetNames;
    bsrr->referenceId = req->referenceId;
    bsrr->output_setname = req->sortedResultSetName;
    yaz_log(log_requestdetail, "Output resultset: '%s'",
                req->sortedResultSetName);
    bsrr->sort_sequence = req->sortSequence;
       /*FIXME - dump those sequences too */
    bsrr->stream = assoc->encode;
    bsrr->print = assoc->print;

    bsrr->sort_status = Z_SortResponse_failure;
    bsrr->errcode = 0;
    bsrr->errstring = 0;
    
    (*assoc->init->bend_sort)(assoc->backend, bsrr);
    
    res->referenceId = bsrr->referenceId;
    res->sortStatus = odr_intdup(assoc->encode, bsrr->sort_status);
    res->resultSetStatus = 0;
    if (bsrr->errcode)
    {
        Z_DiagRecs *dr = zget_DiagRecs(assoc->encode,
                                       bsrr->errcode, bsrr->errstring);
        res->diagnostics = dr->diagRecs;
        res->num_diagnostics = dr->num_diagRecs;
    }
    else
    {
        res->num_diagnostics = 0;
        res->diagnostics = 0;
    }
    res->resultCount = 0;
    res->otherInfo = 0;

    apdu->which = Z_APDU_sortResponse;
    apdu->u.sortResponse = res;
    if (log_request)
    {
        WRBUF wr = wrbuf_alloc();
        wrbuf_printf(wr, "Sort ");
        if (bsrr->errcode)
            wrbuf_printf(wr, " ERROR %d", bsrr->errcode);
        else
            wrbuf_printf(wr,  "OK -");
        wrbuf_printf(wr, " (");
        for (i = 0; i<req->num_inputResultSetNames; i++)
        {
            if (i)
                wrbuf_printf(wr, "+");
            wrbuf_printf(wr, req->inputResultSetNames[i]);
        }
        wrbuf_printf(wr, ")->%s ",req->sortedResultSetName);

        yaz_log(log_request, "%s", wrbuf_buf(wr) );
        wrbuf_free(wr, 1);
    }
    return apdu;
}

static Z_APDU *process_deleteRequest(association *assoc, request *reqb,
    int *fd)
{
    int i;
    Z_DeleteResultSetRequest *req =
        reqb->apdu_request->u.deleteResultSetRequest;
    Z_DeleteResultSetResponse *res = (Z_DeleteResultSetResponse *)
        odr_malloc (assoc->encode, sizeof(*res));
    bend_delete_rr *bdrr = (bend_delete_rr *)
        odr_malloc (assoc->encode, sizeof(*bdrr));
    Z_APDU *apdu = (Z_APDU *)odr_malloc (assoc->encode, sizeof(*apdu));

    yaz_log(log_requestdetail, "Got DeleteRequest.");

    bdrr->num_setnames = req->num_resultSetList;
    bdrr->setnames = req->resultSetList;
    for (i = 0; i<req->num_resultSetList; i++)
        yaz_log(log_requestdetail, "resultset: '%s'",
                req->resultSetList[i]);
    bdrr->stream = assoc->encode;
    bdrr->print = assoc->print;
    bdrr->function = *req->deleteFunction;
    bdrr->referenceId = req->referenceId;
    bdrr->statuses = 0;
    if (bdrr->num_setnames > 0)
    {
        bdrr->statuses = (int*) 
            odr_malloc(assoc->encode, sizeof(*bdrr->statuses) *
                       bdrr->num_setnames);
        for (i = 0; i < bdrr->num_setnames; i++)
            bdrr->statuses[i] = 0;
    }
    (*assoc->init->bend_delete)(assoc->backend, bdrr);
    
    res->referenceId = req->referenceId;

    res->deleteOperationStatus = odr_intdup(assoc->encode,bdrr->delete_status);

    res->deleteListStatuses = 0;
    if (bdrr->num_setnames > 0)
    {
        int i;
        res->deleteListStatuses = (Z_ListStatuses *)
            odr_malloc(assoc->encode, sizeof(*res->deleteListStatuses));
        res->deleteListStatuses->num = bdrr->num_setnames;
        res->deleteListStatuses->elements =
            (Z_ListStatus **)
            odr_malloc (assoc->encode, 
                        sizeof(*res->deleteListStatuses->elements) *
                        bdrr->num_setnames);
        for (i = 0; i<bdrr->num_setnames; i++)
        {
            res->deleteListStatuses->elements[i] =
                (Z_ListStatus *)
                odr_malloc (assoc->encode,
                            sizeof(**res->deleteListStatuses->elements));
            res->deleteListStatuses->elements[i]->status = bdrr->statuses+i;
            res->deleteListStatuses->elements[i]->id =
                odr_strdup (assoc->encode, bdrr->setnames[i]);
        }
    }
    res->numberNotDeleted = 0;
    res->bulkStatuses = 0;
    res->deleteMessage = 0;
    res->otherInfo = 0;

    apdu->which = Z_APDU_deleteResultSetResponse;
    apdu->u.deleteResultSetResponse = res;
    if (log_request)
    {
        WRBUF wr = wrbuf_alloc();
        wrbuf_printf(wr, "Delete ");
        if (bdrr->delete_status)
            wrbuf_printf(wr, "ERROR %d", bdrr->delete_status);
        else
            wrbuf_printf(wr, "OK -");
        for (i = 0; i<req->num_resultSetList; i++)
            wrbuf_printf(wr, " %s ", req->resultSetList[i]);
        yaz_log(log_request, "%s", wrbuf_buf(wr) );
        wrbuf_free(wr, 1);
    }
    return apdu;
}

static void process_close(association *assoc, request *reqb)
{
    Z_Close *req = reqb->apdu_request->u.close;
    static char *reasons[] =
    {
        "finished",
        "shutdown",
        "systemProblem",
        "costLimit",
        "resources",
        "securityViolation",
        "protocolError",
        "lackOfActivity",
        "peerAbort",
        "unspecified"
    };

    yaz_log(log_requestdetail, "Got Close, reason %s, message %s",
        reasons[*req->closeReason], req->diagnosticInformation ?
        req->diagnosticInformation : "NULL");
    if (assoc->version < 3) /* to make do_force respond with close */
        assoc->version = 3;
    do_close_req(assoc, Z_Close_finished,
                 "Association terminated by client", reqb);
    yaz_log(log_request,"Close OK");
}

void save_referenceId (request *reqb, Z_ReferenceId *refid)
{
    if (refid)
    {
        reqb->len_refid = refid->len;
        reqb->refid = (char *)nmem_malloc (reqb->request_mem, refid->len);
        memcpy (reqb->refid, refid->buf, refid->len);
    }
    else
    {
        reqb->len_refid = 0;
        reqb->refid = NULL;
    }
}

void bend_request_send (bend_association a, bend_request req, Z_APDU *res)
{
    process_z_response (a, req, res);
}

bend_request bend_request_mk (bend_association a)
{
    request *nreq = request_get (&a->outgoing);
    nreq->request_mem = nmem_create ();
    return nreq;
}

Z_ReferenceId *bend_request_getid (ODR odr, bend_request req)
{
    Z_ReferenceId *id;
    if (!req->refid)
        return 0;
    id = (Odr_oct *)odr_malloc (odr, sizeof(*odr));
    id->buf = (unsigned char *)odr_malloc (odr, req->len_refid);
    id->len = id->size = req->len_refid;
    memcpy (id->buf, req->refid, req->len_refid);
    return id;
}

void bend_request_destroy (bend_request *req)
{
    nmem_destroy((*req)->request_mem);
    request_release(*req);
    *req = NULL;
}

int bend_backend_respond (bend_association a, bend_request req)
{
    char *msg;
    int r;
    r = process_z_request (a, req, &msg);
    if (r < 0)
        yaz_log (YLOG_WARN, "%s", msg);
    return r;
}

void bend_request_setdata(bend_request r, void *p)
{
    r->clientData = p;
}

void *bend_request_getdata(bend_request r)
{
    return r->clientData;
}

static Z_APDU *process_segmentRequest (association *assoc, request *reqb)
{
    bend_segment_rr req;

    req.segment = reqb->apdu_request->u.segmentRequest;
    req.stream = assoc->encode;
    req.decode = assoc->decode;
    req.print = assoc->print;
    req.association = assoc;
    
    (*assoc->init->bend_segment)(assoc->backend, &req);

    return 0;
}

static Z_APDU *process_ESRequest(association *assoc, request *reqb, int *fd)
{
    bend_esrequest_rr esrequest;
    const char *ext_name = "unknown";

    Z_ExtendedServicesRequest *req =
        reqb->apdu_request->u.extendedServicesRequest;
    Z_APDU *apdu = zget_APDU(assoc->encode, Z_APDU_extendedServicesResponse);

    Z_ExtendedServicesResponse *resp = apdu->u.extendedServicesResponse;

    esrequest.esr = reqb->apdu_request->u.extendedServicesRequest;
    esrequest.stream = assoc->encode;
    esrequest.decode = assoc->decode;
    esrequest.print = assoc->print;
    esrequest.errcode = 0;
    esrequest.errstring = NULL;
    esrequest.request = reqb;
    esrequest.association = assoc;
    esrequest.taskPackage = 0;
    esrequest.referenceId = req->referenceId;

    
    if (esrequest.esr && esrequest.esr->taskSpecificParameters)
    {
        switch(esrequest.esr->taskSpecificParameters->which)
        {
        case Z_External_itemOrder:
            ext_name = "ItemOrder"; break;
        case Z_External_update:
            ext_name = "Update"; break;
        case Z_External_update0:
            ext_name = "Update0"; break;
        case Z_External_ESAdmin:
            ext_name = "Admin"; break;

        }
    }

    (*assoc->init->bend_esrequest)(assoc->backend, &esrequest);
    
    /* If the response is being delayed, return NULL */
    if (esrequest.request == NULL)
        return(NULL);

    resp->referenceId = req->referenceId;

    if (esrequest.errcode == -1)
    {
        /* Backend service indicates request will be processed */
        yaz_log(log_request, "Extended Service: %s (accepted)", ext_name);
        *resp->operationStatus = Z_ExtendedServicesResponse_accepted;
    }
    else if (esrequest.errcode == 0)
    {
        /* Backend service indicates request will be processed */
        yaz_log(log_request, "Extended Service: %s (done)", ext_name);
        *resp->operationStatus = Z_ExtendedServicesResponse_done;
    }
    else
    {
        Z_DiagRecs *diagRecs =
            zget_DiagRecs(assoc->encode, esrequest.errcode,
                          esrequest.errstring);
        /* Backend indicates error, request will not be processed */
        yaz_log(log_request, "Extended Service: %s (failed)", ext_name);
        *resp->operationStatus = Z_ExtendedServicesResponse_failure;
        resp->num_diagnostics = diagRecs->num_diagRecs;
        resp->diagnostics = diagRecs->diagRecs;
        if (log_request)
        {
            WRBUF wr = wrbuf_alloc();
            wrbuf_diags(wr, resp->num_diagnostics, resp->diagnostics);
            yaz_log(log_request, "EsRequest %s", wrbuf_buf(wr) );
            wrbuf_free(wr, 1);
        }

    }
    /* Do something with the members of bend_extendedservice */
    if (esrequest.taskPackage)
        resp->taskPackage = z_ext_record (assoc->encode, VAL_EXTENDED,
                                         (const char *)  esrequest.taskPackage,
                                          -1);
    yaz_log(YLOG_DEBUG,"Send the result apdu");
    return apdu;
}

int bend_assoc_is_alive(bend_association assoc)
{
    if (assoc->state == ASSOC_DEAD)
        return 0; /* already marked as dead. Don't check I/O chan anymore */

    return iochan_is_alive(assoc->client_chan);
}


/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

