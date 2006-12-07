// Copyright 2003-2004 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/XML/OFXMLDocument.h,v 1.18 2004/02/10 04:07:49 kc Exp $

#import <OmniFoundation/OFObject.h>

#import <CoreFoundation/CFURL.h>

@class OFXMLCursor, OFXMLElement, OFXMLWhitespaceBehavior;
@class NSArray, NSMutableArray, NSData;

@interface OFXMLDocument : OFObject
{
    NSMutableArray         *_processingInstructions;
    CFURLRef                _dtdSystemID;
    NSString               *_dtdPublicID;
    NSMutableDictionary    *_idToObject;
    NSMutableDictionary    *_objectToID;
    OFXMLElement           *_rootElement;
    CFStringEncoding        _stringEncoding;
    
    unsigned int             _nextID;
    NSMutableArray          *_elementStack;
    OFXMLWhitespaceBehavior *_whitespaceBehavior;

    NSMutableDictionary     *_userObjects;
}

- initWithRootElementName: (NSString *) rootElementName
              dtdSystemID: (CFURLRef) dtdSystemID
              dtdPublicID: (NSString *) dtdPublicID
       whitespaceBehavior: (OFXMLWhitespaceBehavior *) whitespaceBehavior
           stringEncoding: (CFStringEncoding) stringEncoding;

- initWithContentsOfFile: (NSString *) path whitespaceBehavior: (OFXMLWhitespaceBehavior *) whitespaceBehavior;
- initWithData: (NSData *) xmlData whitespaceBehavior: (OFXMLWhitespaceBehavior *) whitespaceBehavior;

- (OFXMLWhitespaceBehavior *) whitespaceBehavior;
- (CFURLRef) dtdSystemID;
- (NSString *) dtdPublicID;
- (CFStringEncoding) stringEncoding;

- (NSData *) xmlData;
- (NSData *) xmlDataAsFragment;
- (NSData *) xmlDataForElements: (NSArray *) elements asFragment: (BOOL) asFragment;
- (BOOL) writeToFile: (NSString *) path;

- (unsigned int)processingInstructionCount;
- (NSString *)processingInstructionNameAtIndex:(unsigned int)piIndex;
- (NSString *)processingInstructionValueAtIndex:(unsigned int)piIndex;
- (void)addProcessingInstructionNamed:(NSString *)piName value:(NSString *)piValue;

- (OFXMLElement *) rootElement;

// XML identifier management
- (void) clearIdentifiers;
- (BOOL)setPreferedIdentifier:(NSString *) identifier forObject:(id)object;
- (id) objectForIdentifier:(NSString *)identifier;
- (NSString *)generateIdentifierForObject:(id)object;
- (BOOL)identifierRegisteredForObject:(id)object;

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
