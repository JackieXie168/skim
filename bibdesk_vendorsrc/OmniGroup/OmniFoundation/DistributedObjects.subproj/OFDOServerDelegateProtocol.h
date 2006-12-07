// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/DistributedObjects.subproj/OFDOServerDelegateProtocol.h,v 1.6 2004/02/10 04:07:44 kc Exp $

#import <Foundation/NSObject.h>

@class NSException;

@protocol OFDOServerDelegateProtocol <NSObject>

- (BOOL)terminateFromException:(NSException *)anException;
    // If global exception handling is enabled, the OFDOServer wraps each message received from a client in an exception handling block.  If an exception occurs, it messages the delegate with the exception.  The return value from the delegate method determines whether the server continues receiving messages, or terminates.  Normally, uncaught exceptions in a DO server are lost in the NSRunLoop.

@end
