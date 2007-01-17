//
//  BDSKScriptGroup.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 10/19/06.
/*
 This software is Copyright (c) 2006,2007
 Christiaan Hofman. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

 - Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

 - Neither the name of Christiaan Hofman nor the names of any
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

#import "BDSKScriptGroup.h"
#import "BDSKOwnerProtocol.h"
#import "BDSKShellTask.h"
#import "KFAppleScriptHandlerAdditionsCore.h"
#import "KFASHandlerAdditions-TypeTranslation.h"
#import "BibTeXParser.h"
#import "BDSKStringParser.h"
#import "NSString_BDSKExtensions.h"
#import "NSImage+Toolbox.h"
#import "BibAppController.h"
#import "NSError_BDSKExtensions.h"
#import "NSFileManager_BDSKExtensions.h"
#import "NSScanner_BDSKExtensions.h"
#import <OmniFoundation/OFMessageQueue.h>
#import "BibItem.h"
#import "BDSKPublicationsArray.h"
#import "BDSKMacroResolver.h"

#define APPLESCRIPT_HANDLER_NAME @"main"

static OFMessageQueue *messageQueue = nil;

@implementation BDSKScriptGroup

+ (void)initialize
{
    if (nil == messageQueue) {
        messageQueue = [[OFMessageQueue alloc] init];
        // use a small pool of threads for running NSTasks
        [messageQueue startBackgroundProcessors:2];
        [messageQueue setSchedulesBasedOnPriority:NO];
    }
}

- (id)initWithScriptPath:(NSString *)path scriptArguments:(NSString *)arguments scriptType:(int)type;
{
    self = [self initWithName:nil scriptPath:path scriptArguments:arguments scriptType:type];
    return self;
}

- (id)initWithName:(NSString *)aName scriptPath:(NSString *)path scriptArguments:(NSString *)arguments scriptType:(int)type;
{
    NSParameterAssert(path != nil);
    if (aName == nil)
        aName = [[path lastPathComponent] stringByDeletingPathExtension];
    if(self = [super initWithName:aName count:0]){
        publications = nil;
        macroResolver = [[BDSKMacroResolver alloc] initWithOwner:self];
        scriptPath = [path retain];
        scriptArguments = [arguments retain];
        argsArray = nil;
        scriptType = type;
        failedDownload = NO;
        
        workingDirPath = [[[NSApp delegate] temporaryFilePath:nil createDirectory:YES] retain];
        
        OFSimpleLockInit(&processingLock);
        OFSimpleLockInit(&currentTaskLock);
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:NSApplicationWillTerminateNotification object:nil];
    }
    return self;
}

- (id)initWithDictionary:(NSDictionary *)groupDict {
    NSString *aName = [[groupDict objectForKey:@"group name"] stringByUnescapingGroupPlistEntities];
    NSString *aPath = [[groupDict objectForKey:@"script path"] stringByUnescapingGroupPlistEntities];
    NSString *anArguments = [[groupDict objectForKey:@"script arguments"] stringByUnescapingGroupPlistEntities];
    int aType = [[groupDict objectForKey:@"script type"] intValue];
    self = [self initWithName:aName scriptPath:aPath scriptArguments:anArguments scriptType:aType];
    return self;
}

- (NSDictionary *)dictionaryValue {
    NSString *aName = [[self stringValue] stringByEscapingGroupPlistEntities];
    NSString *aPath = [[self scriptPath] stringByEscapingGroupPlistEntities];
    NSString *anArgs = [[self scriptArguments] stringByEscapingGroupPlistEntities];
    NSNumber *aType = [NSNumber numberWithInt:[self scriptType]];
    return [NSDictionary dictionaryWithObjectsAndKeys:aName, @"group name", aPath, @"script path", anArgs, @"script arguments", aType, @"script type", nil];
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

- (void)dealloc;
{
    // don't release currentTask; it's managed in the thread
    [[NSFileManager defaultManager] deleteObjectAtFileURL:[NSURL fileURLWithPath:workingDirPath] error:NULL];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self terminate];
    OFSimpleLockFree(&processingLock);
    OFSimpleLockFree(&currentTaskLock);
    [publications makeObjectsPerformSelector:@selector(setOwner:) withObject:nil];
    [scriptPath release];
    [scriptArguments release];
    [argsArray release];
    [publications release];
    [macroResolver release];
    [workingDirPath release];
    [stdoutData release];
    [super dealloc];
}

- (BOOL)isEqual:(id)other { return self == other; }

- (unsigned int)hash {
    return( ((unsigned int) self >> 4) | (unsigned int) self << (32 - 4));
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"<%@ %p>: {\n\t\tname: %@\n\tscript path: %@\n }", [self class], self, name, scriptPath];
}

#pragma mark Running the script

- (void)startRunningScript;
{
    BOOL isDir = NO;
    NSString *standardizedPath = [scriptPath stringByStandardizingPath];
    
    if([[NSFileManager defaultManager] fileExistsAtPath:standardizedPath isDirectory:&isDir] == NO || isDir){
        NSError *error = [NSError mutableLocalErrorWithCode:kBDSKFileNotFound localizedDescription:nil];
        if (isDir)
            [error setValue:NSLocalizedString(@"Script path points to a directory instead of a file", @"Error description") forKey:NSLocalizedDescriptionKey];
        else
            [error setValue:NSLocalizedString(@"The script path points to a file that does not exist", @"Error description") forKey:NSLocalizedDescriptionKey];
        [error setValue:standardizedPath forKey:NSFilePathErrorKey];
        [self scriptDidFailWithError:error];
    } else if (scriptType == BDSKShellScriptType) {
        NSError *error = nil;
        @try{
            if (argsArray == nil)
                argsArray = [[scriptArguments shellScriptArgumentsArray] retain];
        }
        @catch (id exception) {
            error = [NSError mutableLocalErrorWithCode:kBDSKAppleScriptError localizedDescription:NSLocalizedString(@"Error Parsing Arguments", @"Error description")];
            [error setValue:[exception reason] forKey:NSLocalizedRecoverySuggestionErrorKey];
        }
        if (error) {
            [self scriptDidFailWithError:error];
        } else {
            [messageQueue queueSelector:@selector(runShellScriptAtPath:withArguments:) forObject:self withObject:standardizedPath withObject:argsArray];
            isRetrieving = YES;
        }
    } else if (scriptType == BDSKAppleScriptType) {
        // NSAppleScript can only run on the main thread
        NSString *outputString = nil;
        NSError *error = nil;
        NSDictionary *errorInfo = nil;
        NSAppleScript *script = [[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:standardizedPath] error:&errorInfo];
        if (errorInfo) {
            error = [NSError mutableLocalErrorWithCode:kBDSKAppleScriptError localizedDescription:NSLocalizedString(@"Unable to Create AppleScript", @"Error description")];
            [error setValue:[errorInfo objectForKey:NSAppleScriptErrorMessage] forKey:NSLocalizedRecoverySuggestionErrorKey];
        } else {
            @try{
                if (argsArray == nil)
                    argsArray = [[scriptArguments appleScriptArgumentsArray] retain];
                if ([argsArray count])
                    outputString = [script executeHandler:APPLESCRIPT_HANDLER_NAME withParametersFromArray:argsArray];
                else 
                    outputString = [script executeHandler:APPLESCRIPT_HANDLER_NAME];
            }
            @catch (id exception){
                // if there are no arguments we try to run the whole script
                if ([argsArray count] == 0) {
                    errorInfo = nil;
                    outputString = [[script executeAndReturnError:&errorInfo] objCObjectValue];
                    if (errorInfo) {
                        error = [NSError mutableLocalErrorWithCode:kBDSKAppleScriptError localizedDescription:NSLocalizedString(@"Error Executing AppleScript", @"Error description")];
                        [error setValue:[errorInfo objectForKey:NSAppleScriptErrorMessage] forKey:NSLocalizedRecoverySuggestionErrorKey];
                    }
                } else {
                    error = [NSError mutableLocalErrorWithCode:kBDSKAppleScriptError localizedDescription:NSLocalizedString(@"Error Executing AppleScript", @"Error description")];
                    [error setValue:[exception reason] forKey:NSLocalizedRecoverySuggestionErrorKey];
                }
            }
            [script release];
        }
        if (error || nil == outputString || NO == [outputString isKindOfClass:[NSString class]]) {
            if (error == nil)
                error = [NSError mutableLocalErrorWithCode:kBDSKUnknownError localizedDescription:NSLocalizedString(@"Script Did Not Return Anything", @"Error description")];
            [self scriptDidFailWithError:error];
        } else {
            [self scriptDidFinishWithResult:outputString];
        }
    }
}

- (void)scriptDidFinishWithResult:(NSString *)outputString;
{
    isRetrieving = NO;
    failedDownload = NO;
    NSError *error = nil;

    NSArray *pubs = nil;
    int type = [outputString contentStringType];
    if (type == BDSKNoKeyBibTeXStringType) {
        outputString = [outputString stringWithPhoneyCiteKeys:@"FixMe"];
        type = BDSKBibTeXStringType;
    }
    BOOL isPartialData = NO;

    if (type == BDSKBibTeXStringType) {
        NSMutableString *frontMatter = [NSMutableString string];
        pubs = [BibTeXParser itemsFromData:[outputString dataUsingEncoding:NSUTF8StringEncoding] frontMatter:frontMatter filePath:@"" document:self encoding:NSUTF8StringEncoding isPartialData:&isPartialData error:&error];
    } else if (type != BDSKUnknownStringType){
        pubs = [BDSKStringParser itemsFromString:outputString ofType:type error:&error];
    } else {
        error = [NSError mutableLocalErrorWithCode:kBDSKUnknownError localizedDescription:NSLocalizedString(@"Script Did Not Return BibTeX", @"Error description")];
    }
    if (pubs == nil || isPartialData) {
        failedDownload = YES;
        [NSApp presentError:error];
    }
    [self setPublications:pubs];
}

- (void)scriptDidFailWithError:(NSError *)error;
{
    isRetrieving = NO;
    failedDownload = YES;
    
    // redraw 
    [self setPublications:nil];
    [NSApp presentError:error];
}

#pragma mark Accessors

- (BDSKPublicationsArray *)publications;
{
    if([self isRetrieving] == NO && publications == nil){
        // get the publications asynchronously
        [self startRunningScript]; 
        
        // use this to notify the tableview to start the progress indicators
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"succeeded"];
        [[NSNotificationCenter defaultCenter] postNotificationName:BDSKScriptGroupUpdatedNotification object:self userInfo:userInfo];
    }
    // this posts a notification that the publications of the group changed, forcing a redisplay of the table cell
    return publications;
}

- (void)setPublications:(NSArray *)newPublications;
{
    if ([self isRetrieving])
        [self terminate];
    
    if(newPublications != publications){
        [publications makeObjectsPerformSelector:@selector(setOwner:) withObject:nil];
        [publications release];
        publications = newPublications == nil ? nil : [[BDSKPublicationsArray alloc] initWithArray:newPublications];
        [publications makeObjectsPerformSelector:@selector(setOwner:) withObject:self];
        
        if (publications == nil)
            [macroResolver removeAllMacros];
    }
    
    [self setCount:[publications count]];
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:(publications != nil)] forKey:@"succeeded"];
    [[NSNotificationCenter defaultCenter] postNotificationName:BDSKScriptGroupUpdatedNotification object:self userInfo:userInfo];
}

- (BDSKMacroResolver *)macroResolver;
{
    return macroResolver;
}

- (NSUndoManager *)undoManager { return nil; }

- (NSURL *)fileURL { return nil; }

- (NSString *)documentInfoForKey:(NSString *)key { return nil; }

- (BOOL)isDocument { return NO; }

- (NSString *)scriptPath;
{
    return scriptPath;
}

- (void)setScriptPath:(NSString *)newPath;
{
    if (newPath != scriptPath) {
		[(BDSKScriptGroup *)[[self undoManager] prepareWithInvocationTarget:self] setScriptPath:scriptPath];
        [scriptPath release];
        scriptPath = [newPath retain];
        
        [self setPublications:nil];
    }
}

- (NSString *)scriptArguments;
{
    return scriptArguments;
}

- (void)setScriptArguments:(NSString *)newArguments;
{
    if (newArguments != scriptArguments) {
		[(BDSKScriptGroup *)[[self undoManager] prepareWithInvocationTarget:self] setScriptArguments:scriptArguments];
        [scriptArguments release];
        scriptArguments = [newArguments retain];
        
        [argsArray release];
        argsArray = nil;
        
        [self setPublications:nil];
    }
}

- (int)scriptType;
{
    return scriptType;
}

- (void)setScriptType:(int)newType;
{
    if (newType != scriptType) {
		[(BDSKScriptGroup *)[[self undoManager] prepareWithInvocationTarget:self] setScriptType:scriptType];
        scriptType = newType;
        
        [argsArray release];
        argsArray = nil;
        
        [self setPublications:nil];
    }
}

// BDSKGroup overrides

- (NSImage *)icon {
    return [NSImage smallImageNamed:@"scriptFolderIcon"];
}

- (BOOL)containsItem:(BibItem *)item {
    // calling [self publications] will repeatedly reschedule a retrieval, which is undesirable if the the URL download is busy; containsItem is called very frequently
    NSArray *pubs = [publications retain];
    BOOL rv = [pubs containsObject:item];
    [pubs release];
    return rv;
}

- (BOOL)isRetrieving { return isRetrieving; }

- (BOOL)failedDownload { return failedDownload; }

- (BOOL)isScript { return YES; }

- (BOOL)isExternal { return YES; }

- (BOOL)isEditable { return YES; }

- (void)applicationWillTerminate:(NSNotification *)aNotification{
    [self terminate];
    [[NSFileManager defaultManager] deleteObjectAtFileURL:[NSURL fileURLWithPath:workingDirPath] error:NULL];
}

#pragma mark Shell task thread

// this method is called from the main thread
- (void)terminate{
    
    NSDate *referenceDate = [NSDate date];
    
    while ([self isProcessing]){
        // if the task is still running after 2 seconds, kill it; we can't sleep here, because the main thread (usually this one) may be updating the UI for a task
        if([referenceDate timeIntervalSinceNow] > -2 && OFSimpleLockTry(&currentTaskLock)){
            if([currentTask isRunning])
                [currentTask terminate];
            [currentTask release];
            currentTask = nil;
            OFSimpleUnlock(&currentTaskLock);
            break;
        } else if([referenceDate timeIntervalSinceNow] > -2.1){ // just in case this ever happens
            NSLog(@"%@ failed to lock for task %@", self, currentTask);
            [currentTask terminate];
            [currentTask release];
            currentTask = nil;
            break;
        }
    }    
}

- (BOOL)isProcessing{
	// just see if we can get the lock, otherwise we are processing
    if(OFSimpleLockTry(&processingLock)){
		OFSimpleUnlock(&processingLock);
		return NO;
	}
	return YES;
}

// this runs in the background thread
// we pass arguments because our ivars might change on the main thread
// @@ is this safe now?
- (void)runShellScriptAtPath:(NSString *)path withArguments:(NSArray *)args;
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    OFSimpleLock(&processingLock);
    
    if (nil == stdoutData)
        stdoutData = [[NSMutableData alloc] init];
    else
        [stdoutData setData:[NSData data]];
    
    NSString *outputString = nil;
    NSError *error = nil;
    NSPipe *outputPipe = [NSPipe pipe];
    NSFileHandle *outputFileHandle = [outputPipe fileHandleForReading];
    BOOL isRunning;

    OFSimpleLock(&currentTaskLock);
    currentTask = [[NSTask allocWithZone:[self zone]] init];    
    [currentTask setStandardError:[NSFileHandle fileHandleWithStandardError]];
    [currentTask setLaunchPath:path];
    [currentTask setCurrentDirectoryPath:workingDirPath];
    [currentTask setStandardOutput:outputPipe];
    if ([args count])
        [currentTask setArguments:args];
    OFSimpleUnlock(&currentTaskLock);        
    
    // ignore SIGPIPE, as it causes a crash (seems to happen if the binaries don't exist and you try writing to the pipe)
    signal(SIGPIPE, SIG_IGN);
    
    int terminationStatus = 1;
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

    @try{
        
        [nc addObserver:self selector:@selector(stdoutNowAvailable:) name:NSFileHandleReadCompletionNotification object:outputFileHandle];
        [outputFileHandle readInBackgroundAndNotify];
        
        OFSimpleLock(&currentTaskLock);
        [currentTask launch];
        isRunning = [currentTask isRunning];
        OFSimpleUnlock(&currentTaskLock);        
        
        if (isRunning) {
            
            BOOL didRunLoop;
            do {
                // Run the run loop until the task is finished, and pick up the notifications
                didRunLoop = [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
                OFSimpleLock(&currentTaskLock);
                isRunning = [currentTask isRunning];
                OFSimpleUnlock(&currentTaskLock);        
            } while (isRunning && didRunLoop);
                        
            [nc removeObserver:self name:NSFileHandleReadCompletionNotification object:outputFileHandle];
            
            // get leftover data, since the background method won't get the last read
            NSData *remainingData = [outputFileHandle availableData];
            if ([remainingData length])
                [stdoutData appendData:remainingData];

            outputString = [[NSString allocWithZone:[self zone]] initWithData:stdoutData encoding:NSUTF8StringEncoding];
            if(outputString == nil)
                outputString = [[NSString allocWithZone:[self zone]] initWithData:stdoutData encoding:[NSString defaultCStringEncoding]];
            
            OFSimpleLock(&currentTaskLock);
            terminationStatus = [currentTask terminationStatus];
            OFSimpleUnlock(&currentTaskLock);        

        } else {
            terminationStatus = 1;
            error = [NSError mutableLocalErrorWithCode:kBDSKUnknownError localizedDescription:NSLocalizedString(@"Failed to Run Script", @"Error description")];
            [error setValue:[NSString stringWithFormat:NSLocalizedString(@"Failed to launch shell script %@", @"Error description"), path] forKey:NSLocalizedRecoverySuggestionErrorKey];
        }
    }
    @catch(id exception){
        terminationStatus = 1;
        OFSimpleLock(&currentTaskLock);
        if([currentTask isRunning])
            [currentTask terminate];
        OFSimpleUnlock(&currentTaskLock);        
        
        [nc removeObserver:self name:NSFileHandleReadCompletionNotification object:outputFileHandle];

        // if the pipe failed, we catch an exception here and ignore it
        error = [NSError mutableLocalErrorWithCode:kBDSKUnknownError localizedDescription:NSLocalizedString(@"Failed to Run Script", @"Error description")];
        [error setValue:[NSString stringWithFormat:NSLocalizedString(@"Exception %@ encountered while trying to run shell script %@", @"Error description"), [exception name], path] forKey:NSLocalizedRecoverySuggestionErrorKey];
    }
    
    // reset signal handling to default behavior
    signal(SIGPIPE, SIG_DFL);
    
    OFSimpleLock(&currentTaskLock);
    [currentTask release];
    currentTask = nil;
    OFSimpleUnlock(&currentTaskLock);        
    
    if (terminationStatus != EXIT_SUCCESS || nil == outputString) {
        if(error == nil)
            error = [NSError mutableLocalErrorWithCode:kBDSKUnknownError localizedDescription:NSLocalizedString(@"Script Did Not Return Anything", @"Error description")];
        [[OFMessageQueue mainQueue] queueSelector:@selector(scriptDidFailWithError:) forObject:self withObject:error];
    } else {
        [[OFMessageQueue mainQueue] queueSelector:@selector(scriptDidFinishWithResult:) forObject:self withObject:outputString];
    }
    
    [outputString release];
    
    OFSimpleUnlock(&processingLock);
	[pool release];
}

- (void)stdoutNowAvailable:(NSNotification *)notification {
    NSData *outputData = [[notification userInfo] objectForKey:NSFileHandleNotificationDataItem];
    if ([outputData length]) {
        [stdoutData appendData:outputData];
    }
    [[notification object] readInBackgroundAndNotify];
}

@end
