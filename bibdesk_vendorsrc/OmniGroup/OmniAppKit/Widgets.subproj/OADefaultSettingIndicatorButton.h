// Copyright 2003-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OADefaultSettingIndicatorButton.h,v 1.4 2004/02/10 05:17:53 kc Exp $

#import <AppKit/NSButton.h>

@interface OADefaultSettingIndicatorButton : NSButton
{
    IBOutlet NSView *snuggleUpToRightSideOfView;
    IBOutlet id delegate;
    
    NSString *identifier;
    
    struct {
        unsigned int displaysEvenInDefaultState:1;
    } _flags;
}

// Actions
- (IBAction)resetDefaultValue:(id)sender;

// API
- (id)delegate;
- (void)setDelegate:(id)newDelegate;

- (NSString *)identifier;
- (void)setIdentifier:(NSString *)newIdentifier;

- (void)validate;

- (void)setDisplaysEvenInDefaultState:(BOOL)displays;
- (BOOL)displaysEvenInDefaultState;

- (void)setSnuggleUpToRightSideOfView:(NSView *)view;
- (NSView *)snuggleUpToRightSideOfView;
- (void)repositionWithRespectToSnuggleView;

@end

@interface NSObject (OADefaultSettingIndicatorButtonDelegate)
- (id)defaultObjectValueForSettingIndicatorButton:(OADefaultSettingIndicatorButton *)indicatorButton;
- (id)objectValueForSettingIndicatorButton:(OADefaultSettingIndicatorButton *)indicatorButton;
- (void)restoreDefaultObjectValueForSettingIndicatorButton:(OADefaultSettingIndicatorButton *)indicatorButton;
@end
