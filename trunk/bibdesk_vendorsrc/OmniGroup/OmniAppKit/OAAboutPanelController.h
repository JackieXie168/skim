// Copyright 2006 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniAppKit/OAAboutPanelController.h 79090 2006-09-07 23:55:58Z kc $

#import <OmniFoundation/OFObject.h>

@class NSArray, NSAttributedString, NSMutableArray; // Foundation
@class NSButton, NSImageView, NSPanel, NSTextField, NSTextView; // AppKit

#import <AppKit/NSNibDeclarations.h> // For IBAction, IBOutlet

@interface OAAboutPanelController : OFObject
{
    IBOutlet NSPanel *panel;
    IBOutlet NSImageView *appIconImageView;
    IBOutlet NSTextField *applicationNameTextField;
    IBOutlet NSButton *fullReleaseNameButton;
    IBOutlet NSTextView *creditsTextView;
    IBOutlet NSTextField *copyrightTextField;
    
    NSMutableArray *contentVariants;
    unsigned int currentContentVariantIndex;
}

- (void)awakeFromNib;
- (NSArray *)contentVariants;
- (void)addContentVariant:(NSAttributedString *)content;
- (void)addContentVariantFromMainBundleFile:(NSString *)name ofType:(NSString *)type;

// Subclass API
- (void)willShowAboutPanel;

// Actions
- (IBAction)showNextContentVariant:(id)sender;
- (IBAction)showAboutPanel:(id)sender;
- (IBAction)hideAboutPanel:(id)sender;


@end

