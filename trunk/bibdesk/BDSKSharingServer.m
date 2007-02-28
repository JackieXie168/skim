//
//  BDSKSharingServer.m
//  Bibdesk
//
//  Created by Adam Maxwell on 04/02/06.
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

#import "BDSKSharingServer.h"
#import "BDSKSharedGroup.h"
#import "BDSKSharingBrowser.h"
#import "BDSKPasswordController.h"
#import <SystemConfiguration/SystemConfiguration.h>
#import "NSArray_BDSKExtensions.h"
#import "BibItem.h"
#import "BibDocument.h"
#import <libkern/OSAtomic.h>
#import "BDSKSharedGroup.h"
#import "BDSKAsynchronousDOServer.h"
#import "BDSKThreadSafeMutableDictionary.h"

#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>

static id sharedInstance = nil;

// TXT record keys
NSString *BDSKTXTAuthenticateKey = @"authenticate";
NSString *BDSKTXTVersionKey = @"txtvers";

NSString *BDSKSharedArchivedDataKey = @"publications_v1";
NSString *BDSKSharedArchivedMacroDataKey = @"macros_v1";

NSString *BDSKComputerNameChangedNotification = nil;
NSString *BDSKHostNameChangedNotification = nil;

static SCDynamicStoreRef dynamicStore = NULL;
static const void *retainCallBack(const void *info) { return [(id)info retain]; }
static void releaseCallBack(const void *info) { [(id)info release]; }
static CFStringRef copyDescriptionCallBack(const void *info) { return (CFStringRef)[[(id)info description] copy]; }
// convert this to an NSNotification
static void SCDynamicStoreChanged(SCDynamicStoreRef store, CFArrayRef changedKeys, void *info)
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    CFIndex cnt = CFArrayGetCount(changedKeys);
    NSString *key;
    while(cnt--){
        key = (id)CFArrayGetValueAtIndex(changedKeys, cnt);
        [[NSNotificationCenter defaultCenter] postNotificationName:key object:nil];
    }
    
    // update the text field in prefs if necessary (or that could listen for computer name changes...)
    if([NSString isEmptyString:[[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKSharingNameKey]])
        [[NSNotificationCenter defaultCenter] postNotificationName:BDSKSharingNameChangedNotification object:nil];
    [pool release];
}

// This is the computer name as set in sys prefs (sharing)
NSString *BDSKComputerName() {
    return [(id)SCDynamicStoreCopyComputerName(dynamicStore, NULL) autorelease];
}

#pragma mark -

// private protocol for inter-thread messaging
@protocol BDSKSharingServerLocalThread <BDSKAsyncDOServerThread>

- (oneway void)notifyClientsOfChange;

@end

@interface BDSKSharingDOServer : BDSKAsynchronousDOServer <BDSKSharingServerLocalThread> {
    NSConnection *connection;
    BDSKThreadSafeMutableDictionary *remoteClients;
}

+ (NSString *)requiredProtocolVersion;

- (unsigned int)numberOfConnections;
- (void)notifyClientConnectionsChanged;
- (NSArray *)copyPublicationsFromOpenDocuments;
- (NSDictionary *)copyMacrosFromOpenDocuments;

@end

#pragma mark -

@implementation BDSKSharingServer

// +load so this gets sets up regardless of whether we instantiate the server
+ (void)load;
{
    /* Ensure that computer name changes are propagated as future clients connect to a document.  Also, note that the OS will change the computer name to avoid conflicts by appending "(2)" or similar to the previous name, which is likely the most common scenario.
    */
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    if(dynamicStore == NULL){
        CFAllocatorRef alloc = CFAllocatorGetDefault();
        CFRetain(alloc); // make sure this is maintained for the life of the program
        SCDynamicStoreContext SCNSObjectContext = {
            0,                         // version
            (id)nil,                   // any NSCF type
            &retainCallBack,
            &releaseCallBack,
            &copyDescriptionCallBack
        };
        dynamicStore = SCDynamicStoreCreate(alloc, (CFStringRef)[[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleIdentifierKey], &SCDynamicStoreChanged, &SCNSObjectContext);
        CFRunLoopSourceRef rlSource = SCDynamicStoreCreateRunLoopSource(alloc, dynamicStore, 0);
        CFRunLoopAddSource(CFRunLoopGetCurrent(), rlSource, kCFRunLoopCommonModes);
        CFRelease(rlSource);
        
        CFMutableArrayRef keys = CFArrayCreateMutable(alloc, 0, &kCFTypeArrayCallBacks);
        
        // use SCDynamicStore keys as NSNotification names; don't release them
        CFStringRef key = SCDynamicStoreKeyCreateComputerName(alloc);
        CFArrayAppendValue(keys, key);
        BDSKComputerNameChangedNotification = (NSString *)key;
        
        key = SCDynamicStoreKeyCreateHostNames(alloc);
        CFArrayAppendValue(keys, key);
        BDSKHostNameChangedNotification = (NSString *)key;
        
        OBASSERT(BDSKComputerNameChangedNotification);
        OBASSERT(BDSKHostNameChangedNotification);

        if(SCDynamicStoreSetNotificationKeys(dynamicStore, keys, NULL) == FALSE)
            fprintf(stderr, "unable to register for dynamic store notifications.\n");
        CFRelease(keys);
    }
    [pool release];
}

// base name for sharing (also used for storing remote host names in keychain)
+ (NSString *)sharingName;
{
    // docs say to use computer name instead of host name http://developer.apple.com/qa/qa2001/qa1228.html
    NSString *sharingName = [[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKSharingNameKey];
    if([NSString isEmptyString:sharingName])
        sharingName = BDSKComputerName();
    return sharingName;
}

// If we introduce incompatible changes in future, bump this to avoid sharing breakage
+ (NSString *)supportedProtocolVersion { return @"0"; }

+ (id)defaultServer;
{
    if(sharedInstance == nil)
        sharedInstance = [[self alloc] init];
    return sharedInstance;
}

- (unsigned int)numberOfConnections { 
    // minor thread-safety issue here; this may be off by one
    return [server numberOfConnections]; 
}

- (void)handleQueuedDataChanged;
{
    // not the default connection here; we want to call our background thread, but only if it's running
    // add a hidden pref in case this traffic turns us into a bad network citizen; manual updates will still work
    if([server shouldKeepRunning] && [[NSUserDefaults standardUserDefaults] boolForKey:@"BDSKDisableRemoteChangeNotifications"] == 0){
        [[server serverOnServerThread] notifyClientsOfChange];
    }    
}

// we'll get these notifications on the main thread, and pass off to our secondary thread to handle; they're queued to reduce network traffic
- (void)queueDataChangedNotification:(NSNotification *)note;
{
    SEL theSEL = @selector(handleQueuedDataChanged);
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:theSEL object:nil];
    [self performSelector:theSEL withObject:nil afterDelay:5.0];
}

//  handle changes from the OS
- (void)handleComputerNameChangedNotification:(NSNotification *)note;
{
    // if we're using the computer name, restart sharing so the name propagates correctly; avoid conflicts with other users' share names
    if([NSString isEmptyString:[[OFPreferenceWrapper sharedPreferenceWrapper] objectForKey:BDSKSharingNameKey]])
        [self restartSharingIfNeeded];
}

// handle changes from prefs
- (void)handleSharingNameChangedNotification:(NSNotification *)note;
{
    [self restartSharingIfNeeded];
}

- (void)handlePasswordChangedNotification:(NSNotification *)note;
{
    [self restartSharingIfNeeded];
}

- (void)enableSharing
{
    if(netService){
        // we're already sharing
        return;
    }
    
    uint16_t chosenPort = 0;
    
    // Here, create the socket from traditional BSD socket calls
    int fdForListening;
    struct sockaddr_in serverAddress;
    socklen_t namelen = sizeof(serverAddress);
    
    if((fdForListening = socket(AF_INET, SOCK_STREAM, 0)) > 0) {
        memset(&serverAddress, 0, sizeof(serverAddress));
        serverAddress.sin_family = AF_INET;
        serverAddress.sin_addr.s_addr = htonl(INADDR_ANY);
        serverAddress.sin_port = 0; // allows the kernel to choose the port for us.
        
        if(bind(fdForListening, (struct sockaddr *)&serverAddress, sizeof(serverAddress)) < 0) {
            close(fdForListening);
            return;
        }
        
        // Find out what port number was chosen for us.
        if(getsockname(fdForListening, (struct sockaddr *)&serverAddress, &namelen) < 0) {
            close(fdForListening);
            return;
        }
        
        chosenPort = ntohs(serverAddress.sin_port);
    }
    
    // lazily instantiate the NSNetService object that will advertise on our behalf
    netService = [[NSNetService alloc] initWithDomain:@"" type:BDSKNetServiceDomain name:[BDSKSharingServer sharingName] port:chosenPort];
    [netService setDelegate:self];
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:4];
    [dictionary setObject:[BDSKSharingServer supportedProtocolVersion] forKey:BDSKTXTVersionKey];
    [dictionary setObject:[[OFPreferenceWrapper sharedPreferenceWrapper] stringForKey:BDSKSharingRequiresPasswordKey] forKey:BDSKTXTAuthenticateKey];
    [netService setTXTRecordData:[NSNetService dataFromTXTRecordDictionary:dictionary]];
    
    server = [[BDSKSharingDOServer alloc] init];
    
    // our DO server will also use Bonjour, but this gives us a browseable name
    [netService publish];
    
    // register for notifications
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    [nc addObserver:self
           selector:@selector(handleComputerNameChangedNotification:)
               name:BDSKComputerNameChangedNotification
             object:nil];
    
    [nc addObserver:self
           selector:@selector(handlePasswordChangedNotification:)
               name:BDSKSharingPasswordChangedNotification
             object:nil];
    
    [nc addObserver:self
           selector:@selector(queueDataChangedNotification:)
               name:BDSKDocumentControllerAddDocumentNotification
             object:nil];

    [nc addObserver:self
           selector:@selector(queueDataChangedNotification:)
               name:BDSKDocumentControllerRemoveDocumentNotification
             object:nil];                     
                 
    [nc addObserver:self
           selector:@selector(queueDataChangedNotification:)
               name:BDSKDocAddItemNotification
             object:nil];

    [nc addObserver:self
           selector:@selector(queueDataChangedNotification:)
               name:BDSKDocDelItemNotification
             object:nil];
    
    [nc addObserver:self
           selector:@selector(handleApplicationWillTerminate:)
               name:NSApplicationWillTerminateNotification
             object:nil];
}

- (void)disableSharing
{
    if(netService != nil && [server shouldKeepRunning]){
        [netService stop];
        [netService release];
        netService = nil;
        
        [server stopDOServer];
        [server release];
        server = nil;
        
        // unregister for notifications
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        
        [nc removeObserver:self name:BDSKComputerNameChangedNotification object:nil];
        [nc removeObserver:self name:BDSKSharingPasswordChangedNotification object:nil];
        [nc removeObserver:self name:BDSKDocumentControllerAddDocumentNotification object:nil];
        [nc removeObserver:self name:BDSKDocumentControllerRemoveDocumentNotification object:nil];                                                       
        [nc removeObserver:self name:BDSKDocAddItemNotification object:nil];
        [nc removeObserver:self name:BDSKDocDelItemNotification object:nil];
        [nc removeObserver:self name:NSApplicationWillTerminateNotification object:nil];
    }
}

- (void)restartSharingIfNeeded;
{
    if([[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKShouldShareFilesKey]){
        [self disableSharing];
        
        // give the server a moment to stop
        [self performSelector:@selector(enableSharing) withObject:nil afterDelay:3.0];
    }
}

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict
{
    int err = [[errorDict objectForKey:NSNetServicesErrorCode] intValue];
    NSString *errorMessage = nil;
    switch(err){
        case NSNetServicesUnknownError:
            errorMessage = NSLocalizedString(@"Unknown net services error", @"Error description");
            break;
        case NSNetServicesCollisionError:
            errorMessage = NSLocalizedString(@"Net services collision error", @"Error description");
            break;
        case NSNetServicesNotFoundError:
            errorMessage = NSLocalizedString(@"Net services not found error", @"Error description");
            break;
        case NSNetServicesActivityInProgress:
            errorMessage = NSLocalizedString(@"Net services reports activity in progress", @"Error description");
            break;
        case NSNetServicesBadArgumentError:
            errorMessage = NSLocalizedString(@"Net services bad argument error", @"Error description");
            break;
        case NSNetServicesCancelledError:
            errorMessage = NSLocalizedString(@"Cancelled net service", @"Error description");
            break;
        case NSNetServicesInvalidError:
            errorMessage = NSLocalizedString(@"Net services invalid error", @"Error description");
            break;
        case NSNetServicesTimeoutError:
            errorMessage = NSLocalizedString(@"Net services timeout error", @"Error description");
            break;
        default:
            errorMessage = NSLocalizedString(@"Unrecognized error code from net services", @"Error description");
            break;
    }
    
    NSLog(@"-[%@ %@] reports \"%@\"", [self class], NSStringFromSelector(_cmd), errorMessage);
    
    NSString *errorDescription = NSLocalizedString(@"Unable to Share Bibliographies Using Bonjour", @"Error description");
    NSString *recoverySuggestion = NSLocalizedString(@"You may wish to disable and re-enable sharing in BibDesk's preferences to see if the error persists.", @"Error informative text");
    NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:err userInfo:[NSDictionary dictionaryWithObjectsAndKeys:errorDescription, NSLocalizedDescriptionKey, errorMessage, NSLocalizedFailureReasonErrorKey, recoverySuggestion, NSLocalizedRecoverySuggestionErrorKey, nil]];

    [self disableSharing];
    
    // show the error in a modal dialog
    [NSApp presentError:error];
}

- (void)netServiceDidStop:(NSNetService *)sender
{
    // We'll need to release the NSNetService sending this, since we want to recreate it in sync with the socket at the other end. Since there's only the one NSNetService in this server, we can just release it.
    [netService release];
    netService = nil;
}

- (void)handleApplicationWillTerminate:(NSNotification *)note;
{
    [self disableSharing];
}

@end

@implementation BDSKSharingDOServer

// This is the minimal version for the client that we require
// If we introduce incompatible changes in future, bump this to avoid sharing breakage
+ (NSString *)requiredProtocolVersion { return @"0"; }

- (id)init
{
    if(self = [super init]){
        remoteClients = [[BDSKThreadSafeMutableDictionary alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [remoteClients release];
    [super dealloc];
}

- (unsigned int)numberOfConnections { 
    return [remoteClients count]; 
}

- (void)notifyClientConnectionsChanged;
{
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKClientConnectionsChangedNotification object:nil];
}

- (NSArray *)copyPublicationsFromOpenDocuments
{
    NSMutableSet *set = nil;
    NSMutableArray *pubs = [[NSMutableArray alloc] initWithCapacity:100];

    // this is only useful if everyone else uses the mutex, though...
    @synchronized([NSDocumentController sharedDocumentController]){
        NSEnumerator *docE = [[[[[NSDocumentController sharedDocumentController] documents] copy] autorelease] objectEnumerator];
        set = (NSMutableSet *)CFSetCreateMutable(CFAllocatorGetDefault(), 0, &BDSKBibItemEqualityCallBacks);
        id document = nil;
        while(document = [docE nextObject]){
            [document getCopyOfPublicationsOnMainThread:pubs];
            [set addObjectsFromArray:pubs];
            [pubs removeAllObjects];
        }
        [pubs removeAllObjects];
    }
    [pubs addObjectsFromSet:set];
    [set release];
    return pubs;
}

- (NSDictionary *)copyMacrosFromOpenDocuments
{
    NSMutableDictionary *macros = [[NSMutableDictionary alloc] initWithCapacity:10];

    // this is only useful if everyone else uses the mutex, though...
    @synchronized([NSDocumentController sharedDocumentController]){
        NSArray *docs = [[[NSDocumentController sharedDocumentController] documents] copy];
        [docs makeObjectsPerformSelector:@selector(getCopyOfMacrosOnMainThread:) withObject:macros];
        [docs release];
    }
    return macros;
}

- (bycopy NSData *)archivedSnapshotOfPublications
{
    NSArray *pubs = [self copyPublicationsFromOpenDocuments];
    NSDictionary *macros = [self copyMacrosFromOpenDocuments];
    NSData *dataToSend = [NSKeyedArchiver archivedDataWithRootObject:pubs];
    NSData *macroDataToSend = [NSKeyedArchiver archivedDataWithRootObject:macros];
    [pubs release];
    [macros release];
    
    if(dataToSend != nil && macroDataToSend != nil){
        NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:dataToSend, BDSKSharedArchivedDataKey, macroDataToSend, BDSKSharedArchivedMacroDataKey, nil];
        NSString *errorString = nil;
        dataToSend = [NSPropertyListSerialization dataFromPropertyList:dictionary format:NSPropertyListBinaryFormat_v1_0 errorDescription:&errorString];
        if(errorString != nil){
            NSLog(@"Error serializing publications for sharing: %@", errorString);
            [errorString release];
        } else {
            // Omni's bzip2 method caused a hang when I tried it, but -compressedData produced a 50% size decrease
            @try{ dataToSend = [dataToSend compressedData]; }
            @catch(id exception){ NSLog(@"Ignoring exception %@ raised while compressing data to share.", exception); }
        }
    }
    return dataToSend;
}

#pragma mark -
#pragma mark Server Thread

- (Protocol *)protocolForServerThread { return @protocol(BDSKSharingServerLocalThread); }

- (BOOL)connection:(NSConnection *)parentConnection shouldMakeNewConnection:(NSConnection *)newConnection
{
    // set the child connection's delegate so we get authentication messages
    // this hidden pref will be zero by default, but we'll add a limit here just in case it's needed
    static unsigned int maxConnections = 0;
    if(maxConnections == 0)
        maxConnections = MAX(20, [[NSUserDefaults standardUserDefaults] integerForKey:@"BDSKSharingServerMaxConnections"]);
    
    BOOL allowConnection = [remoteClients count] < maxConnections;
    if(allowConnection){
        [newConnection setDelegate:self];
    } else {
        NSLog(@"*** WARNING *** Maximum number of sharing clients (%d) exceeded.", maxConnections);
        NSLog(@"Use `defaults write %@ BDSKSharingServerMaxConnections N` to change the limit to N.", [[NSBundle mainBundle] bundleIdentifier]);
    }
    return allowConnection;
}

- (BOOL)authenticateComponents:(NSArray *)components withData:(NSData *)authenticationData
{
    BOOL status = YES;
    if([[OFPreferenceWrapper sharedPreferenceWrapper] boolForKey:BDSKSharingRequiresPasswordKey]){
        NSData *myPasswordHashed = [[BDSKPasswordController sharingPasswordForCurrentUserUnhashed] sha1Signature];
        status = [authenticationData isEqual:myPasswordHashed];
    }
    return status;
}

- (void)serverDidSetup
{
    // setup our DO server that will handle requests for publications and passwords
    @try {
        NSPort *receivePort = [NSSocketPort port];
        if([[NSSocketPortNameServer sharedInstance] registerPort:receivePort name:[BDSKSharingServer sharingName]] == NO)
            @throw [NSString stringWithFormat:@"Unable to register port %@ and name %@", receivePort, [BDSKSharingServer sharingName]];
        connection = [[NSConnection alloc] initWithReceivePort:receivePort sendPort:nil];
        NSProtocolChecker *checker = [NSProtocolChecker protocolCheckerWithTarget:self protocol:@protocol(BDSKSharingProtocol)];
        [connection setRootObject:checker];
        
        // so we get connection:shouldMakeNewConnection: messages
        [connection setDelegate:self];
                    
    }
    @catch(id exception) {
        [self stopDOServer];
    }
}

- (oneway void)cleanup
{
    NSEnumerator *e = [remoteClients keyEnumerator];
    id proxyObject;
    NSString *key;
    
    while(key = [e nextObject]){
        proxyObject = [[remoteClients objectForKey:key] objectForKey:@"object"];
        @try {
            [proxyObject invalidate];
        }
        @catch (id exception) {
            NSLog(@"%@: ignoring exception \"%@\" raised while invalidating client %@", [self class], exception, proxyObject);
        }
        [[proxyObject connectionForProxy] invalidate];
    }
    [remoteClients removeAllObjects];
    [self performSelectorOnMainThread:@selector(notifyClientConnectionsChanged) withObject:nil waitUntilDone:NO];
    
    NSPort *port = [[NSSocketPortNameServer sharedInstance] portForName:[BDSKSharingServer sharingName]];
    [[NSSocketPortNameServer sharedInstance] removePortForName:[BDSKSharingServer sharingName]];
    [port invalidate];
    [connection setDelegate:nil];
    [connection setRootObject:nil];
    [connection invalidate];
    [connection release];
    connection = nil;
    
    [super cleanup];
}

- (oneway void)registerClient:(byref id)clientObject forIdentifier:(bycopy NSString *)identifier version:(bycopy NSString *)version;
{
    NSParameterAssert(clientObject != nil && identifier != nil && version != nil);
    
    // we don't register clients that have a version we don't support
    if([version numericCompare:[BDSKSharingDOServer requiredProtocolVersion]] == NSOrderedAscending)
        return;
    
    [clientObject setProtocolForProxy:@protocol(BDSKClientProtocol)];
    NSDictionary *clientInfo = [NSDictionary dictionaryWithObjectsAndKeys:clientObject, @"object", version, @"version", nil];
    [remoteClients setObject:clientInfo forKey:identifier];
    [self performSelectorOnMainThread:@selector(notifyClientConnectionsChanged) withObject:nil waitUntilDone:NO];
}

- (oneway void)removeClientForIdentifier:(bycopy NSString *)identifier;
{
    NSParameterAssert(identifier != nil);
    id proxyObject = [[remoteClients objectForKey:identifier] objectForKey:@"object"];
    [[proxyObject connectionForProxy] invalidate];
    [remoteClients removeObjectForKey:identifier];
    [self performSelectorOnMainThread:@selector(notifyClientConnectionsChanged) withObject:nil waitUntilDone:NO];
}

- (oneway void)notifyClientsOfChange;
{
    // here is where we notify other hosts that something changed
    NSEnumerator *e = [remoteClients keyEnumerator];
    id proxyObject;
    NSString *key;
    
    while(key = [e nextObject]){
        
        proxyObject = [[remoteClients objectForKey:key] objectForKey:@"object"];
        
        @try {
            [proxyObject setNeedsUpdate:YES];
        }
        @catch (id exception) {
            NSLog(@"server: \"%@\" trying to reach host %@", exception, proxyObject);
            // since it's not accessible, remove it from future notifications (we know it has this key)
            [self removeClientForIdentifier:key];
        }
    }
}

@end