/* 
 * Copyright (C) 1995-2006, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: client.c,v 1.321 2006/12/13 11:23:48 adam Exp $
 */
/** \file client.c
 *  \brief yaz-client program
 */

#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <time.h>
#include <ctype.h>
#if HAVE_SYS_TYPES_H
#include <sys/types.h>
#endif
#if HAVE_LOCALE_H
#include <locale.h>
#endif
#if HAVE_LANGINFO_H
#include <langinfo.h>
#endif
#if HAVE_UNISTD_H
#include <unistd.h>
#endif
#if HAVE_SYS_STAT_H
#include <sys/stat.h>
#endif
#if HAVE_SYS_TIME_H
#include <sys/time.h>
#endif

#if HAVE_OPENSSL_SSL_H
#include <openssl/bio.h>
#include <openssl/crypto.h>
#include <openssl/x509.h>
#include <openssl/pem.h>
#include <openssl/ssl.h>
#include <openssl/err.h>
#endif

#ifdef WIN32
#include <sys/stat.h>
#include <io.h>
#include <windows.h>
#define S_ISREG(x) (x & _S_IFREG)
#define S_ISDIR(x) (x & _S_IFDIR)
#endif

#include <yaz/yaz-util.h>

#include <yaz/comstack.h>

#include <yaz/proto.h>
#include <yaz/marcdisp.h>
#include <yaz/diagbib1.h>
#include <yaz/otherinfo.h>
#include <yaz/charneg.h>

#include <yaz/pquery.h>
#include <yaz/sortspec.h>

#include <yaz/ill.h>
#include <yaz/srw.h>
#include <yaz/yaz-ccl.h>
#include <yaz/cql.h>
#include <yaz/log.h>

#if HAVE_READLINE_READLINE_H
#include <readline/readline.h>
#endif
#if HAVE_READLINE_HISTORY_H
#include <readline/history.h>
#endif


#include "admin.h"
#include "tabcomplete.h"

#define C_PROMPT "Z> "

static char *sru_method = "soap";
static char *codeset = 0;               /* character set for output */
static int hex_dump = 0;
static char *dump_file_prefix = 0;
static ODR out, in, print;              /* encoding and decoding streams */
#if YAZ_HAVE_XML2
static ODR srw_sr_odr_out = 0;
static Z_SRW_PDU *srw_sr = 0;
#endif
static FILE *apdu_file = 0;
static FILE *ber_file = 0;
static COMSTACK conn = 0;               /* our z-association */
static Z_IdAuthentication *auth = 0;    /* our current auth definition */
char *databaseNames[128];
int num_databaseNames = 0;
static Z_External *record_last = 0;
static int setnumber = -1;              /* current result set number */
static int smallSetUpperBound = 0;
static int largeSetLowerBound = 1;
static int mediumSetPresentNumber = 0;
static Z_ElementSetNames *elementSetNames = 0; 
static int setno = 1;                   /* current set offset */
static enum oid_proto protocol = PROTO_Z3950;      /* current app protocol */
#define RECORDSYNTAX_MAX 20
static enum oid_value recordsyntax_list[RECORDSYNTAX_MAX]  = { VAL_USMARC };
static int recordsyntax_size = 1;

static char *record_schema = 0;
static int sent_close = 0;
static NMEM session_mem = NULL;         /* memory handle for init-response */
static Z_InitResponse *session_initResponse = 0;   /* session parameters */
static char last_scan_line[512] = "0";
static char last_scan_query[512] = "0";
static char ccl_fields[512] = "default.bib";
/* ### How can I set this path to use wherever YAZ is installed? */
static char cql_fields[512] = "/usr/local/share/yaz/etc/pqf.properties";
static char *esPackageName = 0;
static char *yazProxy = 0;
static int kilobytes = 1024;
static char *negotiationCharset = 0;
static int  negotiationCharsetRecords = 1;
static int  negotiationCharsetVersion = 3;
static char *outputCharset = 0;
static char *marcCharset = 0;
static char* yazLang = 0;

static char last_cmd[32] = "?";
static FILE *marc_file = 0;
static char *refid = NULL;
static char *last_open_command = NULL;
static int auto_reconnect = 0;
static int auto_wait = 1;
static Odr_bitmask z3950_options;
static int z3950_version = 3;
static int scan_stepSize = 0;
static int scan_position = 1;
static int scan_size = 20;
static char cur_host[200];
static int last_hit_count = 0;

typedef enum {
    QueryType_Prefix,
    QueryType_CCL,
    QueryType_CCL2RPN,
    QueryType_CQL,
    QueryType_CQL2RPN
} QueryType;

static QueryType queryType = QueryType_Prefix;

static CCL_bibset bibset;               /* CCL bibset handle */
static cql_transform_t cqltrans;        /* CQL context-set handle */

#if HAVE_READLINE_COMPLETION_OVER

#else
/* readline doesn't have this var. Define it ourselves. */
int rl_attempted_completion_over = 0;
#endif

/* set this one to 1, to avoid decode of unknown MARCs  */
#define AVOID_MARC_DECODE 1

#define maxOtherInfosSupported 10
struct {
    int oidval;
    char* value;
} extraOtherInfos[maxOtherInfosSupported];
        

void process_cmd_line(char* line);
#if HAVE_READLINE_READLINE_H
char **readline_completer(char *text, int start, int end);
#endif
static char *command_generator(const char *text, int state);
int cmd_register_tab(const char* arg);

static void close_session (void);

ODR getODROutputStream(void)
{
    return out;
}

const char* query_type_as_string(QueryType q) 
{
    switch (q) { 
    case QueryType_Prefix: return "prefix (RPN sent to server)";
    case QueryType_CCL: return "CCL (CCL sent to server) ";
    case QueryType_CCL2RPN: return "CCL -> RPN (RPN sent to server)";
    case QueryType_CQL: return "CQL (CQL sent to server)";
    case QueryType_CQL2RPN: return "CQL -> RPN (RPN sent to server)";
    default: 
        return "unknown Query type internal yaz-client error";
    }
}

static void do_hex_dump(const char* buf, int len) 
{
    if (hex_dump)
    {
        int i,x;
        for( i=0; i<len ; i=i+16 ) 
        {                       
            printf(" %4.4d ",i);
            for(x=0 ; i+x<len && x<16; ++x) 
            {
                printf("%2.2X ",(unsigned int)((unsigned char)buf[i+x]));
            }
            printf("\n");
        }
    }
    if (dump_file_prefix)
    {
        static int no = 0;
        if (++no < 1000 && strlen(dump_file_prefix) < 500)
        {
            char fname[1024];
            FILE *of;
            sprintf (fname, "%s.%03d.raw", dump_file_prefix, no);
            of = fopen(fname, "wb");
            
            fwrite (buf, 1, len, of);
            
            fclose(of);
        }
    }
}

void add_otherInfos(Z_APDU *a) 
{
    Z_OtherInformation **oi;
    int i;
                
    yaz_oi_APDU(a, &oi);
    for(i=0; i<maxOtherInfosSupported; ++i) 
    {
        if(extraOtherInfos[i].oidval != -1) 
            yaz_oi_set_string_oidval(oi, out, extraOtherInfos[i].oidval,
                                     1, extraOtherInfos[i].value);
    }   
}

int send_apdu(Z_APDU *a)
{
    char *buf;
    int len;
    
    add_otherInfos(a);
    
    if (apdu_file)
    {
        z_APDU(print, &a, 0, 0);
        odr_reset(print);
    }
    if (!z_APDU(out, &a, 0, 0))
    {
        odr_perror(out, "Encoding APDU");
        close_session();
        return 0;
    }
    buf = odr_getbuf(out, &len, 0);
    if (ber_file)
        odr_dumpBER(ber_file, buf, len);
    /* printf ("sending APDU of size %d\n", len); */
    do_hex_dump(buf, len);
    if (cs_put(conn, buf, len) < 0)
    {
        fprintf(stderr, "cs_put: %s", cs_errmsg(cs_errno(conn)));
        close_session();
        return 0;
    }
    odr_reset(out); /* release the APDU structure  */
    return 1;
}

static void print_stringn(const unsigned char *buf, size_t len)
{
    size_t i;
    for (i = 0; i<len; i++)
        if ((buf[i] <= 126 && buf[i] >= 32) || strchr ("\n\r\t\f", buf[i]))
            printf ("%c", buf[i]);
        else
            printf ("\\X%02X", buf[i]);
}

static void print_refid (Z_ReferenceId *id)
{
    if (id)
    {
        printf ("Reference Id: ");
        print_stringn (id->buf, id->len);
        printf ("\n");
    }
}

static Z_ReferenceId *set_refid (ODR out)
{
    Z_ReferenceId *id;
    if (!refid)
        return 0;
    id = (Z_ReferenceId *) odr_malloc (out, sizeof(*id));
    id->size = id->len = strlen(refid);
    id->buf = (unsigned char *) odr_malloc (out, id->len);
    memcpy (id->buf, refid, id->len);
    return id;
}   

/* INIT SERVICE ------------------------------- */

static void send_initRequest(const char* type_and_host)
{
    Z_APDU *apdu = zget_APDU(out, Z_APDU_initRequest);
    Z_InitRequest *req = apdu->u.initRequest;
    int i;

    req->options = &z3950_options;

    ODR_MASK_ZERO(req->protocolVersion);
    for (i = 0; i<z3950_version; i++)
        ODR_MASK_SET(req->protocolVersion, i);

    *req->maximumRecordSize = 1024*kilobytes;
    *req->preferredMessageSize = 1024*kilobytes;

    req->idAuthentication = auth;

    req->referenceId = set_refid (out);

    if (yazProxy && type_and_host) 
        yaz_oi_set_string_oidval(&req->otherInfo, out, VAL_PROXY,
        1, type_and_host);
    
    if (negotiationCharset || yazLang) {
        Z_OtherInformation **p;
        Z_OtherInformationUnit *p0;
        
        yaz_oi_APDU(apdu, &p);
        
        if ((p0=yaz_oi_update(p, out, NULL, 0, 0))) {
            ODR_MASK_SET(req->options, Z_Options_negotiationModel);
            
            p0->which = Z_OtherInfo_externallyDefinedInfo;
            p0->information.externallyDefinedInfo =
                yaz_set_proposal_charneg_list(out, ",", 
                                              negotiationCharset, 
                                              yazLang,
                                              negotiationCharsetRecords);
        }
    }
    
    if (send_apdu(apdu))
        printf("Sent initrequest.\n");
}


/* These two are used only from process_initResponse() */
static void render_initUserInfo(Z_OtherInformation *ui1);
static void render_diag(Z_DiagnosticFormat *diag);

static void pr_opt(const char *opt, void *clientData)
{
    printf (" %s", opt);
}

static int process_initResponse(Z_InitResponse *res)
{
    int ver = 0;
    /* save session parameters for later use */
    session_mem = odr_extract_mem(in);
    session_initResponse = res;

    for (ver = 0; ver < 8; ver++)
        if (!ODR_MASK_GET(res->protocolVersion, ver))
            break;

    if (!*res->result)
        printf("Connection rejected by v%d target.\n", ver);
    else
        printf("Connection accepted by v%d target.\n", ver);
    if (res->implementationId)
        printf("ID     : %s\n", res->implementationId);
    if (res->implementationName)
        printf("Name   : %s\n", res->implementationName);
    if (res->implementationVersion)
        printf("Version: %s\n", res->implementationVersion);
    if (res->userInformationField)
    {
        Z_External *uif = res->userInformationField;
        if (uif->which == Z_External_userInfo1) {
            render_initUserInfo(uif->u.userInfo1);
        } else {
            printf("UserInformationfield:\n");
            if (!z_External(print, (Z_External**)&uif, 0, 0))
            {
                odr_perror(print, "Printing userinfo\n");
                odr_reset(print);
            }
            if (uif->which == Z_External_octet) {
                printf("Guessing visiblestring:\n");
                printf("'%.*s'\n", uif->u.octet_aligned->len,
                       uif->u.octet_aligned->buf);
            }
            else if (uif->which == Z_External_single) 
            {
                Odr_any *sat = uif->u.single_ASN1_type;
                oident *oid = oid_getentbyoid(uif->direct_reference);
                if (oid->value == VAL_OCLCUI) {
                    Z_OCLC_UserInformation *oclc_ui;
                    ODR decode = odr_createmem(ODR_DECODE);
                    odr_setbuf(decode, (char *) sat->buf, sat->len, 0);
                    if (!z_OCLC_UserInformation(decode, &oclc_ui, 0, 0))
                        printf ("Bad OCLC UserInformation:\n");
                    else
                        printf ("OCLC UserInformation:\n");
                    if (!z_OCLC_UserInformation(print, &oclc_ui, 0, 0))
                        printf ("Bad OCLC UserInformation spec\n");
                    odr_destroy(decode);
                }
                else
                {
                    /* Peek at any private Init-diagnostic APDUs */
                    printf("### NAUGHTY: External is '%.*s'\n",
                           sat->len, sat->buf);
                }
            }
            odr_reset (print);
        }
    }
    printf ("Options:");
    yaz_init_opt_decode(res->options, pr_opt, 0);
    printf ("\n");

    if (ODR_MASK_GET(res->options, Z_Options_namedResultSets))
        setnumber = 0;
    
    if (ODR_MASK_GET(res->options, Z_Options_negotiationModel)) {
    
        Z_CharSetandLanguageNegotiation *p =
                yaz_get_charneg_record(res->otherInfo);
        
        if (p) {
            
            char *charset=NULL, *lang=NULL;
            int selected;
            
            yaz_get_response_charneg(session_mem, p, &charset, &lang,
                                     &selected);

            if (outputCharset && negotiationCharset) {
                    odr_set_charset (out, charset, outputCharset);
                    odr_set_charset (in, outputCharset, charset);
            }
            else {
                    odr_set_charset (out, 0, 0);
                    odr_set_charset (in, 0, 0);
            }
            
            printf("Accepted character set : %s\n", charset);
            printf("Accepted code language : %s\n", lang ? lang : "none");
            printf("Accepted records in ...: %d\n", selected );
        }
    }
    fflush (stdout);
    return 0;
}


static void render_initUserInfo(Z_OtherInformation *ui1) {
    int i;
    printf("Init response contains %d otherInfo unit%s:\n",
           ui1->num_elements, ui1->num_elements == 1 ? "" : "s");

    for (i = 0; i < ui1->num_elements; i++) {
        Z_OtherInformationUnit *unit = ui1->list[i];
        printf("  %d: otherInfo unit contains ", i+1);
        if (unit->which == Z_OtherInfo_externallyDefinedInfo &&
            unit->information.externallyDefinedInfo &&
            unit->information.externallyDefinedInfo->which ==
            Z_External_diag1) {
            render_diag(unit->information.externallyDefinedInfo->u.diag1);
        } 
        else if (unit->which != Z_OtherInfo_externallyDefinedInfo)
        {
            printf("unsupported otherInfo unit->which = %d\n", unit->which);
        }
        else 
        {
            printf("unsupported otherInfo unit external %d\n",
                   unit->information.externallyDefinedInfo ? 
                   unit->information.externallyDefinedInfo->which : -2);
        }
    }
}


/* ### should this share code with display_diagrecs()? */
static void render_diag(Z_DiagnosticFormat *diag) {
    int i;

    printf("%d diagnostic%s:\n", diag->num, diag->num == 1 ? "" : "s");
    for (i = 0; i < diag->num; i++) {
        Z_DiagnosticFormat_s *ds = diag->elements[i];
        printf("    %d: ", i+1);
        switch (ds->which) {
        case Z_DiagnosticFormat_s_defaultDiagRec: {
            Z_DefaultDiagFormat *dd = ds->u.defaultDiagRec;
            /* ### should check `dd->diagnosticSetId' */
            printf("code=%d (%s)", *dd->condition,
                   diagbib1_str(*dd->condition));
            /* Both types of addinfo are the same, so use type-pun */
            if (dd->u.v2Addinfo != 0)
                printf(",\n\taddinfo='%s'", dd->u.v2Addinfo);
            break;
        }
        case Z_DiagnosticFormat_s_explicitDiagnostic:
            printf("Explicit diagnostic (not supported)");
            break;
        default:
            printf("Unrecognised diagnostic type %d", ds->which);
            break;
        }

        if (ds->message != 0)
            printf(", message='%s'", ds->message);
        printf("\n");
    }
}


static int set_base(const char *arg)
{
    int i;
    const char *cp;

    for (i = 0; i<num_databaseNames; i++)
        xfree (databaseNames[i]);
    num_databaseNames = 0;
    while (1)
    {
        char *cp1;
        if (!(cp = strchr(arg, ' ')))
            cp = arg + strlen(arg);
        if (cp - arg < 1)
            break;
        databaseNames[num_databaseNames] = (char *)xmalloc (1 + cp - arg);
        memcpy (databaseNames[num_databaseNames], arg, cp - arg);
        databaseNames[num_databaseNames][cp - arg] = '\0';

        for (cp1 = databaseNames[num_databaseNames]; *cp1 ; cp1++)
            if (*cp1 == '+')
                *cp1 = ' ';
        num_databaseNames++;

        if (!*cp)
            break;
        arg = cp+1;
    }
    if (num_databaseNames == 0)
    {
        num_databaseNames = 1;
        databaseNames[0] = xstrdup("");
    }
    return 1;
}

static int parse_cmd_doc(const char **arg, ODR out, char **buf,
                         int *len, int opt)
{
    const char *sep;
    while (**arg && strchr(" \t\n\r\f", **arg))
        (*arg)++;
    if ((*arg)[0] == '\"' && (sep=strchr(*arg+1, '"')))
    {
        (*arg)++;
        *len = sep - *arg;
        *buf = odr_strdupn(out, *arg, *len);
        (*arg) = sep+1;
        return 1;
    }
    else if ((*arg)[0] && (*arg)[0] != '\"')
    {
        long fsize;
        FILE *inf;
        const char *fname = *arg;
        
        while (**arg != '\0' && **arg != ' ')
            (*arg)++;
            
        inf = fopen(fname, "rb");
        if (!inf)
        {
            printf("Couldn't open %s\n", fname);
            return 0;
        }
        if (fseek(inf, 0L, SEEK_END) == -1)
        {
            printf("Couldn't seek in %s\n", fname);
            fclose(inf);
            return 0;
        }
        fsize = ftell(inf);
        if (fseek(inf, 0L, SEEK_SET) == -1)
        {
            printf("Couldn't seek in %s\n", fname);
            fclose(inf);
            return 0;
        }
        *len = fsize;
        *buf = odr_malloc(out, fsize);
        if (fread(*buf, 1, fsize, inf) != fsize)
        {
            printf("Unable to read %s\n", fname);
            fclose(inf);
            return 0;
        }
        fclose(inf);
        return 1;
    }
    else if (**arg == '\0')
    {
        if (opt)
        {
            *len = 0;
            *buf = 0;
            return 1;
        }
        printf("Missing doc argument\n");
    }
    else
        printf("Bad doc argument %s\n", *arg);
    return 0;
}

static int cmd_base(const char *arg)
{
    if (!*arg)
    {
        printf("Usage: base <database> <database> ...\n");
        return 0;
    }
    return set_base(arg);
}

void cmd_open_remember_last_open_command(const char* arg, char* new_open_command)
{
    if(last_open_command != arg) 
    {
        if(last_open_command) xfree(last_open_command);
        last_open_command = xstrdup(new_open_command);
    }
}

int session_connect(const char *arg)
{
    void *add;
    char type_and_host[101];
    const char *basep = 0;
#if HAVE_OPENSSL_SSL_H
    SSL *ssl;
#endif
    if (conn)
    {
        cs_close (conn);
        conn = 0;
    }   
    if (session_mem)
    {
        nmem_destroy (session_mem);
        session_mem = NULL;
        session_initResponse = 0;
    }
    cs_get_host_args(arg, &basep);

    strncpy(type_and_host, arg, sizeof(type_and_host)-1);
    type_and_host[sizeof(type_and_host)-1] = '\0';

    cmd_open_remember_last_open_command(arg, type_and_host);

    if (yazProxy)
        conn = cs_create_host(yazProxy, 1, &add);
    else
        conn = cs_create_host(arg, 1, &add);
    if (!conn)
    {
        printf ("Could not resolve address %s\n", arg);
        return 0;
    }
#if YAZ_HAVE_XML2
    if (conn->protocol == PROTO_HTTP)
        queryType = QueryType_CQL;
#else
    if (conn->protocol == PROTO_HTTP)
    {
        printf ("SRW/HTTP not enabled in this YAZ\n");
        cs_close(conn);
        conn = 0;
        return 0;
    }
#endif
    protocol = conn->protocol;
    if (conn->protocol == PROTO_HTTP)
        set_base("");
    else
        set_base("Default");
    printf("Connecting...");
    fflush(stdout);
    if (cs_connect(conn, add) < 0)
    {
        printf ("error = %s\n", cs_strerror(conn));
        cs_close(conn);
        conn = 0;
        return 0;
    }
    printf("OK.\n");
#if HAVE_OPENSSL_SSL_H
    if ((ssl = (SSL *) cs_get_ssl(conn)))
    {
        X509 *server_cert = SSL_get_peer_certificate (ssl);

        if (server_cert)
        {
            char *pem_buf;
            int pem_len;
            BIO *bio = BIO_new(BIO_s_mem());

            /* get PEM buffer in memory */
            PEM_write_bio_X509(bio, server_cert);
            pem_len = BIO_get_mem_data(bio, &pem_buf);
            fwrite(pem_buf, pem_len, 1, stdout);
        
            /* print all info on screen .. */
            X509_print_fp(stdout, server_cert);
            BIO_free(bio);

            X509_free (server_cert);
        }
    }
#endif
    if (basep && *basep)
        set_base (basep);
    if (protocol == PROTO_Z3950)
    {
        send_initRequest(type_and_host);
        return 2;
    }
    return 0;
}

int cmd_open(const char *arg)
{
    if (arg)
    {
        strncpy (cur_host, arg, sizeof(cur_host)-1);
        cur_host[sizeof(cur_host)-1] = 0;
    }
    return session_connect(cur_host);
}

void try_reconnect(void)
{
    char* open_command;
        
    if(!( auto_reconnect && last_open_command) ) return ;

    open_command = (char *) xmalloc (strlen(last_open_command)+6);
    strcpy (open_command, "open ");
        
    strcat (open_command, last_open_command);

    process_cmd_line(open_command);
        
    xfree(open_command);                                
}

int cmd_authentication(const char *arg)
{
    static Z_IdAuthentication au;
    static char user[40], group[40], pass[40];
    static Z_IdPass idPass;
    int r;

    if (!*arg)
    {
        printf("Auth field set to null\n");
        auth = 0;
        return 1;
    }
    r = sscanf (arg, "%39s %39s %39s", user, group, pass);
    if (r == 0)
    {
        printf("Authentication set to null\n");
        auth = 0;
    }
    if (r == 1)
    {
        auth = &au;
        if (!strcmp(user, "-")) {
            au.which = Z_IdAuthentication_anonymous;
            printf("Authentication set to Anonymous\n");
        } else {
            au.which = Z_IdAuthentication_open;
            au.u.open = user;
            printf("Authentication set to Open (%s)\n", user);
        }
    }
    if (r == 2)
    {
        auth = &au;
        au.which = Z_IdAuthentication_idPass;
        au.u.idPass = &idPass;
        idPass.groupId = NULL;
        idPass.userId = user;
        idPass.password = group;
        printf("Authentication set to User (%s), Pass (%s)\n", user, group);
    }
    if (r == 3)
    {
        auth = &au;
        au.which = Z_IdAuthentication_idPass;
        au.u.idPass = &idPass;
        idPass.groupId = group;
        idPass.userId = user;
        idPass.password = pass;
        printf("Authentication set to User (%s), Group (%s), Pass (%s)\n",
               user, group, pass);
    }
    return 1;
}

/* SEARCH SERVICE ------------------------------ */
static void display_record(Z_External *r);

static void print_record(const unsigned char *buf, size_t len)
{
    size_t i = len;
    print_stringn (buf, len);
    /* add newline if not already added ... */
    if (i <= 0 || buf[i-1] != '\n')
        printf ("\n");
}

static void display_record(Z_External *r)
{
    oident *ent = oid_getentbyoid(r->direct_reference);

    record_last = r;
    /*
     * Tell the user what we got.
     */
    if (r->direct_reference)
    {
        printf("Record type: ");
        if (ent)
            printf("%s\n", ent->desc);
        else if (!odr_oid(print, &r->direct_reference, 0, 0))
        {
            odr_perror(print, "print oid");
            odr_reset(print);
        }
    }
    /* Check if this is a known, ASN.1 type tucked away in an octet string */
    if (ent && r->which == Z_External_octet)
    {
        Z_ext_typeent *type = z_ext_getentbyref(ent->value);
        char *rr;

        if (type)
        {
            /*
             * Call the given decoder to process the record.
             */
            odr_setbuf(in, (char*)r->u.octet_aligned->buf,
                r->u.octet_aligned->len, 0);
            if (!(*type->fun)(in, &rr, 0, 0))
            {
                odr_perror(in, "Decoding constructed record.");
                fprintf(stdout, "[Near %ld]\n", (long) odr_offset(in));
                fprintf(stdout, "Packet dump:\n---------\n");
                odr_dumpBER(stdout, (char*)r->u.octet_aligned->buf,
                            r->u.octet_aligned->len);
                fprintf(stdout, "---------\n");
                
                /* note just ignores the error ant print the bytes form the octet_aligned later */
            } else {
                /*
                 * Note: we throw away the original, BER-encoded record here.
                 * Do something else with it if you want to keep it.
                 */
                r->u.sutrs = (Z_SUTRS *) rr; /* we don't actually check the type here. */
                r->which = type->what;
            }
        }
    }
    if (ent && ent->value == VAL_SOIF)
    {
        print_record((const unsigned char *) r->u.octet_aligned->buf,
                     r->u.octet_aligned->len);
        if (marc_file)
            fwrite (r->u.octet_aligned->buf, 1, r->u.octet_aligned->len, marc_file);
    }
    else if (r->which == Z_External_octet)
    {
        const char *octet_buf = (char*)r->u.octet_aligned->buf;
        if (ent->oclass == CLASS_RECSYN && 
                (ent->value == VAL_TEXT_XML || 
                 ent->value == VAL_APPLICATION_XML ||
                 ent->value == VAL_HTML))
        {
            print_record((const unsigned char *) octet_buf,
                         r->u.octet_aligned->len);
        }
        else if (ent->value == VAL_POSTSCRIPT)
        {
            int size = r->u.octet_aligned->len;
            if (size > 100)
                size = 100;
            print_record((const unsigned char *) octet_buf, size);
        }
        else
        {
            if ( 
#if AVOID_MARC_DECODE
                /* primitive check for a marc OID 5.1-29 except 16 */
                ent->oidsuffix[0] == 5 && ent->oidsuffix[1] < 30 &&
                ent->oidsuffix[1] != 16
#else
                1
#endif
                )
            {
                char *result;
                int rlen;
                yaz_iconv_t cd = 0;
                yaz_marc_t mt = yaz_marc_create();
                    
                if (yaz_marc_decode_buf(mt, octet_buf,r->u.octet_aligned->len,
                                        &result, &rlen)> 0)
                {
                    char *from = 0;
                    if (marcCharset && !strcmp(marcCharset, "auto"))
                    {
                        if (ent->value == VAL_USMARC)
                        {
                            if (octet_buf[9] == 'a')
                                from = "UTF-8";
                            else
                                from = "MARC-8";
                        }
                        else
                            from = "ISO-8859-1";
                    }
                    else if (marcCharset)
                        from = marcCharset;
                    if (outputCharset && from)
                    {   
                        cd = yaz_iconv_open(outputCharset, from);
                        printf ("convert from %s to %s", from, 
                                outputCharset);
                        if (!cd)
                            printf (" unsupported\n");
                        else
                            printf ("\n");
                    }
                    if (!cd)
                        fwrite (result, 1, rlen, stdout);
                    else
                    {
                        char outbuf[6];
                        size_t inbytesleft = rlen;
                        const char *inp = result;
                        
                        while (inbytesleft)
                        {
                            size_t outbytesleft = sizeof(outbuf);
                            char *outp = outbuf;
                            size_t r;

                            r = yaz_iconv (cd, (char**) &inp,
                                           &inbytesleft, 
                                           &outp, &outbytesleft);
                            if (r == (size_t) (-1))
                            {
                                int e = yaz_iconv_error(cd);
                                if (e != YAZ_ICONV_E2BIG)
                                    break;
                            }
                            fwrite (outbuf, outp - outbuf, 1, stdout);
                        }
                    }
                }
                else
                {
                    printf ("bad MARC. Dumping as it is:\n");
                    print_record((const unsigned char*) octet_buf,
                                  r->u.octet_aligned->len);
                }       
                yaz_marc_destroy(mt);
                if (cd)
                    yaz_iconv_close(cd);
            }
            else
            {
                print_record((const unsigned char*) octet_buf,
                             r->u.octet_aligned->len);
            }
        }
        if (marc_file)
            fwrite (octet_buf, 1, r->u.octet_aligned->len, marc_file);
    }
    else if (ent && ent->value == VAL_SUTRS)
    {
        if (r->which != Z_External_sutrs)
        {
            printf("Expecting single SUTRS type for SUTRS.\n");
            return;
        }
        print_record(r->u.sutrs->buf, r->u.sutrs->len);
        if (marc_file)
            fwrite (r->u.sutrs->buf, 1, r->u.sutrs->len, marc_file);
    }
    else if (ent && ent->value == VAL_GRS1)
    {
        WRBUF w;
        if (r->which != Z_External_grs1)
        {
            printf("Expecting single GRS type for GRS.\n");
            return;
        }
        w = wrbuf_alloc();
        yaz_display_grs1(w, r->u.grs1, 0);
        puts (wrbuf_buf(w));
        wrbuf_free(w, 1);
    }
    else if (ent && ent->value == VAL_OPAC)
    {
        int i;
        if (r->u.opac->bibliographicRecord)
            display_record(r->u.opac->bibliographicRecord);
        for (i = 0; i<r->u.opac->num_holdingsData; i++)
        {
            Z_HoldingsRecord *h = r->u.opac->holdingsData[i];
            if (h->which == Z_HoldingsRecord_marcHoldingsRecord)
            {
                printf ("MARC holdings %d\n", i);
                display_record(h->u.marcHoldingsRecord);
            }
            else if (h->which == Z_HoldingsRecord_holdingsAndCirc)
            {
                int j;

                Z_HoldingsAndCircData *data = h->u.holdingsAndCirc;

                printf ("Data holdings %d\n", i);
                if (data->typeOfRecord)
                    printf ("typeOfRecord: %s\n", data->typeOfRecord);
                if (data->encodingLevel)
                    printf ("encodingLevel: %s\n", data->encodingLevel);
                if (data->receiptAcqStatus)
                    printf ("receiptAcqStatus: %s\n", data->receiptAcqStatus);
                if (data->generalRetention)
                    printf ("generalRetention: %s\n", data->generalRetention);
                if (data->completeness)
                    printf ("completeness: %s\n", data->completeness);
                if (data->dateOfReport)
                    printf ("dateOfReport: %s\n", data->dateOfReport);
                if (data->nucCode)
                    printf ("nucCode: %s\n", data->nucCode);
                if (data->localLocation)
                    printf ("localLocation: %s\n", data->localLocation);
                if (data->shelvingLocation)
                    printf ("shelvingLocation: %s\n", data->shelvingLocation);
                if (data->callNumber)
                    printf ("callNumber: %s\n", data->callNumber);
                if (data->shelvingData)
                    printf ("shelvingData: %s\n", data->shelvingData);
                if (data->copyNumber)
                    printf ("copyNumber: %s\n", data->copyNumber);
                if (data->publicNote)
                    printf ("publicNote: %s\n", data->publicNote);
                if (data->reproductionNote)
                    printf ("reproductionNote: %s\n", data->reproductionNote);
                if (data->termsUseRepro)
                    printf ("termsUseRepro: %s\n", data->termsUseRepro);
                if (data->enumAndChron)
                    printf ("enumAndChron: %s\n", data->enumAndChron);
                for (j = 0; j<data->num_volumes; j++)
                {
                    printf ("volume %d\n", j);
                    if (data->volumes[j]->enumeration)
                        printf (" enumeration: %s\n",
                                data->volumes[j]->enumeration);
                    if (data->volumes[j]->chronology)
                        printf (" chronology: %s\n",
                                data->volumes[j]->chronology);
                    if (data->volumes[j]->enumAndChron)
                        printf (" enumAndChron: %s\n",
                                data->volumes[j]->enumAndChron);
                }
                for (j = 0; j<data->num_circulationData; j++)
                {
                    printf ("circulation %d\n", j);
                    if (data->circulationData[j]->availableNow)
                        printf (" availableNow: %d\n",
                                *data->circulationData[j]->availableNow);
                    if (data->circulationData[j]->availablityDate)
                        printf (" availabiltyDate: %s\n",
                                data->circulationData[j]->availablityDate);
                    if (data->circulationData[j]->availableThru)
                        printf (" availableThru: %s\n",
                                data->circulationData[j]->availableThru);
                    if (data->circulationData[j]->restrictions)
                        printf (" restrictions: %s\n",
                                data->circulationData[j]->restrictions);
                    if (data->circulationData[j]->itemId)
                        printf (" itemId: %s\n",
                                data->circulationData[j]->itemId);
                    if (data->circulationData[j]->renewable)
                        printf (" renewable: %d\n",
                                *data->circulationData[j]->renewable);
                    if (data->circulationData[j]->onHold)
                        printf (" onHold: %d\n",
                                *data->circulationData[j]->onHold);
                    if (data->circulationData[j]->enumAndChron)
                        printf (" enumAndChron: %s\n",
                                data->circulationData[j]->enumAndChron);
                    if (data->circulationData[j]->midspine)
                        printf (" midspine: %s\n",
                                data->circulationData[j]->midspine);
                    if (data->circulationData[j]->temporaryLocation)
                        printf (" temporaryLocation: %s\n",
                                data->circulationData[j]->temporaryLocation);
                }
            }
        }
    }
    else 
    {
        printf("Unknown record representation.\n");
        if (!z_External(print, &r, 0, 0))
        {
            odr_perror(print, "Printing external");
            odr_reset(print);
        }
    }
}

static void display_diagrecs(Z_DiagRec **pp, int num)
{
    int i;
    oident *ent;
    Z_DefaultDiagFormat *r;

    printf("Diagnostic message(s) from database:\n");
    for (i = 0; i<num; i++)
    {
        Z_DiagRec *p = pp[i];
        if (p->which != Z_DiagRec_defaultFormat)
        {
            printf("Diagnostic record not in default format.\n");
            return;
        }
        else
            r = p->u.defaultFormat;
        if (!(ent = oid_getentbyoid(r->diagnosticSetId)) ||
            ent->oclass != CLASS_DIAGSET || ent->value != VAL_BIB1)
            printf("Missing or unknown diagset\n");
        printf("    [%d] %s", *r->condition, diagbib1_str(*r->condition));
        switch (r->which)
        {
        case Z_DefaultDiagFormat_v2Addinfo:
            printf (" -- v2 addinfo '%s'\n", r->u.v2Addinfo);
            break;
        case Z_DefaultDiagFormat_v3Addinfo:
            printf (" -- v3 addinfo '%s'\n", r->u.v3Addinfo);
            break;
        }
    }
}


static void display_nameplusrecord(Z_NamePlusRecord *p)
{
    if (p->databaseName)
        printf("[%s]", p->databaseName);
    if (p->which == Z_NamePlusRecord_surrogateDiagnostic)
        display_diagrecs(&p->u.surrogateDiagnostic, 1);
    else if (p->which == Z_NamePlusRecord_databaseRecord)
        display_record(p->u.databaseRecord);
}

static void display_records(Z_Records *p)
{
    int i;

    if (p->which == Z_Records_NSD)
    {
        Z_DiagRec dr, *dr_p = &dr;
        dr.which = Z_DiagRec_defaultFormat;
        dr.u.defaultFormat = p->u.nonSurrogateDiagnostic;
        display_diagrecs (&dr_p, 1);
    }
    else if (p->which == Z_Records_multipleNSD)
        display_diagrecs (p->u.multipleNonSurDiagnostics->diagRecs,
                          p->u.multipleNonSurDiagnostics->num_diagRecs);
    else 
    {
        printf("Records: %d\n", p->u.databaseOrSurDiagnostics->num_records);
        for (i = 0; i < p->u.databaseOrSurDiagnostics->num_records; i++)
            display_nameplusrecord(p->u.databaseOrSurDiagnostics->records[i]);
    }
}

static int send_deleteResultSetRequest(const char *arg)
{
    char names[8][32];
    int i;

    Z_APDU *apdu = zget_APDU(out, Z_APDU_deleteResultSetRequest);
    Z_DeleteResultSetRequest *req = apdu->u.deleteResultSetRequest;

    req->referenceId = set_refid (out);

    req->num_resultSetList =
        sscanf (arg, "%30s %30s %30s %30s %30s %30s %30s %30s",
                names[0], names[1], names[2], names[3],
                names[4], names[5], names[6], names[7]);

    req->deleteFunction = (int *)
        odr_malloc (out, sizeof(*req->deleteFunction));
    if (req->num_resultSetList > 0)
    {
        *req->deleteFunction = Z_DeleteResultSetRequest_list;
        req->resultSetList = (char **)
            odr_malloc (out, sizeof(*req->resultSetList)*
                        req->num_resultSetList);
        for (i = 0; i<req->num_resultSetList; i++)
            req->resultSetList[i] = names[i];
    }
    else
    {
        *req->deleteFunction = Z_DeleteResultSetRequest_all;
        req->resultSetList = 0;
    }
    
    send_apdu(apdu);
    printf("Sent deleteResultSetRequest.\n");
    return 2;
}

#if YAZ_HAVE_XML2
static int send_srw(Z_SRW_PDU *sr)
{
    const char *charset = negotiationCharset;
    const char *host_port = cur_host;
    Z_GDU *gdu;
    char *path = 0;

    path = odr_malloc(out, 2+strlen(databaseNames[0]));
    *path = '/';
    strcpy(path+1, databaseNames[0]);

    gdu = z_get_HTTP_Request_host_path(out, host_port, path);

    if (!strcmp(sru_method, "get"))
    {
        yaz_sru_get_encode(gdu->u.HTTP_Request, sr, out, charset);
    }
    else if (!strcmp(sru_method, "post"))
    {
        yaz_sru_post_encode(gdu->u.HTTP_Request, sr, out, charset);
    }
    else if (!strcmp(sru_method, "soap"))
    {
        yaz_sru_soap_encode(gdu->u.HTTP_Request, sr, out, charset);
    }

    if (z_GDU(out, &gdu, 0, 0))
    {
        /* encode OK */
        char *buf_out;
        int len_out;
        int r;
        if (apdu_file)
        {
            if (!z_GDU(print, &gdu, 0, 0))
                printf ("Failed to print outgoing SRU package\n");
            odr_reset(print);
        }
        buf_out = odr_getbuf(out, &len_out, 0);
        
        /* we don't odr_reset(out), since we may need the buffer again */

        do_hex_dump(buf_out, len_out);

        r = cs_put(conn, buf_out, len_out);

        if (r >= 0)
            return 2;
    }
    return 0;
}
#endif

#if YAZ_HAVE_XML2
static char *encode_SRW_term(ODR o, const char *q)
{
    const char *in_charset = "ISO-8859-1";
    WRBUF w = wrbuf_alloc();
    yaz_iconv_t cd;
    char *res;
    if (outputCharset)
        in_charset = outputCharset;
    cd = yaz_iconv_open("UTF-8", in_charset);
    if (!cd)
    {
        wrbuf_free(w, 1);
        return odr_strdup(o, q);
    }
    wrbuf_iconv_write(w, cd, q, strlen(q));
    if (wrbuf_len(w))
    {
        int len = wrbuf_len(w);
        res = odr_strdupn(o, wrbuf_buf(w), len);
    }
    else
        res = odr_strdup(o, q);    
    yaz_iconv_close(cd);
    wrbuf_free(w, 1);
    return res;
}


static int send_SRW_scanRequest(const char *arg, int pos, int num)
{
    Z_SRW_PDU *sr = 0;
    
    /* regular requestse .. */
    sr = yaz_srw_get(out, Z_SRW_scan_request);

    switch(queryType)
    {
    case QueryType_CQL:
        sr->u.scan_request->query_type = Z_SRW_query_type_cql;
        sr->u.scan_request->scanClause.cql = encode_SRW_term(out, arg);
        break;
    case QueryType_Prefix:
        sr->u.scan_request->query_type = Z_SRW_query_type_pqf;
        sr->u.scan_request->scanClause.pqf = encode_SRW_term(out, arg);
        break;
    default:
        printf ("Only CQL and PQF supported in SRW\n");
        return 0;
    }
    sr->u.scan_request->responsePosition = odr_intdup(out, pos);
    sr->u.scan_request->maximumTerms = odr_intdup(out, num);
    return send_srw(sr);
}

static int send_SRW_searchRequest(const char *arg)
{
    Z_SRW_PDU *sr = 0;
    
    if (!srw_sr)
    {
        assert(srw_sr_odr_out == 0);
        srw_sr_odr_out = odr_createmem(ODR_ENCODE);
    }
    odr_reset(srw_sr_odr_out);

    setno = 1;

    /* save this for later .. when fetching individual records */
    srw_sr =  yaz_srw_get(srw_sr_odr_out, Z_SRW_searchRetrieve_request);
    
    /* regular request .. */
    sr = yaz_srw_get(out, Z_SRW_searchRetrieve_request);

    switch(queryType)
    {
    case QueryType_CQL:
        srw_sr->u.request->query_type = Z_SRW_query_type_cql;
        srw_sr->u.request->query.cql = encode_SRW_term(srw_sr_odr_out, arg);

        sr->u.request->query_type = Z_SRW_query_type_cql;
        sr->u.request->query.cql = encode_SRW_term(srw_sr_odr_out, arg);
        break;
    case QueryType_Prefix:
        srw_sr->u.request->query_type = Z_SRW_query_type_pqf;
        srw_sr->u.request->query.pqf = encode_SRW_term(srw_sr_odr_out, arg);

        sr->u.request->query_type = Z_SRW_query_type_pqf;
        sr->u.request->query.pqf = encode_SRW_term(srw_sr_odr_out, arg);
        break;
    default:
        printf ("Only CQL and PQF supported in SRW\n");
        return 0;
    }
    sr->u.request->maximumRecords = odr_intdup(out, 0);

    if (record_schema)
        sr->u.request->recordSchema = record_schema;
    if (recordsyntax_size == 1 && recordsyntax_list[0] == VAL_TEXT_XML)
        sr->u.request->recordPacking = "xml";
    return send_srw(sr);
}
#endif

static int send_searchRequest(const char *arg)
{
    Z_APDU *apdu = zget_APDU(out, Z_APDU_searchRequest);
    Z_SearchRequest *req = apdu->u.searchRequest;
    Z_Query query;
    struct ccl_rpn_node *rpn = NULL;
    int error, pos;
    char setstring[100];
    Z_RPNQuery *RPNquery;
    Odr_oct ccl_query;
    YAZ_PQF_Parser pqf_parser;
    Z_External *ext;
    QueryType myQueryType = queryType;
    char pqfbuf[512];

    if (myQueryType == QueryType_CCL2RPN)
    {
        rpn = ccl_find_str(bibset, arg, &error, &pos);
        if (error)
        {
            printf("CCL ERROR: %s\n", ccl_err_msg(error));
            return 0;
        }
    } else if (myQueryType == QueryType_CQL2RPN) {
        /* ### All this code should be wrapped in a utility function */
        CQL_parser parser;
        struct cql_node *node;
        const char *addinfo;
        if (cqltrans == 0) {
            printf("Can't use CQL: no translation file.  Try set_cqlfile\n");
            return 0;
        }
        parser = cql_parser_create();
        if ((error = cql_parser_string(parser, arg)) != 0) {
            printf("Can't parse CQL: must be a syntax error\n");
            return 0;
        }
        node = cql_parser_result(parser);
        if ((error = cql_transform_buf(cqltrans, node, pqfbuf,
                                       sizeof pqfbuf)) != 0) {
            error = cql_transform_error(cqltrans, &addinfo);
            printf ("Can't convert CQL to PQF: %s (addinfo=%s)\n",
                    cql_strerror(error), addinfo);
            return 0;
        }
        arg = pqfbuf;
        myQueryType = QueryType_Prefix;
    }

    req->referenceId = set_refid (out);
    if (!strcmp(arg, "@big")) /* strictly for troublemaking */
    {
        static unsigned char big[2100];
        static Odr_oct bigo;

        /* send a very big referenceid to test transport stack etc. */
        memset(big, 'A', 2100);
        bigo.len = bigo.size = 2100;
        bigo.buf = big;
        req->referenceId = &bigo;
    }
    
    if (setnumber >= 0)
    {
        sprintf(setstring, "%d", ++setnumber);
        req->resultSetName = setstring;
    }
    *req->smallSetUpperBound = smallSetUpperBound;
    *req->largeSetLowerBound = largeSetLowerBound;
    *req->mediumSetPresentNumber = mediumSetPresentNumber;
    if (smallSetUpperBound > 0 || (largeSetLowerBound > 1 &&
        mediumSetPresentNumber > 0))
    {
        if (recordsyntax_size > 0)
            req->preferredRecordSyntax =
                yaz_oidval_to_z3950oid(out, CLASS_RECSYN, recordsyntax_list[0]);
        req->smallSetElementSetNames =
            req->mediumSetElementSetNames = elementSetNames;
    }
    req->num_databaseNames = num_databaseNames;
    req->databaseNames = databaseNames;

    req->query = &query;

    switch (myQueryType)
    {
    case QueryType_Prefix:
        query.which = Z_Query_type_1;
        pqf_parser = yaz_pqf_create ();
        RPNquery = yaz_pqf_parse (pqf_parser, out, arg);
        if (!RPNquery)
        {
            const char *pqf_msg;
            size_t off;
            int code = yaz_pqf_error (pqf_parser, &pqf_msg, &off);
            int ioff = off;
            printf("%*s^\n", ioff+4, "");
            printf("Prefix query error: %s (code %d)\n", pqf_msg, code);
            
            yaz_pqf_destroy (pqf_parser);
            return 0;
        }
        yaz_pqf_destroy (pqf_parser);
        query.u.type_1 = RPNquery;
        break;
    case QueryType_CCL:
        query.which = Z_Query_type_2;
        query.u.type_2 = &ccl_query;
        ccl_query.buf = (unsigned char*) arg;
        ccl_query.len = strlen(arg);
        break;
    case QueryType_CCL2RPN:
        query.which = Z_Query_type_1;
        RPNquery = ccl_rpn_query(out, rpn);
        if (!RPNquery)
        {
            printf ("Couldn't convert from CCL to RPN\n");
            return 0;
        }
        query.u.type_1 = RPNquery;
        ccl_rpn_delete (rpn);
        break;
    case QueryType_CQL:
        query.which = Z_Query_type_104;
        ext = (Z_External *) odr_malloc(out, sizeof(*ext));
        ext->direct_reference = odr_getoidbystr(out, "1.2.840.10003.16.2");
        ext->indirect_reference = 0;
        ext->descriptor = 0;
        ext->which = Z_External_CQL;
        ext->u.cql = odr_strdup(out, arg);
        query.u.type_104 =  ext;
        break;
    default:
        printf ("Unsupported query type\n");
        return 0;
    }
    if (send_apdu(apdu))
        printf("Sent searchRequest.\n");
    setno = 1;
    return 2;
}

/* display Query Expression as part of searchResult-1 */
static void display_queryExpression (const char *lead, Z_QueryExpression *qe)
{
    if (!qe)
        return;
    printf(" %s=", lead);
    if (qe->which == Z_QueryExpression_term)
    {
        if (qe->u.term->queryTerm)
        {
            Z_Term *term = qe->u.term->queryTerm;
            switch (term->which)
            {
            case Z_Term_general:
                printf ("%.*s", term->u.general->len, term->u.general->buf);
                break;
            case Z_Term_characterString:
                printf ("%s", term->u.characterString);
                break;
            case Z_Term_numeric:
                printf ("%d", *term->u.numeric);
                break;
            case Z_Term_null:
                printf ("null");
                break;
            }
        }
    }
}

/* see if we can find USR:SearchResult-1 */
static void display_searchResult (Z_OtherInformation *o)
{
    int i;
    if (!o)
        return ;
    for (i = 0; i < o->num_elements; i++)
    {
        if (o->list[i]->which == Z_OtherInfo_externallyDefinedInfo)
        {
            Z_External *ext = o->list[i]->information.externallyDefinedInfo;
            
            if (ext->which == Z_External_searchResult1)
            {
                int j;
                Z_SearchInfoReport *sr = ext->u.searchResult1;
                printf ("SearchResult-1:");
                for (j = 0; j < sr->num; j++)
                {
                    if (j)
                        printf(",");
                    if (!sr->elements[j]->subqueryExpression)
                        printf("%d", j);
                    display_queryExpression("term",
                        sr->elements[j]->subqueryExpression);
                    display_queryExpression("interpretation",
                        sr->elements[j]->subqueryInterpretation);
                    display_queryExpression("recommendation",
                        sr->elements[j]->subqueryRecommendation);
                    if (sr->elements[j]->subqueryCount)
                        printf(" cnt=%d", *sr->elements[j]->subqueryCount);
                    if (sr->elements[j]->subqueryId)
                        printf(" id=%s ", sr->elements[j]->subqueryId);
                }
                printf ("\n");
            }
        }
    }
}

static int process_searchResponse(Z_SearchResponse *res)
{
    printf ("Received SearchResponse.\n");
    print_refid (res->referenceId);
    if (*res->searchStatus)
        printf("Search was a success.\n");
    else
        printf("Search was a bloomin' failure.\n");
    printf("Number of hits: %d", *res->resultCount);
    last_hit_count = *res->resultCount;
    if (setnumber >= 0)
        printf (", setno %d", setnumber);
    printf ("\n");
    display_searchResult (res->additionalSearchInfo);
    printf("records returned: %d\n",
           *res->numberOfRecordsReturned);
    setno += *res->numberOfRecordsReturned;
    if (res->records)
        display_records(res->records);
    return 0;
}

static void print_level(int iLevel)
{
    int i;
    for (i = 0; i < iLevel * 4; i++)
        printf(" ");
}

static void print_int(int iLevel, const char *pTag, int *pInt)
{
    if (pInt != NULL)
    {
        print_level(iLevel);
        printf("%s: %d\n", pTag, *pInt);
    }
}

static void print_string(int iLevel, const char *pTag, const char *pString)
{
    if (pString != NULL)
    {
        print_level(iLevel);
        printf("%s: %s\n", pTag, pString);
    }
}

static void print_oid(int iLevel, const char *pTag, Odr_oid *pOid)
{
    if (pOid != NULL)
    {
        int *pInt = pOid;

        print_level(iLevel);
        printf("%s:", pTag);
        for (; *pInt != -1; pInt++)
            printf(" %d", *pInt);
        printf("\n");
    }
}

static void print_referenceId(int iLevel, Z_ReferenceId *referenceId)
{
    if (referenceId != NULL)
    {
        int i;

        print_level(iLevel);
        printf("Ref Id (%d, %d): ", referenceId->len, referenceId->size);
        for (i = 0; i < referenceId->len; i++)
            printf("%c", referenceId->buf[i]);
        printf("\n");
    }
}

static void print_string_or_numeric(int iLevel, const char *pTag, Z_StringOrNumeric *pStringNumeric)
{
    if (pStringNumeric != NULL)
    {
        switch (pStringNumeric->which)
        {
        case Z_StringOrNumeric_string:
            print_string(iLevel, pTag, pStringNumeric->u.string);
            break;
            
        case Z_StringOrNumeric_numeric:
            print_int(iLevel, pTag, pStringNumeric->u.numeric);
            break;
            
        default:
            print_level(iLevel);
            printf("%s: valid type for Z_StringOrNumeric\n", pTag);
            break;
        }
    }
}

static void print_universe_report_duplicate(
    int iLevel,
    Z_UniverseReportDuplicate *pUniverseReportDuplicate)
{
    if (pUniverseReportDuplicate != NULL)
    {
        print_level(iLevel);
        printf("Universe Report Duplicate: \n");
        iLevel++;
        print_string_or_numeric(iLevel, "Hit No",
                                pUniverseReportDuplicate->hitno);
    }
}

static void print_universe_report_hits(
    int iLevel,
    Z_UniverseReportHits *pUniverseReportHits)
{
    if (pUniverseReportHits != NULL)
    {
        print_level(iLevel);
        printf("Universe Report Hits: \n");
        iLevel++;
        print_string_or_numeric(iLevel, "Database",
                                pUniverseReportHits->database);
        print_string_or_numeric(iLevel, "Hits", pUniverseReportHits->hits);
    }
}

static void print_universe_report(int iLevel, Z_UniverseReport *pUniverseReport)
{
    if (pUniverseReport != NULL)
    {
        print_level(iLevel);
        printf("Universe Report: \n");
        iLevel++;
        print_int(iLevel, "Total Hits", pUniverseReport->totalHits);
        switch (pUniverseReport->which)
        {
        case Z_UniverseReport_databaseHits:
            print_universe_report_hits(iLevel,
                                       pUniverseReport->u.databaseHits);
            break;
            
        case Z_UniverseReport_duplicate:
            print_universe_report_duplicate(iLevel,
                                            pUniverseReport->u.duplicate);
            break;
            
        default:
            print_level(iLevel);
            printf("Type: %d\n", pUniverseReport->which);
            break;
        }
    }
}

static void print_external(int iLevel, Z_External *pExternal)
{
    if (pExternal != NULL)
    {
        print_level(iLevel);
        printf("External: \n");
        iLevel++;
        print_oid(iLevel, "Direct Reference", pExternal->direct_reference);
        print_int(iLevel, "InDirect Reference", pExternal->indirect_reference);
        print_string(iLevel, "Descriptor", pExternal->descriptor);
        switch (pExternal->which)
        {
        case Z_External_universeReport:
            print_universe_report(iLevel, pExternal->u.universeReport);
            break;
            
        default:
            print_level(iLevel);
            printf("Type: %d\n", pExternal->which);
            break;
        }
    }
}

static int process_resourceControlRequest (Z_ResourceControlRequest *req)
{
    printf ("Received ResourceControlRequest.\n");
    print_referenceId(1, req->referenceId);
    print_int(1, "Suspended Flag", req->suspendedFlag);
    print_int(1, "Partial Results Available", req->partialResultsAvailable);
    print_int(1, "Response Required", req->responseRequired);
    print_int(1, "Triggered Request Flag", req->triggeredRequestFlag);
    print_external(1, req->resourceReport);
    return 0;
}

void process_ESResponse(Z_ExtendedServicesResponse *res)
{
    printf("Status: ");
    switch (*res->operationStatus)
    {
    case Z_ExtendedServicesResponse_done:
        printf ("done\n");
        break;
    case Z_ExtendedServicesResponse_accepted:
        printf ("accepted\n");
        break;
    case Z_ExtendedServicesResponse_failure:
        printf ("failure\n");
        display_diagrecs(res->diagnostics, res->num_diagnostics);
        break;
    default:
        printf ("unknown\n");
    }
    if ( (*res->operationStatus != Z_ExtendedServicesResponse_failure) &&
        (res->num_diagnostics != 0) ) {
        display_diagrecs(res->diagnostics, res->num_diagnostics);
    }
    print_refid (res->referenceId);
    if (res->taskPackage && 
        res->taskPackage->which == Z_External_extendedService)
    {
        Z_TaskPackage *taskPackage = res->taskPackage->u.extendedService;
        Odr_oct *id = taskPackage->targetReference;
        Z_External *ext = taskPackage->taskSpecificParameters;
        
        if (id)
        {
            printf ("Target Reference: ");
            print_stringn (id->buf, id->len);
            printf ("\n");
        }
        if (ext->which == Z_External_update)
        {
            Z_IUUpdateTaskPackage *utp = ext->u.update->u.taskPackage;
            if (utp && utp->targetPart)
            {
                Z_IUTargetPart *targetPart = utp->targetPart;
                int i;

                for (i = 0; i<targetPart->num_taskPackageRecords;  i++)
                {

                    Z_IUTaskPackageRecordStructure *tpr =
                        targetPart->taskPackageRecords[i];
                    printf ("task package record %d\n", i+1);
                    if (tpr->which == Z_IUTaskPackageRecordStructure_record)
                    {
                        display_record (tpr->u.record);
                    }
                    else
                    {
                        printf ("other type\n");
                    }
                }
            }
        }
    }
    if (res->taskPackage && res->taskPackage->which == Z_External_octet)
    {
        Odr_oct *doc = res->taskPackage->u.octet_aligned;
        printf("%.*s\n", doc->len, doc->buf);
    }
}

const char *get_ill_element (void *clientData, const char *element)
{
    return 0;
}

static Z_External *create_external_itemRequest(void)
{
    struct ill_get_ctl ctl;
    ILL_ItemRequest *req;
    Z_External *r = 0;
    int item_request_size = 0;
    char *item_request_buf = 0;

    ctl.odr = out;
    ctl.clientData = 0;
    ctl.f = get_ill_element;
    
    req = ill_get_ItemRequest(&ctl, "ill", 0);
    if (!req)
        printf ("ill_get_ItemRequest failed\n");
        
    if (!ill_ItemRequest (out, &req, 0, 0))
    {
        if (apdu_file)
        {
            ill_ItemRequest(print, &req, 0, 0);
            odr_reset(print);
        }
        item_request_buf = odr_getbuf (out, &item_request_size, 0);
        if (item_request_buf)
            odr_setbuf (out, item_request_buf, item_request_size, 1);
        printf ("Couldn't encode ItemRequest, size %d\n", item_request_size);
        return 0;
    }
    else
    {
        oident oid;
        
        item_request_buf = odr_getbuf (out, &item_request_size, 0);
        oid.proto = PROTO_GENERAL;
        oid.oclass = CLASS_GENERAL;
        oid.value = VAL_ISO_ILL_1;
        
        r = (Z_External *) odr_malloc (out, sizeof(*r));
        r->direct_reference = odr_oiddup(out,oid_getoidbyent(&oid)); 
        r->indirect_reference = 0;
        r->descriptor = 0;
        r->which = Z_External_single;
        
        r->u.single_ASN1_type = (Odr_oct *)
            odr_malloc (out, sizeof(*r->u.single_ASN1_type));
        r->u.single_ASN1_type->buf = (unsigned char *)
        odr_malloc (out, item_request_size);
        r->u.single_ASN1_type->len = item_request_size;
        r->u.single_ASN1_type->size = item_request_size;
        memcpy (r->u.single_ASN1_type->buf, item_request_buf,
                item_request_size);
        
        do_hex_dump(item_request_buf,item_request_size);
    }
    return r;
}

static Z_External *create_external_ILL_APDU(int which)
{
    struct ill_get_ctl ctl;
    ILL_APDU *ill_apdu;
    Z_External *r = 0;
    int ill_request_size = 0;
    char *ill_request_buf = 0;
        
    ctl.odr = out;
    ctl.clientData = 0;
    ctl.f = get_ill_element;

    ill_apdu = ill_get_APDU(&ctl, "ill", 0);

    if (!ill_APDU (out, &ill_apdu, 0, 0))
    {
        if (apdu_file)
        {
            printf ("-------------------\n");
            ill_APDU(print, &ill_apdu, 0, 0);
            odr_reset(print);
            printf ("-------------------\n");
        }
        ill_request_buf = odr_getbuf (out, &ill_request_size, 0);
        if (ill_request_buf)
            odr_setbuf (out, ill_request_buf, ill_request_size, 1);
        printf ("Couldn't encode ILL-Request, size %d\n", ill_request_size);
        return 0;
    }
    else
    {
        oident oid;
        ill_request_buf = odr_getbuf (out, &ill_request_size, 0);
        
        oid.proto = PROTO_GENERAL;
        oid.oclass = CLASS_GENERAL;
        oid.value = VAL_ISO_ILL_1;
        
        r = (Z_External *) odr_malloc (out, sizeof(*r));
        r->direct_reference = odr_oiddup(out,oid_getoidbyent(&oid)); 
        r->indirect_reference = 0;
        r->descriptor = 0;
        r->which = Z_External_single;
        
        r->u.single_ASN1_type = (Odr_oct *)
            odr_malloc (out, sizeof(*r->u.single_ASN1_type));
        r->u.single_ASN1_type->buf = (unsigned char *)
        odr_malloc (out, ill_request_size);
        r->u.single_ASN1_type->len = ill_request_size;
        r->u.single_ASN1_type->size = ill_request_size;
        memcpy (r->u.single_ASN1_type->buf, ill_request_buf, ill_request_size);
/*         printf ("len = %d\n", ill_request_size); */
/*              do_hex_dump(ill_request_buf,ill_request_size); */
/*              printf("--- end of extenal\n"); */

    }
    return r;
}


static Z_External *create_ItemOrderExternal(const char *type, int itemno)
{
    Z_External *r = (Z_External *) odr_malloc(out, sizeof(Z_External));
    oident ItemOrderRequest;
  
    ItemOrderRequest.proto = PROTO_Z3950;
    ItemOrderRequest.oclass = CLASS_EXTSERV;
    ItemOrderRequest.value = VAL_ITEMORDER;
 
    r->direct_reference = odr_oiddup(out,oid_getoidbyent(&ItemOrderRequest)); 
    r->indirect_reference = 0;
    r->descriptor = 0;

    r->which = Z_External_itemOrder;

    r->u.itemOrder = (Z_ItemOrder *) odr_malloc(out,sizeof(Z_ItemOrder));
    memset(r->u.itemOrder, 0, sizeof(Z_ItemOrder));
    r->u.itemOrder->which=Z_IOItemOrder_esRequest;

    r->u.itemOrder->u.esRequest = (Z_IORequest *) 
        odr_malloc(out,sizeof(Z_IORequest));
    memset(r->u.itemOrder->u.esRequest, 0, sizeof(Z_IORequest));

    r->u.itemOrder->u.esRequest->toKeep = (Z_IOOriginPartToKeep *)
        odr_malloc(out,sizeof(Z_IOOriginPartToKeep));
    memset(r->u.itemOrder->u.esRequest->toKeep, 0, sizeof(Z_IOOriginPartToKeep));
    r->u.itemOrder->u.esRequest->notToKeep = (Z_IOOriginPartNotToKeep *)
        odr_malloc(out,sizeof(Z_IOOriginPartNotToKeep));
    memset(r->u.itemOrder->u.esRequest->notToKeep, 0, sizeof(Z_IOOriginPartNotToKeep));

    r->u.itemOrder->u.esRequest->toKeep->supplDescription = NULL;
    r->u.itemOrder->u.esRequest->toKeep->contact = NULL;
    r->u.itemOrder->u.esRequest->toKeep->addlBilling = NULL;

    r->u.itemOrder->u.esRequest->notToKeep->resultSetItem =
        (Z_IOResultSetItem *) odr_malloc(out, sizeof(Z_IOResultSetItem));
    memset(r->u.itemOrder->u.esRequest->notToKeep->resultSetItem, 0, sizeof(Z_IOResultSetItem));
    r->u.itemOrder->u.esRequest->notToKeep->resultSetItem->resultSetId = "1";

    r->u.itemOrder->u.esRequest->notToKeep->resultSetItem->item =
        (int *) odr_malloc(out, sizeof(int));
    *r->u.itemOrder->u.esRequest->notToKeep->resultSetItem->item = itemno;

    if (!strcmp (type, "item") || !strcmp(type, "2"))
    {
        printf ("using item-request\n");
        r->u.itemOrder->u.esRequest->notToKeep->itemRequest = 
            create_external_itemRequest();
    }
    else if (!strcmp(type, "ill") || !strcmp(type, "1"))
    {
        printf ("using ILL-request\n");
        r->u.itemOrder->u.esRequest->notToKeep->itemRequest = 
            create_external_ILL_APDU(ILL_APDU_ILL_Request);
    }
    else if (!strcmp(type, "xml") || !strcmp(type, "3"))
    {
    const char *xml_buf =
        "<itemorder>\n"
        "  <type>request</type>\n"
        "  <libraryNo>000200</libraryNo>\n"
        "  <borrowerTicketNo> 1212 </borrowerTicketNo>\n"
        "</itemorder>";
        r->u.itemOrder->u.esRequest->notToKeep->itemRequest =
            z_ext_record (out, VAL_TEXT_XML, xml_buf, strlen(xml_buf));
    }
    else
        r->u.itemOrder->u.esRequest->notToKeep->itemRequest = 0;

    return r;
}

static int send_itemorder(const char *type, int itemno)
{
    Z_APDU *apdu = zget_APDU(out, Z_APDU_extendedServicesRequest);
    Z_ExtendedServicesRequest *req = apdu->u.extendedServicesRequest;
    oident ItemOrderRequest;


    req->referenceId = set_refid (out);

    ItemOrderRequest.proto = PROTO_Z3950;
    ItemOrderRequest.oclass = CLASS_EXTSERV;
    ItemOrderRequest.value = VAL_ITEMORDER;
    req->packageType = odr_oiddup(out,oid_getoidbyent(&ItemOrderRequest));
    req->packageName = esPackageName;

    req->taskSpecificParameters = create_ItemOrderExternal(type, itemno);

    send_apdu(apdu);
    return 0;
}

static int only_z3950(void)
{
    if (!conn)
    {
        printf ("Not connected yet\n");
        return 1;
    }
    if (protocol == PROTO_HTTP)
    {
        printf ("Not supported by SRW\n");
        return 1;
    }
    return 0;
}

static int cmd_update_common(const char *arg, int version);

static int cmd_update(const char *arg)
{
    return cmd_update_common(arg, 1);
}

static int cmd_update0(const char *arg)
{
    return cmd_update_common(arg, 0);
}

static int cmd_update_Z3950(int version, int action_no, const char *recid,
                            char *rec_buf, int rec_len);

static int cmd_update_SRW(int action_no, const char *recid,
                          char *rec_buf, int rec_len);

static int cmd_update_common(const char *arg, int version)
{
    char action[20], recid[20];
    char *rec_buf;
    int rec_len;
    int action_no;
    int noread = 0;

    *action = 0;
    *recid = 0;
    sscanf (arg, "%19s %19s%n", action, recid, &noread);
    if (noread == 0)
    {
        printf("Update must be followed by action and recid\n");
        printf(" where action is one of insert,replace,delete.update\n");
        printf(" recid is some record ID (any string)\n");
        return 0;
    }

    if (!strcmp (action, "insert"))
        action_no = Z_IUOriginPartToKeep_recordInsert;
    else if (!strcmp (action, "replace"))
        action_no = Z_IUOriginPartToKeep_recordReplace;
    else if (!strcmp (action, "delete"))
        action_no = Z_IUOriginPartToKeep_recordDelete;
    else if (!strcmp (action, "update"))
        action_no = Z_IUOriginPartToKeep_specialUpdate;
    else 
    {
        printf ("Bad action: %s\n", action);
        printf ("Possible values: insert, replace, delete, update\n");
        return 0;
    }

    arg += noread;
    if (parse_cmd_doc(&arg, out, &rec_buf, &rec_len, 1) == 0)
        return 0;

#if YAZ_HAVE_XML2
    if (protocol == PROTO_HTTP)
        return cmd_update_SRW(action_no, recid, rec_buf, rec_len);
#endif
    return cmd_update_Z3950(version, action_no, recid, rec_buf, rec_len);
}

#if YAZ_HAVE_XML2
static int cmd_update_SRW(int action_no, const char *recid,
                          char *rec_buf, int rec_len)
{
    if (!conn)
        cmd_open(0);
    if (!conn)
        return 0;
    else
    {
        Z_SRW_PDU *srw = yaz_srw_get(out, Z_SRW_update_request);
        Z_SRW_updateRequest *sr = srw->u.update_request;

        switch(action_no)
        {
        case Z_IUOriginPartToKeep_recordInsert:
            sr->operation = "info:srw/action/1/create";
            break;
        case Z_IUOriginPartToKeep_recordReplace:
            sr->operation = "info:srw/action/1/replace";
            break;
        case Z_IUOriginPartToKeep_recordDelete:
            sr->operation = "info:srw/action/1/delete";
            break;
        }
        if (rec_buf)
        {
            sr->record = yaz_srw_get_record(out);
            sr->record->recordData_buf = rec_buf;
            sr->record->recordData_len = rec_len;
            sr->record->recordSchema = record_schema;
        }
        if (recid)
            sr->recordId = odr_strdup(out, recid);
        return send_srw(srw);
    }
}
#endif
                          
static int cmd_update_Z3950(int version, int action_no, const char *recid,
                            char *rec_buf, int rec_len)
{
    Z_APDU *apdu = zget_APDU(out, Z_APDU_extendedServicesRequest );
    Z_ExtendedServicesRequest *req = apdu->u.extendedServicesRequest;
    Z_External *r;
    Z_External *record_this = 0;

    if (rec_buf)
        record_this = z_ext_record (out, VAL_TEXT_XML, rec_buf, rec_len);
    else
    {
        if (!record_last)
        {
            printf ("No last record (update ignored)\n");
            return 0;
        }
        record_this = record_last;
    }

    req->packageType =
        yaz_oidval_to_z3950oid(out, CLASS_EXTSERV,
                               version == 0 ? VAL_DBUPDATE0 : VAL_DBUPDATE);

    req->packageName = esPackageName;
    
    req->referenceId = set_refid (out);

    r = req->taskSpecificParameters = (Z_External *)
        odr_malloc (out, sizeof(*r));
    r->direct_reference = req->packageType;
    r->indirect_reference = 0;
    r->descriptor = 0;
    if (version == 0)
    {
        Z_IU0OriginPartToKeep *toKeep;
        Z_IU0SuppliedRecords *notToKeep;

        r->which = Z_External_update0;
        r->u.update0 = (Z_IU0Update *) odr_malloc(out, sizeof(*r->u.update0));
        r->u.update0->which = Z_IUUpdate_esRequest;
        r->u.update0->u.esRequest = (Z_IU0UpdateEsRequest *)
            odr_malloc(out, sizeof(*r->u.update0->u.esRequest));
        toKeep = r->u.update0->u.esRequest->toKeep = (Z_IU0OriginPartToKeep *)
            odr_malloc(out, sizeof(*r->u.update0->u.esRequest->toKeep));
        
        toKeep->databaseName = databaseNames[0];
        toKeep->schema = 0;
        toKeep->elementSetName = 0;

        toKeep->action = (int *) odr_malloc(out, sizeof(*toKeep->action));
        *toKeep->action = action_no;
        
        notToKeep = r->u.update0->u.esRequest->notToKeep = (Z_IU0SuppliedRecords *)
            odr_malloc(out, sizeof(*r->u.update0->u.esRequest->notToKeep));
        notToKeep->num = 1;
        notToKeep->elements = (Z_IU0SuppliedRecords_elem **)
            odr_malloc(out, sizeof(*notToKeep->elements));
        notToKeep->elements[0] = (Z_IU0SuppliedRecords_elem *)
            odr_malloc(out, sizeof(**notToKeep->elements));
        notToKeep->elements[0]->which = Z_IUSuppliedRecords_elem_opaque;
        if (*recid && strcmp(recid, "none"))
        {
            notToKeep->elements[0]->u.opaque = (Odr_oct *)
                odr_malloc (out, sizeof(Odr_oct));
            notToKeep->elements[0]->u.opaque->buf = (unsigned char *) recid;
            notToKeep->elements[0]->u.opaque->size = strlen(recid);
            notToKeep->elements[0]->u.opaque->len = strlen(recid);
        }
        else
            notToKeep->elements[0]->u.opaque = 0;
        notToKeep->elements[0]->supplementalId = 0;
        notToKeep->elements[0]->correlationInfo = 0;
        notToKeep->elements[0]->record = record_this;
    }
    else
    {
        Z_IUOriginPartToKeep *toKeep;
        Z_IUSuppliedRecords *notToKeep;

        r->which = Z_External_update;
        r->u.update = (Z_IUUpdate *) odr_malloc(out, sizeof(*r->u.update));
        r->u.update->which = Z_IUUpdate_esRequest;
        r->u.update->u.esRequest = (Z_IUUpdateEsRequest *)
            odr_malloc(out, sizeof(*r->u.update->u.esRequest));
        toKeep = r->u.update->u.esRequest->toKeep = (Z_IUOriginPartToKeep *)
            odr_malloc(out, sizeof(*r->u.update->u.esRequest->toKeep));
        
        toKeep->databaseName = databaseNames[0];
        toKeep->schema = 0;
        toKeep->elementSetName = 0;
        toKeep->actionQualifier = 0;
        toKeep->action = (int *) odr_malloc(out, sizeof(*toKeep->action));
        *toKeep->action = action_no;

        notToKeep = r->u.update->u.esRequest->notToKeep = (Z_IUSuppliedRecords *)
            odr_malloc(out, sizeof(*r->u.update->u.esRequest->notToKeep));
        notToKeep->num = 1;
        notToKeep->elements = (Z_IUSuppliedRecords_elem **)
            odr_malloc(out, sizeof(*notToKeep->elements));
        notToKeep->elements[0] = (Z_IUSuppliedRecords_elem *)
            odr_malloc(out, sizeof(**notToKeep->elements));
        notToKeep->elements[0]->which = Z_IUSuppliedRecords_elem_opaque;
        if (*recid)
        {
            notToKeep->elements[0]->u.opaque = (Odr_oct *)
                odr_malloc (out, sizeof(Odr_oct));
            notToKeep->elements[0]->u.opaque->buf = (unsigned char *) recid;
            notToKeep->elements[0]->u.opaque->size = strlen(recid);
            notToKeep->elements[0]->u.opaque->len = strlen(recid);
        }
        else
            notToKeep->elements[0]->u.opaque = 0;
        notToKeep->elements[0]->supplementalId = 0;
        notToKeep->elements[0]->correlationInfo = 0;
        notToKeep->elements[0]->record = record_this;
    }
    
    send_apdu(apdu);

    return 2;
}

static int cmd_xmles(const char *arg)
{
    if (only_z3950())
        return 1;
    else
    {
        char *asn_buf = 0;
        int noread = 0;
        char oid_str[51];
        int oid_value_xmles = VAL_XMLES;
        Z_APDU *apdu = zget_APDU(out, Z_APDU_extendedServicesRequest);
        Z_ExtendedServicesRequest *req = apdu->u.extendedServicesRequest;
        

        Z_External *ext = (Z_External *) odr_malloc(out, sizeof(*ext));
        
        req->referenceId = set_refid (out);
        req->taskSpecificParameters = ext;
        ext->indirect_reference = 0;
        ext->descriptor = 0;
        ext->which = Z_External_octet;
        ext->u.single_ASN1_type = (Odr_oct *) odr_malloc (out, sizeof(Odr_oct));        
        sscanf(arg, "%50s%n", oid_str, &noread);
        if (noread == 0)
        {
            printf("Missing OID for xmles\n");
            return 0;
        }
        arg += noread;
        oid_value_xmles  = oid_getvalbyname(oid_str);
        if (oid_value_xmles == VAL_NONE)
        {
            printf("Bad OID: %s\n", oid_str);
            return 0;
        }

        if (parse_cmd_doc(&arg, out, &asn_buf,
                          &ext->u.single_ASN1_type->len, 0) == 0)
            return 0;

        ext->u.single_ASN1_type->buf = (unsigned char *) asn_buf;

        req->packageType = yaz_oidval_to_z3950oid(out, CLASS_EXTSERV,
                                                  oid_value_xmles);
        
        ext->direct_reference = yaz_oidval_to_z3950oid(out, CLASS_EXTSERV,
                                                       oid_value_xmles);
        send_apdu(apdu);
        
        return 2;
    }
}

static int cmd_itemorder(const char *arg)
{
    char type[12];
    int itemno;
   
    if (only_z3950())
        return 1;
    if (sscanf (arg, "%10s %d", type, &itemno) != 2)
        return 0;

    printf("Item order request\n");
    fflush(stdout);
    send_itemorder(type, itemno);
    return 2;
}

static void show_opt(const char *arg, void *clientData)
{
    printf ("%s ", arg);
}

static int cmd_zversion(const char *arg)
{
    if (*arg && arg)
        z3950_version = atoi(arg);
    else
        printf ("version is %d\n", z3950_version);
    return 0;
}

static int cmd_options(const char *arg)
{
    if (*arg)
    {
        int r;
        int pos;
        r = yaz_init_opt_encode(&z3950_options, arg, &pos);
        if (r == -1)
            printf("Unknown option(s) near %s\n", arg+pos);
    }
    else
    {
        yaz_init_opt_decode(&z3950_options, show_opt, 0);
        printf ("\n");
    }
    return 0;
}

static int cmd_explain(const char *arg)
{
    if (protocol != PROTO_HTTP)
        return 0;
#if YAZ_HAVE_XML2
    if (!conn)
        cmd_open(0);
    if (conn)
    {
        Z_SRW_PDU *sr = 0;
        
        setno = 1;
        
        /* save this for later .. when fetching individual records */
        sr = yaz_srw_get(out, Z_SRW_explain_request);
        if (recordsyntax_size > 0 && recordsyntax_list[0] == VAL_TEXT_XML)
            sr->u.explain_request->recordPacking = "xml";
        send_srw(sr);
        return 2;
    }
#endif
    return 0;
}

static int cmd_init(const char *arg)
{
    if (*arg)
    {
        strncpy (cur_host, arg, sizeof(cur_host)-1);
        cur_host[sizeof(cur_host)-1] = 0;
    }
    if (only_z3950())
        return 1;
    send_initRequest(cur_host);
    return 2;
}

static int cmd_sru(const char *arg)
{
    if (!*arg)
    {
        printf("SRU method is: %s\n", sru_method);
    }
    else
    {
        if (!yaz_matchstr(arg, "post"))
            sru_method = "post";
        else if (!yaz_matchstr(arg, "get"))
            sru_method = "get";
        else if (!yaz_matchstr(arg, "soap"))
            sru_method = "soap";
        else
        {
            printf("Unknown SRU method: %s\n", arg);
            printf("Specify one of POST, GET, SOAP\n");
        }
    }
    return 0;
}

static int cmd_find(const char *arg)
{
    if (!*arg)
    {
        printf("Find what?\n");
        return 0;
    }
    if (protocol == PROTO_HTTP)
    {
#if YAZ_HAVE_XML2
        if (!conn)
            cmd_open(0);
        if (!conn)
            return 0;
        if (!send_SRW_searchRequest(arg))
            return 0;
#else
        return 0;
#endif
    }
    else
    {
        if (!conn)
        {
            try_reconnect(); 
            
            if (!conn) {                                        
                printf("Not connected yet\n");
                return 0;
            }
        }
        if (!send_searchRequest(arg))
            return 0;
    }
    return 2;
}

static int cmd_delete(const char *arg)
{
    if (only_z3950())
        return 0;
    if (!send_deleteResultSetRequest(arg))
        return 0;
    return 2;
}

static int cmd_ssub(const char *arg)
{
    if (!(smallSetUpperBound = atoi(arg)))
        return 0;
    return 1;
}

static int cmd_lslb(const char *arg)
{
    if (!(largeSetLowerBound = atoi(arg)))
        return 0;
    return 1;
}

static int cmd_mspn(const char *arg)
{
    if (!(mediumSetPresentNumber = atoi(arg)))
        return 0;
    return 1;
}

static int cmd_status(const char *arg)
{
    printf("smallSetUpperBound: %d\n", smallSetUpperBound);
    printf("largeSetLowerBound: %d\n", largeSetLowerBound);
    printf("mediumSetPresentNumber: %d\n", mediumSetPresentNumber);
    return 1;
}

static int cmd_setnames(const char *arg)
{
    if (*arg == '1')         /* enable ? */
        setnumber = 0;
    else if (*arg == '0')    /* disable ? */
        setnumber = -1;
    else if (setnumber < 0)  /* no args, toggle .. */
        setnumber = 0;
    else
        setnumber = -1;
   
    if (setnumber >= 0)
        printf("Set numbering enabled.\n");
    else
        printf("Set numbering disabled.\n");
    return 1;
}

/* PRESENT SERVICE ----------------------------- */

static void parse_show_args(const char *arg_c, char *setstring,
                            int *start, int *number)
{
    char arg[40];
    char *p;

    strncpy(arg, arg_c, sizeof(arg)-1);
    arg[sizeof(arg)-1] = '\0';

    if ((p = strchr(arg, '+')))
    {
        *number = atoi(p + 1);
        *p = '\0';
    }
    if (*arg)
    {
        if (!strcmp(arg, "all"))
        {
            *number = last_hit_count;
            *start = 1;
        }
        else
            *start = atoi(arg);
    }
    if (p && (p=strchr(p+1, '+')))
        strcpy (setstring, p+1);
    else if (setnumber >= 0)
        sprintf(setstring, "%d", setnumber);
    else
        *setstring = '\0';
}

static int send_presentRequest(const char *arg)
{
    Z_APDU *apdu = zget_APDU(out, Z_APDU_presentRequest);
    Z_PresentRequest *req = apdu->u.presentRequest;
    Z_RecordComposition compo;
    int nos = 1;
    char setstring[100];

    req->referenceId = set_refid (out);

    parse_show_args(arg, setstring, &setno, &nos);
    if (*setstring)
        req->resultSetId = setstring;

    req->resultSetStartPoint = &setno;
    req->numberOfRecordsRequested = &nos;

    if (recordsyntax_size == 1)
        req->preferredRecordSyntax =
            yaz_oidval_to_z3950oid(out, CLASS_RECSYN, recordsyntax_list[0]);

    if (record_schema || recordsyntax_size >= 2)
    {
        req->recordComposition = &compo;
        compo.which = Z_RecordComp_complex;
        compo.u.complex = (Z_CompSpec *)
            odr_malloc(out, sizeof(*compo.u.complex));
        compo.u.complex->selectAlternativeSyntax = (bool_t *) 
            odr_malloc(out, sizeof(bool_t));
        *compo.u.complex->selectAlternativeSyntax = 0;

        compo.u.complex->generic = (Z_Specification *)
            odr_malloc(out, sizeof(*compo.u.complex->generic));
        
        compo.u.complex->generic->which = Z_Schema_oid;
        if (!record_schema)
            compo.u.complex->generic->schema.oid = 0;
        else 
        {
            compo.u.complex->generic->schema.oid =
                yaz_str_to_z3950oid(out, CLASS_SCHEMA, record_schema);
            
            if (!compo.u.complex->generic->schema.oid)
            {
                /* OID wasn't a schema! Try record syntax instead. */
                compo.u.complex->generic->schema.oid = (Odr_oid *)
                    yaz_str_to_z3950oid(out, CLASS_RECSYN, record_schema);
            }
        }
        if (!elementSetNames)
            compo.u.complex->generic->elementSpec = 0;
        else
        {
            compo.u.complex->generic->elementSpec = (Z_ElementSpec *)
                odr_malloc(out, sizeof(Z_ElementSpec));
            compo.u.complex->generic->elementSpec->which =
                Z_ElementSpec_elementSetName;
            compo.u.complex->generic->elementSpec->u.elementSetName =
                elementSetNames->u.generic;
        }
        compo.u.complex->num_dbSpecific = 0;
        compo.u.complex->dbSpecific = 0;
        if (recordsyntax_size >= 2)
        {
            int i;
            compo.u.complex->num_recordSyntax = recordsyntax_size;
            compo.u.complex->recordSyntax = (Odr_oid **)
                odr_malloc(out, recordsyntax_size * sizeof(Odr_oid*));
            for (i = 0; i < recordsyntax_size; i++)
            compo.u.complex->recordSyntax[i] =                 
                yaz_oidval_to_z3950oid(out, CLASS_RECSYN,
                                       recordsyntax_list[i]);
        }
        else
        {
            compo.u.complex->num_recordSyntax = 0;
            compo.u.complex->recordSyntax = 0;
        }
    }
    else if (elementSetNames)
    {
        req->recordComposition = &compo;
        compo.which = Z_RecordComp_simple;
        compo.u.simple = elementSetNames;
    }
    send_apdu(apdu);
    printf("Sent presentRequest (%d+%d).\n", setno, nos);
    return 2;
}

#if YAZ_HAVE_XML2
static int send_SRW_presentRequest(const char *arg)
{
    char setstring[100];
    int nos = 1;
    Z_SRW_PDU *sr = srw_sr;

    if (!sr)
        return 0;
    parse_show_args(arg, setstring, &setno, &nos);
    sr->u.request->startRecord = odr_intdup(out, setno);
    sr->u.request->maximumRecords = odr_intdup(out, nos);
    if (record_schema)
        sr->u.request->recordSchema = record_schema;
    if (recordsyntax_size == 1 && recordsyntax_list[0] == VAL_TEXT_XML)
        sr->u.request->recordPacking = "xml";
    return send_srw(sr);
}
#endif

static void close_session (void)
{
    if (conn)
        cs_close (conn);
    conn = 0;
    sent_close = 0;
    odr_reset(out);
    odr_reset(in);
    odr_reset(print);
    last_hit_count = 0;
}

void process_close(Z_Close *req)
{
    Z_APDU *apdu = zget_APDU(out, Z_APDU_close);
    Z_Close *res = apdu->u.close;

    static char *reasons[] =
    {
        "finished",
        "shutdown",
        "system problem",
        "cost limit reached",
        "resources",
        "security violation",
        "protocolError",
        "lack of activity",
        "peer abort",
        "unspecified"
    };

    printf("Reason: %s, message: %s\n", reasons[*req->closeReason],
        req->diagnosticInformation ? req->diagnosticInformation : "NULL");
    if (sent_close)
        close_session ();
    else
    {
        *res->closeReason = Z_Close_finished;
        send_apdu(apdu);
        printf("Sent response.\n");
        sent_close = 1;
    }
}

static int cmd_show(const char *arg)
{
    if (protocol == PROTO_HTTP)
    {
#if YAZ_HAVE_XML2
        if (!conn)
            cmd_open(0);
        if (!conn)
            return 0;
        if (!send_SRW_presentRequest(arg))
            return 0;
#else
        return 0;
#endif
    }
    else
    {
        if (!conn)
        {
            printf("Not connected yet\n");
            return 0;
        }
        if (!send_presentRequest(arg))
            return 0;
    }
    return 2;
}

int cmd_quit(const char *arg)
{
    printf("See you later, alligator.\n");
    xmalloc_trav ("");
    exit(0);
    return 0;
}

int cmd_cancel(const char *arg)
{
    Z_APDU *apdu = zget_APDU(out, Z_APDU_triggerResourceControlRequest);
    Z_TriggerResourceControlRequest *req =
        apdu->u.triggerResourceControlRequest;
    bool_t rfalse = 0;
    char command[16];
  
    *command = '\0';
    sscanf(arg, "%15s", command);

    if (only_z3950())
        return 0;
    if (session_initResponse &&
        !ODR_MASK_GET(session_initResponse->options,
                      Z_Options_triggerResourceCtrl))
    {
        printf("Target doesn't support cancel (trigger resource ctrl)\n");
        return 0;
    }
    *req->requestedAction = Z_TriggerResourceControlRequest_cancel;
    req->resultSetWanted = &rfalse;
    req->referenceId = set_refid (out);

    send_apdu(apdu);
    printf("Sent cancel request\n");
    if (!strcmp(command, "wait"))
         return 2;
    return 1;
}


int cmd_cancel_find(const char *arg) {
    int fres;
    fres=cmd_find(arg);
    if( fres > 0 ) {
        return cmd_cancel("");
    };
    return fres;
}

int send_scanrequest(const char *query, int pp, int num, const char *term)
{
    Z_APDU *apdu = zget_APDU(out, Z_APDU_scanRequest);
    Z_ScanRequest *req = apdu->u.scanRequest;
    
    if (only_z3950())
        return 0;
    if (queryType == QueryType_CCL2RPN)
    {
        int error, pos;
        struct ccl_rpn_node *rpn;

        rpn = ccl_find_str (bibset,  query, &error, &pos);
        if (error)
        {
            printf("CCL ERROR: %s\n", ccl_err_msg(error));
            return -1;
        }
        req->attributeSet =
            yaz_oidval_to_z3950oid(out, CLASS_ATTSET, VAL_BIB1);
        if (!(req->termListAndStartPoint = ccl_scan_query (out, rpn)))
        {
            printf("Couldn't convert CCL to Scan term\n");
            return -1;
        }
        ccl_rpn_delete (rpn);
    }
    else
    {
        YAZ_PQF_Parser pqf_parser = yaz_pqf_create ();

        if (!(req->termListAndStartPoint =
              yaz_pqf_scan(pqf_parser, out, &req->attributeSet, query)))
        {
            const char *pqf_msg;
            size_t off;
            int code = yaz_pqf_error (pqf_parser, &pqf_msg, &off);
            int ioff = off;
            printf("%*s^\n", ioff+7, "");
            printf("Prefix query error: %s (code %d)\n", pqf_msg, code);
            yaz_pqf_destroy (pqf_parser);
            return -1;
        }
        yaz_pqf_destroy (pqf_parser);
    }
    if (term && *term)
    {
        if (req->termListAndStartPoint->term &&
            req->termListAndStartPoint->term->which == Z_Term_general &&
            req->termListAndStartPoint->term->u.general)
        {
            req->termListAndStartPoint->term->u.general->buf =
                (unsigned char *) odr_strdup(out, term);
            req->termListAndStartPoint->term->u.general->len =
                req->termListAndStartPoint->term->u.general->size =
                strlen(term);
        }
    }
    req->referenceId = set_refid (out);
    req->num_databaseNames = num_databaseNames;
    req->databaseNames = databaseNames;
    req->numberOfTermsRequested = &num;
    req->preferredPositionInResponse = &pp;
    req->stepSize = odr_intdup(out, scan_stepSize);
    send_apdu(apdu);
    return 2;
}

int send_sortrequest(const char *arg, int newset)
{
    Z_APDU *apdu = zget_APDU(out, Z_APDU_sortRequest);
    Z_SortRequest *req = apdu->u.sortRequest;
    Z_SortKeySpecList *sksl = (Z_SortKeySpecList *)
        odr_malloc (out, sizeof(*sksl));
    char setstring[32];

    if (only_z3950())
        return 0;
    if (setnumber >= 0)
        sprintf (setstring, "%d", setnumber);
    else
        sprintf (setstring, "default");

    req->referenceId = set_refid (out);

    req->num_inputResultSetNames = 1;
    req->inputResultSetNames = (Z_InternationalString **)
        odr_malloc (out, sizeof(*req->inputResultSetNames));
    req->inputResultSetNames[0] = odr_strdup (out, setstring);

    if (newset && setnumber >= 0)
        sprintf (setstring, "%d", ++setnumber);

    req->sortedResultSetName = odr_strdup (out, setstring);

    req->sortSequence = yaz_sort_spec (out, arg);
    if (!req->sortSequence)
    {
        printf ("Missing sort specifications\n");
        return -1;
    }
    send_apdu(apdu);
    return 2;
}

void display_term(Z_TermInfo *t)
{
    if (t->displayTerm)
        printf("%s", t->displayTerm);
    else if (t->term->which == Z_Term_general)
    {
        printf("%.*s", t->term->u.general->len, t->term->u.general->buf);
        sprintf(last_scan_line, "%.*s", t->term->u.general->len,
            t->term->u.general->buf);
    }
    else
        printf("Term (not general)");
    if (t->globalOccurrences)
        printf (" (%d)\n", *t->globalOccurrences);
    else
        printf ("\n");
}

void process_scanResponse(Z_ScanResponse *res)
{
    int i;
    Z_Entry **entries = NULL;
    int num_entries = 0;
   
    printf("Received ScanResponse\n"); 
    print_refid (res->referenceId);
    printf("%d entries", *res->numberOfEntriesReturned);
    if (res->positionOfTerm)
        printf (", position=%d", *res->positionOfTerm); 
    printf ("\n");
    if (*res->scanStatus != Z_Scan_success)
        printf("Scan returned code %d\n", *res->scanStatus);
    if (!res->entries)
        return;
    if ((entries = res->entries->entries))
        num_entries = res->entries->num_entries;
    for (i = 0; i < num_entries; i++)
    {
        int pos_term = res->positionOfTerm ? *res->positionOfTerm : -1;
        if (entries[i]->which == Z_Entry_termInfo)
        {
            printf("%c ", i + 1 == pos_term ? '*' : ' ');
            display_term(entries[i]->u.termInfo);
        }
        else
            display_diagrecs(&entries[i]->u.surrogateDiagnostic, 1);
    }
    if (res->entries->nonsurrogateDiagnostics)
        display_diagrecs (res->entries->nonsurrogateDiagnostics,
                          res->entries->num_nonsurrogateDiagnostics);
}

void process_sortResponse(Z_SortResponse *res)
{
    printf("Received SortResponse: status=");
    switch (*res->sortStatus)
    {
    case Z_SortResponse_success:
        printf ("success"); break;
    case Z_SortResponse_partial_1:
        printf ("partial"); break;
    case Z_SortResponse_failure:
        printf ("failure"); break;
    default:
        printf ("unknown (%d)", *res->sortStatus);
    }
    printf ("\n");
    print_refid (res->referenceId);
    if (res->diagnostics)
        display_diagrecs(res->diagnostics,
                         res->num_diagnostics);
}

void process_deleteResultSetResponse (Z_DeleteResultSetResponse *res)
{
    printf("Got deleteResultSetResponse status=%d\n",
           *res->deleteOperationStatus);
    if (res->deleteListStatuses)
    {
        int i;
        for (i = 0; i < res->deleteListStatuses->num; i++)
        {
            printf ("%s status=%d\n", res->deleteListStatuses->elements[i]->id,
                    *res->deleteListStatuses->elements[i]->status);
        }
    }
}

int cmd_sort_generic(const char *arg, int newset)
{
    if (only_z3950())
        return 0;
    if (session_initResponse && 
        !ODR_MASK_GET(session_initResponse->options, Z_Options_sort))
    {
        printf("Target doesn't support sort\n");
        return 0;
    }
    if (*arg)
    {
        if (send_sortrequest(arg, newset) < 0)
            return 0;
        return 2;
    }
    return 0;
}

int cmd_sort(const char *arg)
{
    return cmd_sort_generic (arg, 0);
}

int cmd_sort_newset (const char *arg)
{
    return cmd_sort_generic (arg, 1);
}

int cmd_scanstep(const char *arg)
{
    scan_stepSize = atoi(arg);
    return 0;
}

int cmd_scanpos(const char *arg)
{
    int r = sscanf(arg, "%d", &scan_position);
    if (r == 0)
        scan_position = 1;
    return 0;
}

int cmd_scansize(const char *arg)
{
    int r = sscanf(arg, "%d", &scan_size);
    if (r == 0)
        scan_size = 20;
    return 0;
}

int cmd_scan(const char *arg)
{
    if (protocol == PROTO_HTTP)
    {
#if YAZ_HAVE_XML2
        if (!conn)
            cmd_open(0);
        if (!conn)
            return 0;
        if (*arg)
        {
            if (send_SRW_scanRequest(arg, scan_position, scan_size) < 0)
                return 0;
        }
        else
        {
            if (send_SRW_scanRequest(last_scan_line, 1, scan_size) < 0)
                return 0;
        }
        return 2;
#else
        return 0;
#endif
    }
    else
    {
        if (!conn)
        {
            try_reconnect();
            
            if (!conn) {                                                                
                printf("Session not initialized yet\n");
                return 0;
            }
        }
        if (session_initResponse && 
            !ODR_MASK_GET(session_initResponse->options, Z_Options_scan))
        {
            printf("Target doesn't support scan\n");
            return 0;
        }
        if (*arg)
        {
            strcpy (last_scan_query, arg);
            if (send_scanrequest(arg, scan_position, scan_size, 0) < 0)
                return 0;
        }
        else
        {
            if (send_scanrequest(last_scan_query, 1, scan_size, last_scan_line) < 0)
                return 0;
        }
        return 2;
    }
}

int cmd_schema(const char *arg)
{
    xfree(record_schema);
    record_schema = 0;
    if (arg && *arg)
        record_schema = xstrdup(arg);
    return 1;
}

int cmd_format(const char *arg)
{
    const char *cp = arg;
    int nor;
    int idx = 0;
    oid_value nsyntax[RECORDSYNTAX_MAX];
    char form_str[41];
    if (!arg || !*arg)
    {
        printf("Usage: format <recordsyntax>\n");
        return 0;
    }
    while (sscanf(cp, "%40s%n", form_str, &nor) >= 1 && nor > 0 
           && idx < RECORDSYNTAX_MAX)
    {
        nsyntax[idx] = oid_getvalbyname(form_str);
        if (!strcmp(form_str, "none"))
            break;
        if (nsyntax[idx] == VAL_NONE)
        {
            printf ("unknown record syntax: %s\n", form_str);
            return 0;
        }
        cp += nor;
        idx++;
    }
    recordsyntax_size = idx;
    memcpy(recordsyntax_list, nsyntax, idx * sizeof(*nsyntax));
    return 1;
}

int cmd_elements(const char *arg)
{
    static Z_ElementSetNames esn;
    static char what[100];

    if (!arg || !*arg)
    {
        elementSetNames = 0;
        return 1;
    }
    strcpy(what, arg);
    esn.which = Z_ElementSetNames_generic;
    esn.u.generic = what;
    elementSetNames = &esn;
    return 1;
}

int cmd_attributeset(const char *arg)
{
    char what[100];

    if (!arg || !*arg)
    {
        printf("Usage: attributeset <setname>\n");
        return 0;
    }
    sscanf(arg, "%s", what);
    if (p_query_attset (what))
    {
        printf("Unknown attribute set name\n");
        return 0;
    }
    return 1;
}

int cmd_querytype (const char *arg)
{
    if (!strcmp (arg, "ccl"))
        queryType = QueryType_CCL;
    else if (!strcmp (arg, "prefix") || !strcmp(arg, "rpn"))
        queryType = QueryType_Prefix;
    else if (!strcmp (arg, "ccl2rpn") || !strcmp (arg, "cclrpn"))
        queryType = QueryType_CCL2RPN;
    else if (!strcmp(arg, "cql"))
        queryType = QueryType_CQL;        
    else if (!strcmp (arg, "cql2rpn") || !strcmp (arg, "cqlrpn"))
        queryType = QueryType_CQL2RPN;
    else
    {
        printf ("Querytype must be one of:\n");
        printf (" prefix         - Prefix query\n");
        printf (" ccl            - CCL query\n");
        printf (" ccl2rpn        - CCL query converted to RPN\n");
        printf (" cql            - CQL\n");
        printf (" cql2rpn        - CQL query converted to RPN\n");
        return 0;
    }
    return 1;
}

int cmd_refid (const char *arg)
{
    xfree (refid);
    refid = NULL;
    if (*arg)
        refid = xstrdup (arg);
    return 1;
}

int cmd_close(const char *arg)
{
    Z_APDU *apdu;
    Z_Close *req;
    if (only_z3950())
        return 0;
    apdu = zget_APDU(out, Z_APDU_close);
    req = apdu->u.close;
    *req->closeReason = Z_Close_finished;
    send_apdu(apdu);
    printf("Sent close request.\n");
    sent_close = 1;
    return 2;
}

int cmd_packagename(const char* arg)
{
    xfree (esPackageName);
    esPackageName = NULL;
    if (*arg)
        esPackageName = xstrdup(arg);
    return 1;
}

int cmd_proxy(const char* arg)
{
    xfree(yazProxy);
    yazProxy = 0;
    if (*arg)
        yazProxy = xstrdup (arg);
    return 1;
}

int cmd_marccharset(const char *arg)
{
    char l1[30];

    *l1 = 0;
    if (sscanf(arg, "%29s", l1) < 1)
    {
        printf("MARC character set is `%s'\n", 
               marcCharset ? marcCharset: "none");
        return 1;
    }
    xfree (marcCharset);
    marcCharset = 0;
    if (strcmp(l1, "-"))
        marcCharset = xstrdup(l1);
    return 1;
}

int cmd_displaycharset(const char *arg)
{
    char l1[30];

    *l1 = 0;
    if (sscanf(arg, "%29s", l1) < 1)
    {
        printf("Display character set is `%s'\n", 
               outputCharset ? outputCharset: "none");
    }
    else
    {
        xfree (outputCharset);
        outputCharset = 0;
        if (!strcmp(l1, "auto") && codeset)
        {
            if (codeset)
            {
                printf ("Display character set: %s\n", codeset);
                outputCharset = xstrdup(codeset);
            }
            else
                printf ("No codeset found on this system\n");
        }
        else if (strcmp(l1, "-") && strcmp(l1, "none"))
            outputCharset = xstrdup(l1);
    } 
    return 1;
}

int cmd_negcharset(const char *arg)
{
    char l1[30];

    *l1 = 0;
    if (sscanf(arg, "%29s %d %d", l1, &negotiationCharsetRecords,
               &negotiationCharsetVersion) < 1)
    {
        printf("Current negotiation character set is `%s'\n", 
               negotiationCharset ? negotiationCharset: "none");  
        printf("Records in charset %s\n", negotiationCharsetRecords ? 
               "yes" : "no");
        printf("Charneg version %d\n", negotiationCharsetVersion);
    }
    else
    {
        xfree (negotiationCharset);
        negotiationCharset = NULL;
        if (*l1 && strcmp(l1, "-") && strcmp(l1, "none"))
        {
            negotiationCharset = xstrdup(l1);
            printf ("Character set negotiation : %s\n", negotiationCharset);
        }
    }
    return 1;
}

int cmd_charset(const char* arg)
{
    char l1[30], l2[30], l3[30];

    *l1 = *l2 = *l3 = 0;
    if (sscanf(arg, "%29s %29s %29s", l1, l2, l3) < 1)
    {
        cmd_negcharset("");
        cmd_displaycharset("");
        cmd_marccharset("");
    }
    else
    {
        cmd_negcharset(l1);
        if (*l2)
            cmd_displaycharset(l2);
        if (*l3)
            cmd_marccharset(l3);
    }
    return 1;
}

int cmd_lang(const char* arg)
{
    if (*arg == '\0') {
        printf("Current language is `%s'\n", (yazLang)?yazLang:NULL);
        return 1;
    }
    xfree (yazLang);
    yazLang = NULL;
    if (*arg)
        yazLang = xstrdup(arg);
    return 1;
}

int cmd_source(const char* arg, int echo ) 
{
    /* first should open the file and read one line at a time.. */
    FILE* includeFile;
    char line[102400], *cp;

    if(strlen(arg)<1) {
        fprintf(stderr,"Error in source command use a filename\n");
        return -1;
    }
    
    includeFile = fopen (arg, "r");
    
    if(!includeFile) {
        fprintf(stderr,"Unable to open file %s for reading\n",arg);
        return -1;
    }
    
    while(!feof(includeFile)) {
        memset(line,0,sizeof(line));
        fgets(line,sizeof(line),includeFile);
        
        if(strlen(line) < 2) continue;
        if(line[0] == '#') continue;
        
        if ((cp = strrchr (line, '\n')))
            *cp = '\0';
        
        if( echo ) {
            printf( "processing line: %s\n",line );
        };
        process_cmd_line(line);
    }
    
    if(fclose(includeFile)<0) {
        perror("unable to close include file");
        exit(1);
    }
    return 1;
}

int cmd_source_echo(const char* arg)
{ 
    cmd_source(arg, 1);
    return 1;
}

int cmd_source_noecho(const char* arg)
{
    cmd_source(arg, 0);
    return 1;
}


int cmd_subshell(const char* args)
{
    if(strlen(args)) 
        system(args);
    else 
        system(getenv("SHELL"));
    
    printf("\n");
    return 1;
}

int cmd_set_berfile(const char *arg)
{
    if (ber_file && ber_file != stdout && ber_file != stderr)
        fclose(ber_file);
    if (!strcmp(arg, ""))
        ber_file = 0;
    else if (!strcmp(arg, "-"))
        ber_file = stdout;
    else
        ber_file = fopen(arg, "a");
    return 1;
}

int cmd_set_apdufile(const char *arg)
{
    if(apdu_file && apdu_file != stderr && apdu_file != stderr)
        fclose(apdu_file);
    if (!strcmp(arg, ""))
        apdu_file = 0;
    else if (!strcmp(arg, "-"))
        apdu_file = stderr;
    else
    {
        apdu_file = fopen(arg, "a");
        if (!apdu_file)
            perror("unable to open apdu log file");
    }
    if (apdu_file)
        odr_setprint(print, apdu_file);
    return 1;
}

int cmd_set_cclfile(const char* arg)
{  
    FILE *inf;

    bibset = ccl_qual_mk (); 
    inf = fopen (arg, "r");
    if (!inf)
        perror("unable to open CCL file");
    else
    {
        ccl_qual_file (bibset, inf);
        fclose (inf);
    }
    strcpy(ccl_fields,arg);
    return 0;
}

int cmd_set_cqlfile(const char* arg)
{
    cql_transform_t newcqltrans;

    if ((newcqltrans = cql_transform_open_fname(arg)) == 0) {
        perror("unable to open CQL file");
        return 0;
    }
    if (cqltrans != 0)
        cql_transform_close(cqltrans);

    cqltrans = newcqltrans;
    strcpy(cql_fields, arg);
    return 0;
}

int cmd_set_auto_reconnect(const char* arg)
{  
    if(strlen(arg)==0) {
        auto_reconnect = ! auto_reconnect;
    } else if(strcmp(arg,"on")==0) {
        auto_reconnect = 1;
    } else if(strcmp(arg,"off")==0) {
        auto_reconnect = 0;             
    } else {
        printf("Error use on or off\n");
        return 1;
    }
    
    if (auto_reconnect)
        printf("Set auto reconnect enabled.\n");
    else
        printf("Set auto reconnect disabled.\n");
    
    return 0;
}


int cmd_set_auto_wait(const char* arg)
{  
    if(strlen(arg)==0) {
        auto_wait = ! auto_wait;
    } else if(strcmp(arg,"on")==0) {
        auto_wait = 1;
    } else if(strcmp(arg,"off")==0) {
        auto_wait = 0;          
    } else {
        printf("Error use on or off\n");
        return 1;
    }
    
    if (auto_wait)
        printf("Set auto wait enabled.\n");
    else
        printf("Set auto wait disabled.\n");
    
    return 0;
}

int cmd_set_marcdump(const char* arg)
{
    if(marc_file && marc_file != stderr) { /* don't close stdout*/
        fclose(marc_file);
    }

    if (!strcmp(arg, ""))
        marc_file = 0;
    else if (!strcmp(arg, "-"))
        marc_file = stderr;
    else
    {
        marc_file = fopen(arg, "a");
        if (!marc_file)
            perror("unable to open marc log file");
    }
    return 1;
}

/* 
   this command takes 3 arge {name class oid} 
*/
int cmd_register_oid(const char* args) {
    static struct {
        char* className;
        oid_class oclass;
    } oid_classes[] = {
        {"appctx",CLASS_APPCTX},
        {"absyn",CLASS_ABSYN},
        {"attset",CLASS_ATTSET},
        {"transyn",CLASS_TRANSYN},
        {"diagset",CLASS_DIAGSET},
        {"recsyn",CLASS_RECSYN},
        {"resform",CLASS_RESFORM},
        {"accform",CLASS_ACCFORM},
        {"extserv",CLASS_EXTSERV},
        {"userinfo",CLASS_USERINFO},
        {"elemspec",CLASS_ELEMSPEC},
        {"varset",CLASS_VARSET},
        {"schema",CLASS_SCHEMA},
        {"tagset",CLASS_TAGSET},
        {"general",CLASS_GENERAL},
        {0,(enum oid_class) 0}
    };
    char oname_str[101], oclass_str[101], oid_str[101];  
    char* name;
    int i;
    oid_class oidclass = CLASS_GENERAL;
    int val = 0, oid[OID_SIZE];
    struct oident * new_oident=NULL;
    
    if (sscanf (args, "%100[^ ] %100[^ ] %100s",
                oname_str,oclass_str, oid_str) < 1) {
        printf("Error in register command \n");
        return 0;
    }
    
    for (i = 0; oid_classes[i].className; i++) {
        if (!strcmp(oid_classes[i].className, oclass_str))
        {
            oidclass=oid_classes[i].oclass;
            break;
        }
    }
    
    if(!(oid_classes[i].className)) {
        printf("Unknown oid class %s\n",oclass_str);
        return 0;
    }
    
    i = 0;
    name = oid_str;
    val = 0;
    
    while (isdigit (*(unsigned char *) name))
    {
        val = val*10 + (*name - '0');
        name++;
        if (*name == '.')
        {
            if (i < OID_SIZE-1)
                oid[i++] = val;
            val = 0;
            name++;
        }
    }
    oid[i] = val;
    oid[i+1] = -1;
    
    new_oident = oid_addent (oid, PROTO_GENERAL, oidclass, oname_str,
                             VAL_DYNAMIC);  
    if(strcmp(new_oident->desc,oname_str))
    {
        fprintf(stderr,"oid is already named as %s, registration failed\n",
                new_oident->desc);
    }
    return 1;  
}

int cmd_push_command(const char* arg) 
{
#if HAVE_READLINE_HISTORY_H
    if(strlen(arg)>1) 
        add_history(arg);
#else 
    fprintf(stderr,"Not compiled with the readline/history module\n");
#endif
    return 1;
}

void source_rcfile(void)
{
    /*  Look for a $HOME/.yazclientrc and source it if it exists */
    struct stat statbuf;
    char buffer[1000];
    char* homedir=getenv("HOME");

    if( homedir ) {
        
        sprintf(buffer,"%s/.yazclientrc",homedir);

        if(stat(buffer,&statbuf)==0) {
            cmd_source(buffer, 0 );
        }
        
    };
    
    if(stat(".yazclientrc",&statbuf)==0) {
        cmd_source(".yazclientrc", 0 );
    }
}


static void initialize(void)
{
    FILE *inf;
    int i;
    
    if (!(out = odr_createmem(ODR_ENCODE)) ||
        !(in = odr_createmem(ODR_DECODE)) ||
        !(print = odr_createmem(ODR_PRINT)))
    {
        fprintf(stderr, "failed to allocate ODR streams\n");
        exit(1);
    }
    oid_init();
    
    setvbuf(stdout, 0, _IONBF, 0);
    if (apdu_file)
        odr_setprint(print, apdu_file);

    bibset = ccl_qual_mk (); 
    inf = fopen (ccl_fields, "r");
    if (inf)
    {
        ccl_qual_file (bibset, inf);
        fclose (inf);
    }

    cqltrans = cql_transform_open_fname(cql_fields);
    /* If this fails, no problem: we detect cqltrans == 0 later */

#if HAVE_READLINE_READLINE_H
    rl_attempted_completion_function = (CPPFunction*)readline_completer;
#endif
    for(i = 0; i < maxOtherInfosSupported; ++i) {
        extraOtherInfos[i].oidval = -1;
    }
    
    source_rcfile();
}


#if HAVE_GETTIMEOFDAY
struct timeval tv_start;
#endif

#if YAZ_HAVE_XML2
static void handle_srw_record(Z_SRW_record *rec)
{
    if (rec->recordPosition)
    {
        printf ("pos=%d", *rec->recordPosition);
        setno = *rec->recordPosition + 1;
    }
    if (rec->recordSchema)
        printf (" schema=%s", rec->recordSchema);
    printf ("\n");
    if (rec->recordData_buf && rec->recordData_len)
    {
        fwrite(rec->recordData_buf, 1, rec->recordData_len, stdout);
        if (marc_file)
            fwrite (rec->recordData_buf, 1, rec->recordData_len, marc_file);
    }
    else
        printf ("No data!");
    printf("\n");
}

static void handle_srw_explain_response(Z_SRW_explainResponse *res)
{
    handle_srw_record(&res->record);
}

static void handle_srw_response(Z_SRW_searchRetrieveResponse *res)
{
    int i;

    printf ("Received SRW SearchRetrieve Response\n");
    
    for (i = 0; i<res->num_diagnostics; i++)
    {
        if (res->diagnostics[i].uri)
            printf ("SRW diagnostic %s\n",
                    res->diagnostics[i].uri);
        else
            printf ("SRW diagnostic missing or could not be decoded\n");
        if (res->diagnostics[i].message)
            printf ("Message: %s\n", res->diagnostics[i].message);
        if (res->diagnostics[i].details)
            printf ("Details: %s\n", res->diagnostics[i].details);
    }
    if (res->numberOfRecords)
        printf ("Number of hits: %d\n", *res->numberOfRecords);
    for (i = 0; i<res->num_records; i++)
        handle_srw_record(res->records + i);
}

static void handle_srw_scan_term(Z_SRW_scanTerm *term)
{
    if (term->displayTerm)
        printf("%s:", term->displayTerm);
    else if (term->value)
        printf("%s:", term->value);
    else
        printf("No value:");
    if (term->numberOfRecords)
        printf(" %d", *term->numberOfRecords);
    if (term->whereInList)
        printf(" %s", term->whereInList);
    if (term->value && term->displayTerm)
        printf(" %s", term->value);

    strcpy(last_scan_line, term->value);
    printf("\n");
}

static void handle_srw_scan_response(Z_SRW_scanResponse *res)
{
    int i;

    printf ("Received SRW Scan Response\n");
    
    for (i = 0; i<res->num_diagnostics; i++)
    {
        if (res->diagnostics[i].uri)
            printf ("SRW diagnostic %s\n",
                    res->diagnostics[i].uri);
        else
            printf ("SRW diagnostic missing or could not be decoded\n");
        if (res->diagnostics[i].message)
            printf ("Message: %s\n", res->diagnostics[i].message);
        if (res->diagnostics[i].details)
            printf ("Details: %s\n", res->diagnostics[i].details);
    }
    if (res->terms)
        for (i = 0; i<res->num_terms; i++)
            handle_srw_scan_term(res->terms + i);
}

static void http_response(Z_HTTP_Response *hres)
{
    int ret = -1;
    const char *content_type = z_HTTP_header_lookup(hres->headers,
                                                    "Content-Type");
    const char *connection_head = z_HTTP_header_lookup(hres->headers,
                                                       "Connection");
    if (content_type && !yaz_strcmp_del("text/xml", content_type, "; "))
    {
        Z_SOAP *soap_package = 0;
        ODR o = odr_createmem(ODR_DECODE);
        Z_SOAP_Handler soap_handlers[3] = {
            {YAZ_XMLNS_SRU_v1_1, 0, (Z_SOAP_fun) yaz_srw_codec},
            {YAZ_XMLNS_UPDATE_v0_9, 0, (Z_SOAP_fun) yaz_ucp_codec},
            {0, 0, 0}
        };
        ret = z_soap_codec(o, &soap_package,
                           &hres->content_buf, &hres->content_len,
                           soap_handlers);
        if (!ret && soap_package->which == Z_SOAP_generic)
        {
            Z_SRW_PDU *sr = soap_package->u.generic->p;
            if (sr->which == Z_SRW_searchRetrieve_response)
                handle_srw_response(sr->u.response);
            else if (sr->which == Z_SRW_explain_response)
                handle_srw_explain_response(sr->u.explain_response);
            else if (sr->which == Z_SRW_scan_response)
                handle_srw_scan_response(sr->u.scan_response);
            else if (sr->which == Z_SRW_update_response)
                printf("Got update response. Status: %s\n",
                       sr->u.update_response->operationStatus);
            else
                ret = -1;
        }
        else if (soap_package && (soap_package->which == Z_SOAP_fault
                                  || soap_package->which == Z_SOAP_error))
        {
            printf ("HTTP Error Status=%d\n", hres->code);
            printf ("SOAP Fault code %s\n",
                    soap_package->u.fault->fault_code);
            printf ("SOAP Fault string %s\n", 
                    soap_package->u.fault->fault_string);
            if (soap_package->u.fault->details)
                printf ("SOAP Details %s\n", 
                        soap_package->u.fault->details);
        }
        else
        {
            printf("z_soap_codec failed. (no SOAP error)\n");
            ret = -1;
        }
        odr_destroy(o);
    }
    if (ret)
    {
        if (hres->code != 200)
        {
            printf ("HTTP Error Status=%d\n", hres->code);
        }
        else
        {
            printf ("Decoding of SRW package failed\n");
        }
        close_session();
    }
    else
    {
        if (!strcmp(hres->version, "1.0"))
        {
            /* HTTP 1.0: only if Keep-Alive we stay alive.. */
            if (!connection_head || strcmp(connection_head, "Keep-Alive"))
                close_session();
        }
        else 
        {
            /* HTTP 1.1: only if no close we stay alive .. */
            if (connection_head && !strcmp(connection_head, "close"))
                close_session();
        }
    }
}
#endif

void wait_and_handle_response(int one_response_only) 
{
    int reconnect_ok = 1;
    int res;
    char *netbuffer= 0;
    int netbufferlen = 0;
#if HAVE_GETTIMEOFDAY
    int got_tv_end = 0;
    struct timeval tv_end;
#endif
    Z_GDU *gdu;
    
    while(conn)
    {
        res = cs_get(conn, &netbuffer, &netbufferlen);
        if (reconnect_ok && res <= 0 && protocol == PROTO_HTTP)
        {
            cs_close(conn);
            conn = 0;
            cmd_open(0);
            reconnect_ok = 0;
            if (conn)
            {
                char *buf_out;
                int len_out;
                
                buf_out = odr_getbuf(out, &len_out, 0);
                
                do_hex_dump(buf_out, len_out);

                cs_put(conn, buf_out, len_out);
                
                odr_reset(out);
                continue;
            }
        }
        else if (res <= 0)
        {
            printf("Target closed connection\n");
            close_session();
            break;
        }
#if HAVE_GETTIMEOFDAY
        if (got_tv_end == 0)
            gettimeofday (&tv_end, 0); /* count first one only */
        got_tv_end++;
#endif
        odr_reset(out);
        odr_reset(in); /* release APDU from last round */
        record_last = 0;
        do_hex_dump(netbuffer, res);
        odr_setbuf(in, netbuffer, res, 0);
        
        if (!z_GDU(in, &gdu, 0, 0))
        {
            FILE *f = ber_file ? ber_file : stdout;
            odr_perror(in, "Decoding incoming APDU");
            fprintf(f, "[Near %ld]\n", (long) odr_offset(in));
            fprintf(f, "Packet dump:\n---------\n");
            odr_dumpBER(f, netbuffer, res);
            fprintf(f, "---------\n");
            if (apdu_file)
            {
                z_GDU(print, &gdu, 0, 0);
                odr_reset(print);
            }
            if (conn && cs_more(conn))
                continue;
            break;
        }
        if (ber_file)
            odr_dumpBER(ber_file, netbuffer, res);
        if (apdu_file && !z_GDU(print, &gdu, 0, 0))
        {
            odr_perror(print, "Failed to print incoming APDU");
            odr_reset(print);
                continue;
        }
        if (gdu->which == Z_GDU_Z3950)
        {
            Z_APDU *apdu = gdu->u.z3950;
            switch(apdu->which)
            {
            case Z_APDU_initResponse:
                process_initResponse(apdu->u.initResponse);
                break;
            case Z_APDU_searchResponse:
                process_searchResponse(apdu->u.searchResponse);
                break;
            case Z_APDU_scanResponse:
                process_scanResponse(apdu->u.scanResponse);
                break;
            case Z_APDU_presentResponse:
                print_refid (apdu->u.presentResponse->referenceId);
                setno +=
                    *apdu->u.presentResponse->numberOfRecordsReturned;
                if (apdu->u.presentResponse->records)
                    display_records(apdu->u.presentResponse->records);
                else
                    printf("No records.\n");
                printf ("nextResultSetPosition = %d\n",
                        *apdu->u.presentResponse->nextResultSetPosition);
                break;
            case Z_APDU_sortResponse:
                process_sortResponse(apdu->u.sortResponse);
                break;
            case Z_APDU_extendedServicesResponse:
                printf("Got extended services response\n");
                process_ESResponse(apdu->u.extendedServicesResponse);
                break;
            case Z_APDU_close:
                printf("Target has closed the association.\n");
                process_close(apdu->u.close);
                break;
            case Z_APDU_resourceControlRequest:
                process_resourceControlRequest
                    (apdu->u.resourceControlRequest);
                break;
            case Z_APDU_deleteResultSetResponse:
                process_deleteResultSetResponse(apdu->u.
                                                deleteResultSetResponse);
                break;
            default:
                printf("Received unknown APDU type (%d).\n", 
                       apdu->which);
                close_session ();
            }
        }
#if YAZ_HAVE_XML2
        else if (gdu->which == Z_GDU_HTTP_Response)
        {
            http_response(gdu->u.HTTP_Response);
        }
#endif
        if (one_response_only)
            break;
        if (conn && !cs_more(conn))
            break;
    }
#if HAVE_GETTIMEOFDAY
    if (got_tv_end)
    {
#if 0
        printf ("S/U S/U=%ld/%ld %ld/%ld",
                (long) tv_start.tv_sec,
                (long) tv_start.tv_usec,
                (long) tv_end.tv_sec,
                (long) tv_end.tv_usec);
#endif
        printf ("Elapsed: %.6f\n",
                (double) tv_end.tv_usec / 1e6 + tv_end.tv_sec -
                ((double) tv_start.tv_usec / 1e6 + tv_start.tv_sec));
    }
#endif
    xfree (netbuffer);
}


int cmd_cclparse(const char* arg) 
{
    int error, pos;
    struct ccl_rpn_node *rpn=NULL;
    
    
    rpn = ccl_find_str (bibset, arg, &error, &pos);
    
    if (error) {
        int ioff = 3+strlen(last_cmd)+1+pos;
        printf ("%*s^ - ", ioff, " ");
        printf ("%s\n", ccl_err_msg (error));
    }
    else
    {
        if (rpn)
        {       
            ccl_pr_tree(rpn, stdout); 
        }
    }
    if (rpn)
        ccl_rpn_delete(rpn);
    
    printf ("\n");
    
    return 0;
}


int cmd_set_otherinfo(const char* args)
{
    char oidstr[101], otherinfoString[101];
    int otherinfoNo;
    int sscan_res;
    int oidval;
    
    sscan_res = sscanf (args, "%d %100[^ ] %100s", 
                        &otherinfoNo, oidstr, otherinfoString);
    if (sscan_res==1) {
        /* reset this otherinfo */
        if(otherinfoNo>=maxOtherInfosSupported) {
            printf("Error otherinfo index to large (%d>%d)\n",
                   otherinfoNo,maxOtherInfosSupported);
        }
        extraOtherInfos[otherinfoNo].oidval = -1;
        if (extraOtherInfos[otherinfoNo].value)
            xfree(extraOtherInfos[otherinfoNo].value);                   
        extraOtherInfos[otherinfoNo].value = 0;
        return 0;
    }
    if (sscan_res<3) {
        printf("Error in set_otherinfo command \n");
        return 0;
    }
    
    if (otherinfoNo>=maxOtherInfosSupported) {
        printf("Error otherinfo index too large (%d>=%d)\n",
               otherinfoNo,maxOtherInfosSupported);
    }
    
    oidval = oid_getvalbyname (oidstr);
    if (oidval == VAL_NONE)
    {
        printf("Error in set_otherinfo command unknown oid %s \n",oidstr);
        return 0;
    }
    extraOtherInfos[otherinfoNo].oidval = oidval;
    if (extraOtherInfos[otherinfoNo].value)
        xfree(extraOtherInfos[otherinfoNo].value);
    extraOtherInfos[otherinfoNo].value = xstrdup(otherinfoString);
    
    return 0;
}

int cmd_sleep(const char* args ) 
{
    int sec=atoi(args);
    if( sec > 0 ) {
#ifdef WIN32
        Sleep(sec*1000);
#else
        sleep(sec);
#endif
        printf("Done sleeping %d seconds\n", sec);      
    }
    return 1;    
}

int cmd_list_otherinfo(const char* args)
{
    int i;         
    
    if(strlen(args)>0) {
        i = atoi(args);
        if( i >= maxOtherInfosSupported ) {
            printf("Error otherinfo index to large (%d>%d)\n",i,maxOtherInfosSupported);
            return 0;
        }

        if(extraOtherInfos[i].oidval != -1) 
            printf("  otherinfo %d %s %s\n",
                   i,
                   yaz_z3950_oid_value_to_str(
                       (enum oid_value) extraOtherInfos[i].oidval,
                       CLASS_RECSYN),
                   extraOtherInfos[i].value);
        
    } else {            
        for(i=0; i<maxOtherInfosSupported; ++i) {
            if(extraOtherInfos[i].oidval != -1) 
                printf("  otherinfo %d %s %s\n",
                       i,
                       yaz_z3950_oid_value_to_str(
                           (enum oid_value) extraOtherInfos[i].oidval,
                           CLASS_RECSYN),
                       extraOtherInfos[i].value);
        }
        
    }
    return 0;
}


int cmd_list_all(const char* args) {
    int i;
    
    /* connection options */
    if(conn) {
        printf("Connected to         : %s\n",last_open_command);
    } else {
        if(last_open_command) 
            printf("Not connected to     : %s\n",last_open_command);
        else 
            printf("Not connected        : \n");
        
    }
    if(yazProxy) printf("using proxy          : %s\n",yazProxy);                
    
    printf("auto_reconnect       : %s\n",auto_reconnect?"on":"off");
    printf("auto_wait            : %s\n",auto_wait?"on":"off");
    
    if (!auth) {
        printf("Authentication       : none\n");
    } else {
        switch(auth->which) {
        case Z_IdAuthentication_idPass:
            printf("Authentication       : IdPass\n"); 
            printf("    Login User       : %s\n",auth->u.idPass->userId?auth->u.idPass->userId:"");
            printf("    Login Group      : %s\n",auth->u.idPass->groupId?auth->u.idPass->groupId:"");
            printf("    Password         : %s\n",auth->u.idPass->password?auth->u.idPass->password:"");
            break;
        case Z_IdAuthentication_open:
            printf("Authentication       : psOpen\n");                  
            printf("    Open string      : %s\n",auth->u.open); 
            break;
        default:
            printf("Authentication       : Unknown\n");
        }
    }
    if (negotiationCharset)
        printf("Neg. Character set   : `%s'\n", negotiationCharset);
    
    /* bases */
    printf("Bases                : ");
    for (i = 0; i<num_databaseNames; i++) printf("%s ",databaseNames[i]);
    printf("\n");
    
    /* Query options */
    printf("CCL file             : %s\n",ccl_fields);
    printf("CQL file             : %s\n",cql_fields);
    printf("Query type           : %s\n",query_type_as_string(queryType));
    
    printf("Named Result Sets    : %s\n",setnumber==-1?"off":"on");
    
    /* piggy back options */
    printf("ssub/lslb/mspn       : %d/%d/%d\n",smallSetUpperBound,largeSetLowerBound,mediumSetPresentNumber);
    
    /* print present related options */
    printf("Format               : %s\n",
           (recordsyntax_size > 0) ? 
           yaz_z3950_oid_value_to_str(recordsyntax_list[0], CLASS_RECSYN) :
           "none");
    printf("Schema               : %s\n",record_schema ? record_schema : "not set");
    printf("Elements             : %s\n",elementSetNames?elementSetNames->u.generic:"");
    
    /* loging options */
    printf("APDU log             : %s\n",apdu_file?"on":"off");
    printf("Record log           : %s\n",marc_file?"on":"off");
    
    /* other infos */
    printf("Other Info: \n");
    cmd_list_otherinfo("");
    
    return 0;
}

int cmd_clear_otherinfo(const char* args) 
{
    if(strlen(args)>0) {
        int otherinfoNo = atoi(args);
        if (otherinfoNo >= maxOtherInfosSupported) {
            printf("Error otherinfo index too large (%d>=%d)\n",
                   otherinfoNo, maxOtherInfosSupported);
            return 0;
        }
        if (extraOtherInfos[otherinfoNo].oidval != -1)
        {                 
            /* only clear if set. */
            extraOtherInfos[otherinfoNo].oidval = -1;
            xfree(extraOtherInfos[otherinfoNo].value);
        }
    } else {
        int i;
        for(i = 0; i < maxOtherInfosSupported; ++i) 
        {
            if (extraOtherInfos[i].oidval != -1)
            {                               
                extraOtherInfos[i].oidval = -1;
                xfree(extraOtherInfos[i].value);
            }
        }
    }
    return 0;
}

int cmd_wait_response(const char *arg)
{
    int wait_for = atoi(arg);
    int i=0;
    if( wait_for < 1 ) {
        wait_for = 1;
    };
    
    for( i=0 ; i < wait_for ; ++i ) {
        wait_and_handle_response(1);
    };
    return 0;
}

static int cmd_help (const char *line);

typedef char *(*completerFunctionType)(const char *text, int state);

static struct {
    char *cmd;
    int (*fun)(const char *arg);
    char *ad;
        completerFunctionType rl_completerfunction;
    int complete_filenames;
    char **local_tabcompletes;
} cmd_array[] = {
    {"open", cmd_open, "('tcp'|'ssl')':<host>[':'<port>][/<db>]",NULL,0,NULL},
    {"quit", cmd_quit, "",NULL,0,NULL},
    {"find", cmd_find, "<query>",NULL,0,NULL},
    {"delete", cmd_delete, "<setname>",NULL,0,NULL},
    {"base", cmd_base, "<base-name>",NULL,0,NULL},
    {"show", cmd_show, "<rec#>['+'<#recs>['+'<setname>]]",NULL,0,NULL},
    {"scan", cmd_scan, "<term>",NULL,0,NULL},
    {"scanstep", cmd_scanstep, "<size>",NULL,0,NULL},
    {"scanpos", cmd_scanpos, "<size>",NULL,0,NULL},
    {"scansize", cmd_scansize, "<size>",NULL,0,NULL},
    {"sort", cmd_sort, "<sortkey> <flag> <sortkey> <flag> ...",NULL,0,NULL},
    {"sort+", cmd_sort_newset, "<sortkey> <flag> <sortkey> <flag> ...",NULL,0,NULL},
    {"authentication", cmd_authentication, "<acctstring>",NULL,0,NULL},
    {"lslb", cmd_lslb, "<largeSetLowerBound>",NULL,0,NULL},
    {"ssub", cmd_ssub, "<smallSetUpperBound>",NULL,0,NULL},
    {"mspn", cmd_mspn, "<mediumSetPresentNumber>",NULL,0,NULL},
    {"status", cmd_status, "",NULL,0,NULL},
    {"setnames", cmd_setnames, "",NULL,0,NULL},
    {"cancel", cmd_cancel, "",NULL,0,NULL},
    {"cancel_find", cmd_cancel_find, "<query>",NULL,0,NULL},
    {"format", cmd_format, "<recordsyntax>",complete_format,0,NULL},
    {"schema", cmd_schema, "<schema>",complete_schema,0,NULL},
    {"elements", cmd_elements, "<elementSetName>",NULL,0,NULL},
    {"close", cmd_close, "",NULL,0,NULL},
    {"attributeset", cmd_attributeset, "<attrset>",complete_attributeset,0,NULL},
    {"querytype", cmd_querytype, "<type>",complete_querytype,0,NULL},
    {"refid", cmd_refid, "<id>",NULL,0,NULL},
    {"itemorder", cmd_itemorder, "ill|item|xml <itemno>",NULL,0,NULL},
    {"update", cmd_update, "<action> <recid> [<doc>]",NULL,0,NULL},
    {"update0", cmd_update0, "<action> <recid> [<doc>]",NULL,0,NULL},
    {"xmles", cmd_xmles, "<OID> <doc>",NULL,0,NULL},
    {"packagename", cmd_packagename, "<packagename>",NULL,0,NULL},
    {"proxy", cmd_proxy, "[('tcp'|'ssl')]<host>[':'<port>]",NULL,0,NULL},
    {"charset", cmd_charset, "<nego_charset> <output_charset>",NULL,0,NULL},
    {"negcharset", cmd_negcharset, "<nego_charset>",NULL,0,NULL},
    {"displaycharset", cmd_displaycharset, "<output_charset>",NULL,0,NULL},
    {"marccharset", cmd_marccharset, "<charset_name>",NULL,0,NULL},
    {"lang", cmd_lang, "<language_code>",NULL,0,NULL},
    {".", cmd_source_echo, "<filename>",NULL,1,NULL},
    {"!", cmd_subshell, "Subshell command",NULL,1,NULL},
    {"set_apdufile", cmd_set_apdufile, "<filename>",NULL,1,NULL},
    {"set_berfile", cmd_set_berfile, "<filename>",NULL,1,NULL},
    {"set_marcdump", cmd_set_marcdump," <filename>",NULL,1,NULL},
    {"set_cclfile", cmd_set_cclfile," <filename>",NULL,1,NULL},
    {"set_cqlfile", cmd_set_cqlfile," <filename>",NULL,1,NULL},
    {"set_auto_reconnect", cmd_set_auto_reconnect," on|off",complete_auto_reconnect,1,NULL},
    {"set_auto_wait", cmd_set_auto_wait," on|off",complete_auto_reconnect,1,NULL},
    {"set_otherinfo", cmd_set_otherinfo,"<otherinfoinddex> <oid> <string>",NULL,0,NULL},
    {"sleep", cmd_sleep,"<seconds>",NULL,0,NULL},
    {"register_oid", cmd_register_oid,"<name> <class> <oid>",NULL,0,NULL},
    {"push_command", cmd_push_command,"<command>",command_generator,0,NULL},
    {"register_tab", cmd_register_tab,"<commandname> <tab>",command_generator,0,NULL},
    {"cclparse", cmd_cclparse,"<ccl find command>",NULL,0,NULL},
    {"list_otherinfo",cmd_list_otherinfo,"[otherinfoinddex]",NULL,0,NULL},
    {"list_all",cmd_list_all,"",NULL,0,NULL},
    {"clear_otherinfo",cmd_clear_otherinfo,"",NULL,0,NULL},
    {"wait_response",cmd_wait_response,"<number>",NULL,0,NULL},
    /* Server Admin Functions */
    {"adm-reindex", cmd_adm_reindex, "<database-name>",NULL,0,NULL},
    {"adm-truncate", cmd_adm_truncate, "('database'|'index')<object-name>",NULL,0,NULL},
    {"adm-create", cmd_adm_create, "",NULL,0,NULL},
    {"adm-drop", cmd_adm_drop, "('database'|'index')<object-name>",NULL,0,NULL},
    {"adm-import", cmd_adm_import, "<record-type> <dir> <pattern>",NULL,0,NULL},
    {"adm-refresh", cmd_adm_refresh, "",NULL,0,NULL},
    {"adm-commit", cmd_adm_commit, "",NULL,0,NULL},
    {"adm-shutdown", cmd_adm_shutdown, "",NULL,0,NULL},
    {"adm-startup", cmd_adm_startup, "",NULL,0,NULL},
    {"explain", cmd_explain, "", NULL, 0, NULL},
    {"options", cmd_options, "", NULL, 0, NULL},
    {"zversion", cmd_zversion, "", NULL, 0, NULL},
    {"help", cmd_help, "", NULL,0,NULL},
    {"init", cmd_init, "", NULL,0,NULL},
    {"sru", cmd_sru, "", NULL,0,NULL},
    {"exit", cmd_quit, "",NULL,0,NULL},
    {0,0,0,0,0,0}
};

static int cmd_help (const char *line)
{
    int i;
    char topic[21];
    
    *topic = 0;
    sscanf (line, "%20s", topic);

    if (*topic == 0)
        printf("Commands:\n");
    for (i = 0; cmd_array[i].cmd; i++)
        if (*topic == 0 || strcmp (topic, cmd_array[i].cmd) == 0)
            printf("   %s %s\n", cmd_array[i].cmd, cmd_array[i].ad);
    if (!strcmp(topic, "find"))
    {
        printf("RPN:\n");
        printf(" \"term\"                        Simple Term\n");
        printf(" @attr [attset] type=value op  Attribute\n");
        printf(" @and opl opr                  And\n");
        printf(" @or opl opr                   Or\n");
        printf(" @not opl opr                  And-Not\n");
        printf(" @set set                      Result set\n");
        printf(" @prox exl dist ord rel uc ut  Proximity. Use help prox\n");
        printf("\n");
        printf("Bib-1 attribute types\n");
        printf("1=Use:         ");
        printf("4=Title 7=ISBN 8=ISSN 30=Date 62=Abstract 1003=Author 1016=Any\n");
        printf("2=Relation:    ");
        printf("1<   2<=  3=  4>=  5>  6!=  102=Relevance\n");
        printf("3=Position:    ");
        printf("1=First in Field  2=First in subfield  3=Any position\n");
        printf("4=Structure:   ");
        printf("1=Phrase  2=Word  3=Key  4=Year  5=Date  6=WordList\n");
        printf("5=Truncation:  ");
        printf("1=Right  2=Left  3=L&R  100=No  101=#  102=Re-1  103=Re-2\n");
        printf("6=Completeness:");
        printf("1=Incomplete subfield  2=Complete subfield  3=Complete field\n");
    }
    if (!strcmp(topic, "prox"))
    {
        printf("Proximity:\n");
        printf(" @prox exl dist ord rel uc ut\n");
        printf(" exl:  exclude flag . 0=include, 1=exclude.\n");
        printf(" dist: distance integer.\n");
        printf(" ord:  order flag. 0=unordered, 1=ordered.\n");
        printf(" rel:  relation integer. 1<  2<=  3= 4>=  5>  6!= .\n");
        printf(" uc:   unit class. k=known, p=private.\n");
        printf(" ut:   unit type. 1=character, 2=word, 3=sentence,\n");
        printf("        4=paragraph, 5=section, 6=chapter, 7=document,\n");
        printf("        8=element, 9=subelement, 10=elementType, 11=byte.\n");
        printf("\nExamples:\n");
        printf(" Search for a and b in-order at most 3 words apart:\n");
        printf("  @prox 0 3 1 2 k 2 a b\n");
        printf(" Search for any order of a and b next to each other:\n");
        printf("  @prox 0 1 0 3 k 2 a b\n");
    }
    return 1;
}

int cmd_register_tab(const char* arg) 
{
#if HAVE_READLINE_READLINE_H
    char command[101], tabargument[101];
    int i;
    int num_of_tabs;
    char** tabslist;
    
    if (sscanf (arg, "%100s %100s", command, tabargument) < 1) {
        return 0;
    }
    
    /* locate the amdn in the list */
    for (i = 0; cmd_array[i].cmd; i++) {
        if (!strncmp(cmd_array[i].cmd, command, strlen(command))) {
            break;
        }
    }
    
    if (!cmd_array[i].cmd) { 
        fprintf(stderr,"Unknown command %s\n",command);
        return 1;
    }
    
        
    if (!cmd_array[i].local_tabcompletes)
        cmd_array[i].local_tabcompletes = (char **) calloc(1,sizeof(char**));
    
    num_of_tabs=0;              
    
    tabslist = cmd_array[i].local_tabcompletes;
    for(; tabslist && *tabslist; tabslist++) {
        num_of_tabs++;
    }
    
    cmd_array[i].local_tabcompletes = (char **)
        realloc(cmd_array[i].local_tabcompletes,
                (num_of_tabs+2)*sizeof(char**));
    tabslist = cmd_array[i].local_tabcompletes;
    tabslist[num_of_tabs] = strdup(tabargument);
    tabslist[num_of_tabs+1] = NULL;
#endif
    return 1;
}


void process_cmd_line(char* line)
{  
    int i, res;
    char word[32], arg[10240];
    
#if HAVE_GETTIMEOFDAY
    gettimeofday (&tv_start, 0);
#endif
    
    if ((res = sscanf(line, "%31s %10239[^;]", word, arg)) <= 0)
    {
        strcpy(word, last_cmd);
        *arg = '\0';
    }
    else if (res == 1)
        *arg = 0;
    strcpy(last_cmd, word);
    
    /* removed tailing spaces from the arg command */
    { 
        char* p = arg;
        char* lastnonspace=NULL;
        
        for(;*p; ++p) {
            if(!isspace(*(unsigned char *) p)) {
                lastnonspace = p;
            }
        }
        if(lastnonspace) 
            *(++lastnonspace) = 0;
    }
    
    for (i = 0; cmd_array[i].cmd; i++)
        if (!strncmp(cmd_array[i].cmd, word, strlen(word)))
        {
            res = (*cmd_array[i].fun)(arg);
            break;
        }
    
    if (!cmd_array[i].cmd) /* dump our help-screen */
    {
        printf("Unknown command: %s.\n", word);
        printf("Type 'help' for list of commands\n");
        res = 1;
    }
    
    if(apdu_file) fflush(apdu_file);
    
    if (res >= 2 && auto_wait)
        wait_and_handle_response(0);
    
    if(apdu_file)
        fflush(apdu_file);
    if(marc_file)
        fflush(marc_file);
}

static char *command_generator(const char *text, int state) 
{
#if HAVE_READLINE_READLINE_H
    static int idx; 
    if (state==0) {
        idx = 0;
    }
    for( ; cmd_array[idx].cmd; ++idx) {
        if (!strncmp(cmd_array[idx].cmd, text, strlen(text))) {
            ++idx;  /* skip this entry on the next run */
            return strdup(cmd_array[idx-1].cmd);
        }
    }
#endif
    return NULL;
}

#if HAVE_READLINE_READLINE_H
static char** default_completer_list = NULL;

static char* default_completer(const char* text, int state)
{
    return complete_from_list(default_completer_list, text, state);
}
#endif

#if HAVE_READLINE_READLINE_H

/* 
   This function only known how to complete on the first word
*/
char **readline_completer(char *text, int start, int end)
{
    completerFunctionType completerToUse;
    
    if(start == 0) {
#if HAVE_READLINE_RL_COMPLETION_MATCHES
        char** res = rl_completion_matches(text, command_generator); 
#else
        char** res = completion_matches(text,
                                        (CPFunction*)command_generator); 
#endif
        rl_attempted_completion_over = 1;
        return res;
    } else {
        char arg[10240],word[32];
        int i=0 ,res;
        if ((res = sscanf(rl_line_buffer, "%31s %10239[^;]", word, arg)) <= 0) {     
            rl_attempted_completion_over = 1;
            return NULL;
        }
        
        for (i = 0; cmd_array[i].cmd; i++)
            if (!strncmp(cmd_array[i].cmd, word, strlen(word)))
                break;
        
        if(!cmd_array[i].cmd)
            return NULL;
        
        default_completer_list = cmd_array[i].local_tabcompletes;
        
        completerToUse = cmd_array[i].rl_completerfunction;
        if (!completerToUse) 
        { /* if command completer is not defined use the default completer */
            completerToUse = default_completer;
        }
        if (completerToUse) {
#ifdef HAVE_READLINE_RL_COMPLETION_MATCHES
            char** res=
                rl_completion_matches(text, completerToUse);
#else
            char** res=
                completion_matches(text, (CPFunction*)completerToUse);
#endif
            if (!cmd_array[i].complete_filenames) 
                rl_attempted_completion_over = 1;
            return res;
        } else {
            if (!cmd_array[i].complete_filenames) 
                rl_attempted_completion_over = 1;
            return 0;
        }
    }
}
#endif

static void client(void)
{
    char line[10240];

    line[10239] = '\0';

#if HAVE_GETTIMEOFDAY
    gettimeofday (&tv_start, 0);
#endif

    while (1)
    {
        char *line_in = NULL;
#if HAVE_READLINE_READLINE_H
        if (isatty(0))
        {
            line_in=readline(C_PROMPT);
            if (!line_in)
                break;
#if HAVE_READLINE_HISTORY_H
            if (*line_in)
                add_history(line_in);
#endif
            strncpy(line, line_in, 10239);
            free(line_in);
        }
#endif 
        if (!line_in)
        {
            char *end_p;
            printf (C_PROMPT);
            fflush(stdout);
            if (!fgets(line, 10239, stdin))
                break;
            if ((end_p = strchr (line, '\n')))
                *end_p = '\0';
        }
        process_cmd_line(line);
    }
}

static void show_version(void)
{
    char vstr[20];

    yaz_version(vstr, 0);
    printf ("YAZ version: %s\n", YAZ_VERSION);
    if (strcmp(vstr, YAZ_VERSION))
        printf ("YAZ DLL/SO: %s\n", vstr);
    exit(0);
}

int main(int argc, char **argv)
{
    char *prog = *argv;
    char *open_command = 0;
    char *auth_command = 0;
    char *arg;
    int ret;
    
#if HAVE_LOCALE_H
    if (!setlocale(LC_CTYPE, ""))
        fprintf (stderr, "setlocale failed\n");
#endif
#if HAVE_LANGINFO_H
#ifdef CODESET
    codeset = nl_langinfo(CODESET);
#endif
#endif
    if (codeset)
        outputCharset = xstrdup(codeset);
    
    ODR_MASK_SET(&z3950_options, Z_Options_search);
    ODR_MASK_SET(&z3950_options, Z_Options_present);
    ODR_MASK_SET(&z3950_options, Z_Options_namedResultSets);
    ODR_MASK_SET(&z3950_options, Z_Options_triggerResourceCtrl);
    ODR_MASK_SET(&z3950_options, Z_Options_scan);
    ODR_MASK_SET(&z3950_options, Z_Options_sort);
    ODR_MASK_SET(&z3950_options, Z_Options_extendedServices);
    ODR_MASK_SET(&z3950_options, Z_Options_delSet);

    while ((ret = options("k:c:q:a:b:m:v:p:u:t:Vxd:", argv, argc, &arg)) != -2)
    {
        switch (ret)
        {
        case 0:
            if (!open_command)
            {
                open_command = (char *) xmalloc (strlen(arg)+6);
                strcpy (open_command, "open ");
                strcat (open_command, arg);
            }
            else
            {
                fprintf(stderr, "%s: Specify at most one server address\n",
                        prog);
                exit(1);
            }
            break;
        case 'd':
            dump_file_prefix = arg;
            break;
        case 'k':
            kilobytes = atoi(arg);
            break;
        case 'm':
            if (!(marc_file = fopen (arg, "a")))
            {
                perror (arg);
                exit (1);
            }
            break;
        case 't':
            outputCharset = xstrdup(arg);
            break;
        case 'c':
            strncpy (ccl_fields, arg, sizeof(ccl_fields)-1);
            ccl_fields[sizeof(ccl_fields)-1] = '\0';
            break;
        case 'q':
            strncpy (cql_fields, arg, sizeof(cql_fields)-1);
            cql_fields[sizeof(cql_fields)-1] = '\0';
            break;
        case 'b':
            if (!strcmp(arg, "-"))
                ber_file=stderr;
            else
                ber_file=fopen(arg, "a");
            break;
        case 'a':
            if (!strcmp(arg, "-"))
                apdu_file=stderr;
            else
                apdu_file=fopen(arg, "a");
            break;
        case 'x':
            hex_dump = 1;
            break;
        case 'p':
            yazProxy = xstrdup(arg);
            break;
        case 'u':
            if (!auth_command)
            {
                auth_command = (char *) xmalloc (strlen(arg)+6);
                strcpy (auth_command, "auth ");
                strcat (auth_command, arg);
            }
            break;
        case 'v':
            yaz_log_init(yaz_log_mask_str(arg), "", 0);
            break;
        case 'V':
            show_version();
            break;
        default:
            fprintf (stderr, "Usage: %s "
                     " [-a <apdulog>]"
                     " [-b berdump]"
                     " [-d dump]\n"
                     " [-c cclfields]"
                     " [-k size]"
                     " [-m <marclog>]\n" 
                     " [-p <proxy-addr>]"
                     " [-q cqlfields]"
                     " [-u <auth>]"
                     " [-V]"
                     " [<server-addr>]\n",
                     prog);
            exit (1);
        }      
    }
    initialize();
    if (auth_command)
    {
#ifdef HAVE_GETTIMEOFDAY
        gettimeofday (&tv_start, 0);
#endif
        process_cmd_line (auth_command);
#if HAVE_READLINE_HISTORY_H
        add_history(auth_command);
#endif
        xfree(auth_command);
    }
    if (open_command)
    {
#ifdef HAVE_GETTIMEOFDAY
        gettimeofday (&tv_start, 0);
#endif
        process_cmd_line (open_command);
#if HAVE_READLINE_HISTORY_H
        add_history(open_command);
#endif
        xfree(open_command);
    }
    client ();
    exit (0);
}
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

