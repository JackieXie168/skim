// Copyright 2000-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSColor-OAExtensions.h,v 1.14 2004/02/10 04:07:34 kc Exp $

#import <AppKit/NSColor.h>

@class NSDictionary, NSMutableDictionary;
@class OFXMLDocument, OFXMLCursor;

@interface NSColor (OAExtensions)

+ (NSColor *)colorFromPropertyListRepresentation:(NSDictionary *)dict;
- (NSMutableDictionary *)propertyListRepresentation;

- (BOOL)isSimilarToColor:(NSColor *)color;
- (NSData *)patternImagePNGData;

#ifdef MAC_OS_X_VERSION_10_2
- (NSString *)similarColorNameFromColorLists;
+ (NSColor *)colorWithSimilarName:(NSString *)aName;
#endif

// XML Archiving
+ (NSString *)xmlElementName;
- (void) appendXML:(OFXMLDocument *)doc;
+ (NSColor *)colorFromXML:(OFXMLCursor *)cursor;

@end

// XML Archiving user object key
extern NSString *OAColorXMLAdditionalColorSpace;