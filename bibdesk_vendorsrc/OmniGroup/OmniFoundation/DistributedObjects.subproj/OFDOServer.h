// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/DistributedObjects.subproj/OFDOServer.h 68913 2005-10-03 19:36:19Z kc $

#import <OmniFoundation/OFObject.h>

@class NSConnection, NSDistantObjectRequest;

#import <OmniFoundation/OFDOServerDelegateProtocol.h>

@interface OFDOServer : OFObject
{
    id <OFDOServerDelegateProtocol> _delegate;
    NSConnection *_defaultConnection;

    BOOL _shouldHandleAllInvocations;
}

//
// Server creation methods.  Can raise.
//

+ serverWithRegisteredName:(NSString *)name;
   // Creates and returns an autoreleased instance of OFDOServer.  During initialization it registers the server name, and sets the instance to be the root object of the default NSConnection.

- initWithRegisteredName:(NSString *)name;
   // Initializes an allocated OFDOServer.  During initialization it registers the server name, and sets the instance to be the root object of the default NSConnection.

- (void)dealloc;


//
// Setting and accessing the delegate.
//

- (id <OFDOServerDelegateProtocol>)delegate;
   // Returns the delegate.  See also: OFDOServerDelegateProtocol.h

- (void)setDelegate:(id <OFDOServerDelegateProtocol>)delegate;
   // Sets the delegate.  See also: OFDOServerDelegateProtocol.h


//
// Using the server.
//

- (void)enableGlobalExceptionHandling;
   // If global exception handling is enabled, the OFDOServer wraps each message received from a client in an exception handling block.  If an exception occurs, it messages the delegate with the exception.  The return value from the delegate method determines whether the server continues receiving messages, or terminates.  Normally, uncaught exceptions in a DO server are lost in the NSRunLoop.

- (void)run;
   // Calls [[NSRunLoop defaultRunLoop] run], which causes the server to run until killed, waiting for messages from clients.

- (NSConnection *)connection;
   // Returns the NSConnection instance which the server used to register itself.  Access to this instance allows you to enable independant conversation queueing, etc.


//
// NSConnection delegate methods.
//

- (BOOL)connection:(NSConnection *)connection handleRequest:(NSDistantObjectRequest *)doreq;
   // OFDOServer becomes the delegate of the default NSConnection, and implements this method, which it uses when global exception handling is enabled.

@end

#import <OmniFoundation/FrameworkDefines.h>

//
// OFDOServer exception names.
//

OmniFoundation_EXTERN NSString *OFDOServerFailedToRegisterName;
