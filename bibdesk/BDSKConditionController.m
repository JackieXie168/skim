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
        keys = [[typeMan allFieldNamesIncluding:[NSArray arrayWithObjects:BDSKDateAddedString, BDSKDateModifiedString, BDSKAllFieldsString, BDSKPubTypeString, nil]
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
    [[dateComparisonPopUp superview] release];
    [[comparisonPopUp superview] release];
    [[valueTextField superview] release];
    [[numberTextField superview] release];
    [[andNumberTextField superview] release];
    [[periodPopUp superview] release];
    [[agoText superview] release];
    [[dateTextField superview] release];
    [[toDateTextField superview] release];
    [super dealloc];
}

- (void)awakeFromNib {
    // we add/remove these controls, so we need to retain them
    [[dateComparisonPopUp superview] retain];
    [[comparisonPopUp superview] retain];
    [[valueTextField superview] retain];
    [[numberTextField superview] retain];
    [[andNumberTextField superview] retain];
    [[periodPopUp superview] retain];
    [[agoText superview] retain];
    [[dateTextField superview] retain];
    [[toDateTextField superview] retain];
    
    NSDateFormatter *formatter = [[[NSDateFormatter alloc] initWithDateFormat:[[NSUserDefaults standardUserDefaults] objectForKey:NSShortDateFormatString] allowNaturalLanguage:YES] autorelease];
    if ([formatter respondsToSelector:@selector(setGeneratesCalendarDates:)])
        [formatter setGeneratesCalendarDates:YES];
    [dateTextField setFormatter:formatter];
    [toDateTextField setFormatter:formatter];

	[ownerController setContent:self]; // fix for binding-to-nib-owner bug
	
	[keyComboBox setFormatter:[[[BDSKFieldNameFormatter alloc] init] autorelease]];
    
    [self layoutComparisonControls];
    [self layoutValueControls];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(windowWillClose:)
												 name:NSWindowWillCloseNotification
											   object:[filterController window]];
    
    [condition addObserver:self forKeyPath:@"key" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld  context:NULL];
    [condition addObserver:self forKeyPath:@"dateComparison" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld  context:NULL];
}

- (void)windowWillClose:(NSNotification *)notification {
	[ownerController setContent:nil]; // fix for binding-to-nib-owner bug
    [condition removeObserver:self forKeyPath:@"key"];
    [condition removeObserver:self forKeyPath:@"dateComparison"];
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
    [condition removeObserver:self forKeyPath:@"dateComparison"];
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

- (void)layoutValueControls {
    NSArray *controls = nil;
    if ([condition isDateCondition]) {
        switch ([condition dateComparison]) {
            case BDSKExactly: 
                controls = [NSArray arrayWithObjects:numberTextField, periodPopUp, agoText, nil];
                break;
            case BDSKInLast: 
            case BDSKNotInLast: 
                controls = [NSArray arrayWithObjects:numberTextField, periodPopUp, nil];
                break;
            case BDSKBetween: 
                controls = [NSArray arrayWithObjects:numberTextField, andNumberTextField, periodPopUp, agoText, nil];
                break;
            case BDSKDate: 
            case BDSKAfterDate: 
            case BDSKBeforeDate: 
                controls = [NSArray arrayWithObjects:dateTextField, nil];
                break;
            case BDSKInDateRange:
                controls = [NSArray arrayWithObjects:dateTextField, toDateTextField, nil];
                break;
            default:
                break;
        }
    } else {
        controls = [NSArray arrayWithObjects:valueTextField, nil];
    }
    
    NSRect rect = NSZeroRect;
    NSEnumerator *viewEnum = [[[valueBox contentView] subviews] objectEnumerator];
    NSView *aView;
    
    while (aView = [viewEnum nextObject]) 
        [aView removeFromSuperview];
    
    viewEnum = [controls objectEnumerator];
    while (aView = [viewEnum nextObject]) {
        aView = [aView superview];
        rect.size = [aView frame].size;
        [aView setFrameOrigin:rect.origin];
        [valueBox addSubview:aView];
        rect.origin.x += NSWidth(rect);
    }
}

- (void)layoutComparisonControls {
    [[[[comparisonBox contentView] subviews] lastObject] removeFromSuperview];
    if ([condition isDateCondition]) {
        [[dateComparisonPopUp superview] setFrameOrigin:NSZeroPoint];
        [comparisonBox addSubview:[dateComparisonPopUp superview]];
    } else {
        [[comparisonPopUp superview] setFrameOrigin:NSZeroPoint];
        [comparisonBox addSubview:[comparisonPopUp superview]];
        [self layoutValueControls];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    OBASSERT(object == condition);
    if(object == condition) {
        if ([keyPath isEqualToString:@"key"]){
            NSString *oldKey = [change objectForKey:NSKeyValueChangeOldKey];
            NSString *newKey = [change objectForKey:NSKeyValueChangeNewKey];
            BOOL wasDate = ([oldKey isEqualToString:BDSKDateModifiedString] || [oldKey isEqualToString:BDSKDateAddedString]);
            BOOL isDate = ([newKey isEqualToString:BDSKDateModifiedString] || [newKey isEqualToString:BDSKDateAddedString]);
            if(wasDate != isDate){
                [self layoutComparisonControls];
            }
        } else if ([keyPath isEqualToString:@"dateComparison"]) {
            [self layoutValueControls];
        }
    }
}
    
@end
