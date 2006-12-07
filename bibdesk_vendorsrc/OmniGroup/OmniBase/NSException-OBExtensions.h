// Copyright 2001-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniBase/NSException-OBExtensions.h 68913 2005-10-03 19:36:19Z kc $

#import <Foundation/NSException.h>

@interface NSException (OBExtensions)
+ (void)raise:(NSString *)exceptionName posixErrorNumber:(int)posixErrorNumber format:(NSString *)format, ...;
+ (NSException *)exceptionWithName:(NSString *)exceptionName posixErrorNumber:(int)posixErrorNumber format:(NSString *)format, ...;
- (int)posixErrorNumber;
@end

#import <OmniBase/FrameworkDefines.h>

OmniBase_EXTERN NSString *OBExceptionPosixErrorNumberKey;
OmniBase_EXTERN NSString *OBExceptionCarbonErrorNumberKey;

