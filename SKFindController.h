//
//  SKFindController.h
//  Skim
//
//  Created by Christiaan Hofman on 16/2/07.
/*
 This software is Copyright (c) 2007-2014
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
#import "SKViewController.h"

@protocol SKFindControllerDelegate;

@interface SKFindController : SKViewController {
    id <SKFindControllerDelegate> delegate;
    NSSearchField *findField;
    NSTextField *messageField;
    NSButton *doneButton;
    NSSegmentedControl *navigationButton;
    NSObjectController *ownerController;
    NSString *findString;
    NSInteger lastChangeCount;
    BOOL didChange;
    BOOL animating;
}

@property (nonatomic, retain) IBOutlet NSSearchField *findField;
@property (nonatomic, retain) IBOutlet NSTextField *messageField;
@property (nonatomic, retain) IBOutlet NSButton *doneButton;
@property (nonatomic, retain) IBOutlet NSSegmentedControl *navigationButton;
@property (nonatomic, retain) IBOutlet NSObjectController *ownerController;
@property (nonatomic, assign) id <SKFindControllerDelegate> delegate;
@property (nonatomic, retain) NSString *findString;

- (void)toggleAboveView:(NSView *)view animate:(BOOL)animate;

- (void)findForward:(BOOL)forward;
- (void)updateFindPboard;

- (IBAction)find:(id)sender;
- (IBAction)remove:(id)sender;
- (IBAction)toggleCaseInsensitiveFind:(id)sender;

@end


@protocol SKFindControllerDelegate <NSObject>
- (BOOL)findString:(NSString *)string forward:(BOOL)forward;
@end
