// Copyright 1997-2002 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header$

#import <AppKit/NSView.h>

@class NSString;
@class NSFont;

#import <AppKit/NSNibDeclarations.h> // For IBOutlet and IBAction

@interface OAFontView : NSView
{
    IBOutlet id delegate;

    NSFont *font;
    NSString *fontDescription;
    NSSize textSize;
}

- (void) setDelegate: (id) aDelegate;
- (id) delegate;

- (NSFont *)font;
- (void)setFont:(NSFont *)newFont;

- (IBAction)setFontUsingFontPanel:(id)sender;

@end


@interface NSObject (OAFontViewDelegate)
- (BOOL)fontView:(OAFontView *)aFontView shouldChangeToFont:(NSFont *)newFont;
- (void)fontView:(OAFontView *)aFontView didChangeToFont:(NSFont *)newFont;

// We pass along the NSFontPanel delegate message, adding in the last font view to have been sent -setFontUsingFontPanel:
- (BOOL)fontView:(OAFontView *)aFontView fontManager:(id)sender willIncludeFont:(NSString *)fontName;
@end
