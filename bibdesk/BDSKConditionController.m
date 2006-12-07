//
//  BDSKConditionController.m
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

#import "BDSKConditionController.h"
#import "BDSKFilterController.h"
#import "BibItem.h"
#import "BDSKFieldNameFormatter.h"
#import <OmniBase/assertions.h>
#import "BDSKDateStringFormatter.h"

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
		
        BibTypeManager *typeMan = [BibTypeManager sharedManager];
        keys = [[typeMan allFieldNamesIncluding:[NSArray arrayWithObjects:BDSKDateAddedString, BDSKDateModifiedString, BDSKAllFieldsString, nil]
                                      excluding:nil] mutableCopy];
		
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
    filterController = nil;
	[condition release];
    condition = nil;
    [keys release];
    keys  = nil;
    [view release];
    view  = nil;
	[ownerController release];
    [super dealloc];
}

- (void)awakeFromNib {
	[ownerController setContent:self]; // fix for binding-to-nib-owner bug
	
	[keyComboBox setFormatter:[[[BDSKFieldNameFormatter alloc] init] autorelease]];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(windowWillClose:)
												 name:NSWindowWillCloseNotification
											   object:[filterController window]];
    
    [condition addObserver:self forKeyPath:@"key" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld  context:NULL];
    if([condition isDateCondition])
        [valueTextField setFormatter:[BDSKDateStringFormatter shortDateNaturalLanguageFormatter]];
    
}

- (void)windowWillClose:(NSNotification *)notification {
	[ownerController setContent:nil]; // fix for binding-to-nib-owner bug
    [condition removeObserver:self forKeyPath:@"key"];
}

- (NSView *)view {
	return view;
}

- (IBAction)addNewCondition:(id)sender {
	[filterController insertNewConditionAfter:self];
}

- (IBAction)removeThisCondition:(id)sender {
	if (![self canRemove]) return;
	[ownerController setContent:nil]; // fix for binding-to-nib-owner bug
    [condition removeObserver:self forKeyPath:@"key"];
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

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    OBASSERT(object == condition);
    if(object == condition && [keyPath isEqualToString:@"key"]){
        NSString *key = [change objectForKey:NSKeyValueChangeNewKey];
        if([key isEqualToString:BDSKDateModifiedString] || [key isEqualToString:BDSKDateAddedString]){
            [valueTextField setFormatter:[BDSKDateStringFormatter shortDateNaturalLanguageFormatter]];
        } else {
            [valueTextField setFormatter:nil];
        }
    }
}
    
@end
