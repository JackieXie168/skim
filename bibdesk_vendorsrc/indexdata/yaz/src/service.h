/*
 * NT Service interface Utility.
 *  Based on code written by
 *     Chas Woodfield, Fretwell Downing Datasystems.
 * $Id: service.h,v 1.3 2005/06/25 15:46:05 adam Exp $
 */
/**
 * \file service.h
 * \brief Header for NT service handling.
 */

#ifndef SERVICE_INCLUDED
#define SERVICE_INCLUDED

#ifdef WIN32

#include <windows.h>

typedef struct _Service
{
    LPTSTR pAppName;
    LPTSTR pServiceName;
    LPTSTR pServiceDisplayName;
    LPTSTR pDependancies;
    TCHAR szErr[256];
    SERVICE_STATUS_HANDLE hService;
    SERVICE_STATUS ServiceStatus;
    SERVICE_TABLE_ENTRY ServiceTable[2];
    int argc;
    char **argv;
} AppService;

/* Called by the app to initialize the service */
BOOL SetupService(int argc, char *argv[], void *pHandle, LPTSTR pAppName, LPTSTR pServiceName, LPTSTR pServiceDisplayName, LPTSTR pDependancies);

#endif /* WIN32 */

/* Functions that must be in the main application */
/* Initializes the app */
int StartAppService(void *pHandle, int argc, char **argv);

/* Now we wait for any connections */
void RunAppService(void *pHandle);

/* Time to tidyup and stop the service */
void StopAppService(void *pHandle);

#endif
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

