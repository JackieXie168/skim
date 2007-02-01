//
//  BibAppController+Scripting.m
//  BibDesk
//
//  Created by Sven-S. Porst on Sat Jul 10 2004.
/*
 This software is Copyright (c) 2004,2005,2006,2007
 Sven-S. Porst. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 - Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 - Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in
 the documentation and/or other materials provided with the
 distribution.
 
 - Neither the name of Sven-S. Porst nor the names of any
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

#import "BibAppController+Scripting.h"
#import <OmniFoundation/OFPreference.h>
#import "BDSKScriptHookManager.h"
#import "BibTypeManager.h"
#import "BDSKMacroResolver.h"
#import "BDSKMacro.h"

/* ssp
Category on BibAppController making the papers folder readable for scripting
*/
@implementation BibAppController (Scripting)

/*
 ssp: 2004-07-12
 these two methods make the papers folder preference available to AppleScript
 -papersFolder accessor method
 -application:delegateHandlesKey: advertises the accesor method
*/
- (NSString*) papersFolder {
	return [[[OFPreferenceWrapper sharedPreferenceWrapper] stringForKey:BDSKPapersFolderPathKey] stringByStandardizingPath];
}

- (NSArray *)allTypes {
	return [[BibTypeManager sharedManager] bibTypesForFileType:BDSKBibtexString];
}

- (NSArray *)allFieldNames {
	return [[BibTypeManager sharedManager] allFieldNamesIncluding:nil excluding:nil];
}

- (BDSKScriptHook *)valueInScriptHooksWithUniqueID:(NSNumber *)uniqueID {
	return [[BDSKScriptHookManager sharedManager] scriptHookWithUniqueID:uniqueID];
}

- (BDSKMacro *)valueInMacrosWithName:(NSString *)name {
	return [[[BDSKMacro alloc] initWithName:name macroResolver:[BDSKMacroResolver defaultMacroResolver]] autorelease];
}

- (NSArray *)macros {
    NSEnumerator *mEnum = [[[BDSKMacroResolver defaultMacroResolver] macroDefinitions] keyEnumerator];
	NSString *name = nil;
	BDSKMacro *macro = nil;
	NSMutableArray *macros = [NSMutableArray arrayWithCapacity:5];
	
	while (name = [mEnum nextObject]) {
		macro = [[BDSKMacro alloc] initWithName:name macroResolver:[BDSKMacroResolver defaultMacroResolver]];
		[macros addObject:macro];
		[macro release];
	}
	return macros;
}

- (BOOL)application:(NSApplication *)sender delegateHandlesKey:(NSString *)key {
	if ([key isEqualToString:@"papersFolder"] ||
		[key isEqualToString:@"allTypes"] ||
		[key isEqualToString:@"allFieldNames"] ||
		[key isEqualToString:@"macros"] ||
		[key isEqualToString:@"scriptHooks"]) 
		return YES;
	return NO;
}

@end

