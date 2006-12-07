// Copyright 2002-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Tests/TestController.h,v 1.2 2003/01/15 22:51:42 kc Exp $

#import <Foundation/NSObject.h>
#import <AppKit/NSNibDeclarations.h>

@class NSButton, NSMatrix, NSTextField, NSView;

@interface TestController : NSObject
{
    IBOutlet NSView *drawStringOutputView;
    IBOutlet NSTextField *drawStringInputField;
    IBOutlet NSMatrix *drawStringAlignmentMatrix;
    IBOutlet NSButton *drawOldStyleCheckbox;
    IBOutlet NSButton *verticallyCenterCheckbox;
}

// API

- (IBAction)drawString:(id)sender;

@end
