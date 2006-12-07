//
//  BDSKFilterController.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 17/3/05.
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

#import "BDSKFilterController.h"
#import "BDSKConditionController.h"
#import "BDSKConditionsView.h"


@implementation BDSKFilterController

- (id)init
{
	BDSKFilter *aFilter = [[BDSKFilter alloc] init];
	self = [self initWithFilter:aFilter];
	[aFilter release];
	return self;
}

- (id)initWithFilter:(BDSKFilter *)aFilter
{
    self = [super init];
    if (self) {
		filter = [aFilter retain];
		[self setConditionControllers:[NSMutableArray arrayWithCapacity:[[filter conditions] count]]];
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
    BOOL canRemove = ([[filter conditions] count] > 1);
	
	[conditionControllers removeAllObjects];
	while (condition = [cEnum nextObject]) {
		controller = [[BDSKConditionController alloc] initWithFilterController:self condition:[[condition copy] autorelease]];
        [controller setCanRemove:canRemove];
		[conditionControllers addObject:[controller autorelease]];
        [conditionsView addView:[controller view]];
	}
	
	[ownerController setContent:self]; // fix for binding-to-nib-owner bug
	[self updateUI];
}

- (void)updateUI {
	if ([conditionControllers count] == 1) {
		[messageStartTextField setStringValue:NSLocalizedString(@"Match the following condition:", @"")];
		[conjunctionPopUp setHidden:YES];
		[messageEndTextField setHidden:YES];
	} else {
		[messageStartTextField setStringValue:NSLocalizedString(@"Match", @"")];
		[conjunctionPopUp setHidden:NO];
		[messageEndTextField setHidden:NO];
        [[messageStartTextField superview] setNeedsDisplayInRect:[messageStartTextField frame]];
	}
	[messageStartTextField sizeToFit];
}

- (IBAction)set:(id)sender {
	NSMutableArray *conditions = [NSMutableArray arrayWithCapacity:1];
	NSEnumerator *cEnum = [conditionControllers objectEnumerator];
	BDSKConditionController *controller = nil;
	
	if (![[self window] makeFirstResponder:[self window]])
		[[self window] endEditingFor:nil];
	
	while (controller = [cEnum nextObject]) {
		[conditions addObject:[controller condition]];
	}
	[filter setConditions:conditions];
	[filter setConjunction:[self conjunction]];
	
	[[filter undoManager] setActionName:NSLocalizedString(@"Edit Smart Group", @"Edit smart group")];
	
    if ([[self window] isSheet]) {
		[[NSNotificationCenter defaultCenter] postNotificationName:NSWindowWillCloseNotification object:[self window]];
		[[self window] orderOut:sender];
		[NSApp endSheet:[self window] returnCode:NSOKButton];
	} else {
		[[self window] performClose:sender];
	}
}

- (IBAction)cancel:(id)sender {
    if ([[self window] isSheet]) {
		[[NSNotificationCenter defaultCenter] postNotificationName:NSWindowWillCloseNotification object:[self window]];
		[[self window] orderOut:sender];
		[NSApp endSheet:[self window] returnCode:NSCancelButton];
	} else {
		[[self window] performClose:sender];
	}
}

- (BDSKFilter *)filter {
	return [[filter retain] autorelease];
}

- (void)insertNewConditionAfter:(BDSKConditionController *)aConditionController {
	unsigned int index = [conditionControllers indexOfObject:aConditionController];
    unsigned int count = [conditionControllers count];
	if (index == NSNotFound) 
		index = count - 1;
	BDSKConditionController *newController = [[[BDSKConditionController alloc] initWithFilterController:self] autorelease];
    [conditionControllers insertObject:newController atIndex:index + 1];
    [conditionsView insertView:[newController view] atIndex:index + 1];
    [newController setCanRemove:(count > 0)];
	if (count == 1) {
        [[conditionControllers objectAtIndex:0] setCanRemove:YES];
        [self updateUI];
    }
    [conditionsView scrollRectToVisible:[[newController view] frame]];
}

- (void)removeConditionController:(BDSKConditionController *)aConditionController {
	[conditionControllers removeObject:aConditionController]; 
    [conditionsView removeView:[aConditionController view]];
	if ([conditionControllers count] == 1) {
        [[conditionControllers objectAtIndex:0] setCanRemove:NO];
        [self updateUI];
    }
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

- (BDSKConjunction)conjunction {
    return conjunction;
}

- (void)setConjunction:(BDSKConjunction)newConjunction {
	conjunction = newConjunction;
}

- (void)windowWillClose:(NSNotification *)aNotification {
	[ownerController setContent:nil]; // fix for binding-to-nib-owner bug
}

@end
