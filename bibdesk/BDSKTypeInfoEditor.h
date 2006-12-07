//
//  BDSKTypeInfoEditor.h
//  BibDesk
//
//  Created by Christiaan Hofman on 5/4/05.
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

#import <Cocoa/Cocoa.h>
#import "BDSKSheetController.h"


@interface BDSKTypeInfoEditor : BDSKSheetController {
	IBOutlet NSTableView *typeTableView;
	IBOutlet NSTableView *requiredTableView;
	IBOutlet NSTableView *optionalTableView;
	IBOutlet NSButton *addTypeButton;
	IBOutlet NSButton *removeTypeButton;
	IBOutlet NSButton *addRequiredButton;
	IBOutlet NSButton *removeRequiredButton;
	IBOutlet NSButton *addOptionalButton;
	IBOutlet NSButton *removeOptionalButton;
	IBOutlet NSButton *revertCurrentToDefaultButton;
	IBOutlet NSButton *revertAllToDefaultButton;
	NSMutableDictionary *fieldsForTypesDict;
	NSMutableArray *types;
	NSDictionary *defaultFieldsForTypesDict;
	NSArray *defaultTypes;
	NSMutableArray *currentRequiredFields;
	NSMutableArray *currentOptionalFields;
	NSArray *currentDefaultRequiredFields;
	NSArray *currentDefaultOptionalFields;
	NSString *currentType;
}

+ (BDSKTypeInfoEditor *)sharedTypeInfoEditor;

- (void)revertTypes;

- (void)addType:(NSString *)newType withFields:(NSDictionary *)fieldsDict;
- (void)setCurrentType:(NSString *)newCurrentType;

- (IBAction)addType:(id)sender;
- (IBAction)removeType:(id)sender;
- (IBAction)addRequired:(id)sender;
- (IBAction)removeRequired:(id)sender;
- (IBAction)addOptional:(id)sender;
- (IBAction)removeOptional:(id)sender;
- (IBAction)revertCurrentToDefault:(id)sender;
- (IBAction)revertAllToDefault:(id)sender;

- (BOOL)canEditType:(NSString *)type;
- (BOOL)canEditField:(NSString *)field;
- (BOOL)canEditTableView:(NSTableView *)tv row:(int)row;
- (void)updateButtons;

@end
