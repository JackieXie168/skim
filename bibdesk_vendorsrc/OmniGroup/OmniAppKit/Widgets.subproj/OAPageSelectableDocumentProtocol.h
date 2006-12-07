// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OAPageSelectableDocumentProtocol.h,v 1.10 2003/01/15 22:51:44 kc Exp $

enum {
    OMNI_PAGE_UP_TAG, OMNI_PAGE_DOWN_TAG
};

@protocol OAPageSelectableDocument
- (void)pageUp;
- (void)pageDown;
- (void)displayPageNumber:(int)pageNumber;
@end
