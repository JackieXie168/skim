// Copyright 2000-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OAShrinkingTextDisplayer.h,v 1.5 2003/01/15 22:51:45 kc Exp $

#import <AppKit/NSView.h>

@class NSFont, NSString;

@interface OAShrinkingTextDisplayer : NSView
{
    NSFont *baseFont;
    NSString *string;
}

- (void)setFont:(NSFont *)font;
- (NSFont *)font;

- (void)setStringValue:(NSString *)newString;
- (NSString *)stringValue;

@end
