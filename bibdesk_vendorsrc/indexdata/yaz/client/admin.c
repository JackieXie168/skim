/*
 * Copyright (C) 1995-2005, Index Data ApS
 * See the file LICENSE for details.
 *
 * $Id: admin.c,v 1.22 2006/10/04 16:59:33 mike Exp $
 */

#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <assert.h>

#if HAVE_DIRENT_H
#include <dirent.h>
#endif
#if HAVE_FNMATCH_H
#include <fnmatch.h>
#endif
#if HAVE_SYS_STAT_H
#include <sys/stat.h>
#endif

#include <yaz/yaz-util.h>

#include <yaz/tcpip.h>

#include <yaz/proto.h>
#include <yaz/marcdisp.h>
#include <yaz/diagbib1.h>

#include <yaz/pquery.h>

#include "admin.h"

/* Helper functions to get to various statics in the client */
ODR getODROutputStream(void);

extern char *databaseNames[];
extern int num_databaseNames;

int sendAdminES(int type, char* param1)
{
    ODR out = getODROutputStream();
    char *dbname = odr_strdup (out, databaseNames[0]);
    
    /* Type: 1=reindex, 2=truncate, 3=delete, 4=create, 5=import, 6=refresh, 7=commit */
    Z_APDU *apdu = zget_APDU(out, Z_APDU_extendedServicesRequest );
    Z_ExtendedServicesRequest *req = apdu->u.extendedServicesRequest;
    Z_External *r;
    int oid[OID_SIZE];
    Z_ESAdminOriginPartToKeep  *toKeep;
    Z_ESAdminOriginPartNotToKeep  *notToKeep;
    oident update_oid;
    printf ("Admin request\n");
    fflush(stdout);

    /* Set up the OID for the external */
    update_oid.proto = PROTO_Z3950;
    update_oid.oclass = CLASS_EXTSERV;
    update_oid.value = VAL_ADMINSERVICE;

    oid_ent_to_oid (&update_oid, oid);
    req->packageType = odr_oiddup(out,oid);
    req->packageName = "1.Extendedserveq";

    /* Allocate the external */
    r = req->taskSpecificParameters = (Z_External *)
        odr_malloc (out, sizeof(*r));
    r->direct_reference = odr_oiddup(out,oid);
    r->indirect_reference = 0;
    r->descriptor = 0;
    r->which = Z_External_ESAdmin;
    r->u.adminService = (Z_Admin *)
        odr_malloc(out, sizeof(*r->u.adminService));
    r->u.adminService->which = Z_Admin_esRequest;
    r->u.adminService->u.esRequest = (Z_AdminEsRequest *)
        odr_malloc(out, sizeof(*r->u.adminService->u.esRequest));
    
    toKeep = r->u.adminService->u.esRequest->toKeep =
        (Z_ESAdminOriginPartToKeep *) 
        odr_malloc(out, sizeof(*r->u.adminService->u.esRequest->toKeep));
    
    toKeep->which=type;
    toKeep->databaseName = dbname;
    switch ( type )
    {
    case Z_ESAdminOriginPartToKeep_reIndex:
        toKeep->u.reIndex=odr_nullval();
        break;
        
    case Z_ESAdminOriginPartToKeep_truncate:
        toKeep->u.truncate=odr_nullval();
        break;
    case Z_ESAdminOriginPartToKeep_drop:
        toKeep->u.drop=odr_nullval();
        break;
    case Z_ESAdminOriginPartToKeep_create:
        toKeep->u.create=odr_nullval();
        break;
    case Z_ESAdminOriginPartToKeep_import:
        toKeep->u.import = (Z_ImportParameters*)
            odr_malloc(out, sizeof(*toKeep->u.import));
        toKeep->u.import->recordType=param1;
        /* Need to add additional setup of records here */
        break;
    case Z_ESAdminOriginPartToKeep_refresh:
        toKeep->u.refresh=odr_nullval();
        break;
    case Z_ESAdminOriginPartToKeep_commit:
        toKeep->u.commit=odr_nullval();
        break;
    case Z_ESAdminOriginPartToKeep_shutdown:
        toKeep->u.commit=odr_nullval();
        break;
    case Z_ESAdminOriginPartToKeep_start:
        toKeep->u.commit=odr_nullval();
        break;
    default:
        /* Unknown admin service */
        break;
    }
    
    notToKeep = r->u.adminService->u.esRequest->notToKeep =
        (Z_ESAdminOriginPartNotToKeep *)
        odr_malloc(out, sizeof(*r->u.adminService->u.esRequest->notToKeep));
    notToKeep->which=Z_ESAdminOriginPartNotToKeep_recordsWillFollow;
    notToKeep->u.recordsWillFollow=odr_nullval();
    
    send_apdu(apdu);
    
    return 0;
}

/* cmd_adm_reindex
   Ask the specified database to fully reindex itself */
int cmd_adm_reindex(const char *arg)
{
    sendAdminES(Z_ESAdminOriginPartToKeep_reIndex, NULL);
    return 2;
}

/* cmd_adm_truncate
   Truncate the specified database, removing all records and index entries, but leaving 
   the database & it's explain information intact ready for new records */
int cmd_adm_truncate(const char *arg)
{
    if ( arg )
    {
        sendAdminES(Z_ESAdminOriginPartToKeep_truncate, NULL);
        return 2;
    }
    return 0;
}

/* cmd_adm_create
   Create a new database */
int cmd_adm_create(const char *arg)
{
    if ( arg )
    {
        sendAdminES(Z_ESAdminOriginPartToKeep_create, NULL);
        return 2;
    }
    return 0;
}

/* cmd_adm_drop
   Drop (Delete) a database */
int cmd_adm_drop(const char *arg)
{
    if ( arg )
    {
        sendAdminES(Z_ESAdminOriginPartToKeep_drop, NULL);
        return 2;
    }
    return 0;
}

/* cmd_adm_import <dbname> <rectype> <sourcefile>
   Import the specified updated into the database
   N.B. That in this case, the import may contain instructions to delete records as well as new or updates
   to existing records */

#if HAVE_FNMATCH_H
int cmd_adm_import(const char *arg)
{
    char type_str[20], dir_str[1024], pattern_str[1024];
    char *cp;
    char *sep = "/";
    DIR *dir;
    struct dirent *ent;
    int chunk = 10;
    Z_APDU *apdu = 0;
    Z_Segment *segment = 0;
    ODR out = getODROutputStream();

    if (arg && sscanf (arg, "%19s %1023s %1023s", type_str,
                       dir_str, pattern_str) != 3)
        return 0;
    if (num_databaseNames != 1)
        return 0;
    dir = opendir(dir_str);
    if (!dir)
        return 0;
    
    sendAdminES(Z_ESAdminOriginPartToKeep_import, type_str);
    
    printf ("sent es request\n");
    if ((cp=strrchr(dir_str, '/')) && cp[1] == 0)
        sep="";
        
    while ((ent = readdir(dir)))
    {
        if (fnmatch (pattern_str, ent->d_name, 0) == 0)
        {
            char fname[1024];
            struct stat status;
            FILE *inf;
                
            sprintf (fname, "%s%s%s", dir_str, sep, ent->d_name);
            stat (fname, &status);

            if (S_ISREG(status.st_mode) && (inf = fopen(fname, "r")))
            {
                Z_NamePlusRecord *rec;
                Odr_oct *oct = (Odr_oct *) odr_malloc (out, sizeof(*oct));

                if (!apdu)
                {
                    apdu = zget_APDU(out, Z_APDU_segmentRequest);
                    segment = apdu->u.segmentRequest;
                    segment->segmentRecords = (Z_NamePlusRecord **)
                        odr_malloc (out, chunk * sizeof(*segment->segmentRecords));
                }
                rec = (Z_NamePlusRecord *) odr_malloc (out, sizeof(*rec));
                rec->databaseName = 0;
                rec->which = Z_NamePlusRecord_intermediateFragment;
                rec->u.intermediateFragment = (Z_FragmentSyntax *)
                    odr_malloc (out, sizeof(*rec->u.intermediateFragment));
                rec->u.intermediateFragment->which =
                    Z_FragmentSyntax_notExternallyTagged;
                rec->u.intermediateFragment->u.notExternallyTagged = oct;
                
                oct->len = oct->size = status.st_size;
                oct->buf = (unsigned char *) odr_malloc (out, oct->size);
                fread (oct->buf, 1, oct->size, inf);
                fclose (inf);
                
                segment->segmentRecords[segment->num_segmentRecords++] = rec;

                if (segment->num_segmentRecords == chunk)
                {
                    send_apdu (apdu);
                    apdu = 0;
                }
            }   
        }
    }
    if (apdu)
        send_apdu(apdu);
    apdu = zget_APDU(out, Z_APDU_segmentRequest);
    send_apdu (apdu);
    closedir(dir);
    return 2;
}
#else
int cmd_adm_import(const char *arg)
{
    printf ("not available on WIN32\n");
    return 0;
}
#endif


/* "Freshen" the specified database, by checking metadata records against the sources from which they were 
   generated, and creating a new record if the source has been touched since the last extraction */
int cmd_adm_refresh(const char *arg)
{
    if ( arg )
    {
        sendAdminES(Z_ESAdminOriginPartToKeep_refresh, NULL);
        return 2;
    }
    return 0;
}

/* cmd_adm_commit 
   Make imported records a permenant & visible to the live system */
int cmd_adm_commit(const char *arg)
{
    sendAdminES(Z_ESAdminOriginPartToKeep_commit, NULL);
    return 2;
}

int cmd_adm_shutdown(const char *arg)
{
    sendAdminES(Z_ESAdminOriginPartToKeep_shutdown, NULL);
    return 2;
}

int cmd_adm_startup(const char *arg)
{
    sendAdminES(Z_ESAdminOriginPartToKeep_start, NULL);
    return 2;
}
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

