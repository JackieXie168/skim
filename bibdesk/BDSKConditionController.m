//
//  BDSKConditionController.m
//  Bibdesk
//
//  Created by Christiaan Hofman on 17/3/05.
/*
 This software is Copyright (c) 2005,2006,2007
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
    }
    return self;
}

- (void)dealloc
{
	//NSLog(@"dealloc conditionController");
    [condition removeObserver:self forKeyPath:@"key"];
    [condition removeObserver:self forKeyPath:@"dateComparison"];
    [condition removeObserver:self forKeyPath:@"stringComparison"];
    [condition removeObserver:self forKeyPath:@"stringValue"];
    [condition removeObserver:self forKeyPath:@"numberValue"];
    [condition removeObserver:self forKeyPath:@"andNumberValue"];
    [condition removeObserver:self forKeyPath:@"periodValue"];
    [condition removeObserver:self forKeyPath:@"dateValue"];
    [condition removeObserver:self forKeyPath:@"toDateValue"];
    filterController = nil;
	[condition release];
    condition = nil;
    [keys release];
    keys  = nil;
    [view release];
    view  = nil;
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

- (NSString *)windowNibName {
    return @"BDSKCondition";
}

- (void)awakeFromNib {
    // we add/remove these controls, so we need to retain them
    [view retain];
    [[dateComparisonPopUp superview] retain];
    [[comparisonPopUp superview] retain];
    [[valueTextField superview] retain];
    [[numberTextField superview] retain];
    [[andNumberTextField superview] retain];
    [[periodPopUp superview] retain];
    [[agoText superview] retain];
    [[dateTextField superview] retain];
    [[toDateTextField superview] retain];
    
    // @@ can we safely upgrade to NSDateFormatterShortStyle and drop natural language?
    NSDateFormatter *formatter = [[[NSDateFormatter alloc] initWithDateFormat:[[NSUserDefaults standardUserDefaults] objectForKey:NSShortDateFormatString] allowNaturalLanguage:YES] autorelease];
    [formatter setGeneratesCalendarDates:YES];
    [dateTextField setFormatter:formatter];
    [toDateTextField setFormatter:formatter];
	
	[keyComboBox setFormatter:[[[BDSKFieldNameFormatter alloc] init] autorelease]];
    
    [self layoutComparisonControls];
    [self layoutValueControls];
	
    [condition addObserver:self forKeyPath:@"key" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld  context:NULL];
    [condition addObserver:self forKeyPath:@"dateComparison" options: NSKeyValueObservingOptionOld  context:NULL];
    [condition addObserver:self forKeyPath:@"stringComparison" options:NSKeyValueObservingOptionOld  context:NULL];
    [condition addObserver:self forKeyPath:@"stringValue" options:NSKeyValueObservingOptionOld  context:NULL];
    [condition addObserver:self forKeyPath:@"numberValue" options:NSKeyValueObservingOptionOld  context:NULL];
    [condition addObserver:self forKeyPath:@"andNumberValue" options:NSKeyValueObservingOptionOld  context:NULL];
    [condition addObserver:self forKeyPath:@"periodValue" options:NSKeyValueObservingOptionOld  context:NULL];
    [condition addObserver:self forKeyPath:@"dateValue" options:NSKeyValueObservingOptionOld  context:NULL];
    [condition addObserver:self forKeyPath:@"toDateValue" options:NSKeyValueObservingOptionOld  context:NULL];
}

- (NSView *)view {
    [self window]; // this makes sure the nib is loaded
	return view;
}

- (IBAction)addNewCondition:(id)sender {
	[filterController insertNewConditionAfter:self];
}

- (IBAction)removeThisCondition:(id)sender {
	if (![self canRemove]) return;
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
    NSArray *views = [[[valueBox contentView] subviews] copy];
    [views makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [views release];
    
    NSEnumerator *viewEnum = [controls objectEnumerator];
    NSView *aView;
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

- (void)objectDidBeginEditing:(id)editor {
    [filterController objectDidBeginEditing:editor];		
}


- (void)objectDidEndEditing:(id)editor {
    [filterController objectDidEndEditing:editor];		
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    OBASSERT(object == condition);
    if(object == condition) {
        NSUndoManager *undoManager = [filterController undoManager];
        id oldValue = [change objectForKey:NSKeyValueChangeOldKey];
        if (oldValue == [NSNull null])
            oldValue = nil;
        if ([keyPath isEqualToString:@"key"]){
            NSString *newValue = [change objectForKey:NSKeyValueChangeNewKey];
            BOOL wasDate = ([oldValue isEqualToString:BDSKDateModifiedString] || [oldValue isEqualToString:BDSKDateAddedString]);
            BOOL isDate = ([newValue isEqualToString:BDSKDateModifiedString] || [newValue isEqualToString:BDSKDateAddedString]);
            if(wasDate != isDate){
                [self layoutComparisonControls];
            }
            [[undoManager prepareWithInvocationTarget:condition] setKey:oldValue];
        } else if ([keyPath isEqualToString:@"dateComparison"]) {
            [self layoutValueControls];
            [[undoManager prepareWithInvocationTarget:condition] setDateComparison:[oldValue intValue]];
        } else if ([keyPath isEqualToString:@"stringComparison"]) {
            [[undoManager prepareWithInvocationTarget:condition] setStringComparison:[oldValue intValue]];
        } else if ([keyPath isEqualToString:@"stringValue"]) {
            [[undoManager prepareWithInvocationTarget:condition] setStringValue:oldValue];
        } else if ([keyPath isEqualToString:@"numberValue"]) {
            [[undoManager prepareWithInvocationTarget:condition] setNumberValue:[oldValue intValue]];
        } else if ([keyPath isEqualToString:@"andNumberValue"]) {
            [[undoManager prepareWithInvocationTarget:condition] setAndNumberValue:[oldValue intValue]];
        } else if ([keyPath isEqualToString:@"periodValue"]) {
            [[undoManager prepareWithInvocationTarget:condition] setPeriodValue:[oldValue intValue]];
        } else if ([keyPath isEqualToString:@"dateValue"]) {
            [[undoManager prepareWithInvocationTarget:condition] setDateValue:oldValue];
        } else if ([keyPath isEqualToString:@"toDateValue"]) {
            [[undoManager prepareWithInvocationTarget:condition] setToDateValue:oldValue];
        }
    }
}
    
@end
