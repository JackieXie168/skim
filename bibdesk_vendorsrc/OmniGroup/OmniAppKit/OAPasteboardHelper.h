// Copyright 1997-2003 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OAPasteboardHelper.h,v 1.10 2003/01/15 22:51:31 kc Exp $

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
