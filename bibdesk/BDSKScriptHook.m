//
//  BDSKScriptHook.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 17/10/05.
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

#import "BDSKScriptHook.h"
#import "BibDocument.h"
#import "KFAppleScriptHandlerAdditionsCore.h"

// these correspond to the script codes in the .sdef file
#define kBDSKBibdeskSuite				'BDSK'
#define kBDSKPerformBibdeskAction		'pAct'
#define kBDSKPrepositionForScriptHook	'fshk'

static unsigned long scriptHookID = 0;

@implementation BDSKScriptHook

// dummy, don't use this
- (id)init {
	self = [self initWithName:@"" script:nil];
	return self;
}

- (id)initWithName:(NSString *)aName script:(NSAppleScript *)aScript {
	if (self = [super init]) {
        if (aScript == nil || aName == nil) {
            [self release];
            self = nil;
        } else {
            uniqueID = [[NSNumber alloc] initWithInt:++scriptHookID];
            name = [aName retain];
            script = [aScript retain];
            field = nil;
            oldValues = nil;
            newValues = nil;
            document = nil;
        }
	}
	return self;
}

- (void)dealloc {
	[name release];
	[uniqueID release];
	[script release];
	[field release];
	[oldValues release];
	[newValues release];
	[document release];
	[super dealloc];
}

- (NSString *)name {
    return name;
}

- (NSNumber *)uniqueID {
    return uniqueID;
}

- (NSAppleScript *)script {
    return script;
}

- (NSString *)field {
    return field;
}

- (void)setField:(NSString *)newField {
    if (![field isEqualToString:newField]) {
        [field release];
        field = [newField retain];
    }
}

- (NSArray *)oldValues {
    return oldValues;
}

- (void)setOldValues:(NSArray *)values {
    if (oldValues != values) {
        [oldValues release];
        oldValues = [values retain];
    }
}

- (NSArray *)newValues {
    return newValues;
}

- (void)setNewValues:(NSArray *)values {
    if (newValues != values) {
        [newValues release];
        newValues = [values retain];
    }
}

- (BibDocument *)document {
    return document;
}

- (void)setDocument:(BibDocument *)newDocument {
    if (document != newDocument) {
        [document release];
        document = [newDocument retain];
    }
}

- (BOOL)executeForPublications:(NSArray *)items document:(BibDocument *)aDocument{
	if (script == nil) {
		NSLog(@"No script found for script hook \"%@\"", name);
		return NO;
	}
	BOOL rv = YES;
    
    [self setDocument:aDocument];
	
	NS_DURING
		[script executeHandler:kBDSKPerformBibdeskAction 
					 fromSuite:kBDSKBibdeskSuite 
	   withLabelsAndParameters:keyDirectObject, items, kBDSKPrepositionForScriptHook, self, nil];
	NS_HANDLER
		NSLog(@"Error executing script hook \"%@\": %@", name, [localException reason]);
		rv = NO;
	NS_ENDHANDLER
	
	return rv;
}

@end
