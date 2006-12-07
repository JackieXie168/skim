// Copyright 2005-2006 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "NSError-OFExtensions.h"

#import <Foundation/Foundation.h>
#import <OmniBase/rcsid.h>
#import <OmniFoundation/OmniFoundation.h>

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSError-OFExtensions.m 79079 2006-09-07 22:35:32Z kc $");

NSString *OFUserCancelledActionErrorKey = OMNI_BUNDLE_IDENTIFIER @".ErrorDomain.ErrorDueToUserCancel";
NSString *OFFileNameAndNumberErrorKey = OMNI_BUNDLE_IDENTIFIER @".ErrorDomain.FileLineAndNumber";

static NSMutableDictionary *_createUserInfo(NSString *firstKey, va_list args)
{
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];

    NSString *key = firstKey;
    while (key) { // firstKey might be nil
	id value = va_arg(args, id);
	[userInfo setValue:value forKey:key];
	key = va_arg(args, id);
    }
    
    return userInfo;
}

@implementation NSError (OFExtensions)

/*" Returns YES if the receiver or any of its underlying errors has a user info key of OFUserCancelledActionErrorKey with a boolean value of YES.  Under 10.4 and higher, this also returns YES if the receiver or any of its underlying errors has the domain NSCocoaErrorDomain and code NSUserCancelledError (see NSResponder.h). "*/
- (BOOL)causedByUserCancelling;
{
    NSError *error = self;
    while (error) {
	NSDictionary *userInfo = [error userInfo];
	if ([[userInfo valueForKey:OFUserCancelledActionErrorKey] boolValue])
	    return YES;
	
#if defined(MAC_OS_X_VERSION_10_4) && MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_4
	// TJW: There is also NSUserCancelledError in 10.4.  See NSResponder.h -- it says NSApplication will bail on presenting the error if the domain is NSCocoaErrorDomain and code is NSUserCancelledError.  It's unclear if NSApplication checks the whole chain (question open on cocoa-dev as of 2005/09/29).
	if ([[error domain] isEqualToString:NSCocoaErrorDomain] && [error code] == NSUserCancelledError)
	    return YES;
#endif
	
	error = [userInfo valueForKey:NSUnderlyingErrorKey];
    }
    return NO;
}

@end

void OFErrorWithDomainv(NSError **error, NSString *domain, int code, const char *fileName, unsigned int line, NSString *firstKey, va_list args)
{
    OBPRECONDITION(error); // Must supply a error pointer or this is pointless (since it is in-out)
    
    NSMutableDictionary *userInfo = _createUserInfo(firstKey, args);
    
    // Add in the previous error, if there was one
    if (*error) {
	OBASSERT(![userInfo valueForKey:NSUnderlyingErrorKey]); // Don't pass NSUnderlyingErrorKey in the varargs to this macro, silly!
	[userInfo setValue:*error forKey:NSUnderlyingErrorKey];
    }
    
    // Add in file and line information if the file was supplied
    if (fileName) {
	NSString *fileString = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:fileName length:strlen(fileName)];
	[userInfo setValue:[fileString stringByAppendingFormat:@":%d", line] forKey:OFFileNameAndNumberErrorKey];
    }
    
    *error = [NSError errorWithDomain:domain code:code userInfo:userInfo];
    [userInfo release];
}

/*" Convenience function, invoked by the OFError macro, that allows for creating error objects with user info objects without creating a dictionary object.  The keys and values list must be terminated with a nil key. Integer error codes are _so_ 1980...  This creates a different domain for each error based on the bundle identifier and a name and then uses code=0 within that domain. "*/
void _OFError(NSError **error, NSString *bundleIdentifier, const char *name, const char *fileName, unsigned int line, NSString *firstKey, ...)
{
    OBPRECONDITION(![NSString isEmptyString:bundleIdentifier]); // Did you forget to define OMNI_BUNDLE_IDENTIFIER in your target?
    
    // 'ErrorDomain' suggested by NSError documentation
    NSString *domain = [[NSString alloc] initWithFormat:@"%@.ErrorDomain.%s", bundleIdentifier, name];

    va_list args;
    va_start(args, firstKey);
    OFErrorWithDomainv(error, domain, 0, fileName, line, firstKey, args);
    va_end(args);
    [domain release];
}

/* As above, but if you want to use a plain domain with a list of integer codes */
void _OFErrorWithCode(NSError **error, NSString *domain, int code, const char *fileName, unsigned int line, NSString *firstKey, ...)
{
    OBPRECONDITION(![NSString isEmptyString:domain]);
    
    va_list args;
    va_start(args, firstKey);
    OFErrorWithDomainv(error, domain, code, fileName, line, firstKey, args);
    va_end(args);
    [domain release];
}
