// Copyright 2000-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OAOutlineViewEnumerator.h,v 1.6 2004/02/10 04:07:37 kc Exp $


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
