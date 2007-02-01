//
//  BDSKMacro.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 1/2/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "BDSKMacro.h"
#import "BibDocument.h"
#import "BDSKMacroResolver.h"


@implementation BDSKMacro

+ (BOOL)accessInstanceVariablesDirectly {
	return NO;
}

- (id)initWithName:(NSString *)aName document:(BibDocument *)aDocument {
    self = [super init];
    if (self) {
        name = [aName copy];
        document = aDocument;
    }
    return self;
}

- (void)dealloc {
    [name release];
    [super dealloc];
}

- (NSScriptObjectSpecifier *) objectSpecifier {
    if ([self name] && document) {
        NSScriptObjectSpecifier *containerRef = [document objectSpecifier];
        return [[[NSNameSpecifier allocWithZone: [self zone]] 
			  initWithContainerClassDescription: [containerRef keyClassDescription] 
							 containerSpecifier: containerRef 
											key: @"macros" 
										   name: [self name]] autorelease];
    } else {
        return nil;
    }
}

- (BOOL)isEqual:(id)other {
    if ([other isMemberOfClass:[self class]] == NO)
        return NO;
    return [[self name] caseInsensitiveCompare:[other name]] == NSOrderedSame && 
           [[self document] isEqual:[other document]];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@: {%@ = %@}",[self class], [self name], [self value]];
}

- (NSString *)name {
    return [[name retain] autorelease];
}

- (void)setName:(NSString *)newName {
    if (name != newName) {
        if ([[document macroResolver] valueOfMacro:name] != nil)
            [[document macroResolver] changeMacroKey:name to:newName];
        [[document undoManager] setActionName:NSLocalizedString(@"AppleScript",@"Undo action name for AppleScript")];
        [name release];
        name = [newName copy];
    }
}

- (id)value {
    NSString *value = [[document macroResolver] valueOfMacro:name];
	if (value == nil) return [NSNull null]; // returns "missing value" in AppleScript
	return value;
}

- (void)setValue:(NSString *)newValue {
    [[document macroResolver] setMacroDefinition:newValue forMacro:name];
	[[document undoManager] setActionName:NSLocalizedString(@"AppleScript",@"Undo action name for AppleScript")];
}

- (id)bibTeXString {
    NSString *value = [[document macroResolver] valueOfMacro:name];
	if (value == nil) return [NSNull null]; // returns "missing value" in AppleScript
	return [value stringAsBibTeXString];
}

- (void)setBibTeXString:(NSString *)newValue {
    NS_DURING
		NSString *value = [NSString stringWithBibTeXString:newValue macroResolver:[document macroResolver]];
        [[document macroResolver] setMacroDefinition:value forMacro:name];
        [[document undoManager] setActionName:NSLocalizedString(@"AppleScript",@"Undo action name for AppleScript")];
    NS_HANDLER
		NSBeep();
    NS_ENDHANDLER
}

- (BibDocument *)document {
    return document;
}

@end
