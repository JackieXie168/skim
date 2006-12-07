// Copyright 1997-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OAPasteboardHelper.h,v 1.12 2004/02/10 04:07:31 kc Exp $

#import <OmniFoundation/OFObject.h>
#import <AppKit/NSPasteboard.h>

@interface OAPasteboardHelper : OFObject
{
    NSMutableDictionary *typeToOwner;
    unsigned int responsible;
    NSPasteboard *pasteboard;
}

+ (OAPasteboardHelper *) helperWithPasteboard:(NSPasteboard *)newPasteboard;
+ (OAPasteboardHelper *) helperWithPasteboardNamed:(NSString *)pasteboardName;
- initWithPasteboard:(NSPasteboard *)newPasteboard;
- initWithPasteboardNamed:(NSString *)pasteboardName;

- (NSPasteboard *) pasteboard;

- (void)declareTypes:(NSArray *)someTypes owner:(id)anOwner;
- (void)addTypes:(NSArray *)someTypes owner:(id)anOwner;

- (void)absolvePasteboardResponsibility;

@end
