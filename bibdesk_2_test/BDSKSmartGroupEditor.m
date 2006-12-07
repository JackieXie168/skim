//
//  BDSKSmartGroupEditor.m
//  bd2
//
//  Created by Christiaan Hofman on 2/15/06.
//  Copyright 2006. All rights reserved.
//

#import "BDSKSmartGroupEditor.h"
#import "BDSKDataModelNames.h"


@interface BDSKMarker : NSObject {} 
@end

@implementation BDSKMarker 

id BDSKNoCategoriesMarker;
id BDSKAddOtherMarker;

+ (void)load {
    BDSKNoCategoriesMarker = (BDSKMarker *)NSAllocateObject(self, 0, NSDefaultMallocZone());
    BDSKAddOtherMarker = (BDSKMarker *)NSAllocateObject(self, 0, NSDefaultMallocZone());
}

+ (id)allocWithZone:(NSZone *)zone { return nil; }
- (id)copyWithZone:(NSZone *)zone { return self; }
- (id)autorelease { return self; }
- (void)release {}
- (id)retain { return self; }

@end


@implementation BDSKSmartGroupEditor

+ (void)initialize {
    [self setKeys:[NSArray arrayWithObjects:@"entityName", nil]
        triggerChangeNotificationsForDependentKey:@"propertyNames"];
    [self setKeys:[NSArray arrayWithObjects:@"propertyName", nil]
        triggerChangeNotificationsForDependentKey:@"categoryPropertyName"];
}

- (id)init {
    if (self = [super initWithWindowNibName:[self windowNibName]]) {
        managedObjectContext = nil;
        entityName = nil;
        propertyName = nil;
        conjunction = 0;
        predicateRules = [[NSDictionary alloc] initWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"PredicateRules.plist"]];
        publicationPropertyNames = [[NSMutableArray alloc] initWithArray:[[predicateRules objectForKey:@"propertyNames"] objectForKey:PublicationEntityName]];
        [publicationPropertyNames addObject:[NSDictionary dictionaryWithObjectsAndKeys:BDSKAddOtherMarker, @"propertyName", [NSString stringWithFormat:@"Add Other%C",0x2026], @"displayName", @"", @"type", nil]];
        controllers = [[NSMutableArray alloc] init];
        editors = CFArrayCreateMutable(kCFAllocatorMallocZone, 0, NULL);
    }
    return self;
}

- (void)dealloc {
    [self reset];
    CFRelease(editors), editors = nil;
    [controllers release], controllers = nil;
    [entityName release], entityName = nil;
    [propertyName release], propertyName = nil;
    [publicationPropertyNames release], predicateRules = nil;
    [predicateRules release], predicateRules = nil;
    [managedObjectContext release], managedObjectContext = nil;
    [super dealloc];
}

- (NSString *)windowNibName {
    return @"BDSKSmartGroupEditor";
}

- (void)reset {
    [mainView removeAllSubviews];
    
    [controllers makeObjectsPerformSelector:@selector(cleanup)];
    
    [self willChangeValueForKey:@"isCompound"];
    [controllers removeAllObjects];
    [self didChangeValueForKey:@"isCompound"];
    
    [self setPropertyName:nil];
}

#pragma mark Actions

- (IBAction)add:(id)sender {
    BDSKComparisonPredicateController *controller = [[BDSKComparisonPredicateController alloc] initWithEditor:self];
    NSView *view = [controller view];
    
    if (view) {
        [mainView addView:view];
        
        [self willChangeValueForKey:@"isCompound"];
		[controllers addObject:controller]; 
        [self didChangeValueForKey:@"isCompound"];
    }
    [controller release];
}

- (IBAction)remove:(BDSKComparisonPredicateController *)controller {
    int index = [controllers indexOfObjectIdenticalTo:controller];
    
    if (index != NSNotFound) {  
        [mainView removeView:[controller view]];
        
        [self willChangeValueForKey:@"isCompound"];
        [controllers removeObjectAtIndex:index];
        [self didChangeValueForKey:@"isCompound"];
    }
}

- (IBAction)closeEditor:(id)sender {
    if ([[self window] isSheet]) {
		[[self window] orderOut:sender];
		[NSApp endSheet:[self window] returnCode:[sender tag]];
	} else {
        // how do we notify the caller?
		[[self window] performClose:sender];
	}
}

- (IBAction)addNewProperty:(id)sender {
    [self setAddedPropertyName:nil];
    
    [NSApp beginSheet:addPropertySheet
       modalForWindow:[self window] 
        modalDelegate:self 
       didEndSelector:@selector(addPropertySheetDidEnd:returnCode:contextInfo:) 
          contextInfo:[sender retain]];
}

- (IBAction)closeAddPropertySheet:(id)sender {
    [addPropertySheet orderOut:sender];
    [NSApp endSheet:addPropertySheet returnCode:[sender tag]];
}

- (void)addPropertySheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(id)sender {
    if (returnCode == NSOKButton) {
        NSString *newPropertyName = [self addNewPropertyForDisplayName:[self addedPropertyName]];
        if (newPropertyName != nil) {
            [sender setPropertyName:newPropertyName];
        } else {
            [sender setPropertyName:[sender propertyName]];
            NSBeep();
        }
    } else {
        [sender setPropertyName:[sender propertyName]];
    }
    [sender release];
}

// TODO: room for improvement
- (NSString *)addNewPropertyForPropertyName:(NSString *)newPropertyName {
    if ([[self entityName] isEqualToString:PublicationEntityName] == NO)
        return nil;
    if ([[publicationPropertyNames valueForKeyPath:@"@distinctUnionOfObjects.propertyName"] containsObject:newPropertyName] == YES) 
        return newPropertyName;
    NSMutableString *newDisplayName = [[NSMutableString alloc] initWithCapacity:[newPropertyName length]];
    
    if ([newPropertyName hasPrefix:@"contributors/"]) {
        if ([newPropertyName hasSuffix:@".name"]) {
            [newDisplayName appendString:[[newDisplayName substringWithRange:NSMakeRange(13, [newPropertyName length] - 5)] capitalizedString]];
            [newDisplayName appendString:@" Name"];
        } else if ([newPropertyName hasSuffix:@".lastNamePart"]) {
            [newDisplayName appendString:[[newDisplayName substringWithRange:NSMakeRange(13, [newPropertyName length] - 13)] capitalizedString]];
            [newDisplayName appendString:@" Last Name"];
        } else if ([newPropertyName hasSuffix:@".firstNamePart"]) {
            [newDisplayName appendString:[[newDisplayName substringWithRange:NSMakeRange(13, [newPropertyName length] - 14)] capitalizedString]];
            [newDisplayName appendString:@" First Name"];
        } else return nil;
    } else {
        [newDisplayName appendString:[newPropertyName capitalizedString]];
    }
    NSCharacterSet *dashCharacterSet = [NSCharacterSet characterSetWithRange:NSMakeRange('-',0)];
    NSRange range = [newPropertyName rangeOfCharacterFromSet:dashCharacterSet];
    while (range.location != NSNotFound) {
        [newDisplayName replaceCharactersInRange:range withString:@" "];
        range = [newDisplayName rangeOfCharacterFromSet:dashCharacterSet];
    }
    NSDictionary *propertyDict = [NSDictionary dictionaryWithObjectsAndKeys:newPropertyName, @"propertyName", newDisplayName, @"displayName", @"string", @"type", nil];
    
    [self willChangeValueForKey:@"propertyNames"];
    [self willChangeValueForKey:@"categoryPropertyNames"];
    [publicationPropertyNames insertObject:propertyDict atIndex:[publicationPropertyNames count] - 1];
    [self didChangeValueForKey:@"categoryPropertyNames"];
    [self didChangeValueForKey:@"propertyNames"];
    
    [newDisplayName release];
    return newPropertyName;
}

// TODO: room for improvement
- (NSString *)addNewPropertyForDisplayName:(NSString *)newDisplayName {
    if ([[self entityName] isEqualToString:PublicationEntityName] == NO || newDisplayName == nil || [newDisplayName isEqualToString:@""])
        return nil;
    
    NSMutableString *newPropertyName = [[NSMutableString alloc] initWithCapacity:[newDisplayName length]];
    
    if ([newDisplayName hasSuffix:@" Name"] ) {
        [newPropertyName appendString:@"contributors/"];
        [newPropertyName appendString:[newDisplayName substringToIndex:[newDisplayName length] - 5]];
        [newPropertyName appendString:@".name"];
    } else if ([newDisplayName hasSuffix:@" Last Name"]) {
        [newPropertyName appendString:@"contributors/"];
        [newPropertyName appendString:[newDisplayName substringToIndex:[newDisplayName length] - 10]];
        [newPropertyName appendString:@".lastNamePart"];
    } else if ([newDisplayName hasSuffix:@" First Name"]) {
        [newPropertyName appendString:@"contributors/"];
        [newPropertyName appendString:[newDisplayName substringToIndex:[newDisplayName length] - 11]];
        [newPropertyName appendString:@".firstNamePart"];
    } else {
        [newPropertyName appendString:newDisplayName];
    }
    NSRange range = [newPropertyName rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]];
    while (range.location != NSNotFound) {
        [newPropertyName replaceCharactersInRange:range withString:@"-"];
        range = [newPropertyName rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]];
    }
    
    if ([[publicationPropertyNames valueForKeyPath:@"@distinctUnionOfObjects.propertyName"] containsObject:newPropertyName] == YES)
        return newPropertyName;
    
    NSDictionary *propertyDict = [NSDictionary dictionaryWithObjectsAndKeys:newPropertyName, @"propertyName", newDisplayName, @"displayName", @"string", @"type", nil];
    
    [self willChangeValueForKey:@"propertyNames"];
    [self willChangeValueForKey:@"categoryPropertyNames"];
    [publicationPropertyNames insertObject:propertyDict atIndex:[publicationPropertyNames count] - 1];
    [self didChangeValueForKey:@"categoryPropertyNames"];
    [self didChangeValueForKey:@"propertyNames"];
    
    [newPropertyName release];
    return newPropertyName;
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
        [self reset];
    }
}

- (NSString *)propertyName {
	return propertyName;
}

- (void)setPropertyName:(NSString *)newPropertyName {
	if (newPropertyName != propertyName) {
        if (newPropertyName != nil && [self addNewPropertyForPropertyName:newPropertyName] == nil) {
            NSBeep();
            return;
        }
        [propertyName release]; 
        propertyName = [newPropertyName retain];
    }
}

- (id)categoryPropertyName {
	return (propertyName == nil) ? BDSKNoCategoriesMarker : propertyName;
}

- (void)setCategoryPropertyName:(id)newPropertyName {
    if (newPropertyName == BDSKNoCategoriesMarker || NSIsControllerMarker(propertyName)) {
        newPropertyName = nil;
    } else if (newPropertyName == BDSKAddOtherMarker) {
        [self addNewProperty:self];
        return;
    }
    [self setPropertyName:newPropertyName];
}

- (int)conjunction {
    return conjunction;
}

- (void)setConjunction:(int)value {
    conjunction = value;
}

- (NSPredicate *)predicate {
    int count = [controllers count];
    
    if (count == 0)
        return [NSPredicate predicateWithValue:YES];
    else if (count == 1)
        return [[controllers lastObject] predicate];
    
    NSMutableArray *subpredicates = [[NSMutableArray alloc] initWithCapacity:count];
    NSPredicate *predicate;
    int i;
    
    for (i = 0; i < count; i++) {
        id controller = [controller objectAtIndex:i];
        [subpredicates addObject:[controller predicate]];
    }
    
    if ([self conjunction] == 1)
        predicate = [NSCompoundPredicate orPredicateWithSubpredicates:subpredicates];
    else
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:subpredicates];
    
    [subpredicates release];
    
    return predicate;
}

- (void)setPredicate:(NSPredicate *)newPredicate {
	NSArray *subpredicates;
    
    [self setConjunction:0];

	// The predicate may be nil, compound or comparison
	if (newPredicate == nil || [newPredicate isEqualTo:[NSPredicate predicateWithValue:YES]] || [newPredicate isEqualTo:[NSPredicate predicateWithValue:NO]]) {
		subpredicates = [NSArray array];
	} else if ([newPredicate isKindOfClass:[NSCompoundPredicate self]]) {
		subpredicates = [(NSCompoundPredicate *)newPredicate subpredicates];
        if ([(NSCompoundPredicate *)newPredicate compoundPredicateType] == NSOrPredicateType)
            [self setConjunction:1];
	} else {
	    subpredicates = [NSArray arrayWithObject:newPredicate];
	}

    NSEnumerator *predicateEnum = [subpredicates objectEnumerator];
	NSPredicate *predicate;
    
    if ([controllers count] > 0)
        [self reset];
	while (predicate = [predicateEnum nextObject]) {
        [self add:nil];
        [[controllers lastObject] setPredicate:predicate];
    }    
}

- (NSString *)addedPropertyName {
	return addedPropertyName;
}

- (void)setAddedPropertyName:(NSString *)newPropertyName {
	if (newPropertyName != addedPropertyName) {
        [addedPropertyName release]; 
        addedPropertyName = [newPropertyName retain];
    }
}

- (NSArray *)entityNames {
    return [predicateRules objectForKey:@"entityNames"];
}

- (NSArray *)propertyNames {
    NSArray *propertyNames = nil;
    
    if (entityName != nil) {
        if ([entityName isEqualToString:PublicationEntityName])
            propertyNames = publicationPropertyNames;
        else
            propertyNames = [[predicateRules objectForKey:@"propertyNames"] objectForKey:entityName];
    }
    
    return (propertyNames != nil) ? propertyNames : [NSArray array];
}

- (NSArray *)categoryPropertyNames {
    NSMutableArray *propertyNames = [NSMutableArray arrayWithObject:[NSDictionary dictionaryWithObjectsAndKeys:BDSKNoCategoriesMarker, @"propertyName", @"No Categories", @"displayName", @"", @"type", nil]];
    
    if (entityName != nil)
        [propertyNames addObjectsFromArray:[self propertyNames]];
    
    return (propertyNames != nil) ? propertyNames : [NSArray array];
}

- (NSArray *)operatorNamesForTypeName:(NSString *)attributeTypeName {
    NSArray *operatorNames = [[predicateRules objectForKey:@"operatorNames"] objectForKey:attributeTypeName];
    
    return (operatorNames != nil) ? operatorNames : [NSArray array];
}

- (NSPredicateOperatorType)operatorTypeForOperatorName:(NSString *)operatorName {
    return [[predicateRules objectForKey:@"operatorTypes"] indexOfObject:operatorName];
}

- (NSString *)operatorNameForOperatorType:(NSPredicateOperatorType)operatorType {
    return [[predicateRules objectForKey:@"operatorTypes"] objectAtIndex:operatorType];
}

- (BOOL)isCompound {
    return ([controllers count] > 1);
}

- (BOOL)canChangeEntityName {
    return canChangeEntityName;
}

- (void)setCanChangeEntityName:(BOOL)flag {
    canChangeEntityName = flag;
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
		if (![editor commitEditing]) 
			return NO;
	}
    
    // ensure the predicate is valid
    @try { 
        [self entityName]; 
        [self propertyName]; 
        [self predicate];
    }
    
    @catch ( NSException *e ) {  
        // present an alert about the problem
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert addButtonWithTitle:@"OK"];
        [alert setMessageText:@"Invalid Conditions"];
        [alert setInformativeText: [NSString stringWithFormat: @"The conditions you have specified for the SmartGroup are invalid:  please examine the values entered to ensure they have the proper formatting.\n\n(Error: %@)", [e description]]];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert runModal];

        return NO;  
    }
    
    return YES;
}

@end


#define SEPARATION 0.0l

@implementation BDSKPredicateView

// this makes it easier to place the subviews
- (BOOL)isFlipped {
    return YES;
}

- (NSSize)minimumSize { 
    NSArray *subviews = [self subviews];
    float height = ([subviews count] > 0) ? NSMaxY([[subviews lastObject] frame]) : 10.0f;
    return NSMakeSize(NSWidth([self frame]), height);
}

- (void)setFrameSize:(NSSize)newSize {
    if (newSize.height >= [self minimumSize].height) {        
        [super setFrameSize:newSize];
    }
}

- (void)updateSize {
    float oldHeight = NSHeight([self frame]);
    
    [self setFrameSize:[self minimumSize]];
    
    float dh = NSHeight([self frame]) - oldHeight;
    if (dh != 0.0f) {
        NSRect winFrame = [[self window] frame];
        winFrame.size.height += dh;
        winFrame.origin.y -= dh;
        [[self window] setFrame:winFrame display:YES animate:YES];
    }
}

- (void)addView:(NSView *)view {
    NSArray *subviews = [self subviews];
    
    NSView *lastView = [subviews lastObject]; // use the lastView to compute location of next view
    
    [self addSubview:view];
    if (lastView != nil) {
        float yPosition = NSMaxY([lastView frame]) + SEPARATION;
        [view setFrameOrigin:NSMakePoint(0.0l, yPosition)];
    }
    
    NSSize size = [view frame].size;
    [view setFrameSize:NSMakeSize(NSWidth([self frame]), size.height)];
    
    [self updateSize];
    [self setNeedsDisplay:YES];
}

- (void)removeView:(NSView *)view {
    NSArray *subviews = [[[self subviews] copy] autorelease];
    int index = [subviews indexOfObjectIdenticalTo:view];
    
    if (index != NSNotFound) {
        NSView *view = [subviews objectAtIndex:index];
        NSPoint newPoint = [view frame].origin;
        float dy = NSHeight([view frame]) + SEPARATION;
        
        [view removeFromSuperview];
        
        int count = [subviews count];
        
        for (index++; index < count; index++) {
            view = [subviews objectAtIndex:index];
            [view setFrameOrigin:newPoint];
            newPoint.y += dy;
        }
        
        [self updateSize];
    }
    [self setNeedsDisplay:YES];
}

- (void)removeAllSubviews {
    NSArray *subviews = [[[self subviews] copy] autorelease];
    NSEnumerator *viewEnum = [subviews objectEnumerator];
    NSView *view;
    
    while (view = [viewEnum nextObject]) {
        [view removeFromSuperviewWithoutNeedingDisplay];
    }
    [self updateSize];
    [self setNeedsDisplay:YES];
}

@end
