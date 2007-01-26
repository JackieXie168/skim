/*
 * NT Service interface Utility.
 *  Based on code written by
 *     Chas Woodfield, Fretwell Downing Informatics.
 * $Id: service.c,v 1.5 2007/01/03 08:42:15 adam Exp $
 */

/**
 * \file service.c
 * \brief Implements NT service handling for GFS.
 */

#ifdef WIN32

#include <windows.h>
#include <stdio.h>
#include <tchar.h>
#include <direct.h>

#include "service.h"

static AppService *pService = NULL;
static BOOL bRunAsService = TRUE;
static void *pAppHandle = NULL;

/* Private functions to this module */
void Service_Create(LPTSTR pAppName, LPTSTR pServiceName, LPTSTR pServiceDisplayName, LPTSTR pDependancies, int argc, char **argv);
void Service_Delete();
void Service_Initialize();
BOOL NotifyServiceController();
BOOL UpdateServiceStatus(DWORD Status);
void FailServiceStart(DWORD Win32Code, DWORD PrivateCode);
void CmdInstallService(int argc, char *argv[], BOOL bAutoStart);
void CmdRemoveService();
LPTSTR GetLastErrorText(LPTSTR lpszBuf, DWORD dwSize);
BOOL CheckServiceArguments(int argc, char *argv[]);

/* Callback functions for thee service manager */
void WINAPI ServiceMain(DWORD argc, LPTSTR argv[]);
void WINAPI ServiceControlHandler(DWORD fdwControl);

/* Function to handle Ctrl + C etc... */
BOOL EventHandlerRoutine(DWORD dwCtrlType);

void Service_Create(LPTSTR pAppName, LPTSTR pServiceName, LPTSTR pServiceDisplayName, LPTSTR pDependancies, int argc, char **argv)
{
    pService = malloc(sizeof(AppService));
    pService->pAppName = pAppName;
    pService->pServiceName = pServiceName;
    pService->pServiceDisplayName = pServiceDisplayName;
    pService->pDependancies = pDependancies;
    pService->hService = 0;
    pService->ServiceTable[0].lpServiceName = pServiceName; 
    pService->ServiceTable[0].lpServiceProc = ServiceMain; 
    pService->ServiceTable[1].lpServiceName = NULL; 
    pService->ServiceTable[1].lpServiceProc = NULL; 
    pService->argc = argc;
    pService->argv = argv;
}

void Service_Delete()
{
    if (pService != NULL)
    {
        /* Mark the service as stopping */
        UpdateServiceStatus(SERVICE_STOP_PENDING);

        /* Stop the service */
        StopAppService(pAppHandle);

        /* Service has now stopped */
        UpdateServiceStatus(SERVICE_STOPPED);

        /* Free the memory */
        free(pService);
        pService = NULL;
    }
}

void Service_Initialize()
{
    if (pService != NULL)
    {
        /* Register ourselves with the control dispatcher */
        StartServiceCtrlDispatcher(pService->ServiceTable);
    }
}

void WINAPI ServiceMain(DWORD argc, LPTSTR argv[])
{
    if (pService != NULL)
    {
        if (NotifyServiceController())
        {
            /* Set the status to pending */
            UpdateServiceStatus(SERVICE_START_PENDING);

            /* Lets attempt to start the service */
            if (StartAppService(pAppHandle, pService->argc, pService->argv))
            {
                /* Service is now up and running */
                UpdateServiceStatus(SERVICE_RUNNING);

                /* Lets wait for our clients */
                RunAppService(pAppHandle);
            }
            else
            {
                FailServiceStart(GetLastError(), 0);
                Service_Delete();
            }
        }
    }
}

BOOL NotifyServiceController()
{
    if (pService == NULL)
    {
        return(FALSE);
    }
    else
    {
        if (bRunAsService)
        {
            pService->ServiceStatus.dwServiceType = SERVICE_WIN32_OWN_PROCESS;
            pService->ServiceStatus.dwCurrentState = SERVICE_STOPPED;
            pService->ServiceStatus.dwControlsAccepted = SERVICE_ACCEPT_STOP;
            pService->ServiceStatus.dwWin32ExitCode = 0;
            pService->ServiceStatus.dwServiceSpecificExitCode = 0;
            pService->ServiceStatus.dwCheckPoint = 0;
            pService->ServiceStatus.dwWaitHint = 0;
            pService->hService = RegisterServiceCtrlHandler(pService->pServiceName, ServiceControlHandler);

            if (pService->hService)
                UpdateServiceStatus(SERVICE_START_PENDING);
            else
                return(FALSE);
        }
        return(TRUE);
    }
}

void WINAPI ServiceControlHandler(DWORD fdwControl)
{
    if (pService != NULL)
    {
        switch (fdwControl)
        {
            case SERVICE_CONTROL_STOP:
                /* Update the service status to be pending */
                Service_Delete();
                break;

            case SERVICE_CONTROL_INTERROGATE:
                UpdateServiceStatus(pService->ServiceStatus.dwCurrentState);
                break;

            default:
                break;
        }
    }
}

BOOL UpdateServiceStatus(DWORD Status)
{
    if (pService != NULL)
    {
        if (pService->hService)
        {
            pService->ServiceStatus.dwCurrentState = Status;
            if ((Status == SERVICE_START_PENDING) || (Status == SERVICE_STOP_PENDING))
            {
                pService->ServiceStatus.dwCheckPoint ++;
                pService->ServiceStatus.dwWaitHint = 5000;    /* 5 sec.*/
            }
            else
            {
                pService->ServiceStatus.dwCheckPoint = 0;
                pService->ServiceStatus.dwWaitHint = 0;
            }

            return(SetServiceStatus(pService->hService, &pService->ServiceStatus));
        }
    }

    return(FALSE);
}

void FailServiceStart(DWORD Win32Code, DWORD PrivateCode)
{
    if (pService != NULL)
    {
        pService->ServiceStatus.dwWin32ExitCode = Win32Code;
        pService->ServiceStatus.dwServiceSpecificExitCode = PrivateCode;
        UpdateServiceStatus(SERVICE_STOPPED);
    }
}

void CmdInstallService(int argc, char *argv[], BOOL bAutoStart)
{
    if (pService != NULL)
    {
        SC_HANDLE   schService;
        SC_HANDLE   schSCManager;

        TCHAR szPath[2048];

        if (GetModuleFileName(NULL, szPath, 512) == 0)
        {
            _tprintf(TEXT("Unable to install %s - %s\n"), TEXT(pService->pServiceDisplayName), GetLastErrorText(pService->szErr, 256));
        }
        else
        {
            int i;
            char cwdstr[_MAX_PATH];

            if (!_getcwd(cwdstr, sizeof(cwdstr)))
                strcpy (cwdstr, ".");

            strcat (szPath, TEXT(" -runservice \""));
            strcat (szPath, cwdstr);
            strcat (szPath, "\"");

            for (i = 1; i < argc; i++)
            {
                /* We will add the given command line arguments to the command */
                /* We are not interested in the install and remove options */
                if ((strcmp("-install", argv[i]) != 0) &&
                    (strcmp("-installa", argv[i]) != 0) &&
                    (strcmp("-remove", argv[i]) != 0))
                {
                    strcat(szPath, TEXT(" "));
                    strcat(szPath, argv[i]);
                }
            }

            schSCManager = OpenSCManager(NULL,                   /* machine (NULL == local) */
                                         NULL,                   /* database (NULL == default) */
                                         SC_MANAGER_ALL_ACCESS); /* access required */
            if (schSCManager)
            {
                schService = CreateService(schSCManager,               /* SCManager database */
                                           TEXT(pService->pServiceName),        /* name of service */
                                           TEXT(pService->pServiceDisplayName), /* name to display */
                                           SERVICE_ALL_ACCESS,         /* desired access */
                                           SERVICE_WIN32_OWN_PROCESS,  /* service type */
                                           bAutoStart ? SERVICE_AUTO_START :
                                                        SERVICE_DEMAND_START, /* start type */
                                           SERVICE_ERROR_NORMAL,       /* error control type */
                                           szPath,                     /* service's binary */
                                           NULL,                       /* no load ordering group */
                                           NULL,                       /* no tag identifier */
                                           TEXT(pService->pDependancies),       /* dependencies */
                                           NULL,                       /* LocalSystem account */
                                           NULL);                      /* no password */

                if (schService)
                {
                    _tprintf(TEXT("%s installed.\n"), TEXT(pService->pServiceDisplayName));
                    CloseServiceHandle(schService);
                }
                else
                {
                    _tprintf(TEXT("CreateService failed - %s\n"), GetLastErrorText(pService->szErr, 256));
                }

                CloseServiceHandle(schSCManager);
            }
            else
                _tprintf(TEXT("OpenSCManager failed - %s\n"), GetLastErrorText(pService->szErr,256));
        }
    }
}

void CmdRemoveService()
{
    if (pService != NULL)
    {
        SC_HANDLE   schService;
        SC_HANDLE   schSCManager;

        schSCManager = OpenSCManager(NULL,                   /* machine (NULL == local) */
                                     NULL,                   /* database (NULL == default) */
                                     SC_MANAGER_ALL_ACCESS); /* access required */
        if (schSCManager)
        {
            schService = OpenService(schSCManager, TEXT(pService->pServiceName), SERVICE_ALL_ACCESS);

            if (schService)
            {
                /* try to stop the service */
                if (ControlService(schService, SERVICE_CONTROL_STOP, &pService->ServiceStatus))
                {
                    _tprintf(TEXT("Stopping %s."), TEXT(pService->pServiceDisplayName));
                    Sleep(1000);

                    while (QueryServiceStatus(schService, &pService->ServiceStatus))
                    {
                        if (pService->ServiceStatus.dwCurrentState == SERVICE_STOP_PENDING)
                        {
                            _tprintf(TEXT("."));
                            Sleep( 1000 );
                        }
                        else
                            break;
                    }

                    if (pService->ServiceStatus.dwCurrentState == SERVICE_STOPPED)
                        _tprintf(TEXT("\n%s stopped.\n"), TEXT(pService->pServiceDisplayName));
                    else
                        _tprintf(TEXT("\n%s failed to stop.\n"), TEXT(pService->pServiceDisplayName));

                }

                /* now remove the service */
                if(DeleteService(schService))
                    _tprintf(TEXT("%s removed.\n"), TEXT(pService->pServiceDisplayName));
                else
                    _tprintf(TEXT("DeleteService failed - %s\n"), GetLastErrorText(pService->szErr,256));

                CloseServiceHandle(schService);
            }
            else
                _tprintf(TEXT("OpenService failed - %s\n"), GetLastErrorText(pService->szErr,256));

            CloseServiceHandle(schSCManager);
        }
        else
            _tprintf(TEXT("OpenSCManager failed - %s\n"), GetLastErrorText(pService->szErr,256));
    }
}

LPTSTR GetLastErrorText(LPTSTR lpszBuf, DWORD dwSize)
{
    DWORD dwRet;
    LPTSTR lpszTemp = NULL;

    dwRet = FormatMessage(FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM |FORMAT_MESSAGE_ARGUMENT_ARRAY,
                          NULL,
                          GetLastError(),
                          LANG_NEUTRAL,
                          (LPTSTR)&lpszTemp,
                          0,
                          NULL);

    /* supplied buffer is not long enough */
    if (!dwRet || ((long)dwSize < (long)dwRet + 14))
        lpszBuf[0] = TEXT('\0');
    else
    {
        lpszTemp[lstrlen(lpszTemp)-2] = TEXT('\0');  /* remove cr and newline character */
        _stprintf(lpszBuf, TEXT("%s (0x%x)"), lpszTemp, GetLastError());
    }

    if (lpszTemp)
        LocalFree((HLOCAL)lpszTemp);

    return(lpszBuf);
}

BOOL CheckServiceArguments(int argc, char *argv[])
{
    int i;

    /* Lets process the arguments */
    for (i = 1; i < argc; i++)
    {
        if (stricmp("-install", argv[i]) == 0)
        {
            /* They want to install the service */
            CmdInstallService(argc, argv, FALSE);

            /* We don't carry on, after we have installed the service */
            return(FALSE);
        }
        else if (stricmp("-installa", argv[i]) == 0)
        {
            /* They want to install the service */
            CmdInstallService(argc, argv, TRUE);

            /* We don't carry on, after we have installed the service */
            return(FALSE);
        }
        else if (stricmp("-remove", argv[i]) == 0)
        {
            /* Here they want to remove it */
            CmdRemoveService();

            /* We don't carry on, after we have removed the service */
            return(FALSE);
        }
        else if (stricmp ("-runservice", argv[i]) == 0)
        {
            /* We can carry on, if we reached here */
            chdir(argv[i+1]);
            argv[i] = "";
            argv[i+1] = "";
            return(TRUE);
        }
    }
    bRunAsService = FALSE;
    return(TRUE);
}

BOOL SetupService(int argc, char *argv[], void *pHandle, LPTSTR pAppName, LPTSTR pServiceName, LPTSTR pServiceDisplayName, LPTSTR pDependancies)
{
    BOOL bDeleteService = TRUE;
    BOOL bResult = FALSE;

    /* Save the handle for later use */
    pAppHandle = pHandle;

    /* Create our service class */
    Service_Create(pAppName, pServiceName, pServiceDisplayName, pDependancies, argc, argv);

    if (CheckServiceArguments(argc, argv))
    {
        if (bRunAsService)
        {
            /* No need to set the console control handler, as the service manager handles all this for us */
            Service_Initialize();
            bDeleteService = FALSE;
        }
        else
        {
            /* Set the console control handler for exiting the program */
            SetConsoleCtrlHandler((PHANDLER_ROUTINE)EventHandlerRoutine, TRUE);

            /* Now do the main work */
            ServiceMain(argc, argv);
        }

        /* We have been successful initializing, so let the caller know */
        bResult = TRUE;
    }

    if (bDeleteService)
    {
        /* Finished with the service now */
        Service_Delete();
    }
    return(bResult);
}

BOOL EventHandlerRoutine(DWORD dwCtrlType)
{
    /* This routine dosn't seem to get called all the time, Why ??? */
    switch (dwCtrlType)
    {
        case CTRL_C_EVENT:        /* A CTRL+C signal was received, either from keyboard input or from a signal generated by the GenerateConsoleCtrlEvent function.*/
        case CTRL_BREAK_EVENT:    /* A CTRL+BREAK signal was received, either from keyboard input or from a signal generated by GenerateConsoleCtrlEvent.*/
        case CTRL_CLOSE_EVENT:    /* A signal that the system sends to all processes attached to a console when the user closes the console (either by choosing the Close command from the console window's System menu, or by choosing the End Task command from the Task List).*/
        case CTRL_LOGOFF_EVENT:   /* A signal that the system sends to all console processes when a user is logging off. This signal does not indicate which user is logging off, so no assumptions can be made.*/
        case CTRL_SHUTDOWN_EVENT: /* A signal that the system sends to all console processes when the system */
            /* We are basically shutting down, so call Service_Delete */
            Service_Delete();
            return(FALSE);
            break;

        default:
            /* we are not handling this one, so return FALSE */
            return(FALSE);
    }
}
#endif
/*
 * Local variables:
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 * vim: shiftwidth=4 tabstop=8 expandtab
 */

