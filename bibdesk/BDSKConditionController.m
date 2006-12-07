//
//  BDSKConditionController.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 17/3/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "BDSKConditionController.h"
#import "BDSKFilterController.h"


@implementation BDSKConditionController

- (id)initWithFilterController:(BDSKFilterController *)aFilterController
{
	BDSKCondition *aCondition = [[[BDSKCondition alloc] init] autorelease];
    self = [self initWithFilterController:aFilterController condition:aCondition];
    return self;
}

- (id)initWithFilterController:(BDSKFilterController *)aFilterController condition:(BDSKCondition *)aCondition
{
    self = [super init];
    if (self) {
        filterController = aFilterController;
        condition = [aCondition retain];
		canRemove = [filterController canRemoveCondition];
		
		[self updateKeys];
		
		[condition addObserver:self forKeyPath:@"itemType" options:0 context:NULL];
		
		BOOL success = [NSBundle loadNibNamed:@"BDSKCondition" owner:self];
		if (!success) {
			NSLog(@"Could not load BDSKCondition nib.");
		}
    }
    return self;
}

- (void)dealloc
{
	//NSLog(@"dealloc conditionController");
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[condition removeObserver:self forKeyPath:@"itemType"];
    filterController = nil;
	[condition release];
    condition = nil;
    [keys release];
    keys  = nil;
    [super dealloc];
}

- (void)awakeFromNib {
	[ownerController setContent:self]; // fix for binding-to-nib-owner bug
	
	[self updateKeyMenu];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(windowWillClose:)
												 name:NSWindowWillCloseNotification
											   object:[filterController window]];
}

- (void)windowWillClose:(NSNotification *)notification {
	[ownerController setContent:nil]; // fix for binding-to-nib-owner bug
}

- (NSView *)view {
	return view;
}

- (NSMenu *)keyMenu {
	NSMenu *menu = [[NSMenu alloc] init];
	NSMenuItem *menuItem;
	
	NSEnumerator *keyEnum = [keys objectEnumerator];
	NSString *key = nil;
	
	while (key = [keyEnum nextObject]) {
		menuItem = [[NSMenuItem alloc] initWithTitle:key action:@selector(changeKey:) keyEquivalent:@""];
		[menuItem setTarget:self];
		[menu addItem:[menuItem autorelease]];
	}
	
	if ([[condition itemClass] acceptsOtherFilterKeys]) {
		[menu addItem:[NSMenuItem separatorItem]];
		menuItem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"%@%C",NSLocalizedString(@"Add Other", @"Add Other..."),0x2026] action:@selector(addNewKey:) keyEquivalent:@""];
		[menuItem setTarget:self];
		[menu addItem:[menuItem autorelease]];
	}
	
	return [menu autorelease];
}

- (void)updateKeyMenu {
	[keyPopUp setMenu:[self keyMenu]];
	[keyPopUp selectItemWithTitle:[condition key]];
}

- (void)updateKeys {
	[keys autorelease];
	keys = [[[condition itemClass] filterKeys] mutableCopy];
	NSAssert1([keys count],@"Filter item class %@ must provide at least one filter key.",[condition itemClassName]);
	if ([condition key] == nil || [[condition key] isEqualToString:@""]) {
		[condition setKey:[keys objectAtIndex:0]];
	} else if (![keys containsObject:[condition key]]) {
		[keys addObject:[condition key]];
	}
	[self updateKeyMenu];
}

- (IBAction)addCondition:(id)sender {
	[filterController insertNewConditionAfter:self];
}

- (IBAction)removeCondition:(id)sender {
	if (![self canRemove]) return;
	[ownerController setContent:nil]; // fix for binding-to-nib-owner bug
	[filterController removeConditionController:self];
}

- (BDSKCondition *)condition {
    return [[condition retain] autorelease];
}

- (BOOL)canRemove {
	return canRemove;
}

- (void)setCanRemove:(BOOL)flag {
	canRemove = flag;
}

- (NSArray *)keys {
    return [[keys copy] autorelease];
}

- (void)setKeys:(NSArray *)newKeys {
    if (keys != newKeys) {
        [keys release];
        keys = [newKeys mutableCopy];
    }
}

- (void)changeKey:(id)sender {
	[condition setKey:[sender title]];
}

- (void)addKey:(NSString *)newKey {
	if (![keys containsObject:newKey]) 
		[keys addObject:newKey];
}

- (void)addNewKey:(id)sender {
    [NSApp beginSheet:addKeySheet
       modalForWindow:[filterController window]
        modalDelegate:self
       didEndSelector:@selector(addKeySheetDidEnd:returnCode:contextInfo:)
          contextInfo:nil];
}

- (IBAction)dismissAddKeySheet:(id)sender{
    [addKeySheet orderOut:sender];
    [NSApp endSheet:addKeySheet returnCode:[sender tag]];
}

- (void)addKeySheetDidEnd:(NSWindow *)sheet
			   returnCode:(int)returnCode
			  contextInfo:(void *)contextInfo{
    if(returnCode == NSOKButton){
		NSString *newKey = [[newKeyField stringValue] capitalizedString];
		[self addKey:newKey];
		[condition setKey:newKey];
		[self updateKeyMenu];
    }
	else {
		[keyPopUp selectItemWithTitle:[condition key]];
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:@"itemType"]) {
		[condition setKey:@""];
		[self updateKeys];
	}
}

@end
