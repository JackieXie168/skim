// Copyright 2001-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "NSException-OBExtensions.h"

#import <Foundation/Foundation.h>

#import "macros.h"
#import "OBUtilities.h"
#import "rcsid.h"

RCS_ID("$Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniBase/NSException-OBExtensions.m 68913 2005-10-03 19:36:19Z kc $");

@implementation NSException (OBExtensions)

+ (void)raise:(NSString *)exceptionName posixErrorNumber:(int)posixErrorNumber format:(NSString *)format, ...;
{
    va_list argList;
    NSString *formattedString;

    va_start(argList, format);
    formattedString = [[[NSString alloc] initWithFormat:format arguments:argList] autorelease];
    va_end(argList);
    [[NSException exceptionWithName:exceptionName reason:formattedString userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:posixErrorNumber] forKey:OBExceptionPosixErrorNumberKey]] raise];
}

+ (NSException *)exceptionWithName:(NSString *)exceptionName posixErrorNumber:(int)posixErrorNumber format:(NSString *)format, ...;
{
    va_list argList;
    NSString *formattedString;

    va_start(argList, format);
    formattedString = [[[NSString alloc] initWithFormat:format arguments:argList] autorelease];
    va_end(argList);
    return [NSException exceptionWithName:exceptionName reason:formattedString userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:posixErrorNumber] forKey:OBExceptionPosixErrorNumberKey]];
}

- (int)posixErrorNumber;
{
    NSNumber *errorNumber;

    errorNumber = [[self userInfo] objectForKey:OBExceptionPosixErrorNumberKey];
    return errorNumber != nil ? [errorNumber intValue] : 0;
}

@end

NSString *OBExceptionPosixErrorNumberKey = @"errno";
NSString *OBExceptionCarbonErrorNumberKey = @"OSErr";
