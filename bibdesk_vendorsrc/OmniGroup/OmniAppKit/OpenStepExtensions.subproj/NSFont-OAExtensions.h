// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSFont-OAExtensions.h,v 1.11 2004/02/10 04:07:34 kc Exp $

#import <AppKit/NSFont.h>

@interface NSFont (OAExtensions)
- (BOOL)isScreenFont;

+ (NSFont *)fontFromPropertyListRepresentation:(NSDictionary *)dict;
- (NSDictionary *)propertyListRepresentation;
@end
