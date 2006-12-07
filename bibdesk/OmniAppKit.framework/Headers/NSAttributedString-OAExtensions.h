// Copyright 1997-2002 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header$

#import <Foundation/NSAttributedString.h>
#import <Foundation/NSGeometry.h> // For NSRect

@interface NSAttributedString (OAExtensions)

- (NSAttributedString *)initWithHTML:(NSString *)htmlString;
- (NSString *)htmlString;
- (NSData *)rtf;

- (void)drawInRectangle:(NSRect)rectangle alignment:(int)alignment verticallyCentered:(BOOL)verticallyCenter;

@end
