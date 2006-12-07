//
//  BibField.m
//  BibDesk
//
//  Created by Christiaan Hofman on 27/11/04.
/*
 This software is Copyright (c) 2004,2005,2006
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

#import "BibField.h"
#import "BDSKOwnerProtocol.h"

/* cmh
A wrapper object around the fields to access them in AppleScript. 
*/
@implementation BibField

+ (BOOL)accessInstanceVariablesDirectly {
	return NO;
}

- (id)initWithName:(NSString *)newName bibItem:(BibItem *)newBibItem {
    self = [super init];
    if (self) {
        name = [newName copy];
        bibItem = newBibItem;
    }
    return self;
}

- (void)dealloc {
    [name release];
    [super dealloc];
}

- (NSScriptObjectSpecifier *) objectSpecifier {
    if ([self name] && bibItem) {
        NSScriptObjectSpecifier *containerRef = [bibItem objectSpecifier];
        return [[[NSNameSpecifier allocWithZone: [self zone]] 
			  initWithContainerClassDescription: [containerRef keyClassDescription] 
							 containerSpecifier: containerRef 
											key: @"bibFields" 
										   name: [self name]] autorelease];
    } else {
        return nil;
    }
}

- (NSString *)description {
    return [NSString stringWithFormat:@"{%@ = %@}",[self name], [self value]];
}

- (NSString *)name {
    return [[name retain] autorelease];
}

- (NSString *)value {
    NSString *value = [bibItem valueOfField:name];
	if (value == nil) return @"";
	return value;
}

- (void)setValue:(NSString *)newValue {
    [bibItem setField:name toValue:newValue];
	[[bibItem undoManager] setActionName:NSLocalizedString(@"AppleScript",@"Undo action name for AppleScript")];
}

- (BibItem *)publication {
	return bibItem;
}

- (NSString *)bibTeXString {
    NSString *value = [bibItem valueOfField:name];
	if (value == nil) return @"";
	return [value stringAsBibTeXString];
}

- (void)setBibTeXString:(NSString *)newValue {
    NS_DURING
		NSString *value = [NSString stringWithBibTeXString:newValue macroResolver:[[bibItem owner] macroResolver]];
		[bibItem setField:name toValue:value];
    NS_HANDLER
		NSBeep();
    NS_ENDHANDLER
}

- (BOOL)isInherited {
	return [[bibItem valueOfField:name] isInherited];
}

@end
