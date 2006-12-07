//
//  BibField.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 27/11/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "BibField.h"


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

- (NSString *)name {
    return [[name retain] autorelease];
}

- (NSString *)value {
    return [bibItem valueOfField:name];
}

- (void)setValue:(NSString *)newValue {
    [bibItem setField:name toValue:newValue];
}

@end
