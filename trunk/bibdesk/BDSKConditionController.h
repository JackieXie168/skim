//
//  BDSKConditionController.h
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

#import <Cocoa/Cocoa.h>
#import "BDSKCondition.h"

@class BDSKFilterController, BDSKRatingButton;


@interface BDSKConditionController : NSWindowController {
	IBOutlet NSComboBox *keyComboBox;
	IBOutlet NSPopUpButton *comparisonPopUp;
    IBOutlet NSPopUpButton *dateComparisonPopUp;
	IBOutlet NSTextField *valueTextField;
    IBOutlet NSTextField *numberTextField;
    IBOutlet NSTextField *andNumberTextField;
    IBOutlet NSTextField *dateTextField;
    IBOutlet NSTextField *toDateTextField;
    IBOutlet NSTextField *agoText;
    IBOutlet NSPopUpButton *periodPopUp;
    IBOutlet NSButton *booleanButton;
    IBOutlet NSButton *triStateButton;
    IBOutlet BDSKRatingButton *ratingButton;
    IBOutlet NSBox *comparisonBox;
    IBOutlet NSBox *valueBox;
	IBOutlet NSView *view;
	IBOutlet NSButton *addButton;
	IBOutlet NSButton *removeButton;
	BDSKFilterController *filterController;
	BDSKCondition *condition;
	NSMutableArray *keys;
	BOOL canRemove;
}

- (id)initWithFilterController:(BDSKFilterController *)aFilterController;
- (id)initWithFilterController:(BDSKFilterController *)aFilterController condition:(BDSKCondition *)aCondition;
- (NSView *)view;
- (IBAction)addNewCondition:(id)sender;
- (IBAction)removeThisCondition:(id)sender;
- (IBAction)changeRating:(id)sender;
- (BDSKCondition *)condition;
- (BOOL)canRemove;
- (void)setCanRemove:(BOOL)flag;
- (NSArray *)keys;
- (void)setKeys:(NSArray *)newKeys;
- (void)layoutValueControls;
- (void)layoutComparisonControls;

@end
