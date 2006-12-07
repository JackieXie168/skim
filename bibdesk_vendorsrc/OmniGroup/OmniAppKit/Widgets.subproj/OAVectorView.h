// Copyright 2003-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/SourceRelease_2005-10-03/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OAVectorView.h 68913 2005-10-03 19:36:19Z kc $

#import <AppKit/NSControl.h>

@class NSTextField;

#import <AppKit/NSNibDeclarations.h> // For IBAction, IBOutlet

@interface OAVectorView : NSControl
{
    IBOutlet NSTextField *xField;
    IBOutlet NSTextField *yField;
    IBOutlet NSTextField *commaTextField;
}

// Actions
- (IBAction)vectorTextFieldAction:(id)sender;

// API
- (void)setIsMultiple:(BOOL)flag;
- (BOOL)isMultiple;

- (NSTextField *)xField;
- (NSTextField *)yField;

@end
