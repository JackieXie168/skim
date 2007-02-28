// Copyright 2003-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: svn+ssh://source.omnigroup.com/Source/svn/Omni/tags/OmniSourceRelease_2006-09-07/OmniGroup/Frameworks/OmniFoundation/XML/OFXMLDocument.h 66043 2005-07-25 21:17:05Z kc $

#import <OmniFoundation/OFXMLIdentifierRegistry.h>

#import <CoreFoundation/CFURL.h>
#import <OmniFoundation/OFXMLWhitespaceBehavior.h>

@class OFXMLCursor, OFXMLElement, OFXMLWhitespaceBehavior;
@class NSArray, NSMutableArray, NSData;

@interface OFXMLDocument : OFXMLIdentifierRegistry
{
    NSMutableArray         *_processingInstructions;
    CFURLRef                _dtdSystemID;
    NSString               *_dtdPublicID;
    OFXMLElement           *_rootElement;
    CFStringEncoding        _stringEncoding;
    
    NSMutableArray          *_elementStack;
    OFXMLWhitespaceBehavior *_whitespaceBehavior;

    NSMutableDictionary     *_userObjects;
}

- initWithRootElement:(OFXMLElement *)rootElement
          dtdSystemID:(CFURLRef)dtdSystemID
          dtdPublicID:(NSString *)dtdPublicID
   whitespaceBehavior:(OFXMLWhitespaceBehavior *)whitespaceBehavior
       stringEncoding:(CFStringEncoding)stringEncoding;

- initWithRootElementName:(NSString *)rootElementName
              dtdSystemID:(CFURLRef)dtdSystemID
              dtdPublicID:(NSString *)dtdPublicID
       whitespaceBehavior:(OFXMLWhitespaceBehavior *)whitespaceBehavior
           stringEncoding:(CFStringEncoding)stringEncoding;

- initWithContentsOfFile: (NSString *) path whitespaceBehavior: (OFXMLWhitespaceBehavior *) whitespaceBehavior;
- initWithData: (NSData *) xmlData whitespaceBehavior: (OFXMLWhitespaceBehavior *) whitespaceBehavior;
- initWithData:(NSData *)xmlData whitespaceBehavior:(OFXMLWhitespaceBehavior *)whitespaceBehavior defaultWhitespaceBehavior:(OFXMLWhitespaceBehaviorType)defaultWhitespaceBehavior;

- (OFXMLWhitespaceBehavior *) whitespaceBehavior;
- (CFURLRef) dtdSystemID;
- (NSString *) dtdPublicID;
- (CFStringEncoding) stringEncoding;

- (NSData *)xmlData;
- (NSData *)xmlDataWithDefaultWhiteSpaceBehavior:(OFXMLWhitespaceBehaviorType)defaultWhiteSpaceBehavior;
- (NSData *)xmlDataAsFragment;
- (NSData *)xmlDataForElements:(NSArray *)elements asFragment:(BOOL)asFragment;
- (NSData *)xmlDataForElements:(NSArray *)elements asFragment:(BOOL)asFragment defaultWhiteSpaceBehavior:(OFXMLWhitespaceBehaviorType)defaultWhiteSpaceBehavior;
- (BOOL)writeToFile:(NSString *)path;

- (unsigned int)processingInstructionCount;
- (NSString *)processingInstructionNameAtIndex:(unsigned int)piIndex;
- (NSString *)processingInstructionValueAtIndex:(unsigned int)piIndex;
- (void)addProcessingInstructionNamed:(NSString *)piName value:(NSString *)piValue;

- (OFXMLElement *) rootElement;

// User objects
- (id)userObjectForKey:(NSString *)key;
- (void)setUserObject:(id)object forKey:(NSString *)key;

// Writing conveniences
- (OFXMLElement *) pushElement: (NSString *) elementName;
- (void) popElement;
- (OFXMLElement *) topElement;
- (void) appendString: (NSString *) string;
- (void) appendString: (NSString *) string quotingMask: (unsigned int) quotingMask newlineReplacment: (NSString *) newlineReplacment;
- (void) setAttribute: (NSString *) name string: (NSString *) value;
- (void) setAttribute: (NSString *) name value: (id) value;
- (void) setAttribute: (NSString *) name integer: (int) value;
- (void) setAttribute: (NSString *) name real: (float) value;  // "%g"
- (void) setAttribute: (NSString *) name real: (float) value format: (NSString *) formatString;
- (void) appendElement: (NSString *) elementName;
- (void) appendElement: (NSString *) elementName containingString: (NSString *) contents;
- (void) appendElement: (NSString *) elementName containingInteger: (int) contents;
- (void) appendElement: (NSString *) elementName containingReal: (float) contents; // "%g"
- (void) appendElement: (NSString *) elementName containingReal: (float) contents format: (NSString *) formatString;

// Reading conveniences
- (OFXMLCursor *) createCursor;

@end
