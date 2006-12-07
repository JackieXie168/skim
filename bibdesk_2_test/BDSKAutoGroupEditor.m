//
//  BDSKAutoGroupEditor.m
//  bd2xtest
//
//  Created by Christiaan Hofman on 2/16/06.
//  Copyright 2006. All rights reserved.
//

#import "BDSKAutoGroupEditor.h"
#import "BDSKDataModelNames.h"


@implementation BDSKAutoGroupEditor

+ (void)initialize {
    [self setKeys:[NSArray arrayWithObjects:@"entityName", nil]
        triggerChangeNotificationsForDependentKey:@"propertyNames"];
}

- (id)init {
    if (self = [super initWithWindowNibName:[self windowNibName]]) {
        managedObjectContext = nil;
        entityName = nil;
        propertyName = nil;
        editors = CFArrayCreateMutable(kCFAllocatorMallocZone, 0, NULL);
        predicateRules = [[NSDictionary alloc] initWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"PredicateRules.plist"]];
    }
    return self;
}

- (void)dealloc {
    CFRelease(editors), editors = nil;
    [entityName release], entityName = nil;
    [propertyName release], propertyName = nil;
    [predicateRules release], predicateRules = nil;
    [managedObjectContext release], managedObjectContext = nil;
    [super dealloc];
}

- (NSString *)windowNibName {
    return @"BDSKAutoGroupEditor";
}

- (void)reset {
    [self setPropertyName:nil];
}

#pragma mark Actions

- (IBAction)closeEditor:(id)sender {
    if ([[self window] isSheet]) {
		[[self window] orderOut:sender];
		[NSApp endSheet:[self window] returnCode:[sender tag]];
	} else {
        // how do we notify the caller?
		[[self window] performClose:sender];
	}
}

#pragma mark Accessors

- (NSManagedObjectContext *)managedObjectContext {
    return managedObjectContext;
}

- (void)setManagedObjectContext:(NSManagedObjectContext *)context {
    if (context != managedObjectContext) {
        [managedObjectContext release];
        managedObjectContext = [context retain];
    }
}

- (NSString *)entityName {
	return entityName;
}

- (void)setEntityName:(NSString *)newEntityName {
	if ([newEntityName isEqualToString:entityName] == NO) {
        [entityName release]; 
        entityName = [newEntityName retain];
        [self setPropertyName:nil];
    }
}

- (NSString *)propertyName {
	return propertyName;
}

- (void)setPropertyName:(NSString *)newPropertyName {
	if (newPropertyName != propertyName) {
        [propertyName release]; 
        propertyName = [newPropertyName retain];
    }
}

- (NSArray *)entityNames {
    return [NSArray arrayWithObjects:PublicationEntityName, PersonEntityName, InstitutionEntityName, VenueEntityName, NoteEntityName, TagEntityName, nil];
}

- (NSArray *)propertyNames {
    NSArray *propertyNames = nil;
    
    if (entityName != nil)
        propertyNames = [[predicateRules objectForKey:@"propertyNames"] objectForKey:entityName];
    
    return (propertyNames != nil) ? propertyNames : [NSArray array];
}

#pragma mark NSEditorRegistration

- (void)objectDidBeginEditing:(id)editor {
    if (CFArrayGetFirstIndexOfValue(editors, CFRangeMake(0, CFArrayGetCount(editors)), editor) == -1) {
		CFArrayAppendValue((CFMutableArrayRef)editors, editor);		
    }
}

- (void)objectDidEndEditing:(id)editor {
    CFIndex index = CFArrayGetFirstIndexOfValue(editors, CFRangeMake(0, CFArrayGetCount(editors)), editor);
    if (index != -1) {
		CFArrayRemoveValueAtIndex((CFMutableArrayRef)editors, index);		
    }
}

- (BOOL)commitEditing {
    CFIndex i, index, count = CFArrayGetCount(editors);
    NSObject *editor;
    
	for (i = 0; i < count; i++) {
		index = count - i - 1;
		editor = (NSObject *)(CFArrayGetValueAtIndex(editors, index));
		if (![editor commitEditing]) {
			return NO;
        }
	}
    
    // ensure the entityName and propertyName are valid
    @try {
        [self entityName]; 
        [self propertyName]; 
    }
    
    @catch ( NSException *e ) {  
        // present an alert about the problem
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert addButtonWithTitle:@"OK"];
        [alert setMessageText:@"Invalid Conditions"];
        [alert setInformativeText: [NSString stringWithFormat: @"The conditions you have specified for the AutoGroup are invalid:  please examine the values entered to ensure they have the proper formatting.\n\n(Error: %@)", [e description]]];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert runModal];

        return NO;  
    }
    
    return YES;
}

@end
