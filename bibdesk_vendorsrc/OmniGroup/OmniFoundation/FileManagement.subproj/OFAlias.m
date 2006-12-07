// Copyright 2004-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OFAlias.h"

#import <Foundation/Foundation.h>
#import <OmniBase/rcsid.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/FileManagement.subproj/OFAlias.m 66265 2005-07-29 04:07:59Z bungi $");

// We may want to store the path verbatim as well as the alias.

@implementation OFAlias

// Init and dealloc

- initWithPath:(NSString *)path;
{
    if ([super init] == nil)
        return nil;

    CFURLRef urlRef = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)path, kCFURLPOSIXPathStyle, false);
    
    FSRef fsRef;

    require(CFURLGetFSRef(urlRef, &fsRef) == true, error_out);
    require_noerr(FSNewAlias(NULL, &fsRef, &_aliasHandle), error_out);

    CFRelease(urlRef);
    
    return self;
error_out:
    CFRelease(urlRef);
    [self release];
    return nil;

}

- initWithData:(NSData *)data;
{
    if ([super init] == nil)
        return nil;

    unsigned int length = [data length];
    _aliasHandle = (AliasHandle)NewHandle(length);   
    [data getBytes:*_aliasHandle length:length];
      
    return self;
}


- (void)dealloc;
{
    if (_aliasHandle != NULL)
        DisposeHandle((Handle)_aliasHandle);
    [super dealloc];
}


// API

- (NSString *)path;
{
    return [self pathAllowingUserInterface:YES missingVolume:NULL];
}

- (NSString *)pathAllowingUserInterface:(BOOL)allowUserInterface missingVolume:(BOOL *)missingVolume;
{
    // We want to allow the caller to avoid blocking if the volume in question is not reachable.  The only way I see to do that is to pass the kResolveAliasFileNoUI flag to FSResolveAliasWithMountFlags.  This will cause it to fail immediately with nsvErr (no such volume).
    FSRef target;
    Boolean wasChanged;
    OSErr result;
    
    unsigned long mountFlags = kResolveAliasTryFileIDFirst;
    if (!allowUserInterface)
	mountFlags |= kResolveAliasFileNoUI;
    
    if (missingVolume)
	*missingVolume = NO;

    result = FSResolveAliasWithMountFlags(NULL, _aliasHandle, &target, &wasChanged, mountFlags);
    if (result == noErr) {
        CFURLRef urlRef = CFURLCreateFromFSRef(kCFAllocatorDefault, &target);
        NSString *urlString = (NSString *)CFURLCopyFileSystemPath(urlRef, kCFURLPOSIXPathStyle);
        CFRelease(urlRef);
        return [urlString autorelease];
    } else if (result == nsvErr) {
	if (missingVolume)
	    *missingVolume = YES;
    } else {
	NSLog(@"FSResolveAliasWithMountFlags -> %d", result);
    }

    return nil;
}

- (NSData *)data;
{
    HLock((Handle)_aliasHandle);
    NSData *retval = [NSData dataWithBytes:*_aliasHandle length:GetHandleSize((Handle)_aliasHandle)];
    HUnlock((Handle)_aliasHandle);
    return retval;
}


@end
