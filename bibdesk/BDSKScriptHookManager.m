//
//  BDSKScriptHookManager.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 19/10/05.
/*
 This software is Copyright (c) 2005,2006
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

#import "BDSKScriptHookManager.h"
#import "BibDocument.h"
#import "BibPrefController.h"
#import <OmniFoundation/NSString-OFExtensions.h>

#define MAX_RUNNING_SCRIPT_HOOKS	100

NSString *BDSKChangeFieldScriptHookName = @"Change Field";
NSString *BDSKCloseEditorWindowScriptHookName = @"Close Editor Window";
NSString *BDSKWillAutoFileScriptHookName = @"Will Auto File";
NSString *BDSKDidAutoFileScriptHookName = @"Did Auto File";
NSString *BDSKWillGenerateCiteKeyScriptHookName = @"Will Generate Cite Key";
NSString *BDSKDidGenerateCiteKeyScriptHookName = @"Did Generate Cite Key";
NSString *BDSKSaveDocumentScriptHookName = @"Save Document";

static BDSKScriptHookManager *sharedManager = nil;
static NSArray *scriptHookNames = nil;

@implementation BDSKScriptHookManager

+ (BDSKScriptHookManager *)sharedManager {
	if (sharedManager == nil) {
		sharedManager = [[BDSKScriptHookManager alloc] init];
	}
	return sharedManager;
}

+ (NSArray *)scriptHookNames {
    if (scriptHookNames == nil) {
		scriptHookNames = [[NSArray alloc] initWithObjects:BDSKChangeFieldScriptHookName, 
														   BDSKCloseEditorWindowScriptHookName, 
														   BDSKWillAutoFileScriptHookName, 
														   BDSKDidAutoFileScriptHookName, 
														   BDSKWillGenerateCiteKeyScriptHookName, 
														   BDSKDidGenerateCiteKeyScriptHookName, 
														   BDSKSaveDocumentScriptHookName, nil];
    }
    return scriptHookNames;
}

- (id)init {
    if (sharedManager != nil)
		[NSException raise:NSInternalInconsistencyException format:@"attempt to instantiate a second %@", [self class]];
	
	if (self = [super init]) {
		scriptHooks = [[NSMutableDictionary alloc] initWithCapacity:3];
	}
	return self;
}

- (void)dealloc {
	[scriptHooks release];
	[super dealloc];
}

- (BDSKScriptHook *)scriptHookWithUniqueID:(NSNumber *)uniqueID {
	return [scriptHooks objectForKey:uniqueID];
}

- (void)removeScriptHook:(BDSKScriptHook *)scriptHook {
	[scriptHooks removeObjectForKey:[scriptHook uniqueID]];
}

- (BDSKScriptHook *)makeScriptHookWithName:(NSString *)name {
	if (name == nil)
		return nil;
	// Safety call in case a script generates a loop
	if ([scriptHooks count] >= MAX_RUNNING_SCRIPT_HOOKS) {
        [NSException raise:NSRangeException format:@"Too many script hooks are running. There may be a loop."];
		return nil;
	}
	// We could also build a cache of scripts for each name.
	NSString *path = [[[OFPreferenceWrapper sharedPreferenceWrapper] dictionaryForKey:BDSKScriptHooksKey] objectForKey:name];
	NSAppleScript *script = nil;
	
	if ([NSString isEmptyString:path]) {
		return nil; // no script hook with this name set in the prefs
	} else if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSLog(@"No script file found for script hook %@.", name);
		return nil;
	} else {
		NSDictionary *errorInfo = nil;
		script = [[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path] error:&errorInfo];
		if (errorInfo) {
			NSLog(@"Error creating AppleScript: %@", [errorInfo objectForKey:NSAppleScriptErrorMessage]);
			return nil;
		}
	}
	
	BDSKScriptHook *scriptHook = [[BDSKScriptHook alloc] initWithName:name script:script];
	[scriptHooks setObject:scriptHook forKey:[scriptHook uniqueID]];
	[scriptHook release];
	
	return scriptHook;
}

- (BOOL)runScriptHook:(BDSKScriptHook *)scriptHook forPublications:(NSArray *)items document:(BibDocument *)document {
	if (scriptHook == nil)
		return NO;
	// execute the script
	BOOL rv = [scriptHook executeForPublications:items document:document];
	// cleanup
	[self removeScriptHook:scriptHook];
	return rv;
}

- (BOOL)runScriptHookWithName:(NSString *)name forPublications:(NSArray *)items document:(BibDocument *)document {
	return [self runScriptHookWithName:name forPublications:items document:document userInfo:nil];
}

- (BOOL)runScriptHookWithName:(NSString *)name forPublications:(NSArray *)items document:(BibDocument *)document userInfo:(NSDictionary *)userInfo {
	BDSKScriptHook *scriptHook = [self makeScriptHookWithName:name];
	if (scriptHook == nil)
		return NO;
	id value = nil;
	// set the user info values
	if ((value = [userInfo objectForKey:@"field"]) != nil)
		[scriptHook setField:value];
	if ((value = [userInfo objectForKey:@"oldValues"]) != nil)
		[scriptHook setOldValues:value];
	if ((value = [userInfo objectForKey:@"newValues"]) != nil)
		[scriptHook setNewValues:value];
	// execute the script and remove the script hook
	return [self runScriptHook:scriptHook forPublications:items document:document];
}

@end
