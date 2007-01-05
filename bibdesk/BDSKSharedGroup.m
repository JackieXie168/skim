//
//  BDSKSharedGroup.m
//  Bibdesk
//
//  Created by Adam Maxwell on 04/03/06.
/*
 This software is Copyright (c) 2006,2007
 Adam Maxwell. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 - Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 - Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in
 the documentation and/or other materials provided with the
 distribution.
 
 - Neither the name of Adam Maxwell nor the names of any
 contributors may be used to endorse or promote products derived
 from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "BDSKSharedGroup.h"
#import "BDSKOwnerProtocol.h"
#import "BDSKSharingServer.h"
#import "BDSKPasswordController.h"
#import "NSArray_BDSKExtensions.h"
#import "NSImage+Toolbox.h"
#import <BDSKAsynchronousDOServer.h>
#import "BDSKPublicationsArray.h"
#import "BDSKMacroResolver.h"

typedef struct _BDSKSharedGroupFlags {
    volatile int32_t isRetrieving __attribute__ ((aligned (4)));
    volatile int32_t authenticationFailed __attribute__ ((aligned (4)));
    volatile int32_t canceledAuthentication __attribute__ ((aligned (4)));
    volatile int32_t needsAuthentication __attribute__ ((aligned (4)));
    volatile int32_t failedDownload __attribute__ ((aligned (4)));
} BDSKSharedGroupFlags;    

// private protocols for inter-thread messaging
@protocol BDSKSharedGroupServerLocalThread <BDSKAsyncDOServerThread>

- (oneway void)retrievePublications;

@end

@protocol BDSKSharedGroupServerMainThread <BDSKAsyncDOServerMainThread>

- (oneway void)unarchivePublications:(bycopy NSData *)archive;
- (oneway void)unarchiveMacros:(bycopy NSData *)archive;
- (int)runPasswordPrompt;
- (int)runAuthenticationFailedAlert;

@end

#pragma mark -

// private class for DO server. We have it as a separate object so we don't get a retain loop, we remove it from the thread runloop in the group's dealloc
@interface BDSKSharedGroupServer : BDSKAsynchronousDOServer <BDSKSharedGroupServerLocalThread, BDSKSharedGroupServerMainThread, BDSKClientProtocol> {
    NSNetService *service;              // service with information about the remote server (BDSKSharingServer)
    BDSKSharedGroup *group;             // the owner of the local server (BDSKSharedGroupServer)
    id remoteServer;
    BDSKSharedGroupFlags flags;         // state variables
    NSString *uniqueIdentifier;         // used by the remote server
}

+ (NSString *)supportedProtocolVersion;

- (id)initWithGroup:(BDSKSharedGroup *)aGroup andService:(NSNetService *)aService;

- (BOOL)isRetrieving;
- (BOOL)needsAuthentication;
- (BOOL)failedDownload;

// proxy object for messaging the remote server
- (id <BDSKSharingProtocol>)remoteServer;

- (void)retrievePublicationsInBackground;

@end

#pragma mark -

@implementation BDSKSharedGroup

#pragma mark Class methods

// Cached icons

static NSImage *lockedIcon = nil;
static NSImage *unlockedIcon = nil;

+ (NSImage *)icon{
    return [NSImage smallImageNamed:@"sharedFolderIcon"];
}

+ (NSImage *)lockedIcon {
    if(lockedIcon == nil){
        NSRect iconRect = NSMakeRect(0.0, 0.0, 16.0, 16.0);
        NSRect badgeRect = NSMakeRect(7.0, 0.0, 11.0, 11.0);
        NSImage *image = [[NSImage alloc] initWithSize:iconRect.size];
        NSImage *badge = [NSImage imageNamed:@"SmallLock_Locked"];
        
        [image lockFocus];
        [NSGraphicsContext saveGraphicsState];
        [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
        [[self icon] drawInRect:iconRect fromRect:iconRect operation:NSCompositeSourceOver  fraction:1.0];
        [badge drawInRect:badgeRect fromRect:iconRect operation:NSCompositeSourceOver  fraction:1.0];
        [NSGraphicsContext restoreGraphicsState];
        [image unlockFocus];
        
        lockedIcon = image;
    }
    return lockedIcon;
}

+ (NSImage *)unlockedIcon {
    if(unlockedIcon == nil){
        NSRect iconRect = NSMakeRect(0.0, 0.0, 16.0, 16.0);
        NSRect badgeRect = NSMakeRect(6.0, 0.0, 11.0, 11.0);
        NSImage *image = [[NSImage alloc] initWithSize:iconRect.size];
        NSImage *badge = [NSImage imageNamed:@"SmallLock_Unlocked"];
        
        [image lockFocus];
        [NSGraphicsContext saveGraphicsState];
        [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
        [[self icon] drawInRect:iconRect fromRect:iconRect operation:NSCompositeSourceOver  fraction:1.0];
        [badge drawInRect:badgeRect fromRect:iconRect operation:NSCompositeSourceOver  fraction:1.0];
        [NSGraphicsContext restoreGraphicsState];
        [image unlockFocus];
        
        unlockedIcon = image;
    }
    return unlockedIcon;
}

#pragma mark Init and dealloc

- (id)initWithService:(NSNetService *)aService;
{
    NSParameterAssert(aService != nil);
    if(self = [super initWithName:[aService name] count:0]){

        publications = nil;
        macroResolver = [[BDSKMacroResolver alloc] initWithOwner:self];
        needsUpdate = YES;
        
        server = [[BDSKSharedGroupServer alloc] initWithGroup:self andService:aService];
    }
    
    return self;
}

- (void)dealloc;
{
    [server stopDOServer];
    [server release];
    [publications release];
    [macroResolver release];
    [super dealloc];
}

- (id)initWithCoder:(NSCoder *)aCoder
{
    [NSException raise:BDSKUnimplementedException format:@"Instances of %@ do not conform to NSCoding", [self class]];
    return nil;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [NSException raise:BDSKUnimplementedException format:@"Instances of %@ do not conform to NSCoding", [self class]];
}

// Logging

- (NSString *)description;
{
    return [NSString stringWithFormat:@"<%@ %p>: {\n\tneeds update: %@\n\tname: %@\n }", [self class], self, (needsUpdate ? @"yes" : @"no"), name];
}

#pragma mark Accessors

- (BDSKPublicationsArray *)publications;
{
    if([self isRetrieving] == NO && ([self needsUpdate] == YES || publications == nil)){
        // let the server get the publications asynchronously
        [server retrievePublicationsInBackground]; 
        
        // use this to notify the tableview to start the progress indicators
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"succeeded"];
        [[NSNotificationCenter defaultCenter] postNotificationName:BDSKSharedGroupUpdatedNotification object:self userInfo:userInfo];
    }
    // this will likely be nil the first time
    return publications;
}

- (void)setPublications:(NSArray *)newPublications;
{
    if(newPublications != publications){
        [publications makeObjectsPerformSelector:@selector(setOwner:) withObject:nil];
        [publications release];
        publications = newPublications == nil ? nil : [[BDSKPublicationsArray alloc] initWithArray:newPublications];
        [publications makeObjectsPerformSelector:@selector(setOwner:) withObject:self];
        
        if (publications == nil)
            [macroResolver removeAllMacros];
    }
    
    [self setCount:[publications count]];
    [self setNeedsUpdate:NO];
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:(publications != nil)] forKey:@"succeeded"];
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKSharedGroupUpdatedNotification object:self userInfo:userInfo];
}


- (BDSKMacroResolver *)macroResolver { return macroResolver; }

- (NSUndoManager *)undoManager { return nil; }

- (NSURL *)fileURL { return nil; }

- (NSString *)documentInfoForKey:(NSString *)key { return nil; }

- (BOOL)isDocument { return NO; }

- (BOOL)isRetrieving { return (BOOL)[server isRetrieving]; }

- (BOOL)failedDownload { return [server failedDownload]; }

- (BOOL)needsUpdate { return needsUpdate; }

- (void)setNeedsUpdate:(BOOL)flag { needsUpdate = flag; }

// BDSKGroup overrides

- (NSImage *)icon {
    if([server needsAuthentication])
        return (publications == nil) ? [[self class] lockedIcon] : [[self class] unlockedIcon];
    else
        return [[self class] icon];
}

- (BOOL)isShared { return YES; }

- (BOOL)isExternal { return YES; }

- (BOOL)containsItem:(BibItem *)item {
    // calling [self publications] will repeatedly reschedule a retrieval, which is undesirable if the user canceled a password; containsItem is called very frequently
    NSArray *pubs = [publications retain];
    BOOL rv = [pubs containsObject:item];
    [pubs release];
    return rv;
}

- (BOOL)isEqual:(id)other { return self == other; }

- (unsigned int)hash {
    return( ((unsigned int) self >> 4) | (unsigned int) self << (32 - 4));
}

@end

#pragma mark -

@implementation BDSKSharedGroupServer

// If we introduce incompatible changes in future, bump this to avoid sharing breakage
+ (NSString *)supportedProtocolVersion { return @"0"; }

- (id)initWithGroup:(BDSKSharedGroup *)aGroup andService:(NSNetService *)aService;
{
    if (self = [super init]) {
        group = aGroup; // don't retain since it retains us
        
        service = [aService retain];
        
        // monitor changes to the TXT data
        [service setDelegate:self];
        [service startMonitoring];
        
        // set up flags
        memset(&flags, 0, sizeof(flags));
        
        // set up the authentication flag
        NSData *TXTData = [service TXTRecordData];
        if(TXTData)
            [self netService:service didUpdateTXTRecordData:TXTData];
        
        // test this to see if we've registered with the remote host
        uniqueIdentifier = nil;
    }
    return self;
}

- (void)dealloc;
{
    [service setDelegate:nil];
    [service release];
    [uniqueIdentifier release];
    [super dealloc];
}

#pragma mark Accessors

// BDSKClientProtocol
- (oneway void)setNeedsUpdate:(BOOL)flag { 
    // don't message the group during cleanup
    if([self shouldKeepRunning])
        [group setNeedsUpdate:flag]; 
}

- (BOOL)isAlive{ return YES; }

- (BOOL)isRetrieving { return flags.isRetrieving == 1; }

- (BOOL)needsAuthentication { return flags.needsAuthentication == 1; }

- (BOOL)failedDownload { return flags.failedDownload == 1; }

#pragma mark Proxies

- (id <BDSKSharingProtocol>)remoteServer;
{
    if (remoteServer != nil)
        return remoteServer;
    
    NSConnection *conn = nil;
    id proxy = nil;
    
    NSPort *sendPort = [[NSSocketPortNameServer sharedInstance] portForName:[service name] host:[service hostName]];
    
    if(sendPort == nil)
        @throw [NSString stringWithFormat:@"%@: unable to look up server %@", NSStringFromSelector(_cmd), [service hostName]];
    @try {
        conn = [NSConnection connectionWithReceivePort:nil sendPort:sendPort];
        [conn setRequestTimeout:60];
        // ask for password
        [conn setDelegate:self];
        proxy = [conn rootProxy];
    }
    @catch (id exception) {
        
        [conn setDelegate:nil];
        [conn setRootObject:nil];
        [conn invalidate];
        conn = nil;
        proxy = nil;

        // flag authentication failures so we get a prompt the next time around (in case our password was wrong)
        // we also get this if the user canceled, since an empty data will be returned
        if([exception respondsToSelector:@selector(name)] && [[exception name] isEqual:NSFailedAuthenticationException]){
            
            // if the user didn't cancel, set an auth failure flag and show an alert
            if(flags.canceledAuthentication == 0){
                OSAtomicCompareAndSwap32Barrier(0, 1, (int32_t *)&flags.authenticationFailed);
                // don't show the alert when we couldn't authenticate when cleaning up
                if([self shouldKeepRunning]){
                    [[self serverOnMainThread] runAuthenticationFailedAlert];
                }
            }
            
        } else {
            @throw [NSString stringWithFormat:@"%@: exception \"%@\" while connecting to remote server %@", NSStringFromSelector(_cmd), exception, [service hostName]];
        }
    }

    if (proxy != nil) {
        [proxy setProtocolForProxy:@protocol(BDSKSharingProtocol)];
        
        if(uniqueIdentifier == nil){
            // use uniqueIdentifier as the notification identifier for this host on the other end
            uniqueIdentifier = [[[NSProcessInfo processInfo] globallyUniqueString] copy];
            @try {
                NSProtocolChecker *checker = [NSProtocolChecker protocolCheckerWithTarget:self protocol:@protocol(BDSKClientProtocol)];
                [proxy registerClient:checker forIdentifier:uniqueIdentifier version:[BDSKSharedGroupServer supportedProtocolVersion]];
            }
            @catch(id exception) {
                [uniqueIdentifier release];
                uniqueIdentifier = nil;
                NSLog(@"%@: unable to register with remote server %@", [self class], [service hostName]);
                // don't throw; this isn't critical
            }
        }
    }
    
    remoteServer = [proxy retain];
    return remoteServer;
}

#pragma mark Authentication

- (int)runPasswordPrompt;
{
    NSAssert([NSThread inMainThread] == 1, @"password controller must be run from the main thread");
    BDSKPasswordController *pwc = [[BDSKPasswordController alloc] init];
    int rv = [pwc runModalForKeychainServiceName:[BDSKPasswordController keychainServiceNameWithComputerName:[service name]] message:[NSString stringWithFormat:NSLocalizedString(@"Enter password for %@", @"Prompt for Password dialog"), [service name]]];
    [pwc close];
    [pwc release];
    return rv;
}

- (int)runAuthenticationFailedAlert;
{
    NSAssert([NSThread inMainThread] == 1, @"runAuthenticationFailedAlert must be run from the main thread");
    return NSRunAlertPanel(NSLocalizedString(@"Authentication Failed", @"Message in alert dialog when authentication failed"), [NSString stringWithFormat:NSLocalizedString(@"Incorrect password for BibDesk Sharing on server %@.  Reselect to try again.", @"Informative text in alert dialog"), [service name]], nil, nil, nil);
}

// this can be called from any thread
- (NSData *)authenticationDataForComponents:(NSArray *)components;
{
    if(flags.needsAuthentication == 0)
        return [[NSData data] sha1Signature];
    
    NSData *password = nil;
    OSAtomicCompareAndSwap32Barrier(1, 0, (int32_t *)&flags.canceledAuthentication);
    
    int rv = 1;
    if(flags.authenticationFailed == 0)
        password = [BDSKPasswordController passwordHashedForKeychainServiceName:[BDSKPasswordController keychainServiceNameWithComputerName:[service name]]];
    
    if(password == nil && [self shouldKeepRunning]){   
        
        // run the prompt on the main thread
        rv = [[self serverOnMainThread] runPasswordPrompt];
        
        // retry from the keychain
        if (rv == BDSKPasswordReturn){
            password = [BDSKPasswordController passwordHashedForKeychainServiceName:[BDSKPasswordController keychainServiceNameWithComputerName:[service name]]];
            // assume we succeeded; the exception handler for the connection will change it back if we fail again
            OSAtomicCompareAndSwap32Barrier(1, 0, (int32_t *)&flags.authenticationFailed);
        }else{
            OSAtomicCompareAndSwap32Barrier(0, 1, (int32_t *)&flags.canceledAuthentication);
        }
    }
    
    // doc says we're required to return empty NSData instead of nil
    return password ? password : [NSData data];
}

// monitor the TXT record in case the server changes password requirements
- (void)netService:(NSNetService *)sender didUpdateTXTRecordData:(NSData *)data;
{
    OBASSERT(sender == service);
    OBASSERT(data != nil);
    if(data){
        NSDictionary *dict = [NSNetService dictionaryFromTXTRecordData:data];
        int32_t val = [[NSString stringWithData:[dict objectForKey:BDSKTXTAuthenticateKey] encoding:NSUTF8StringEncoding] intValue];
        int32_t oldVal = flags.needsAuthentication;
        OSAtomicCompareAndSwap32Barrier(oldVal, val, (int32_t *)&flags.needsAuthentication);
    }
}

#pragma mark ServerThread

- (Protocol *)protocolForServerThread { return @protocol(BDSKSharedGroupServerLocalThread); }
- (Protocol *)protocolForMainThread { return @protocol(BDSKSharedGroupServerMainThread); }

- (oneway void)unarchivePublications:(bycopy NSData *)archive;
{
    // retain as the autoreleasepool of our caller will be released as we're oneway
    [archive retain];
    
    NSAssert([NSThread inMainThread] == 1, @"publications must be set from the main thread");
    
    [BDSKComplexString setMacroResolverForUnarchiving:[group macroResolver]];
    
    NSArray *publications = archive ? [NSKeyedUnarchiver unarchiveObjectWithData:archive] : nil;
    [archive release];
    
    [BDSKComplexString setMacroResolverForUnarchiving:nil];
    
    [group setPublications:publications];
}

- (oneway void)unarchiveMacros:(bycopy NSData *)archive;
{
    // retain as the autoreleasepool of our caller will be released as we're oneway
    [archive retain];
    
    NSAssert([NSThread inMainThread] == 1, @"macros must be set from the main thread");
    
    NSDictionary *macros = archive ? [NSKeyedUnarchiver unarchiveObjectWithData:archive] : nil;
    [archive release];
    
    NSEnumerator *macroEnum = [macros keyEnumerator];
    NSString *macro;
    while(macro = [macroEnum nextObject])
        [[group macroResolver] setMacroDefinition:[macros objectForKey:macro] forMacro:macro];
}

- (void)retrievePublicationsInBackground{ [[self serverOnServerThread] retrievePublications]; }

- (oneway void)retrievePublications;
{
    // set so we don't try calling this multiple times
    OSAtomicCompareAndSwap32Barrier(0, 1, (int32_t *)&flags.isRetrieving);
    OSAtomicCompareAndSwap32Barrier(1, 0, (int32_t *)&flags.failedDownload);
    
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    
    @try {
        NSData *archive = nil;
        NSData *macroArchive = nil;
        NSData *proxyData = [[self remoteServer] archivedSnapshotOfPublications];
        
        if([proxyData length] != 0){
            if([proxyData mightBeCompressed])
                proxyData = [proxyData decompressedData];
            NSString *errorString = nil;
            NSDictionary *dictionary = [NSPropertyListSerialization propertyListFromData:proxyData mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:&errorString];
            if(errorString != nil){
                NSString *errorStr = [NSString stringWithFormat:@"Error reading shared data: %@", errorString];
                [errorString release];
                @throw errorStr;
            } else {
                archive = [dictionary objectForKey:BDSKSharedArchivedDataKey];
                macroArchive = [dictionary objectForKey:BDSKSharedArchivedMacroDataKey];
            }
        }
        OSAtomicCompareAndSwap32Barrier(1, 0, (int32_t *)&flags.isRetrieving);
        // use the main thread; this avoids an extra (un)archiving between threads and it ends up posting notifications for UI updates
        if(macroArchive)
            [[self serverOnMainThread] unarchiveMacros:macroArchive];
        [[self serverOnMainThread] unarchivePublications:archive];
    }
    @catch(id exception){
        NSLog(@"%@: discarding exception \"%@\" while retrieving publications", [self class], exception);
        OSAtomicCompareAndSwap32Barrier(1, 0, (int32_t *)&flags.isRetrieving);
        OSAtomicCompareAndSwap32Barrier(0, 1, (int32_t *)&flags.failedDownload);
        
        // this posts a notification that the publications of the group changed, forcing a redisplay of the table cell
        [group performSelectorOnMainThread:@selector(setPublications:) withObject:nil waitUntilDone:NO];
    }
    @finally{
        [pool release];
    }
}

- (oneway void)cleanup;
{
    // clean up our remote end
    if (uniqueIdentifier != nil){
        @try {
            [remoteServer removeClientForIdentifier:uniqueIdentifier];
        }
        @catch(id exception) {
            NSLog(@"%@ ignoring exception \"%@\" raised during cleanup", [self class], exception);
        }
    }
    if (remoteServer != nil){
        NSConnection *conn = [remoteServer connectionForProxy];
        [conn setDelegate:nil];
        [conn setRootObject:nil];
        [[conn receivePort] invalidate];
        [conn invalidate];
        [remoteServer release];
        remoteServer = nil;
    }
    
    [super cleanup];
}

- (oneway void)invalidate
{
    // set this to nil so we won't try to get back to the remote server
    [uniqueIdentifier release];
    uniqueIdentifier = nil;
}

@end
