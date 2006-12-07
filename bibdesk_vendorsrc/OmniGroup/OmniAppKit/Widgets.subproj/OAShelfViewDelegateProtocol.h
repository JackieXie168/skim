// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OAShelfViewDelegateProtocol.h,v 1.6 2003/01/15 22:51:45 kc Exp $

@class OAShelfView;

@protocol OAShelfViewDelegate <NSObject>
- (void)shelfViewSelectionChanged:(OAShelfView *)view;
- (void)shelfViewClick:(OAShelfView *)view onEntry:(id)entry;
- (void)shelfViewDoubleClick:(OAShelfView *)view onEntry:(id)entry;
- (void)shelfView:(OAShelfView *)view willRemoveEntry:(id)entry;
- (void)shelfView:(OAShelfView *)view willAddEntry:(id)entry;
- (BOOL)shelfView:(OAShelfView *)view didGetKey:(unsigned short)key;
- (void)shelfViewChanged:(OAShelfView *)view;
@end
