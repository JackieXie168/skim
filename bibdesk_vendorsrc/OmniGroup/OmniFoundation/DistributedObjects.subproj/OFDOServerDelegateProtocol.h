// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/DistributedObjects.subproj/OFDOServerDelegateProtocol.h 68913 2005-10-03 19:36:19Z kc $

#import <Foundation/NSObject.h>

@class NSException;

@protocol OFDOServerDelegateProtocol <NSObject>

- (BOOL)terminateFromException:(NSException *)anException;
    // If global exception handling is enabled, the OFDOServer wraps each message received from a client in an exception handling block.  If an exception occurs, it messages the delegate with the exception.  The return value from the delegate method determines whether the server continues receiving messages, or terminates.  Normally, uncaught exceptions in a DO server are lost in the NSRunLoop.

@end
