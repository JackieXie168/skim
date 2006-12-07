// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Outline.subproj/OAOutlineTextFormatter.h,v 1.9 2003/01/15 22:51:40 kc Exp $

// This formatter provides for displaying a string value in a given font, color and alignment.

#import <OmniAppKit/OAOutlineFormatter.h>

@class NSFont;

#import <AppKit/NSText.h> // For NSTextAlignment

@interface OAOutlineTextFormatter : OAOutlineFormatter
{
    NSFont *font;
    NSColor *textColor;
    SEL stringValueSelector;
    id <NSObject> stringValueSelectorArgument;
    int alignment;
}

// Text attributes
- (void)setFont:(NSFont *)aFont;
- (void)setTextColor:(NSColor *)aColor;
- (void)setTextAlignment:(NSTextAlignment)alignment;

// These methods let you specify a selector to be used for getting a displayable string value from the object we are formatting
- (void)setValueSelector:(SEL)selector;
- (void)setValueSelector:(SEL)selector withObject:(id <NSObject>)anObject;

@end
