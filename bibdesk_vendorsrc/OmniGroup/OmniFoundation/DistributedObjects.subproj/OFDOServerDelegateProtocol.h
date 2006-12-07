// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/DistributedObjects.subproj/OFDOServerDelegateProtocol.h,v 1.4 2003/01/15 22:51:56 kc Exp $

#import <Foundation/NSObject.h>

@class NSException;

@protocol OFDOServerDelegateProtocol <NSObject>

- (BOOL)terminateFromException:(NSException *)anException;
    // If global exception handling is enabled, the OFDOServer wraps each message received from a client in an exception handling block.  If an exception occurs, it messages the delegate with the exception.  The return value from the delegate method determines whether the server continues receiving messages, or terminates.  Normally, uncaught exceptions in a DO server are lost in the NSRunLoop.

@end
