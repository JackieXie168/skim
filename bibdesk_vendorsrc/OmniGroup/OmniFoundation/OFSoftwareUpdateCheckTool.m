// Copyright 2002-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import "OFSoftwareUpdateCheckTool.h"

#import <OmniBase/rcsid.h>
#import <CoreFoundation/CFURL.h>
#import <CoreFoundation/CFURLAccess.h>
#import <SystemConfiguration/SCDynamicStore.h>
#import <SystemConfiguration/SCNetwork.h>

RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OFSoftwareUpdateCheckTool.m,v 1.3 2003/03/26 00:24:35 wiml Exp $");

void contemplate_reachability(const char *hostname);
void perform_check(const char *url);
char *argv0;

void fwriteData(CFDataRef buf, FILE *fp);
void fputString(CFStringRef str, FILE *fp);

void usage()
{
    fprintf(stderr, "usage: %s firsthophost url\n"
            "\tUnobtrusively retrieves the specified URL, which must contain\n"
            "\ta plist, and writes its contents to stdout.\n\tExit code indicates reason for failure.\n",
            argv0);
    exit(OFOSUSCT_MiscFailure);
}


int main(int argc, char **argv)
{
    argv0 = argv[0];

    if (argc != 3 || !strchr(argv[2], ':')) {
        usage();
    }

    contemplate_reachability(argv[1]);
    perform_check(argv[2]);

    return OFOSUSCT_Success;
}

void contemplate_reachability(const char *hostname)
{
    SCNetworkConnectionFlags status;

    if (!hostname || !*hostname)
        return;

    if (!SCNetworkCheckReachabilityByName(hostname, &status)) {
        // Unable to determine whether the host is reachable. Most likely problem is that we failed to look up the host name. Most likely reason for that is a network partition, or a multiple failure of name servers (because, of course, EVERYONE actually READS the dns specs and maintains at least two nameservers with decent geographical and topological separation, RIGHT?). Another possibility is that configd is screwed up somehow. At any rate, it's unlikely that we'd be able to retrieve the status info, so return an error.
        exit(OFOSUSCT_RemoteNetworkFailure);
    }

    if (!(status & kSCNetworkFlagsReachable))
        exit (OFOSUSCT_LocalNetworkFailure);
}

void perform_check(const char *urlString)
{
    CFURLRef url = CFURLCreateWithBytes(kCFAllocatorDefault, urlString, strlen(urlString), kCFStringEncodingUTF8, NULL);
    SInt32 errorCode;
    CFStringRef errorString;
    int exitCode;
    CFDataRef data;
    CFDictionaryRef properties;
    CFMutableDictionaryRef result;

    exitCode = OFOSUSCT_Success;
    errorString = NULL;

    // There's no way to make these functions use a proxy server, as far as I can tell. This makes baby Jesus cry.
    if (!CFURLCreateDataAndPropertiesFromResource(kCFAllocatorDefault, url, &data, &properties, NULL, &errorCode)) {
        switch(errorCode) {
            case kCFURLRemoteHostUnavailableError:
            case kCFURLTimeoutError:
                exit(OFOSUSCT_RemoteNetworkFailure);
            case kCFURLResourceNotFoundError:
            case kCFURLResourceAccessViolationError:
                exit(OFOSUSCT_RemoteServiceFailure);
            default:
                exit(OFOSUSCT_MiscFailure);
        }
    }

    if (properties != NULL && CFNumberGetValue(CFDictionaryGetValue(properties, kCFURLHTTPStatusCode), kCFNumberSInt32Type, &errorCode)) {
        if (errorCode / 100 != 2) {
            errorString = CFDictionaryGetValue(properties, kCFURLHTTPStatusLine);
            exitCode = OFOSUSCT_RemoteServiceFailure;
        }
    }
    
    result = CFDictionaryCreateMutable(kCFAllocatorDefault, 2, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    if (data != NULL && errorString == NULL) {
        CFPropertyListRef parsedData;

        parsedData = CFPropertyListCreateFromXMLData(kCFAllocatorDefault, data, kCFPropertyListImmutable, &errorString);
        if (parsedData) {
            CFDictionaryAddValue(result, CFSTR("plist"), parsedData);
            CFRelease(parsedData);
        } else {
            exitCode = OFOSUSCT_RemoteServiceFailure;
            fputString(errorString, stderr);
            fputs("\n", stderr);
        }
    }
    if (properties)
        CFDictionaryAddValue(result, CFSTR("headers"), properties);
    if (errorString) {
        CFDictionaryAddValue(result, CFSTR("error"), errorString);
        CFRelease(errorString);
    }

    if (CFDictionaryGetCount(result) > 0) {
        CFDataRef xml = CFPropertyListCreateXMLData(kCFAllocatorDefault, result);
        fwriteData(xml, stdout);
        CFRelease(xml);
    } else {
        if (!exitCode)
            exitCode = OFOSUSCT_MiscFailure;
    }

    CFRelease(result);
    
    if (exitCode)
        exit(exitCode);
}

void fwriteData(CFDataRef buf, FILE *fp)
{
    fwrite(CFDataGetBytePtr(buf), 1, CFDataGetLength(buf), fp);
}

void fputString(CFStringRef str, FILE *fp)
{
    CFDataRef utf8Data = CFStringCreateExternalRepresentation(kCFAllocatorDefault, str, kCFStringEncodingNonLossyASCII, (UInt8)'?');

    fwriteData(utf8Data, fp);

    CFRelease(utf8Data);
}


