// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSString-OAExtensions.h,v 1.16 2004/02/10 04:07:34 kc Exp $

#import <Foundation/NSString.h>

#import <Foundation/NSGeometry.h> // For NSRect

@class NSColor, NSFont, NSImage, NSTableColumn, NSTableView;

@interface NSString (OAExtensions)

// Used for displaying a file size in a tableview, which automatically abbreviates when the column gets too narrow.
+ (NSString *)possiblyAbbreviatedStringForBytes:(unsigned long long)bytes inTableView:(NSTableView *)tableView tableColumn:(NSTableColumn *)tableColumn;

// String drawing
- (void)drawWithFontAttributes:(NSDictionary *)attributes alignment:(int)alignment verticallyCenter:(BOOL)verticallyCenter inRectangle:(NSRect)rectangle;
- (void)drawWithFont:(NSFont *)font color:(NSColor *)color alignment:(int)alignment verticallyCenter:(BOOL)verticallyCenter inRectangle:(NSRect)rectangle;
- (void)drawWithFontAttributes:(NSDictionary *)attributes alignment:(int)alignment rectangle:(NSRect)rectangle;
- (void)drawWithFont:(NSFont *)font color:(NSColor *)color alignment:(int)alignment rectangle:(NSRect)rectangle;

- (void)drawOutlinedWithFont:(NSFont *)font color:(NSColor *)color backgroundColor:(NSColor *)backgroundColor rectangle:(NSRect)rectangle;
- (NSImage *)outlinedImageWithColor:(NSColor *)color;

@end
