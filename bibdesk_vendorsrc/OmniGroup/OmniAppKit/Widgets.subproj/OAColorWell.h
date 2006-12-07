// Copyright 2003-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OAColorWell.h,v 1.4 2004/02/10 04:07:37 kc Exp $

#import <AppKit/NSColorWell.h>

@interface OAColorWell : NSColorWell
+ (BOOL)hasActiveColorWell;
+ (NSArray *)activeColorWells;
+ (void)deactivateAllColorWells;
@end
