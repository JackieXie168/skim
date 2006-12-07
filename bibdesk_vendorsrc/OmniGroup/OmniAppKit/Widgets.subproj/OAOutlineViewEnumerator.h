// Copyright 2000-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OAOutlineViewEnumerator.h,v 1.4 2003/01/15 22:51:44 kc Exp $


#import <OmniFoundation/OFObject.h>

@class NSOutlineView;
@class NSArray;

@interface OAOutlineViewEnumerator : OFObject
{
    NSOutlineView *_outlineView;
    id             _dataSource;
    
    struct _OAOutlineViewEnumeratorState *_state;
    unsigned int _stateCount;
    unsigned int _stateCapacity;
}

- initWithOutlineView: (NSOutlineView *) outlineView
          visibleItem: (id) visibleItem;

- (NSArray *) nextPath;
- (NSArray *) previousPath;

- (void) resetToBeginning;
- (void) resetToEnd;

@end
