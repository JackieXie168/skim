// Copyright 2003-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/XML/OFXMLCursor.h,v 1.7 2004/02/10 04:07:48 kc Exp $

#import <OmniFoundation/OFObject.h>

@class NSArray;
@class OFXMLDocument, OFXMLElement;

@interface OFXMLCursor : OFObject
{
    OFXMLDocument            *_document;
    struct _OFXMLCursorState *_state;
    unsigned int              _stateCount;
    unsigned int              _stateSize;
}

- initWithDocument:(OFXMLDocument *)document;

- (OFXMLDocument *)document;

- (OFXMLElement *)currentElement;
- (id)currentChild;
- (NSString *)currentPath;

- (id)nextChild;
- (id)peekNextChild;
- (void)openElement;
- (void)closeElement;

// Convenience methods that forward to -currentElement
- (NSString *)name;
- (NSArray *)children;
- (NSString *)attributeNamed:(NSString *)attributeName;

// More complex convenience methods
- (BOOL)openNextChildElementNamed:(NSString *)childElementName;

@end
