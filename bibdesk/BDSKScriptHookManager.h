//
//  BDSKScriptHookManager.h
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

#import <Cocoa/Cocoa.h>
#import "BDSKScriptHook.h"

extern NSString *BDSKCloseEditorWindowScriptHookName;
extern NSString *BDSKChangeFieldScriptHookName;
extern NSString *BDSKWillAutoFileScriptHookName;
extern NSString *BDSKDidAutoFileScriptHookName;
extern NSString *BDSKWillGenerateCiteKeyScriptHookName;
extern NSString *BDSKDidGenerateCiteKeyScriptHookName;
extern NSString *BDSKSaveDocumentScriptHookName;


@class BibDocument;

@interface BDSKScriptHookManager : NSObject {
	NSMutableDictionary *scriptHooks;
}


/*!
	@method sharedManager
	@abstract Returns the shared instance of the class.
	@discussion -
*/
+ (BDSKScriptHookManager *)sharedManager;

/*!
	@method scriptHookNames
	@abstract Returns the known scripthook names
	@discussion -
*/
+ (NSArray *)scriptHookNames;

/*!
	@method scriptHookWithUniqueID:
	@abstract Returns the script hook with the given unique ID. 
	@discussion This is used for the AppleScript accessor.
	@param uniqueID The unique ID number.
*/
- (BDSKScriptHook *)scriptHookWithUniqueID:(NSNumber *)uniqueID;

/*!
	@method removeScriptHook:
	@abstract Removes the given script hook.
	@discussion -
	@param scriptHook The script hook object to remove.
*/
- (void)removeScriptHook:(BDSKScriptHook *)scriptHook;

/*!
	@method makeScriptHookWithName:
	@abstract Returns a newly created script hook with the given name, or nil if the script cannot be found.
	@discussion Remove the script hook after being done, or use one of the -runScriptHook... methods. 
	@param name The name for the script hook.
*/
- (BDSKScriptHook *)makeScriptHookWithName:(NSString *)name;

/*!
	@method runScriptHook:forPublications:document:
	@abstract Convenience method to execute the script and remove the script hook object. 
	@discussion -
	@param scriptHook The script hook to run.
	@param items An array of publications passed to the script for the script hook.
	@param document The document for the script hook.
*/
- (BOOL)runScriptHook:(BDSKScriptHook *)scriptHook forPublications:(NSArray *)items document:(BibDocument *)document;

/*!
	@method runScriptHookWithName:forPublications:document:
	@abstract Calls -runScriptHookWithName:forPublication:userInfo: with nil userInfo. 
	@discussion -
	@param name The name for the script hook.
	@param items An array of publications passed to the script for the script hook.
	@param document The document for the script hook.
*/
- (BOOL)runScriptHookWithName:(NSString *)name forPublications:(NSArray *)items document:(BibDocument *)document;

/*!
	@method runScriptHookWithName:forPublications:document:userInfo:
	@abstract Convenience method to create a script hook with the given name, set values from the userInfo, run the script, and remove the script hook object. 
	@discussion -
	@param name The name for the script hook.
	@param items An array of publications passed to the script for the script hook.
	@param document The document for the script hook.
	@param userInfo The user info set in the script hook.
*/
- (BOOL)runScriptHookWithName:(NSString *)name forPublications:(NSArray *)items document:(BibDocument *)document userInfo:(NSDictionary *)userInfo;

@end
