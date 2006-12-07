//
//  BDSKFilterController.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 17/3/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "BDSKFilterController.h"


@implementation BDSKFilterController

- (id)initWithFilter:(BDSKFilter *)aFilter
{
    self = [super init];
    if (self) {
		filter = [aFilter retain];
		[self setConditionControllers:[NSMutableArray arrayWithCapacity:[[filter conditions] count]]];
		[self setEnabled:[filter enabled]];
		[self setConjunction:[filter conjunction]];
    }
    return self;
}

- (void)dealloc
{
	//NSLog(@"dealloc filterController");
    [filter release];
    filter  = nil;
    [conditionControllers release];
    conditionControllers = nil;
    [super dealloc];
}

- (NSString *)windowNibName {
	return @"BDSKFilter";
}

- (void)awakeFromNib {
	NSEnumerator *cEnum = [[filter conditions] objectEnumerator];
	BDSKCondition *condition = nil;
	BDSKConditionController *controller = nil;
	
	[conditionControllers removeAllObjects];
	while (condition = [cEnum nextObject]) {
		controller = [[BDSKConditionController alloc] initWithFilterController:self condition:[[condition copy] autorelease]];
		[conditionControllers addObject:[controller autorelease]];
	}
	
	[ownerController setContent:self]; // fix for binding-to-nib-owner bug
	[stackView setLayoutEnabled:YES display:NO];
	[self updateUI];
}

- (void)updateUI {
	if ([conditionControllers count] == 1) {
		[enabledCheckButton setTitle:NSLocalizedString(@"Match the following condition:", @"")];
		[conjunctionPopUp setHidden:YES];
		[messageTextField setHidden:YES];
	} else {
		[enabledCheckButton setTitle:NSLocalizedString(@"Match", @"")];
		[conjunctionPopUp setHidden:NO];
		[messageTextField setHidden:NO];
	}
	
	int dHeight = -[stackView frame].size.height;
	if ([conditionControllers count]) 
		dHeight += [[[conditionControllers objectAtIndex:0] view] frame].size.height * [conditionControllers count];
	NSRect winFrame = [[self window] frame];
	winFrame.size.height += dHeight;
	winFrame.origin.y -= dHeight;
	
	if (dHeight < 0) [stackView reloadSubviews];		
	[[self window] setFrame:winFrame display:YES animate:YES];
	if (dHeight >= 0) [stackView reloadSubviews];		
}

- (IBAction)set:(id)sender {
	NSMutableArray *conditions = [NSMutableArray arrayWithCapacity:1];
	NSEnumerator *cEnum = [conditionControllers objectEnumerator];
	BDSKConditionController *controller = nil;
	
	while (controller = [cEnum nextObject]) {
		[conditions addObject:[controller condition]];
	}
	[filter setConditions:conditions];
	[filter setEnabled:[self enabled]];
	[filter setConjunction:[self conjunction]];
	
	[self close];
}

- (IBAction)cancel:(id)sender {
	[self close];
}

- (void)insertNewConditionAfter:(BDSKConditionController *)aConditionController {
	unsigned int index = [conditionControllers indexOfObject:aConditionController];
	if (index == NSNotFound) 
		index = [conditionControllers count] - 1;
	BDSKConditionController *newController = [[[BDSKConditionController alloc] initWithFilterController:self] autorelease];
	[conditionControllers insertObject:newController atIndex:index + 1];
	[self updateUI];
}

- (void)removeConditionController:(BDSKConditionController *)aConditionController {
	[conditionControllers removeObject:aConditionController]; 
	[self updateUI];
}

- (BOOL)canRemoveCondition {
	return ([conditionControllers count] > 1);
}

- (NSArray *)conditionControllers {
    return [[conditionControllers copy] autorelease];
}

- (void)setConditionControllers:(NSArray *)newConditionControllers {
    if (conditionControllers != newConditionControllers) {
        [conditionControllers release];
        conditionControllers = [newConditionControllers mutableCopy];
    }
}

- (BOOL)enabled {
    return enabled;
}

- (void)setEnabled:(BOOL)newEnabled {
	enabled = newEnabled;
}

- (BDSKConjunction)conjunction {
    return conjunction;
}

- (void)setConjunction:(BDSKConjunction)newConjunction {
	conjunction = newConjunction;
}

- (NSArray *)subviewsForStackView:(OAStackView *)aStackView {
	NSMutableArray *views = [NSMutableArray arrayWithCapacity:[conditionControllers count]];
	NSEnumerator *cEnum = [conditionControllers objectEnumerator];
	BDSKConditionController *controller = nil;
	NSView *stretchableView = [[[NSView alloc] init] autorelease];
	[stretchableView setAutoresizingMask:NSViewHeightSizable];
	
	while (controller = [cEnum nextObject]) {
		[controller setCanRemove:[self canRemoveCondition]];
		[views addObject:[controller view]];
	}
	[views addObject:stretchableView]; // stackView needs at least one vertically resizable subview
	return views;
}

- (void)windowWillClose:(NSNotification *)aNotification {
	[ownerController setContent:nil]; // fix for binding-to-nib-owner bug
}

@end
