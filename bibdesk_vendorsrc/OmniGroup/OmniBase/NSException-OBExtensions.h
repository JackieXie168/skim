// Copyright 2001-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniBase/NSException-OBExtensions.h,v 1.4 2003/02/08 00:54:59 wiml Exp $

#import <Foundation/NSException.h>

@interface NSException (OBExtensions)
+ (void)raise:(NSString *)exceptionName posixErrorNumber:(int)posixErrorNumber format:(NSString *)format, ...;
- (int)posixErrorNumber;
@end

#import <OmniBase/FrameworkDefines.h>

OmniBase_EXTERN NSString *OBExceptionPosixErrorNumberKey;
OmniBase_EXTERN NSString *OBExceptionCarbonErrorNumberKey;

